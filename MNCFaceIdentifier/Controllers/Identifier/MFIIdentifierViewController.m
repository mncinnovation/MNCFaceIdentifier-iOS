//
//  MFIIdentifierViewController.m
//  MNCFaceIdentifier
//
//  Created by MCOMM00008 on 30/05/22.
//

#import "MFIIdentifierViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreVideo/CoreVideo.h>
#import "MFIUtils.h"
#import "MFIDataModel.h"
#import "MNCFaceIdentifierResult.h"

@import MLKitFaceDetection;
@import MLKitVision;

static const CGFloat faceFrameWidthRatio = 302;
static const CGFloat faceFrameHeightRatio = 357;

@interface MFIIdentifierViewController () <AVCaptureVideoDataOutputSampleBufferDelegate> {
    NSBundle *bundle;
    MLKFaceDetectorOptions *options;
    NSTimer *timer;
    UIImage *lastImage;
    BOOL isCaptured;
    NSDate *dateStartedScanning;
}

typedef NS_ENUM(NSInteger, StepFace) {
    StepFaceInframe,
    StepFaceBlink,
    StepFaceLookLeftOrRight,
    StepFaceSmile,
    StepFaceComplete
};

@property (nonatomic) MFIDataModel *dataModel;
@property (nonatomic) MNCFaceIdentifierResult *faceIdentifierResult;
@property (nonatomic) MFIComparationModel *comparationModel;
@property (nonatomic) StepFace stepFace;
@property (nonatomic) UIView *previewView;
@property (nonatomic) UIView *coordinateView;
@property (nonatomic) UIView *faceView;
@property (nonatomic) UILabel *counterLabel;
@property (nonatomic) UILabel *instructionLabel;
@property (nonatomic) AVCaptureSession *capturesSession;
@property (nonatomic) AVCapturePhotoOutput *stillImageOutput;
@property (nonatomic) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@property (nonatomic) CGFloat percentageToPass;

@end

@implementation MFIIdentifierViewController

- (NSString *)instructionForStepFace:(StepFace)stepFace {
    switch (stepFace) {
        case StepFaceInframe:
            return @"Tahan wajah anda didalam frame selama 3 detik";
        case StepFaceBlink:
            return  @"Kedua, Berkedip";
        case StepFaceLookLeftOrRight:
            return @"Ketiga, arahkan kepala ke kiri atau kanan";
        case StepFaceSmile:
            return @"Terakhir, tersenyum";
        case StepFaceComplete:
            return @"Detection Complete";
    }
};

int countdown = 0;
int startedInframe = 0;
long totalTimeMillis = 0;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    bundle = [NSBundle bundleWithIdentifier:@"MNCIdentifier.MNCFaceIdentifier"];
    self.dataModel = [MFIDataModel new];
    self.faceIdentifierResult = [MNCFaceIdentifierResult new];
    self.stepFace = StepFaceInframe;
    countdown = 20;
    startedInframe = 0;
    
    options = [[MLKFaceDetectorOptions alloc] init];
    options.performanceMode = MLKFaceDetectorPerformanceModeFast;
    options.contourMode = MLKFaceDetectorContourModeAll;
    options.landmarkMode = MLKFaceDetectorLandmarkModeNone;
    options.classificationMode = MLKFaceDetectorClassificationModeAll;
    
    [self setupView];
    [self startTimer];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.capturesSession = [AVCaptureSession new];
    self.capturesSession.sessionPreset = AVCaptureSessionPresetPhoto;
    
    AVCaptureDeviceDiscoverySession *captureDeviceDiscoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionFront];
    NSArray *captureDevices = [captureDeviceDiscoverySession devices];
    
    NSError *error;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevices[0] error:&error];
    
    AVCaptureVideoDataOutput *outputDevice = [[AVCaptureVideoDataOutput alloc] init];
    outputDevice.videoSettings = @{(id) kCVPixelBufferPixelFormatTypeKey: [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA]};
    outputDevice.alwaysDiscardsLateVideoFrames = YES;
    [outputDevice setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    
    if (!error) {
        self.stillImageOutput = [AVCapturePhotoOutput new];
        
        if ([self.capturesSession canAddInput:input] && [self.capturesSession canAddOutput:self.stillImageOutput]) {
            [self.capturesSession addInput:input];
            [self.capturesSession addOutput:outputDevice];
            [self setupLivePreview];
        }
    } else {
        NSLog(@"Error Unable to intialize front camera: %@", error.localizedDescription);
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.capturesSession stopRunning];
}

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CGFloat imageWidth = CVPixelBufferGetWidth(imageBuffer);
    CGFloat imageHeight = CVPixelBufferGetHeight(imageBuffer);
    
    [self processPicture:sampleBuffer withWidth:imageWidth withHeight:imageHeight];
}

