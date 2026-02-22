import 'dart:convert';
import 'package:http/http.dart' as http;

class PlacesService {
  static const String apiKey = "AIzaSyCTN8h73sVywgIk8DIxiWCHJ-ygHPHJj1A";

  static Future<List<dynamic>> getNearbyRestaurants(
      double lat, double lng) async {

    final url =
        "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
        "?location=$lat,$lng"
        "&radius=3000"
        "&type=restaurant"
        "&key=$apiKey";

    final res = await http.get(Uri.parse(url));
    final data = jsonDecode(res.body);

    return data["results"];
  }
}