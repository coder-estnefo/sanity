import '../../domain/entities/addiction.dart';

class AddictionModel {
  static Map<String, dynamic> toJson(Addiction a) => {
        'id': a.id,
        'name': a.name,
        'quitDate': a.quitDate.toIso8601String(),
        'relapses': a.relapses,
      };

  static Addiction fromJson(Map<String, dynamic> j) => Addiction(
        id: j['id'] as String,
        name: j['name'] as String,
        quitDate: DateTime.parse(j['quitDate'] as String),
        relapses: (j['relapses'] as int?) ?? 0,
      );
}

