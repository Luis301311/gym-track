import 'package:cloud_functions/cloud_functions.dart';

import '../../domain/usecases/coach.dart';

/// Coach con IA: llama a la Cloud Function `coachWorkout` (functions/), que
/// es la única que conoce la llave del modelo. La app nunca la ve.
class CloudFunctionAiCoach implements AiCoach {
  final FirebaseFunctions functions;
  const CloudFunctionAiCoach(this.functions);

  @override
  Future<String> workoutFeedback(CoachRequest request) async {
    final result = await functions
        .httpsCallable('coachWorkout')
        .call<Map<String, dynamic>>(request.toPayload());
    return (result.data['message'] as String?) ?? '';
  }
}
