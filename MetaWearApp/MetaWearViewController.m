//
//  MetaWearViewController.m
//  MetaWearAPI
//
//  Created by Laura Kassovic on 6/3/14.
//  Copyright (c) 2014 Laura Kassovic. All rights reserved.
//
//  IMPORTANT: Your use of this Software is limited to those specific rights granted under the terms of a
//  software license agreement between the user who downloaded the software, his/her employer (which must be
//  your employer) and MbientLab Inc, (the "License").  You may not use this Software unless you agree to abide
//  by the terms of the License which can be found at www.mbientlab.com/terms. The License limits your use, and
//  you acknowledge, that the Software may not be modified, copied or distributed and can be used solely and
//  exclusively in conjunction with a MbientLab Inc, product.  Other than for the foregoing purpose, you may not
//  use, reproduce, copy, prepare derivative works of, modify, distribute, perform, display or sell this
//  Software and/or its documentation for any purpose.
//  YOU FURTHER ACKNOWLEDGE AND AGREE THAT THE SOFTWARE AND DOCUMENTATION ARE PROVIDED “AS IS” WITHOUT WARRANTY
//  OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION, ANY WARRANTY OF MERCHANTABILITY,
//  TITLE, NON-INFRINGEMENT AND FITNESS FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL MBIENTLAB OR ITS LICENSORS
//  BE LIABLE OR OBLIGATED UNDER CONTRACT, NEGLIGENCE, STRICT LIABILITY, CONTRIBUTION, BREACH OF WARRANTY, OR
//  OTHER LEGAL EQUITABLE THEORY ANY DIRECT OR INDIRECT DAMAGES OR EXPENSES INCLUDING BUT NOT LIMITED TO ANY
//  INCIDENTAL, SPECIAL, INDIRECT, PUNITIVE OR CONSEQUENTIAL DAMAGES, LOST PROFITS OR LOST DATA, COST OF
//  PROCUREMENT OF SUBSTITUTE GOODS, TECHNOLOGY, SERVICES, OR ANY CLAIMS BY THIRD PARTIES (INCLUDING BUT NOT
//  LIMITED TO ANY DEFENSE THEREOF), OR OTHER SIMILAR COSTS.
//
//  Should you have any questions regarding your right to use this Software, contact MbientLab Inc, at
//  www.mbientlab.com.
//

#import "MetaWearViewController.h"
#import "AppDelegate.h"

@implementation MetaWearViewController

@synthesize tableView, lastindex; 
@synthesize metawearFound, metawearAPI;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.metawearAPI = [[MetaWearAPI alloc] init];
        self.metawearAPI.delegate = self;
        self.metawearFound = [[NSMutableArray alloc] init];
        
        self.title = @"Connect";
        
        self.view.backgroundColor = [UIColor whiteColor];
        
        CGRect navBarFrame = CGRectMake(0, 20, self.view.frame.size.width, 44.0);
        UINavigationBar *navBar = [[UINavigationBar alloc] initWithFrame:navBarFrame];
        navBar.backgroundColor = [UIColor whiteColor];
        navBar.barTintColor = [UIColor whiteColor];
        UINavigationItem *navItem = [UINavigationItem alloc];
        navItem.title = @"Connect";
        [navBar setBackgroundColor:[UIColor whiteColor]];
        
        navItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Refresh" style:UIBarButtonItemStylePlain target:self action:@selector(refreshAction:)];
        
        navItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Disconnect" style:UIBarButtonItemStylePlain target:self action:@selector(disconnectAction:)];
        
        [navBar pushNavigationItem:navItem animated:false];
        [self.view addSubview:navBar];
        
        self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(15, 70, self.view.frame.size.width-30, self.view.frame.size.height-154) style:UITableViewStylePlain];
        self.tableView.layer.borderColor = [UIColor clearColor].CGColor;
        self.tableView.layer.backgroundColor = [UIColor clearColor].CGColor;
        self.tableView.layer.borderWidth = 2.0;
        [self.tableView.layer setCornerRadius:10.0];
        self.tableView.dataSource = self;
        self.tableView.delegate = self;
        [self.view addSubview:self.tableView];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.metawearAPI startScan:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.metawearAPI.delegate = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.metawearFound.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:[NSString stringWithFormat:@"%d_Cell",(int)indexPath.row]];
    
    CBPeripheral *p = [self.metawearFound objectAtIndex:indexPath.row];
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@",p.name];
    cell.backgroundColor = [UIColor clearColor];
    cell.textLabel.textColor = [UIColor blackColor];
    cell.detailTextLabel.textColor = [UIColor grayColor];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@",CFUUIDCreateString(nil, p.UUID)];
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 70.0;
}

-(UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.text = [self tableView:self.tableView titleForHeaderInSection:section];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor grayColor];
    label.font = [UIFont systemFontOfSize:20.0];
    label.backgroundColor = [UIColor clearColor];
    [label sizeToFit];
    label.frame = CGRectMake(label.frame.origin.x + self.tableView.bounds.size.width*1.0/2 - label.frame.size.width/2, 7.0f, label.frame.size.width, label.frame.size.height);
    
    UIView *headerview = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, self.tableView.bounds.size.height)];
    [headerview addSubview:label];
    
    return headerview;
    
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 42.0f;
}

-(NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        NSLog(@"%d",(int)self.metawearFound.count);
        if (self.metawearFound.count >= 1 )return [NSString stringWithFormat:@"%d MetaWear(s) Found",(int)self.metawearFound.count];
        else return [NSString stringWithFormat:@"No MetaWear Found"];
    }
    
    return @"";
}

-(UIView*)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView *footerview = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, self.tableView.bounds.size.width-20, self.tableView.bounds.size.height)];
    footerview.backgroundColor = [UIColor clearColor];
    
    return footerview;
    
}

-(CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 1.0f;
}

#pragma mark - Table view delegate

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.metawearAPI stopScan];
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    
    if ([self.metawearFound count] != 0) {
        CBPeripheral *p = [self.metawearFound objectAtIndex:indexPath.row];
        
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        appDelegate.metawearAPI = self.metawearAPI;
        
        [self.metawearAPI connectToDevice:p];
        
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];

    self.lastindex = indexPath;
    
    NSLog(@"Scanning stopped");
}

#pragma  mark - User Action

- (IBAction)refreshAction:(id)sender
{
    [self.metawearAPI stopScan];
    [self.metawearFound removeAllObjects];
    [self.tableView reloadData];
    [self.metawearAPI startScan:nil];
}

- (IBAction)disconnectAction:(id)sender
{
    [self.metawearAPI disconnectDevice];
    //[self.metawearFound removeAllObjects];
    [self.metawearAPI stopScan];
}

#pragma  mark - MetaWear API Delegates

-(void) devicesFound:(NSMutableArray *)metawear
{
    [self.metawearFound removeAllObjects];
    [self.metawearFound addObjectsFromArray:metawear];
    if ([self.metawearFound count] > 4) {
        [self.metawearAPI stopScan];
    }
    [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
}

-(void) connectionFailed:(NSError *)error ForDevice:(CBPeripheral *)device
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Device Disconnected" message:@"Connection Failed" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    
    [alert show];
}

-(void) disconnectionSuccessForDevice:(CBPeripheral *)device
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Device Disconnected" message:@"Disconnection Success" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    
    [alert show];
}

@end
