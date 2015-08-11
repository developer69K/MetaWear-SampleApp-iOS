/**
 * DeviceDetailViewController.m
 * MetaWearApiTest
 *
 * Created by Stephen Schiffli on 7/30/14.
 * Copyright 2014-2015 MbientLab Inc. All rights reserved.
 *
 * IMPORTANT: Your use of this Software is limited to those specific rights
 * granted under the terms of a software license agreement between the user who
 * downloaded the software, his/her employer (which must be your employer) and
 * MbientLab Inc, (the "License").  You may not use this Software unless you
 * agree to abide by the terms of the License which can be found at
 * www.mbientlab.com/terms.  The License limits your use, and you acknowledge,
 * that the Software may be modified, copied, and distributed when used in
 * conjunction with an MbientLab Inc, product.  Other than for the foregoing
 * purpose, you may not use, reproduce, copy, prepare derivative works of,
 * modify, distribute, perform, display or sell this Software and/or its
 * documentation for any purpose.
 *
 * YOU FURTHER ACKNOWLEDGE AND AGREE THAT THE SOFTWARE AND DOCUMENTATION ARE
 * PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESS OR IMPLIED,
 * INCLUDING WITHOUT LIMITATION, ANY WARRANTY OF MERCHANTABILITY, TITLE,
 * NON-INFRINGEMENT AND FITNESS FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL
 * MBIENTLAB OR ITS LICENSORS BE LIABLE OR OBLIGATED UNDER CONTRACT, NEGLIGENCE,
 * STRICT LIABILITY, CONTRIBUTION, BREACH OF WARRANTY, OR OTHER LEGAL EQUITABLE
 * THEORY ANY DIRECT OR INDIRECT DAMAGES OR EXPENSES INCLUDING BUT NOT LIMITED
 * TO ANY INCIDENTAL, SPECIAL, INDIRECT, PUNITIVE OR CONSEQUENTIAL DAMAGES, LOST
 * PROFITS OR LOST DATA, COST OF PROCUREMENT OF SUBSTITUTE GOODS, TECHNOLOGY,
 * SERVICES, OR ANY CLAIMS BY THIRD PARTIES (INCLUDING BUT NOT LIMITED TO ANY
 * DEFENSE THEREOF), OR OTHER SIMILAR COSTS.
 *
 * Should you have any questions regarding your right to use this Software,
 * contact MbientLab via email: hello@mbientlab.com
 */

#import "DeviceDetailViewController.h"
#import "MBProgressHUD.h"
#import "APLGraphView.h"

@interface DeviceDetailViewController () <MFMailComposeViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UISwitch *connectionSwitch;
@property (weak, nonatomic) IBOutlet UILabel *tempratureLabel;

@property (weak, nonatomic) IBOutlet UISegmentedControl *accelerometerScale;
@property (weak, nonatomic) IBOutlet UISegmentedControl *sampleFrequency;
@property (weak, nonatomic) IBOutlet UISwitch *highPassFilterSwitch;
@property (weak, nonatomic) IBOutlet UISegmentedControl *hpfCutoffFreq;
@property (weak, nonatomic) IBOutlet UISwitch *lowNoiseSwitch;
@property (weak, nonatomic) IBOutlet UISegmentedControl *activePowerScheme;
@property (weak, nonatomic) IBOutlet UISwitch *autoSleepSwitch;
@property (weak, nonatomic) IBOutlet UISegmentedControl *sleepSampleFrequency;
@property (weak, nonatomic) IBOutlet UISegmentedControl *sleepPowerScheme;
@property (weak, nonatomic) IBOutlet UISegmentedControl *tapDetectionAxis;
@property (weak, nonatomic) IBOutlet UISegmentedControl *tapDetectionType;

@property (weak, nonatomic) IBOutlet APLGraphView *accelerometerGraph;
@property (weak, nonatomic) IBOutlet UILabel *tapLabel;
@property (nonatomic) int tapCount;
@property (weak, nonatomic) IBOutlet UILabel *shakeLabel;
@property (nonatomic) int shakeCount;
@property (weak, nonatomic) IBOutlet UILabel *orientationLabel;

