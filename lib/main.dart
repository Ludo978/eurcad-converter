import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

Future<double> fetchRate() async {
  const String url =
      'https://api.apilayer.com/fixer/latest?base=EUR&symbols=CAD';
  final Map<String, String> headers = {
    'apiKey': 'k0iDMF05S0DiRuEvZzgzy3j9J1BxstPG'
  };
  final response = await http.get(Uri.parse(url), headers: headers);
  if (response.statusCode == 200) {
    final Map<String, dynamic> data = jsonDecode(response.body);
    final double rate = data['rates']['CAD'];
    return rate;
  } else {
    throw Exception('Failed to load data');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Convertisseur',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Convertisseur'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _controller = TextEditingController();
  late Future<double> _response;
  double _eurToCad = 0.0;
  double _cadToEur = 0.0;
  String _result = '';
  bool _convertToCad = false;

  @override
  void initState() {
    super.initState();
    _response = fetchRate();
    _setRateValue();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _setRateValue() async {
    final response = await _response;
    setState(() {
      _eurToCad = response;
      _cadToEur = 1 / _eurToCad;
    });
  }

  void _calculateResult() {
    setState(() {
      try {
        final value =
            NumberFormat().parse(_controller.text.replaceAll(',', '.'));
        double result = value * (_convertToCad ? _eurToCad : _cadToEur);
        _result = NumberFormat.currency(
          locale: 'fr_FR',
          symbol: _convertToCad ? '\$' : '€',
          decimalDigits: 2,
        ).format(result);
      } on Exception {
        _result = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('\$'),
              const SizedBox(width: 8),
              Switch(
                value: _convertToCad,
                onChanged: (value) {
                  setState(() {
                    _convertToCad = value;
                  });
                  _calculateResult();
                },
                activeColor: Colors.blue,
                inactiveThumbColor: Colors.blue,
                activeTrackColor: Colors.lightBlue,
                inactiveTrackColor: Colors.lightBlue,
              ),
              const SizedBox(width: 8),
              const Text('€'),
            ],
          ),
          Column(
            children: [
              SizedBox(
                width: 100,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 42),
                  child: TextField(
                    controller: _controller,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      alignLabelWithHint: true,
                      suffixText: _convertToCad ? '\u20AC' : '\u0024',
                    ),
                    textAlign: TextAlign.center,
                    autofocus: true,
                    onChanged: (value) => {
                      if (value.startsWith(',') || value.startsWith('.'))
                        {
                          _controller.text = '0$value',
                          _controller.selection = TextSelection.fromPosition(
                              TextPosition(offset: _controller.text.length))
                        },
                      _calculateResult(),
                    },
                  ),
                ),
              ),
              Text(
                'Résultat: $_result',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
