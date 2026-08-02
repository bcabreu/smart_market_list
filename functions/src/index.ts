import {createHash, randomBytes, timingSafeEqual} from "node:crypto";
import {initializeApp} from "firebase-admin/app";
import {getAuth} from "firebase-admin/auth";
import {
  CollectionReference,
  DocumentReference,
  FieldValue,
  Firestore,
  Timestamp,
  getFirestore,
} from "firebase-admin/firestore";
import {getStorage} from "firebase-admin/storage";
import {defineSecret} from "firebase-functions/params";
import {onSchedule} from "firebase-functions/v2/scheduler";
import {onRequest} from "firebase-functions/v2/https";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";

initializeApp();

const db = getFirestore();
const revenueCatSecret = defineSecret("REVENUECAT_SECRET_API_KEY");
const revenueCatWebhookAuth = defineSecret("REVENUECAT_WEBHOOK_AUTH");
const REGION = "southamerica-east1";
const INVITE_TTL_MS = 24 * 60 * 60 * 1000;
const RECENT_LOGIN_SECONDS = 5 * 60;
const PREMIUM_CLOUD_PURGE_GRACE_MS = 6 * 60 * 60 * 1000;

type PlanType = "free" | "premium_individual" | "premium_family";
type DirectSource = "revenuecat" | "administrative_grant";

interface DirectStatus {
  active: boolean;
  planType: PlanType;
  expiresAt: Date | null;
  managementUrl: string | null;
  source: DirectSource;
}

interface RevenueCatEntitlement {
  expires_date?: string | null;
  product_identifier?: string;
}

interface RevenueCatSubscription {
  expires_date?: string | null;
  billing_issues_detected_at?: string | null;
  unsubscribe_detected_at?: string | null;
}

interface RevenueCatSubscriber {
  subscriber?: {
    entitlements?: Record<string, RevenueCatEntitlement>;
    subscriptions?: Record<string, RevenueCatSubscription>;
    management_url?: string | null;
  };
}

function requireUid(auth: {uid: string} | undefined): string {
  if (!auth) {
    throw new HttpsError("unauthenticated", "Authentication is required.");
  }
  return auth.uid;
}

function requireString(value: unknown, field: string, maxLength = 512): string {
  if (typeof value !== "string" || value.length === 0 || value.length > maxLength) {
    throw new HttpsError("invalid-argument", `Invalid ${field}.`);
  }
  return value;
}

function createInviteToken(): {token: string; hash: string} {
  const token = randomBytes(32).toString("base64url");
  return {token, hash: hashToken(token)};
}

function hashToken(token: string): string {
  return createHash("sha256").update(token, "utf8").digest("hex");
}

function tokensMatch(token: string, expectedHash: string): boolean {
  const actual = Buffer.from(hashToken(token), "hex");
  const expected = Buffer.from(expectedHash, "hex");
  return actual.length === expected.length && timingSafeEqual(actual, expected);
}

function timestampIsFuture(value: unknown): boolean {
  return value instanceof Timestamp && value.toMillis() > Date.now();
}

function directPurchaseIsActive(data: FirebaseFirestore.DocumentData): boolean {
  if (data.purchasePremium !== true) return false;
  const expiration = data.purchaseExpiresAt;
  return expiration == null || timestampIsFuture(expiration);
}

function directFamilyIsActive(data: FirebaseFirestore.DocumentData): boolean {
  return directPurchaseIsActive(data) &&
    data.purchasePlanType === "premium_family";
}

function effectivePremiumIsActive(
  data: FirebaseFirestore.DocumentData,
): boolean {
  if (data.isPremium !== true) return false;
  const expiration = data.effectiveExpiresAt;
  return expiration == null || timestampIsFuture(expiration);
}

function premiumCloudCleanupFields(
  data: FirebaseFirestore.DocumentData,
  remainsPremium: boolean,
): Record<string, unknown> {
  if (remainsPremium) {
    return {
      premiumCloudPurgeAt: FieldValue.delete(),
      premiumCloudPurgeReason: FieldValue.delete(),
      premiumCloudPurgedAt: FieldValue.delete(),
    };
  }
  if (data.premiumCloudPurgeAt instanceof Timestamp ||
      data.premiumCloudPurgedAt instanceof Timestamp) {
    return {};
  }
  return {
    premiumCloudPurgeAt: Timestamp.fromMillis(
      Date.now() + PREMIUM_CLOUD_PURGE_GRACE_MS,
    ),
    premiumCloudPurgeReason: "subscription_inactive",
  };
}

function combinedExpiration(
  sources: Array<{
    active: boolean;
    expiresAt: Timestamp | Date | null | undefined;
  }>,
): Timestamp | null {
  let latest: Timestamp | null = null;
  for (const source of sources) {
    if (!source.active) continue;
    if (source.expiresAt == null) return null;
    const timestamp = source.expiresAt instanceof Timestamp ?
      source.expiresAt : Timestamp.fromDate(source.expiresAt);
    if (latest == null || timestamp.toMillis() > latest.toMillis()) {
      latest = timestamp;
    }
  }
  return latest;
}

function entitlementIsActive(entitlement: RevenueCatEntitlement | undefined): boolean {
  if (!entitlement) return false;
  if (entitlement.expires_date == null) return true;
  const expiresAt = Date.parse(entitlement.expires_date);
  return Number.isFinite(expiresAt) && expiresAt > Date.now();
}

