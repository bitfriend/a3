import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter/common/controllers/client_controller.dart';
import 'package:acter/common/models/profile_data.dart';
import 'package:flutter/material.dart';
import 'package:acter/common/controllers/spaces_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:core';

class MySpacesSection extends ConsumerWidget {
  const MySpacesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaces = ref.watch(spacesProvider);

    return Row(
      children: [
        Text(
          'My Spaces',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        ...spaces.when(
          data: (spaces) => spaces.map(
            (space) {
              final roomId = space.getRoomId();
              final profile = ref.watch(spaceProfileDataProvider(space));
              return profile.when(
                data: (profile) => Padding(
                  padding: const EdgeInsets.only(
                    bottom: 10,
                  ),
                  child: ListTile(
                    onTap: () => context.go('/$roomId'),
                    title: Text(
                      profile.displayName,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    leading: profile.hasAvatar()
                        ? CircleAvatar(
                            foregroundImage: profile.getAvatarImage(),
                            radius: 24,
                          )
                        : SvgPicture.asset(
                            'assets/icon/acter.svg',
                            height: 24,
                            width: 24,
                          ),
                  ),
                ),
                error: (error, stack) => ListTile(
                  title: Text('Error loading: $roomId'),
                  subtitle: Text('$error'),
                ),
                loading: () => ListTile(
                  title: Text(roomId),
                  subtitle: const Text('loading'),
                ),
              );
            },
          ),
          error: (error, stack) => [Text('Loading spaces failed: $error')],
          loading: () => [const Text('Loading')],
        )
      ],
    );
  }
}
