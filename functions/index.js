const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

initializeApp();
const db = getFirestore();

exports.sendDeliveryNoteEmail = onDocumentCreated(
  {
    document: "delivery_notes/{docId}",
    region: "europe-west1",
  },
  async (event) => {
    const deliveryNote = event.data.data();
    console.log("🔥 Neuer Lieferschein:", deliveryNote.number);

    try {
      // Email-Empfänger holen
      const settingsDoc = await db
        .collection("settings")
        .doc("delivery_note_emails")
        .get();

      if (!settingsDoc.exists) {
        console.log("Keine Email-Einstellungen gefunden");
        return null;
      }

      const recipients = (settingsDoc.data().recipients || [])
        .filter((r) => r.receivesCopy === true)
        .map((r) => r.email);

      if (recipients.length === 0) {
        console.log("Keine aktiven Empfänger");
        return null;
      }

      console.log("Sende an:", recipients);

      const formattedDate = new Date().toLocaleDateString("de-DE");
      const totalVolume = (deliveryNote.totalVolume || 0).toFixed(3);

      const emailHtml = `
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
        </head>
        <body style="font-family: Arial, sans-serif; background: #f5f5f5; margin: 0; padding: 20px;">
          <div style="max-width: 600px; margin: auto; background: white; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
            <div style="background: #00897B; color: white; padding: 20px; border-radius: 8px 8px 0 0; text-align: center;">
              <h1 style="margin: 0;">Neuer Lieferschein</h1>
            </div>
            <div style="padding: 30px;">
              <div style="background: #f8f8f8; border-radius: 8px; padding: 20px; margin: 20px 0;">
                <h2 style="margin-top: 0;">Details:</h2>
                <table style="width: 100%; border-collapse: collapse;">
                  <tr style="border-bottom: 1px solid #eee;">
                    <td style="padding: 10px 0; font-weight: bold; color: #666;">Lieferschein-Nr.:</td>
                    <td style="padding: 10px 0; color: #333;">${deliveryNote.number || "-"}</td>
                  </tr>
                  <tr style="border-bottom: 1px solid #eee;">
                    <td style="padding: 10px 0; font-weight: bold; color: #666;">Datum:</td>
                    <td style="padding: 10px 0; color: #333;">${formattedDate}</td>
                  </tr>
                  <tr style="border-bottom: 1px solid #eee;">
                    <td style="padding: 10px 0; font-weight: bold; color: #666;">Kunde:</td>
                    <td style="padding: 10px 0; color: #333;">${deliveryNote.customerName || "-"}</td>
                  </tr>
                  <tr style="border-bottom: 1px solid #eee;">
                    <td style="padding: 10px 0; font-weight: bold; color: #666;">Anzahl:</td>
                    <td style="padding: 10px 0; color: #333;">${deliveryNote.totalQuantity || 0} Stk</td>
                  </tr>
                  <tr>
                    <td style="padding: 10px 0; font-weight: bold; color: #666;">Volumen:</td>
                    <td style="padding: 10px 0; color: #333;">${totalVolume} m³</td>
                  </tr>
                </table>
              </div>
              ${deliveryNote.pdfUrl ? "<p>Den Lieferschein finden Sie im Anhang.</p>" : ""}
            </div>
            <div style="background: #f8f8f8; padding: 20px; text-align: center; border-radius: 0 0 8px 8px; color: #666;">
              Mit freundlichen Grüßen<br>Sägewerk Schaible
            </div>
          </div>
        </body>
        </html>
      `;

      // Email in mail-Collection schreiben
      await db.collection("mail").add({
        to: recipients,
        message: {
          subject: `Lieferschein Nr. ${deliveryNote.number} - ${deliveryNote.customerName || ""}`,
          html: emailHtml,
          attachments: deliveryNote.pdfUrl
            ? [
                {
                  filename: `Lieferschein_${deliveryNote.number}.pdf`,
                  path: deliveryNote.pdfUrl,
                },
              ]
            : [],
        },
      });

      // Status aktualisieren
      await event.data.ref.update({
        emailSentAt: FieldValue.serverTimestamp(),
        emailRecipients: recipients,
      });

      console.log("✅ Email getriggert");
      return null;
    } catch (error) {
      console.error("❌ Fehler:", error);
      throw error;
    }
  }
);