- (void)setupView {
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.previewView = [[UIView alloc] init];
    self.previewView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.previewView];
    [self.previewView.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;
    [self.previewView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
    [self.previewView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor].active = YES;
    [self.previewView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor].active = YES;
    
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    CGFloat widthFaceImageView = width - 72;
    CGFloat heightFaceImageView = (faceFrameHeightRatio * widthFaceImageView) / faceFrameWidthRatio;
    
    self.faceView = [[UIView alloc] init];
    self.faceView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.faceView];
    
    [self.faceView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
    [self.faceView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:95].active = YES;
    [self.faceView.widthAnchor constraintEqualToConstant:widthFaceImageView].active = YES;
    [self.faceView.heightAnchor constraintEqualToConstant:heightFaceImageView].active = YES;
    
    UIImage *faceImage = [UIImage imageNamed:@"image_face" inBundle:bundle compatibleWithTraitCollection:nil];
    UIImageView *faceImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, widthFaceImageView, heightFaceImageView)];
    faceImageView.image = faceImage;
    [self.faceView addSubview:faceImageView];
    
    CAShapeLayer *yourViewBorder = [CAShapeLayer layer];
    yourViewBorder.strokeColor = [UIColor whiteColor].CGColor;
    yourViewBorder.fillColor = nil;
    yourViewBorder.lineDashPattern = @[@10, @5];
    yourViewBorder.frame = faceImageView.bounds;
    yourViewBorder.path = [UIBezierPath bezierPathWithRect:faceImageView.bounds].CGPath;
    [faceImageView.layer addSublayer:yourViewBorder];
    
    UIView *topTransparentView = [[UIView alloc] init];
    topTransparentView.backgroundColor = [UIColor blackColor];
    topTransparentView.alpha = 0.5;
    topTransparentView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:topTransparentView];
    [topTransparentView.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;
    [topTransparentView.leftAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leftAnchor].active = YES;
    [topTransparentView.rightAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.rightAnchor].active = YES;
    [topTransparentView.bottomAnchor constraintEqualToAnchor:self.faceView.topAnchor].active = YES;
    
    UIView *bottomTransparentView = [[UIView alloc] init];
    bottomTransparentView.backgroundColor = [UIColor blackColor];
    bottomTransparentView.alpha = 0.5;
    bottomTransparentView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:bottomTransparentView];
    [bottomTransparentView.topAnchor constraintEqualToAnchor:self.faceView.bottomAnchor].active = YES;
    [bottomTransparentView.leftAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leftAnchor].active = YES;
    [bottomTransparentView.rightAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.rightAnchor].active = YES;
    [bottomTransparentView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
    
    UIView *leftTransparentView = [[UIView alloc] init];
    leftTransparentView.backgroundColor = [UIColor blackColor];
    leftTransparentView.alpha = 0.5;
    leftTransparentView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:leftTransparentView];
    [leftTransparentView.topAnchor constraintEqualToAnchor:topTransparentView.bottomAnchor].active = YES;
    [leftTransparentView.leftAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leftAnchor].active = YES;
    [leftTransparentView.rightAnchor constraintEqualToAnchor:self.faceView.leftAnchor].active = YES;
    [leftTransparentView.bottomAnchor constraintEqualToAnchor:bottomTransparentView.topAnchor].active = YES;
    
    UIView *rightTransparentView = [[UIView alloc] init];
    rightTransparentView.backgroundColor = [UIColor blackColor];
    rightTransparentView.alpha = 0.5;
    rightTransparentView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:rightTransparentView];
    [rightTransparentView.topAnchor constraintEqualToAnchor:topTransparentView.bottomAnchor].active = YES;
    [rightTransparentView.leftAnchor constraintEqualToAnchor:self.faceView.rightAnchor].active = YES;
    [rightTransparentView.rightAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.rightAnchor].active = YES;
    [rightTransparentView.bottomAnchor constraintEqualToAnchor:bottomTransparentView.topAnchor].active = YES;
    
    self.instructionLabel = [[UILabel alloc] init];
    self.instructionLabel.textColor = [UIColor whiteColor];
    self.instructionLabel.text = @"Pertama, gerakan wajah anda di dalam frame kamera.";
    self.instructionLabel.font = [UIFont boldSystemFontOfSize:16];
    self.instructionLabel.textAlignment = NSTextAlignmentCenter;
    self.instructionLabel.numberOfLines = 0;
    self.instructionLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.instructionLabel];
    [self.instructionLabel.leftAnchor constraintEqualToAnchor:self.faceView.leftAnchor].active = YES;
    [self.instructionLabel.rightAnchor constraintEqualToAnchor:self.faceView.rightAnchor].active = YES;
    [self.instructionLabel.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-48].active = YES;
    
    self.counterLabel = [[UILabel alloc] init];
    self.counterLabel.textColor = [UIColor redColor];
    self.counterLabel.text = @"20";
    self.counterLabel.font = [UIFont systemFontOfSize:48];
    self.counterLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.counterLabel];
    [self.counterLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
    [self.counterLabel.bottomAnchor constraintEqualToAnchor:self.instructionLabel.topAnchor constant:-12].active = YES;
    
    self.coordinateView = [[UIView alloc] init];
    self.coordinateView.translatesAutoresizingMaskIntoConstraints = NO;
    self.coordinateView.backgroundColor = UIColor.clearColor;
    [self.view addSubview:self.coordinateView];
    [self.coordinateView.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;
    [self.coordinateView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
    [self.coordinateView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor].active = YES;
    [self.coordinateView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor].active = YES;
    
    UIStackView *backStackView = [[UIStackView alloc] init];
    backStackView.axis = UILayoutConstraintAxisHorizontal;
    backStackView.distribution = UIStackViewDistributionEqualSpacing;
    backStackView.alignment = UIStackViewAlignmentCenter;
    backStackView.spacing = 16;
    backStackView.translatesAutoresizingMaskIntoConstraints = NO;
    
    UIImage *backImage = [UIImage imageNamed:@"icon_arrow_back" inBundle:bundle compatibleWithTraitCollection:nil];
    UIImageView *backImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 16, 16)];
    backImageView.image = backImage;
    
    UILabel *backLabel = [[UILabel alloc] init];
    backLabel.text = @"Kembali";
    backLabel.textColor = [UIColor whiteColor];
    backLabel.font = [UIFont systemFontOfSize:16];
    
    [backStackView addArrangedSubview:backImageView];
    [backStackView addArrangedSubview:backLabel];
    
    [self.view addSubview:backStackView];
    [backStackView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:28].active = YES;
    [backStackView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:33].active = YES;
    
    UIButton *backButton = [[UIButton alloc] init];
    [backButton addTarget:self
                   action:@selector(backTapped)
         forControlEvents:UIControlEventTouchUpInside];
    backButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:backButton];
    [backButton.leftAnchor constraintEqualToAnchor:backStackView.leftAnchor].active = YES;
    [backButton.rightAnchor constraintEqualToAnchor:backStackView.rightAnchor].active = YES;
    [backButton.topAnchor constraintEqualToAnchor:backStackView.topAnchor].active = YES;
    [backButton.bottomAnchor constraintEqualToAnchor:backStackView.bottomAnchor].active = YES;
}