@property (weak, nonatomic) IBOutlet UILabel *mechanicalSwitchLabel;
@property (weak, nonatomic) IBOutlet UILabel *batteryLevelLabel;
@property (weak, nonatomic) IBOutlet UILabel *rssiLevelLabel;
@property (weak, nonatomic) IBOutlet UITextField *hapticPulseWidth;
@property (weak, nonatomic) IBOutlet UITextField *hapticDutyCycle;
@property (weak, nonatomic) IBOutlet UISegmentedControl *gpioPinSelector;
@property (weak, nonatomic) IBOutlet UILabel *gpioPinDigitalValue;
@property (weak, nonatomic) IBOutlet UILabel *gpioPinAnalogValue;

@property (weak, nonatomic) IBOutlet UIButton *startSwitch;
@property (weak, nonatomic) IBOutlet UIButton *stopSwitch;
@property (weak, nonatomic) IBOutlet UIButton *startAccelerometer;
@property (weak, nonatomic) IBOutlet UIButton *stopAccelerometer;
@property (weak, nonatomic) IBOutlet UIButton *startLog;
@property (weak, nonatomic) IBOutlet UIButton *stopLog;
@property (weak, nonatomic) IBOutlet UIButton *startTap;
@property (weak, nonatomic) IBOutlet UIButton *stopTap;
@property (weak, nonatomic) IBOutlet UIButton *startShake;
@property (weak, nonatomic) IBOutlet UIButton *stopShake;
@property (weak, nonatomic) IBOutlet UIButton *startOrientation;
@property (weak, nonatomic) IBOutlet UIButton *stopOrientation;

@property (weak, nonatomic) IBOutlet UILabel *mfgNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *serialNumLabel;
@property (weak, nonatomic) IBOutlet UILabel *hwRevLabel;
@property (weak, nonatomic) IBOutlet UILabel *fwRevLabel;

@property (weak, nonatomic) IBOutlet UILabel *firmwareUpdateLabel;

@property (strong, nonatomic) UIView *grayScreen;
@property (strong, nonatomic) NSArray *accelerometerDataArray;
@property (nonatomic) BOOL accelerometerRunning;
@property (nonatomic) BOOL switchRunning;
@end

@implementation DeviceDetailViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.grayScreen = [[UIView alloc] initWithFrame:CGRectMake(0, 120, self.view.frame.size.width, self.view.frame.size.height - 120)];
    self.grayScreen.backgroundColor = [UIColor grayColor];
    self.grayScreen.alpha = 0.4;
    [self.view addSubview:self.grayScreen];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.device addObserver:self forKeyPath:@"state" options:NSKeyValueObservingOptionNew context:nil];
    [self connectDevice:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.device removeObserver:self forKeyPath:@"state"];

    if (self.accelerometerRunning) {
        [self stopAccelerationPressed:nil];
    }
    if (self.switchRunning) {
        [self StopSwitchNotifyPressed:nil];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (self.device.state == CBPeripheralStateDisconnected) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self setConnected:NO];
            [self.scrollView scrollRectToVisible:CGRectMake(0, 0, 10, 10) animated:YES];
        }];
    }
}

- (void)setConnected:(BOOL)on
{
    [self.connectionSwitch setOn:on animated:YES];
    [self.grayScreen setHidden:on];
}

