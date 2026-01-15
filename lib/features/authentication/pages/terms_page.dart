import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Necessario per aprire il link

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  // Funzione per aprire il tuo link specifico
  Future<void> _launchPrivacyUrl() async {
    final Uri url = Uri.parse('https://www.privacypolicies.com/live/e1ceb6ca-a83e-4513-93bc-b9936ef66b8e');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      print("Impossibile aprire il link: $url");
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Termini e Privacy", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader("Informativa sulla Privacy e Termini di Servizio"),
            const SizedBox(height: 16),
            const Text(
              "Benvenuto in Magi Hair. La tua privacy è importante per noi. "
                  "Questa informativa riassume come raccogliamo, utilizziamo e proteggiamo i tuoi dati "
                  "all'interno dell'applicazione.",
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 24),

            _buildSectionTitle("1. Dati Raccolti", primaryColor),
            _buildBulletPoint("Nome e Cognome: Per identificare la prenotazione."),
            _buildBulletPoint("Numero di Telefono: Necessario per il login, confermare gli appuntamenti e contattarti in caso di variazioni."),

            const SizedBox(height: 24),
            _buildSectionTitle("2. Uso del Numero di Telefono", primaryColor),
            const Text(
              "Il tuo numero di telefono viene utilizzato ESCLUSIVAMENTE per gestire le tue prenotazioni "
                  "presso il salone Magi Hair. Non sarà mai venduto a terzi, né utilizzato per spam o marketing "
                  "senza il tuo esplicito consenso.",
              style: TextStyle(fontSize: 15, height: 1.5),
            ),

            const SizedBox(height: 24),
            _buildSectionTitle("3. Cancellazione Account", primaryColor),
            const Text(
              "Hai il diritto di richiedere la cancellazione completa del tuo account e di tutti i dati associati "
                  "in qualsiasi momento. Puoi farlo autonomamente tramite il pulsante 'Elimina il mio account' nella pagina Profilo dell'app.",
              style: TextStyle(fontSize: 15, height: 1.5),
            ),

            const SizedBox(height: 24),
            _buildSectionTitle("4. Contatti", primaryColor),
            const Text(
              "Per qualsiasi domanda riguardante la privacy, puoi contattarci presso:\n"
                  "Magi Hair - Via Reatina, 109, Mentana (RM)\n"
                  "Tel: +39 388 810 6944",
              style: TextStyle(fontSize: 15, height: 1.5, fontWeight: FontWeight.w500),
            ),

            const SizedBox(height: 30),
            const Divider(thickness: 1),
            const SizedBox(height: 20),

            // 🟢 LINK ALLA POLICY COMPLETA (Il tuo link generato)
            const Text(
              "Documentazione Legale Completa",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Per visualizzare il documento legale completo (Privacy Policy) ospitato esternamente, clicca qui sotto:",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Center(
              child: ElevatedButton.icon(
                onPressed: _launchPrivacyUrl,
                icon: const Icon(Icons.description, color: Colors.white),
                label: const Text("Apri Privacy Policy Completa", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
    );
  }

  Widget _buildSectionTitle(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Text(
        text,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 15, height: 1.4))),
        ],
      ),
    );
  }
}