function latestExpiration(values: Array<string | null | undefined>): Date | null {
  let latest: Date | null = null;
  for (const value of values) {
    if (!value) continue;
    const milliseconds = Date.parse(value);
    if (!Number.isFinite(milliseconds)) continue;
    const date = new Date(milliseconds);
    if (latest == null || date > latest) latest = date;
  }
  return latest;
}

function parseRevenueCatStatus(payload: RevenueCatSubscriber): DirectStatus {
  const subscriber = payload.subscriber ?? {};
  const entitlements = subscriber.entitlements ?? {};
  const family = entitlements.premium_family;
  const individual = entitlements.premium_individual;

  if (entitlementIsActive(family)) {
    return {
      active: true,
      planType: "premium_family",
      expiresAt: family?.expires_date ? new Date(family.expires_date) : null,
      managementUrl: subscriber.management_url ?? null,
      source: "revenuecat",
    };
  }
  if (entitlementIsActive(individual)) {
    return {
      active: true,
      planType: "premium_individual",
      expiresAt: individual?.expires_date ?
        new Date(individual.expires_date) : null,
      managementUrl: subscriber.management_url ?? null,
      source: "revenuecat",
    };
  }

  // A recognizable active product is a safe migration fallback when the
  // RevenueCat entitlement mapping has not yet propagated.
  const activeSubscriptions = Object.entries(subscriber.subscriptions ?? {})
    .filter(([, subscription]) => {
      if (subscription.expires_date == null) return true;
      return Date.parse(subscription.expires_date) > Date.now();
    });
  const familySubscription = activeSubscriptions.find(([id]) =>
    id.toLowerCase().includes("family"));
  const individualSubscription = activeSubscriptions.find(([id]) =>
    id.toLowerCase().includes("individual"));
  const fallback = familySubscription ?? individualSubscription;
  if (fallback) {
    return {
      active: true,
      planType: familySubscription ?
        "premium_family" : "premium_individual",
      expiresAt: latestExpiration([fallback[1].expires_date]),
      managementUrl: subscriber.management_url ?? null,
      source: "revenuecat",
    };
  }

  return {
    active: false,
    planType: "free",
    expiresAt: latestExpiration([
      family?.expires_date,
      individual?.expires_date,
    ]),
    managementUrl: subscriber.management_url ?? null,
    source: "revenuecat",
  };
}

function parseAdministrativeGrant(
  data: FirebaseFirestore.DocumentData | undefined,
  nowMillis = Date.now(),
): DirectStatus | null {
  if (data?.active !== true) return null;
  if (data.planType !== "premium_individual" &&
      data.planType !== "premium_family") {
    return null;
  }

  let expiresAt: Date | null = null;
  if (data.expiresAt != null) {
    if (!(data.expiresAt instanceof Timestamp)) return null;
    expiresAt = data.expiresAt.toDate();
    if (expiresAt.getTime() <= nowMillis) return null;
  }

  return {
    active: true,
    planType: data.planType,
    expiresAt,
    managementUrl: null,
    source: "administrative_grant",
  };
}

async function fetchRevenueCatStatus(uid: string): Promise<DirectStatus> {
  const response = await fetch(
    `https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(uid)}`,
    {
      headers: {
        Authorization: `Bearer ${revenueCatSecret.value()}`,
        Accept: "application/json",
      },
    },
  );

  if (response.status === 404) {
    return {
      active: false,
      planType: "free",
      expiresAt: null,
      managementUrl: null,
      source: "revenuecat",
    };
  }
  if (!response.ok) {
    throw new Error(`RevenueCat returned HTTP ${response.status}.`);
  }
  return parseRevenueCatStatus(await response.json() as RevenueCatSubscriber);
}

async function resolveDirectStatus(uid: string): Promise<DirectStatus> {
  const grantSnap = await db.collection("subscription_grants").doc(uid).get();
  const grant = parseAdministrativeGrant(grantSnap.data());
  if (grant != null) return grant;
  return fetchRevenueCatStatus(uid);
}

async function ensureWorkspace(
  uid: string,
  identity?: {email?: string; name?: string; picture?: string},
): Promise<string> {
  const userRef = db.collection("users").doc(uid);
  return db.runTransaction(async (transaction) => {
    const userSnap = await transaction.get(userRef);
    const user = userSnap.data() ?? {};

    let personalFamilyId = user.personalFamilyId as string | undefined;
    if (!personalFamilyId && user.role !== "guest" &&
        typeof user.familyId === "string") {
      personalFamilyId = user.familyId;
    }
    const familyRef = personalFamilyId ?
      db.collection("families").doc(personalFamilyId) :
      db.collection("families").doc();
    const familySnap = await transaction.get(familyRef);

    if (!familySnap.exists) {
      transaction.set(familyRef, {
        ownerId: uid,
        members: [uid],
        createdAt: FieldValue.serverTimestamp(),
      });
    }

    const isGuest = user.role === "guest" &&
      typeof user.familyId === "string";
    const safeIdentity: Record<string, unknown> = {};
    if (identity?.email != null) safeIdentity.email = identity.email;
    if (identity?.name != null) safeIdentity.name = identity.name;
    if (identity?.picture != null) safeIdentity.photoUrl = identity.picture;

    transaction.set(userRef, {
      ...safeIdentity,
      personalFamilyId: familyRef.id,
      familyId: isGuest ? user.familyId : familyRef.id,
      role: isGuest ? "guest" : "owner",
      isPremium: user.isPremium === true,
      planType: typeof user.planType === "string" ? user.planType : "free",
      purchasePremium: user.purchasePremium === true,
      purchasePlanType: typeof user.purchasePlanType === "string" ?
        user.purchasePlanType : "free",
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});

    return familyRef.id;
  });
}

