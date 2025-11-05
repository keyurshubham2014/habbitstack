# Task 26: OpenRouter API Integration

**Status**: TODO
**Priority**: HIGH
**Estimated Time**: 3 hours
**Assigned To**: Claude
**Dependencies**: Task 21 (Authentication - requires cloud data)
**Completed**: -

---

## Objective

Integrate OpenRouter API (Claude 3.5 Sonnet) to power AI-driven habit insights, pattern recognition, and personalized recommendations.

## Acceptance Criteria

- [ ] OpenRouter API key configured securely
- [ ] API service wrapper created
- [ ] Rate limiting implemented (10 requests/day free tier)
- [ ] Error handling for API failures
- [ ] Request/response logging for debugging
- [ ] Cost tracking per user
- [ ] Streaming response support (optional)
- [ ] Fallback for offline mode

---

## Step-by-Step Instructions

### 1. Get OpenRouter API Key

1. Go to https://openrouter.ai/
2. Sign up and create account
3. Navigate to "API Keys" section
4. Generate new API key
5. Note the key securely

### 2. Configure Environment Variables

#### Create `.env` file (add to `.gitignore`)

```env
OPENROUTER_API_KEY=sk-or-v1-xxxxxxxxxxxxxxxxxxxxx
OPENROUTER_MODEL=anthropic/claude-3.5-sonnet
```

#### Add to `.gitignore`

```
.env
.env.local
.env.*.local
```

### 3. Add Dependencies

#### Update `pubspec.yaml`

```yaml
dependencies:
  http: ^1.2.1
  flutter_dotenv: ^5.1.0

dev_dependencies:
  flutter_secure_storage: ^9.2.2  # For secure key storage
```

### 4. Create OpenRouter Service

#### `lib/services/openrouter_service.dart`

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class OpenRouterConfig {
  static const String baseUrl = 'https://openrouter.ai/api/v1';
  static const String model = 'anthropic/claude-3.5-sonnet';
  static const int maxTokens = 2000;
  static const double temperature = 0.7;
}

class OpenRouterUsage {
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;
  final double estimatedCost;

  OpenRouterUsage({
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
    required this.estimatedCost,
  });

