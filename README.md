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

## Basic Usage

Import library

```
import RNKitExcard from 'rnkit_sensor';
```

### Init

```jsx
RNKitExcard.config({
  DisplayLogo: false
  ....
})
```

#### Init Params

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| OrientationMask | string | 'MaskAll' | 方向设置，设置扫描页面支持的识别方向 |
| ByPresent | BOOL | NO | 扫描页面调用方式设置,是否以present方式调用，默认为NO，YES-以present方式调用，NO-以sdk默认方式调用(push或present) |
| NumberOfSpace | BOOL | YES | 结果设置，银行卡号是否包含空格 |
| DisplayLogo | BOOL | YES | 是否显示logo |
| EnablePhotoRec | BOOL | YES | EnablePhotoRec |
| FrameColor | int |  | 扫描框颜色, 必须与FrameAlpha共同设置 |
| FrameAlpha | float |  | 扫描框透明度, 必须与FrameColor共同设置 |
| ScanTextColor | int |  | 扫描字体颜色 |
| IDCardScanNormalTextColor | int |  | 正常状态扫描字体颜色 (身份证) |
| IDCardScanErrorTextColor | int |  | 错误状态扫描字体颜色 (身份证) |
| BankScanTips | string | | 银行卡扫描提示文字 |
| DRCardScanTips | string | | 驾驶证扫描提示文字 |
| VECardScanTips | string | | 行驶证扫描提示文字 |
| BankScanTips | string | | 银行卡扫描提示文字 |
| IDCardScanFrontNormalTips | string | | 身份证正常状态正面扫描提示文字 |
| IDCardScanFrontErrorTips | string | | 身份证错误状态正面扫描提示文字 |
| IDCardScanBackNormalTips | string | | 身份证正常状态背面扫描提示文字 |
| IDCardScanBackErrorTips | string | | 身份证错误状态背面扫描提示文字 |
| fontName | string | | 扫描提示文字字体名称 |
| ScanTipsFontSize | float | | 扫描提示文字字体大小 |
| IDCardNormalFontName | string | | 正常状态扫描提示文字字体名称 |
| IDCardNormalFontSize | float | | 正常状态扫描提示文字字体大小 |
| IDCardErrorFontName | string | | 错误状态扫描提示文字字体名称 |
| IDCardErrorFontSize | float | | 错误状态扫描提示文字字体大小 |
| quality | float | | 图片清晰度, 范围(0-1) |

##### OrientationMask

- Portrait
- LandscapeLeft
- LandscapeRight
- PortraitUpsideDown
- Landscape
- MaskAll
- AllButUpsideDown


## Contribution

- [@simamn](mailto:liwei0990@gmail.com) The main author.

## Questions

Feel free to [contact me](mailto:liwei0990@gmail.com) or [create an issue](https://github.com/rnkit/rnkit_sensor/issues/new)

> made with ♥
