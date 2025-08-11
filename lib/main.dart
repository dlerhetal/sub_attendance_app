import 'package:flutter/material.dart';
import 'package:gsheets/gsheets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sub Attendance',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Subcontractor Attendance'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _usernameController = TextEditingController();
  final _subcontractorController = TextEditingController();
  final _startController = TextEditingController();
  final _endController = TextEditingController();
  final _countController = TextEditingController();
  final _commentController = TextEditingController();

  String? _username;
  List<String> _subcontractors = [];
  String? _selectedSubcontractor;

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _updateSubcontractorsFromSheets();
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username');
      if (_username != null) {
        _usernameController.text = _username!;
      }
    });
  }

  Future<void> _saveUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
    setState(() {
      _username = username;
    });
  }

  Future<String> _getCorrectedCredentials() async {
    final jsonCredentials = await rootBundle.loadString('assets/credentials.json');
    return jsonCredentials;
  }

  Future<void> _updateSubcontractorsFromSheets() async {
    try {
      print('[1] Starting subcontractor update from Google Sheets...');

      final correctedCredentials = await _getCorrectedCredentials();
      print('[2] Loaded credentials file content.');

      final gsheets = GSheets(json.decode(correctedCredentials));
      print('[3] GSheets object initialized successfully.');

      print('[4] Attempting to access spreadsheet by ID...');
      final ss = await gsheets.spreadsheet('15H1fsYaC1sN_dd2idWlumand3k206IhiFmQOIXPPeMw');
      print('[5] Successfully accessed spreadsheet.');

      final sheet = ss.worksheetByTitle('Lists');
      if (sheet != null) {
        final values = await sheet.values.column(1, fromRow: 2);
        setState(() {
          _subcontractors = values;
          if (_subcontractors.isNotEmpty) {
            _selectedSubcontractor = _subcontractors[0];
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subcontractors updated successfully!')),
        );
      }
    } on FormatException catch (e) {
      print('ERROR at step [3] or before: Invalid format - $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Invalid credentials format. Please check the credentials file.')),
      );
    } catch (e) {
      print('ERROR during GSheets operation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error connecting to Google Sheets: $e')),
      );
    }
  }

  Future<void> _submitData() async {
    if (_formKey.currentState!.validate()) {
      try {
        final correctedCredentials = await _getCorrectedCredentials();
        final gsheets = GSheets(json.decode(correctedCredentials));
        final ss = await gsheets.spreadsheet('15H1fsYaC1sN_dd2idWlumand3k206IhiFmQOIXPPeMw');
        final sheet = ss.worksheetByTitle('Data');

        if (sheet != null) {
          final now = DateTime.now();
          final timestamp =
              '${now.month}/${now.day}/${now.year} ${now.hour}:${now.minute}:${now.second}';

          await sheet.values.appendRow([
            timestamp,
            _username,
            _selectedSubcontractor,
            _startController.text,
            _endController.text,
            _countController.text,
            _commentController.text,
          ]);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data submitted successfully!')),
          );
          _formKey.currentState!.reset();
          _startController.clear();
          _endController.clear();
          _countController.clear();
          _commentController.clear();
        }
      } on FormatException catch (e) {
        print('Error submitting data: Invalid format - $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Invalid credentials format. Please check the credentials file.')),
        );
      } catch (e) {
        print('Error submitting data: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _username == null
            ? _buildUsernameInput()
            : _buildAttendanceForm(),
      ),
    );
  }

  Widget _buildUsernameInput() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextFormField(
            controller: _usernameController,
            decoration: const InputDecoration(labelText: 'Enter Your Name'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _saveUsername(_usernameController.text);
              }
            },
            child: const Text('Save Name'),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceForm() {
    return Form(
      key: _formKey,
      child: ListView(
        children: [
          Text('Welcome, $_username!', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: _selectedSubcontractor,
            decoration: const InputDecoration(labelText: 'Subcontractor'),
            items: _subcontractors.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                _selectedSubcontractor = newValue;
              });
            },
            validator: (value) => value == null ? 'Please select a subcontractor' : null,
          ),
          TextFormField(
            controller: _startController,
            decoration: const InputDecoration(labelText: 'Start Time'),
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (time != null) {
                _startController.text = time.format(context);
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a start time';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _endController,
            decoration: const InputDecoration(labelText: 'End Time'),
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (time != null) {
                _endController.text = time.format(context);
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an end time';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _countController,
            decoration: const InputDecoration(labelText: 'Count'),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a count';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _commentController,
            decoration: const InputDecoration(labelText: 'Comment'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _submitData,
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
