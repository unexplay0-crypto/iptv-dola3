import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

/// Armazenamento local. As credenciais são mantidas em cache em memória
/// ([_cachedCreds]) para que o getter [credentials] permaneça síncrono.
/// Para produção com maior segurança, recomenda-se flutter_secure_storage
/// (Keystore) — não incluído aqui por aumentar o tempo de build nativo.
class AppStorage {
  static const _kDns = "dns";
  static const _kUser = "username";
  static const _kPass = "password";
  static const _kM3u = "m3u_url";
  static const _kPin = "parental_pin";
  static const _kAdultUnlocked = "adult_unlocked";
  static const _kFavorites = "favorites";
  static const _kHistory = "history";
  static const _kProgress = "vod_progress";
  static const _kChannelViews = "channel_views";
  static const _kAudioPref = "audio_pref";
  static const _kSubtitlePref = "subtitle_pref";
  static const _kUiSound = "ui_sound";
  static const _kLastChannel = "last_channel";
  static const defaultPin = "0000";

  late SharedPreferences _prefs;
  AppCredentials _cachedCreds = const AppCredentials();

  static final AppStorage instance = AppStorage._();
  AppStorage._();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _cachedCreds = AppCredentials(
      dns: _prefs.getString(_kDns) ?? "",
      username: _prefs.getString(_kUser) ?? "",
      password: _prefs.getString(_kPass) ?? "",
      m3uUrl: _prefs.getString(_kM3u),
      activationCode: _prefs.getString("activation_code"),
    );
  }

  // Credenciais (getter síncrono via cache em memória)
  AppCredentials get credentials => _cachedCreds;

  Future<void> saveCredentials(AppCredentials c) async {
    _cachedCreds = c;
    await _prefs.setString(_kDns, c.dns);
    await _prefs.setString(_kUser, c.username);
    await _prefs.setString(_kPass, c.password);
    if (c.m3uUrl != null) {
      await _prefs.setString(_kM3u, c.m3uUrl!);
    } else {
      await _prefs.remove(_kM3u);
    }
    if (c.activationCode != null) {
      await _prefs.setString("activation_code", c.activationCode!);
    }
  }

  bool get isLoggedIn =>
      _cachedCreds.dns.isNotEmpty || (_cachedCreds.m3uUrl?.isNotEmpty ?? false);

  Future<void> clearCredentials() async {
    _cachedCreds = const AppCredentials();
    for (final k in [_kDns, _kUser, _kPass, _kM3u, "activation_code"]) {
      await _prefs.remove(k);
    }
  }

  // PIN parental
  String get pin => _prefs.getString(_kPin) ?? defaultPin;
  Future<void> setPin(String pin) async => _prefs.setString(_kPin, pin);
  bool get adultUnlocked => _prefs.getBool(_kAdultUnlocked) ?? false;
  Future<void> setAdultUnlocked(bool v) async => _prefs.setBool(_kAdultUnlocked, v);

  // Favoritos
  Set<String> get favorites => _prefs.getStringList(_kFavorites)?.toSet() ?? {};
  Future<void> toggleFavorite(String id) async {
    final s = favorites;
    s.contains(id) ? s.remove(id) : s.add(id);
    await _prefs.setStringList(_kFavorites, s.toList());
  }

  bool isFavorite(String id) => favorites.contains(id);

  // Histórico (ids, mais recente primeiro)
  List<String> get history => _prefs.getStringList(_kHistory) ?? [];
  Future<void> addToHistory(String id) async {
    final h = history.where((e) => e != id).toList();
    h.insert(0, id);
    await _prefs.setStringList(_kHistory, h.take(100).toList());
  }

  // Progresso VOD (id -> position em ms)
  Map<String, int> get vodProgress {
    final s = _prefs.getString(_kProgress);
    if (s == null) return {};
    final m = jsonDecode(s) as Map<String, dynamic>;
    return m.map((k, v) => MapEntry(k, (v as num).toInt()));
  }

  Future<void> saveProgress(String id, int positionMs) async {
    final m = vodProgress;
    m[id] = positionMs;
    await _prefs.setString(_kProgress, jsonEncode(m));
  }

  int? progressFor(String id) => vodProgress[id];

  // Canais mais assistidos (id -> contagem)
  Map<String, int> get channelViews {
    final s = _prefs.getString(_kChannelViews);
    if (s == null) return {};
    final m = jsonDecode(s) as Map<String, dynamic>;
    return m.map((k, v) => MapEntry(k, (v as num).toInt()));
  }

  Future<void> incrementChannelView(String id) async {
    final m = channelViews;
    m[id] = (m[id] ?? 0) + 1;
    await _prefs.setString(_kChannelViews, jsonEncode(m));
  }

  // Preferências de áudio/legenda por série
  String? audioPrefFor(String seriesKey) =>
      (_prefs.getString("${_kAudioPref}_$seriesKey")) ?? _prefs.getString(_kAudioPref);
  Future<void> setAudioPref(String? seriesKey, String lang) async {
    if (seriesKey != null) {
      await _prefs.setString("${_kAudioPref}_$seriesKey", lang);
    } else {
      await _prefs.setString(_kAudioPref, lang);
    }
  }

  bool get subtitleEnabled => _prefs.getBool(_kSubtitlePref) ?? false;
  Future<void> setSubtitleEnabled(bool v) async => _prefs.setBool(_kSubtitlePref, v);

  // Som de UI
  bool get uiSoundEnabled => _prefs.getBool(_kUiSound) ?? true;
  Future<void> setUiSoundEnabled(bool v) async => _prefs.setBool(_kUiSound, v);

  // Último canal (recall)
  String? get lastChannel => _prefs.getString(_kLastChannel);
  Future<void> setLastChannel(String id) async => _prefs.setString(_kLastChannel, id);
}
