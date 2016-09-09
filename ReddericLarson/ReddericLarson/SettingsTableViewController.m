//
//  SettingsTableViewController.m
//  ReddericLarson
//
//  Created by Erik Gabrielsen on 9/7/16.
//  Copyright © 2016 MobileSensing. All rights reserved.
//

#import "SettingsTableViewController.h"
#import "SettingsModel.h"

@interface SettingsTableViewController ()

@property (weak, nonatomic) IBOutlet UIPickerView *picker;
@property (weak, nonatomic) IBOutlet UILabel *sliderLabel;
@property (weak, nonatomic) IBOutlet UISlider *slider;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (strong,nonatomic) SettingsModel* settingsModel;
@property (weak, nonatomic) IBOutlet UISwitch* ourSwitch;

@property (assign, nonatomic) NSInteger timerVal;
@property (assign, nonatomic) NSTimer* timer;
@property (assign, nonatomic) NSInteger endTimeValue;
@property (weak, nonatomic) IBOutlet UIStepper *stepper;

@end

@implementation SettingsTableViewController
NSArray *_pickerData;
NSString *pickerValue;

- (IBAction)switchOnOff:(id)sender {
    if ([sender isOn]) {
        self.picker.userInteractionEnabled = YES;
        self.slider.enabled = true;
        self.segmentedControl.enabled = true;
        self.stepper.enabled = true;
        [self createTimer];

    }
    else {
        self.picker.userInteractionEnabled = NO;
        self.slider.enabled = false;
        self.segmentedControl.enabled = false;
        self.stepper.enabled = false;
        [self actionStop];
    }
}

- (void)actionStop {
    
    // stop the timer
    [self.timer invalidate];
    [self.ourSwitch setOn:NO animated:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _pickerData = @[@"5", @"10", @"15", @"20"];

    self.picker.userInteractionEnabled = NO;
    self.slider.enabled = false;
    self.segmentedControl.enabled = false;
    self.stepper.enabled = false;
    self.timerVal = 1;
    self.endTimeValue = 5;
    
    
    
    // Connect dataSource to picker
    // Connect data
    self.picker.dataSource = self;
    self.picker.delegate = self;
    pickerValue = @"";
    
    
    // set initial slider values
    [self.slider setValue:[self.settingsModel.numberOfResults floatValue] animated:YES];
    _sliderLabel.text = [NSString stringWithFormat:@"Number of results: %0.0f", self.slider.value];
    
    // set initial segmented control values
    int selectedIndex = 0;
    if ([self.settingsModel.sortValue  isEqual: @"Ascending"]) {
        selectedIndex = 0;
    } else {
        selectedIndex = 1;
    }
    
    [self.segmentedControl setSelectedSegmentIndex:selectedIndex];
    
    
    // set colors
    UINavigationBar *navBar = [self.navigationController navigationBar];
    
    [self.navigationController.navigationBar setTitleTextAttributes:
     @{NSForegroundColorAttributeName:[UIColor whiteColor]}];
    
    [navBar setBarTintColor:[UIColor lightGrayColor]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(SettingsModel*)settingsModel{
    if(!_settingsModel) {
        _settingsModel = [SettingsModel sharedInstance];
    }
    return _settingsModel;
}

-(void)createTimer {
    
    // create timer on run loop
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timerTicked:) userInfo:nil repeats:YES];
}

- (IBAction)changeValue:(id)sender {
    UIStepper *stepper = (UIStepper *) sender;
    
    stepper.maximumValue = 25;
    stepper.minimumValue = 0;
    self.slider.value = stepper.value;
    _sliderLabel.text = [NSString stringWithFormat:@"Number of results: %0.0f", stepper.value];
    
}


- (void)timerTicked:(NSTimer*)timer {
    
    // decrement timer 1 … this is your UI, tick down and redraw
    self.timerVal += 1;
    
    if (self.timerVal > self.endTimeValue) {
        self.picker.userInteractionEnabled = NO;
        self.slider.enabled = false;
        self.segmentedControl.enabled = false;
        [self actionStop];
    }

}

#pragma mark - Table view data source
//
//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
//#warning Incomplete implementation, return the number of sections
//    return 1;
//}
//
//- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//#warning Incomplete implementation, return the number of rows
//    return 1;
//}
- (IBAction)sliderView:(id)sender {
    if (sender == _slider) {
        self.stepper.value = _slider.value;
        _sliderLabel.text = [NSString stringWithFormat:@"Number of results: %0.0f", _slider.value];
    }
}

- (IBAction)save:(id)sender {
    //save segmented control
    NSString * selectedTitle = [self.segmentedControl titleForSegmentAtIndex:self.segmentedControl.selectedSegmentIndex];
    [self.settingsModel setSortValue:selectedTitle];
    
    //save slider
    [self.settingsModel setNumberOfResults: @(self.slider.value)];
    
    
    [self dismissViewControllerAnimated:true completion:nil];
}

- (IBAction)close:(id)sender {
    [self dismissViewControllerAnimated:true completion:nil];
}

// The number of columns of data
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

// The number of rows of data
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return _pickerData.count;
}

// The data to return for the row and component (column) that's being passed in
- (NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return _pickerData[row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    // This method is triggered whenever the user makes a change to the picker selection.
    // The parameter named row and component represents what was selected
    if ([_pickerData[row]  isEqual: @"5"]) {
        self.endTimeValue = 5;
    } else if ([_pickerData[row]  isEqual: @"10"]) {
        self.endTimeValue = 10;

    } else if ([_pickerData[row]  isEqual: @"15"]) {
        self.endTimeValue = 15;

    } else if ([_pickerData[row]  isEqual: @"20"]) {
        self.endTimeValue = 20;

    } else {
        self.endTimeValue = 5;

    }
}

/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
*/

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
