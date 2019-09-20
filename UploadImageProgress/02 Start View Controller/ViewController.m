//
//  ViewController.m
//  UploadImageProgress
//
//  Created by Piyush Kaklotar on 19/09/19.
//  Copyright © 2019 Piyush Kaklotar. All rights reserved.
//

#import "ViewController.h"
#import "ListUserCell.h"
#import <ImagePicker/ImagePicker-Swift.h>

#import "TJDropbox.h"
#import "TJDropboxAuthenticationViewController.h"

#define MAX_IMAGES 10

static NSString *const kClientIdentifier = @"sibc52opm73hqto";


@interface ViewController () <ImagePickerDelegate, TJDropboxAuthenticationViewControllerDelegate> {
    IBOutlet UIBarButtonItem *btnSelect;
    IBOutlet UIBarButtonItem *btnUpload;
    
    IBOutlet UICollectionView *collView;
    
    NSMutableArray *arrSelectedImages;
    ImagePickerController *imgPicker;
    Configuration *config;
    
    int imageCount;
    
}
@property (nonatomic, copy) NSString *accessToken;
- (IBAction)btnSelect_Pressed:(id)sender;
- (IBAction)btnUpload_Pressed:(id)sender;
@end

@implementation ViewController
#pragma mark - General Methods
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    arrSelectedImages = [[NSMutableArray alloc] init];
    btnUpload.enabled = FALSE;
}
#pragma mark - UIBarButton Methods
- (IBAction)btnSelect_Pressed:(id)sender {
    config = [[Configuration alloc] init];
    config.doneButtonTitle = @"Finish";
    config.noImagesTitle = @"Sorry! There are no images here!";
    config.recordLocation = FALSE;
    config.allowVideoSelection = FALSE;
    
    imgPicker = [[ImagePickerController alloc] initWithConfiguration:config];
    imgPicker.imageLimit = MAX_IMAGES;
    imgPicker.delegate = self;
    [self presentViewController:imgPicker animated:YES completion:nil];
}
- (IBAction)btnUpload_Pressed:(id)sender {
    if (self.accessToken.length == 0) {
        //Login Process
        TJDropboxAuthenticationViewController *authenticationController = [[TJDropboxAuthenticationViewController alloc] initWithClientIdentifier:kClientIdentifier delegate:self];
        [self.navigationController pushViewController:authenticationController animated:YES];
    }
    else {
        imageCount = 0;
        [self uploadImage];
    }
}
#pragma mark - UICollectionView DataSource & Delegate Methods
- (NSInteger)collectionView:(UICollectionView *)colView numberOfItemsInSection:(NSInteger)section{
    return [arrSelectedImages count];
}
- (ListUserCell *)collectionView:(UICollectionView *)colView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    ListUserCell *cell = [colView dequeueReusableCellWithReuseIdentifier:@"CELL" forIndexPath:indexPath];
    cell.viewForFirstBaselineLayout.layer.borderColor = [UIColor blackColor].CGColor;
    cell.viewForFirstBaselineLayout.layer.borderWidth = 2.0f;
    
    //Image Path
    cell.imgView.image = (UIImage *)[arrSelectedImages objectAtIndex:indexPath.row];
    cell.prgsView.tag = indexPath.row;
    cell.prgsView.hidden = YES;
    ListUserCell *tempCell = cell;
    cell = nil;
    return tempCell;
}

#pragma mark - ImagePickerView Delegate Methods
- (void)cancelButtonDidPress:(ImagePickerController * _Nonnull)imagePicker {
    if (arrSelectedImages.count == 0) {
        btnUpload.enabled = FALSE;
    }
    else {
        btnUpload.enabled = TRUE;
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (void)doneButtonDidPress:(ImagePickerController * _Nonnull)imagePicker images:(NSArray<UIImage *> * _Nonnull)images {
    [arrSelectedImages removeAllObjects];
    for (int i = 0; i < images.count; i++) {
        [arrSelectedImages addObject:images[i]];
        
        NSData *fileData = UIImageJPEGRepresentation(images[i], 1.0);
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsPath = [paths objectAtIndex:0]; //Get the docs directory
        NSString *filePath = [documentsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%d.jpg",i]]; //Add the file name
        [fileData writeToFile:filePath atomically:YES];
    }
    [collView reloadData];
    if (arrSelectedImages.count == 0) {
        btnUpload.enabled = FALSE;
    }
    else {
        btnUpload.enabled = TRUE;
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (void)wrapperDidPress:(ImagePickerController * _Nonnull)imagePicker images:(NSArray<UIImage *> * _Nonnull)images {
    if (arrSelectedImages.count == 0) {
        btnUpload.enabled = FALSE;
    }
    else {
        btnUpload.enabled = TRUE;
    }
}

#pragma mark - Dropbox Login Delegate Methods
- (void)dropboxAuthenticationViewController:(TJDropboxAuthenticationViewController *)viewController didAuthenticateWithAccessToken:(NSString *const)accessToken
{
    [self.navigationController popViewControllerAnimated:YES];
    self.accessToken = accessToken;
    if (self.accessToken.length > 0) {
        imageCount = 0;
        [self uploadImage];
    }
}

#pragma mark - Other Methods
- (void)uploadImage {
    if (imageCount < arrSelectedImages.count) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:self->imageCount inSection:0];
        ListUserCell *cell = (ListUserCell *)[self->collView cellForItemAtIndexPath:indexPath];
        UIProgressView *progressView = (UIProgressView *)cell.prgsView;
        progressView.hidden = FALSE;
        progressView.progress = 0;
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsPath = [paths objectAtIndex:0]; //Get the docs directory
        NSString *filePath = [documentsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%d.jpg",imageCount]]; //Add the file name
        NSString *remotePath = [NSString stringWithFormat:@"/%d.jpg",imageCount];
        [TJDropbox uploadFileAtPath:filePath toPath:remotePath overwriteExisting:NO muteDesktopNotifications:NO accessToken:self.accessToken progressBlock:^(CGFloat progress) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [progressView setProgress:progress];
            });
        } completion:^(NSDictionary * _Nullable parsedResponse, NSError * _Nullable error) {
            if (error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self uploadImage];
                });
            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self->imageCount ++;
                    [self uploadImage];
                });
            }
        }];
    }
}
#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
}

@end
