import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

class CheckInRepository {
  Dio dio = Dio();

  Future<void> checkIn(List<double> embedding) async {
    await dio.post(
      'https://dev.upsen.id/api/checkin-public',
      data: {
        'face_embedding': embedding,
        'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'time_in': DateFormat('HH:mm:ss').format(DateTime.now()),
      },
    );
  }
}