- (void)setupLivePreview {
    self.videoPreviewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.capturesSession];
    self.videoPreviewLayer.connection.videoOrientation = AVCaptureVideoOrientationPortrait;
    [self.videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [self.previewView.layer addSublayer:self.videoPreviewLayer];
    
    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_async(globalQueue, ^{
        [self.capturesSession startRunning];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.videoPreviewLayer.frame = self.previewView.bounds;
        });
    });
}

- (void)startTimer {
    countdown = 20;
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timerHandler) userInfo:nil repeats:YES];
    dateStartedScanning = [NSDate new];
}

- (void)stopTimer {
    if (timer != NULL) {
        [timer invalidate];
    }
}

- (void)timerHandler {
    NSString *countString = [NSString stringWithFormat:@"%d", countdown];
    self.counterLabel.text = countString;
    countdown -= 1;
    [self checkEKYC];
    if (countdown < 0) {
        [self backTapped];
    }
}

- (void)checkEKYC {
    BOOL isFaceInFrame = [self isFaceInFrame];
    if (!isFaceInFrame) {
        self.instructionLabel.text = _stepFace == StepFaceInframe ? @"Pertama, gerakan wajah anda di dalam frame kamera." : @"Sesuaikan kembali wajah ada kedalam frame";
        startedInframe = 0;
        return;
    }
    
    self.instructionLabel.text = [self instructionForStepFace:_stepFace];
    
    switch (self.stepFace) {
        case StepFaceInframe:
            startedInframe = startedInframe == 0 ? countdown : startedInframe;
            if (countdown <= (startedInframe - 3)) {
                MOIFaceModel *faceModel = [MOIFaceModel new];
                faceModel.detectionMode = HOLD_STILL;
                faceModel.image = [MFIUtils saveImageToStorage:lastImage withFileName:@"faceInFrame.jpg"];
                faceModel.timeMillis =  (([NSDate new].timeIntervalSince1970 - dateStartedScanning.timeIntervalSince1970) * 1000);
                self.faceIdentifierResult.detectionResult = [NSMutableArray new];
                [self.faceIdentifierResult.detectionResult addObject:faceModel];
                
                
                self.faceIdentifierResult.faceInFrame = [MFIUtils saveImageToStorage:lastImage withFileName:@"faceInFrame.jpg"];
                self.stepFace = StepFaceBlink;
                countdown = 20;
                isCaptured = NO;
                totalTimeMillis = totalTimeMillis + faceModel.timeMillis;
                dateStartedScanning = [NSDate new];
            }
            break;
        case StepFaceBlink:
            if (self.dataModel.hasBlink) {
                self.stepFace = StepFaceLookLeftOrRight;
                countdown = 20;
                isCaptured = NO;
                dateStartedScanning = [NSDate new];
            }
            break;
        case StepFaceLookLeftOrRight:
            if (self.dataModel.hasLookLeft || self.dataModel.hasLookRight) {
                self.stepFace = StepFaceSmile;
                countdown = 20;
                isCaptured = NO;
                dateStartedScanning = [NSDate new];
            }
            break;
        case StepFaceSmile:
            if (self.dataModel.hasSmile) {
                self.stepFace = StepFaceComplete;
                countdown = 20;
                isCaptured = NO;
                dateStartedScanning = [NSDate new];
            }
            break;
        case StepFaceComplete:
            self.faceIdentifierResult.attempt = 1;
            self.faceIdentifierResult.totalTimeInMillis = totalTimeMillis;
            [self backTapped];
            break;
    }
}

