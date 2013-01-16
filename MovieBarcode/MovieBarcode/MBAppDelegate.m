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
#import <QuartzCore/QuartzCore.h>

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
    
    [self.processButton setTarget:self];
    [self.processButton setAction:@selector(processButtonPressed:)];
    
	[self reset];
	
}

- (void)reset {
    self.numberOfFrames = MAX(1, self.framesTextField.integerValue);
    self.imageWidth = MAX(1, self.imageWidthTextField.integerValue);
    self.imageHeight = MAX(1, self.imageHeightTextField.integerValue);
    
	_barcodeImage = [[NSImage alloc] initWithSize:(NSSize){self.imageWidth, self.imageHeight}];
    _imageArray = [NSMutableArray arrayWithCapacity:10];
 
    [self.progressBar setMaxValue:self.numberOfFrames];
	[self.progressBar setDoubleValue:0];
	[self.saveButton setEnabled:NO];
}

- (void)incrementProgressBar {
    [self.progressBar incrementBy:1.0];
}

- (IBAction)openFile:(NSMenuItem *)sender {
    [self.openPanel beginWithCompletionHandler:^(NSInteger result) {
        [self performSelectorInBackground:@selector(processMovie:) withObject:[self.openPanel URL]];
    }];
    return;
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

#pragma mark - BUTTON ACTIONS
- (void)saveButtonPressed:(id)sender {
	[self.savePanel beginWithCompletionHandler:^(NSInteger result) {
		[self saveImage:[self.savePanel URL]];
	}];
}

- (void)openButtonPressed:(id)sender {
	[self.openPanel beginWithCompletionHandler:^(NSInteger result) {
		[self reset];
        [self.fileNameLabel setStringValue:self.openPanel.URL.lastPathComponent];
	}];
}

- (void)processButtonPressed:(id)sender {
    [self reset];
    [self performSelectorInBackground:@selector(processMovie:) withObject:[self.openPanel URL]];
}

#pragma mark - IMAGE PROCESSING

- (void)processMovie:(NSURL *)fileURL {
    // disable the start button
    [self.processButton setEnabled:NO];
    
	// Set the number of frames and final image dimensions minimum of 1
	self.numberOfFrames = MAX(1, self.framesTextField.integerValue);
	self.imageWidth = MAX(1, self.imageWidthTextField.integerValue);
    self.imageHeight = MAX(1, self.imageHeightTextField.integerValue);
    
	// Unhide the progress bar
	[self.progressBar setHidden:NO];
	self.progressLabel.stringValue = @"Grabbing frames...";
	
	// Create the QTMovie object
    QTMovie *movie = [QTMovie movieWithURL:fileURL error:NULL];
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    
	// Determine the image size
	NSSize imageSize = NSMakeSize(ceilf(self.imageWidth/(float)self.numberOfFrames), self.imageHeight);
	NSValue *sizeValue = [NSValue valueWithSize:imageSize];
	[attributes setObject:sizeValue forKey:QTMovieFrameImageSize];
    
	// Get the movie duration
    QTTime duration = movie.duration;
	
	// Grab the frames
    for (int i=0; i<self.numberOfFrames; i++) {
        NSError *error;
        NSImage *imageFrame = [movie frameImageAtTime:QTMakeTime(duration.timeValue*((float)i/(float)self.numberOfFrames), duration.timeScale) withAttributes:attributes error:&error];
        if (imageFrame) {
            [self.imageArray addObject:imageFrame];
        }
        if (error) {
            NSLog(@"ERROR");
        }
        [self performSelectorOnMainThread:@selector(incrementProgressBar) withObject:nil waitUntilDone:YES];
    }
	
	// Do post processing
    [self createBarcodeImage];
}

- (void)createBarcodeImage {
    float x = 0.0;
	
	// Set our prgress bar properties
	self.progressLabel.stringValue = @"Pasting frames...";
    [self.progressBar setMaxValue:self.imageArray.count];
	[self.progressBar setDoubleValue:0];
	
	// Iterate over the images we grabbed
    for (NSImage *imageFromMovie in self.imageArray) {
        // TODO: Implement blur for smoother images
        /*
        CIImage* inputImage = [CIImage imageWithData:[imageFromMovie TIFFRepresentation]];
        CIFilter* filter = [CIFilter filterWithName:@"CIBoxBlur"];
        [filter setDefaults];
        [filter setValue:inputImage forKey:kCIInputImageKey];
        CIImage* outputImage = [filter valueForKey:@"outputImage"];
        
        
        //NSRect outputImageRect = NSRectFromCGRect([outputImage extent]);
        NSRect outputImageRect = imageFromMovie.alignmentRect;
        NSImage* blurredImage = [[NSImage alloc] initWithSize:outputImageRect.size];
        [blurredImage lockFocus];
        [outputImage drawAtPoint:NSZeroPoint fromRect:outputImageRect operation:NSCompositeCopy fraction:1.0];
        [blurredImage unlockFocus];
         */
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
    [self.processButton setEnabled:YES];
	[self.progressBar setHidden:YES];
	self.progressLabel.stringValue = @"";
}

#pragma mark - PROTOCOL METHODS

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
