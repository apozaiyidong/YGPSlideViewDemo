
#import "ViewController.h"
#import "YLSlideView/YLSlideView.h"
#import "YLSlideConfig.h"
#import "YLSlideView/YLSlideCell.h"
#import "YGPCache.h"

@interface ViewController ()<YLSlideViewDelegate,UITableViewDataSource,UITableViewDelegate>
{

    YLSlideView * _slideView;
    NSArray *colors;
    NSArray *_testArray;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"新闻客户端ScrollView重用";
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.extendedLayoutIncludesOpaqueBars =NO;
    self.modalPresentationCapturesStatusBarAppearance =NO;
    self.navigationController.navigationBar.translucent =NO;
    
    colors = @[[UIColor redColor],[UIColor yellowColor],[UIColor blackColor],[UIColor redColor],[UIColor yellowColor],[UIColor blackColor],[UIColor redColor],[UIColor yellowColor],[UIColor blackColor]];
    
    _slideView = [[YLSlideView alloc]initWithFrame:CGRectMake(0, 0,
                                                              SCREEN_WIDTH_YLSLIDE,
                                                              SCREEN_HEIGHT_YLSLIDE-64)
                                         forTitles:@[@"有书头条",
                                                     @"头条",
                                                     @"要闻",
                                                     @"有书头条",
                                                     @"头条",
                                                     @"要闻",
                                                     @"有书头条",
                                                     @"头条",
                                                     @"要闻"]];
    
    _slideView.backgroundColor = [UIColor whiteColor];
    _slideView.delegate        = self;
    [self.view addSubview:_slideView];
    
}

- (NSInteger)columnNumber{
    return colors.count;
}

- (YLSlideCell *)slideView:(YLSlideView *)slideView
         cellForRowAtIndex:(NSUInteger)index{

    YLSlideCell * cell = [slideView dequeueReusableCell];
    
    if (!cell) {
        cell = [[YLSlideCell alloc]initWithFrame:CGRectMake(0, 0, 320, 500)
                                           style:UITableViewStylePlain];
        cell.delegate   = self;
        cell.dataSource = self;
    }
    
//    cell.backgroundColor = colors[index];
    
    
    return cell;
}
- (void)slideVisibleView:(YLSlideCell *)cell forIndex:(NSUInteger)index{
    
    NSLog(@"index :%@ ",@(index));
    [cell reloadData]; //刷新TableView
//    NSLog(@"刷新数据");
}

- (void)slideViewInitiatedComplete:(YLSlideCell *)cell forIndex:(NSUInteger)index{

    //可以在这里做数据的预加载（缓存数据）
    NSLog(@"缓存数据 %@",@(index));
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [cell reloadData];

    });
}

#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{

    return 20;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{

    NSString *Identifier = @"cell";
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:Identifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:Identifier];
    }
    
    cell.textLabel.text = [@(arc4random()%1000) stringValue];
    
    
    return cell;
}

@end
