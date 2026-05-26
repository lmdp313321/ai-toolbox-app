import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 手机号归属地查询页面
class PhoneLookupPage extends StatefulWidget {
  const PhoneLookupPage({super.key});

  @override
  State<PhoneLookupPage> createState() => _PhoneLookupPageState();
}

class _PhoneLookupPageState extends State<PhoneLookupPage> {
  final TextEditingController _phoneController = TextEditingController();
  Map<String, dynamic>? _phoneInfo;
  bool _isQuerying = false;

  // 手机号段数据库（简化版）
  final Map<String, Map<String, String>> _phoneDB = {
    '130': {'province': '北京', 'carrier': '中国联通'},
    '131': {'province': '北京', 'carrier': '中国联通'},
    '132': {'province': '北京', 'carrier': '中国联通'},
    '133': {'province': '北京', 'carrier': '中国电信'},
    '134': {'province': '北京', 'carrier': '中国移动'},
    '135': {'province': '北京', 'carrier': '中国移动'},
    '136': {'province': '北京', 'carrier': '中国移动'},
    '137': {'province': '北京', 'carrier': '中国移动'},
    '138': {'province': '北京', 'carrier': '中国移动'},
    '139': {'province': '北京', 'carrier': '中国移动'},
    '150': {'province': '北京', 'carrier': '中国移动'},
    '151': {'province': '北京', 'carrier': '中国移动'},
    '152': {'province': '北京', 'carrier': '中国移动'},
    '153': {'province': '北京', 'carrier': '中国电信'},
    '155': {'province': '北京', 'carrier': '中国联通'},
    '156': {'province': '北京', 'carrier': '中国联通'},
    '157': {'province': '北京', 'carrier': '中国移动'},
    '158': {'province': '北京', 'carrier': '中国移动'},
    '159': {'province': '北京', 'carrier': '中国移动'},
    '180': {'province': '北京', 'carrier': '中国电信'},
    '181': {'province': '北京', 'carrier': '中国电信'},
    '182': {'province': '北京', 'carrier': '中国移动'},
    '183': {'province': '北京', 'carrier': '中国移动'},
    '184': {'province': '北京', 'carrier': '中国移动'},
    '185': {'province': '北京', 'carrier': '中国联通'},
    '186': {'province': '北京', 'carrier': '中国联通'},
    '187': {'province': '北京', 'carrier': '中国移动'},
    '188': {'province': '北京', 'carrier': '中国移动'},
    '189': {'province': '北京', 'carrier': '中国电信'},
  };

  Future<void> _queryPhone() async {
    final phone = _phoneController.text.trim().replaceAll(RegExp(r'\s+|-'), '');
    
    if (phone.length != 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入11位手机号码')),
      );
      return;
    }

    setState(() => _isQuerying = true);

    // 模拟查询
    await Future.delayed(const Duration(milliseconds: 500));

    final prefix = phone.substring(0, 3);
    final info = _phoneDB[prefix];

    setState(() {
      _isQuerying = false;
      if (info != null) {
        _phoneInfo = {
          'phone': phone,
          'province': info['province'],
          'carrier': info['carrier'],
          'type': _getCardType(phone),
        };
      } else {
        _phoneInfo = {
          'phone': phone,
          'province': '未知地区',
          'carrier': '未知运营商',
          'type': '未知',
        };
      }
    });
  }

  String _getCardType(String phone) {
    // 根据号段判断卡类型
    final prefixes = {
      '13': '普通卡',
      '15': '普通卡',
      '18': '普通卡',
    };
    return prefixes[phone.substring(0, 2)] ?? '物联网卡';
  }

  Color _getCarrierColor(String carrier) {
    if (carrier.contains('移动')) return Colors.blue;
    if (carrier.contains('联通')) return Colors.orange;
    if (carrier.contains('电信')) return Colors.red;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('手机号归属地'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 手机号输入
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: '手机号码',
                hintText: '请输入11位手机号',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.phone_android),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _phoneController.clear();
                    setState(() => _phoneInfo = null);
                  },
                ),
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
              onSubmitted: (_) => _queryPhone(),
            ),
            
            const SizedBox(height: 16),
            
            // 查询按钮
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isQuerying ? null : _queryPhone,
                icon: _isQuerying
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                label: Text(_isQuerying ? '查询中...' : '查询归属地'),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 查询结果
            if (_phoneInfo != null) ...[
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // 手机号显示
                      Text(
                        _phoneInfo!['phone'],
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // 运营商
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _getCarrierColor(_phoneInfo!['carrier'])
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _phoneInfo!['carrier'],
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _getCarrierColor(_phoneInfo!['carrier']),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      
                      // 详细信息
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoItem(
                              icon: Icons.location_on,
                              label: '归属地',
                              value: _phoneInfo!['province'],
                            ),
                          ),
                          Expanded(
                            child: _buildInfoItem(
                              icon: Icons.sim_card,
                              label: '卡类型',
                              value: _phoneInfo!['type'],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 操作按钮
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: _phoneInfo!['phone']),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('已复制手机号')),
                        );
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('复制号码'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // 分享功能
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('分享功能')),
                        );
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('分享结果'),
                    ),
                  ),
                ],
              ),
            ],
            
            // 号段说明
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '运营商号段',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildCarrierInfo('中国移动', '134-139, 147-152, 157-159, 178, 182-184, 187-188, 198', Colors.blue),
                    const SizedBox(height: 8),
                    _buildCarrierInfo('中国联通', '130-132, 145, 155-156, 166, 175, 176, 185-186', Colors.orange),
                    const SizedBox(height: 8),
                    _buildCarrierInfo('中国电信', '133, 149, 153, 173, 177, 180-181, 189, 199', Colors.red),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[600]),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildCarrierInfo(String name, String ranges, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              Text(ranges, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ),
      ],
    );
  }
}
