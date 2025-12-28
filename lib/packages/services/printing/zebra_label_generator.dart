// lib/services/printing/zebra_label_generator.dart

/// ZPL-Code Generator für Paket-Etiketten
/// Angepasst für Zebra ZD421t (300 DPI, max. 108mm Breite)
class ZebraLabelGenerator {
  // 300 DPI: 12 dots = 1mm
  static const int dpi = 300;
  static const double dotsPerMm = 12.0;

  /// Generiert ZPL für Standard-Paket-Etikett
  static String generatePackageLabel(Map<String, dynamic> data) {
    final barcode = data['Barcode']?.toString() ?? '';
    final kunde = _sanitize(data['Kunde']?.toString() ?? '');
    final kundeAlias = _sanitize(data['kundeAlias']?.toString() ?? '');
    final useAlias = data['useKundeAlias'] == true;
    final displayKunde = useAlias && kundeAlias.isNotEmpty ? kundeAlias : kunde;

    final holzart = _sanitize(data['Holzart']?.toString() ?? '');
    final h = data['H']?.toString() ?? '';
    final b = data['B']?.toString() ?? '';
    final l = data['L']?.toString() ?? '';
    final stk = data['Stk']?.toString() ?? '';
    final menge = data['Menge']?.toString() ?? '';
    final bemerkung = _sanitize(data['Bemerkung']?.toString() ?? '');
    final auftragsnr = data['Auftragsnr']?.toString() ?? '';
    final nrExt = data['Nr_ext']?.toString() ?? '';
    final bearb = _sanitize(data['Bearb']?.toString() ?? '');
    final saegerInitials = data['SaegerInitials']?.toString() ?? '';
    final sortiererInitials = data['SortiererInitials']?.toString() ?? '';
    final produkt = data['Produkt']?.toString() ?? '';

    // Maße formatieren
    final dimensions = '$h x $b x $l';
    final quantity = '$stk Stk / $menge m³';

    // Initiale für Mitarbeiter
    final workers = [saegerInitials, sortiererInitials]
        .where((s) => s.isNotEmpty)
        .join(' / ');

    return '''
^XA
^CI28
^PW1200
^LL600
^LH0,0

~SD${_getDarkness(data)}

^FO40,30^A0N,45,45^FD$displayKunde^FS

^FO40,90^A0N,30,30^FD$holzart${bearb.isNotEmpty ? ' - $bearb' : ''}^FS

^FO40,135^A0N,35,35^FD$dimensions^FS
^FO40,180^A0N,28,28^FD$quantity^FS

${auftragsnr.isNotEmpty ? '^FO40,225^A0N,24,24^FDAuftrag: $auftragsnr^FS' : ''}
${nrExt.isNotEmpty ? '^FO40,255^A0N,24,24^FDExt-Nr: $nrExt^FS' : ''}

${bemerkung.isNotEmpty ? '^FO40,295^A0N,22,22^FB600,2,0,L^FD$bemerkung^FS' : ''}

${workers.isNotEmpty ? '^FO40,350^A0N,20,20^FD$workers^FS' : ''}

^FO700,30^BQN,2,6^FDQA,$barcode^FS

^FO700,250^BY3^BCN,100,Y,N,N^FD$barcode^FS

${produkt.isNotEmpty ? '^FO700,380^A0N,24,24^FD$produkt^FS' : ''}

^FO40,420^GB1120,0,2^FS

^FO40,440^A0N,50,50^FDNr: $barcode^FS

^FO40,510^A0N,22,22^FD${DateTime.now().toString().substring(0, 16)}^FS

^XZ
''';
  }

  /// Generiert ZPL für Lamellen-Etikett
  static String generateLamellenLabel(Map<String, dynamic> data) {
    final barcode = data['Barcode']?.toString() ?? '';
    final kunde = _sanitize(data['Kunde']?.toString() ?? '');
    final holzart = _sanitize(data['Holzart']?.toString() ?? '');
    final h = data['H']?.toString() ?? '';
    final b = data['B']?.toString() ?? '';

    // Lamellen-Längen
    final lamellen = data['Lamellen'] as Map<String, dynamic>? ?? {};
    final l50 = lamellen['5.0']?.toString() ?? '0';
    final l45 = lamellen['4.5']?.toString() ?? '0';
    final l40 = lamellen['4.0']?.toString() ?? '0';
    final l35 = lamellen['3.5']?.toString() ?? '0';
    final l30 = lamellen['3.0']?.toString() ?? '0';

    return '''
^XA
^CI28
^PW1200
^LL500
^LH0,0

^FO40,30^A0N,40,40^FD$kunde^FS
^FO40,80^A0N,28,28^FD$holzart - $h x $b^FS

^FO40,130^A0N,24,24^FDLamellen:^FS

^FO40,165^A0N,22,22^FD5.0m: $l50^FS
^FO200,165^A0N,22,22^FD4.5m: $l45^FS
^FO360,165^A0N,22,22^FD4.0m: $l40^FS
^FO40,195^A0N,22,22^FD3.5m: $l35^FS
^FO200,195^A0N,22,22^FD3.0m: $l30^FS

^FO700,30^BQN,2,5^FDQA,$barcode^FS

^FO700,200^BY2^BCN,80,Y,N,N^FD$barcode^FS

^FO40,280^GB1120,0,2^FS

^FO40,300^A0N,45,45^FDNr: $barcode^FS

^XZ
''';
  }



  /// Generiert einfaches Barcode-Label
  static String generateBarcodeLabel(String barcode, {String? title}) {
    return '''
^XA
^CI28
^PW1200
^LL300
^LH0,0

${title != null ? '^FO40,30^A0N,30,30^FD${_sanitize(title)}^FS' : ''}

^FO40,80^BY3^BCN,120,Y,N,N^FD$barcode^FS

^FO700,50^BQN,2,5^FDQA,$barcode^FS

^XZ
''';
  }

  // Hilfsmethoden

  static String _sanitize(String text) {
    // ZPL-Sonderzeichen escapen
    return text
        .replaceAll('^', '')
        .replaceAll('~', '')
        .replaceAll('\\', '')
        .trim();
  }

  static int _getDarkness(Map<String, dynamic> data) {
    // Standard-Darkness, kann aus Einstellungen kommen
    return 15;
  }
}