
http://code4app.com/ios/567577dd594b90e97f8b47e4 //可看动画演示

YGPSlideViewDemo
在做新闻客户端 UIScrollView 重用展现较多的栏目比较常见
简单的封装了下

// delegate Method

Cell 初始化完成时会进行回调，可以在此处加载缓存数据
- (void)slideViewInitiatedComplete:(YLSlideCell*)cell forIndex:(NSUInteger)index

Cell 可见时会回调此代理方法。这时可以加载新的数据
- (void)slideVisibleView:(YLSlideCell*)cell forIndex:(NSUInteger)index

//数据缓存
如果你的 Cell 是 UITableView 当 UITableView 滚出屏幕不时可见时会保存offset。 当下一次加载Cell时会显示上次滚动的位置