  factory OpenRouterUsage.fromJson(Map<String, dynamic> json) {
    return OpenRouterUsage(
      promptTokens: json['prompt_tokens'] as int? ?? 0,
      completionTokens: json['completion_tokens'] as int? ?? 0,
      totalTokens: json['total_tokens'] as int? ?? 0,
      estimatedCost: (json['estimated_cost'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class OpenRouterResponse {
  final String content;
  final OpenRouterUsage usage;
  final String model;

  OpenRouterResponse({
    required this.content,
    required this.usage,
    required this.model,
  });
}

class OpenRouterService {
  static final OpenRouterService _instance = OpenRouterService._internal();
  factory OpenRouterService() => _instance;
  OpenRouterService._internal();

  final _storage = FlutterSecureStorage();
  final _client = http.Client();

  String? _apiKey;
  int _requestsToday = 0;
  DateTime? _lastRequestDate;

  static const int _maxRequestsPerDay = 10; // Free tier limit

  /// Initialize with API key
  Future<void> initialize(String apiKey) async {
    _apiKey = apiKey;
    await _storage.write(key: 'openrouter_api_key', value: apiKey);
  }

  /// Load API key from secure storage
  Future<void> loadApiKey() async {
    _apiKey = await _storage.read(key: 'openrouter_api_key');
    if (_apiKey == null) {
      throw Exception('OpenRouter API key not configured');
    }
  }

  /// Check rate limit
  bool _checkRateLimit() {
    final now = DateTime.now();

    // Reset counter if new day
    if (_lastRequestDate == null ||
        now.day != _lastRequestDate!.day ||
        now.month != _lastRequestDate!.month ||
        now.year != _lastRequestDate!.year) {
      _requestsToday = 0;
      _lastRequestDate = now;
    }

    if (_requestsToday >= _maxRequestsPerDay) {
      return false;
    }

    _requestsToday++;
    return true;
  }

  /// Get remaining requests for today
  int get remainingRequests => _maxRequestsPerDay - _requestsToday;

  /// Send chat completion request
  Future<OpenRouterResponse> chatCompletion({
    required String systemPrompt,
    required String userPrompt,
    double? temperature,
    int? maxTokens,
  }) async {
    // Check rate limit
    if (!_checkRateLimit()) {
      throw Exception('Rate limit exceeded. Try again tomorrow.');
    }

    // Ensure API key is loaded
    if (_apiKey == null) {
      await loadApiKey();
    }

    final url = Uri.parse('${OpenRouterConfig.baseUrl}/chat/completions');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_apiKey',
      'HTTP-Referer': 'https://stackhabit.app', // Optional: Your app URL
      'X-Title': 'StackHabit', // Optional: Your app name
    };

    final body = jsonEncode({
      'model': OpenRouterConfig.model,
      'messages': [
        {
          'role': 'system',
          'content': systemPrompt,
        },
        {
          'role': 'user',
          'content': userPrompt,
        },
      ],
      'temperature': temperature ?? OpenRouterConfig.temperature,
      'max_tokens': maxTokens ?? OpenRouterConfig.maxTokens,
    });

    try {
      final response = await _client.post(
        url,
        headers: headers,
        body: body,
      ).timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final content = data['choices'][0]['message']['content'] as String;
        final usage = OpenRouterUsage.fromJson(data['usage'] ?? {});
        final model = data['model'] as String;

        // Log usage
        await _logUsage(usage);

        return OpenRouterResponse(
          content: content,
          usage: usage,
          model: model,
        );
      } else {
        final error = jsonDecode(response.body);
        throw Exception('OpenRouter API error: ${error['error']?['message'] ?? response.statusCode}');
      }
    } catch (e) {
      print('OpenRouter request failed: $e');
      rethrow;
    }
  }

  /// Analyze habit patterns (convenience method)
  Future<String> analyzeHabitPatterns({
    required String habitData,
    required String analysisType,
  }) async {
    final systemPrompt = '''You are an expert habit coach analyzing user data to provide personalized insights.
Focus on being encouraging, specific, and actionable.
Keep responses concise (under 200 words) and avoid generic advice.''';

    final userPrompt = '''Analyze this habit data and provide $analysisType:

$habitData

Provide specific, actionable insights based on the patterns you observe.''';

    final response = await chatCompletion(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
    );

    return response.content;
  }

  /// Log usage for cost tracking
  Future<void> _logUsage(OpenRouterUsage usage) async {
    // TODO: Save to database for cost tracking
    print('OpenRouter Usage:');
    print('  Tokens: ${usage.totalTokens}');
    print('  Cost: \$${usage.estimatedCost.toStringAsFixed(4)}');
  }

  /// Test API connection
  Future<bool> testConnection() async {
    try {
      final response = await chatCompletion(
        systemPrompt: 'You are a helpful assistant.',
        userPrompt: 'Say "Hello" in one word.',
        maxTokens: 10,
      );
      return response.content.isNotEmpty;
    } catch (e) {
      print('API connection test failed: $e');
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _client.close();
  }
}
```

### 5. Create Usage Tracking Model

#### `lib/models/ai_usage.dart`

```dart
class AIUsage {
  final String? id;
  final String userId;
  final String feature;        // 'insights', 'pattern_analysis', 'prediction'
  final int tokensUsed;
  final double estimatedCost;
  final DateTime createdAt;

  AIUsage({
    this.id,
    required this.userId,
    required this.feature,
    required this.tokensUsed,
    required this.estimatedCost,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'feature': feature,
      'tokens_used': tokensUsed,
      'estimated_cost': estimatedCost,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory AIUsage.fromMap(Map<String, dynamic> map) {
    return AIUsage(
      id: map['id'] as String?,
      userId: map['user_id'] as String,
      feature: map['feature'] as String,
      tokensUsed: map['tokens_used'] as int,
      estimatedCost: (map['estimated_cost'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
```

### 6. Update Supabase Schema

```sql
-- AI Usage Tracking table
CREATE TABLE IF NOT EXISTS ai_usage (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  feature TEXT NOT NULL,
  tokens_used INTEGER NOT NULL,
  estimated_cost DECIMAL(10, 6) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_ai_usage_user_id ON ai_usage(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_usage_created_at ON ai_usage(created_at);

-- RLS
ALTER TABLE ai_usage ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own AI usage"
  ON ai_usage FOR SELECT
  USING (auth.uid() = user_id);

-- Function to get monthly AI usage
CREATE OR REPLACE FUNCTION get_monthly_ai_usage(p_user_id UUID)
RETURNS TABLE (
  month DATE,
  total_requests INTEGER,
  total_tokens INTEGER,
  total_cost DECIMAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    DATE_TRUNC('month', created_at)::DATE as month,
    COUNT(*)::INTEGER as total_requests,
    SUM(tokens_used)::INTEGER as total_tokens,
    SUM(estimated_cost)::DECIMAL as total_cost
  FROM ai_usage
  WHERE user_id = p_user_id
    AND created_at >= NOW() - INTERVAL '6 months'
  GROUP BY DATE_TRUNC('month', created_at)
  ORDER BY month DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### 7. Create Provider

#### `lib/providers/openrouter_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/openrouter_service.dart';

// OpenRouter Service Provider
final openRouterServiceProvider = Provider<OpenRouterService>((ref) {
  final service = OpenRouterService();
  ref.onDispose(() => service.dispose());
  return service;
});

// Remaining Requests Provider
final remainingRequestsProvider = Provider<int>((ref) {
  final service = ref.watch(openRouterServiceProvider);
  return service.remainingRequests;
});
```

### 8. Create Settings Screen for API Configuration

#### `lib/screens/settings/ai_settings_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/openrouter_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class AISettingsScreen extends ConsumerStatefulWidget {
  const AISettingsScreen({super.key});

  @override
  ConsumerState<AISettingsScreen> createState() => _AISettingsScreenState();
}

class _AISettingsScreenState extends ConsumerState<AISettingsScreen> {
  final _apiKeyController = TextEditingController();
  bool _isTestingConnection = false;
  String? _connectionStatus;

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.read(openRouterServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('AI Settings', style: AppTextStyles.headline),
        backgroundColor: AppColors.primaryBg,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Info Card
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.psychology, color: AppColors.deepBlue),
                      SizedBox(width: 12),
                      Text('AI Insights (Premium)', style: AppTextStyles.title),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Get personalized insights powered by Claude AI. Requires OpenRouter API key.',
                    style: AppTextStyles.body.copyWith(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 24),

          // API Key Input
          Text('OpenRouter API Key', style: AppTextStyles.title),
          SizedBox(height: 8),
          TextField(
            controller: _apiKeyController,
            obscureText: true,
            decoration: InputDecoration(
              hintText: 'sk-or-v1-...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: IconButton(
                icon: Icon(Icons.save),
                onPressed: _saveApiKey,
              ),
            ),
          ),

          SizedBox(height: 16),

          // Test Connection Button
          ElevatedButton.icon(
            onPressed: _isTestingConnection ? null : _testConnection,
            icon: _isTestingConnection
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.wifi_tethering),
            label: Text('Test Connection'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.deepBlue,
              padding: EdgeInsets.all(16),
            ),
          ),

          if (_connectionStatus != null) ...[
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _connectionStatus!.contains('Success')
                    ? AppColors.successGreen.withOpacity(0.1)
                    : AppColors.softRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _connectionStatus!,
                style: AppTextStyles.body.copyWith(
                  color: _connectionStatus!.contains('Success')
                      ? AppColors.successGreen
                      : AppColors.softRed,
                ),
              ),
            ),
          ],

          SizedBox(height: 24),

          // Usage Stats
          Text('Daily Usage', style: AppTextStyles.title),
          SizedBox(height: 12),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Requests Today', style: AppTextStyles.body),
                  Text(
                    '${10 - service.remainingRequests} / 10',
                    style: AppTextStyles.title,
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 24),

          // Get API Key Link
          TextButton.icon(
            onPressed: () {
              // TODO: Open browser to openrouter.ai
            },
            icon: Icon(Icons.open_in_new),
            label: Text('Get API Key from OpenRouter'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveApiKey() async {
    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isEmpty) {
      _showError('Please enter an API key');
      return;
    }

    try {
      final service = ref.read(openRouterServiceProvider);
      await service.initialize(apiKey);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('API key saved successfully')),
      );
    } catch (e) {
      _showError('Error saving API key: $e');
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTestingConnection = true;
      _connectionStatus = null;
    });

    try {
      final service = ref.read(openRouterServiceProvider);
      final success = await service.testConnection();

      setState(() {
        _connectionStatus = success
            ? 'Success! API connection working.'
            : 'Failed to connect. Check your API key.';
        _isTestingConnection = false;
      });
    } catch (e) {
      setState(() {
        _connectionStatus = 'Error: $e';
        _isTestingConnection = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.softRed,
      ),
    );
  }
}
```

---

## Verification Checklist

- [ ] OpenRouter API key configured
- [ ] API service makes successful requests
- [ ] Rate limiting enforces 10 requests/day
- [ ] Usage tracking saves to database
- [ ] Error messages clear and actionable
- [ ] Test connection works
- [ ] Cost tracking implemented
- [ ] Secure storage for API key

---

## Testing Scenarios

1. **Configure API**: Enter key, save, verify stored
2. **Test Connection**: Click test, verify success message
3. **Rate Limit**: Make 10 requests, verify 11th blocked
4. **Invalid Key**: Enter wrong key, verify error message
5. **Usage Tracking**: Make request, verify logged to database
6. **Cost Calculation**: Verify token costs calculated correctly

---

## Security Notes

- **Never commit API keys** to version control
- Store keys in `.env` (local) and secure storage (production)
- Use environment variables in production (not hardcoded)
- Implement rate limiting to prevent abuse
- Monitor costs via OpenRouter dashboard

---

## Next Task

After completion, proceed to: [27_ai_insights_screen.md](./27_ai_insights_screen.md)

---

**Last Updated**: 2025-11-05
