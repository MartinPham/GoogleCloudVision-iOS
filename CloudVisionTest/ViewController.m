//
//  ViewController.m
//  CloudVisionTest
//
//  Created by MartinPham on 26/06/17.
//  Copyright © 2017 fornace. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () <AVCaptureVideoDataOutputSampleBufferDelegate>
{
    AVCaptureSession *session;
    AVCaptureDevice *device;
    AVCaptureDeviceInput *input;
    
    BOOL waitingAPI;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    waitingAPI = NO;
    
    //Capture Session
    session = [[AVCaptureSession alloc]init];
    session.sessionPreset = AVCaptureSessionPreset352x288;
    
    //Add device
    device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    //Input
    input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    
    
    [session addInput:input];
    
    //Output
    AVCaptureVideoDataOutput *videoDataOutput = [AVCaptureVideoDataOutput new];
    [videoDataOutput setVideoSettings:[NSDictionary dictionaryWithObject:
                                       [NSNumber numberWithInt:kCMPixelFormat_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    [videoDataOutput setAlwaysDiscardsLateVideoFrames:YES];
    [session addOutput:videoDataOutput];
    
    [videoDataOutput setSampleBufferDelegate:self queue:dispatch_queue_create("VideoDataOutputQueue", DISPATCH_QUEUE_SERIAL)];

    
    [[videoDataOutput connectionWithMediaType:AVMediaTypeVideo] setEnabled:YES];
    

    
    //Preview Layer
    AVCaptureVideoPreviewLayer *previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
    previewLayer.frame = _cameraView.bounds;
    previewLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    [_cameraView.layer addSublayer:previewLayer];
    
    //Start capture session
    [session startRunning];
    
    _debugTextView.layer.shadowColor = [[UIColor blackColor] CGColor];
    _debugTextView.layer.shadowOffset = CGSizeMake(1.0f, 1.0f);
    _debugTextView.layer.shadowOpacity = 1.0f;
    _debugTextView.layer.shadowRadius = 1.0f;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSLog(@"xx");
    if ( context == @"AVCaptureStillImageIsCapturingStillImageContext" ) {
        
    }
}


- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    
    connection.videoOrientation = AVCaptureVideoOrientationPortrait;
    
    // got an image
    UIImage *image = [self imageFromSampleBuffer:sampleBuffer];
    
    [self sendRequest:image];
    
}

- (void)sendRequest:(UIImage*)image
{
    if(!waitingAPI){
        waitingAPI = true;
        
        /* Configure session, choose between:
         * defaultSessionConfiguration
         * ephemeralSessionConfiguration
         * backgroundSessionConfigurationWithIdentifier:
         And set session-wide properties, such as: HTTPAdditionalHeaders,
         HTTPCookieAcceptPolicy, requestCachePolicy or timeoutIntervalForRequest.
         */
        NSURLSessionConfiguration* sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        
        /* Create session, and optionally set a NSURLSessionDelegate. */
        NSURLSession* urlSession = [NSURLSession sessionWithConfiguration:sessionConfig delegate:nil delegateQueue:nil];
        
        /* Create the Request:
         Request (POST https://vision.googleapis.com/v1/images:annotate)
         */
        
        NSURL* URL = [NSURL URLWithString:@"https://vision.googleapis.com/v1/images:annotate"];
        NSDictionary* URLParams = @{
                                    @"key": @"AIzaSyC2TrHOWVo7rmHtzM_k643_DU7_W5qJDo4",
                                    };
        URL = NSURLByAppendingQueryParameters(URL, URLParams);
        NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:URL];
        request.HTTPMethod = @"POST";
        
        // Headers
        
        [request addValue:@"text/plain; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
        
        // Body
        
        
        NSString *image64 = [UIImagePNGRepresentation(image) base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
        
        request.HTTPBody = [[NSString stringWithFormat:
                             @
                             "{"
                                "\"requests\": ["
                                    "{"
                                        "\"image\": {"
                                            "\"content\": \"%@\""
                                        "},"
                                        "\"features\": ["
                                            "{"
                                                "\"type\": \"LABEL_DETECTION\""
                                            "}"
                                        "]"
                                    "}"
                                "]"
                             "}"
                             , image64] dataUsingEncoding:NSUTF8StringEncoding];
        
        /* Start a new Task */
        NSURLSessionDataTask* task = [urlSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            waitingAPI = NO;
            if (error == nil) {
                // Success
                //            NSLog(@"URL Session Task Succeeded: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
                
                NSString *debug = @"";
                NSDictionary *object = [NSJSONSerialization
                                        JSONObjectWithData:data
                                        options:0
                                        error:&error];
                
                NSLog(@"%@", object);
                
                NSArray *labelAnnotations = object[@"responses"][0][@"labelAnnotations"];
                for(NSDictionary *annotation in labelAnnotations)
                {
                    debug = [debug stringByAppendingString:[NSString stringWithFormat:@"%@ - %f\n", annotation[@"description"], [annotation[@"score"] floatValue]]];
                }
                
                dispatch_sync(dispatch_get_main_queue(),
                              ^{
                                  _debugTextView.text = debug;
                              });
            }
            else {
                // Failure
                //            NSLog(@"URL Session Task Failed: %@", [error localizedDescription]);
            }
        }];
        [task resume];
        [urlSession finishTasksAndInvalidate];

    }
}

/*
 * Utils: Add this section before your class implementation
 */

/**
 This creates a new query parameters string from the given NSDictionary. For
 example, if the input is @{@"day":@"Tuesday", @"month":@"January"}, the output
 string will be @"day=Tuesday&month=January".
 @param queryParameters The input dictionary.
 @return The created parameters string.
 */
static NSString* NSStringFromQueryParameters(NSDictionary* queryParameters)
{
    NSMutableArray* parts = [NSMutableArray array];
    [queryParameters enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        NSString *part = [NSString stringWithFormat: @"%@=%@",
                          [key stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding],
                          [value stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]
                          ];
        [parts addObject:part];
    }];
    return [parts componentsJoinedByString: @"&"];
}

/**
 Creates a new URL by adding the given query parameters.
 @param URL The input URL.
 @param queryParameters The query parameter dictionary to add.
 @return A new NSURL.
 */
static NSURL* NSURLByAppendingQueryParameters(NSURL* URL, NSDictionary* queryParameters)
{
    NSString* URLString = [NSString stringWithFormat:@"%@?%@",
                           [URL absoluteString],
                           NSStringFromQueryParameters(queryParameters)
                           ];
    return [NSURL URLWithString:URLString];
}






// Create a UIImage from sample buffer data
- (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer  {
    // Get a CMSampleBuffer's Core Video image buffer for the media data
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // Lock the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // Get the number of bytes per row for the pixel buffer
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    // Get the number of bytes per row for the pixel buffer
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // Get the pixel buffer width and height
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // Create a device-dependent RGB color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // Create a bitmap graphics context with the sample buffer data
    CGContextRef context1 = CGBitmapContextCreate(baseAddress, width, height, 8,
                                                  bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    
    // Create a Quartz image from the pixel data in the bitmap graphics context
    CGImageRef quartzImage = CGBitmapContextCreateImage(context1);
    // Unlock the pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    // Free up the context and color space
    CGContextRelease(context1);
    CGColorSpaceRelease(colorSpace);
    
    // Create an image object from the Quartz image
    //I modified this line: [UIImage imageWithCGImage:quartzImage]; to the following to correct the orientation:
    UIImage *image =  [UIImage imageWithCGImage:quartzImage scale:1.0 orientation:UIImageOrientationRight];
    
    // Release the Quartz image
    CGImageRelease(quartzImage);
    
    return (image);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [[_cameraView.layer sublayers] firstObject].frame = _cameraView.bounds;
    
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
