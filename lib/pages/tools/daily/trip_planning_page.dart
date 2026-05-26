import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/storage/app_database.dart';

/// 旅行计划页面 - 行程规划与费用管理
class TripPlanningPage extends StatefulWidget {
  const TripPlanningPage({super.key});

  @override
  State<TripPlanningPage> createState() => _TripPlanningPageState();
}

class _TripPlanningPageState extends State<TripPlanningPage> with SingleTickerProviderStateMixin {
  final AppDatabase _db = AppDatabase();
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  final ImagePicker _picker = ImagePicker();
  
  List<Map<String, dynamic>> _trips = [];
  bool _isLoading = true;
  String _filter = 'all'; // all, planning, ongoing, finished
  TabController? _tabController;
  Map<String, dynamic>? _selectedTrip;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _trips = await _db.getTrips();
      if (_filter != 'all') {
        _trips = _trips.where((t) => t['status'] == _filter).toList();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载失败: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _selectTrip(Map<String, dynamic> trip) {
    setState(() {
      _selectedTrip = trip;
    });
    _tabController?.animateTo(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('旅行计划'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() => _filter = value);
              _loadData();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('全部')),
              const PopupMenuItem(value: 'planning', child: Text('规划中')),
              const PopupMenuItem(value: 'ongoing', child: Text('进行中')),
              const PopupMenuItem(value: 'finished', child: Text('已完成')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: '列表'),
            Tab(icon: Icon(Icons.map), text: '行程'),
            Tab(icon: Icon(Icons.bar_chart), text: '费用'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTripList(),
          _buildItineraryView(),
          _buildExpenseStats(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTripDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTripList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_trips.isEmpty) {
      return _buildEmptyState();
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _trips.length,
      itemBuilder: (context, index) {
        final trip = _trips[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => _selectTrip(trip),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.flight_takeoff, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          trip['title'] ?? '未命名旅行',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildStatusBadge(trip['status']),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (trip['destination'] != null)
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(trip['destination']!),
                      ],
                    ),
                  if (trip['startDate'] != null && trip['endDate'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text('${trip['startDate']} 至 ${trip['endDate']}'),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.account_balance_wallet, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '预算: ¥${trip['budget']?.toStringAsFixed(0) ?? '0'} | '
                        '已花费: ¥${trip['actualCost']?.toStringAsFixed(0) ?? '0'}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildItineraryView() {
    if (_selectedTrip == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.touch_app, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('选择一个旅行计划查看行程', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _db.getTripItineraries(_selectedTrip!['id']),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final itineraries = snapshot.data!;
        if (itineraries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.route, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('暂无行程安排', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _showAddItineraryDialog(_selectedTrip!['id']),
                  icon: const Icon(Icons.add),
                  label: const Text('添加行程'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: itineraries.length,
          itemBuilder: (context, index) {
            final itinerary = itineraries[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Text('D${itinerary['day']}'),
                ),
                title: Text(itinerary['title'] ?? '第${itinerary['day']}天'),
                subtitle: itinerary['date'] != null ? Text(itinerary['date']!) : null,
                children: [
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _db.getTripActivities(itinerary['id']),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('暂无活动安排', style: TextStyle(color: Colors.grey)),
                        );
                      }
                      return Column(
                        children: snapshot.data!.map((activity) => ListTile(
                          leading: _getActivityIcon(activity['type']),
                          title: Text(activity['title'] ?? ''),
                          subtitle: Text([
                            activity['time'],
                            activity['location'],
                            activity['cost'] != null ? '¥${activity['cost']}' : null,
                          ].where((e) => e != null).join(' · ')),
                        )).toList(),
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: TextButton.icon(
                      onPressed: () => _showAddActivityDialog(itinerary['id']),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('添加活动'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildExpenseStats() {
    if (_selectedTrip == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.touch_app, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('选择一个旅行计划查看费用', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: _db.getTripExpenseStats(_selectedTrip!['id']),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final stats = snapshot.data!;
        final budget = _selectedTrip!['budget'] ?? 0.0;
        final actualCost = stats['totalCost'] ?? 0.0;
        final percentage = budget > 0 ? (actualCost / budget * 100).clamp(0.0, 100.0) : 0.0;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('预算使用率', style: TextStyle(fontSize: 16)),
                          Text(
                            '${percentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: percentage > 90 ? Colors.red : Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          percentage > 90 ? Colors.red : Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('预算: ¥${budget.toStringAsFixed(0)}'),
                          Text('已花费: ¥${actualCost.toStringAsFixed(0)}'),
                          Text('剩余: ¥${(budget - actualCost).toStringAsFixed(0)}'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('费用分类', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _db.getTripExpensesByCategory(_selectedTrip!['id']),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();
                  return Column(
                    children: snapshot.data!.map((cat) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(cat['category'] ?? '其他'),
                          ),
                          Text('¥${cat['total']?.toStringAsFixed(0) ?? '0'}'),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 100,
                            child: LinearProgressIndicator(
                              value: actualCost > 0 ? (cat['total'] ?? 0) / actualCost : 0,
                              backgroundColor: Colors.grey[200],
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.luggage, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('暂无旅行计划', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          const SizedBox(height: 8),
          Text('点击右下角 + 创建你的第一次旅行', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String? status) {
    final colors = {
      'planning': Colors.orange,
      'ongoing': Colors.green,
      'finished': Colors.blue,
    };
    final labels = {
      'planning': '规划中',
      'ongoing': '进行中',
      'finished': '已完成',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (colors[status] ?? Colors.grey).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        labels[status] ?? '未知',
        style: TextStyle(color: colors[status] ?? Colors.grey, fontSize: 12),
      ),
    );
  }

  Widget _getActivityIcon(String? type) {
    final icons = {
      'sight': Icons.landscape,
      'food': Icons.restaurant,
      'transport': Icons.directions_bus,
      'accommodation': Icons.hotel,
      'shopping': Icons.shopping_bag,
    };
    return Icon(icons[type] ?? Icons.event, color: Colors.blue);
  }

  void _showAddTripDialog() {
    final titleController = TextEditingController();
    final destinationController = TextEditingController();
    final budgetController = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('新建旅行计划'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: '旅行名称 *'),
                ),
                TextField(
                  controller: destinationController,
                  decoration: const InputDecoration(labelText: '目的地'),
                ),
                TextField(
                  controller: budgetController,
                  decoration: const InputDecoration(labelText: '预算 (元)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setDialogState(() => startDate = picked);
                          }
                        },
                        child: Text(startDate == null ? '选择开始日期' : _dateFormat.format(startDate!)),
                      ),
                    ),
                    const Text(' 至 '),
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: startDate ?? DateTime.now(),
                            firstDate: startDate ?? DateTime.now(),
                            lastDate: (startDate ?? DateTime.now()).add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setDialogState(() => endDate = picked);
                          }
                        },
                        child: Text(endDate == null ? '选择结束日期' : _dateFormat.format(endDate!)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isEmpty) return;
                _db.addTrip({
                  'title': titleController.text,
                  'destination': destinationController.text,
                  'budget': double.tryParse(budgetController.text) ?? 0,
                  'startDate': startDate != null ? _dateFormat.format(startDate!) : null,
                  'endDate': endDate != null ? _dateFormat.format(endDate!) : null,
                  'status': 'planning',
                }).then((_) {
                  Navigator.pop(context);
                  _loadData();
                });
              },
              child: const Text('创建'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddItineraryDialog(int tripId) {
    final titleController = TextEditingController();
    int day = 1;
    DateTime? date;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('添加行程'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: '行程标题'),
              ),
              TextField(
                controller: TextEditingController(text: day.toString()),
                decoration: const InputDecoration(labelText: '第几天'),
                keyboardType: TextInputType.number,
                onChanged: (v) => day = int.tryParse(v) ?? 1,
              ),
              TextButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setDialogState(() => date = picked);
                  }
                },
                child: Text(date == null ? '选择日期' : _dateFormat.format(date!)),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
            ElevatedButton(
              onPressed: () {
                _db.insertTripItinerary(tripId, day, titleController.text, date != null ? _dateFormat.format(date!) : null)
                    .then((_) {
                  Navigator.pop(context);
                  _loadData();
                });
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddActivityDialog(int itineraryId) {
    final titleController = TextEditingController();
    final locationController = TextEditingController();
    final costController = TextEditingController();
    String type = 'sight';
    String? time;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加活动'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: '活动名称 *')),
            TextField(controller: locationController, decoration: const InputDecoration(labelText: '地点')),
            TextField(controller: costController, decoration: const InputDecoration(labelText: '费用 (元)'), keyboardType: TextInputType.number),
            DropdownButtonFormField<String>(
              value: type,
              items: const [
                DropdownMenuItem(value: 'sight', child: Text('🏞️ 景点')),
                DropdownMenuItem(value: 'food', child: Text('🍽️ 餐饮')),
                DropdownMenuItem(value: 'transport', child: Text('🚌 交通')),
                DropdownMenuItem(value: 'accommodation', child: Text('🏨 住宿')),
                DropdownMenuItem(value: 'shopping', child: Text('🛍️ 购物')),
              ],
              onChanged: (v) => type = v ?? 'sight',
              decoration: const InputDecoration(labelText: '类型'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isEmpty) return;
              _db.insertTripActivity(
                itineraryId, titleController.text, type, locationController.text,
                double.tryParse(costController.text), time,
              ).then((_) {
                Navigator.pop(context);
                _loadData();
              });
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
}
