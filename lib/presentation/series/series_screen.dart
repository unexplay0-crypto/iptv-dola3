import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app_theme.dart';
import '../../core/models.dart';
import '../../data/repositories/content_repository.dart';
import '../../widgets/tv_focusable_item.dart';
import '../../widgets/skeleton.dart';
import '../player/player_screen.dart';

class SeriesScreen extends StatefulWidget {
  const SeriesScreen({super.key});

  @override
  State<SeriesScreen> createState() => _SeriesScreenState();
}

class _SeriesScreenState extends State<SeriesScreen> {
  final _repo = ContentRepository();
  List<SeriesGroup> _series = [];
  bool _loading = true;
  String _search = "";

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _series = await _repo.series(search: _search.isEmpty ? null : _search);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: SkeletonGrid());
    return Column(children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            hintText: "Buscar série...",
            hintStyle: TextStyle(color: AppTheme.textSecondary),
            prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary),
            filled: true,
            fillColor: AppTheme.surface,
            border: OutlineInputBorder(borderSide: BorderSide.none),
          ),
          onChanged: (v) async {
            _search = v;
            setState(() => _loading = true);
            await _load();
          },
        ),
      ),
      Expanded(
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, childAspectRatio: 0.6, crossAxisSpacing: 10, mainAxisSpacing: 10),
          itemCount: _series.length,
          itemBuilder: (_, i) {
            final s = _series[i];
            return TVFocusableItem(
              autofocus: i == 0,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SeriesDetailScreen(series: s))),
              child: Column(children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    color: AppTheme.surface,
                    child: s.logo != null
                        ? CachedNetworkImage(imageUrl: s.logo!, fit: BoxFit.cover, errorWidget: (_, __, ___) => const Icon(Icons.tv, size: 40, color: Colors.grey))
                        : const Icon(Icons.tv, size: 40, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 4),
                Text(s.name, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
                Text("${s.seasonNumbers.length} temp. • ${s.episodeCount} ep.", style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
              ]),
            );
          },
        ),
      ),
    ]);
  }
}

class SeriesDetailScreen extends StatefulWidget {
  final SeriesGroup series;
  const SeriesDetailScreen({super.key, required this.series});

  @override
  State<SeriesDetailScreen> createState() => _SeriesDetailScreenState();
}

class _SeriesDetailScreenState extends State<SeriesDetailScreen> {
  late int _selectedSeason;

  @override
  void initState() {
    super.initState();
    _selectedSeason = widget.series.seasonNumbers.first;
  }

  @override
  Widget build(BuildContext context) {
    final episodes = widget.series.seasons[_selectedSeason] ?? [];
    return Scaffold(
      appBar: AppBar(title: Text(widget.series.name), backgroundColor: Colors.transparent),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Abas de temporada
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.series.seasonNumbers.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final s = widget.series.seasonNumbers[i];
                final sel = s == _selectedSeason;
                return TVFocusableItem(
                  autofocus: i == 0,
                  onTap: () => setState(() => _selectedSeason = s),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(color: sel ? AppTheme.accent : AppTheme.surface, borderRadius: BorderRadius.circular(20)),
                    child: Text("Temporada $s", style: TextStyle(color: sel ? Colors.black : AppTheme.textPrimary, fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: episodes.length,
              separatorBuilder: (_, __) => const Divider(color: Colors.white10),
              itemBuilder: (_, i) {
                final ep = episodes[i];
                return TVFocusableItem(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlayerScreen(item: ep))),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    child: Row(children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(8)),
                        alignment: Alignment.center,
                        child: Text("${ep.episode ?? i + 1}", style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accent)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(ep.name, maxLines: 2, overflow: TextOverflow.ellipsis)),
                      const Icon(Icons.play_arrow, color: AppTheme.textSecondary),
                    ]),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}
