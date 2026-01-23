import 'package:flutter/foundation.dart';
import '../models/vault.dart';
import '../models/note.dart';
import '../services/vault_service.dart';
import '../services/link_service.dart';

class VaultProvider with ChangeNotifier {
  final VaultService _vaultService = VaultService();
  final LinkService _linkService = LinkService();

  Vault? _currentVault;
  List<Vault> _vaults = [];
  List<Note> _notes = [];
  bool _isLoading = false;

  Vault? get currentVault => _currentVault;
  List<Vault> get vaults => _vaults;
  List<Note> get notes => _notes;
  bool get isLoading => _isLoading;

  VaultProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners();

    _vaults = await _vaultService.getVaults();
    _currentVault = await _vaultService.getCurrentVault();

    if (_currentVault != null) {
      await loadNotes();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadNotes() async {
    if (_currentVault == null) return;

    _isLoading = true;
    notifyListeners();

    _notes = await _vaultService.getNotesInVault(_currentVault!);
    _notes = await _linkService.updateBacklinks(_notes);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> createVault(String name, String path) async {
    final vault = await _vaultService.createVault(name, path);
    _vaults.add(vault);
    await setCurrentVault(vault);
    notifyListeners();
  }

  Future<void> openVault(String path) async {
    final vault = await _vaultService.openVault(path);
    _vaults.add(vault);
    await setCurrentVault(vault);
    notifyListeners();
  }

  Future<void> setCurrentVault(Vault vault) async {
    _currentVault = vault;
    await _vaultService.setCurrentVault(vault);
    await loadNotes();
    notifyListeners();
  }

  Future<void> createNote(String title, {String? subfolder}) async {
    if (_currentVault == null) return;

    final note = await _vaultService.createNote(_currentVault!, title, subfolder: subfolder);
    _notes.add(note);
    notifyListeners();
  }

  Future<void> saveNote(Note note) async {
    if (_currentVault == null) return;

    await _vaultService.saveNote(_currentVault!, note);

    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      _notes[index] = note;
      _notes = await _linkService.updateBacklinks(_notes);
      notifyListeners();
    }
  }

  Future<void> deleteNote(Note note) async {
    await _vaultService.deleteNote(note);
    _notes.removeWhere((n) => n.id == note.id);
    _notes = await _linkService.updateBacklinks(_notes);
    notifyListeners();
  }

  Future<void> renameNote(Note note, String newTitle) async {
    final updatedNote = await _vaultService.renameNote(note, newTitle);
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      _notes[index] = updatedNote;
      _notes = await _linkService.updateBacklinks(_notes);
      notifyListeners();
    }
  }

  Note? getNoteByTitle(String title) {
    try {
      return _notes.firstWhere((note) => note.title == title);
    } catch (e) {
      return null;
    }
  }

  Note? getNoteById(String id) {
    try {
      return _notes.firstWhere((note) => note.id == id);
    } catch (e) {
      return null;
    }
  }
}
