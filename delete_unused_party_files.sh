#!/bin/bash

# Script to delete unused party files

echo "Deleting unused party screens..."
rm -f lib/features/party/screens/party_screen.dart
rm -f lib/screens/party/party_info_screen.dart
rm -f lib/features/party/screens/party_list_screen.dart
rm -f lib/features/party/screens/party_detail_screen.dart
rm -f lib/features/party/screens/join_party_screen.dart

echo "Deleting old provider system..."
rm -f lib/features/party/providers/party_provider.dart
rm -f lib/features/party/providers/multi_party_provider.dart
rm -f lib/features/party/streams/party_stream_manager.dart
rm -f lib/features/party/state/party_state.dart
rm -f lib/features/party/actions/party_actions.dart

echo "Deleting old repositories..."
rm -f lib/features/party/repositories/party_repository.dart
rm -f lib/features/party/repositories/multi_party_repository.dart

echo "Deleting unused models..."
rm -f lib/features/party/models/party_model.dart
rm -f lib/features/party/models/party_model_new.dart
rm -f lib/features/party/models/party_model_multi.dart
rm -f lib/features/party/models/party_membership.dart

echo "Deleting unused services..."
rm -f lib/features/party/services/party_members_service.dart

echo "Done! All unused party files have been deleted."