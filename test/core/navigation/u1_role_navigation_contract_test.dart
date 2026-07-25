import 'package:chegaja_v2/features/cliente/cliente_home_screen.dart';
import 'package:chegaja_v2/features/prestador/prestador_home_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Cliente keeps legacy navigation while U1 rollout is disabled', () {
    expect(
      clienteHomeDestinationsFor(navigationV2: false),
      <ClienteHomeDestination>[
        ClienteHomeDestination.home,
        ClienteHomeDestination.orders,
        ClienteHomeDestination.messages,
        ClienteHomeDestination.profile,
      ],
    );
  });

  test('Cliente exposes the approved five destinations when U1 is enabled', () {
    expect(
      clienteHomeDestinationsFor(navigationV2: true),
      ClienteHomeDestination.values,
    );
  });

  test('Cliente keeps private history behind verified phone identity', () {
    expect(
      clienteIdentityMayLoadPrivateData(
        isAnonymous: true,
        phoneNumber: '+351912345678',
      ),
      isFalse,
    );
    expect(
      clienteIdentityMayLoadPrivateData(
        isAnonymous: false,
        phoneNumber: null,
      ),
      isFalse,
    );
    expect(
      clienteIdentityMayLoadPrivateData(
        isAnonymous: false,
        phoneNumber: '+351912345678',
      ),
      isTrue,
    );
  });

  test('Cliente gates orders and messages but keeps exploration public', () {
    expect(
      clienteDestinationRequiresVerifiedPhone(
        ClienteHomeDestination.orders,
      ),
      isTrue,
    );
    expect(
      clienteDestinationRequiresVerifiedPhone(
        ClienteHomeDestination.messages,
      ),
      isTrue,
    );
    expect(
      clienteDestinationRequiresVerifiedPhone(
        ClienteHomeDestination.home,
      ),
      isFalse,
    );
    expect(
      clienteDestinationRequiresVerifiedPhone(
        ClienteHomeDestination.saved,
      ),
      isFalse,
    );
    expect(
      clienteDestinationRequiresVerifiedPhone(
        ClienteHomeDestination.profile,
      ),
      isFalse,
    );
  });

  test('Prestador keeps legacy navigation while U1 rollout is disabled', () {
    expect(
      prestadorHomeDestinationsFor(navigationV2: false),
      <PrestadorHomeDestination>[
        PrestadorHomeDestination.opportunities,
        PrestadorHomeDestination.jobs,
        PrestadorHomeDestination.messages,
        PrestadorHomeDestination.business,
      ],
    );
  });

  test('Prestador exposes the approved five destinations when U1 is enabled',
      () {
    expect(
      prestadorHomeDestinationsFor(navigationV2: true),
      PrestadorHomeDestination.values,
    );
  });

  test('home entrypoints expose deterministic U1 rollout overrides', () {
    expect(
      const ClienteHomeScreen(
        u1ExperienceOverride: false,
      ).u1ExperienceOverride,
      isFalse,
    );
    expect(
      const ClienteHomeScreen(
        u1ExperienceOverride: true,
      ).u1ExperienceOverride,
      isTrue,
    );
    expect(
      const PrestadorHomeScreen(
        u1ExperienceOverride: false,
      ).u1ExperienceOverride,
      isFalse,
    );
    expect(
      const PrestadorHomeScreen(
        u1ExperienceOverride: true,
      ).u1ExperienceOverride,
      isTrue,
    );
  });
}
