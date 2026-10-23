import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'models.dart';

/// Armazenamento local. Credenciais do usuário (DNS/usuário/senha) são
/// salvas no Keystore via flutter_secure_storage, com fallback automático
/// para SharedPreferences se o armazenamento seguro falhar. Mantemos um
/// cache em memória para que o getter [credentials] continue síncrono.
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
  static const FlutterSecureStorage _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  bool _secureAvailable = true;
  AppCredentials _cachedCreds = const AppCredentials();

  static final AppStorage instance = AppStorage._();
  AppStorage._();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    try {
      await _secure.write(key: "_probe", value: "1");
      await _secure.delete(key: "_probe");
      _secureAvailable = true;
    } catch (_) {
      _secureAvailable = false;
    }
    // Migra credenciais antigas (plaintext) para o armazenamento seguro
    final oldDns = _prefs.getString(_kDns);
    if (_secureAvailable && oldDns != null && oldDns.isNotEmpty) {
      try {
        await _secure.write(key: _kDns, value: oldDns);
        await _secure.write(key: _kUser, value: _prefs.getString(_kUser) ?? "");
        await _secure.write(key: _kPass, value: _prefs.getString(_kPass) ?? "");
        final m3u = _prefs.getString(_kM3u);
        if (m3u != null) await _secure.write(key: _kM3u, value: m3u);
        final act = _prefs.getString("activation_code");
        if (act != null) await _secure.write(key: "activation_code", value: act);
        await _prefs.remove(_kDns);
        await _prefs.remove(_kUser);
        await _prefs.remove(_kPass);
        await _prefs.remove(_kM3u);
        await _prefs.remove("activation_code");
      } catch (_) {
        _secureAvailable = false;
      }
    }
    // Carrega credenciais para o cache em memória (getter síncrono)
    _cachedCreds = await _loadCreds();
  }

  Future<AppCredentials> _loadCreds() async {
    Future<String?> read(String k) async {
      if (!_secureAvailable) return _prefs.getString(k);
      try {
        return await _secure.read(key: k);
      } catch (_) {
        return _prefs.getString(k);
      }
    }
    return AppCredentials(
      dns: await read(_kDns) ?? "",
      username: await read(_kUser) ?? "",
      password: await read(_kPass) ?? "",
      m3uUrl: await read(_kM3u),
      activationCode: await read("activation_code"),
    );
  }

  // Credenciais (getter síncrono via cache em memória)
  AppCredentials get credentials => _cachedCreds;

  Future<void> saveCredentials(AppCredentials c) async {
    _cachedCreds = c;
    Future<void> write(String k, String v) async {
      if (!_secureAvailable) {
        await _prefs.setString(k, v);
        return;
      }
      try {
        await _secure.write(key: k, value: v);
      } catch (_) {
        await _prefs.setString(k, v);
      }
    }
    await write(_kDns, c.dns);
    await write(_kUser, c.username);
    await write(_kPass, c.password);
    if (c.m3uUrl != null) {
      await write(_kM3u, c.m3uUrl!);
    }
    if (c.activationCode != null) {
      await write("activation_code", c.activationCode!);
    }
  }

  bool get isLoggedIn =>
      _cachedCreds.dns.isNotEmpty ||
      (_cachedCreds.m3uUrl?.isNotEmpty ?? false);

  Future<void> clearCredentials() async {
    _cachedCreds = const AppCredentials();
    Future<void> delete(String k) async {
      if (!_secureAvailable) {
        await _prefs.remove(k);
        return;
      }
      try {
        await _secure.delete(key: k);
      } catch (_) {
        await _prefs.remove(k);
      }
    }
    for (final k in [_kDns, _kUser, _kPass, _kM3u, "activation_code"]) {
      await delete(k);
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
