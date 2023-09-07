# Functional Fashion Watch
<p> The purpose of this app is to query the heartbeat and other biometric signal data in enabling actuated physical responses on functional wearables which signal a change in a person's state of mind. </p>
---

## Installation and Deployment
<b>Note: this app will not function for any device that does not use Apple hardware</b>

```
cd ~/folder/of/choice
git clone https://github.com/ehng359/functional_fashion_watch
```

1. If you currently do not have any version of XCode, install it from the built-in App Store on Mac.
2. Navigate to [Apple's developer website](https://developer.apple.com/), click to account tab and sign in with your personal iCloud account. This will enable the development for any user and allow for capabilities (i.e. HealthKit, which is used in this project) to be accessed.
3. Once XCode is installed, open the hb_read.xcodeproj file from the cloned repository. If you do not currently have the capability to run any WatchOS-based simulator, there will be a prompt at the top detailing the current watch simulator being used and the status of XCode with regards to the app, indicating the capability to download tools to build and run a WatchOS simulator.
4. With the 'Window' tab at the top of the application, navigate to Devices and Simulators. Connect your iPhone with bluetooth connected Apple-watch to your Macbook with USB-C to lightning cable. This will display a prompt asking you to press "trust" for both the iPhone and Apple Watch (which will allow the Mac to run and build applications directly onto the devices). Allow XCode to fetch debug symbols and tools necessary for building applications (it will say finished/ready at the top when ready).
5. Once the devices trust the Macbook, head into settings on the iPhone -> Privacy & Security -> Developer Mode and enable this option. This will directly prompt a restart from the device. Similarly perform this for the Apple Watch. If this option doesn't work for the Apple Watch:
* Unplug the device.
* Quit XCode.
* Open XCode.
* Replug the device.

6. In the file tree on the left-hand side, click on the root called 'hb_read'. For each of the sections within 'Targets', go to signing and capabilities and add your iCloud account (the same one you signed in with). Once signed in, switch teams to your personal team and change the bundle identifier for each section to [_your_name].hb_read.* or a name which creates a unique bundle identifier.
7. Change the target being deployed to at the top (where it indicates a simulator-type) to your Apple Watch. Run. The first initial run will prompt the user for access to Health read/write data. Once this is granted, the process will be paused. Stop the application and re-run the project. This should present live heart-rate data on your watch.

## Usage
There are three primary screens related to this application: the heartbeat/recording page, the settings page, and the VA-model page.

### Settings
Indicated within the settings button containing `...` in the corner of the initial view. Under this section, adjust the address by tapping into the relevant text-field which will prompt the user to input an address of the form: `[http/https]://your.website.com/endpoint`.

The other options for adjustment include: 
1. VA-Display Type - Grid, Line, Form - indicates which way the user inputs valence (and/or arousal) values.
2. Activity Type - provides context of the current activities relevant to the biometrics being derived.
Note: to make an adjustment in this picker field, select the box and use the Apple Watch Crown to navigate between each option.

### Main
Once the address has been inputed (required to start sending HTTP requests), tap record to begin sending JSON information to the aforementioned endpoint established in the settings menu. This will start an activity session recording key values in the format:
```
{
    "watchUser": "XXXXXXXX-XXXX-XXXX-XXXX-ALPHANUMERIC",
    "date": "YYYY-MM-DD HH:MM:SS +0000",
    "heartBeat": Int(X),
    "respiratoryRate": Int(X),
    "heartBeatVar": Int(X),
    "restingHeartRate": Int(X),
    "valence": Float(X),
    "arousal": Float(X),
    "activity": "activity-type"
}
```
Once the session has concluded, press stop recording to cease sending values to the endpoint. Reinitiate at any point in time.

#### How to Get Heart-rate Variability (HRV) and Respiratory-rate (RR) Consistently
Navigate to the ECG application provided by Apple which allows the user to perform a recording session for measuring their heart rate. This provides the `hb_read` application with ECG data necessary that directly send information to the server for parsing/processing. Follow the following steps:
- Hold the crown for 30 seconds straight until you are prompted with a screen to conclude the session.
- Navigate back to the `hb_read` application and set your valence-arousal values once you have concluded the session.
- Repeat the previous steps. This will allow for the app to generate information about RR and HRV once in 30 seconds (user-initiated).

## VA-Model
This model effectively presents information to enable recording of valence and arousal values by either pressing on the model and dragging the cursor around to record values within the next HTTP request sent to the endpoint or simply pressing along the model (Grid/Line). The most basic of these implementations allows for the user to input values into a form and sending those manually inputted values along.
