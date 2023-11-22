import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ingresos y Egresos',
      home: IngresosEgresosScreen(),
    );
  }
}

class IngresosEgresosScreen extends StatefulWidget {
  @override
  _IngresosEgresosScreenState createState() => _IngresosEgresosScreenState();
}

class _IngresosEgresosScreenState extends State<IngresosEgresosScreen> {
  late Database _database;
  TextEditingController ingresoController = TextEditingController();
  TextEditingController egresoController = TextEditingController();
  double saldo = 0.0;

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  void _initDatabase() async {
    _database = await openDatabase(
      join(await getDatabasesPath(), 'ingresos_egresos_database.db'),
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE registros(id INTEGER PRIMARY KEY, ingreso REAL, egreso REAL)",
        );
      },
      version: 1,
    );
  }

  void _actualizarSaldo() async {
    final List<Map<String, dynamic>> registros = await _database.query('registros');
    double ingresos = 0.0;
    double egresos = 0.0;

    for (var registro in registros) {
      ingresos += registro['ingreso'];
      egresos += registro['egreso'];
    }

    setState(() {
      saldo = ingresos - egresos;
    });
  }

void _registrarTransaccion(BuildContext context) async {
  double ingreso = double.tryParse(ingresoController.text) ?? 0.0;
  double egreso = double.tryParse(egresoController.text) ?? 0.0;

  if (egreso > ingreso) {
    // Mostrar mensaje de error
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text('Los egresos no pueden ser mayores a los ingresos.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  } else {
    await _database.insert(
      'registros',
      {'ingreso': ingreso, 'egreso': egreso},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    ingresoController.clear();
    egresoController.clear();
    _actualizarSaldo();
  }
}


   @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ingresos y Egresos'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Saldo: \$${saldo.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 18.0),
            ),
            TextField(
              controller: ingresoController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: 'Ingreso'),
            ),
            TextField(
              controller: egresoController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: 'Egreso'),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () => _registrarTransaccion(context),
              child: Text('Registrar'),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _database.close();
    super.dispose();
  }
}