import 'package:bcrypt/bcrypt.dart';

String hashPassword(String password) => BCrypt.hashpw(password, BCrypt.gensalt());

bool verifyPassword(String password, String hash) => BCrypt.checkpw(password, hash);
