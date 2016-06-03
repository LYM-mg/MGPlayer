//
//  MGTencentNewsViewController.m
//  MGPlayer
//
//  Created by ming on 16/6/3.
//  Copyright © 2016年 ming. All rights reserved.
//

#import "MGTencentNewsViewController.h"
#import "SidModel.h"
#import "VideoCell.h"
#import "VideoModel.h"
#import "MGDetailViewController.h"

static NSString *VideoCellIdentifier = @"VideoCell";

@interface MGTencentNewsViewController ()<UITableViewDelegate,UITableViewDataSource>
{
    /** 视频播放器 */
    WMPlayer *wmPlayer;
}
/** 视频数据源 */
@property (nonatomic,strong) NSMutableArray *dataSource;

/** 当前索引 */
@property (nonatomic, assign) NSIndexPath *currentIndexPath;
/** 是否小屏幕 */
@property (nonatomic, assign) BOOL isSmallScreen;
/** 当前的VideoCell */
@property(nonatomic,strong) VideoCell *currentCell;
@end

@implementation MGTencentNewsViewController

#pragma mark - 系统方法
- (instancetype)init{
    self = [super init];
    if (self) {
        self.dataSource = [NSMutableArray array];
        self.isSmallScreen = NO;
    }
    return self;
}

// 是否显示状态栏
-(BOOL)prefersStatusBarHidden{
    if (wmPlayer) {
        if (wmPlayer.isFullscreen) {
            return YES;
        }else{
            return NO;
        }
    }else{
        return NO;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // 注册cell
//    [[self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([VideoCell class]) bundle:nil] forCellReuseIdentifier:VideoCellIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:@"VideoCell" bundle:nil] forCellReuseIdentifier:VideoCellIdentifier];
    
    //注册播放完成通知
    [MGNotificationCenter addObserver:self selector:@selector(videoDidFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    //注册播放完成通知
    [MGNotificationCenter addObserver:self selector:@selector(fullScreenBtnClick:) name:WMPlayerFullScreenButtonClickedNotification object:nil];
    //关闭通知
    [MGNotificationCenter addObserver:self selector:@selector(closeTheVideo:) name:WMPlayerClosedNotification object:nil];
    
    [self addMJRefresh];
}

- (void)viewDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [wmPlayer pause];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [MGNotificationCenter removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    
    //旋转屏幕通知
    [MGNotificationCenter addObserver:self selector:@selector(onDeviceOrientationChange) name:UIDeviceOrientationDidChangeNotification object:nil];
}

// 加载数据
-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self performSelector:@selector(loadData) withObject:nil afterDelay:1.0];
    [wmPlayer play];
}
-(void)loadData{
    [_dataSource addObjectsFromArray:[AppDelegate shareAppDelegate].videoArray];
    [self.tableView reloadData];
}

// 刷新操作
-(void)addMJRefresh{
    __weak __typeof(&*self) weakSelf = self;
    
    __unsafe_unretained UITableView *tableView = self.tableView;
    // 下拉刷新
    tableView.mj_header= [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        if ([AppDelegate shareAppDelegate].sidArray.count>2) {
            SidModel *sidModl = [AppDelegate shareAppDelegate].sidArray[2];
            [weakSelf addHudWithMessage:@"加载中..."];
            
            [[DataManager shareManager] getVideoListWithURLString:[NSString stringWithFormat:@"http://c.3g.163.com/nc/video/list/%@/y/0-10.html",sidModl.sid] ListID:sidModl.sid success:^(NSArray *listArray, NSArray *videoArray) {
                self.dataSource =[NSMutableArray arrayWithArray:listArray];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (self.currentIndexPath.row>self.dataSource.count) {
                        [weakSelf releaseWMPlayer];
                    }
                    [tableView reloadData];
                    [weakSelf removeHud];
                    [tableView.mj_header endRefreshing];
                });
            } failed:^(NSError *error) {
                [weakSelf removeHud];
                
                [tableView.mj_header endRefreshing];
            }];
                               
        }
    }];
     
     // 设置自动切换透明度(在导航栏下面自动隐藏)
     tableView.mj_header.automaticallyChangeAlpha = YES;
     // 上拉刷新
     tableView.mj_footer = [MJRefreshBackNormalFooter footerWithRefreshingBlock:^{
        SidModel *sidModl = [AppDelegate shareAppDelegate].sidArray[2];
        [weakSelf addHudWithMessage:@"加载中..."];
        
        NSString *URLString = [NSString stringWithFormat:@"http://c.3g.163.com/nc/video/list/%@/y/%ld-10.html",sidModl.sid,self.dataSource.count - self.dataSource.count%10];
        
        
        
        [[DataManager shareManager] getVideoListWithURLString:URLString ListID:sidModl.sid success:^(NSArray *listArray, NSArray *videoArray) {
            [self.dataSource addObjectsFromArray:listArray];
            dispatch_async(dispatch_get_main_queue(), ^{
                [tableView reloadData];
                [weakSelf removeHud];
                
                [tableView.mj_header endRefreshing];
            });
        } failed:^(NSError *error) {
            [weakSelf removeHud];
            
            [tableView.mj_header endRefreshing];
            
        }];
        // 结束刷新
        [tableView.mj_footer endRefreshing];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - 通知方法
/**
 *  旋转屏幕通知
 */
- (void)onDeviceOrientationChange{
    if (wmPlayer==nil||wmPlayer.superview==nil){
        return;
    }
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    UIInterfaceOrientation interfaceOrientation = (UIInterfaceOrientation)orientation;
    switch (interfaceOrientation) {
        case UIInterfaceOrientationPortraitUpsideDown:{
            NSLog(@"第3个旋转方向---电池栏在下");
        }
            break;
        case UIInterfaceOrientationPortrait:{
            NSLog(@"第0个旋转方向---电池栏在上");
            if (wmPlayer.isFullscreen) {
                if (_isSmallScreen) {
                    //放widow上,小屏显示
                    [self toSmallScreen];
                }else{
                    [self toCell];
                }
            }
        }
            break;
        case UIInterfaceOrientationLandscapeLeft:{
            NSLog(@"第2个旋转方向---电池栏在左");
            if (wmPlayer.isFullscreen == NO) {
                wmPlayer.isFullscreen = YES;
                
                [self setNeedsStatusBarAppearanceUpdate];
                [self toFullScreenWithInterfaceOrientation:interfaceOrientation];
            }
        }
            break;
        case UIInterfaceOrientationLandscapeRight:{
            NSLog(@"第1个旋转方向---电池栏在右");
            if (wmPlayer.isFullscreen == NO) {
                wmPlayer.isFullscreen = YES;
                [self setNeedsStatusBarAppearanceUpdate];
                [self toFullScreenWithInterfaceOrientation:interfaceOrientation];
            }
        }
            break;
        default:
            break;
    }
}

// 取得当前cell
-(void)toCell{
    VideoCell *currentCell = (VideoCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:_currentIndexPath.row inSection:0]];
    [wmPlayer removeFromSuperview];
    NSLog(@"row = %ld",_currentIndexPath.row);
    [UIView animateWithDuration:0.5f animations:^{
        wmPlayer.transform = CGAffineTransformIdentity;
        wmPlayer.frame = currentCell.backgroundIV.bounds;
        wmPlayer.playerLayer.frame =  wmPlayer.bounds;
        [currentCell.backgroundIV addSubview:wmPlayer];
        [currentCell.backgroundIV bringSubviewToFront:wmPlayer];
        [wmPlayer.bottomView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(wmPlayer).with.offset(0);
            make.right.equalTo(wmPlayer).with.offset(0);
            make.height.mas_equalTo(40);
            make.bottom.equalTo(wmPlayer).with.offset(0);
        }];
        
        [wmPlayer.closeBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(wmPlayer).with.offset(5);
            make.height.mas_equalTo(30);
            make.width.mas_equalTo(30);
            make.top.equalTo(wmPlayer).with.offset(5);
        }];
    }completion:^(BOOL finished) {
        wmPlayer.isFullscreen = NO;
        [self setNeedsStatusBarAppearanceUpdate];
        self.isSmallScreen = NO;
        wmPlayer.fullScreenBtn.selected = NO;
        
    }];
    
}

