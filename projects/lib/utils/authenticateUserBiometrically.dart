import 'package:local_auth/local_auth.dart';

final LocalAuthentication auth = LocalAuthentication();

Future<bool> authenticateUserBiometrically() async {
  try {
    bool canCheckBiometrics = await auth.canCheckBiometrics;
    bool isDeviceSupported = await auth.isDeviceSupported();

    if (!canCheckBiometrics || !isDeviceSupported) return false;

    return await auth.authenticate(
      localizedReason: 'Authenticate to proceed',
      options: const AuthenticationOptions(
        biometricOnly: false, // allow fallback to PIN/password/pattern
        stickyAuth: true,
      ),
    );
  } catch (e) {
    print("Authentication error: $e");
    return false;
  }
}
