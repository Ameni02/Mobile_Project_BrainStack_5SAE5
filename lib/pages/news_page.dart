import 'package:flutter/material.dart';
import '../services/news_service.dart';
import 'package:url_launcher/url_launcher.dart';

class NewsPage extends StatefulWidget {
  const NewsPage({super.key});

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  List<dynamic>? articles;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadNews();
  }

  Future<void> loadNews() async {
    setState(() => isLoading = true);
    try {
      articles = await NewsService.fetchBusinessNews(country: 'us');
    } catch (e) {
      print('Erreur: $e');
      articles = [];
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Economic News"),
        backgroundColor: const Color(0xFF4A90E2),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : articles == null || articles!.isEmpty
          ? const Center(child: Text("No news found"))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: articles!.length,
        itemBuilder: (context, index) {
          final article = articles![index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              title: Text(article['title'] ?? ''),
              subtitle: Text(article['source']['name'] ?? ''),
              onTap: () async {
                final url = article['url'];
                if (url != null && await canLaunch(url)) {
                  await launch(url);
                }
              },
            ),
          );
        },
      ),
    );
  }
}
