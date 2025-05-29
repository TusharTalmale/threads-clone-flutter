
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static final String superbaseUrl = dotenv.env["SUPERBASE_URL"]!;
  static final String superbaseKey = dotenv.env["SUPERBASE_KEY"]!;
  static final String storageBucket = dotenv.env["BUCKET"]!;

}