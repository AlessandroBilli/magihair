const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
admin.initializeApp();

exports.notificaNuovaPrenotazione = onDocumentCreated("bookings/{bookingId}", async (event) => {
    const snap = event.data;
    if (!snap) return null;

    const data = snap.data();
    console.log("DEBUG: Ricevuta nuova prenotazione:", JSON.stringify(data));

    const cliente = data.userName || "Un cliente";
    const servizio = data.treatment ? data.treatment.name : "un servizio";

    const payload = {
        notification: {
            title: 'Nuova Prenotazione! ✂️',
            body: `${cliente} ha prenotato: ${servizio}`,
        },
        topic: 'admin_bookings',
    };

    try {
        const response = await admin.messaging().send(payload);
        console.log("✅ SUCCESS: Notifica inviata al topic. ID messaggio:", response);
    } catch (error) {
        console.error("❌ ERROR invio notifica:", error);
    }
});