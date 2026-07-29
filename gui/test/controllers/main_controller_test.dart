import 'package:flutter_test/flutter_test.dart';
// เปลี่ยน path ให้ตรงกับชื่อโปรเจกต์จริงของคุณ
import 'package:gui/controllers/main_controller.dart';

void main() {
  group('MainController Tests', () {
    test('Initial state should be correct', () {
      final controller = MainController();
      
      expect(controller.isLoading, false);
      expect(controller.currentData, null);
      expect(controller.errorMessage, isEmpty);
    });

    test('fetchData should update loading and load data successfully', () async {
      final controller = MainController();
      
      // เริ่มเรียกฟังก์ชัน
      final future = controller.fetchData();
      
      // เช็กจังหวะที่กำลังโหลด
      expect(controller.isLoading, true);
      
      // รอจนกว่าจะทำงานเสร็จ
      await future;
      
      // เช็กสถานะหลังโหลดเสร็จ
      expect(controller.isLoading, false);
      expect(controller.currentData, isNotNull);
      expect(controller.currentData?.id, '001');
      expect(controller.currentData?.status, 'Active');
    });
  });
}