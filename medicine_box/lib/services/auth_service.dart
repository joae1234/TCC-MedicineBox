import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  Session? get currentSession => _supabase.auth.currentSession;

  User? get currentUser => _supabase.auth.currentUser;

  Stream<AuthChangeEvent> get onAuthChanges =>
    _supabase.auth.onAuthStateChange.map((e) => e.event);

  Future<AuthResponse> signIn(String email, String pass) =>
    _supabase.auth.signInWithPassword(email: email, password: pass);

  Future<void> signUp(String email, String pass) =>
    _supabase.auth.signUp(email: email, password: pass);

  Future<void> signOut() => _supabase.auth.signOut();
}
