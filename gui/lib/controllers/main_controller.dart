import 'package:flutter/material.dart';
import '../models/data_model.dart';

class MainController extends ChangeNotifier {
  bool isLoading = false;
  DataModel? currentData;
  String errorMessage = '';

  // จำลองฟังก์ชันเรียกข้อมูลหรือคุยกับ Backend
  Future<void> fetchData() async {
    isLoading = true;
    errorMessage = '';
    notifyListeners();

    try {
      // จำลองการดึงข้อมูล
      await Future.delayed(const Duration(seconds: 1));
      currentData = DataModel(id: '001', status: 'Active', estimate: 99.5);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}