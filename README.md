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
