import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SelectDevices extends StatelessWidget {
  const SelectDevices({super.key});

  Widget deviceCard(String name, String details) {
    return GestureDetector(
      onTap: () {},
      child: Card(
        color: Colors.black,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              SizedBox(
                height: 45,
                width: double.infinity,
                child: Center(
                  child: Text(
                    'Device Name :- $name',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Center(
                child: Text(
                  details,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select Device',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      backgroundColor: const Color(0xfff0f0f0),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Center(
                child: SizedBox(
                  height: 180,
                  child: Lottie.asset('assets/Lottie/select_device.json'),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Which Device You Have',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              deviceCard('Mini', '4 Switch & 1 Fan'),
              const SizedBox(height: 10),
              deviceCard('Pro', '8 Switch & 2 Fan'),
              const SizedBox(height: 10),
              deviceCard('Pro Max', '16 Switch & 2 Fan'),
            ],
          ),
        ),
      ),
    );
  }
}
