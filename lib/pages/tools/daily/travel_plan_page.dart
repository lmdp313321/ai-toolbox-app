import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/storage/app_database.dart';

/// 旅行规划页面 - 行程管理与规划
class TravelPlanPage extends StatefulWidget {
  const TravelPlanPage({super.key});

  @override
  State<TravelPlanPage> createState() => _TravelPlanPageState();
}

class _TravelPlanPageState extends State<TravelPlanPage> {
  final AppDatabase _db = AppDatabase();
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  
  List<Map<String, dynamic>> _trips = [];
  bool _isLoading = true;
  String _filter = 'upcoming'; // upcoming, past, all

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _trips = await _db.getTrips();
      // 按开始日期排序
      _trips.sort((a, b) {
        final dateA = DateTime.parse(a['startDate']);
        final dateB = DateTime.parse(b['startDate']);
        return dateB.compareTo(dateA);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredTrips {
    if (_filter == 'all') return _trips;
    
    final now = DateTime.now();
    return _trips.where((trip) {
      final endDate = DateTime.parse(trip['endDate']);
      if (_filter == 'upcoming') {
        return endDate.isAfter(now) || _isSameDay(endDate, now);
      } else {
        return endDate.isBefore(now) && !_isSameDay(endDate, now);
      }
    }).toList();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('旅行规划'),
        actions: [
          PopupMenuButton<String>(
            initialValue: _filter,
            onSelected: (value) => setState(() => _filter = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'upcoming', child: Text('即将出行')),
              const PopupMenuItem(value: 'past', child: Text('过往行程')),
              const PopupMenuItem(value: 'all', child: Text('全部')),
            ],
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Icon(Icons.filter_list),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredTrips.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredTrips.length,
                  itemBuilder: (context, index) => _buildTripCard(_filteredTrips[index]),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTripDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.flight_takeoff, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('暂无旅行计划', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          const SizedBox(height: 8),
          Text('点击右下角添加行程', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildTripCard(Map<String, dynamic> trip) {
    final startDate = DateTime.parse(trip['startDate']);
    final endDate = DateTime.parse(trip['endDate']);
    final duration = endDate.difference(startDate).inDays + 1;
    final now = DateTime.now();
    final isUpcoming = endDate.isAfter(now) || _isSameDay(endDate, now);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showTripDetail(trip),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isUpcoming ? Colors.green : Colors.grey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isUpcoming ? '即将出行' : '已完成',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => _showEditTripDialog(trip),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                    onPressed: () => _deleteTrip(trip['id']),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                trip['destination'] ?? '未命名目的地',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    '${_dateFormat.format(startDate)} - ${_dateFormat.format(endDate)}',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$duration天',
                      style: const TextStyle(color: Colors.blue, fontSize: 12),
                    ),
                  ),
                ],
              ),
              if (trip['budget'] != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.account_balance_wallet, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      '预算: ¥${trip['budget']}',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ],
              if (trip['notes'] != null && trip['notes'].toString().isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.notes, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        trip['notes'],
                        style: TextStyle(color: Colors.grey[700]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddTripDialog() async {
    await _showTripDialog();
  }

  Future<void> _showEditTripDialog(Map<String, dynamic> trip) async {
    await _showTripDialog(trip: trip);
  }

  Future<void> _showTripDialog({Map<String, dynamic>? trip}) async {
    final isEdit = trip != null;
    final destinationController = TextEditingController(text: trip?['destination'] ?? '');
    final budgetController = TextEditingController(text: trip?['budget']?.toString() ?? '');
    final notesController = TextEditingController(text: trip?['notes'] ?? '');
    
    DateTime startDate = isEdit 
        ? DateTime.parse(trip['startDate']) 
        : DateTime.now();
    DateTime endDate = isEdit 
        ? DateTime.parse(trip['endDate']) 
        : DateTime.now().add(const Duration(days: 3));

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? '编辑行程' : '添加行程',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: destinationController,
                decoration: const InputDecoration(
                  labelText: '目的地 *',
                  hintText: '输入城市或景点名称',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: startDate,
                          firstDate: DateTime(2024),
                          lastDate: DateTime(2030),
                        );
                        if (date != null) {
                          setModalState(() => startDate = date);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: '开始日期',
                          prefixIcon: Icon(Icons.calendar_today),
                          border: OutlineInputBorder(),
                        ),
                        child: Text(_dateFormat.format(startDate)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: endDate,
                          firstDate: startDate,
                          lastDate: DateTime(2030),
                        );
                        if (date != null) {
                          setModalState(() => endDate = date);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: '结束日期',
                          prefixIcon: Icon(Icons.calendar_today),
                          border: OutlineInputBorder(),
                        ),
                        child: Text(_dateFormat.format(endDate)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: budgetController,
                decoration: const InputDecoration(
                  labelText: '预算 (元)',
                  hintText: '预计花费金额',
                  prefixIcon: Icon(Icons.account_balance_wallet),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: '备注',
                  hintText: '其他信息...',
                  prefixIcon: Icon(Icons.notes),
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        if (destinationController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('请输入目的地')),
                          );
                          return;
                        }
                        
                        if (endDate.isBefore(startDate)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('结束日期不能早于开始日期')),
                          );
                          return;
                        }

                        final data = {
                          'destination': destinationController.text,
                          'startDate': _dateFormat.format(startDate),
                          'endDate': _dateFormat.format(endDate),
                          'budget': budgetController.text.isEmpty 
                              ? null 
                              : double.tryParse(budgetController.text),
                          'notes': notesController.text,
                        };

                        if (isEdit) {
                          await _db.updateTrip(trip['id'], data);
                        } else {
                          await _db.addTrip(data);
                        }
                        
                        if (mounted) {
                          Navigator.pop(context);
                          _loadData();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(isEdit ? '行程已更新' : '行程已添加')),
                          );
                        }
                      },
                      child: Text(isEdit ? '保存' : '添加'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteTrip(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个行程吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _db.deleteTrip(id);
      _loadData();
    }
  }

  void _showTripDetail(Map<String, dynamic> trip) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              trip['destination'],
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _buildDetailRow(Icons.calendar_today, '日期', 
                '${trip['startDate']} 至 ${trip['endDate']}'),
            if (trip['budget'] != null)
              _buildDetailRow(Icons.account_balance_wallet, '预算', '¥${trip['budget']}'),
            if (trip['notes'] != null && trip['notes'].toString().isNotEmpty)
              _buildDetailRow(Icons.notes, '备注', trip['notes']),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('关闭'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }
}
