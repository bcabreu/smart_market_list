const {after, before, test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');
const {
  Timestamp,
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  setDoc,
  updateDoc,
} = require('firebase/firestore');
const {
  getDownloadURL,
  ref,
  uploadBytes,
} = require('firebase/storage');

const projectId = 'smart-market-list-82bf7';
const future = Timestamp.fromMillis(Date.now() + 60 * 60 * 1000);
let environment;

before(async () => {
  environment = await initializeTestEnvironment({
    projectId,
    firestore: {
      rules: fs.readFileSync(
        path.join(__dirname, '..', 'firestore.rules'),
        'utf8',
      ),
    },
    storage: {
      rules: fs.readFileSync(
        path.join(__dirname, '..', 'storage.rules'),
        'utf8',
      ),
    },
  });

  await environment.withSecurityRulesDisabled(async (context) => {
    const firestore = context.firestore();
    await setDoc(doc(firestore, 'users/owner'), {
      email: 'owner@example.com',
      personalFamilyId: 'family-owner',
      familyId: 'family-owner',
      role: 'owner',
      isPremium: true,
      planType: 'premium_family',
      purchasePremium: true,
      purchasePlanType: 'premium_family',
      purchaseExpiresAt: future,
    });
    await setDoc(doc(firestore, 'users/family-guest'), {
      email: 'family@example.com',
      personalFamilyId: 'family-guest-personal',
      familyId: 'family-owner',
      role: 'guest',
      isPremium: true,
      planType: 'premium_family_guest',
      purchasePremium: false,
      purchasePlanType: 'free',
      purchaseExpiresAt: null,
    });
    await setDoc(doc(firestore, 'users/list-guest'), {
      email: 'list@example.com',
      personalFamilyId: 'family-list-guest',
      familyId: 'family-list-guest',
      role: 'owner',
      isPremium: false,
      planType: 'free',
      purchasePremium: false,
      purchasePlanType: 'free',
      purchaseExpiresAt: null,
    });
    await setDoc(doc(firestore, 'users/attacker'), {
      email: 'attacker@example.com',
      personalFamilyId: 'family-attacker',
      familyId: 'family-attacker',
      role: 'owner',
      isPremium: false,
      planType: 'free',
      purchasePremium: false,
      purchasePlanType: 'free',
      purchaseExpiresAt: null,
    });
    await setDoc(doc(firestore, 'users/lifetime-owner'), {
      email: 'lifetime@example.com',
      personalFamilyId: 'family-lifetime',
      familyId: 'family-lifetime',
      role: 'owner',
      isPremium: true,
      planType: 'premium_family',
      purchasePremium: true,
      purchasePlanType: 'premium_family',
      purchaseExpiresAt: null,
      purchaseSource: 'administrative_grant',
    });
    await setDoc(doc(firestore, 'users/lifetime-wife'), {
      email: 'wife@example.com',
      personalFamilyId: 'family-lifetime-wife',
      familyId: 'family-lifetime',
      role: 'guest',
      isPremium: true,
      planType: 'premium_family_guest',
      purchasePremium: false,
      purchasePlanType: 'free',
      purchaseExpiresAt: null,
    });
    await setDoc(doc(firestore, 'families/family-owner'), {
      ownerId: 'owner',
      guestId: 'family-guest',
      members: ['owner', 'family-guest'],
    });
    await setDoc(doc(firestore, 'families/family-lifetime'), {
      ownerId: 'lifetime-owner',
      guestId: 'lifetime-wife',
      members: ['lifetime-owner', 'lifetime-wife'],
    });
    await setDoc(doc(firestore, 'subscription_grants/lifetime-owner'), {
      active: true,
      planType: 'premium_family',
      expiresAt: null,
    });
    await setDoc(
      doc(firestore, 'users/list-guest/shared_lists/share-1'),
      {
        familyId: 'family-owner',
        listId: 'list-1',
        ownerId: 'owner',
      },
    );
    await setDoc(
      doc(
        firestore,
        'families/family-owner/shopping_lists/list-1',
      ),
      {
        id: 'list-1',
        name: 'Shared list',
        emoji: '🛒',
        budget: 100,
        items: [],
        createdAt: Date.now(),
        ownerId: 'owner',
        shareSponsorId: 'owner',
        familyId: 'family-owner',
        members: ['owner', 'list-guest'],
      },
    );
    await setDoc(
      doc(
        firestore,
        'families/family-owner/shopping_lists/family-delete',
      ),
      {
        id: 'family-delete',
        name: 'Family list',
        emoji: '🛒',
        budget: 100,
        items: [],
        createdAt: Date.now(),
        ownerId: 'owner',
        familyId: 'family-owner',
        members: ['owner'],
      },
    );
    await setDoc(
      doc(
        firestore,
        'families/family-owner/shopping_notes/note-1',
      ),
      {id: 'note-1', storeName: 'Store'},
    );
    await setDoc(
      doc(
        firestore,
        'families/family-lifetime/shopping_notes/note-1',
      ),
      {id: 'note-1', storeName: 'Lifetime Store'},
    );
    await uploadBytes(
      ref(context.storage(), 'users/owner/profile.jpg'),
      new Uint8Array([1, 2, 3]),
      {contentType: 'image/jpeg'},
    );
  });
});

after(async () => {
  await environment.cleanup();
});

test('a signed-in user cannot read another arbitrary profile', async () => {
  const firestore = environment.authenticatedContext('attacker').firestore();
  await assertFails(getDoc(doc(firestore, 'users/owner')));
});

test('a user can edit safe profile fields but cannot grant Premium', async () => {
  const firestore = environment.authenticatedContext('owner').firestore();
  await assertSucceeds(updateDoc(doc(firestore, 'users/owner'), {
    name: 'Owner name',
  }));
  await assertFails(updateDoc(doc(firestore, 'users/owner'), {
    isPremium: false,
  }));
  await assertFails(updateDoc(doc(firestore, 'users/owner'), {
    purchasePremium: false,
  }));
});

test('a Free invitee can access only the explicitly shared list', async () => {
  const firestore =
      environment.authenticatedContext('list-guest').firestore();
  const listRef = doc(
    firestore,
    'families/family-owner/shopping_lists/list-1',
  );
  await assertSucceeds(getDoc(listRef));
  await assertSucceeds(updateDoc(listRef, {name: 'Updated together'}));
  await assertFails(deleteDoc(listRef));
  await assertFails(updateDoc(listRef, {
    members: ['owner', 'list-guest', 'attacker'],
  }));
  await assertFails(updateDoc(listRef, {
    createdAt: Date.now(),
  }));
  await assertFails(
    getDoc(doc(
      firestore,
      'families/family-owner/shopping_notes/note-1',
    )),
  );
});

test('only the invitee can read their server-managed shared-list index', async () => {
  const firestore =
      environment.authenticatedContext('list-guest').firestore();
  const result = await assertSucceeds(getDocs(collection(
    firestore,
    'users/list-guest/shared_lists',
  )));
  assert.equal(result.size, 1);

  const attacker =
      environment.authenticatedContext('attacker').firestore();
  await assertFails(getDocs(collection(
    attacker,
    'users/list-guest/shared_lists',
  )));
});

test('a Family guest can manage the complete shared workspace', async () => {
  const firestore =
      environment.authenticatedContext('family-guest').firestore();
  await assertSucceeds(deleteDoc(doc(
    firestore,
    'families/family-owner/shopping_lists/family-delete',
  )));
});

test('a lifetime Family grant keeps the spouse workspace available', async () => {
  const firestore =
      environment.authenticatedContext('lifetime-wife').firestore();
  await assertSucceeds(getDoc(doc(
    firestore,
    'families/family-lifetime/shopping_notes/note-1',
  )));
});

test('administrative subscription grants are server-only', async () => {
  const firestore =
      environment.authenticatedContext('lifetime-owner').firestore();
  const grantRef = doc(
    firestore,
    'subscription_grants/lifetime-owner',
  );
  await assertFails(getDoc(grantRef));
  await assertFails(updateDoc(grantRef, {active: false}));
});

test('Storage profile images are private outside an active family', async () => {
  const ownerStorage = environment.authenticatedContext('owner').storage();
  await assertSucceeds(getDownloadURL(
    ref(ownerStorage, 'users/owner/profile.jpg'),
  ));

  const familyStorage =
      environment.authenticatedContext('family-guest').storage();
  await assertSucceeds(getDownloadURL(
    ref(familyStorage, 'users/owner/profile.jpg'),
  ));

  const attackerStorage =
      environment.authenticatedContext('attacker').storage();
  await assertFails(getDownloadURL(
    ref(attackerStorage, 'users/owner/profile.jpg'),
  ));
});

test('a Family guest loses the workspace when the owner loses Family', async () => {
  const guestFirestore =
      environment.authenticatedContext('family-guest').firestore();
  const noteRef = doc(
    guestFirestore,
    'families/family-owner/shopping_notes/note-1',
  );
  const familyRef = doc(guestFirestore, 'families/family-owner');
  await assertSucceeds(getDoc(noteRef));
  await assertSucceeds(getDoc(familyRef));

  await environment.withSecurityRulesDisabled(async (context) => {
    await updateDoc(doc(context.firestore(), 'users/owner'), {
      purchasePlanType: 'premium_individual',
      planType: 'premium_individual',
    });
  });
  await assertFails(getDoc(noteRef));
  await assertFails(getDoc(familyRef));
});

test('a shared list is revoked when its owner is no longer Premium', async () => {
  await environment.withSecurityRulesDisabled(async (context) => {
    await updateDoc(doc(context.firestore(), 'users/owner'), {
      purchasePremium: false,
      purchasePlanType: 'free',
      purchaseExpiresAt: null,
      isPremium: false,
      planType: 'free',
    });
  });
  const firestore =
      environment.authenticatedContext('list-guest').firestore();
  await assertFails(getDoc(doc(
    firestore,
    'families/family-owner/shopping_lists/list-1',
  )));
});

test('Storage rejects non-images and another user profile path', async () => {
  const context = environment.authenticatedContext('owner');
  const storage = context.storage();
  await assertFails(uploadBytes(
    ref(storage, 'users/attacker/profile.jpg'),
    new Uint8Array([1, 2, 3]),
    {contentType: 'image/jpeg'},
  ));
  await assertFails(uploadBytes(
    ref(storage, 'users/owner/profile.txt'),
    new Uint8Array([1, 2, 3]),
    {contentType: 'text/plain'},
  ));
});
