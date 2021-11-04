const bool isWeb = identical(1, 1.0);
const bool isReleaseMode = bool.fromEnvironment('dart.vm.product');
const bool isProfileMode = bool.fromEnvironment('dart.vm.profile');
const bool isDebugMode = !isReleaseMode && !isProfileMode;
