// ignore_for_file: prefer_const_constructors, avoid_unnecessary_containers, sized_box_for_whitespace

import 'package:effektio/common/store/Colors.dart';
import 'package:effektio/common/widget/ChatOverview.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key, required this.client}) : super(key: key);
  final Future<Client> client;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leadingWidth: MediaQuery.of(context).size.width / 5,
        toolbarHeight: MediaQuery.of(context).size.height / 15,
        backgroundColor: Colors.black,
        elevation: 1,
        leading: Container(
          margin: const EdgeInsets.only(left: 10),
          child: TextButton(
            onPressed: () {},
            child: Text(
              'Select',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: AppColors.primaryColor,
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            padding: const EdgeInsets.only(
              right: 10,
            ),
            icon: SvgPicture.asset(
              'assets/images/edit.svg',
              width: 20,
              height: 20,
            ),
          ),
        ],
      ),
      body: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              margin: const EdgeInsets.only(
                left: 18,
              ),
              child: Text(
                'Chat',
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            FutureBuilder<Client>(
              future: widget.client,
              builder: (BuildContext context, AsyncSnapshot<Client> snapshot) {
                if (snapshot.hasData) {
                  if (snapshot.requireData.hasFirstSynced()) {
                    return ChatOverview(
                      rooms: snapshot.requireData.conversations().toList(),
                    );
                  } else {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        SizedBox(
                          height: MediaQuery.of(context).size.height / 6,
                        ),
                        Center(
                          child: Container(
                            child: SvgPicture.asset(
                              'assets/images/empty_messages.svg',
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        Text(
                          'Looks Empty here...',
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        Center(
                          child: Container(
                            height: MediaQuery.of(context).size.height / 3,
                            width: MediaQuery.of(context).size.width / 2,
                            child: Text(
                              'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.',
                              style: GoogleFonts.montserrat(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.clip,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                } else {
                  return SizedBox(
                    height: MediaQuery.of(context).size.height / 1.5,
                    width: MediaQuery.of(context).size.width,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryColor,
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
