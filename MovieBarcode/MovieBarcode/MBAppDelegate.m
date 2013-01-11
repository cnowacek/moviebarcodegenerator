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

#define kBarcodeWidth 1280.0f
#define kBarcodeHeight 480.0f


@implementation MBAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Init some properties
    _openPanel = [NSOpenPanel openPanel];
	_savePanel = [NSSavePanel savePanel];
	[self.savePanel setAllowedFileTypes:[NSArray arrayWithObject:@"png"]];

    [self.saveButton setTarget:self];
    [self.saveButton setAction:@selector(saveButtonPressed:)];
	
	[self.openButton setTarget:self];
    [self.openButton setAction:@selector(openButtonPressed:)];
    
	[self reset];
	
}

- (void)reset {
	_barcodeImage = [[NSImage alloc] initWithSize:(NSSize){(float)kBarcodeWidth, (float)kBarcodeHeight}];
    _imageArray = [NSMutableArray arrayWithCapacity:10];
	
	self.numberOfFrames = MAX(1, self.framesTextField.integerValue);
    [self.progressBar setMaxValue:self.numberOfFrames];
	[self.progressBar setDoubleValue:0];
	[self.saveButton setEnabled:NO];
}

- (void)processMovie:(NSURL *)fileURL {
	// Set the number of frames, minimum of 1
	self.numberOfFrames = MAX(1, self.framesTextField.integerValue);
	
	// Unhide the progress bar
	[self.progressBar setHidden:NO];
	self.progressLabel.stringValue = @"Grabbing frames...";
	
	// Create the QTMovie object
    QTMovie *movie = [QTMovie movieWithURL:fileURL error:NULL];
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
		
	// Determine the image size
	NSSize imageSize = NSMakeSize(ceilf(kBarcodeWidth/(float)self.numberOfFrames), kBarcodeHeight);
	NSValue *sizeValue = [NSValue valueWithSize:imageSize];
	[attributes setObject:sizeValue forKey:QTMovieFrameImageSize];
    
	// Get the movie duration
    QTTime duration = movie.duration;
	
	//Starting grabbing frames
    for (int i=0; i<self.numberOfFrames; i++) {
        NSError *error;
        NSImage *tempImage = [movie frameImageAtTime:QTMakeTime(duration.timeValue*((float)i/(float)self.numberOfFrames), duration.timeScale) withAttributes:attributes error:&error];
        if (tempImage) {
			// Add the image to our array
            [self.imageArray addObject:tempImage];
        }
        if (error) {
            NSLog(@"OOPS!");
        }
        [self performSelectorOnMainThread:@selector(incrementProgressBar) withObject:nil waitUntilDone:YES];
    }
	
	// Do post processing
    [self createBarcodeImage];
}

- (void)incrementProgressBar {
    [self.progressBar incrementBy:1.0];
}

- (void)saveButtonPressed:(id)sender {
	[self.savePanel beginWithCompletionHandler:^(NSInteger result) {
		[self saveImage:[self.savePanel URL]];
	}];
}

- (void)openButtonPressed:(id)sender {
	[self.openPanel beginWithCompletionHandler:^(NSInteger result) {
		[self reset];
        [self performSelectorInBackground:@selector(processMovie:) withObject:[self.openPanel URL]];
	}];
}

- (void)saveImage:(NSURL *)saveURL {
    // Cache the reduced image
    NSData *imageData = [self.barcodeImage TIFFRepresentation];
    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
    NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] forKey:NSImageCompressionFactor];
    imageData = [imageRep representationUsingType:NSPNGFileType properties:imageProps];
    [imageData writeToFile:[saveURL path] atomically:NO];
    return;
}

- (void)createBarcodeImage {
    float x = 0.0;
	
	// Set our prgress bar properties
	self.progressLabel.stringValue = @"Pasting frames...";
    [self.progressBar setMaxValue:self.imageArray.count];
	[self.progressBar setDoubleValue:0];
	
	// Iterate over the images we grabbed
    for (NSImage *imageFromMovie in self.imageArray) {
        
		// Lock focus and paste the image
        [self.barcodeImage lockFocus];
        [imageFromMovie drawAtPoint:(NSPoint){x, 0.0} fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
        [self.barcodeImage unlockFocus];
		
		// Move the new x location over
        x += imageFromMovie.size.width;
		
		// Increment the progress bar
		[self incrementProgressBar];
    }
	
	// Image is ready to be displayed
    [self.imageView setImage:self.barcodeImage];
	
	// Cleanup UI elements
    [self.saveButton setEnabled:YES];
	[self.progressBar setHidden:YES];
	self.progressLabel.stringValue = @"";
}

- (IBAction)openFile:(NSMenuItem *)sender {
    [self.openPanel beginWithCompletionHandler:^(NSInteger result) {
		[self reset];
        [self performSelectorInBackground:@selector(processMovie:) withObject:[self.openPanel URL]];
    }];
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
