import 'package:flutter/material.dart';

class PracticeScreen extends StatelessWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Widget Practice"), centerTitle: true),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // Text Widget Practice
            const Text(
              "Flutter Widget Practice",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            // Container Widget Practice
            Container(
              height: 120,

              width: double.infinity,

              decoration: BoxDecoration(
                color: Colors.blue,

                borderRadius: BorderRadius.circular(20),
              ),

              child: const Center(
                child: Text(
                  "Container Widget",

                  style: TextStyle(
                    color: Colors.white,

                    fontSize: 22,

                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Row Widget Practice
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,

              children: [
                Icon(Icons.wb_sunny, size: 50, color: Colors.orange),

                Icon(Icons.cloud, size: 50, color: Colors.grey),

                Icon(Icons.water_drop, size: 50, color: Colors.blue),
              ],
            ),

            const SizedBox(height: 20),

            // Card Widget Practice
            Card(
              elevation: 5,

              child: Padding(
                padding: const EdgeInsets.all(20),

                child: Column(
                  children: [
                    const Text(
                      "Weather Outfit AI",

                      style: TextStyle(
                        fontSize: 20,

                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      "Your outfit suggestion will appear here based on weather.",

                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Button Practice
            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Button clicked!")),
                  );
                },

                child: const Text("Test Button"),
              ),
            ),

            const SizedBox(height: 20),

            // ListView Practice
            const Text(
              "Outfit Categories",

              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            ...["Casual", "Formal", "Winter", "Rainy"].map(
              (item) => ListTile(
                leading: const Icon(Icons.checkroom),

                title: Text(item),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