/**
 *  全屏显示
 */
-(void)toFullScreenWithInterfaceOrientation:(UIInterfaceOrientation )interfaceOrientation{
    [wmPlayer removeFromSuperview];
    wmPlayer.transform = CGAffineTransformIdentity;
    if (interfaceOrientation==UIInterfaceOrientationLandscapeLeft) {
        wmPlayer.transform = CGAffineTransformMakeRotation(-M_PI_2);
    }else if(interfaceOrientation==UIInterfaceOrientationLandscapeRight){
        wmPlayer.transform = CGAffineTransformMakeRotation(M_PI_2);
    }
    wmPlayer.frame = CGRectMake(0, 0, kScreenWidth, kScreenHeight);
    wmPlayer.playerLayer.frame =  CGRectMake(0,0, kScreenHeight,kScreenWidth);
    
    [wmPlayer.bottomView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(40);
        make.top.mas_equalTo(kScreenWidth-40);
        make.width.mas_equalTo(kScreenHeight);
    }];
    
    [wmPlayer.closeBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(wmPlayer).with.offset((-kScreenHeight/2));
        make.height.mas_equalTo(30);
        make.width.mas_equalTo(30);
        make.top.equalTo(wmPlayer).with.offset(5);
        
    }];
    
    
    [[UIApplication sharedApplication].keyWindow addSubview:wmPlayer];
    
    wmPlayer.fullScreenBtn.selected = YES;
    [wmPlayer bringSubviewToFront:wmPlayer.bottomView];
    
}

