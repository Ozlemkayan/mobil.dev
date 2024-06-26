import 'package:flutter/material.dart';
import 'dart:convert';

// Mock http.get function
Future<MockHttpResponse> mockHttpGet(Uri url) async {
  if (url.path.contains('categories')) {
    return MockHttpResponse(
      json.encode(['Action', 'Drama', 'Comedy']),
      200,
    );
  } else if (url.path.contains('films')) {
    return MockHttpResponse(
      json.encode([
        {
          'id': '1',
          'title': 'Film 1',
          'director': 'Director 1',
          'actors': ['Actor 1', 'Actor 2'],
          'imageUrl': 'https://via.placeholder.com/150'
        },
        {
          'id': '2',
          'title': 'Film 2',
          'director': 'Director 2',
          'actors': ['Actor 3', 'Actor 4'],
          'imageUrl': 'https://via.placeholder.com/150'
        }
      ]),
      200,
    );
  } else {
    return MockHttpResponse('Not Found', 404);
  }
}

class MockHttpResponse {
  final String body;
  final int statusCode;
  MockHttpResponse(this.body, this.statusCode);
}

class http {
  static Future<MockHttpResponse> get(Uri url) => mockHttpGet(url);
}

void main() => runApp(MyApp());

class Film {
  final String id;
  final String title;
  final String director;
  final List<String> actors;
  final String imageUrl;

  Film({
    required this.id,
    required this.title,
    required this.director,
    required this.actors,
    required this.imageUrl,
  });

  factory Film.fromJson(Map<String, dynamic> json) {
    return Film(
      id: json['id'],
      title: json['title'],
      director: json['director'],
      actors: List<String>.from(json['actors']),
      imageUrl: json['imageUrl'],
    );
  }
}

class ApiService {
  static const String apiUrl = 'https://api.example.com'; // Gerçek API URL'si ile değiştirilmelidir

  Future<List<String>> getCategories() async {
    final response = await http.get(Uri.parse('$apiUrl/categories'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return List<String>.from(data);
    } else {
      throw Exception('Kategorileri getirirken hata oluştu.');
    }
  }

  Future<List<Film>> getFilmsByCategory(String category) async {
    final response = await http.get(Uri.parse('$apiUrl/films?category=$category'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((filmJson) => Film.fromJson(filmJson)).toList();
    } else {
      throw Exception('Filmleri getirirken hata oluştu.');
    }
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter API Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: CategoryScreen(),
    );
  }
}

class CategoryScreen extends StatelessWidget {
  final ApiService apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kategoriler'),
      ),
      body: FutureBuilder<List<String>>(
        future: apiService.getCategories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Hata oluştu: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Kategori bulunamadı.'));
          }

          List<String> categories = snapshot.data!;

          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(categories[index]),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailScreen(category: categories[index]),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class DetailScreen extends StatelessWidget {
  final String category;
  final ApiService apiService = ApiService();

  DetailScreen({required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$category Filmleri'),
      ),
      body: FutureBuilder<List<Film>>(
        future: apiService.getFilmsByCategory(category),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Hata oluştu: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Film bulunamadı.'));
          }

          List<Film> films = snapshot.data!;

          return ListView.builder(
            itemCount: films.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(films[index].title),
                subtitle: Text(films[index].director),
                leading: Hero(
                  tag: films[index].id,
                  child: Image.network(films[index].imageUrl, width: 50, height: 50, fit: BoxFit.cover),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FilmDetailScreen(film: films[index]),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class FilmDetailScreen extends StatelessWidget {
  final Film film;

  FilmDetailScreen({required this.film});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(film.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Hero(
              tag: film.id,
              child: Image.network(film.imageUrl, width: 200, height: 300, fit: BoxFit.cover),
            ),
            SizedBox(height: 20),
            Text('Yönetmen: ${film.director}', style: TextStyle(fontSize: 20)),
            SizedBox(height: 20),
            Text('Oyuncular:', style: TextStyle(fontSize: 18)),
            ...film.actors.map((actor) => Text(actor, style: TextStyle(fontSize: 16))),
          ],
        ),
      ),
    );
  }
}