async function applyDirectStatus(
  uid: string,
  status: DirectStatus,
): Promise<void> {
  await ensureWorkspace(uid);
  const userRef = db.collection("users").doc(uid);

  await db.runTransaction(async (transaction) => {
    const userSnap = await transaction.get(userRef);
    if (!userSnap.exists) throw new Error("User workspace was not created.");
    const user = userSnap.data() ?? {};
    const currentFamilyId = user.familyId as string;
    const personalFamilyId = user.personalFamilyId as string;
    const isGuest = user.role === "guest" && currentFamilyId !== personalFamilyId;

    let currentFamilyRef: DocumentReference | null = null;
    let currentFamily: FirebaseFirestore.DocumentData | undefined;
    let owner: FirebaseFirestore.DocumentData | undefined;
    let guestRef: DocumentReference | null = null;
    let guest: FirebaseFirestore.DocumentData | undefined;

    if (currentFamilyId) {
      currentFamilyRef = db.collection("families").doc(currentFamilyId);
      const familySnap = await transaction.get(currentFamilyRef);
      currentFamily = familySnap.data();
      if (isGuest && currentFamily?.ownerId) {
        const ownerSnap = await transaction.get(
          db.collection("users").doc(currentFamily.ownerId as string),
        );
        owner = ownerSnap.data();
      } else if (!isGuest && currentFamily?.guestId) {
        guestRef = db.collection("users").doc(currentFamily.guestId as string);
        const guestSnap = await transaction.get(guestRef);
        guest = guestSnap.data();
      }
    }

    const directFields = {
      purchasePremium: status.active,
      purchasePlanType: status.active ? status.planType : "free",
      purchaseExpiresAt: status.expiresAt ?
        Timestamp.fromDate(status.expiresAt) : null,
      purchaseSource: status.source,
      subscriptionManagementUrl: status.managementUrl,
      entitlementUpdatedAt: FieldValue.serverTimestamp(),
    };

    if (isGuest) {
      const familyValid = currentFamily?.guestId === uid &&
        owner != null && directFamilyIsActive(owner);
      if (familyValid) {
        const ownerExpiration = owner?.purchaseExpiresAt as
          Timestamp | null | undefined;
        transaction.set(userRef, {
          ...directFields,
          isPremium: true,
          planType: status.active ? status.planType : "premium_family_guest",
          familyAccessExpiresAt: ownerExpiration ?? null,
          effectiveExpiresAt: combinedExpiration([
            {active: status.active, expiresAt: status.expiresAt},
            {active: true, expiresAt: ownerExpiration},
          ]),
          ...premiumCloudCleanupFields(user, true),
        }, {merge: true});
      } else {
        if (currentFamilyRef && currentFamily?.guestId === uid) {
          transaction.update(currentFamilyRef, {
            guestId: FieldValue.delete(),
            members: FieldValue.arrayRemove(uid),
          });
        }
        transaction.set(userRef, {
          ...directFields,
          familyId: personalFamilyId,
          role: "owner",
          isPremium: status.active,
          planType: status.active ? status.planType : "free",
          familyAccessExpiresAt: null,
          effectiveExpiresAt: combinedExpiration([
            {active: status.active, expiresAt: status.expiresAt},
          ]),
          ...premiumCloudCleanupFields(user, status.active),
        }, {merge: true});
      }
      return;
    }

    transaction.set(userRef, {
      ...directFields,
      familyId: personalFamilyId,
      role: "owner",
      isPremium: status.active,
      planType: status.active ? status.planType : "free",
      familyAccessExpiresAt: null,
      effectiveExpiresAt: combinedExpiration([
        {active: status.active, expiresAt: status.expiresAt},
      ]),
      ...premiumCloudCleanupFields(user, status.active),
    }, {merge: true});

    // Downgrading from Family immediately removes inherited Premium and the
    // shared workspace from its guest. The guest's own purchase is preserved.
    if (status.planType !== "premium_family" && currentFamilyRef && guestRef) {
      const guestDirectActive = guest != null && directPurchaseIsActive(guest);
      transaction.update(currentFamilyRef, {
        guestId: FieldValue.delete(),
        members: FieldValue.arrayRemove(guestRef.id),
      });
      transaction.set(guestRef, {
        familyId: guest?.personalFamilyId,
        role: "owner",
        isPremium: guestDirectActive,
        planType: guestDirectActive ? guest?.purchasePlanType : "free",
        familyAccessExpiresAt: null,
        effectiveExpiresAt: combinedExpiration([{
          active: guestDirectActive,
          expiresAt: guest?.purchaseExpiresAt as Timestamp | null | undefined,
        }]),
        entitlementUpdatedAt: FieldValue.serverTimestamp(),
        ...premiumCloudCleanupFields(
          guest ?? {},
          guestDirectActive,
        ),
      }, {merge: true});
    } else if (status.planType === "premium_family" &&
        currentFamilyRef && guestRef && guest) {
      const guestDirectActive = directPurchaseIsActive(guest);
      transaction.set(guestRef, {
        isPremium: true,
        planType: guestDirectActive ?
          guest.purchasePlanType : "premium_family_guest",
        familyAccessExpiresAt: status.expiresAt ?
          Timestamp.fromDate(status.expiresAt) : null,
        effectiveExpiresAt: combinedExpiration([
          {active: true, expiresAt: status.expiresAt},
          {
            active: guestDirectActive,
            expiresAt: guest.purchaseExpiresAt as Timestamp | null | undefined,
          },
        ]),
        entitlementUpdatedAt: FieldValue.serverTimestamp(),
        ...premiumCloudCleanupFields(guest, true),
      }, {merge: true});
    }
  });
}

