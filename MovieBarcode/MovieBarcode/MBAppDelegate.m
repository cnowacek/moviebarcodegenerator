//
//  MBAppDelegate.m
//  MovieBarcode
//
//  Created by Charlie Nowacek on 1/11/13.
//  Copyright (c) 2013 Charlie Nowacek. All rights reserved.
//

#import "MBAppDelegate.h"

#import <AVFoundation/AVFoundation.h>
#import <QTKit/QTKit.h>

#define kImages 200.0
#define kBarcodeWidth 1280.0f
#define kBarcodeHeight 480.0f


@implementation MBAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    _openPanel = [NSOpenPanel openPanel];
    // Create our empty barcode
    [self.saveButton setTarget:self];
    [self.saveButton setAction:@selector(saveImage)];
    [self.saveButton setEnabled:NO];
    
    _barcodeImage = [[NSImage alloc] initWithSize:(NSSize){(float)kBarcodeWidth, (float)kBarcodeHeight}];
    _imageArray = [NSMutableArray arrayWithCapacity:10];
    self.barcodeImage.backgroundColor = [NSColor blackColor];
    [self.progressBar setMaxValue:kImages];
	[self performSelectorInBackground:@selector(processMovie) withObject:nil];
}

- (void)processMovie {
    QTMovie *movie = [QTMovie movieWithURL:[self fileURL] error:NULL];
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    
	// We'll specify a custom size of 95 X 120 for the returned image:
	NSSize imageSize = NSMakeSize(ceilf(kBarcodeWidth/(float)kImages), kBarcodeHeight);
    //NSSize imageSize = NSMakeSize(47.3f, 112.0f);
	NSValue *sizeValue = [NSValue valueWithSize:imageSize];
	[attributes setObject:sizeValue forKey:QTMovieFrameImageSize];
    
    QTTime duration = movie.duration;
    for (int i=0; i<kImages; i++) {
        NSError *error;
        NSImage *tempImage = [movie frameImageAtTime:QTMakeTime(duration.timeValue*((float)i/(float)kImages), duration.timeScale) withAttributes:attributes error:&error];
        if (tempImage) {
            [self.imageArray addObject:tempImage];
        }
        if (error) {
            NSLog(@"OOPS!");
        }
        [self performSelectorOnMainThread:@selector(incrementProgressBar) withObject:nil waitUntilDone:YES];
    }
    [self done];
}

- (void)incrementProgressBar {
    [self.progressBar incrementBy:1.0];
}

- (void)saveImage {
    // Cache the reduced image
    NSData *imageData = [self.barcodeImage TIFFRepresentation];
    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
    NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] forKey:NSImageCompressionFactor];
    imageData = [imageRep representationUsingType:NSPNGFileType properties:imageProps];
    [imageData writeToFile:[NSString stringWithFormat:@"/Users/cnowacek/Desktop/image_%d.png", (int)[[NSDate date] timeIntervalSince1970]] atomically:NO];
    return;
}

- (void)done {
    NSLog(@"DONE!");
    float x = 0.0;
    
    for (NSImage *imageFromMovie in self.imageArray) {
        
        [self.barcodeImage lockFocus];
        [imageFromMovie drawAtPoint:(NSPoint){x, 0.0} fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
        [self.barcodeImage unlockFocus];
        x += imageFromMovie.size.width;
    }
    [self.imageView setImage:self.barcodeImage];
    [self.saveButton setEnabled:YES];
}

- (IBAction)openFile:(NSMenuItem *)sender {
    [self.openPanel beginWithCompletionHandler:^(NSInteger result) {
        
    }];
    [self.openPanel URL];
    return;
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
	if (outError != NULL)
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	return nil;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
	if (outError != NULL)
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	return YES;
}

@end
