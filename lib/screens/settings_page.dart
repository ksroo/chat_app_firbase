import 'dart:io';

import 'package:chat_ui/main.dart';
import 'package:chat_ui/models/user_chat.dart';
import 'package:chat_ui/provider/settings_provider.dart';
import 'package:chat_ui/utils/app_constans.dart';
import 'package:chat_ui/utils/color_constans.dart';
import 'package:chat_ui/utils/firestore_constants.dart';
import 'package:chat_ui/widgets/loading_view.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/src/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isWhite ? Colors.white : Colors.black,
      appBar: AppBar(
        backgroundColor: isWhite ? Colors.white : Colors.black,
        iconTheme: const IconThemeData(
          color: ColorConstants.primaryColor,
        ),
        title: const Text(
          AppConstants.settingsTitle,
          style: TextStyle(
            color: ColorConstants.primaryColor,
          ),
        ),
        centerTitle: true,
      ),
      body: SettingsPageState(),
    );
  }
}

class SettingsPageState extends StatefulWidget {
  @override
  _SettingsPageStateState createState() => _SettingsPageStateState();
}

class _SettingsPageStateState extends State<SettingsPageState> {
  TextEditingController? controllerNickname;
  TextEditingController? controllerNicAboutMe;

  String dialCodeDigits = "+00";
  final TextEditingController controller = TextEditingController();

  String id = '';
  String nickName = '';
  String aboutMe = '';
  String photoUrl = '';
  String phoneNumber = '';

  bool isLoading = false;
  File? avatarImageFile;
  late SettingsProvider settingsProvider;

  final FocusNode focusNodeNickname = FocusNode();
  final FocusNode focusNodeAboutMe = FocusNode();

  @override
  void initState() {
    super.initState();
    settingsProvider = context.read<SettingsProvider>();
    readLocal();
  }

  void readLocal() {
    setState(() {
      id = settingsProvider.getPrefs(FirestoreConstants.id) ?? "";
      nickName = settingsProvider.getPrefs(FirestoreConstants.nickname) ?? "";
      aboutMe = settingsProvider.getPrefs(FirestoreConstants.aboutMe) ?? "";
      photoUrl = settingsProvider.getPrefs(FirestoreConstants.photoUrl) ?? "";
      phoneNumber =
          settingsProvider.getPrefs(FirestoreConstants.phoneNumber) ?? "";
    });

    controllerNickname = TextEditingController(text: nickName);
    controllerNicAboutMe = TextEditingController(text: aboutMe);
  }

  Future getImage() async {
    ImagePicker imagePicker = ImagePicker();
    PickedFile? pickedFile = await imagePicker
        .getImage(source: ImageSource.gallery)
        .catchError((err) {
      Fluttertoast.showToast(msg: err.toString());
    });
    File? image;
    if (pickedFile != null) {
      image = File(pickedFile.path);
    }
    if (image != null) {
      setState(() {
        avatarImageFile = image;
        isLoading = true;
      });
      uploadFile();
    }
  }