- (void)connectDevice:(BOOL)on
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    if (on) {
        hud.labelText = @"Connecting...";
        [self.device connectWithHandler:^(NSError *error) {
            [self setConnected:(error == nil)];
            
            if ([error.domain isEqualToString:kMBLErrorDomain] && error.code == kMBLErrorOutdatedFirmware) {
                [hud hide:YES];
                [self updateFirmware:nil];
                return;
            }
            
            hud.mode = MBProgressHUDModeText;
            if (error) {
                hud.labelText = error.localizedDescription;
                [hud hide:YES afterDelay:2];
            } else {
                // Device specific setup
                if ([self.device.accelerometer isKindOfClass:[MBLAccelerometerMMA8452Q class]]) {
                    self.accelerometerMMA8452Q = (MBLAccelerometerMMA8452Q *)self.device.accelerometer;
                    self.accelerometerBMI160 = nil;
                } else if ([self.device.accelerometer isKindOfClass:[MBLAccelerometerBMI160 class]]) {
                    self.accelerometerBMI160 = (MBLAccelerometerBMI160 *)self.device.accelerometer;
                    self.accelerometerMMA8452Q = nil;
                }
                if (self.accelerometerBMI160) {
                    [self.accelerometerScale setEnabled:NO];
                    [self.sampleFrequency setEnabled:NO];
                    [self.highPassFilterSwitch setEnabled:NO];
                    [self.hpfCutoffFreq setEnabled:NO];
                    [self.lowNoiseSwitch setEnabled:NO];
                    [self.activePowerScheme setEnabled:NO];
                    [self.autoSleepSwitch setEnabled:NO];
                    [self.sleepSampleFrequency setEnabled:NO];
                    [self.sleepPowerScheme setEnabled:NO];
                    [self.tapDetectionAxis setEnabled:NO];
                    [self.tapDetectionType setEnabled:NO];
                    
                    [self.startOrientation setEnabled:NO];
                    [self.startShake setEnabled:NO];
                    [self.startTap setEnabled:NO];
                }
                
                hud.labelText = @"Connected!";
                [hud hide:YES afterDelay:0.5];
            }
        }];
    } else {
        hud.labelText = @"Disconnecting...";
        [self.device disconnectWithHandler:^(NSError *error) {
            [self setConnected:NO];
            hud.mode = MBProgressHUDModeText;
            if (error) {
                hud.labelText = error.localizedDescription;
                [hud hide:YES afterDelay:2];
            } else {
                hud.labelText = @"Disconnected!";
                [hud hide:YES afterDelay:0.5];
            }
        }];
    }
}

- (IBAction)connectionSwitchPressed:(id)sender
{
    [self connectDevice:self.connectionSwitch.on];
}

- (IBAction)readTempraturePressed:(id)sender
{
    // The internal temperature will always be available
    MBLData *temperature = self.device.temperature.internal;
    if (self.device.temperature.onboardThermistor) {
        // Use the more accurate thermistor if available
        temperature = self.device.temperature.onboardThermistor;
    }
    [temperature readWithHandler:^(MBLNumericData *obj, NSError *error) {
        self.tempratureLabel.text = [obj.value.stringValue stringByAppendingString:@"°C"];
    }];
}

- (IBAction)turnOnGreenLEDPressed:(id)sender
{
    [self.device.led setLEDColor:[UIColor greenColor] withIntensity:1.0];
}
- (IBAction)flashGreenLEDPressed:(id)sender
{
    [self.device.led flashLEDColor:[UIColor greenColor] withIntensity:1.0];
}

- (IBAction)turnOnRedLEDPressed:(id)sender
{
    [self.device.led setLEDColor:[UIColor redColor] withIntensity:1.0];
}
- (IBAction)flashRedLEDPressed:(id)sender
{
    [self.device.led flashLEDColor:[UIColor redColor] withIntensity:1.0];
}

- (IBAction)turnOnBlueLEDPressed:(id)sender
{
    [self.device.led setLEDColor:[UIColor blueColor] withIntensity:1.0];
}
- (IBAction)flashBlueLEDPressed:(id)sender
{
    [self.device.led flashLEDColor:[UIColor blueColor] withIntensity:1.0];
}

- (IBAction)turnOffLEDPressed:(id)sender
{
    [self.device.led setLEDOn:NO withOptions:1];
}

- (IBAction)readSwitchPressed:(id)sender
{
    [self.device.mechanicalSwitch.switchValue readWithHandler:^(MBLNumericData *obj, NSError *error) {
        self.mechanicalSwitchLabel.text = obj.value.boolValue ? @"Down" : @"Up";
    }];
}

