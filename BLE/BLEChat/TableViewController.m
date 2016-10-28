//
//  TableViewController.m
//  BLE Chat
//
//  Created by Eric Larson on 3/20/15.
//  Copyright (c) 2015 Red Bear Company Limited. All rights reserved.
//

#import "TableViewController.h"
#import "AppDelegate.h"
#import "BLE.h"

@interface TableViewController ()

@property (strong, nonatomic, readonly) BLE* bleShield;

@end

@implementation TableViewController

-(BLE*)bleShield
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    return appDelegate.bleShield;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIRefreshControl * refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(scanForDevices) forControlEvents:UIControlEventValueChanged];
    
    self.refreshControl = refreshControl;
    
    [self scanForDevices];

}

-(void)scanForDevices
{
    // disconnect from any peripherals
    if (self.bleShield.activePeripheral)
        if(self.bleShield.activePeripheral.state == CBPeripheralStateConnected)
        {
            [[self.bleShield CM] cancelPeripheralConnection:[self.bleShield activePeripheral]];
            return;
        }
    
    // set peripheral to nil
    if (self.bleShield.peripherals)
        self.bleShield.peripherals = nil;
    
    //start search for peripherals with a timeout of 3 seconds
    // this is an asunchronous call and will return before search is complete
    [self.bleShield findBLEPeripherals:3];
    
    // after three seconds, try to connect to first peripheral
    [NSTimer scheduledTimerWithTimeInterval:(float)3.0
                                     target:self
                                   selector:@selector(didFinishScanning:)
                                   userInfo:nil
                                    repeats:NO];
}

-(void) didFinishScanning:(NSTimer*) timer{
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [self.bleShield.peripherals count];;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"BLECell" forIndexPath:indexPath];
    
    
    CBPeripheral* aPeripheral = [self.bleShield.peripherals objectAtIndex:indexPath.row];
    
    // Configure the cell...
    cell.textLabel.text = aPeripheral.name;
    cell.detailTextLabel.text = aPeripheral.identifier.UUIDString;
    
    return cell;
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    NSLog(@"Attemp to connect to peripherals %ld", (long)indexPath.row);
    CBPeripheral *aPeripheral = [self.bleShield.peripherals objectAtIndex:indexPath.row];
    
    //CHANGE 6: add code her to connect to the selected peripheral (aPeripheral)
    [self.bleShield connectPeripheral:aPeripheral];
    
    
}

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
