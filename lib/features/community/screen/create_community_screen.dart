import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/common/constants/constants.dart';
import 'package:hash_balance/core/common/loading_circular.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/community/controller/comunity_controller.dart';
import 'package:hash_balance/theme/pallette.dart';

class CreateCommunityScreen extends ConsumerStatefulWidget {
  const CreateCommunityScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _CreateCommunityScreenState();
}

class _CreateCommunityScreenState extends ConsumerState<CreateCommunityScreen> {
  final communityNameController = TextEditingController();
  String selectedCommunityType = Constants.communityTypes[0];
  String? selectedCommunityTypeDesc = Constants.communityTypesDescMap['Public'];
  bool containsExposureContents = false;

  @override
  void dispose() {
    super.dispose();
    communityNameController.dispose();
  }

  void createCommunity() async {
    ref.read(communityControllerProvider.notifier).createCommunity(
        context,
        communityNameController.text.trim(),
        selectedCommunityType,
        containsExposureContents);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create your new Community',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.topLeft,
              child: Text('Your Community name'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              style: const TextStyle(
                color: Colors.white,
              ),
              controller: communityNameController,
              decoration: const InputDecoration(
                prefixText: '#=',
                hintText: 'Community_name',
                filled: true,
                fillColor: Pallete.blackColor,
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(18),
              ),
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Community name cannot be empty';
                }
                return null;
              },
              maxLength: 21,
            ),
            const Align(
              alignment: Alignment.topLeft,
              child: Text('Your Community type'),
            ),
            InkWell(
              onTap: () {
                _showCommunityTypeModal();
              },
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 15,
                  bottom: 10,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          selectedCommunityType,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            selectedCommunityTypeDesc!,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Exposure contents?',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 60,
                    height: 40,
                    child: FittedBox(
                      fit: BoxFit.fill,
                      child: Switch(
                        value: containsExposureContents,
                        onChanged: (value) {
                          setState(
                            () {
                              containsExposureContents = value;
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
              onTap: () => setState(
                () {
                  containsExposureContents = !containsExposureContents;
                },
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                createCommunity();
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                backgroundColor: Pallete.blueColor,
              ),
              child: const Text(
                'Create community',
                style: TextStyle(
                  fontSize: 17,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCommunityTypeModal() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 3,
              width: 40,
              color: Colors.grey,
              margin: const EdgeInsets.symmetric(vertical: 8),
            ),
            const SizedBox(height: 10),
            const Text(
              'Community type',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            ...Constants.communityTypes.map<Widget>(
              (String value) {
                return ListTile(
                  leading: Icon(Constants.communityTypeIcons[value]),
                  title: Text(value),
                  subtitle: Text(Constants.communityTypesDescMap[value]!),
                  onTap: () {
                    setState(() {
                      selectedCommunityType = value;
                      selectedCommunityTypeDesc =
                          Constants.communityTypesDescMap[value]!;
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }
}