- (IBAction)startSwitchNotifyPressed:(id)sender
{
    [self.startSwitch setEnabled:NO];
    [self.stopSwitch setEnabled:YES];
    
    self.switchRunning = YES;
    [self.device.mechanicalSwitch.switchUpdateEvent startNotificationsWithHandler:^(MBLNumericData *isPressed, NSError *error) {
        self.mechanicalSwitchLabel.text = isPressed.value.boolValue ? @"Down" : @"Up";
    }];
}

- (IBAction)StopSwitchNotifyPressed:(id)sender
{
    [self.startSwitch setEnabled:YES];
    [self.stopSwitch setEnabled:NO];
    
    self.switchRunning = NO;
    [self.device.mechanicalSwitch.switchUpdateEvent stopNotifications];
}

- (IBAction)readBatteryPressed:(id)sender
{
    [self.device readBatteryLifeWithHandler:^(NSNumber *number, NSError *error) {
        self.batteryLevelLabel.text = [number stringValue];
    }];
}

- (IBAction)readRSSIPressed:(id)sender
{
    [self.device readRSSIWithHandler:^(NSNumber *number, NSError *error) {
        self.rssiLevelLabel.text = [number stringValue];
    }];
}

- (IBAction)readDeviceInfoPressed:(id)sender
{
    self.mfgNameLabel.text = self.device.deviceInfo.manufacturerName;
    self.serialNumLabel.text = self.device.deviceInfo.serialNumber;
    self.hwRevLabel.text = self.device.deviceInfo.hardwareRevision;
    self.fwRevLabel.text = self.device.deviceInfo.firmwareRevision;
}

- (IBAction)resetDevicePressed:(id)sender
{
    // Resetting causes a disconnection
    [self setConnected:NO];
    [self.device resetDevice];
}

- (IBAction)checkForFirmwareUpdatesPressed:(id)sender
{
    [self.device checkForFirmwareUpdateWithHandler:^(BOOL isTrue, NSError *error) {
        self.firmwareUpdateLabel.text = isTrue ? @"Available!" : @"Up To Date";
    }];
}

- (IBAction)updateFirmware:(id)sender
{
    // Pause the screen while update is going on
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeDeterminateHorizontalBar;
    hud.labelText = @"Updating...";
    
    [self.device updateFirmwareWithHandler:^(NSError *error) {
        hud.mode = MBProgressHUDModeText;
        if (error) {
            NSLog(@"Firmware update error: %@", error.localizedDescription);
            [[[UIAlertView alloc] initWithTitle:@"Update Error"
                                        message:[@"Please re-connect and try again, if you can't connect, try MetaBoot Mode to recover.\nError: " stringByAppendingString:error.localizedDescription]
                                       delegate:nil
                              cancelButtonTitle:@"Okay"
                              otherButtonTitles:nil] show];
            [hud hide:YES];
        } else {
            hud.labelText = @"Success!";
            [hud hide:YES afterDelay:2.0];
        }
    } progressHandler:^(float number, NSError *error) {
        hud.progress = number;
        if (number == 1.0) {
            hud.mode = MBProgressHUDModeIndeterminate;
            hud.labelText = @"Resetting...";
        }
    }];
}

- (IBAction)startHapticDriverPressed:(id)sender
{
    uint8_t dcycle = [self.hapticDutyCycle.text intValue];
    uint16_t pwidth = [self.hapticPulseWidth.text intValue];
    [self.device.hapticBuzzer startHapticWithDutyCycle:dcycle pulseWidth:pwidth completion:nil];
}

- (IBAction)startiBeaconPressed:(id)sender
{
    [self.device.iBeacon setBeaconOn:YES];
}

- (IBAction)stopiBeaconPressed:(id)sender
{
    [self.device.iBeacon setBeaconOn:NO];
}

