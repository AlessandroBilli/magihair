import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class InfoPage extends StatelessWidget {
  const InfoPage({super.key});

  // Funzione helper per lanciare gli URL (Telefono, Mappa, Social)
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      await launchUrl(uri, mode: LaunchMode.inAppWebView);
    }
  }

  // Helper per il titolo della sezione
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 28.0, bottom: 12.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w900,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Info & Contatti', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: SingleChildScrollView( // 🟢 Permette lo scroll verticale se i contenuti sono troppi
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // --- Sezione HERO ---
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.05),
                border: Border(bottom: BorderSide(color: primaryColor, width: 2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(
                    'assets/img/Logooffmagi.png',
                    height: 60,
                    color: primaryColor,
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    "Il tuo momento Beauty & Wellness senza attese. Prenota subito, il tuo stile ti aspetta..",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // --- Sezione Contatti & Orari ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildSectionTitle(context, "Contatti Utili"),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    _buildContactTile(
                      context,
                      icon: Icons.location_on,
                      title: "Dove Trovarci",
                      subtitle: "Via Reatina, 109, 00013 Mentana RM",
                      onTap: () => _launchUrl('https://www.google.com/maps/search/?api=1&query=Via+Reatina+109+Mentana'),
                    ),
                    const Divider(height: 0, indent: 72, endIndent: 16),
                    _buildContactTile(
                      context,
                      icon: Icons.phone_in_talk,
                      title: "Chiamaci Subito",
                      subtitle: "+39 388 810 6944",
                      onTap: () => _launchUrl('tel:+393888106944'),
                    ),
                    const Divider(height: 0, indent: 72, endIndent: 16),
                    _buildContactTile(
                      context,
                      icon: Icons.access_time_filled,
                      title: "Orari di Apertura:",
                      subtitle: """
Lunedì: Chiuso
Martedì: 09:00–13:00 / 15:30–19:00
Mercoledì: 09:00–13:00 / 15:30–19:00
Giovedì: 09:00–13:00 / 14:00–19:00
Venerdì: 09:00–13:00 / 15:30–19:00
Sabato: 09:00–18:00
Domenica: Chiuso
""",
                      onTap: null,
                    ),
                  ],
                ),
              ),
            ),

            // --- Sezione Social (Fixata con Wrap) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildSectionTitle(context, "Seguici qui:"),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0), // Padding ridotto per ottimizzare
                  child: Wrap( // 🟢 FIX: Wrap manda le icone a capo se lo spazio finisce
                    alignment: WrapAlignment.spaceEvenly,
                    spacing: 10, // Spazio orizzontale tra i pulsanti
                    runSpacing: 15, // Spazio verticale se vanno a capo
                    children: [
                      _buildSocialButton(
                        context,
                        icon: FontAwesomeIcons.instagram,
                        color: const Color(0xFFC13584),
                        label: 'Instagram',
                        url: 'https://www.instagram.com/magihair.mentana/',
                      ),
                      _buildSocialButton(
                        context,
                        icon: FontAwesomeIcons.facebookF,
                        color: const Color(0xFF1877F2),
                        label: 'Facebook',
                        url: 'https://www.facebook.com/p/Magihair-100063529363992/',
                      ),
                      _buildSocialButton(
                        context,
                        icon: FontAwesomeIcons.whatsapp,
                        color: const Color(0xFF25D366),
                        label: 'WhatsApp',
                        url: 'https://wa.me/393888106944',
                      ),
                      _buildSocialButton(
                        context,
                        icon: FontAwesomeIcons.tiktok,
                        color: Colors.black,
                        label: 'Tiktok',
                        url: 'https://www.tiktok.com/@magihair.mentana',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildContactTile(BuildContext context, {required IconData icon, required String title, required String subtitle, VoidCallback? onTap}) {
    final primaryColor = Theme.of(context).primaryColor;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: primaryColor, size: 24),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      // 🟢 Fix per testi orario/indirizzo lunghi: permette di andare a capo senza errori
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade700)),
      trailing: onTap != null ? Icon(Icons.chevron_right, color: primaryColor) : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
    );
  }

  Widget _buildSocialButton(BuildContext context, {required IconData icon, required Color color, required String label, required String url}) {
    return InkWell(
      onTap: () => _launchUrl(url),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 75, // 🟢 Larghezza fissa per ogni tasto per un allineamento pulito nel Wrap
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(icon, size: 32.0, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}