  Future uploadFile() async {
    String fileName = id;
    UploadTask uploadTask =
        settingsProvider.uploadFile(avatarImageFile!, fileName);
    try {
      TaskSnapshot snapshot = await uploadTask;
      photoUrl = await snapshot.ref.getDownloadURL();

      UserChat updateInfo = UserChat(
        id: id,
        photoUrl: photoUrl,
        nickname: nickName,
        aboutMe: aboutMe,
        phoneNumber: phoneNumber,
      );
      settingsProvider
          .updateDataFirestore(
              FirestoreConstants.pathUserCollection, id, updateInfo.toJson())
          .then((data) async {
        await settingsProvider.setPref(FirestoreConstants.photoUrl, photoUrl);
        setState(() {
          isLoading = false;
        });
      }).catchError((err) {
        setState(() {
          isLoading = false;
        });
        Fluttertoast.showToast(msg: err.toString());
      });
    } on FirebaseException catch (e) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: e.message ?? e.toString());
    }
  }

  void handleUpdateData() {
    focusNodeNickname.unfocus();
    focusNodeAboutMe.unfocus();

    setState(() {
      isLoading = true;

      if (dialCodeDigits != "+00" && controller.text != "") {
        phoneNumber = dialCodeDigits + controller.text.toString();
      }
    });
    UserChat updateInfo = UserChat(
      id: id,
      photoUrl: photoUrl,
      nickname: nickName,
      aboutMe: aboutMe,
      phoneNumber: phoneNumber,
    );
    settingsProvider
        .updateDataFirestore(
            FirestoreConstants.pathUserCollection, id, updateInfo.toJson())
        .then((data) async {
      await settingsProvider.setPref(FirestoreConstants.nickname, nickName);
      await settingsProvider.setPref(FirestoreConstants.aboutMe, aboutMe);
      await settingsProvider.setPref(FirestoreConstants.photoUrl, photoUrl);
      await settingsProvider.setPref(
          FirestoreConstants.phoneNumber, phoneNumber);

      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: "Update success");
    }).catchError((err) {
      setState(() {
        isLoading = false;
      });

      Fluttertoast.showToast(msg: err.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        SingleChildScrollView(
          padding: const EdgeInsets.only(left: 15, right: 15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CupertinoButton(
                onPressed: getImage,
                child: Container(
                  margin: const EdgeInsets.all(20),
                  child: avatarImageFile == null
                      ? photoUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(45),
                              child: Image.network(
                                photoUrl,
                                fit: BoxFit.cover,
                                width: 90,
                                height: 90,
                                errorBuilder: (context, object, stackTrace) {
                                  return const Icon(
                                    Icons.account_circle,
                                    size: 90,
                                    color: ColorConstants.greyColor,
                                  );
                                },
                                loadingBuilder: (BuildContext context,
                                    Widget child,
                                    ImageChunkEvent? loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return SizedBox(
                                    width: 90,
                                    height: 90,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.grey,
                                        value: loadingProgress
                                                        .expectedTotalBytes !=
                                                    null &&
                                                loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                            ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                loadingProgress
                                                    .expectedTotalBytes!
                                            : null,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                          : const Icon(
                              Icons.account_circle,
                              size: 90,
                              color: ColorConstants.greyColor,
                            )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(45),
                          child: Image.file(
                            avatarImageFile!,
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    child: const Text(
                      'Name',
                      style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.bold,
                          color: ColorConstants.primaryColor),
                    ),
                    margin: const EdgeInsets.only(left: 10, bottom: 5, top: 10),
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 30, right: 30),
                    child: Theme(
                      data: Theme.of(context)
                          .copyWith(primaryColor: ColorConstants.primaryColor),
                      child: TextField(
                        style: const TextStyle(color: Colors.grey),
                        decoration: const InputDecoration(
                          enabledBorder: UnderlineInputBorder(
                            borderSide:
                                BorderSide(color: ColorConstants.greyColor2),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide:
                                BorderSide(color: ColorConstants.primaryColor),
                          ),
                          hintText: 'Write your name...',
                          contentPadding: EdgeInsets.all(5),
                          hintStyle: TextStyle(color: ColorConstants.greyColor),
                        ),
                        controller: controllerNickname,
                        onChanged: (value) {
                          nickName = value;
                        },
                        focusNode: focusNodeNickname,
                      ),
                    ),
                  ),
                  Container(
                    child: const Text(
                      'About me',
                      style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.bold,
                          color: ColorConstants.primaryColor),
                    ),
                    margin: const EdgeInsets.only(left: 10, top: 30, bottom: 5),
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 30, right: 30),
                    child: Theme(
                      data: Theme.of(context)
                          .copyWith(primaryColor: ColorConstants.primaryColor),
                      child: TextField(
                        style: const TextStyle(color: Colors.grey),
                        decoration: const InputDecoration(
                          enabledBorder: UnderlineInputBorder(
                            borderSide:
                                BorderSide(color: ColorConstants.greyColor2),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide:
                                BorderSide(color: ColorConstants.primaryColor),
                          ),
                          hintText: 'Write something about yourself...',
                          contentPadding: EdgeInsets.all(5),
                          hintStyle: TextStyle(color: ColorConstants.greyColor),
                        ),
                        controller: controllerNicAboutMe,
                        onChanged: (value) {
                          aboutMe = value;
                        },
                        focusNode: focusNodeAboutMe,
                      ),
                    ),
                  ),
                  Container(
                    child: const Text(
                      'Phone No',
                      style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.bold,
                          color: ColorConstants.primaryColor),
                    ),
                    margin: const EdgeInsets.only(left: 10, top: 30, bottom: 5),
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 30, right: 30),
                    child: Theme(
                      data: Theme.of(context)
                          .copyWith(primaryColor: ColorConstants.primaryColor),
                      child: TextField(
                        style: const TextStyle(color: Colors.grey),
                        enabled: false,
                        decoration: InputDecoration(
                          hintText: phoneNumber,
                          contentPadding: const EdgeInsets.all(5),
                          hintStyle: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 10, top: 30, bottom: 5),
                    child: SizedBox(
                      width: 400,
                      height: 60,
                      child: CountryCodePicker(
                        onChanged: (country) {
                          setState(() {
                            dialCodeDigits = country.dialCode!;
                          });
                        },
                        initialSelection: "IT",
                        showCountryOnly: false,
                        showOnlyCountryWhenClosed: false,
                        favorite: const ["+1", "US", "+20", "EG"],
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 30, right: 30),
                    child: TextField(
                      style: const TextStyle(color: Colors.grey),
                      decoration: InputDecoration(
                          enabledBorder: const UnderlineInputBorder(
                            borderSide:
                                BorderSide(color: ColorConstants.greyColor2),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide:
                                BorderSide(color: ColorConstants.primaryColor),
                          ),
                          hintText: "Phone Number",
                          hintStyle: const TextStyle(color: Colors.grey),
                          prefix: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Text(
                              dialCodeDigits,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          )),
                      maxLength: 12,
                      keyboardType: TextInputType.number,
                      controller: controller,
                    ),
                  ),
                ],
              ),
              Container(
                margin: const EdgeInsets.only(top: 50, bottom: 50),
                child: TextButton(
                  onPressed: handleUpdateData,
                  child: const Text(
                    'Update Now',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                        ColorConstants.primaryColor),
                    padding: MaterialStateProperty.all<EdgeInsets>(
                      const EdgeInsets.fromLTRB(30, 10, 30, 10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
            child: isLoading ? const LoadingView() : const SizedBox.shrink()),
      ],
    );
  }
}
