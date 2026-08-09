import 'dart:math';

String generateRandomPassword(int size, bool uppercase, bool lowercase, bool digits, bool specials) {
  // Define character sets based on parameters
  List<String> charSets = [];
  if (uppercase) charSets.add("ABCDEFGHIJKLMNOPQRSTUVWXYZ");
  if (lowercase) charSets.add("abcdefghijklmnopqrstuvwxyz");
  if (digits) charSets.add("0123456789");
  if (specials) charSets.add("!@#\$%^&*()-_+=");

  // Check if at least one character set is selected
  if (charSets.isEmpty) {
    throw ArgumentError("At least one character set must be selected");
  }

  // Generate password ensuring at least one character from each set
  String password = '';

  // Add at least one character from each selected set
  for (var set in charSets) {
    password += set[Random.secure().nextInt(set.length)];
  }

  // Fill the remaining characters randomly
  for (int i = charSets.length; i < size; i++) {
    String randomSet = charSets[Random.secure().nextInt(charSets.length)];
    password += randomSet[Random.secure().nextInt(randomSet.length)];
  }

  // Shuffle the password to ensure randomness
  List<String> passwordChars = password.split('');
  passwordChars.shuffle();
  return passwordChars.join('');
}
