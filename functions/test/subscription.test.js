const assert = require('node:assert/strict');
const {test} = require('node:test');
const {Timestamp} = require('firebase-admin/firestore');

const {_test} = require('../lib/index.js');

test('RevenueCat Family entitlement takes precedence', () => {
  const future = new Date(Date.now() + 60_000).toISOString();
  const status = _test.parseRevenueCatStatus({
    subscriber: {
      entitlements: {
        premium_individual: {expires_date: future},
        premium_family: {expires_date: future},
      },
    },
  });

  assert.equal(status.active, true);
  assert.equal(status.planType, 'premium_family');
});

test('expired RevenueCat entitlements become Free', () => {
  const past = new Date(Date.now() - 60_000).toISOString();
  const status = _test.parseRevenueCatStatus({
    subscriber: {
      entitlements: {
        premium_individual: {expires_date: past},
      },
    },
  });

  assert.equal(status.active, false);
  assert.equal(status.planType, 'free');
});

test('a lifetime administrative Family grant stays active', () => {
  const status = _test.parseAdministrativeGrant({
    active: true,
    planType: 'premium_family',
    expiresAt: null,
  });

  assert.equal(status.active, true);
  assert.equal(status.planType, 'premium_family');
  assert.equal(status.expiresAt, null);
  assert.equal(status.source, 'administrative_grant');
});

test('an expired administrative grant falls back to RevenueCat', () => {
  const status = _test.parseAdministrativeGrant({
    active: true,
    planType: 'premium_family',
    expiresAt: Timestamp.fromMillis(Date.now() - 60_000),
  });

  assert.equal(status, null);
});

test('expired effective Premium is eligible for cloud cleanup', () => {
  assert.equal(_test.effectivePremiumIsActive({
    isPremium: true,
    effectiveExpiresAt: Timestamp.fromMillis(Date.now() - 60_000),
  }), false);
});

test('lifetime administrative Premium is never eligible for cleanup', () => {
  assert.equal(_test.effectivePremiumIsActive({
    isPremium: true,
    effectiveExpiresAt: null,
  }), true);
});

test('invite token hashes are deterministic and do not expose the token', () => {
  const token = 'private-invite-token';
  const hash = _test.hashToken(token);

  assert.equal(hash, _test.hashToken(token));
  assert.notEqual(hash, token);
  assert.match(hash, /^[a-f0-9]{64}$/);
});
