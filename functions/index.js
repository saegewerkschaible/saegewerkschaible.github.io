const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

initializeApp();
const db = getFirestore();

// ══════════════════════════════════════════════════════════════════════════════
// HELPER: Interne Email (an Mitarbeiter)
// ══════════════════════════════════════════════════════════════════════════════
function buildInternalEmailHtml(deliveryNote, formattedDate, totalVolume) {
  return `
    <!DOCTYPE html>
    <html>
    <head><meta charset="utf-8"></head>
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
          <p style="color: #666; font-size: 14px;">
            📎 PDF und JSON-Export im Anhang
          </p>
        </div>
        <div style="background: #f8f8f8; padding: 20px; text-align: center; border-radius: 0 0 8px 8px; color: #666;">
          Mit freundlichen Grüßen<br>Sägewerk Schaible
        </div>
      </div>
    </body>
    </html>
  `;
}

// ══════════════════════════════════════════════════════════════════════════════
// HELPER: Kunden-Email (freundlicher, mit Dank)
// ══════════════════════════════════════════════════════════════════════════════
function buildCustomerEmailHtml(deliveryNote, formattedDate, totalVolume, attachmentInfo) {
  return `
    <!DOCTYPE html>
    <html>
    <head><meta charset="utf-8"></head>
    <body style="font-family: Arial, sans-serif; background: #f5f5f5; margin: 0; padding: 20px;">
      <div style="max-width: 600px; margin: auto; background: white; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
        <div style="background: #00897B; color: white; padding: 20px; border-radius: 8px 8px 0 0; text-align: center;">
          <h1 style="margin: 0;">Ihr Lieferschein</h1>
        </div>
        <div style="padding: 30px;">
          <p style="color: #333; font-size: 16px;">
            Guten Tag,
          </p>
          <p style="color: #333; font-size: 16px;">
            vielen Dank für Ihren Einkauf! Anbei erhalten Sie Ihren Lieferschein${attachmentInfo}.
          </p>

          <div style="background: #f8f8f8; border-radius: 8px; padding: 20px; margin: 20px 0;">
            <h2 style="margin-top: 0; color: #00897B;">Zusammenfassung:</h2>
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
                <td style="padding: 10px 0; font-weight: bold; color: #666;">Anzahl Stück:</td>
                <td style="padding: 10px 0; color: #333;">${deliveryNote.totalQuantity || 0} Stk</td>
              </tr>
              <tr>
                <td style="padding: 10px 0; font-weight: bold; color: #666;">Gesamtvolumen:</td>
                <td style="padding: 10px 0; color: #333;">${totalVolume} m³</td>
              </tr>
            </table>
          </div>

          <p style="color: #666; font-size: 14px;">
            Bei Fragen stehen wir Ihnen gerne zur Verfügung.
          </p>
        </div>
        <div style="background: #f8f8f8; padding: 20px; text-align: center; border-radius: 0 0 8px 8px;">
          <p style="margin: 0 0 10px 0; color: #333; font-weight: bold;">Sägewerk Schaible</p>
          <p style="margin: 0; color: #666; font-size: 13px;">
            Hagelenweg 1a · 78652 Deißlingen<br>
            Tel: 07420-1332 · info@saegewerk-schaible.de
          </p>
        </div>
      </div>
    </body>
    </html>
  `;
}