async function syncSubscriber(uid: string): Promise<DirectStatus> {
  const status = await resolveDirectStatus(uid);
  await applyDirectStatus(uid, status);
  if (!status.active) {
    await revokeOwnedListShares(uid);
  }
  await ensureSharedMembershipIndex(uid);
  return status;
}

function sharedMembershipId(familyId: string, listId: string): string {
  return createHash("sha256")
    .update(`${familyId}/${listId}`, "utf8")
    .digest("hex");
}

function sharedMembershipRef(
  uid: string,
  familyId: string,
  listId: string,
): DocumentReference {
  return db.collection("users").doc(uid)
    .collection("shared_lists")
    .doc(sharedMembershipId(familyId, listId));
}

async function ensureSharedMembershipIndex(uid: string): Promise<void> {
  const lists = await db.collectionGroup("shopping_lists")
    .where("members", "array-contains", uid)
    .get();
  const writer = db.bulkWriter();
  for (const list of lists.docs) {
    const data = list.data();
    const familyId = list.ref.parent.parent?.id;
    const ownerId = data.shareSponsorId ?? data.ownerId;
    if (!familyId || typeof ownerId !== "string" || ownerId === uid) continue;
    const ownerSnap = await db.collection("users").doc(ownerId).get();
    if (!ownerSnap.exists || !directPurchaseIsActive(ownerSnap.data() ?? {})) {
      continue;
    }
    writer.set(sharedMembershipRef(uid, familyId, list.id), {
      familyId,
      listId: list.id,
      ownerId,
      createdAt: FieldValue.serverTimestamp(),
    });
  }
  await writer.close();
}

async function revokeOwnedListShares(ownerId: string): Promise<void> {
  const [sponsoredLists, legacyOwnedLists] = await Promise.all([
    db.collectionGroup("shopping_lists")
      .where("shareSponsorId", "==", ownerId)
      .get(),
    db.collectionGroup("shopping_lists")
      .where("ownerId", "==", ownerId)
      .get(),
  ]);
  const lists = new Map<string, FirebaseFirestore.QueryDocumentSnapshot>();
  for (const list of [...sponsoredLists.docs, ...legacyOwnedLists.docs]) {
    lists.set(list.ref.path, list);
  }
  const writer = db.bulkWriter();
  for (const list of lists.values()) {
    const shareSponsorId = list.data().shareSponsorId;
    if (typeof shareSponsorId === "string" && shareSponsorId !== ownerId) {
      continue;
    }
    const familyId = list.ref.parent.parent?.id;
    if (!familyId) continue;
    const members = (list.data().members as unknown[] ?? [])
      .filter((member): member is string => typeof member === "string");
    for (const memberUid of members) {
      if (memberUid !== ownerId) {
        writer.delete(sharedMembershipRef(memberUid, familyId, list.id));
      }
    }
    writer.update(list.ref, {
      members: [list.data().ownerId ?? ownerId],
      shareSponsorId: FieldValue.delete(),
    });
  }
  await writer.close();
}

async function recursivelyDeleteCollection(
  ref: CollectionReference,
): Promise<void> {
  await (db as Firestore).recursiveDelete(ref);
}

async function purgePremiumCloudData(uid: string): Promise<boolean> {
  const userRef = db.collection("users").doc(uid);
  const userSnap = await userRef.get();
  if (!userSnap.exists) return false;

  const user = userSnap.data() ?? {};
  const purgeAt = user.premiumCloudPurgeAt;
  if (!(purgeAt instanceof Timestamp) ||
      purgeAt.toMillis() > Date.now() ||
      effectivePremiumIsActive(user)) {
    return false;
  }

  await revokeOwnedListShares(uid);
  await Promise.all([
    recursivelyDeleteCollection(userRef.collection("custom_items")),
    recursivelyDeleteCollection(userRef.collection("custom_categories")),
  ]);

  const personalFamilyId = user.personalFamilyId;
  if (typeof personalFamilyId === "string") {
    const familyRef = db.collection("families").doc(personalFamilyId);
    const familySnap = await familyRef.get();
    if (familySnap.data()?.ownerId === uid) {
      await Promise.all([
        recursivelyDeleteCollection(familyRef.collection("shopping_lists")),
        recursivelyDeleteCollection(familyRef.collection("shopping_notes")),
        recursivelyDeleteCollection(familyRef.collection("favorite_recipes")),
        getStorage().bucket().deleteFiles({
          prefix: `families/${personalFamilyId}/notes/`,
        }),
      ]);
    }
  }

  await userRef.set({
    premiumCloudPurgeAt: FieldValue.delete(),
    premiumCloudPurgeReason: FieldValue.delete(),
    premiumCloudPurgedAt: FieldValue.serverTimestamp(),
  }, {merge: true});
  logger.info("Premium cloud data purged after subscription ended", {uid});
  return true;
}

