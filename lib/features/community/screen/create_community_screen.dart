import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/constants/constants.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/community/controller/community_controller.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
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
    if (communityNameController.text.isEmpty) {
      showToast(false, 'Community Name Cannot Be Empty!');
      return;
    }
    if (communityNameController.text.contains(' ')) {
      showToast(false, 'Community Name Should Not Contain Whitespaces...');
      return;
    }
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 4,
                width: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: const EdgeInsets.symmetric(vertical: 8),
              ),
              const SizedBox(height: 10),
              const Text(
                'Community Type',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              ...Constants.communityTypes.map<Widget>(
                (String value) {
                  return ListTile(
                    leading: Icon(
                      Constants.communityTypeIcons[value],
                      color: Pallete.blueColor,
                    ),
                    title: Text(
                      value,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      Constants.communityTypesDescMap[value]!,
                      style: const TextStyle(color: Colors.black54),
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
          ).animate().fadeIn(),
        );
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
            'Create Your New Community',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          backgroundColor: ref.watch(preferredThemeProvider).second,
          elevation: 0,
        ),
        body: Container(
          decoration: BoxDecoration(
            color: ref.watch(preferredThemeProvider).first,
          ),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Community Name',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        color: Colors.white.withOpacity(0.1),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: TextFormField(
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                            controller: communityNameController,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              prefixText: '#=',
                              prefixStyle: TextStyle(color: Colors.white54),
                              hintText: 'Enter community name',
                              hintStyle: TextStyle(color: Colors.white38),
                            ),
                            maxLength: 21,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Community Type',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ).animate().fadeIn(),
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: _showCommunityTypeModal,
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          color: Colors.white.withOpacity(0.1),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 15, horizontal: 16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    selectedCommunityType,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
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
                          padding: const EdgeInsets.symmetric(vertical: 8),
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
                      const SizedBox(height: 8),
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        color: Colors.white.withOpacity(0.1),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: TextFormField(
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                            controller: descController,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Describe your community...',
                              hintStyle: TextStyle(color: Colors.white38),
                            ),
                            maxLines: 3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Contains Sensitive Content?',
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
              ).animate().fadeIn(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: !isLoading ? createCommunity : null,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    backgroundColor: Colors.lightBlueAccent,
                  ),
                  child: isLoading
                      ? const Loading().animate().fadeIn()
                      : const Text(
                          'Create Community',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ).animate().fadeIn(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