/**
 *  正常显示
 */
-(void)toSmallScreen{
    //放widow上
    [wmPlayer removeFromSuperview];
    [UIView animateWithDuration:0.5f animations:^{
        wmPlayer.transform = CGAffineTransformIdentity;
        wmPlayer.frame = CGRectMake(kScreenWidth/2,kScreenHeight-kTabBarHeight-(kScreenWidth/2)*0.75, kScreenWidth/2, (kScreenWidth/2)*0.75);
        wmPlayer.playerLayer.frame =  wmPlayer.bounds;
        [[UIApplication sharedApplication].keyWindow addSubview:wmPlayer];
        [wmPlayer.bottomView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(wmPlayer).with.offset(0);
            make.right.equalTo(wmPlayer).with.offset(0);
            make.height.mas_equalTo(40);
            make.bottom.equalTo(wmPlayer).with.offset(0);
        }];
        
        [wmPlayer.closeBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(wmPlayer).with.offset(5);
            make.height.mas_equalTo(30);
            make.width.mas_equalTo(30);
            make.top.equalTo(wmPlayer).with.offset(5);
            
        }];
        
    }completion:^(BOOL finished) {
        wmPlayer.isFullscreen = NO;
        [self setNeedsStatusBarAppearanceUpdate];
        wmPlayer.fullScreenBtn.selected = NO;
        self.isSmallScreen = YES;
        [[UIApplication sharedApplication].keyWindow bringSubviewToFront:wmPlayer];
    }];
    
}


-(void)videoDidFinished:(NSNotification *)notice{
    VideoCell *currentCell = (VideoCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.currentIndexPath.row inSection:0]];
    [currentCell.playBtn.superview bringSubviewToFront:currentCell.playBtn];
    [wmPlayer removeFromSuperview];
}

-(void)fullScreenBtnClick:(NSNotification *)notice{
    
}

-(void)closeTheVideo:(NSNotification *)obj{
    VideoCell *currentCell = (VideoCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.currentIndexPath.row inSection:0]];
    [currentCell.playBtn.superview bringSubviewToFront:currentCell.playBtn];
    [self releaseWMPlayer];
    [self setNeedsStatusBarAppearanceUpdate];
}

/**
 *  释放WMPlayer
 */
-(void)releaseWMPlayer{
    [wmPlayer.player.currentItem cancelPendingSeeks];
    [wmPlayer.player.currentItem.asset cancelLoading];
    [wmPlayer pause];
    
    //移除观察者
    [wmPlayer.currentItem removeObserver:wmPlayer forKeyPath:@"status"];
    
    [wmPlayer removeFromSuperview];
    [wmPlayer.playerLayer removeFromSuperlayer];
    [wmPlayer.player replaceCurrentItemWithPlayerItem:nil];
    wmPlayer.player = nil;
    wmPlayer.currentItem = nil;
    //释放定时器，否侧不会调用WMPlayer中的dealloc方法
    [wmPlayer.autoDismissTimer invalidate];
    wmPlayer.autoDismissTimer = nil;
    [wmPlayer.durationTimer invalidate];
    wmPlayer.durationTimer = nil;
    
    
    wmPlayer.playOrPauseBtn = nil;
    wmPlayer.playerLayer = nil;
    wmPlayer = nil;
}


-(void)dealloc{
    NSLog(@"%@ dealloc",[self class]);
    [MGNotificationCenter removeObserver:self];
    
    [self releaseWMPlayer];
}

