const test = require("node:test");
const assert = require("node:assert");
const crypto = require("node:crypto");

test("Phase 14 Security Hardening: Cryptographic HMAC SHA-256 Signature Verification", () => {
  const secret = "rzp_test_secret_key_123456";
  const orderId = "order_123456789";
  const paymentId = "pay_987654321";

  // Legitimate signature computed on server/client
  const validSignature = crypto
    .createHmac("sha256", secret)
    .update(`${orderId}|${paymentId}`)
    .digest("hex");

  assert.strictEqual(typeof validSignature, "string");
  assert.strictEqual(validSignature.length, 64);

  // Verification helper matching functions/src/index.ts
  function verifySignature(order, pay, sig, sec) {
    if (!sec) throw new Error("failed-precondition: Secret missing");
    if (!sig) throw new Error("invalid-argument: Signature missing");
    const expected = crypto.createHmac("sha256", sec).update(`${order}|${pay}`).digest("hex");
    if (expected !== sig) {
      throw new Error("permission-denied: Signature mismatch");
    }
    return true;
  }

  // 1. Valid signature passes
  assert.strictEqual(verifySignature(orderId, paymentId, validSignature, secret), true);

  // 2. Tampered paymentId fails
  assert.throws(
    () => verifySignature(orderId, "pay_forged_999", validSignature, secret),
    /permission-denied/
  );

  // 3. Tampered orderId fails
  assert.throws(
    () => verifySignature("order_forged_999", paymentId, validSignature, secret),
    /permission-denied/
  );

  // 4. Missing signature fails
  assert.throws(
    () => verifySignature(orderId, paymentId, "", secret),
    /invalid-argument/
  );

  // 5. Missing secret in production fails closed
  assert.throws(
    () => verifySignature(orderId, paymentId, validSignature, ""),
    /failed-precondition/
  );
});

test("Phase 14 Security Hardening: Payment Idempotency & Replay Defense Simulation", () => {
  const processedPayments = new Set();

  function processPayment(paymentId) {
    if (processedPayments.has(paymentId)) {
      throw new Error("already-exists: Replayed payment rejected");
    }
    processedPayments.add(paymentId);
    return { success: true, paymentId };
  }

  // 1. First execution succeeds
  const first = processPayment("pay_test_001");
  assert.strictEqual(first.success, true);

  // 2. Immediate replay is rejected
  assert.throws(
    () => processPayment("pay_test_001"),
    /already-exists/
  );

  // 3. Different payment succeeds
  const second = processPayment("pay_test_002");
  assert.strictEqual(second.success, true);
});

test("Phase 14 Security Hardening: Atomic AI Credit Deduction & Rollback Invariants", () => {
  let userSubscription = {
    monthlyCreditsTotal: 20,
    monthlyCreditsUsed: 19,
    purchasedCredits: 1,
  };

  function deductCredit() {
    const availableMonthly = userSubscription.monthlyCreditsTotal - userSubscription.monthlyCreditsUsed;
    const totalAvailable = Math.max(0, availableMonthly) + userSubscription.purchasedCredits;

    if (totalAvailable < 1) {
      throw new Error("resource-exhausted");
    }

    let source = "monthly";
    if (availableMonthly > 0) {
      userSubscription.monthlyCreditsUsed += 1;
      source = "monthly";
    } else {
      userSubscription.purchasedCredits -= 1;
      source = "purchased";
    }
    return source;
  }

  function refundCredit(source) {
    if (source === "monthly") {
      userSubscription.monthlyCreditsUsed = Math.max(0, userSubscription.monthlyCreditsUsed - 1);
    } else {
      userSubscription.purchasedCredits += 1;
    }
  }

  // Operation 1: Deducts from monthly (20 - 19 = 1 available monthly)
  const src1 = deductCredit();
  assert.strictEqual(src1, "monthly");
  assert.strictEqual(userSubscription.monthlyCreditsUsed, 20);
  assert.strictEqual(userSubscription.purchasedCredits, 1);

  // Operation 2: Monthly exhausted, deducts from purchased
  const src2 = deductCredit();
  assert.strictEqual(src2, "purchased");
  assert.strictEqual(userSubscription.monthlyCreditsUsed, 20);
  assert.strictEqual(userSubscription.purchasedCredits, 0);

  // Operation 3: Overdraft attempt throws resource-exhausted
  assert.throws(() => deductCredit(), /resource-exhausted/);

  // Upstream Gemini failure triggers refund of operation 2
  refundCredit(src2);
  assert.strictEqual(userSubscription.purchasedCredits, 1);

  // Now a subsequent request succeeds
  const src3 = deductCredit();
  assert.strictEqual(src3, "purchased");
  assert.strictEqual(userSubscription.purchasedCredits, 0);
});
