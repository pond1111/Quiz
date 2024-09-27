import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyDQ8zD_1O5ZLlo4vCHQi6o9nu-YmYkKnxs",
        authDomain: "income-and-expenses-project.firebaseapp.com",
        projectId: "income-and-expenses-project",
        storageBucket: "income-and-expenses-project.appspot.com",
        messagingSenderId: "378166065775",
        appId: "1:378166065775:web:15df99e8bdedba2ae7eb9a",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(const MyApp());
}

class TransactionModel {
  String id;
  double amount;
  DateTime date;
  String type;
  String note;

  TransactionModel({
    required this.id,
    required this.amount,
    required this.date,
    required this.type,
    required this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'date': date,
      'type': type,
      'note': note,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      amount: map['amount'],
      date: (map['date'] as Timestamp).toDate(),
      type: map['type'],
      note: map['note'],
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Income and Expenses Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  String _selectedType = 'income'; // ค่าเริ่มต้นเป็นรายรับ

  Future<void> _saveTransaction() async {
    final double amount = double.tryParse(_amountController.text) ?? 0;
    final String note = _noteController.text;

    if (amount > 0 && note.isNotEmpty) {
      TransactionModel transaction = TransactionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: amount,
        date: DateTime.now(),
        type: _selectedType,
        note: note,
      );

      await FirebaseFirestore.instance.collection('transactions').add(transaction.toMap());

      _amountController.clear();
      _noteController.clear();
    }
  }

  Future<Map<String, double>> _calculateTotals() async {
    final querySnapshot = await FirebaseFirestore.instance.collection('transactions').get();
    double totalIncome = 0;
    double totalExpense = 0;

    for (var doc in querySnapshot.docs) {
      var transaction = TransactionModel.fromMap(doc.data());
      if (transaction.type == 'income') {
        totalIncome += transaction.amount;
      } else {
        totalExpense += transaction.amount;
      }
    }

    return {'income': totalIncome, 'expense': totalExpense};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Income and Expenses'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(labelText: 'Note'),
            ),
            DropdownButton<String>(
              value: _selectedType,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedType = newValue!;
                });
              },
              items: const [
                DropdownMenuItem(value: 'income', child: Text('Income')),
                DropdownMenuItem(value: 'expense', child: Text('Expense')),
              ],
            ),
            ElevatedButton(
              onPressed: _saveTransaction,
              child: const Text('Save Transaction'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('transactions').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var transactions = snapshot.data!.docs.map((doc) {
                    return TransactionModel.fromMap(doc.data() as Map<String, dynamic>);
                  }).toList();

                  return ListView.builder(
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = transactions[index];
                      return ListTile(
                        title: Text('${transaction.amount} - ${transaction.type}'),
                        subtitle: Text(transaction.note),
                        trailing: Text(transaction.date.toString()),
                      );
                    },
                  );
                },
              ),
            ),
            FutureBuilder<Map<String, double>>(
              future: _calculateTotals(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                final totals = snapshot.data!;
                return Column(
                  children: [
                    Text('Total Income: ${totals['income']}'),
                    Text('Total Expense: ${totals['expense']}'),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
