import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:health_app/allergens.dart' as display;
import 'package:health_app/profile.dart' as profile;
import 'package:health_app/setup.dart';
import 'package:openfoodfacts/openfoodfacts.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:health_app/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer';

class MyHomePage extends StatefulWidget {
  final List<String> allergies;

  const MyHomePage(
    Key key,
    this.allergies,
  ) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final Future<SharedPreferences> local_history =
      SharedPreferences.getInstance();
  var imageUrl = "";
  String name = 'Initial Name';
  String ingredients = 'Initial Ingredients';
  String whichAllergens = 'Initial No Allergens';
  String canEat = 'This is safe for consumption';
  //List<String> allergies = ["Peanut", "Egg", "Sugar"];
  List<List<String>> history = [[]];

  void scanStuff() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    OpenFoodAPIConfiguration.userAgent = UserAgent(name: 'Health App');
    OpenFoodAPIConfiguration.globalLanguages = <OpenFoodFactsLanguage>[
      OpenFoodFactsLanguage.ENGLISH
    ];

    OpenFoodAPIConfiguration.globalCountry = OpenFoodFactsCountry.USA;

    return Scaffold(
      extendBody: true,
      appBar: AppBar(),
      body: FutureBuilder<ListView>(
        future: getListView(),
        builder: (BuildContext context, AsyncSnapshot<ListView> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            return snapshot.data!;
          }
        },
      ),
      //body: ListView(),
      bottomNavigationBar: Container(
        color: ThemeClass().secondaryColor,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 35, vertical: 20),
          child: GNav(
              onTabChange: (index) async {
                //Resetting the local history
                //final SharedPreferences localHistory = await local_history;
                //localHistory.clear();
                if (index == 1) {
                  imageUrl =
                      "https://cdn.discordapp.com/attachments/1206499194194497546/1211425314232860712/rcLxML7Ri.png?ex=65ee26be&is=65dbb1be&hm=cb1a8c22c2769872510cbccedf8cff71b94cbba38a03534db5b52a5b52247de5&";

                  var tempString;
                  var res = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SimpleBarcodeScannerPage(),
                      ));
                  if (res is String) {
                    tempString = res;
                  }

                  var product = await OpenFoodAPIClient.getProductV3(
                    ProductQueryConfiguration(tempString,
                        version: ProductQueryVersion.v3),
                  );

                  setState(() {
                    product.product?.imageFrontUrl;
                    if (product.product != null) {
                      imageUrl = "${product.product?.imageFrontUrl}";
                      //var imageWidget = Image.network(imageUrl);
                      name =
                          "Product: ${product.product?.getBestProductName(OpenFoodFactsLanguage.ENGLISH) /*getProductNameBrand(OpenFoodFactsLanguage.ENGLISH, " ")*/}";

                      if (product.product?.ingredientsText != null) {
                        ingredients = "${product.product?.ingredientsText}";

                        List<Ingredient>? ingredientsList =
                            product.product?.ingredients;
                        List<String>? allergensList = [];
                        whichAllergens = "";

                        for (int i = 0; i < widget.allergies.length; i++) {
                          allergensList.add("");
                        }

                        for (int i = 0; i < ingredientsList!.length; i++) {
                          String? currentIngredient = ingredientsList[i].text;

                          for (int j = 0; j < widget.allergies.length; j++) {
                            if (allergensList[j].compareTo("") == 0 ||
                                allergensList[j].contains("No")) {
                              if (currentIngredient!.toUpperCase().contains(
                                  widget.allergies[j].toUpperCase())) {
                                allergensList.insert(
                                    j, "Has Allergen: $currentIngredient\n");

                                allergensList.removeAt(j + 1);
                              } else {
                                allergensList.insert(
                                    j, "No Allergen: ${widget.allergies[j]}\n");

                                allergensList.removeAt(j + 1);
                              }
                            }
                          }
                        }

                        for (int i = 0; i < allergensList.length; i++) {
                          if (!allergensList[i].contains("No")) {
                            whichAllergens += allergensList[i];
                          }
                        }

                        if (whichAllergens.compareTo("") == 0) {
                          canEat = "This is safe for consumption";
                        } else {
                          canEat = "We would not recommend consumption";
                        }
                      } else {
                        name = "Error With Scanning";
                        whichAllergens = "";
                        ingredients = "Please Try Again";
                        canEat = "";
                      }
                    } else {
                      name = "Error With Scanning";
                      whichAllergens = "";
                      ingredients = "Please Try Again";
                      canEat = "";
                    }
                  });

                  final SharedPreferences localHistory = await local_history;
                  history.add([name, canEat, imageUrl]);
                  localHistory.setInt("itemAmt", history.length);
                  for (int i = 0; i < history.length; i++) {
                    localHistory.setStringList((i).toString(), history[i]);
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => display.Allergens(
                        key: UniqueKey(),
                        name: this.name,
                        ingredients: this.ingredients,
                        whichAllergens: this.whichAllergens,
                        canEat: this.canEat,
                        image: this.imageUrl,
                        allergies: this.widget.allergies,
                      ),
                    ),
                  );
                } else if (index == 2) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Setup(),
                    ),
                  );
                }
              },

              //color: Color.fromARGB(255, 195, 131, 27),
              gap: 9,
              activeColor: ThemeClass().wColor,
              backgroundColor: ThemeClass().secondaryColor,
              padding: const EdgeInsets.all(16),
              // tabBorder: Border(
              //     bottom: BorderSide(color: Colors.black, width: 1.5),
              //     top: BorderSide(color: Colors.black, width: 1.5),
              //     left: BorderSide(color: Colors.black, width: 1.5),
              //     right: BorderSide(color: Colors.black, width: 1.5)),
              tabs: [
                GButton(
                  backgroundColor: ThemeClass().primaryColor,
                  icon: Icons.home,
                  iconColor: ThemeClass().wColor,
                  text: 'Home',
                  textStyle: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ThemeClass().wColor,
                      fontFamily: 'Hind'),
                ),
                GButton(
                  backgroundColor: ThemeClass().primaryColor,
                  icon: Icons.camera_alt,
                  iconColor: ThemeClass().wColor,
                  text: 'Scan',
                  textStyle: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ThemeClass().wColor,
                      fontFamily: 'Hind'),
                ),
                GButton(
                  backgroundColor: ThemeClass().primaryColor,
                  icon: Icons.person,
                  iconColor: ThemeClass().wColor,
                  text: 'Profile',
                  textStyle: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ThemeClass().wColor,
                      fontFamily: 'Hind'),
                ),
              ]),
        ),
      ),
    );
  }

  Future<ListView> getListView() async {
    final SharedPreferences localHistory = await local_history;
    int listSize = (localHistory.getInt('itemAmt') ?? 0);

    for (int i = 0; i < listSize; i++) {
      history[i] = localHistory.getStringList((i).toString())!;
    }

    if (listSize == 0) {
      return ListView();
    }

    var listView = ListView.builder(
        itemCount: listSize,
        itemBuilder: (BuildContext context, int index) {
          List<String> current =
              localHistory.getStringList((index).toString()) ??
                  ["Error", "Error", "Error"];

          for (int i = 0; i < current.length; i++) {
            log("Current $i: ${current[i]}");
          }

          if (current.length < 3) {
            return ListTile();
          }

          return ListTile(
            leading: SizedBox(
              width: 100,
              child: CachedNetworkImage(
                fit: BoxFit.fitHeight,
                imageUrl: current[2],
                placeholder: (context, url) =>
                    const CircularProgressIndicator(),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
            title: Text("${current[0]}\n${current[1]}\n"),
            onTap: () {
              debugPrint('${[index]} was tapped');
            },
          );
        });

    return listView;
  }
}
