class AppStrings {
  static const String appName = 'Aerosphere Travels';
  static const String pasteMessageTitle = 'Paste WhatsApp Message';
  static const String pasteMessageHint = 'Paste the flight details from WhatsApp here...';
  static const String extractButtonText = 'Extract Flight Data';
  static const String availableFlightsTitle = 'Available Flights';
  static const String noFlightsMessage = 'No flights added yet. Paste a message above!';
  static const String processingMessage = 'Processing message with AI...';
  
  // Error Messages
  static const String networkError = 'Network error occurred. Please check your connection.';
  static const String unknownError = 'An unknown error occurred.';
  static const String geminiParseError = 'Could not parse the message. Please check the format.';

  static const Map<String, String> airportNames = {
    'TRZ': 'Trichy',
    'CCJ': 'Calicut',
    'DXB': 'Dubai',
    'SHJ': 'Sharjah',
    'AUH': 'Abu Dhabi',
    'AAN': 'Al Ain',
    'COK': 'Kochi',
    'TRV': 'Trivandrum',
    'CNN': 'Kannur',
    'IXE': 'Mangalore',
    'BLR': 'Bangalore',
    'MAA': 'Chennai',
    'HYD': 'Hyderabad',
    'CJB': 'Coimbatore',
    'IXM': 'Madurai',
    'GOI': 'Goa',
    'BOM': 'Mumbai',
    'DEL': 'Delhi',
    'AMD': 'Ahmedabad',
    'RKT': 'Ras Al Khaimah',
    'DOH': 'Doha',
    'KWI': 'Kuwait',
    'MCT': 'Muscat',
    'BAH': 'Bahrain',
    'RUH': 'Riyadh',
    'JED': 'Jeddah',
    'DMM': 'Dammam',
    'SLL': 'Salalah',
    'SAL': 'Salalah',
    'CAN': 'Guangzhou',
    'SIN': 'Singapore',
    'KUL': 'Kuala Lumpur',
    'CMB': 'Colombo',
    'BKK': 'Bangkok',
  };

  static const Map<String, String> airlineNames = {
    'IX': 'Air India Express',
    'OV': 'SalamAir',
    '6E': 'IndiGo',
    'FZ': 'Flydubai',
    'GF': 'Gulf Air',
    'J9': 'Jazeera Airways',
    'KU': 'Kuwait Airways',
    'QP': 'Akasa Air',
    'WY': 'Oman Air',
    'XY': 'Flynas',
    '3L': 'Air Arabia',
    'G9': 'Air Arabia',
    'SV': 'Saudia',
    'AI': 'Air India',
    'EK': 'Emirates',
    'QR': 'Qatar Airways',
    'EY': 'Etihad Airways',
    'F3': 'flyadeal',
    'RX': 'Riyadh Air',
    'SG': 'SpiceJet',
  };
}
