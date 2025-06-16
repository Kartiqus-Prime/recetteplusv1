class TimeFormatter {
  /// Formate une durée au format hh:mm:ss en texte lisible
  static String formatDuration(String? duration) {
    if (duration == null || duration.isEmpty) {
      return '';
    }

    try {
      // Nettoyer la chaîne et extraire les parties numériques
      String cleanDuration = duration.toLowerCase().replaceAll(RegExp(r'[^\d:]'), '');
      
      // Si c'est déjà au format numérique simple (ex: "30"), on assume que c'est en minutes
      if (RegExp(r'^\d+$').hasMatch(cleanDuration)) {
        int minutes = int.parse(cleanDuration);
        return _formatMinutes(minutes);
      }

      // Parser le format hh:mm:ss ou mm:ss
      List<String> parts = cleanDuration.split(':');
      
      if (parts.length == 3) {
        // Format hh:mm:ss
        int hours = int.parse(parts[0]);
        int minutes = int.parse(parts[1]);
        int seconds = int.parse(parts[2]);
        
        // Convertir tout en minutes (arrondir les secondes)
        int totalMinutes = hours * 60 + minutes + (seconds >= 30 ? 1 : 0);
        return _formatMinutes(totalMinutes);
        
      } else if (parts.length == 2) {
        // Format mm:ss (on assume que c'est minutes:secondes)
        int minutes = int.parse(parts[0]);
        int seconds = int.parse(parts[1]);
        
        // Arrondir les secondes
        int totalMinutes = minutes + (seconds >= 30 ? 1 : 0);
        return _formatMinutes(totalMinutes);
        
      } else {
        // Format non reconnu, essayer d'extraire les nombres
        RegExp regExp = RegExp(r'(\d+)');
        Iterable<Match> matches = regExp.allMatches(duration);
        if (matches.isNotEmpty) {
          int firstNumber = int.parse(matches.first.group(1) ?? '0');
          return _formatMinutes(firstNumber);
        }
      }
    } catch (e) {
      // En cas d'erreur, essayer d'extraire le premier nombre trouvé
      RegExp regExp = RegExp(r'(\d+)');
      Match? match = regExp.firstMatch(duration);
      if (match != null) {
        int minutes = int.parse(match.group(1) ?? '0');
        return _formatMinutes(minutes);
      }
    }

    return duration; // Retourner la chaîne originale si impossible à parser
  }

  /// Formate un nombre de minutes en texte lisible
  static String _formatMinutes(int totalMinutes) {
    if (totalMinutes == 0) {
      return '0 min';
    }

    int hours = totalMinutes ~/ 60;
    int minutes = totalMinutes % 60;

    if (hours == 0) {
      return '${minutes} min';
    } else if (minutes == 0) {
      return hours == 1 ? '1h' : '${hours}h';
    } else {
      return '${hours}h${minutes.toString().padLeft(2, '0')}';
    }
  }

  /// Extrait le nombre de minutes d'une durée formatée pour les calculs
  static int extractMinutes(String? duration) {
    if (duration == null || duration.isEmpty) {
      return 0;
    }

    try {
      String cleanDuration = duration.toLowerCase().replaceAll(RegExp(r'[^\d:]'), '');
      
      if (RegExp(r'^\d+$').hasMatch(cleanDuration)) {
        return int.parse(cleanDuration);
      }

      List<String> parts = cleanDuration.split(':');
      
      if (parts.length == 3) {
        int hours = int.parse(parts[0]);
        int minutes = int.parse(parts[1]);
        int seconds = int.parse(parts[2]);
        return hours * 60 + minutes + (seconds >= 30 ? 1 : 0);
      } else if (parts.length == 2) {
        int minutes = int.parse(parts[0]);
        int seconds = int.parse(parts[1]);
        return minutes + (seconds >= 30 ? 1 : 0);
      }
    } catch (e) {
      RegExp regExp = RegExp(r'(\d+)');
      Match? match = regExp.firstMatch(duration);
      if (match != null) {
        return int.parse(match.group(1) ?? '0');
      }
    }

    return 0;
  }
}
