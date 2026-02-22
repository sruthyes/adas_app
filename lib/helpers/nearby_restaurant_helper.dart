import 'package:flutter/material.dart';
import '../services/location_service.dart';
import '../services/places_service.dart';
import 'package:url_launcher/url_launcher.dart';

class NearbyRestaurantHelper {

  static Future<void> showNearby(BuildContext context) async {

    final position =
        await LocationService.getCurrentLocation();

    final places =
        await PlacesService.getNearbyRestaurants(
          position.latitude,
          position.longitude,
        );

    showModalBottomSheet(
      context: context,
      builder: (_) => ListView.builder(
        itemCount: places.length,
        itemBuilder: (_, index) {

          final place = places[index];

          return ListTile(
            leading: const Icon(Icons.restaurant),
            title: Text(place["name"]),
            subtitle: Text(place["vicinity"] ?? ""),
            onTap: () {
              final lat =
                  place["geometry"]["location"]["lat"];
              final lng =
                  place["geometry"]["location"]["lng"];

              final url =
                  "https://www.google.com/maps/dir/?api=1"
                  "&destination=$lat,$lng";

              launchUrl(Uri.parse(url));
            },
          );
        },
      ),
    );
  }
}