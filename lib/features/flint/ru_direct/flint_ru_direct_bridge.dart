import 'dart:convert';
import 'dart:io';

import 'package:hiddify/core/directories/directories_provider.dart';
import 'package:hiddify/features/route_rules/notifier/rule_notifier.dart';
import 'package:hiddify/features/route_rules/notifier/rules_notifier.dart';
import 'package:hiddify/hiddifycore/generated/v2/config/route_rule.pb.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../api/flint_backend_api.dart';
import '../flint_config.dart';

class FlintRuDirectSnapshot {
  const FlintRuDirectSnapshot({
    required this.domains,
    this.version,
    this.updatedAt,
  });

  final List<String> domains;
  final String? version;
  final DateTime? updatedAt;
}

class FlintRuDirectBridge {
  FlintRuDirectBridge(this.api);

  static const ruleName = 'Flint RU Direct';

  final FlintBackendApi api;

  Future<FlintRuDirectSnapshot> download() async {
    final raw = await api.getAny(FlintConfig.ruDirectPath);

    List<dynamic>? items;
    String? version;

    if (raw is List) {
      items = raw;
    } else if (raw is Map) {
      version = raw['version']?.toString();
      final value = raw['domains'] ??
          raw['domainSuffixes'] ??
          raw['items'] ??
          raw['data'];
      if (value is List) items = value;
    }

    if (items == null) {
      throw FlintBackendException(
        'RU Direct API не вернул список domains',
      );
    }

    final domains = items
        .map((e) => e.toString().trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .map((e) => e.startsWith('.') ? e.substring(1) : e)
        .toSet()
        .toList(growable: false)
      ..sort();

    if (domains.isEmpty) {
      throw FlintBackendException('RU Direct список пуст');
    }

    return FlintRuDirectSnapshot(
      domains: domains,
      version: version,
      updatedAt: DateTime.now(),
    );
  }

  Future<File> _cacheFile(WidgetRef ref) async {
    final directories = ref.read(appDirectoriesProvider).requireValue;
    return File('${directories.baseDir.path}/flint_ru_direct.json');
  }

  Future<void> saveCache(
    WidgetRef ref,
    FlintRuDirectSnapshot snapshot,
  ) async {
    final file = await _cacheFile(ref);
    await file.parent.create(recursive: true);

    await file.writeAsString(
      jsonEncode({
        'version': snapshot.version,
        'updatedAt': snapshot.updatedAt?.toIso8601String(),
        'domains': snapshot.domains,
      }),
      flush: true,
    );
  }

  Future<FlintRuDirectSnapshot?> loadCache(WidgetRef ref) async {
    final file = await _cacheFile(ref);
    if (!await file.exists()) return null;

    try {
      final raw = jsonDecode(await file.readAsString());
      if (raw is! Map) return null;

      final domainsRaw = raw['domains'];
      if (domainsRaw is! List) return null;

      final domains = domainsRaw
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList(growable: false);

      if (domains.isEmpty) return null;

      return FlintRuDirectSnapshot(
        domains: domains,
        version: raw['version']?.toString(),
        updatedAt: DateTime.tryParse(
          raw['updatedAt']?.toString() ?? '',
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Future<FlintRuDirectSnapshot> refreshAndApply(
    WidgetRef ref,
  ) async {
    try {
      final snapshot = await download();
      await saveCache(ref, snapshot);
      await apply(ref, snapshot.domains, enabled: true);
      return snapshot;
    } catch (_) {
      final cached = await loadCache(ref);
      if (cached == null) rethrow;

      await apply(ref, cached.domains, enabled: true);
      return cached;
    }
  }

  Future<void> apply(
    WidgetRef ref,
    List<String> domains, {
    required bool enabled,
  }) async {
    final currentRules = ref.read(rulesNotifierProvider);

    int? existingOrder;
    for (final rule in currentRules) {
      if (rule.name == ruleName) {
        existingOrder = rule.listOrder;
        break;
      }
    }

    final ruleNotifier = ref.read(
      RuleNotifierProvider(existingOrder).notifier,
    );

    ruleNotifier.update(RuleEnum.name, ruleName);
    ruleNotifier.update(RuleEnum.outbound, Outbound.direct);
    ruleNotifier.update(RuleEnum.network, Network.all);
    ruleNotifier.update(RuleEnum.domainSuffix, domains);

    await ruleNotifier.save();

    final rulesAfterSave = ref.read(rulesNotifierProvider);
    int? finalOrder = existingOrder;

    if (finalOrder == null) {
      for (final rule in rulesAfterSave) {
        if (rule.name == ruleName) {
          finalOrder = rule.listOrder;
          break;
        }
      }
    }

    if (finalOrder != null) {
      await ref
          .read(rulesNotifierProvider.notifier)
          .updateEnabled(enabled, finalOrder);
    }
  }

  Future<void> setEnabled(
    WidgetRef ref,
    bool enabled,
  ) async {
    final currentRules = ref.read(rulesNotifierProvider);
    for (final rule in currentRules) {
      if (rule.name == ruleName) {
        await ref
            .read(rulesNotifierProvider.notifier)
            .updateEnabled(enabled, rule.listOrder);
        return;
      }
    }

    if (enabled) {
      final cached = await loadCache(ref);
      if (cached != null) {
        await apply(ref, cached.domains, enabled: true);
      } else {
        await refreshAndApply(ref);
      }
    }
  }

  bool isEnabled(WidgetRef ref) {
    for (final rule in ref.read(rulesNotifierProvider)) {
      if (rule.name == ruleName) {
        return rule.enabled;
      }
    }
    return false;
  }

  int currentDomainCount(WidgetRef ref) {
    for (final rule in ref.read(rulesNotifierProvider)) {
      if (rule.name == ruleName) {
        return rule.domainSuffixes.length;
      }
    }
    return 0;
  }
}
