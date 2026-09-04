#import <UIKit/UIKit.h>

static NSString * const TPDomain = @"com.chenwei1145.touchpoint";
static NSString * const TPChanged = @"com.chenwei1145.touchpoint.changed";

@interface TPSettingsController : UITableViewController
@property(nonatomic) UISwitch *enabled;
@property(nonatomic) UISlider *size;
@property(nonatomic) UISlider *alpha;
@property(nonatomic) UISlider *red;
@property(nonatomic) UISlider *green;
@property(nonatomic) UISlider *blue;
@property(nonatomic) UISlider *maxTouches;
@property(nonatomic) UISwitch *coords;
@end

@implementation TPSettingsController
- (NSUserDefaults *)prefs { NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:TPDomain]; return d; }
- (UISlider *)slider:(NSString *)key min:(float)min max:(float)max value:(float)fallback {
    UISlider *s = [UISlider new]; s.minimumValue=min; s.maximumValue=max; s.value=[[[self prefs] objectForKey:key] floatValue] ?: fallback; [s addTarget:self action:@selector(changed:) forControlEvents:UIControlEventValueChanged]; return s;
}
- (void)viewDidLoad {
    [super viewDidLoad]; self.title = @"TouchPoint"; self.tableView = [UITableView new];
    self.enabled = [UISwitch new]; self.enabled.on = [[self prefs] objectForKey:@"enabled"] ? [[[self prefs] objectForKey:@"enabled"] boolValue] : YES; [self.enabled addTarget:self action:@selector(changed:) forControlEvents:UIControlEventValueChanged];
    self.size=[self slider:@"size" min:6 max:80 value:24]; self.alpha=[self slider:@"alpha" min:.1 max:1 value:.88]; self.red=[self slider:@"red" min:0 max:1 value:.1]; self.green=[self slider:@"green" min:0 max:1 value:.65]; self.blue=[self slider:@"blue" min:0 max:1 value:1]; self.maxTouches=[self slider:@"maxTouches" min:1 max:10 value:5];
    self.coords=[UISwitch new]; self.coords.on=[[[self prefs] objectForKey:@"showCoordinates"] boolValue]; [self.coords addTarget:self action:@selector(changed:) forControlEvents:UIControlEventValueChanged];
    self.navigationItem.rightBarButtonItem=[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reset)];
}
- (NSArray *)labels { return @[@"启用触摸点", @"大小", @"透明度", @"红", @"绿", @"蓝", @"最大触摸点", @"显示坐标"]; }
- (NSInteger)tableView:(UITableView *)t numberOfRowsInSection:(NSInteger)s { return 8; }
- (UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)p { UITableViewCell *c=[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil]; c.textLabel.text=[self labels][p.row]; UIView *v=@[self.enabled,self.size,self.alpha,self.red,self.green,self.blue,self.maxTouches,self.coords][p.row]; c.accessoryView=v; return c; }
- (void)changed:(id)sender { NSUserDefaults *d=[self prefs]; NSArray *keys=@[@"enabled",@"size",@"alpha",@"red",@"green",@"blue",@"maxTouches",@"showCoordinates"]; NSArray *views=@[self.enabled,self.size,self.alpha,self.red,self.green,self.blue,self.maxTouches,self.coords]; for(NSUInteger i=0;i<keys.count;i++){id v=views[i]; NSNumber *value = [v isKindOfClass:UISwitch.class] ? @([(UISwitch *)v isOn]) : @([(UISlider *)v value]); [d setObject:value forKey:keys[i]];} [d synchronize]; CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge CFStringRef)TPChanged, NULL, NULL, true); }
- (void)reset { [[self prefs] removePersistentDomainForName:TPDomain]; [self viewDidLoad]; [self.tableView reloadData]; [self changed:nil]; }
@end

@interface TPAppDelegate : UIResponder <UIApplicationDelegate> @property(nonatomic) UIWindow *window; @end
@implementation TPAppDelegate
- (BOOL)application:(UIApplication *)app didFinishLaunchingWithOptions:(NSDictionary *)opts { self.window=[[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds]; UINavigationController *n=[[UINavigationController alloc] initWithRootViewController:[TPSettingsController new]]; self.window.rootViewController=n; [self.window makeKeyAndVisible]; return YES; }
@end
int main(int argc, char **argv) { @autoreleasepool { return UIApplicationMain(argc, argv, nil, NSStringFromClass(TPAppDelegate.class)); } }