- (IBAction)setPullUpPressed:(id)sender
{
    MBLGPIOPin *pin = self.device.gpio.pins[self.gpioPinSelector.selectedSegmentIndex];
    pin.configuration = MBLPinConfigurationPullup;
}
- (IBAction)setPullDownPressed:(id)sender
{
    MBLGPIOPin *pin = self.device.gpio.pins[self.gpioPinSelector.selectedSegmentIndex];
    pin.configuration = MBLPinConfigurationPulldown;
}
- (IBAction)setNoPullPressed:(id)sender
{
    MBLGPIOPin *pin = self.device.gpio.pins[self.gpioPinSelector.selectedSegmentIndex];
    pin.configuration = MBLPinConfigurationNopull;
}
- (IBAction)setPinPressed:(id)sender
{
    MBLGPIOPin *pin = self.device.gpio.pins[self.gpioPinSelector.selectedSegmentIndex];
    [pin setToDigitalValue:YES];
}
- (IBAction)clearPinPressed:(id)sender
{
    MBLGPIOPin *pin = self.device.gpio.pins[self.gpioPinSelector.selectedSegmentIndex];
    [pin setToDigitalValue:NO];
}
- (IBAction)readDigitalPressed:(id)sender
{
    MBLGPIOPin *pin = self.device.gpio.pins[self.gpioPinSelector.selectedSegmentIndex];
    [pin.digitalValue readWithHandler:^(MBLNumericData *obj, NSError *error) {
        self.gpioPinDigitalValue.text = obj.value.boolValue ? @"1" : @"0";
    }];
}
- (IBAction)readAnalogPressed:(id)sender
{
    MBLGPIOPin *pin = self.device.gpio.pins[self.gpioPinSelector.selectedSegmentIndex];
    [pin.analogAbsolute readWithHandler:^(MBLNumericData *obj, NSError *error) {
        self.gpioPinAnalogValue.text = [NSString stringWithFormat:@"%.3fV", obj.value.doubleValue];
    }];
}

- (void)updateAccelerometerSettings
{
    if (self.accelerometerMMA8452Q) {
        if (self.accelerometerScale.selectedSegmentIndex == 0) {
            self.accelerometerGraph.fullScale = 2;
        } else if (self.accelerometerScale.selectedSegmentIndex == 1) {
            self.accelerometerGraph.fullScale = 4;
        } else {
            self.accelerometerGraph.fullScale = 8;
        }

        self.accelerometerMMA8452Q.fullScaleRange = (int)self.accelerometerScale.selectedSegmentIndex;
        self.accelerometerMMA8452Q.sampleFrequency = [[self.sampleFrequency titleForSegmentAtIndex:self.sampleFrequency.selectedSegmentIndex] floatValue];
        self.accelerometerMMA8452Q.highPassFilter = self.highPassFilterSwitch.on;
        self.accelerometerMMA8452Q.highPassCutoffFreq = self.hpfCutoffFreq.selectedSegmentIndex;
        self.accelerometerMMA8452Q.lowNoise = self.lowNoiseSwitch.on;
        self.accelerometerMMA8452Q.activePowerScheme = (int)self.activePowerScheme.selectedSegmentIndex;
        self.accelerometerMMA8452Q.autoSleep = self.autoSleepSwitch.on;
        self.accelerometerMMA8452Q.sleepSampleFrequency = (int)self.sleepSampleFrequency.selectedSegmentIndex;
        self.accelerometerMMA8452Q.sleepPowerScheme = (int)self.sleepPowerScheme.selectedSegmentIndex;
        self.accelerometerMMA8452Q.tapDetectionAxis = (int)self.tapDetectionAxis.selectedSegmentIndex;
        self.accelerometerMMA8452Q.tapType = (int)self.tapDetectionType.selectedSegmentIndex;
    } else if (self.accelerometerBMI160) {
        // TODO: It is fixed at +-16G's for now
        self.accelerometerGraph.fullScale = 16;
        // TODO: Fixed sample frequency of 100Hz
        self.accelerometerBMI160.sampleFrequency = 100;
    }
}

- (IBAction)startAccelerationPressed:(id)sender
{
    [self updateAccelerometerSettings];
    
    [self.startAccelerometer setEnabled:NO];
    [self.stopAccelerometer setEnabled:YES];
    [self.startLog setEnabled:NO];
    [self.stopLog setEnabled:NO];
    self.accelerometerRunning = YES;
    // These variables are used for data recording
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:1000];
    self.accelerometerDataArray = array;
    
    [self.device.accelerometer.dataReadyEvent startNotificationsWithHandler:^(MBLAccelerometerData *acceleration, NSError *error) {
        [self.accelerometerGraph addX:acceleration.x y:acceleration.y z:acceleration.z];
        // Add data to data array for saving
        [array addObject:acceleration];
    }];
}

