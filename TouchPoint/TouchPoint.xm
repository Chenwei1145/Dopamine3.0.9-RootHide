#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

static NSString * const TPDomain = @"com.chenwei1145.touchpoint";
static NSString * const TPChanged = @"com.chenwei1145.touchpoint.changed";

static NSUserDefaults *tpDefaults(void) {
    static NSUserDefaults *defaults;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ defaults = [[NSUserDefaults alloc] initWithSuiteName:TPDomain]; });
    return defaults ?: [NSUserDefaults standardUserDefaults];
}

static BOOL tpBool(NSString *key, BOOL fallback) {
    NSNumber *v = [tpDefaults() objectForKey:key];
    return v ? v.boolValue : fallback;
}
static CGFloat tpFloat(NSString *key, CGFloat fallback) {
    NSNumber *v = [tpDefaults() objectForKey:key];
    return v ? v.doubleValue : fallback;
}
static UIColor *tpColor(void) {
    NSNumber *r = [tpDefaults() objectForKey:@"red"];
    NSNumber *g = [tpDefaults() objectForKey:@"green"];
    NSNumber *b = [tpDefaults() objectForKey:@"blue"];
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
static UIWindow *gHostWindow;
static void tpEnsureOverlay(void);
static void tpSettingsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (tpBool(@"enabled", YES)) {
            tpEnsureOverlay();
            [gOverlay reloadSettings];
            gWindow.hidden = NO;
        } else {
            gWindow.hidden = YES;
        }
    });
}
static void tpEnsureOverlay(void) {
    if (!tpBool(@"enabled", YES)) return;
    if (gWindow) return;
    UIScreen *screen = UIScreen.mainScreen;
    // Prefer SpringBoard's existing window scene; an unattached standalone
    // UIWindow can be invisible on iOS 13+ even when made key and visible.
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated-declarations"
    UIWindow *host = UIApplication.sharedApplication.keyWindow;
    if (!host) {
        for (UIWindow *candidate in UIApplication.sharedApplication.windows) {
            if (!candidate.hidden && candidate.bounds.size.width > 0) { host = candidate; break; }
        }
    }
    #pragma clang diagnostic pop
    if (@available(iOS 13.0, *)) {
        UIWindowScene *scene = nil;
        for (UIScene *candidate in UIApplication.sharedApplication.connectedScenes) {
            if ([candidate isKindOfClass:UIWindowScene.class] && candidate.activationState != UISceneActivationStateUnattached) {
                scene = (UIWindowScene *)candidate;
                break;
            }
        }
        if (!scene) scene = host.windowScene;
        gWindow = scene ? [[UIWindow alloc] initWithWindowScene:scene] : [[UIWindow alloc] initWithFrame:screen.bounds];
    } else {
        gWindow = [[UIWindow alloc] initWithFrame:screen.bounds];
    }
    gWindow.windowLevel = UIWindowLevelAlert + 100.0;
    gWindow.backgroundColor = UIColor.clearColor;
    gWindow.userInteractionEnabled = NO;
    UIViewController *vc = [UIViewController new];
    gOverlay = [[TPOverlayView alloc] initWithFrame:gWindow.bounds];
    vc.view = gOverlay;
    gWindow.rootViewController = vc;
    [gWindow makeKeyAndVisible];
    gWindow.hidden = NO;
    gOverlay.frame = gWindow.bounds;
    if (!gWindow.windowScene && host) {
        // Fallback for SpringBoard's legacy/non-scene window: attach directly
        // to an existing visible window instead of creating an unattached one.
        gWindow.hidden = YES;
        gHostWindow = host;
        gOverlay.frame = host.bounds;
        [host addSubview:gOverlay];
    }
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, tpSettingsChanged, (__bridge CFStringRef)TPChanged, NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
}

// TouchVisualizer-style event pipeline: enumerate every touch in each
// UIApplication event and keep one visual marker per UITouch identity.
static void tpHandleEvent(UIEvent *event) {
    if (!gOverlay || !tpBool(@"enabled", YES)) return;
    NSUInteger maxTouches = (NSUInteger)MAX(1, MIN(10, tpFloat(@"maxTouches", 5)));
    for (UITouch *touch in event.allTouches) {
        if (touch.phase == UITouchPhaseBegan || touch.phase == UITouchPhaseMoved || touch.phase == UITouchPhaseStationary) {
            if (gOverlay.dots.count < maxTouches || [gOverlay.dots objectForKey:[NSValue valueWithNonretainedObject:touch]]) [gOverlay placeTouch:touch];
        } else if (touch.phase == UITouchPhaseEnded || touch.phase == UITouchPhaseCancelled) {
            [gOverlay endTouch:touch];
        }
    }
}

%hook UIApplication
- (void)sendEvent:(UIEvent *)event {
    %orig;
    tpHandleEvent(event);
}
%end

%ctor {
    NSLog(@"[TouchPoint] loaded (TouchVisualizer-style event pipeline)");
    dispatch_async(dispatch_get_main_queue(), ^{
        tpEnsureOverlay();
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            tpEnsureOverlay();
        });
    });
}