#pragma mark - UITableViewDataSource
-(NSInteger )numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}
-(NSInteger )tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    VideoCell *cell = (VideoCell *)[tableView dequeueReusableCellWithIdentifier:VideoCellIdentifier];
    cell.model = [self.dataSource objectAtIndex:indexPath.row];
    [cell.playBtn addTarget:self action:@selector(startPlayVideo:) forControlEvents:UIControlEventTouchUpInside];
    cell.playBtn.tag = indexPath.row;
    
    if (wmPlayer&&wmPlayer.superview) {
        if (indexPath.row==self.currentIndexPath.row) {
            [cell.playBtn.superview sendSubviewToBack:cell.playBtn];
        }else{
            [cell.playBtn.superview bringSubviewToFront:cell.playBtn];
        }
        NSArray *indexpaths = [tableView indexPathsForVisibleRows];
        if (![indexpaths containsObject:self.currentIndexPath]&&self.currentIndexPath!=nil) {//复用
            
            if ([[UIApplication sharedApplication].keyWindow.subviews containsObject:wmPlayer]) {
                wmPlayer.hidden = NO;
            }else{
                wmPlayer.hidden = YES;
                [cell.playBtn.superview bringSubviewToFront:cell.playBtn];
            }
        }else{
            if ([cell.backgroundIV.subviews containsObject:wmPlayer]) {
                [cell.backgroundIV addSubview:wmPlayer];
                
                [wmPlayer play];
                wmPlayer.hidden = NO;
            }
            
        }
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate
/**
 *  返回行高
 */
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 274;
}

/**
 *  选中cell,跳转到详情控制器
 */
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    VideoModel *   model = [self.dataSource objectAtIndex:indexPath.row];
    
    MGDetailViewController *detailVC = [[MGDetailViewController alloc]init];
    detailVC.URLString  = model.m3u8_url;
    detailVC.title = model.title;
    
    //    detailVC.URLString = model.mp4_url;
    [self.navigationController pushViewController:detailVC animated:YES];
}


#pragma mark - UIScrollViewDelegate
/**
 *  拖拽tableView
 */
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if(scrollView ==self.tableView){
        if (wmPlayer==nil) {
            return;
        }
        
        if (wmPlayer.superview) {
            CGRect rectInTableView = [self.tableView rectForRowAtIndexPath:_currentIndexPath];
            CGRect rectInSuperview = [self.tableView convertRect:rectInTableView toView:[self.tableView superview]];
            if (rectInSuperview.origin.y<-self.currentCell.backgroundIV.frame.size.height||rectInSuperview.origin.y>kScreenHeight-kNavbarHeight-kTabBarHeight) {//往上拖动
                
                if ([[UIApplication sharedApplication].keyWindow.subviews containsObject:wmPlayer]&&self.isSmallScreen) {
                    self.isSmallScreen = YES;
                }else{
                    //放widow上,小屏显示
                    [self toSmallScreen];
                }
                
            }else{
                if ([self.currentCell.backgroundIV.subviews containsObject:wmPlayer]) {
                    
                }else{
                    [self toCell];
                }
            }
        }
        
    }
}


#pragma mark - 按钮监听操作
-(void)startPlayVideo:(UIButton *)sender{
    _currentIndexPath = [NSIndexPath indexPathForRow:sender.tag inSection:0];
    NSLog(@"currentIndexPath.row = %ld",_currentIndexPath.row);
    if ([UIDevice currentDevice].systemVersion.floatValue>=8||[UIDevice currentDevice].systemVersion.floatValue<7) {
        self.currentCell = (VideoCell *)sender.superview.superview;
    }else{//ios7系统 UITableViewCell上多了一个层级UITableViewCellScrollView
        self.currentCell = (VideoCell *)sender.superview.superview.subviews;
        
    }
    VideoModel *model = [_dataSource objectAtIndex:sender.tag];
    
    //    isSmallScreen = NO;
    if (_isSmallScreen) {
        [self releaseWMPlayer];
        _isSmallScreen = NO;
        
    }
    if (wmPlayer) {
        [wmPlayer removeFromSuperview];
        [wmPlayer.player replaceCurrentItemWithPlayerItem:nil];
        [wmPlayer setVideoURLStr:model.mp4_url];
        [wmPlayer play];
    }else{
        wmPlayer = [[WMPlayer alloc]initWithFrame:self.currentCell.backgroundIV.bounds videoURLStr:model.mp4_url];
        
    }
    [self.currentCell.backgroundIV addSubview:wmPlayer];
    [self.currentCell.backgroundIV bringSubviewToFront:wmPlayer];
    [self.currentCell.playBtn.superview sendSubviewToBack:self.currentCell.playBtn];
    [self.tableView reloadData];
}
     
@end