- (IBAction)stopAccelerationPressed:(id)sender
{
    [self.device.accelerometer.dataReadyEvent stopNotifications];
    self.accelerometerRunning = NO;

    [self.startAccelerometer setEnabled:YES];
    [self.stopAccelerometer setEnabled:NO];
    [self.startLog setEnabled:YES];
}

- (IBAction)startAccelerometerLog:(id)sender
{
    [self updateAccelerometerSettings];
    
    [self.startLog setEnabled:NO];
    [self.stopLog setEnabled:YES];
    [self.startAccelerometer setEnabled:NO];
    [self.stopAccelerometer setEnabled:NO];
    
    [self.device.accelerometer.dataReadyEvent startLogging];
}

- (IBAction)stopAccelerometerLog:(id)sender
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeDeterminateHorizontalBar;
    hud.labelText = @"Downloading...";
    
    [self.device.accelerometer.dataReadyEvent downloadLogAndStopLogging:YES handler:^(NSArray *array, NSError *error) {
        [hud hide:YES];
        if (!error) {
            self.accelerometerDataArray = array;
            for (MBLAccelerometerData *acceleration in array) {
                [self.accelerometerGraph addX:acceleration.x y:acceleration.y z:acceleration.z];
            }
        }
    } progressHandler:^(float number, NSError *error) {
        hud.progress = number;
    }];
    [self.stopLog setEnabled:NO];
    [self.startLog setEnabled:YES];
    [self.startAccelerometer setEnabled:YES];
}


- (IBAction)sendDataPressed:(id)sender
{
    NSMutableData *accelerometerData = [NSMutableData data];
    for (MBLAccelerometerData *dataElement in self.accelerometerDataArray) {
        @autoreleasepool {
            [accelerometerData appendData:[[NSString stringWithFormat:@"%f,%f,%f,%f\n",
                                            dataElement.timestamp.timeIntervalSince1970,
                                            dataElement.x,
                                            dataElement.y,
                                            dataElement.z] dataUsingEncoding:NSUTF8StringEncoding]];
        }
    }
    [self sendMail:accelerometerData];
}

