//
//  MBAppDelegate.h
//  MovieBarcode
//
//  Created by Charlie Nowacek on 1/11/13.
//  Copyright (c) 2013 Charlie Nowacek. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MBAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (strong, nonatomic) IBOutlet NSImageView *imageView;
@property (strong) NSImage *barcodeImage;
@property (strong) NSMutableArray *imageArray;
@property (assign) int pointX;
@property (strong) IBOutlet NSProgressIndicator *progressBar;
@property (strong) IBOutlet NSButton *saveButton;
@property (strong) NSOpenPanel *openPanel;

@end