async function scheduleLegacyFreeCloudPurges(): Promise<void> {
  let lastDocument: FirebaseFirestore.QueryDocumentSnapshot | undefined;
  do {
    let query = db.collection("users")
      .where("isPremium", "==", false)
      .orderBy("__name__")
      .limit(500);
    if (lastDocument) query = query.startAfter(lastDocument);
    const users = await query.get();
    const writer = db.bulkWriter();
    for (const user of users.docs) {
      const data = user.data();
      if (data.premiumCloudPurgeAt instanceof Timestamp ||
          data.premiumCloudPurgedAt instanceof Timestamp) {
        continue;
      }
      writer.set(user.ref, premiumCloudCleanupFields(data, false), {
        merge: true,
      });
    }
    await writer.close();
    lastDocument = users.docs.at(-1);
    if (users.size < 500) break;
  } while (lastDocument);
}

async function purgeDuePremiumCloudData(): Promise<void> {
  let lastDocument: FirebaseFirestore.QueryDocumentSnapshot | undefined;
  do {
    let query = db.collection("users")
      .where("premiumCloudPurgeAt", "<=", Timestamp.now())
      .orderBy("premiumCloudPurgeAt")
      .orderBy("__name__")
      .limit(100);
    if (lastDocument) query = query.startAfter(lastDocument);
    const users = await query.get();
    for (const user of users.docs) {
      try {
        await purgePremiumCloudData(user.id);
      } catch (error) {
        logger.error("Premium cloud purge failed", {
          uid: user.id,
          error,
        });
      }
    }
    lastDocument = users.docs.at(-1);
    if (users.size < 100) break;
  } while (lastDocument);
}

export const ensureUserWorkspace = onCall(
  {region: REGION},
  async (request) => {
    const uid = requireUid(request.auth);
    const token = (request.auth?.token ?? {}) as Record<string, unknown>;
    const personalFamilyId = await ensureWorkspace(uid, {
      email: typeof token.email === "string" ? token.email : undefined,
      name: typeof token.name === "string" ? token.name : undefined,
      picture: typeof token.picture === "string" ? token.picture : undefined,
    });
    return {personalFamilyId};
  },
);

export const syncRevenueCatStatus = onCall(
  {region: REGION, secrets: [revenueCatSecret]},
  async (request) => {
    const uid = requireUid(request.auth);
    const status = await syncSubscriber(uid);
    return {
      isPremium: status.active,
      planType: status.planType,
      expiresAt: status.expiresAt?.toISOString() ?? null,
      managementUrl: status.managementUrl,
    };
  },
);

export const revenueCatWebhook = onRequest(
  {region: REGION, secrets: [revenueCatSecret, revenueCatWebhookAuth]},
  async (request, response) => {
    const authorization = request.get("authorization") ?? "";
    const expected = revenueCatWebhookAuth.value();
    const suppliedBytes = Buffer.from(authorization);
    const expectedBytes = Buffer.from(expected);
    if (suppliedBytes.length !== expectedBytes.length ||
        !timingSafeEqual(suppliedBytes, expectedBytes)) {
      response.status(401).send("Unauthorized");
      return;
    }

    const event = request.body?.event ?? request.body;
    const candidates = [
      event?.app_user_id,
      event?.original_app_user_id,
      ...(Array.isArray(event?.aliases) ? event.aliases : []),
      ...(Array.isArray(event?.transferred_from) ? event.transferred_from : []),
      ...(Array.isArray(event?.transferred_to) ? event.transferred_to : []),
    ].filter((value): value is string =>
      typeof value === "string" && !value.startsWith("$RCAnonymousID:"));

    const uniqueUids = [...new Set(candidates)];
    await Promise.all(uniqueUids.map(async (uid) => {
      try {
        await syncSubscriber(uid);
      } catch (error) {
        logger.error("RevenueCat webhook sync failed", {uid, error});
        throw error;
      }
    }));
    response.status(200).send("OK");
  },
);

async function refreshSubscriptionQuery(
  fieldPath: "isPremium" | "purchasePremium",
  seen: Set<string>,
  include: (data: FirebaseFirestore.DocumentData) => boolean,
): Promise<void> {
  let lastDocument: FirebaseFirestore.QueryDocumentSnapshot | undefined;
  do {
    let query = db.collection("users")
      .where(fieldPath, "==", true)
      .orderBy("__name__")
      .limit(500);
    if (lastDocument) query = query.startAfter(lastDocument);
    const users = await query.get();
    for (const user of users.docs) {
      if (seen.has(user.id) || !include(user.data())) continue;
      seen.add(user.id);
      try {
        await syncSubscriber(user.id);
      } catch (error) {
        logger.error("Scheduled subscription sync failed", {
          uid: user.id,
          error,
        });
      }
    }
    lastDocument = users.docs.at(-1);
    if (users.size < 500) break;
  } while (lastDocument);
}

export const refreshActiveSubscriptions = onSchedule(
  {
    region: REGION,
    schedule: "every 6 hours",
    secrets: [revenueCatSecret],
    timeZone: "Etc/UTC",
  },
  async () => {
    const seen = new Set<string>();
    const administrativeGrants = await db.collection("subscription_grants")
      .where("active", "==", true)
      .get();
    for (const grant of administrativeGrants.docs) {
      seen.add(grant.id);
      try {
        await syncSubscriber(grant.id);
      } catch (error) {
        logger.error("Administrative subscription sync failed", {
          uid: grant.id,
          error,
        });
      }
    }

    // Migrates legacy paid owners before evaluating any inherited Family
    // access. Current direct subscribers are then refreshed, including a
    // Family guest who also owns a separate purchase.
    await refreshSubscriptionQuery(
      "isPremium",
      seen,
      (data) => data.role !== "guest",
    );
    await refreshSubscriptionQuery(
      "purchasePremium",
      seen,
      () => true,
    );
    await scheduleLegacyFreeCloudPurges();
    await purgeDuePremiumCloudData();
  },
);