- (void)sendMail:(NSData *)attachment
{
    if (![MFMailComposeViewController canSendMail]) {
        [[[UIAlertView alloc] initWithTitle:@"Mail Error" message:@"This device does not have an email account setup" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        return;
    }

    // Get current Time/Date
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeStyle:NSDateFormatterLongStyle];
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    
    // Some filesystems hate colons
    NSString *dateString = [[dateFormatter stringFromDate:[NSDate date]] stringByReplacingOccurrencesOfString:@":" withString:@"_"];
    // I hate spaces in dates
    dateString = [dateString stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    // OS hates forward slashes
    dateString = [dateString stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    
    MFMailComposeViewController *emailController = [[MFMailComposeViewController alloc] init];
    emailController.mailComposeDelegate = self;
    
    // attachment
    NSString *name = [NSString stringWithFormat:@"AccData_%@.txt", dateString, nil];
    [emailController addAttachmentData:attachment mimeType:@"text/plain" fileName:name];
    
    // subject
    NSString *subject = [NSString stringWithFormat:@"Accelerometer Data %@.txt", dateString, nil];
    [emailController setSubject:subject];
    
    NSMutableString *body = [[NSMutableString alloc] initWithFormat:@"The data was recorded on %@.\n", dateString];
    [body appendString:[NSString stringWithFormat:@"Scale = %@\n", [self.accelerometerScale titleForSegmentAtIndex:self.accelerometerScale.selectedSegmentIndex]]];
    [body appendString:[NSString stringWithFormat:@"Freq = %@\n", [self.sampleFrequency titleForSegmentAtIndex:self.sampleFrequency.selectedSegmentIndex]]];
    [body appendString:self.highPassFilterSwitch.on ? @"HPF On\n" : @"HPF Off\n"];
    [body appendString:[NSString stringWithFormat:@"HPF Cutoff = %@\n", [self.hpfCutoffFreq titleForSegmentAtIndex:self.hpfCutoffFreq.selectedSegmentIndex]]];
    [body appendString:self.lowNoiseSwitch.on ? @"LowNoise On\n" : @"LowNoise Off\n"];
    [body appendString:[NSString stringWithFormat:@"Active Power Scheme = %@\n", [self.activePowerScheme titleForSegmentAtIndex:self.activePowerScheme.selectedSegmentIndex]]];
    [body appendString:self.autoSleepSwitch.on ? @"Auto Sleep On\n" : @"Auto Sleep Off\n"];
    [body appendString:[NSString stringWithFormat:@"SleepFreq = %@\n", [self.sleepSampleFrequency titleForSegmentAtIndex:self.sleepSampleFrequency.selectedSegmentIndex]]];
    [body appendString:[NSString stringWithFormat:@"Sleep Power Scheme = %@\n", [self.sleepPowerScheme titleForSegmentAtIndex:self.sleepPowerScheme.selectedSegmentIndex]]];
    [emailController setMessageBody:body isHTML:NO];
    
    [self presentViewController:emailController animated:YES completion:NULL];
}

-(void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)startTapPressed:(id)sender
{
    [self.startTap setEnabled:NO];
    [self.stopTap setEnabled:YES];
    
    [self updateAccelerometerSettings];
    [self.accelerometerMMA8452Q.tapEvent startNotificationsWithHandler:^(id obj, NSError *error) {
        self.tapLabel.text = [NSString stringWithFormat:@"Tap Count: %d", ++self.tapCount];
    }];
}

- (IBAction)stopTapPressed:(id)sender
{
    [self.startTap setEnabled:YES];
    [self.stopTap setEnabled:NO];
    
    [self.accelerometerMMA8452Q.tapEvent stopNotifications];
    self.tapCount = 0;
    self.tapLabel.text = @"Tap Count: 0";
}

- (IBAction)startShakePressed:(id)sender
{
    [self.startShake setEnabled:NO];
    [self.stopShake setEnabled:YES];
    
    [self updateAccelerometerSettings];
    [self.accelerometerMMA8452Q.shakeEvent startNotificationsWithHandler:^(id obj, NSError *error) {
        self.shakeLabel.text = [NSString stringWithFormat:@"Shakes: %d", ++self.shakeCount];
    }];
}

- (IBAction)stopShakePressed:(id)sender
{
    [self.startShake setEnabled:YES];
    [self.stopShake setEnabled:NO];
    
    [self.accelerometerMMA8452Q.shakeEvent stopNotifications];
    self.shakeCount = 0;
    self.shakeLabel.text = @"Shakes: 0";
}

- (IBAction)startOrientationPressed:(id)sender
{
    [self.startOrientation setEnabled:NO];
    [self.stopOrientation setEnabled:YES];
    
    [self updateAccelerometerSettings];
    [self.accelerometerMMA8452Q.orientationEvent startNotificationsWithHandler:^(id obj, NSError *error) {
        MBLOrientationData *data = obj;
        switch (data.orientation) {
            case MBLAccelerometerOrientationPortrait:
                self.orientationLabel.text = @"Portrait";
                break;
            case MBLAccelerometerOrientationPortraitUpsideDown:
                self.orientationLabel.text = @"PortraitUpsideDown";
                break;
            case MBLAccelerometerOrientationLandscapeLeft:
                self.orientationLabel.text = @"LandscapeLeft";
                break;
            case MBLAccelerometerOrientationLandscapeRight:
                self.orientationLabel.text = @"LandscapeRight";
                break;
        }
    }];
}

- (IBAction)stopOrientationPressed:(id)sender
{
    [self.startOrientation setEnabled:YES];
    [self.stopOrientation setEnabled:NO];
    
    [self.accelerometerMMA8452Q.orientationEvent stopNotifications];
    self.orientationLabel.text = @"XXXXXXXXXXXXXX";
}

@end
