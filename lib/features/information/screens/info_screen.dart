// lib/features/information/screens/info_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/info_card.dart';
import '../../../data/repositories/info_repository.dart';
import '../../../data/models/info_model.dart';
import '../../../core/di/service_locator.dart';
import '../../multilingual/providers/language_provider.dart';
import '../../../core/theme/app_theme.dart';

class InfoScreen extends StatefulWidget {
  const InfoScreen({super.key});

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen>
    with SingleTickerProviderStateMixin {
  final InfoRepository _repo = sl<InfoRepository>();
  late TabController _tabController;

  List<InfoModel> _allItems = [];
  bool _isLoading = true;

  final List<Map<String, dynamic>> _tabs = const [
    {'label': 'All',        'category': 'all',      'icon': Icons.apps_rounded},
    {'label': 'Rules',      'category': 'rule',     'icon': Icons.gavel_rounded},
    {'label': 'Facilities', 'category': 'facility', 'icon': Icons.apartment_rounded},
    {'label': 'Contacts',   'category': 'contact',  'icon': Icons.call_rounded},
    {'label': 'Events',     'category': 'event',    'icon': Icons.event_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    final (items, _) = await _repo.getAllInfo();
    setState(() {
      _allItems = items ?? _fallbackItems;
      _isLoading = false;
    });
  }

  List<InfoModel> _getFilteredItems(String category) {
    if (category == 'all') return _allItems;
    return _allItems.where((i) => i.category == category).toList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final langCode = context.watch<LanguageProvider>().langCode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Information'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: AppTheme.secondaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor:
          theme.colorScheme.onSurface.withOpacity(0.5),
          tabs: _tabs.map((tab) {
            return Tab(
              child: Row(
                children: [
                  Icon(tab['icon'] as IconData, size: 16),
                  const SizedBox(width: 6),
                  Text(tab['label'] as String),
                ],
              ),
            );
          }).toList(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: _tabs.map((tab) {
          final items = _getFilteredItems(tab['category'] as String);
          return _InfoList(items: items, langCode: langCode);
        }).toList(),
      ),
    );
  }

  static final List<InfoModel> _fallbackItems = [
    const InfoModel(
      id: '1',
      title: 'Chapel Attendance',
      content: 'Mandatory chapel service every Monday, Wednesday, and Friday at 6:45 AM.',
      category: 'rule',
      iconName: 'church',
    ),
    const InfoModel(
      id: '2',
      title: 'Student Health Centre',
      content: 'Located near the male hostel. Open Monday–Friday, 8 AM–5 PM. Emergency: 24/7.',
      category: 'facility',
      iconName: 'medical',
    ),
    const InfoModel(
      id: '3',
      title: 'Registry Office',
      content: 'Course registration, results and transcripts. Mon–Fri, 8 AM–4 PM.',
      category: 'contact',
      iconName: 'admin',
    ),
    const InfoModel(
      id: '4',
      title: 'Dress Code Policy',
      content: 'Academic gown on Mondays. Smart casual at all times. No shorts or sleeveless tops.',
      category: 'rule',
      iconName: 'rule',
    ),
    const InfoModel(
      id: '5',
      title: 'University Library',
      content: 'Mon–Fri 7 AM–10 PM, Sat 8 AM–6 PM. Student ID required.',
      category: 'facility',
      iconName: 'academic',
    ),
    const InfoModel(
      id: '6',
      title: 'ICT Support',
      content: 'Email: ict@covenantuniversity.edu.ng | Ext: 2200',
      category: 'contact',
      iconName: 'admin',
    ),
  ];
}

class _InfoList extends StatelessWidget {
  final List<InfoModel> items;
  final String langCode;

  const _InfoList({required this.items, required this.langCode});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('No information available'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return InfoCard(item: items[index], langCode: langCode)
            .animate(delay: (index * 60).ms)
            .fadeIn(duration: 300.ms)
            .slideY(begin: 0.15, end: 0);
      },
    );
  }
}