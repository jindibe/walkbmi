import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '만보기와 BMI 계산기', // 앱의 제목
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: '만보기와 BMI 계산기'), // 홈 화면으로 MyHomePage를 사용
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState(); // MyHomePage 상태를 관리하는 _MyHomePageState 클래스 생성
}

class _MyHomePageState extends State<MyHomePage> {
  AccelerometerEvent? _lastEvent;
  StreamSubscription<AccelerometerEvent>? _streamSubscription;
  int _steps = 0;
  double _previousY = 0.0;
  double _weight = 0.0; // 체중 변수 추가
  double _height = 0.0; // 신장 변수 추가

  @override
  void initState() {
    super.initState();
    _listenToSensor();
    _loadSteps(); // 이전에 저장된 걸음 수 불러오기
    _resetStepsAtMidnight(); // 자정에 걸음 수 초기화
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadSteps(); // 앱이 다시 실행될 때 저장된 걸음 수 불러오기
    }
  }

  void _listenToSensor() {
    _streamSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
      setState(() {
        _lastEvent = event;
        _calculateSteps();
      });
    });
  }

  void _calculateSteps() {
    double y = _lastEvent?.y ?? 0.0;
    if ((_previousY < 0 && y > 0) || (_previousY > 0 && y < 0)) {
      setState(() {
        _steps++;
      });
    }
    _previousY = y;
  }

  void _resetStepsAtMidnight() {
    Timer.periodic(Duration(days: 1), (timer) {
      DateTime now = DateTime.now();
      if (now.hour == 0 && now.minute == 0 && now.second == 0) {
        setState(() {
          _steps = 0;
        });
      }
    });
  }

  void _loadSteps() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _steps = prefs.getInt('steps') ?? 0;
    });
  }

  void _saveSteps() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('steps', _steps);
  }

  double _calculateBMI() {
    // BMI 지수 계산
    if (_height > 0.0) {
      double heightInMeters = _height / 100;
      return _weight / (heightInMeters * heightInMeters);
    } else {
      return 0.0;
    }
  }

  @override
  void dispose() {
    super.dispose();
    _streamSubscription?.cancel();
    _saveSteps(); // 앱이 종료될 때 걸음 수 저장
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title), // 상단 앱바에 제목 표시
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    '체중 (kg):', // 체중 입력 텍스트
                  ),
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        _weight = double.tryParse(value) ?? 0.0;
                      });
                    },
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 16.0),
                  Text(
                    '신장 (cm):', // 신장 입력 텍스트
                  ),
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        _height = double.tryParse(value) ?? 0.0;
                      });
                    },
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    '걸음 수:', // 걸음 수 텍스트
                  ),
                  Text(
                    '$_steps', // 현재 걸음 수
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'BMI 지수:', // BMI 지수 텍스트
                  ),
                  Text(
                    _calculateBMI().toStringAsFixed(2), // BMI 지수 계산 결과 표시 (소수점 둘째 자리까지)
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