- (BOOL)isFaceInFrame {
    CGFloat percentageMatchToFrame = _comparationModel.accuratePercentage;
    
    switch (self.stepFace) {
        case StepFaceLookLeftOrRight:
            self.percentageToPass = 25;
        default:
            self.percentageToPass = 50;
    }
    
    if (percentageMatchToFrame > self.percentageToPass && ((self.comparationModel.isTopPointInside && self.comparationModel.isBottomPointInside) || (self.comparationModel.isLeftPointInside && self.comparationModel.isRightPointInside))) {
        return YES;
    }
    
    return NO;
}

- (void)processPicture:(CMSampleBufferRef)sampleBuffer withWidth:(CGFloat)width withHeight:(CGFloat)height {
    
    UIImage *convertImage =[self screenshotOfVideoStream:sampleBuffer];
    
    MLKVisionImage *visionImage = [[MLKVisionImage alloc] initWithBuffer:sampleBuffer];
    UIImageOrientation orientation = [MFIUtils imageOrientationFromDevicePosition:AVCaptureDevicePositionFront];
    lastImage = [UIImage imageWithCGImage:[convertImage CGImage] scale:[convertImage scale] orientation: orientation];
    visionImage.orientation = orientation;
    MLKFaceDetector *faceDetector = [MLKFaceDetector faceDetectorWithOptions:options];
    
    [faceDetector processImage:visionImage completion:^(NSArray<MLKFace *> *faces, NSError *error) {
        for (UIView *annotationView in self.coordinateView.subviews) {
            [annotationView removeFromSuperview];
        }
        
        if (error != nil) {
            NSLog(@"%@", error.description);
            return;
        }
        
        if (faces.count > 0) {
            
            for (MLKFace *face in faces) {
                [self calculateFaceForData:face withWidth:width withHeight:height];
            }
        }
    }];
}

