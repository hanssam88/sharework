import 'package:flutter/material.dart';

import '../../data/dummy_data.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';

enum _ViewMode { grid, list }
enum _SortMode { recent, name, kind }

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  late List<PortfolioItem> _items;
  final Set<int> _featuredIds = {1};
  final Set<int> _privateIds = {};
  _ViewMode _view = _ViewMode.grid;
  _SortMode _sort = _SortMode.recent;

  bool _selectMode = false;
  final Set<int> _selected = {};

  static const _categories = [
    '카페', '서빙', '행사', '디자인', '기타',
  ];

  static const _placeholders = [
    '#E6F8F6', '#FFF6E5', '#EEF4FF', '#FFE9EC', '#F1F3F5', '#E0F2FE',
  ];

  @override
  void initState() {
    super.initState();
    _items = List.of(Dummy.portfolio);
  }

  List<PortfolioItem> get _sorted {
    final list = List.of(_items);
    switch (_sort) {
      case _SortMode.recent:
        list.sort((a, b) => b.id.compareTo(a.id));
        break;
      case _SortMode.name:
        list.sort((a, b) => a.title.compareTo(b.title));
        break;
      case _SortMode.kind:
        list.sort((a, b) => a.kind.index.compareTo(b.kind.index));
        break;
    }
    return list;
  }

  int get _nextId =>
      _items.isEmpty ? 1 : _items.map((i) => i.id).reduce((a, b) => a > b ? a : b) + 1;

  void _toggleSelect(int id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  void _exitSelectMode() {
    setState(() {
      _selectMode = false;
      _selected.clear();
    });
  }

  void _showAddTypeSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('포트폴리오 추가',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('어떤 형식으로 등록할까요?',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textMuted)),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _typeTile(Icons.image_outlined, '이미지', () {
                    Navigator.pop(sheetCtx);
                    _editItem(kind: PortfolioKind.image);
                  }),
                  _typeTile(Icons.link, '링크', () {
                    Navigator.pop(sheetCtx);
                    _editItem(kind: PortfolioKind.link);
                  }),
                  _typeTile(Icons.videocam_outlined, '동영상', () {
                    Navigator.pop(sheetCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('동영상 업로드 (목업)')),
                    );
                  }),
                  _typeTile(Icons.description_outlined, '문서', () {
                    Navigator.pop(sheetCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('문서 업로드 (목업)')),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.brandSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lightbulb_outline,
                        size: 16, color: AppColors.brandDark),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '한 줄 설명을 잘 적어두면 매칭율이 1.4배까지 올라가요.',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.brandDark),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeTile(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: AppColors.brandSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.brandDark),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _editItem({PortfolioKind? kind, PortfolioItem? existing}) {
    final k = existing?.kind ?? kind ?? PortfolioKind.image;
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final subCtrl = TextEditingController(text: existing?.subtitle ?? '');
    final urlCtrl = TextEditingController(text: existing?.url ?? '');
    String selectedColor = existing?.colorTag ?? _placeholders[0];
    String selectedCategory = _categories[0];
    bool isPrivate = existing != null && _privateIds.contains(existing.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
        ),
        child: StatefulBuilder(
          builder: (innerCtx, innerSet) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      k == PortfolioKind.image
                          ? Icons.image_outlined
                          : Icons.link,
                      color: AppColors.brandDark,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      existing == null
                          ? (k == PortfolioKind.image
                              ? '이미지 작품 추가'
                              : '링크 추가')
                          : '편집',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (k == PortfolioKind.image) ...[
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('갤러리 연결 (목업)')),
                      );
                    },
                    child: Container(
                      height: 160,
                      decoration: BoxDecoration(
                        color: Color(int.parse(
                            'FF${selectedColor.replaceAll('#', '')}',
                            radix: 16)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      alignment: Alignment.center,
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              size: 40, color: AppColors.brandDark),
                          SizedBox(height: 6),
                          Text('이미지 추가 (목업)',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.brandDark,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('썸네일 색상',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textMuted)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: _placeholders
                        .map((c) => GestureDetector(
                              onTap: () => innerSet(() => selectedColor = c),
                              child: Container(
                                width: 28, height: 28,
                                decoration: BoxDecoration(
                                  color: Color(int.parse(
                                      'FF${c.replaceAll('#', '')}',
                                      radix: 16)),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: selectedColor == c
                                        ? AppColors.brandDark
                                        : AppColors.divider,
                                    width: selectedColor == c ? 2 : 1,
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                if (k == PortfolioKind.link) ...[
                  TextField(
                    controller: urlCtrl,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'URL',
                      hintText: 'https://...',
                      prefixIcon: Icon(Icons.link),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextButton.icon(
                    onPressed: () {
                      final raw = urlCtrl.text.trim();
                      if (raw.isEmpty) return;
                      innerSet(() {
                        if (titleCtrl.text.isEmpty) {
                          titleCtrl.text = '링크: ${raw.replaceAll(RegExp(r'^https?://'), '').split('/').first}';
                        }
                        if (subCtrl.text.isEmpty) {
                          subCtrl.text = '미리보기 자동 추출 (목업)';
                        }
                      });
                    },
                    icon: const Icon(Icons.auto_awesome, size: 16),
                    label: const Text('미리보기 자동 추출'),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: titleCtrl,
                  maxLength: 40,
                  decoration: const InputDecoration(
                    labelText: '제목',
                    hintText: '예) 카페 시즌 메뉴 개발',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: subCtrl,
                  maxLength: 60,
                  decoration: const InputDecoration(
                    labelText: '한 줄 설명 (선택)',
                    hintText: '예) 2024 봄 — 라떼 4종',
                  ),
                ),
                const SizedBox(height: 12),
                const Text('카테고리',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: _categories
                      .map((c) => ChoiceChip(
                            label: Text(c),
                            selected: selectedCategory == c,
                            onSelected: (_) =>
                                innerSet(() => selectedCategory = c),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: isPrivate,
                  onChanged: (v) => innerSet(() => isPrivate = v),
                  title: const Text('비공개로 저장',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                  subtitle: const Text('나만 볼 수 있어요',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textMuted)),
                  activeColor: AppColors.brandDark,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (existing != null) ...[
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _items.removeWhere((i) => i.id == existing.id);
                            _featuredIds.remove(existing.id);
                            _privateIds.remove(existing.id);
                          });
                          Navigator.pop(sheetCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('삭제되었어요')),
                          );
                        },
                        icon: const Icon(Icons.delete_outline,
                            color: AppColors.danger, size: 18),
                        label: const Text('삭제',
                            style: TextStyle(color: AppColors.danger)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.danger),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          if (titleCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('제목을 입력해주세요')),
                            );
                            return;
                          }
                          final id = existing?.id ?? _nextId;
                          final item = PortfolioItem(
                            id: id,
                            kind: k,
                            title: titleCtrl.text.trim(),
                            subtitle: subCtrl.text.trim().isEmpty
                                ? null
                                : subCtrl.text.trim(),
                            url: k == PortfolioKind.link
                                ? urlCtrl.text.trim()
                                : null,
                            colorTag: k == PortfolioKind.image
                                ? selectedColor
                                : null,
                          );
                          setState(() {
                            if (existing != null) {
                              final idx = _items
                                  .indexWhere((i) => i.id == existing.id);
                              if (idx >= 0) _items[idx] = item;
                            } else {
                              _items.add(item);
                            }
                            if (isPrivate) {
                              _privateIds.add(id);
                            } else {
                              _privateIds.remove(id);
                            }
                          });
                          Navigator.pop(sheetCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(existing == null
                                    ? '포트폴리오에 추가되었어요'
                                    : '저장되었어요')),
                          );
                        },
                        child: const Text('저장'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showItemSheet(PortfolioItem item) {
    final isFeatured = _featuredIds.contains(item.id);
    final isPrivate = _privateIds.contains(item.id);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: item.colorTag != null
                          ? Color(int.parse(
                              'FF${item.colorTag!.replaceAll('#', '')}',
                              radix: 16))
                          : AppColors.chipBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      item.kind == PortfolioKind.image
                          ? Icons.image_outlined
                          : Icons.link,
                      color: AppColors.brandDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800)),
                        if (item.subtitle != null)
                          Text(item.subtitle!,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.open_in_new,
                    color: AppColors.brandDark),
                title: const Text('미리보기'),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${item.title} 미리보기 (목업)')),
                  );
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.edit_outlined,
                    color: AppColors.brandDark),
                title: const Text('편집'),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _editItem(existing: item);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  isFeatured ? Icons.star : Icons.star_border,
                  color: isFeatured
                      ? const Color(0xFFFFC400)
                      : AppColors.brandDark,
                ),
                title: Text(isFeatured ? '대표 해제' : '대표로 설정'),
                subtitle: const Text('프로필 상단에 강조됩니다'),
                onTap: () {
                  setState(() {
                    if (isFeatured) {
                      _featuredIds.remove(item.id);
                    } else {
                      _featuredIds.add(item.id);
                    }
                  });
                  Navigator.pop(sheetCtx);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  isPrivate
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.brandDark,
                ),
                title: Text(isPrivate ? '공개로 전환' : '비공개로 전환'),
                onTap: () {
                  setState(() {
                    if (isPrivate) {
                      _privateIds.remove(item.id);
                    } else {
                      _privateIds.add(item.id);
                    }
                  });
                  Navigator.pop(sheetCtx);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.share_outlined,
                    color: AppColors.brandDark),
                title: const Text('공유'),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _showShareSheet(item: item);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.delete_outline,
                    color: AppColors.danger),
                title: const Text('삭제',
                    style: TextStyle(color: AppColors.danger)),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _confirmDelete([item.id]);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(List<int> ids) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(ids.length == 1 ? '항목 삭제' : '${ids.length}개 항목 삭제'),
        content: const Text('삭제하면 되돌릴 수 없어요. 정말 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _items.removeWhere((i) => ids.contains(i.id));
                _featuredIds.removeAll(ids);
                _privateIds.removeAll(ids);
                _selected.removeAll(ids);
                if (_selected.isEmpty) _selectMode = false;
              });
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const Text('정렬',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            for (final s in _SortMode.values)
              RadioListTile<_SortMode>(
                title: Text({
                  _SortMode.recent: '최신 등록순',
                  _SortMode.name: '제목 가나다순',
                  _SortMode.kind: '종류별 (이미지·링크)',
                }[s]!),
                value: s,
                groupValue: _sort,
                activeColor: AppColors.brandDark,
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _sort = v);
                  Navigator.pop(sheetCtx);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showMoreMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.sort, color: AppColors.brandDark),
              title: const Text('정렬'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _showSortSheet();
              },
            ),
            ListTile(
              leading: Icon(
                _view == _ViewMode.grid
                    ? Icons.view_list
                    : Icons.grid_view,
                color: AppColors.brandDark,
              ),
              title: Text(_view == _ViewMode.grid
                  ? '리스트로 보기'
                  : '그리드로 보기'),
              onTap: () {
                Navigator.pop(sheetCtx);
                setState(() => _view = _view == _ViewMode.grid
                    ? _ViewMode.list
                    : _ViewMode.grid);
              },
            ),
            ListTile(
              leading: const Icon(Icons.checklist,
                  color: AppColors.brandDark),
              title: const Text('일괄 선택'),
              onTap: () {
                Navigator.pop(sheetCtx);
                setState(() => _selectMode = true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined,
                  color: AppColors.brandDark),
              title: const Text('포트폴리오 전체 공유'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _showShareSheet();
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart,
                  color: AppColors.brandDark),
              title: const Text('조회수 통계'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _showStatsSheet();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showStatsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('이번 달 조회수 (목업)',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(label: '총 조회', value: '1,284'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatCard(label: '관심 추가', value: '47'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatCard(label: '연락 시도', value: '12'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('가장 많이 본 작품',
                  style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              for (var i = 0; i < _items.take(3).length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Text('${i + 1}.',
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(_items[i].title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700)),
                      ),
                      Text('${(384 - i * 92)}회',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.brandDark)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showShareSheet({PortfolioItem? item}) {
    final title = item == null ? '포트폴리오 공유' : '${item.title} 공유';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _shareTile(Icons.chat_bubble, '카카오톡',
                      const Color(0xFFFEE500), AppColors.text, () {
                    Navigator.pop(sheetCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('카카오톡 공유 (목업)')),
                    );
                  }),
                  _shareTile(Icons.link, '링크 복사',
                      AppColors.brandSoft, AppColors.brandDark, () {
                    Navigator.pop(sheetCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('https://share.work/p/abc123 복사됨 (목업)')),
                    );
                  }),
                  _shareTile(Icons.qr_code, 'QR',
                      AppColors.chipBg, AppColors.text, () {
                    Navigator.pop(sheetCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('QR 보기 (목업)')),
                    );
                  }),
                  _shareTile(Icons.ios_share, '다른 앱',
                      AppColors.chipBg, AppColors.text, () {
                    Navigator.pop(sheetCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('OS 공유 시트 (목업)')),
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shareTile(
      IconData icon, String label, Color bg, Color fg, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: fg),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.collections_outlined,
                size: 64, color: AppColors.textFaint),
            const SizedBox(height: 12),
            const Text('아직 등록된 포트폴리오가 없어요',
                style: TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 4),
            const Text('첫 작품을 추가해보세요',
                style:
                    TextStyle(fontSize: 12, color: AppColors.textFaint)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _showAddTypeSheet,
              icon: const Icon(Icons.add),
              label: const Text('추가하기'),
            ),
          ],
        ),
      );
    }
    final sorted = _sorted;
    if (_view == _ViewMode.grid) {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.95,
        ),
        itemCount: sorted.length,
        itemBuilder: (_, i) {
          final item = sorted[i];
          return _PortfolioCard(
            item: item,
            featured: _featuredIds.contains(item.id),
            isPrivate: _privateIds.contains(item.id),
            selectMode: _selectMode,
            selected: _selected.contains(item.id),
            onTap: () {
              if (_selectMode) {
                _toggleSelect(item.id);
              } else {
                _showItemSheet(item);
              }
            },
            onLongPress: () {
              setState(() {
                _selectMode = true;
                _selected.add(item.id);
              });
            },
          );
        },
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final item = sorted[i];
        final featured = _featuredIds.contains(item.id);
        final isPrivate = _privateIds.contains(item.id);
        final selected = _selected.contains(item.id);
        return InkWell(
          onTap: () {
            if (_selectMode) {
              _toggleSelect(item.id);
            } else {
              _showItemSheet(item);
            }
          },
          onLongPress: () {
            setState(() {
              _selectMode = true;
              _selected.add(item.id);
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? AppColors.brandDark : AppColors.divider,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                if (_selectMode)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      selected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: selected
                          ? AppColors.brandDark
                          : AppColors.textFaint,
                    ),
                  ),
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: item.colorTag != null
                        ? Color(int.parse(
                            'FF${item.colorTag!.replaceAll('#', '')}',
                            radix: 16))
                        : AppColors.chipBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    item.kind == PortfolioKind.image
                        ? Icons.image_outlined
                        : Icons.link,
                    color: AppColors.brandDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14)),
                          ),
                          if (featured)
                            const Icon(Icons.star,
                                size: 14, color: Color(0xFFFFC400)),
                          if (isPrivate)
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(Icons.lock_outline,
                                  size: 14, color: AppColors.textFaint),
                            ),
                        ],
                      ),
                      if (item.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(item.subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectMode
            ? '${_selected.length}개 선택됨'
            : '포트폴리오'),
        leading: _selectMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSelectMode,
              )
            : null,
        actions: [
          if (_selectMode) ...[
            IconButton(
              icon: const Icon(Icons.visibility_off_outlined),
              tooltip: '비공개로 전환',
              onPressed: _selected.isEmpty
                  ? null
                  : () {
                      setState(() => _privateIds.addAll(_selected));
                      _exitSelectMode();
                    },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: '삭제',
              color: AppColors.danger,
              onPressed: _selected.isEmpty
                  ? null
                  : () => _confirmDelete(_selected.toList()),
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.tune),
              tooltip: '정렬',
              onPressed: _showSortSheet,
            ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: _showMoreMenu,
            ),
          ],
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _selectMode
          ? null
          : FloatingActionButton.extended(
              onPressed: _showAddTypeSheet,
              backgroundColor: AppColors.brandDark,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('추가'),
            ),
    );
  }
}

