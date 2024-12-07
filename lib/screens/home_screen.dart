import 'package:flutter/material.dart';
import '../services/grpc_client.dart';
import '../protos/compte_service.pb.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Compte> comptes = [];

  @override
  void initState() {
    super.initState();
    fetchComptes();
  }

  Future<void> fetchComptes() async {
    final client = GrpcClient().client;
    try {
      final response = await client.allComptes(GetAllComptesRequest());
      setState(() {
        comptes = response.comptes;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors du chargement des comptes.'),
          backgroundColor: Colors.purple,
        ),
      );
    }
  }

  Future<void> showTotalSoldeDialog(BuildContext context) async {
    final client = GrpcClient().client;
    try {
      final response = await client.totalSolde(GetTotalSoldeRequest());
      final stats = response.stats;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Statistiques du solde total',
            style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Nombre: ${stats.count}\nSomme: ${stats.sum}\nMoyenne: ${stats.average}',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer', style: TextStyle(color: Colors.purple)),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de la récupération du solde total.'),
          backgroundColor: Colors.purple,
        ),
      );
    }
  }

  Future<void> showSaveCompteForm(BuildContext context) async {
    final TextEditingController soldeController = TextEditingController();
    TypeCompte? selectedType;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Ajouter un compte',
            style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: soldeController,
                decoration: const InputDecoration(
                  labelText: 'Solde',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              const Text('Type de compte :'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Radio<TypeCompte>(
                        value: TypeCompte.COURANT,
                        groupValue: selectedType,
                        onChanged: (value) {
                          setState(() {
                            selectedType = value;
                          });
                        },
                      ),
                      const Text('Courant'),
                    ],
                  ),
                  Column(
                    children: [
                      Radio<TypeCompte>(
                        value: TypeCompte.EPARGNE,
                        groupValue: selectedType,
                        onChanged: (value) {
                          setState(() {
                            selectedType = value;
                          });
                        },
                      ),
                      const Text('Épargne'),
                    ],
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () async {
                final solde = double.tryParse(soldeController.text);

                if (solde != null && selectedType != null) {
                  final compteRequest = CompteRequest(
                    solde: solde,
                    dateCreation: DateTime.now().toIso8601String(),
                    type: selectedType!,
                  );

                  final client = GrpcClient().client;
                  await client.saveCompte(SaveCompteRequest(compte: compteRequest));
                  fetchComptes();
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Entrées non valides ! Vérifiez le solde et le type.'),
                      backgroundColor: Colors.purple,
                    ),
                  );
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> deleteCompteById(int id) async {
    final client = GrpcClient().client;
    try {
      await client.deleteCompte(DeleteCompteRequest(id: id));
      setState(() {
        comptes.removeWhere((compte) => compte.id == id);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de la suppression du compte.'),
          backgroundColor: Colors.purple,
        ),
      );
    }
  }

  Future<void> searchCompteById(BuildContext context) async {
    final TextEditingController idController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Rechercher un compte', style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: idController,
          decoration: const InputDecoration(
            labelText: 'ID du compte',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () async {
              final id = int.tryParse(idController.text);
              if (id != null) {
                try {
                  final client = GrpcClient().client;
                  final response = await client.compteById(GetCompteByIdRequest(id: id));
                  final compte = response.compte;
                  Navigator.of(context).pop();
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: const Text('Détails du compte', style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)),
                      content: Text(
                        'ID: ${compte.id}\nSolde: ${compte.solde}\nType: ${compte.type}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Fermer', style: TextStyle(color: Colors.purple)),
                        ),
                      ],
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Compte introuvable.'),
                      backgroundColor: Colors.purple,
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('ID invalide.'),
                    backgroundColor: Colors.purple,
                  ),
                );
              }
            },
            child: const Text('Rechercher'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste des comptes', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.purple,
        actions: [
          IconButton(
            icon: const Icon(Icons.calculate),
            onPressed: () => showTotalSoldeDialog(context),
          ),
        ],
      ),
      body: comptes.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Colors.purple))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: comptes.length,
              itemBuilder: (context, index) {
                final compte = comptes[index];
                return Card(
                  elevation: 5,
                  color: Colors.purple.shade50,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ID: ${compte.id}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16, color: Colors.purple),
                        ),
                        Text('Solde: ${compte.solde}',
                            style: const TextStyle(fontSize: 14, color: Colors.black87)),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () => deleteCompteById(compte.id),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () => showSaveCompteForm(context),
            backgroundColor: Colors.purple,
            heroTag: 'add',
            child: const Icon(Icons.add),
          ),
          const SizedBox(width: 16),
          FloatingActionButton(
            onPressed: () => searchCompteById(context),
            backgroundColor: Colors.purple,
            heroTag: 'search',
            child: const Icon(Icons.search),
          ),
        ],
      ),
    );
  }
}
