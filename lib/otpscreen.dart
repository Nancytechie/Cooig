// import 'package:cooig_firebase/appbar.dart';
// import 'package:cooig_firebase/background.dart';
// import 'package:cooig_firebase/lostandfound/lostpage.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';

// class Otpscreen extends StatefulWidget {
//   String verificationid;
//   Otpscreen(
//       {super.key,
//       required this.verificationid,
//       required String verificationId});

//   @override
//   State<Otpscreen> createState() => _OtpscreenState();
// }

// class _OtpscreenState extends State<Otpscreen> {
//   TextEditingController otpcontroller = TextEditingController();

//   @override
//   Widget build(BuildContext context) {
//     return RadialGradientBackground(
//         colors: const [Color(0XFF9752C5), Color(0xFF000000)],
//         radius: 0.8,
//         centerAlignment: Alignment.bottomRight,
//         child: Scaffold(
//           appBar: const CustomAppBar(title: 'Cooig', textSize: 35.0),
//           backgroundColor: Colors.transparent,
//           body: Column(
//             children: [
//               Padding(
//                 padding: const EdgeInsets.all(30.0),
//                 child: TextField(
//                   controller: otpcontroller,
//                   keyboardType: TextInputType.phone,
//                   decoration: InputDecoration(
//                       hintText: "Enter the OTP",
//                       icon: const Icon(Icons.phone),
//                       border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(25))),
//                 ),
//               ),
//               const SizedBox(
//                 height: 20,
//               ),
//               ElevatedButton(
//                   onPressed: () async {
//                     try {
//                       PhoneAuthCredential credential =
//                           PhoneAuthProvider.credential(
//                               verificationId: widget.verificationid,
//                               smsCode: otpcontroller.text.toString());
//                       FirebaseAuth.instance
//                           .signInWithCredential(credential)
//                           .then((value) {
//                         Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                                 builder: (context) => Lostpage(userId: widget.userId)));
//                       });
//                     } catch (e) {
//                       print("Wrong OTP");
//                     }
//                   },
//                   child: const Text("verify otp"))
//             ],
//           ),
//         ));
//   }
// }
