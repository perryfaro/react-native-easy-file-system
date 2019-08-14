# react-native-easy-file-system

## Getting started

`$ npm install react-native-easy-file-system --save`

### Mostly automatic installation

`$ react-native link react-native-easy-file-system`

### Manual installation


#### iOS

1. In XCode, in the project navigator, right click `Libraries` ➜ `Add Files to [your project's name]`
2. Go to `node_modules` ➜ `react-native-easy-file-system` and add `EasyFileSystem.xcodeproj`
3. In XCode, in the project navigator, select your project. Add `libEasyFileSystem.a` to your project's `Build Phases` ➜ `Link Binary With Libraries`
4. Run your project (`Cmd+R`)<

#### Android

1. Open up `android/app/src/main/java/[...]/MainApplication.java`
  - Add `import com.reactlibrary.EasyFileSystemPackage;` to the imports at the top of the file
  - Add `new EasyFileSystemPackage()` to the list returned by the `getPackages()` method
2. Append the following lines to `android/settings.gradle`:
  	```
  	include ':react-native-easy-file-system'
  	project(':react-native-easy-file-system').projectDir = new File(rootProject.projectDir, 	'../node_modules/react-native-easy-file-system/android')
  	```
3. Insert the following lines inside the dependencies block in `android/app/build.gradle`:
  	```
      compile project(':react-native-easy-file-system')
  	```


## Usage
```javascript
import EasyFileSystem from 'react-native-easy-file-system';


EasyFileSystem;
```
