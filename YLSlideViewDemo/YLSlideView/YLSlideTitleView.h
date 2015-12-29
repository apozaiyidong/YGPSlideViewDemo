
/*
  YLSlideTitleView 栏目标题
 */

#import <UIKit/UIKit.h>
static float const YLSildeTitleViewHeight = 44;

typedef void (^YLSlideTitleViewScrollBlock)(CGFloat offset_x);
typedef void (^YLSlideViewWillScrollEndBlock)(CGFloat offset_x);
typedef void (^YLSlideTitleViewClickButtonBlock)(NSUInteger index);

@interface YLSlideTitleView : UIScrollView

@property (nonatomic,copy) YLSlideTitleViewScrollBlock
slideTitleViewScrollBlock;
@property (nonatomic,copy) YLSlideTitleViewClickButtonBlock slideTitleViewClickButtonBlock;
@property (nonatomic,copy) YLSlideViewWillScrollEndBlock
slideViewWillScrollEndBlock;
/*判断是否点击 Button 或 滚动 UIScrollView 进行页面的切换 */
@property (nonatomic,assign) BOOL isClickTitleButton;

- (instancetype)initWithFrame:(CGRect)frame forTitles:(NSArray*)titles;

@end
