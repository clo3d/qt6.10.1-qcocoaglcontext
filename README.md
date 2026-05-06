# qt6.10.1-qcocoaglcontext

A public source release of a patch for the OpenGL context bug in the Qt 6.10.1 macOS Cocoa platform plugin.

## Patched Bug

- Upstream issue: [QTBUG-143779 — OpenGL backend with custom surface format crashes QQuickWidget when resizing](https://qt-project.atlassian.net/browse/QTBUG-143779)

This repository fixes a crash that occurs when resizing a `QQuickWidget` while using the OpenGL backend with a custom surface format. The patch is applied to `qtbase/src/plugins/platforms/cocoa/qcocoaglcontext.mm`.

The patched source is published here so that anyone affected by the same issue can use it freely.

## How to Build

The included `patch_build.sh` script builds the patched Cocoa platform plugin (`libqcocoa.dylib`) for Qt 6.10.1.

```bash
./patch_build.sh
```

The script performs the following steps:

- Clones `qtbase` at tag `v6.10.1` from the official Qt repository (with a GitHub mirror fallback) into `~/qt-source-build/qtbase`.
- Overlays the patched `qcocoaglcontext.mm` from this repository onto the cloned source.
- Configures `qtbase` standalone and builds only the `QCocoaIntegrationPlugin` target.
- Prints the path to the resulting `plugins/platforms/libqcocoa.dylib`.

Default build options:

- Install prefix: `/usr/local/Qt-6.10.1-CocoaOnly`
- Architectures: `arm64;x86_64` (Universal Binary)
- Minimum deployment target: macOS 12.0
- Build type: Release

Adjust the environment variables at the top of the script (`QT_VERSION`, `SOURCE_DIR`, `INSTALL_DIR`, `DEPLOY_TARGET`, `ARCHS`) as needed.

## License

This repository is distributed under the **GNU Lesser General Public License v3.0 (LGPL-3.0-only)**, which is one of the licenses available for the upstream Qt source (`LicenseRef-Qt-Commercial OR LGPL-3.0-only OR GPL-2.0-only OR GPL-3.0-only`). See [LICENSE](LICENSE) for the full text.

## LGPL-3.0 Compliance on macOS (Anti-Tivoization)

LGPL-3.0 §4 combined with GPL-3.0 §6 ("Installation Information") requires that an end user be able to **replace this Qt component with a modified version and run the resulting application on the same hardware**. On macOS this involves code signing, which can otherwise lock users out. The following procedure satisfies the requirement for any application that ships `libqcocoa.dylib` (or any other LGPL-3.0 Qt library) built from this repository.

### 1. Replacing the library

The patched plugin is a drop-in replacement for the stock `libqcocoa.dylib`. Locate the existing file inside the application bundle (or the Qt installation) and overwrite it:

```bash
# Inside an app bundle
cp libqcocoa.dylib MyApp.app/Contents/PlugIns/platforms/libqcocoa.dylib

# Or against a Qt installation prefix
cp libqcocoa.dylib /usr/local/Qt-6.10.1-CocoaOnly/plugins/platforms/libqcocoa.dylib
```

### 2. Re-signing the replaced library

Replacing a signed dylib invalidates the original signature. Re-sign it with either ad-hoc signing (no Apple Developer account needed) or your own Developer ID:

```bash
# Ad-hoc signing — works for local use
codesign --force --sign - libqcocoa.dylib

# Or with your own Developer ID
codesign --force --sign "Developer ID Application: Your Name (TEAMID)" libqcocoa.dylib
```

### 3. Re-signing the application bundle

If the dylib lives inside an `.app` bundle, the bundle's signature must be regenerated as well, or macOS will refuse to launch it:

```bash
codesign --force --deep --sign - MyApp.app
# Or with your own identity
codesign --force --deep --sign "Developer ID Application: Your Name (TEAMID)" MyApp.app
```

Remove Gatekeeper quarantine if the bundle was downloaded:

```bash
xattr -dr com.apple.quarantine MyApp.app
```

### 4. Library validation and entitlements (important)

If the application is shipped with **hardened runtime + library validation enabled**, macOS will reject any dylib that is not signed by the original Team ID, even after a correct re-sign. Merely documenting `codesign` is **not** sufficient in that case — the user must also be able to disable library validation.

To remain LGPL-3.0 compliant, distributors of binaries that link against this library MUST do **at least one** of the following:

- **(a)** Ship the application with the `com.apple.security.cs.disable-library-validation` entitlement enabled, **or**
- **(b)** Provide the entitlements plist used at signing time, so that the user can re-sign with library validation disabled.

Minimal entitlements file (`entitlements.plist`) for option (b):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.cs.disable-library-validation</key>
    <true/>
</dict>
</plist>
```

Re-sign with the entitlements applied:

```bash
codesign --force --deep --options runtime \
    --entitlements entitlements.plist \
    --sign - MyApp.app
```

### 5. Notarization

Notarization staples a ticket to the bundle and is invalidated by re-signing. Users may strip the staple (`xcrun stapler remove MyApp.app`) or run the re-signed bundle locally without notarization. Distributors are not required to provide notarization credentials; the LGPL-3.0 obligation ends at "the modified work runs on the same hardware," which ad-hoc signing on the user's machine satisfies.

### Summary checklist for distributors

A binary distribution that links this library is LGPL-3.0 compliant on macOS only if **all** of the following are true:

- [ ] The (modified) source of this library is offered to the user (this repository fulfills that part for the patch itself).
- [ ] The user is able to replace `libqcocoa.dylib` inside the shipped application.
- [ ] Re-signing instructions are provided (or implied by standard `codesign` usage as documented above).
- [ ] Either library validation is disabled in the shipped binary, or the entitlements needed to disable it are provided to the user.
