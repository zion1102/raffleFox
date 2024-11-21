const functions = require('firebase-functions');



const admin = require('firebase-admin');
admin.initializeApp();

exports.sendNewRaffleNotification = functions.firestore
  .document('/raffles/{raffleId}')
  .onCreate(async (snapshot, context) => {
    const raffleData = snapshot.data();

    if (!raffleData) {
      console.error('No raffle data found.');
      return;
    }

    const message = {
      notification: {
        title: "New Raffle Added!",
        body: `Check out the new raffle: ${raffleData.title}`,
      },
      topic: "all_users",
    };

    try {
      await admin.messaging().send(message);
      console.log("Notification sent for new raffle:", raffleData.title);
    } catch (error) {
      console.error("Error sending notification:", error);
    }
  });


  exports.scheduleRaffleNotifications = functions.pubsub
  .schedule('0 * * * *') // Correct cron syntax for "every hour"
  .timeZone('UTC') // Specify a valid timezone
  .onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();
    const oneHourLater = admin.firestore.Timestamp.fromMillis(now.toMillis() + 60 * 60 * 1000);
    const twentyFourHoursLater = admin.firestore.Timestamp.fromMillis(now.toMillis() + 24 * 60 * 60 * 1000);

    const rafflesSnapshot = await admin.firestore().collection('raffles')
      .where('expiryDate', '<=', twentyFourHoursLater)
      .where('expiryDate', '>=', now)
      .get();

    const notificationPromises = rafflesSnapshot.docs.map(async (doc) => {
      const raffle = doc.data();

      let notificationTitle, notificationBody;

      if (raffle.expiryDate.toDate() <= oneHourLater.toDate()) {
        notificationTitle = `Raffle "${raffle.title}" is Ending Soon!`;
        notificationBody = `This raffle is ending in 1 hour! Don't miss your chance!`;
      } else {
        notificationTitle = `Raffle "${raffle.title}" is Ending Soon!`;
        notificationBody = `This raffle is ending in 24 hours! Act now before it's too late.`;
      }

      const message = {
        notification: {
          title: notificationTitle,
          body: notificationBody,
        },
        topic: 'raffle_notifications',
      };

      try {
        await admin.messaging().send(message);
        console.log(`Notification sent for raffle: ${raffle.title}`);
      } catch (error) {
        console.error(`Error sending notification for raffle: ${raffle.title}`, error);
      }
    });

    await Promise.all(notificationPromises);
  });
