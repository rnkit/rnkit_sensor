[![npm][npm-badge]][npm]
[![react-native][rn-badge]][rn]
[![MIT][license-badge]][license]
[![bitHound Score][bithound-badge]][bithound]
[![Downloads](https://img.shields.io/npm/dm/rnkit_sensor.svg)](https://www.npmjs.com/package/rnkit_sensor)

埋点 for [React Native][rn].

[**Support me with a Follow**](https://github.com/simman/followers)

[npm-badge]: https://img.shields.io/npm/v/rnkit_sensor.svg
[npm]: https://www.npmjs.com/package/rnkit_sensor
[rn-badge]: https://img.shields.io/badge/react--native-v0.40-05A5D1.svg
[rn]: https://facebook.github.io/react-native
[license-badge]: https://img.shields.io/dub/l/vibe-d.svg
[license]: https://raw.githubusercontent.com/rnkit/rnkit_sensor/master/LICENSE
[bithound-badge]: https://www.bithound.io/github/rnkit/rnkit_sensor/badges/score.svg
[bithound]: https://www.bithound.io/github/rnkit/rnkit_sensor

## Getting Started

First, `cd` to your RN project directory, and install RNMK through [rnpm](https://github.com/rnpm/rnpm) . If you don't have rnpm, you can install RNMK from npm with the command `npm i -S rnkit_sensor` and link it manually (see below).

### iOS

* #### React Native < 0.29 (Using rnpm)

  `rnpm install rnkit_sensor`

* #### React Native >= 0.29
  `$npm install -S rnkit_sensor`

  `$react-native link rnkit_sensor`

#### Manually
1. Add `node_modules/rnkit_sensor/ios/RNKitExcard.xcodeproj` to your xcode project, usually under the `Libraries` group
1. Add `libRNKitExcard.a` (from `Products` under `RNKitExcard.xcodeproj`) to build target's `Linked Frameworks and Libraries` list
1. Add ocr framework to `$(PROJECT_DIR)/Frameworks.`

### Android

* #### React Native < 0.29 (Using rnpm)

  `rnpm install rnkit_sensor`

* #### React Native >= 0.29
  `$npm install -S rnkit_sensor`

  `$react-native link rnkit_sensor`

#### Manually
1. JDK 7+ is required
1. Add the following snippet to your `android/settings.gradle`:

  ```gradle
include ':rnkit_sensor'
project(':rnkit_sensor').projectDir = new File(rootProject.projectDir, '../node_modules/rnkit_sensor/android/app')
  ```
  
1. Declare the dependency in your `android/app/build.gradle`
  
  ```gradle
  dependencies {
      ...
      compile project(':rnkit_sensor')
  }
  ```
  
1. Import `import io.rnkit.excard.EXOCRPackage;` and register it in your `MainActivity` (or equivalent, RN >= 0.32 MainApplication.java):

  ```java
  @Override
  protected List<ReactPackage> getPackages() {
      return Arrays.asList(
              new MainReactPackage(),
              new EXOCRPackage()
      );
  }
  ```
1. Add Module `ExBankCardSDK` And `ExCardSDK` In Your Main Project.

Finally, you're good to go, feel free to require `rnkit_sensor` in your JS files.

Have fun! :metal:

## Questions

Feel free to [contact me](mailto:liwei0990@gmail.com) or [create an issue](https://github.com/rnkit/rnkit_sensor/issues/new)

> made with ♥
