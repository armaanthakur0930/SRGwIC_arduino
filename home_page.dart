import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  final Map<String, dynamic> ingredientData;

  const HomePage({Key? key, required this.ingredientData}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> cuisines = [];
  List<String> recipeNames = [];
  List<String> recipes = [];
  List<String> totalTimeInMins = [];
  List<String> urls = [];

  @override
  void initState() {
    super.initState();

    // Call the _getRecipes function when this widget is first created
    _getRecipes();
  }

  Future<void> _getRecipes() async {
    // Receive the ingredient data sent from InitialPage
    String ingredientName = widget.ingredientData['ingredientName'];
    double? ingredientWeight = widget.ingredientData['weight'];

    if (ingredientName.isEmpty || ingredientWeight == null) {
      // Handle the case when data is not received
      _showDataNotReceived();
      return;
    }

    // Now you can use the ingredientName and ingredientWeight for the API request
    String url = 'https://api-srgwic.onrender.com/RecipeGen';
    Map<String, String> headers = {"Content-type": "application/json"};
    String jsonBody = json.encode({"inputIngredients": [ingredientName]});

    try {
      final response = await http.post(Uri.parse(url), headers: headers, body: jsonBody);
      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        setState(() {
          cuisines = List<String>.from(data['Cuisines']);
          recipeNames = List<String>.from(data['RecipeName']);
          // Update to format the recipe details
          List<dynamic> rawRecipes = data['Recipes'];
          recipes = rawRecipes.map((recipe) => _formatRecipe(recipe)).toList();
          totalTimeInMins = List<String>.from(data['TotalTimeInMins']);
          urls = List<String>.from(data['URLs']);
        });
      } else {
        throw Exception('Failed to load recipes');
      }
    } catch (e) {
      print(e);
    }
  }

  // Helper function to format the recipe
  String _formatRecipe(List<dynamic> recipe) {
    String ingredients = recipe[1].replaceAllMapped(
      RegExp(r'(\d+)\s(\w+)\s(\w+)'),
          (match) => '${match[1]} ${match[2]} ${match[3]}',
    );

    String instructions = recipe[2].replaceAll('\n', '\n\n');

    return "Ingredients:\n$ingredients\n\nInstructions:\n$instructions";
  }

  void _showDataNotReceived() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Data Not Received'),
          content: Text('Ingredient data was not received.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        fontFamily: 'Roboto',
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Recipe Generator'),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Display the ingredient name and weight
              Text(
                'Ingredient Name: ${widget.ingredientData['ingredientName']}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Ingredient Weight: ${widget.ingredientData['weight'] != null ? widget.ingredientData['weight'].toString() + ' g' : 'Data not received'}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: recipeNames.length,
                  itemBuilder: (context, index) {
                    return Card(
                      elevation: 4,
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: Image.network(
                          urls[index],
                          width: 100,
                          fit: BoxFit.cover,
                        ),
                        title: Text(
                          recipeNames[index],
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(cuisines[index]),
                        onTap: () {
                          // Display recipe details in a dialog
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text(recipeNames[index]),
                                content: SingleChildScrollView(
                                  child: Text(
                                    recipes[index],
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Text('Close'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