- (void)calculateFaceForData:(MLKFace *)face withWidth:(CGFloat)width withHeight:(CGFloat)height {
    CGRect normalizedRect = CGRectMake(face.frame.origin.x / width, face.frame.origin.y / height, face.frame.size.width / width, face.frame.size.height / height);
    CGRect standardizedRect = CGRectStandardize([self.videoPreviewLayer rectForMetadataOutputRectOfInterest:normalizedRect]);
    
    self.comparationModel =  [MFIUtils getRectAccuration:standardizedRect byComparison:self.faceView.frame enableDot:NO viewForDot:self.coordinateView];
    
    if (face.hasHeadEulerAngleX) {
        self.dataModel.rotX = face.headEulerAngleX;
    }
    
    if (face.hasHeadEulerAngleY) {
        self.dataModel.rotY = face.headEulerAngleY;
    }
    
    if (face.hasHeadEulerAngleZ) {
        self.dataModel.rotZ = face.headEulerAngleZ;
    }
    
    if (face.hasSmilingProbability) {
        self.dataModel.smileProb = face.smilingProbability;
    }
    
    if (face.hasLeftEyeOpenProbability) {
        self.dataModel.leftEyeProb = face.leftEyeOpenProbability;
    }
    
    if (face.hasRightEyeOpenProbability) {
        self.dataModel.rightEyeProb = face.rightEyeOpenProbability;
    }
    
    switch(self.stepFace) {
        case StepFaceInframe:
            break;
        case StepFaceBlink:
            [self.dataModel blinkingCheck];
            if (self.dataModel.hasBlink && !isCaptured) {
                MOIFaceModel *faceModel = [MOIFaceModel new];
                faceModel.detectionMode = BLINK;
                faceModel.image = [MFIUtils saveImageToStorage:lastImage withFileName:@"faceBlink.jpg"];
                faceModel.timeMillis = (([NSDate new].timeIntervalSince1970 - dateStartedScanning.timeIntervalSince1970) * 1000);
                
                [self.faceIdentifierResult.detectionResult addObject:faceModel];
                
                totalTimeMillis = totalTimeMillis + faceModel.timeMillis;
                
                self.faceIdentifierResult.faceBlink = [MFIUtils saveImageToStorage:lastImage withFileName:@"faceBlink.jpg"];
                isCaptured = YES;
            }
            break;
        case StepFaceLookLeftOrRight:
            [self.dataModel lookDirectionCheck];
            if ((self.dataModel.hasLookLeft || self.dataModel.hasLookRight) && !isCaptured) {
                MOIFaceModel *faceModel = [MOIFaceModel new];
                faceModel.detectionMode = SHAKE_HEAD;
                faceModel.image = [MFIUtils saveImageToStorage:lastImage withFileName:@"faceLookLeftOrRight.jpg"];
                faceModel.timeMillis = (([NSDate new].timeIntervalSince1970 - dateStartedScanning.timeIntervalSince1970) * 1000);
                
                [self.faceIdentifierResult.detectionResult addObject:faceModel];
                
                totalTimeMillis = totalTimeMillis + faceModel.timeMillis;
                
                self.faceIdentifierResult.faceLookLeftOrRight = [MFIUtils saveImageToStorage:lastImage withFileName:@"faceLookLeftOrRight.jpg"];
                isCaptured = YES;
            }
            break;
        case StepFaceSmile:
            [self.dataModel smilingCheck];
            if (self.dataModel.hasSmile && !isCaptured) {
                MOIFaceModel *faceModel = [MOIFaceModel new];
                faceModel.detectionMode = SMILE;
                faceModel.image = [MFIUtils saveImageToStorage:lastImage withFileName:@"faceSmile.jpg"];
                faceModel.timeMillis = (([NSDate new].timeIntervalSince1970 - dateStartedScanning.timeIntervalSince1970) * 1000);
                
                [self.faceIdentifierResult.detectionResult addObject:faceModel];
                
                totalTimeMillis = totalTimeMillis + faceModel.timeMillis;
                
                self.faceIdentifierResult.faceSmile = [MFIUtils saveImageToStorage:lastImage withFileName:@"faceSmile.jpg"];
                isCaptured = YES;
            }
            break;
        case StepFaceComplete:
            break;
    }
}

-(UIImage *)screenshotOfVideoStream:(CMSampleBufferRef)samImageBuff {
    CVImageBufferRef imageBuffer =
    CMSampleBufferGetImageBuffer(samImageBuff);
    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:imageBuffer];
    CIContext *temporaryContext = [CIContext contextWithOptions:nil];
    CGImageRef videoImage = [temporaryContext createCGImage:ciImage fromRect:CGRectMake(0, 0, CVPixelBufferGetWidth(imageBuffer), CVPixelBufferGetHeight(imageBuffer))];
    
    UIImage *image = [[UIImage alloc] initWithCGImage:videoImage];
    CGImageRelease(videoImage);
    return image;
}

- (void)backTapped {
    self.faceIdentifierResult.isSuccess = NO;
    if (countdown < 0) {
        [self.faceIdentifierResult.detectionResult removeAllObjects];
        self.faceIdentifierResult.errorMessage = @"Timeout";
    } else if (self.stepFace == StepFaceComplete) {
        self.faceIdentifierResult.isSuccess = YES;
    } else {
        [self.faceIdentifierResult.detectionResult removeAllObjects];
        self.faceIdentifierResult.errorMessage = @"Canceled by user";
    }
    [self stopTimer];
    [self.delegate faceIdentifierResult:self.faceIdentifierResult];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