export const createFamilyInvite = onCall(
  {region: REGION},
  async (request) => {
    const uid = requireUid(request.auth);
    const userRef = db.collection("users").doc(uid);
    const userSnap = await userRef.get();
    const user = userSnap.data();
    if (!user || user.role !== "owner" || !directFamilyIsActive(user)) {
      throw new HttpsError(
        "permission-denied",
        "An active Family subscription is required.",
      );
    }
    const familyId = requireString(user.familyId, "familyId");
    const familyRef = db.collection("families").doc(familyId);
    const familySnap = await familyRef.get();
    if (!familySnap.exists || familySnap.data()?.ownerId !== uid) {
      throw new HttpsError("permission-denied", "Only the family owner can invite.");
    }
    if (familySnap.data()?.guestId) {
      throw new HttpsError("resource-exhausted", "familyAlreadyHasMember");
    }

    const inviteRef = db.collection("family_invites").doc();
    const {token, hash} = createInviteToken();
    const expiresAt = Timestamp.fromMillis(Date.now() + INVITE_TTL_MS);
    await inviteRef.set({
      familyId,
      ownerId: uid,
      tokenHash: hash,
      createdAt: FieldValue.serverTimestamp(),
      expiresAt,
      usedAt: null,
    });
    return {inviteId: inviteRef.id, token, familyId, expiresAt: expiresAt.toDate().toISOString()};
  },
);

export const joinFamily = onCall(
  {region: REGION},
  async (request) => {
    const uid = requireUid(request.auth);
    const inviteId = requireString(request.data?.inviteId, "inviteId", 128);
    const token = requireString(request.data?.token, "token", 256);
    await ensureWorkspace(uid);

    await db.runTransaction(async (transaction) => {
      const inviteRef = db.collection("family_invites").doc(inviteId);
      const userRef = db.collection("users").doc(uid);
      const inviteSnap = await transaction.get(inviteRef);
      const invite = inviteSnap.data();
      if (!invite || invite.usedAt != null ||
          !timestampIsFuture(invite.expiresAt) ||
          typeof invite.tokenHash !== "string" ||
          !tokensMatch(token, invite.tokenHash)) {
        throw new HttpsError("permission-denied", "inviteInvalidOrExpired");
      }
      if (invite.ownerId === uid) {
        throw new HttpsError("failed-precondition", "Owner cannot join as guest.");
      }

      const familyRef = db.collection("families").doc(invite.familyId as string);
      const ownerRef = db.collection("users").doc(invite.ownerId as string);
      const [familySnap, ownerSnap, userSnap] = await Promise.all([
        transaction.get(familyRef),
        transaction.get(ownerRef),
        transaction.get(userRef),
      ]);
      const family = familySnap.data();
      const owner = ownerSnap.data();
      const user = userSnap.data();

      if (!family || family.ownerId !== invite.ownerId || family.guestId ||
          !owner || !directFamilyIsActive(owner)) {
        throw new HttpsError("failed-precondition", "familyAlreadyHasMember");
      }
      if (user?.role === "guest" && user.familyId !== invite.familyId) {
        throw new HttpsError(
          "failed-precondition",
          "Leave the current family before joining another.",
        );
      }

      const guestDirectActive = user != null && directPurchaseIsActive(user);
      const ownerExpiration = owner?.purchaseExpiresAt as
        Timestamp | null | undefined;
      transaction.update(familyRef, {
        guestId: uid,
        members: FieldValue.arrayUnion(uid),
      });
      transaction.set(userRef, {
        familyId: invite.familyId,
        role: "guest",
        isPremium: true,
        planType: guestDirectActive ?
          user?.purchasePlanType : "premium_family_guest",
        familyAccessExpiresAt: ownerExpiration ?? null,
        effectiveExpiresAt: combinedExpiration([
          {active: true, expiresAt: ownerExpiration},
          {
            active: guestDirectActive,
            expiresAt: user?.purchaseExpiresAt as Timestamp | null | undefined,
          },
        ]),
        entitlementUpdatedAt: FieldValue.serverTimestamp(),
        ...premiumCloudCleanupFields(user ?? {}, true),
      }, {merge: true});
      transaction.update(inviteRef, {
        usedAt: FieldValue.serverTimestamp(),
        usedBy: uid,
        tokenHash: FieldValue.delete(),
      });
    });
    return {joined: true};
  },
);

export const leaveFamily = onCall(
  {region: REGION},
  async (request) => {
    const uid = requireUid(request.auth);
    await db.runTransaction(async (transaction) => {
      const userRef = db.collection("users").doc(uid);
      const userSnap = await transaction.get(userRef);
      const user = userSnap.data();
      if (!user || user.role !== "guest" || !user.familyId) return;
      const familyRef = db.collection("families").doc(user.familyId as string);
      const familySnap = await transaction.get(familyRef);
      const family = familySnap.data();
      if (family?.guestId === uid) {
        transaction.update(familyRef, {
          guestId: FieldValue.delete(),
          members: FieldValue.arrayRemove(uid),
        });
      }
      const directActive = directPurchaseIsActive(user);
      transaction.set(userRef, {
        familyId: user.personalFamilyId,
        role: "owner",
        isPremium: directActive,
        planType: directActive ? user.purchasePlanType : "free",
        familyAccessExpiresAt: null,
        effectiveExpiresAt: combinedExpiration([{
          active: directActive,
          expiresAt: user.purchaseExpiresAt as Timestamp | null | undefined,
        }]),
        entitlementUpdatedAt: FieldValue.serverTimestamp(),
        ...premiumCloudCleanupFields(user, directActive),
      }, {merge: true});
    });
    return {left: true};
  },
);

