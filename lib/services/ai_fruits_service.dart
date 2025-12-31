// lib/services/ai_fruits_service.dart

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;

/// Résultat de prédiction avec métadonnées enrichies
class FruitsPrediction {
  final String label;
  final double confidence;
  final List<ClassProbability>? topPredictions;
  final Duration inferenceTime;

  FruitsPrediction({
    required this.label,
    required this.confidence,
    this.topPredictions,
    required this.inferenceTime,
  });
}

/// Label + probabilité
class ClassProbability {
  final String label;
  final double probability;

  ClassProbability({
    required this.label,
    required this.probability,
  });
}

/// Service singleton pour l’IA fruits
class FruitsAiService {
  FruitsAiService._internal();

  static final FruitsAiService instance = FruitsAiService._internal();

  tfl.Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isInitialized = false;

  int _totalInferences = 0;
  Duration _totalInferenceTime = Duration.zero;

  bool get isInitialized => _isInitialized;

  double? get averageLatencyMs {
    if (_totalInferences == 0) return null;
    return _totalInferenceTime.inMilliseconds / _totalInferences;
  }

  /// Initialisation du modèle TFLite + labels
  Future<void> init() async {
    if (_isInitialized && _interpreter != null) return;

    debugPrint('🔄 Initialisation du modèle TFLite...');

    try {
      final options = tfl.InterpreterOptions()
        ..threads = 4; // CPU multithread

      // ⚠️ NE PAS activer NNAPI ici : ça fait planter sur beaucoup d’émulateurs.
      // Si tu veux tester plus tard sur DEVICE réel :
      // try { options.useNnApiForAndroid = true; } catch (_) {}

      _interpreter = await tfl.Interpreter.fromAsset(
        'assets/models/fruits_cnn.tflite',
        options: options,
      );

      // Charger les labels
      final labelsStr =
      await rootBundle.loadString('assets/models/fruits_labels.txt');
      _labels = labelsStr
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      _isInitialized = true;
      debugPrint(
          '✅ Modèle TFLite initialisé. Inputs: ${_interpreter!.getInputTensors().length}, '
              'Outputs: ${_interpreter!.getOutputTensors().length}, '
              'Labels: ${_labels.length}');
    } catch (e, st) {
      debugPrint('❌ Erreur d\'initialisation : $e');
      debugPrint('STACK: $st');
      rethrow;
    }
  }

  /// API principale pour classifier une image
  Future<FruitsPrediction> classifyImage(File imageFile) async {
    return _classify(imageFile);
  }

  /// Logique de classification avec métriques
  Future<FruitsPrediction> _classify(File imageFile) async {
    if (_interpreter == null || !_isInitialized) {
      await init();
    }

    final stopwatch = Stopwatch()..start();

    try {
      // 1) Lire et décoder l'image
      final bytes = await imageFile.readAsBytes();
      final img.Image? original = img.decodeImage(bytes);

      if (original == null) {
        throw Exception("Impossible de décoder l'image");
      }

      // 2) Prétraitement de l'image
      final processedInput = _preprocessImage(original);

      // 3) Préparer le buffer de sortie en fonction du TENSOR DE SORTIE
      final outputTensor = _interpreter!.getOutputTensors().first;
      // On suppose une forme [1, N] ou [1, 1, N]
      final shape = outputTensor.shape;
      final numClasses = shape.last;

      final output = List.generate(
        1,
            (_) => List<double>.filled(numClasses, 0.0),
      );

      // 4) Inférence
      _interpreter!.run(processedInput, output);
      stopwatch.stop();

      final inferenceTime = stopwatch.elapsed;
      _totalInferences++;
      _totalInferenceTime += inferenceTime;

      debugPrint('⚡ Inférence effectuée en ${inferenceTime.inMilliseconds} ms');

      // 5) Post-traitement des résultats
      final probs = output[0];
      final topPredictions = _getTopPredictions(probs, topK: 3);
      final bestPrediction = topPredictions.first;

      return FruitsPrediction(
        label: bestPrediction.label,
        confidence: bestPrediction.probability,
        topPredictions: topPredictions,
        inferenceTime: inferenceTime,
      );
    } catch (e, st) {
      stopwatch.stop();
      debugPrint('❌ Erreur de classification : $e');
      debugPrint('STACK: $st');
      rethrow;
    }
  }

  List<List<List<List<double>>>> _preprocessImage(img.Image original) {
    // 1) Redimensionner en 32x32
    final img.Image resized = img.copyResize(
      original,
      width: 32,
      height: 32,
      interpolation: img.Interpolation.cubic,
    );

    // 2) Garder les pixels en 0..255 (PAS de /255, le modèle le fait déjà)
    final List<List<List<double>>> imageData = List.generate(
      32,
          (y) => List.generate(
        32,
            (x) {
          final img.Pixel pixel = resized.getPixel(x, y);

          final int rInt = pixel.getChannel(img.Channel.red).toInt();
          final int gInt = pixel.getChannel(img.Channel.green).toInt();
          final int bInt = pixel.getChannel(img.Channel.blue).toInt();

          final double r = rInt.toDouble(); // 0..255
          final double g = gInt.toDouble();
          final double b = bInt.toDouble();

          return <double>[r, g, b];
        },
      ),
    );

    return <List<List<List<double>>>>[imageData];
  }




  /// Récupérer les top K prédictions (triées)
  List<ClassProbability> _getTopPredictions(
      List<double> probabilities, {
        int topK = 3,
      }) {
    final predictions = <ClassProbability>[];

    for (var i = 0; i < probabilities.length; i++) {
      final label = i < _labels.length ? _labels[i] : 'Class $i';
      predictions.add(
        ClassProbability(
          label: label,
          probability: probabilities[i],
        ),
      );
    }

    // Trier par probabilité décroissante
    predictions.sort((a, b) => b.probability.compareTo(a.probability));

    return predictions.take(math.min(topK, predictions.length)).toList();
  }

  /// Nettoyer les ressources
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
    debugPrint('🗑️ Ressources du modèle libérées');
  }

  /// Réinitialiser les statistiques
  void resetStats() {
    _totalInferences = 0;
    _totalInferenceTime = Duration.zero;
    debugPrint('📊 Statistiques réinitialisées');
  }
}
