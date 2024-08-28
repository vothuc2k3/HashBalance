import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/constants/constants.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/core/utils.dart';
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
  final descController = TextEditingController();
  String selectedCommunityType = Constants.communityTypes[0];
  String? selectedCommunityTypeDesc = Constants.communityTypesDescMap['Public'];
  bool containsExposureContents = false;

  @override
  void dispose() {
    super.dispose();
    communityNameController.dispose();
    descController.dispose();
  }

  void createCommunity() async {
    final result =
        await ref.watch(communityControllerProvider.notifier).createCommunity(
              context,
              communityNameController.text.trim(),
              selectedCommunityType,
              descController.text.trim(),
              containsExposureContents,
            );
    result.fold((l) => showToast(false, l.message), (r) {
      showToast(true, r);
      Navigator.pop(context);
    });
  }

  void _showCommunityTypeModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Pallete.blackColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
                  leading: Icon(
                    Constants.communityTypeIcons[value],
                    color: Colors.white,
                  ),
                  title: Text(
                    value,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    Constants.communityTypesDescMap[value]!,
                    style: const TextStyle(color: Colors.white70),
                  ),
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
        ).animate().fadeIn(duration: 800.ms);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isLoading = ref.watch(communityControllerProvider);

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Create your new Community',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          backgroundColor: Pallete.blackColor,
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF000000),
                Color(0xFF0D47A1),
                Color(0xFF1976D2),
              ],
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Community name',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                        controller: communityNameController,
                        decoration: const InputDecoration(
                          prefixText: '#=',
                          prefixStyle: TextStyle(color: Colors.grey),
                          hintText: 'Community_name',
                          hintStyle: TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: Pallete.greyColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(20)),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 15, horizontal: 20),
                        ),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Community name cannot be empty';
                          }
                          return null;
                        },
                        maxLength: 21,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Your Community type',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ).animate().fadeIn(duration: 800.ms),
                      InkWell(
                        onTap: _showCommunityTypeModal,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 15, bottom: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 15, horizontal: 20),
                            decoration: BoxDecoration(
                              color: Pallete.greyColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    selectedCommunityType,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (selectedCommunityTypeDesc != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            selectedCommunityTypeDesc!,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      const SizedBox(height: 20),
                      const Text(
                        'Community Description',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                        controller: descController,
                        decoration: const InputDecoration(
                          hintText: 'Describe your community...',
                          hintStyle: TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: Pallete.greyColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(20)),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 15, horizontal: 20),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Exposure contents?',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Switch(
                            value: containsExposureContents,
                            onChanged: (value) {
                              setState(() {
                                containsExposureContents = value;
                              });
                            },
                            activeColor: Pallete.blueColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 800.ms),
              Padding(
                padding: const EdgeInsets.all(10),
                child: ElevatedButton(
                  onPressed: !isLoading ? createCommunity : null,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    backgroundColor: Pallete.blueColor,
                  ),
                  child: isLoading
                      ? const Loading().animate().fadeIn(duration: 800.ms)
                      : const Text(
                          'Create community',
                          style: TextStyle(
                            fontSize: 17,
                            color: Colors.white,
                          ),
                        ).animate().fadeIn(duration: 800.ms),
                ),
              ).animate().fadeIn(duration: 800.ms),
            ],
          ),
        ),
      ),
    );
  }
}