export const removeFamilyMember = onCall(
  {region: REGION},
  async (request) => {
    const uid = requireUid(request.auth);
    const memberUid = requireString(request.data?.memberUid, "memberUid", 128);
    await db.runTransaction(async (transaction) => {
      const ownerRef = db.collection("users").doc(uid);
      const memberRef = db.collection("users").doc(memberUid);
      const [ownerSnap, memberSnap] = await Promise.all([
        transaction.get(ownerRef),
        transaction.get(memberRef),
      ]);
      const owner = ownerSnap.data();
      const member = memberSnap.data();
      if (!owner?.familyId || owner.role !== "owner") {
        throw new HttpsError("permission-denied", "Only the family owner can remove members.");
      }
      const familyRef = db.collection("families").doc(owner.familyId as string);
      const familySnap = await transaction.get(familyRef);
      if (familySnap.data()?.ownerId !== uid ||
          familySnap.data()?.guestId !== memberUid) {
        throw new HttpsError("not-found", "Family member not found.");
      }
      const directActive = member != null && directPurchaseIsActive(member);
      transaction.update(familyRef, {
        guestId: FieldValue.delete(),
        members: FieldValue.arrayRemove(memberUid),
      });
      transaction.set(memberRef, {
        familyId: member?.personalFamilyId,
        role: "owner",
        isPremium: directActive,
        planType: directActive ? member?.purchasePlanType : "free",
        familyAccessExpiresAt: null,
        effectiveExpiresAt: combinedExpiration([{
          active: directActive,
          expiresAt: member?.purchaseExpiresAt as
            Timestamp | null | undefined,
        }]),
        entitlementUpdatedAt: FieldValue.serverTimestamp(),
        ...premiumCloudCleanupFields(member ?? {}, directActive),
      }, {merge: true});
    });
    return {removed: true};
  },
);

export const createListInvite = onCall(
  {region: REGION},
  async (request) => {
    const uid = requireUid(request.auth);
    const familyId = requireString(request.data?.familyId, "familyId", 128);
    const listId = requireString(request.data?.listId, "listId", 128);
    const userRef = db.collection("users").doc(uid);
    const familyRef = db.collection("families").doc(familyId);
    const listRef = familyRef.collection("shopping_lists").doc(listId);
    const [userSnap, familySnap, listSnap] = await Promise.all([
      userRef.get(),
      familyRef.get(),
      listRef.get(),
    ]);
    const user = userSnap.data();
    const family = familySnap.data();
    const list = listSnap.data();
    const ownsList = list?.ownerId === uid || family?.ownerId === uid;
    if (!user || !directPurchaseIsActive(user) || !list || !ownsList) {
      throw new HttpsError(
        "permission-denied",
        "An active Premium owner is required to share this list.",
      );
    }

    const inviteRef = db.collection("list_invites").doc();
    const {token, hash} = createInviteToken();
    const expiresAt = Timestamp.fromMillis(Date.now() + INVITE_TTL_MS);
    const batch = db.batch();
    batch.set(inviteRef, {
      familyId,
      listId,
      ownerId: uid,
      tokenHash: hash,
      createdAt: FieldValue.serverTimestamp(),
      expiresAt,
      usedAt: null,
    });
    batch.set(listRef, {
      ...(list.ownerId == null ? {ownerId: uid} : {}),
      shareSponsorId: uid,
      familyId,
      members: FieldValue.arrayUnion(uid),
    }, {merge: true});
    await batch.commit();
    return {inviteId: inviteRef.id, token, familyId, listId, expiresAt: expiresAt.toDate().toISOString()};
  },
);

export const joinSharedList = onCall(
  {region: REGION},
  async (request) => {
    const uid = requireUid(request.auth);
    const inviteId = requireString(request.data?.inviteId, "inviteId", 128);
    const token = requireString(request.data?.token, "token", 256);
    await ensureWorkspace(uid);

    await db.runTransaction(async (transaction) => {
      const inviteRef = db.collection("list_invites").doc(inviteId);
      const inviteSnap = await transaction.get(inviteRef);
      const invite = inviteSnap.data();
      if (!invite || invite.usedAt != null ||
          !timestampIsFuture(invite.expiresAt) ||
          typeof invite.tokenHash !== "string" ||
          !tokensMatch(token, invite.tokenHash)) {
        throw new HttpsError("permission-denied", "inviteInvalidOrExpired");
      }
      const ownerRef = db.collection("users").doc(invite.ownerId as string);
      const listRef = db.collection("families")
        .doc(invite.familyId as string)
        .collection("shopping_lists")
        .doc(invite.listId as string);
      const [ownerSnap, listSnap] = await Promise.all([
        transaction.get(ownerRef),
        transaction.get(listRef),
      ]);
      const owner = ownerSnap.data();
      const list = listSnap.data();
      if (!owner || !directPurchaseIsActive(owner) || !list ||
          (list.shareSponsorId !== invite.ownerId &&
            !(list.shareSponsorId == null &&
              list.ownerId === invite.ownerId))) {
        throw new HttpsError(
          "failed-precondition",
          "The list owner no longer has Premium.",
        );
      }
      transaction.update(listRef, {
        members: FieldValue.arrayUnion(uid),
      });
      transaction.set(
        sharedMembershipRef(
          uid,
          invite.familyId as string,
          invite.listId as string,
        ),
        {
          familyId: invite.familyId,
          listId: invite.listId,
          ownerId: invite.ownerId,
          createdAt: FieldValue.serverTimestamp(),
        },
      );
      transaction.update(inviteRef, {
        usedAt: FieldValue.serverTimestamp(),
        usedBy: uid,
        tokenHash: FieldValue.delete(),
      });
    });
    return {joined: true};
  },
);

