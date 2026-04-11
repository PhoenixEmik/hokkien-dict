import 'package:flutter/foundation.dart';

void registerBundledFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    yield const LicenseEntryWithLineBreaks(
      <String>['Tauhu-oo font'],
      '''
Tauhu-oo (豆腐烏) font
Source repository: https://github.com/tauhu-tw/tauhu-oo

This app bundles the Tauhu-oo font to render Taiwanese Hanzi and specific
CJK Extension characters that may be missing from the platform default fonts.

Copyright (c) Tauhu-oo contributors.

Licensed under the SIL Open Font License, Version 1.1.
This is a summarized placeholder notice for the bundled font registration.
Replace this text with the full OFL 1.1 license text if full in-app license
verbatim display is required.
''',
    );
  });

  LicenseRegistry.addLicense(() async* {
    yield const LicenseEntryWithLineBreaks(
      <String>['jf open-huninn font'],
      '''
jf open-huninn (jf open 粉圓)
Source repository: https://github.com/justfont/open-huninn-font

This app uses jf open-huninn in the application icon artwork.

Copyright (c) jf open-huninn contributors.

Licensed under the SIL Open Font License, Version 1.1.
This is a summarized placeholder notice for the bundled font registration.
Replace this text with the full OFL 1.1 license text if full in-app license
verbatim display is required.
''',
    );
  });
}