// ══════════════════════════════════════════════════════════════════════════════
// MAIN FUNCTION: Lieferschein Email Trigger
// ══════════════════════════════════════════════════════════════════════════════
exports.sendDeliveryNoteEmail = onDocumentCreated(
  {
    document: "delivery_notes/{docId}",
    region: "europe-west1",
  },
  async (event) => {
    const deliveryNote = event.data.data();
    console.log("📥 Neuer Lieferschein:", deliveryNote.number);

    try {
      const formattedDate = new Date().toLocaleDateString("de-DE");
      const totalVolume = (deliveryNote.totalVolume || 0).toFixed(3);

      // ────────────────────────────────────────────────────────────────────────
      // 1. Alle Anhänge vorbereiten (für interne Empfänger)
      // ────────────────────────────────────────────────────────────────────────
      const allAttachments = [];

      if (deliveryNote.pdfUrl) {
        allAttachments.push({
          filename: `Lieferschein_${deliveryNote.number}.pdf`,
          path: deliveryNote.pdfUrl,
        });
      }

      if (deliveryNote.jsonUrl) {
        allAttachments.push({
          filename: `Lieferschein_${deliveryNote.number}.json`,
          path: deliveryNote.jsonUrl,
        });
      }

      // ────────────────────────────────────────────────────────────────────────
      // 2. Interne Empfänger (Mitarbeiter) - bekommen immer PDF + JSON
      // ────────────────────────────────────────────────────────────────────────
      const settingsDoc = await db
        .collection("settings")
        .doc("delivery_note_emails")
        .get();

      const internalRecipients = settingsDoc.exists
        ? (settingsDoc.data().recipients || [])
            .filter((r) => r.receivesCopy === true)
            .map((r) => r.email)
        : [];

      if (internalRecipients.length > 0) {
        console.log("📧 Interne Empfänger:", internalRecipients);

        await db.collection("mail").add({
          to: internalRecipients,
          message: {
            subject: `Lieferschein Nr. ${deliveryNote.number} - ${deliveryNote.customerName || ""}`,
            html: buildInternalEmailHtml(deliveryNote, formattedDate, totalVolume),
            attachments: allAttachments,
          },
        });
      }

      // ────────────────────────────────────────────────────────────────────────
      // 3. Kunden-Email (basierend auf emailSettings)
      // ────────────────────────────────────────────────────────────────────────
      const customerEmail = deliveryNote.customerData?.email;
      const emailSettings = deliveryNote.customerData?.emailSettings || {};

      // Prüfe ob Email-Versand aktiviert ist
      const receivesDeliveryNote = emailSettings.receivesDeliveryNote === true;
      const sendPdf = emailSettings.sendPdf !== false; // Default: true
      const sendJson = emailSettings.sendJson === true; // Default: false

      if (customerEmail && receivesDeliveryNote) {
        console.log("📧 Kunde erhält Kopie:", customerEmail);
        console.log("   → PDF:", sendPdf, "| JSON:", sendJson);

        // Anhänge für Kunden basierend auf Einstellungen
        const customerAttachments = [];
        const attachmentParts = [];

        if (sendPdf && deliveryNote.pdfUrl) {
          customerAttachments.push({
            filename: `Lieferschein_${deliveryNote.number}.pdf`,
            path: deliveryNote.pdfUrl,
          });
          attachmentParts.push("PDF");
        }

        if (sendJson && deliveryNote.jsonUrl) {
          customerAttachments.push({
            filename: `Lieferschein_${deliveryNote.number}.json`,
            path: deliveryNote.jsonUrl,
          });
          attachmentParts.push("Daten-Export");
        }

        // Info-Text für Email erstellen
        let attachmentInfo = "";
        if (attachmentParts.length > 0) {
          attachmentInfo = ` (${attachmentParts.join(" und ")})`;
        }

        if (customerAttachments.length > 0) {
          await db.collection("mail").add({
            to: [customerEmail],
            message: {
              subject: `Ihr Lieferschein Nr. ${deliveryNote.number} - Sägewerk Schaible`,
              html: buildCustomerEmailHtml(deliveryNote, formattedDate, totalVolume, attachmentInfo),
              attachments: customerAttachments,
            },
          });

          // Kunden-Email Status speichern
          await event.data.ref.update({
            customerEmailSentTo: customerEmail,
            customerEmailSentAt: FieldValue.serverTimestamp(),
            customerEmailAttachments: {
              pdf: sendPdf && !!deliveryNote.pdfUrl,
              json: sendJson && !!deliveryNote.jsonUrl,
            },
          });
        } else {
          console.log("⚠️ Keine Anhänge für Kunde konfiguriert");
        }
      } else if (customerEmail && !receivesDeliveryNote) {
        console.log("ℹ️ Kunden-Email deaktiviert für:", customerEmail);
      }

      // ────────────────────────────────────────────────────────────────────────
      // 4. Status aktualisieren
      // ────────────────────────────────────────────────────────────────────────
      await event.data.ref.update({
        emailSentAt: FieldValue.serverTimestamp(),
        emailRecipients: internalRecipients,
      });

      console.log("✅ Emails verarbeitet");
      return null;
    } catch (error) {
      console.error("❌ Fehler:", error);
      throw error;
    }
  }
);