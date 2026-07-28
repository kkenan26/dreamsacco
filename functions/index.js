const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

// ---------------------------------------------------------------------
// Loan limit upgrade thresholds. Tune these with Member 4 (credit
// scoring) so streak-based upgrades and credit-score-based limits don't
// conflict — this function only ever RAISES the limit, never lowers it.
// ---------------------------------------------------------------------
const STREAK_THRESHOLDS = [
  { streak: 12, multiplier: 3.0 },
  { streak: 6, multiplier: 2.0 },
  { streak: 3, multiplier: 1.5 },
];
const BASE_LOAN_LIMIT = 200000; // UGX, adjust to your group's base amount

/**
 * Fires whenever a contribution document is created or updated.
 * Recalculates the user's consecutive-payment streak by walking
 * backwards through their contribution history, then applies any
 * loan-limit upgrade the new streak unlocks.
 */
exports.onContributionWrite = functions.firestore
  .document("contributions/{contributionId}")
  .onWrite(async (change, context) => {
    const after = change.after.exists ? change.after.data() : null;
    if (!after) return null; // ignore deletes

    const { userId } = after;

    // Pull this user's full history, most recent month first.
    const historySnap = await db
      .collection("contributions")
      .where("userId", "==", userId)
      .orderBy("month", "desc")
      .get();

    const history = historySnap.docs.map((d) => d.data());

    // Walk backwards from the most recent month. Streak breaks the
    // moment we hit anything that isn't "paid" (treat "late" as
    // breaking it too — tune this rule with your team if "late" should
    // still count).
    let streak = 0;
    for (const record of history) {
      if (record.status === "paid") {
        streak += 1;
      } else {
        break;
      }
    }

    const userRef = db.collection("users").doc(userId);
    const userSnap = await userRef.get();
    const currentLoanLimit = userSnap.data()?.loanLimit || BASE_LOAN_LIMIT;

    // Find the highest threshold this streak qualifies for.
    let newLoanLimit = currentLoanLimit;
    for (const tier of STREAK_THRESHOLDS) {
      if (streak >= tier.streak) {
        const tierLimit = BASE_LOAN_LIMIT * tier.multiplier;
        if (tierLimit > newLoanLimit) newLoanLimit = tierLimit;
        break; // thresholds array is sorted highest-first, so first match wins
      }
    }

    const updates = { contributionStreak: streak };
    const limitUpgraded = newLoanLimit > currentLoanLimit;
    if (limitUpgraded) updates.loanLimit = newLoanLimit;

    await userRef.update(updates);

    // Notify on milestone (streak crossed a threshold this write).
    if (limitUpgraded) {
      await db.collection("notifications").add({
        type: "milestone",
        message: `🎉 ${streak}-month streak! Your loan limit is now ${newLoanLimit.toLocaleString()} UGX.`,
        targetUserId: userId,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        read: false,
      });

      const token = userSnap.data()?.fcmToken;
      if (token) {
        await messaging.send({
          token,
          notification: {
            title: "Loan limit upgraded!",
            body: `Your ${streak}-month streak just raised your loan limit to ${newLoanLimit.toLocaleString()} UGX.`,
          },
        });
      }
    }

    return null;
  });

/**
 * Runs once a day. For each active group, checks members who have not
 * yet paid this month:
 *   - a few days before the due date  -> sends a friendly FCM reminder
 *   - on/after the due date           -> marks them "missed" (which
 *                                        breaks their streak on the
 *                                        next onContributionWrite pass,
 *                                        since a missing doc means the
 *                                        history walk above simply
 *                                        won't find a "paid" record)
 *
 * Deploy with a schedule like: functions.pubsub.schedule("every day 08:00")
 */
exports.dailyContributionCheck = functions.pubsub
  .schedule("every day 08:00")
  .timeZone("Africa/Kampala")
  .onRun(async (context) => {
    const now = new Date();
    const month = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}`;
    const dayOfMonth = now.getDate();

    const groupsSnap = await db.collection("groups").get();

    for (const groupDoc of groupsSnap.docs) {
      const groupId = groupDoc.id;
      const dueDay = groupDoc.data().contributionDueDay || 5;

      const membersSnap = await db
        .collection("groups")
        .doc(groupId)
        .collection("members")
        .where("status", "==", "active")
        .get();

      for (const memberDoc of membersSnap.docs) {
        const userId = memberDoc.id;
        const contribDocId = `${groupId}_${userId}_${month}`;
        const contribSnap = await db.collection("contributions").doc(contribDocId).get();

        if (contribSnap.exists) continue; // already paid this month

        const userSnap = await db.collection("users").doc(userId).get();
        const token = userSnap.data()?.fcmToken;
        const userName = userSnap.data()?.name || "Member";

        if (dayOfMonth === dueDay - 3 || dayOfMonth === dueDay - 1) {
          // Reminder window
          if (token) {
            await messaging.send({
              token,
              notification: {
                title: "Contribution reminder",
                body: `Hi ${userName}, your contribution for ${month} is due soon.`,
              },
            });
          }
          await db.collection("notifications").add({
            type: "contribution_due",
            message: `Contribution for ${month} is due soon.`,
            targetUserId: userId,
            sentAt: admin.firestore.FieldValue.serverTimestamp(),
            read: false,
          });
        } else if (dayOfMonth === dueDay + 1) {
          // Past due — mark as missed. This write triggers
          // onContributionWrite above, which will recompute streak
          // (and it will reset to 0 since this record isn't "paid").
          await db.collection("contributions").doc(contribDocId).set({
            userId,
            groupId,
            amount: 0,
            month,
            paidAt: null,
            status: "missed",
          });
        }
      }
    }

    return null;
  }); c