class _PortfolioCard extends StatelessWidget {
  final PortfolioItem item;
  final bool featured;
  final bool isPrivate;
  final bool selectMode;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  const _PortfolioCard({
    required this.item,
    required this.featured,
    required this.isPrivate,
    required this.selectMode,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  Color _bgColor() {
    if (item.colorTag != null) {
      final s = item.colorTag!.replaceAll('#', '');
      return Color(int.parse('FF$s', radix: 16));
    }
    return AppColors.chipBg;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.brandDark : AppColors.divider,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    color: _bgColor(),
                    alignment: Alignment.center,
                    child: Icon(
                      item.kind == PortfolioKind.image
                          ? Icons.image_outlined
                          : Icons.link,
                      size: 36,
                      color: AppColors.brandDark,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13),
                            ),
                          ),
                          if (isPrivate)
                            const Icon(Icons.lock_outline,
                                size: 12, color: AppColors.textFaint),
                        ],
                      ),
                      if (item.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (featured)
              Positioned(
                top: 6, left: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC400),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 11, color: Colors.white),
                      SizedBox(width: 2),
                      Text('대표',
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ),
            if (selectMode)
              Positioned(
                top: 6, right: 6,
                child: Container(
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.brandDark
                        : Colors.white.withOpacity(0.85),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? AppColors.brandDark
                          : AppColors.divider,
                    ),
                  ),
                  child: Icon(
                    Icons.check,
                    size: 14,
                    color: selected
                        ? Colors.white
                        : AppColors.textFaint,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.brandSoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.brandDark)),
        ],
      ),
    );
  }
}
