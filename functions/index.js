const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

exports.notificaNuovaPrenotazione = onDocumentCreated("bookings/{bookingId}", async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const data = snapshot.data();

    // 1. IDENTIFICHIAMO IL TIPO DI PRENOTAZIONE
    // Usiamo l'ID fittizio che abbiamo impostato nel MainScreen per l'eccezione
    const isManualAdminEntry = data.userId === 'prenotazione_terzi';

    // 2. RECUPERO DATI (Nome, Trattamento, Data)
    const customerName = data.userName || "Un cliente";
    const treatmentName = (data.treatment && data.treatment.name) ? data.treatment.name : "Servizio";

    let dateStr = "";
    try {
        if (data.date) {
            const date = data.date.toDate();
            const day = String(date.getDate()).padStart(2, '0');
            const month = String(date.getMonth() + 1).padStart(2, '0');
            const hours = String(date.getHours()).padStart(2, '0');
            const minutes = String(date.getMinutes()).padStart(2, '0');
            dateStr = `${day}/${month} alle ${hours}:${minutes}`;
        }
    } catch (e) {
        dateStr = "Data non disponibile";
    }

    // 3. LOGICA DIFFERENZIATA PER IL LAYOUT DELLA NOTIFICA
    let notificationTitle = "";
    let notificationBody = "";

    if (isManualAdminEntry) {
        // COMPORTAMENTO A: Admin inserisce per terzi
        notificationTitle = "Appuntamento Inserito 📝";
        notificationBody = `Hai segnato un appuntamento per: ${customerName}\nServizio: ${treatmentName}\nData: ${dateStr}`;
    } else {
        // COMPORTAMENTO B: Prenotazione normale (Cliente o Admin per sé)
        notificationTitle = "Nuova Prenotazione! ✂️";
        notificationBody = `Cliente: ${customerName}\nServizio: ${treatmentName}\nIl ${dateStr}`;
    }

    // 4. COSTRUZIONE MESSAGGIO (Formato V1 - Obbligatorio per farle funzionare)
    const message = {
        notification: {
            title: notificationTitle,
            body: notificationBody
        },
        android: {
            notification: {
                sound: 'default',
                // Necessario per gestire il click sulla notifica
                clickAction: 'FLUTTER_NOTIFICATION_CLICK'
            }
        },
        apns: {
            payload: {
                aps: {
                    sound: 'default'
                }
            }
        },
        topic: 'admin_bookings'
    };

    try {
        // Invio tramite le nuove API
        const response = await getMessaging().send(message);
        console.log(`Notifica inviata con successo (${isManualAdminEntry ? 'Manuale' : 'Standard'}). ID: ${response}`);
    } catch (error) {
        console.error('Errore durante l\'invio della notifica:', error);
    }
});