export const removeListMember = onCall(
  {region: REGION},
  async (request) => {
    const uid = requireUid(request.auth);
    const familyId = requireString(request.data?.familyId, "familyId", 128);
    const listId = requireString(request.data?.listId, "listId", 128);
    const requestedMember = request.data?.memberUid;
    const listRef = db.collection("families").doc(familyId)
      .collection("shopping_lists").doc(listId);
    await db.runTransaction(async (transaction) => {
      const listSnap = await transaction.get(listRef);
      const list = listSnap.data();
      if (!list) throw new HttpsError("not-found", "List not found.");
      const memberUid = typeof requestedMember === "string" ?
        requestedMember : uid;
      if (uid !== list.ownerId &&
          uid !== list.shareSponsorId &&
          uid !== memberUid) {
        throw new HttpsError("permission-denied", "Not allowed.");
      }
      if (memberUid === list.ownerId) {
        throw new HttpsError("failed-precondition", "The owner cannot leave the list.");
      }
      transaction.update(listRef, {
        members: FieldValue.arrayRemove(memberUid),
      });
      transaction.delete(sharedMembershipRef(
        memberUid,
        familyId,
        listId,
      ));
    });
    return {removed: true};
  },
);

async function removeUserFromSharedLists(uid: string): Promise<void> {
  const shared = await db.collectionGroup("shopping_lists")
    .where("members", "array-contains", uid)
    .get();
  const writer = db.bulkWriter();
  for (const list of shared.docs) {
    if (list.data().ownerId !== uid) {
      writer.update(list.ref, {members: FieldValue.arrayRemove(uid)});
    }
  }
  await writer.close();
}

async function deleteRevenueCatSubscriber(uid: string): Promise<void> {
  const response = await fetch(
    `https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(uid)}`,
    {
      method: "DELETE",
      headers: {Authorization: `Bearer ${revenueCatSecret.value()}`},
    },
  );
  if (!response.ok && response.status !== 404) {
    throw new Error(
      `RevenueCat subscriber deletion returned HTTP ${response.status}.`,
    );
  }
}

async function recursivelyDelete(ref: DocumentReference): Promise<void> {
  await (db as Firestore).recursiveDelete(ref);
}

export const deleteAccount = onCall(
  {region: REGION, secrets: [revenueCatSecret], timeoutSeconds: 120},
  async (request) => {
    const uid = requireUid(request.auth);
    const authTime = Number(request.auth?.token.auth_time ?? 0);
    if (!authTime ||
        Math.floor(Date.now() / 1000) - authTime > RECENT_LOGIN_SECONDS) {
      throw new HttpsError(
        "failed-precondition",
        "requires-recent-login",
      );
    }

    const userRef = db.collection("users").doc(uid);
    const userSnap = await userRef.get();
    const user = userSnap.data() ?? {};
    const familyIds = new Set<string>();
    if (typeof user.personalFamilyId === "string") {
      familyIds.add(user.personalFamilyId);
    }
    if (user.role === "owner" && typeof user.familyId === "string") {
      familyIds.add(user.familyId);
      const familyRef = db.collection("families").doc(user.familyId);
      const familySnap = await familyRef.get();
      const guestId = familySnap.data()?.guestId;
      if (typeof guestId === "string") {
        const guestRef = db.collection("users").doc(guestId);
        const guestSnap = await guestRef.get();
        const guest = guestSnap.data() ?? {};
        const directActive = directPurchaseIsActive(guest);
        await guestRef.set({
          familyId: guest.personalFamilyId,
          role: "owner",
          isPremium: directActive,
          planType: directActive ? guest.purchasePlanType : "free",
          familyAccessExpiresAt: null,
          effectiveExpiresAt: combinedExpiration([{
            active: directActive,
            expiresAt: guest.purchaseExpiresAt as
              Timestamp | null | undefined,
          }]),
          entitlementUpdatedAt: FieldValue.serverTimestamp(),
          ...premiumCloudCleanupFields(guest, directActive),
        }, {merge: true});
      }
    } else if (user.role === "guest" && typeof user.familyId === "string") {
      await db.collection("families").doc(user.familyId).set({
        guestId: FieldValue.delete(),
        members: FieldValue.arrayRemove(uid),
      }, {merge: true});
    }

    await removeUserFromSharedLists(uid);
    await revokeOwnedListShares(uid);
    // Delete the external subscriber first. If this fails, keep the account
    // available so the user can retry instead of leaving orphaned billing data.
    await deleteRevenueCatSubscriber(uid);
    await db.collection("subscription_grants").doc(uid).delete();
    for (const familyId of familyIds) {
      await recursivelyDelete(db.collection("families").doc(familyId));
    }
    await recursivelyDelete(userRef);
    await getStorage().bucket().deleteFiles({prefix: `users/${uid}/`});
    for (const familyId of familyIds) {
      await getStorage().bucket().deleteFiles({prefix: `families/${familyId}/`});
    }
    await getAuth().deleteUser(uid);
    return {deleted: true};
  },
);

export const _test = {
  parseRevenueCatStatus,
  parseAdministrativeGrant,
  effectivePremiumIsActive,
  hashToken,
};
