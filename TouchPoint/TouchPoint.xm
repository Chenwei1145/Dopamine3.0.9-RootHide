#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

static NSString * const TPDomain = @"com.chenwei1145.touchpoint";
static NSString * const TPChanged = @"com.chenwei1145.touchpoint.changed";

static BOOL tpBool(NSString *key, BOOL fallback) {
    NSNumber *v = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    return v ? v.boolValue : fallback;
}
static CGFloat tpFloat(NSString *key, CGFloat fallback) {
    NSNumber *v = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    return v ? v.doubleValue : fallback;
}
static UIColor *tpColor(void) {
    NSNumber *r = [[NSUserDefaults standardUserDefaults] objectForKey:@"red"];
    NSNumber *g = [[NSUserDefaults standardUserDefaults] objectForKey:@"green"];
    NSNumber *b = [[NSUserDefaults standardUserDefaults] objectForKey:@"blue"];
    return [UIColor colorWithRed:r ? r.doubleValue : 0.10 green:g ? g.doubleValue : 0.65 blue:b ? b.doubleValue : 1.0 alpha:1.0];
}

@interface TPOverlayView : UIView
@property(nonatomic) NSMutableDictionary<NSValue *, UIView *> *dots;
@property(nonatomic) UIColor *dotColor;
@property(nonatomic) CGFloat dotSize;
@property(nonatomic) CGFloat dotAlpha;
@property(nonatomic) BOOL showCoordinates;
@end

@implementation TPOverlayView
- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.userInteractionEnabled = NO;
        self.backgroundColor = UIColor.clearColor;
        self.dots = [NSMutableDictionary dictionary];
        [self reloadSettings];
    }
    return self;
}
- (void)reloadSettings {
    self.dotColor = tpColor();
    self.dotSize = MAX(6.0, MIN(80.0, tpFloat(@"size", 24.0)));
    self.dotAlpha = MAX(0.05, MIN(1.0, tpFloat(@"alpha", 0.88)));
    self.showCoordinates = tpBool(@"showCoordinates", NO);
    for (UIView *dot in self.dots.allValues) {
        dot.backgroundColor = [self.dotColor colorWithAlphaComponent:self.dotAlpha];
        dot.layer.cornerRadius = self.dotSize / 2.0;
        dot.bounds = CGRectMake(0, 0, self.dotSize, self.dotSize);
    }
}
- (void)placeTouch:(UITouch *)touch {
    NSValue *key = [NSValue valueWithNonretainedObject:touch];
    CGPoint p = [touch locationInView:self];
    UIView *dot = self.dots[key];
    if (!dot) {
        dot = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.dotSize, self.dotSize)];
        dot.backgroundColor = [self.dotColor colorWithAlphaComponent:self.dotAlpha];
        dot.layer.cornerRadius = self.dotSize / 2.0;
        dot.layer.shadowColor = self.dotColor.CGColor;
        dot.layer.shadowOpacity = 0.45;
        dot.layer.shadowRadius = 5.0;
        dot.layer.shadowOffset = CGSizeZero;
        [self addSubview:dot];
        self.dots[key] = dot;
        dot.alpha = 0.0;
        [UIView animateWithDuration:0.12 animations:^{ dot.alpha = 1.0; }];
    }
    dot.center = p;
}
- (void)endTouch:(UITouch *)touch {
    NSValue *key = [NSValue valueWithNonretainedObject:touch];
    UIView *dot = self.dots[key];
    [self.dots removeObjectForKey:key];
    [UIView animateWithDuration:0.16 animations:^{ dot.alpha = 0.0; dot.transform = CGAffineTransformMakeScale(1.35, 1.35); } completion:^(__unused BOOL done) { [dot removeFromSuperview]; }];
}
@end

static TPOverlayView *gOverlay;
static UIWindow *gWindow;
static void tpSettingsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    dispatch_async(dispatch_get_main_queue(), ^{ [gOverlay reloadSettings]; });
}
static void tpEnsureOverlay(void) {
    if (!tpBool(@"enabled", YES)) return;
    if (gWindow) return;
    UIScreen *screen = UIScreen.mainScreen;
    gWindow = [[UIWindow alloc] initWithFrame:screen.bounds];
    gWindow.windowLevel = UIWindowLevelAlert + 100.0;
    gWindow.backgroundColor = UIColor.clearColor;
    gWindow.userInteractionEnabled = NO;
    UIViewController *vc = [UIViewController new];
    gOverlay = [[TPOverlayView alloc] initWithFrame:gWindow.bounds];
    vc.view = gOverlay;
    gWindow.rootViewController = vc;
    [gWindow makeKeyAndVisible];
    gWindow.hidden = NO;
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, tpSettingsChanged, (__bridge CFStringRef)TPChanged, NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
}

%hook UIApplication
- (void)sendEvent:(UIEvent *)event {
    %orig;
    if (!gOverlay || !tpBool(@"enabled", YES)) return;
    NSUInteger maxTouches = (NSUInteger)MAX(1, MIN(10, tpFloat(@"maxTouches", 5)));
    NSUInteger active = gOverlay.dots.count;
    for (UITouch *touch in event.allTouches) {
        if (touch.phase == UITouchPhaseBegan || touch.phase == UITouchPhaseMoved || touch.phase == UITouchPhaseStationary) {
            if (gOverlay.dots.count < maxTouches || [gOverlay.dots objectForKey:[NSValue valueWithNonretainedObject:touch]]) [gOverlay placeTouch:touch];
        } else if (touch.phase == UITouchPhaseEnded || touch.phase == UITouchPhaseCancelled) {
            [gOverlay endTouch:touch];
        }
    }
    (void)active;
}
%end

%ctor {
    [[NSUserDefaults standardUserDefaults] addSuiteNamed:TPDomain];
    dispatch_async(dispatch_get_main_queue(), ^{ tpEnsureOverlay(); });
}
