import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:graphview/GraphView.dart';
import '../providers/vault_provider.dart';
import '../models/note.dart';

class GraphScreen extends StatefulWidget {
  const GraphScreen({super.key});

  @override
  State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  final Graph graph = Graph();
  late BuchheimWalkerConfiguration builder;
  final TransformationController _transformationController = TransformationController();

  @override
  void initState() {
    super.initState();
    builder = BuchheimWalkerConfiguration()
      ..siblingSeparation = 100
      ..levelSeparation = 100
      ..subtreeSeparation = 150
      ..orientation = BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM;

    final vaultProvider = Provider.of<VaultProvider>(context, listen: false);
    _buildGraph(vaultProvider.notes);
  }

  void _buildGraph(List<Note> notes) {
    graph.nodes.clear();
    graph.edges.clear();

    final nodeMap = <String, Node>{};

    // Create nodes
    for (final note in notes) {
      final node = Node.Id(note.id);
      nodeMap[note.title] = node;
      graph.addNode(node);
    }

    // Create edges from wikilinks
    for (final note in notes) {
      for (final linkTitle in note.outgoingLinks) {
        final targetNode = nodeMap[linkTitle];
        if (targetNode != null) {
          final sourceNode = nodeMap[note.title];
          if (sourceNode != null) {
            graph.addEdge(sourceNode, targetNode);
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vaultProvider = Provider.of<VaultProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Graph View'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _buildGraph(vaultProvider.notes);
              });
            },
            tooltip: 'Refresh Graph',
          ),
        ],
      ),
      body: graph.nodeCount() == 0
          ? const Center(
              child: Text('No notes or links to display'),
            )
          : InteractiveViewer(
              transformationController: _transformationController,
              constrained: false,
              boundaryMargin: const EdgeInsets.all(100),
              minScale: 0.1,
              maxScale: 4.0,
              child: GraphView(
                graph: graph,
                algorithm: BuchheimWalkerAlgorithm(builder, TreeEdgeRenderer(builder)),
                paint: Paint()
                  ..color = Theme.of(context).colorScheme.primary
                  ..strokeWidth = 1
                  ..style = PaintingStyle.stroke,
                builder: (Node node) {
                  final noteId = node.key!.value as String;
                  final note = vaultProvider.getNoteById(noteId);

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      note?.title ?? 'Unknown',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _transformationController.value = Matrix4.identity();
        },
        tooltip: 'Reset View',
        child: const Icon(Icons.center_focus_strong),
      ),
    );
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }
}
