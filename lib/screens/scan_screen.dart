import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../core/classifier.dart';
import '../core/leaf_analysis.dart';
import '../main.dart';
import '../state/demo_state.dart';
import 'result_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});
  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _busy = false;

  Future<void> _run(Uint8List bytes, {String? sampleId}) async {
    setState(() => _busy = true);
    await Future.delayed(const Duration(milliseconds: 1200)); // "analysing" beat for the demo
    final analysis = analyzeLeaf(bytes);
    if (!mounted) return;
    final result = context.read<DemoState>().evaluate(analysis, sampleId: sampleId);
    setState(() => _busy = false);
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ResultScreen(result: result, imageBytes: bytes)));
  }

  Future<void> _sample(String id) async {
    final data = await rootBundle.load(sampleAsset(id));
    await _run(data.buffer.asUint8List(), sampleId: id);
  }

  Future<void> _gallery() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1200);
    if (x == null) return;
    await _run(await x.readAsBytes());
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DemoState>();
    return Stack(children: [
      ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Scanning for ${state.selectedField.name} (${state.selectedFieldId}) · ${state.selectedField.crop}, ${state.selectedField.stage}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: kNavy)),
          const SizedBox(height: 8),
          FilledButton.icon(onPressed: _busy ? null : _gallery, icon: const Icon(Icons.photo_library_outlined), label: const Text('Pick a leaf photo')),
          const SizedBox(height: 16),
          const Text('Or use a bundled sample', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              for (final id in kSampleIds)
                InkWell(
                  onTap: _busy ? null : () => _sample(id),
                  child: Column(children: [
                    Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.asset(sampleAsset(id), fit: BoxFit.cover, width: double.infinity))),
                    const SizedBox(height: 4),
                    Text(id.replaceAll('_', ' '), style: const TextStyle(fontSize: 12)),
                  ]),
                ),
            ],
          ),
        ],
      ),
      if (_busy)
        Container(
          color: Colors.black45,
          child: const Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 12),
              Text('Analysing leaf on device...', style: TextStyle(color: Colors.white, fontSize: 16)),
            ]),
          ),
        ),
    ]);
  }
}
