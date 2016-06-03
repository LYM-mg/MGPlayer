//
//  MGNetEaseViewController.m
//  MGPlayer
//
//  Created by ming on 16/6/3.
//  Copyright © 2016年 ming. All rights reserved.
//

#import "MGNetEaseViewController.h"
#import "SidModel.h"
#import "VideoCell.h"
#import "VideoModel.h"
#import "MGDetailViewController.h"

static NSString *VideoCellIdentifier = @"VideoCell";

@interface MGNetEaseViewController ()<UITableViewDelegate,UITableViewDataSource>
/** 视频数据源 */
@property (nonatomic,strong) NSMutableArray *dataSource;
/** 视频播放器 */
@property (nonatomic,strong) WMPlayer *wmPlayer;
/** 当前索引 */
@property (nonatomic, assign) NSIndexPath *currentIndexPath;

@end

@implementation MGNetEaseViewController
#pragma mark - 系统方法
- (instancetype)init{
    self = [super init];
    if (self) {
        self.dataSource = [NSMutableArray array];
    }
    return self;
}

// 是否显示状态栏
-(BOOL)prefersStatusBarHidden{
    if (_wmPlayer) {
        if (_wmPlayer.isFullscreen) {
            return YES;
        }else{
            return NO;
        }
    }else{
        return NO;
    }
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    //旋转屏幕通知
    [MGNotificationCenter addObserver:self selector:@selector(onDeviceOrientationChange) name:UIDeviceOrientationDidChangeNotification object:nil];
}
-(VideoCell *)currentCell{
    if (_currentIndexPath==nil) {
        return nil;
    }
    VideoCell *currentCell = (VideoCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:_currentIndexPath.row inSection:0]];
    return currentCell;
}
-(void)videoDidFinished:(NSNotification *)notice{
    VideoCell *currentCell = [self currentCell];
    [currentCell.playBtn.superview bringSubviewToFront:currentCell.playBtn];
    [_wmPlayer removeFromSuperview];
    [self setNeedsStatusBarAppearanceUpdate];
    
}
-(void)fullScreenBtnClick:(NSNotification *)notice{
    
}
/**
 *  旋转屏幕通知
 */
- (void)onDeviceOrientationChange{
    
    if (_wmPlayer==nil||_wmPlayer.superview==nil){
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
            if (_wmPlayer.isFullscreen) {
                [self toCell];
            }
        }
            break;
        case UIInterfaceOrientationLandscapeLeft:{
            NSLog(@"第2个旋转方向---电池栏在左");
            if (_wmPlayer.fullScreenBtn.selected == NO) {
                _wmPlayer.isFullscreen = YES;
                
                [self setNeedsStatusBarAppearanceUpdate];
                
                [self toFullScreenWithInterfaceOrientation:interfaceOrientation];
            }
            
        }
            break;
        case UIInterfaceOrientationLandscapeRight:{
            NSLog(@"第1个旋转方向---电池栏在右");
            if (_wmPlayer.fullScreenBtn.selected == NO) {
                _wmPlayer.isFullscreen = YES;
                
                [self setNeedsStatusBarAppearanceUpdate];
                
                [self toFullScreenWithInterfaceOrientation:interfaceOrientation];
            }
            
        }
            break;
        default:
            break;
    }
}

-(void)toCell{
    
    VideoCell *currentCell = (VideoCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:_currentIndexPath.row inSection:0]];
    
    [_wmPlayer removeFromSuperview];
    NSLog(@"row = %ld",_currentIndexPath.row);
    [UIView animateWithDuration:0.5f animations:^{
        _wmPlayer.transform = CGAffineTransformIdentity;
        _wmPlayer.frame = currentCell.backgroundIV.bounds;
        _wmPlayer.playerLayer.frame =  _wmPlayer.bounds;
        [currentCell.backgroundIV addSubview:_wmPlayer];
        [currentCell.backgroundIV bringSubviewToFront:_wmPlayer];
        [_wmPlayer.bottomView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_wmPlayer).with.offset(0);
            make.right.equalTo(_wmPlayer).with.offset(0);
            make.height.mas_equalTo(40);
            make.bottom.equalTo(_wmPlayer).with.offset(0);
            
        }];
        
        [_wmPlayer.closeBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_wmPlayer).with.offset(5);
            make.height.mas_equalTo(30);
            make.width.mas_equalTo(30);
            make.top.equalTo(_wmPlayer).with.offset(5);
        }];
        
        
    }completion:^(BOOL finished) {
        _wmPlayer.isFullscreen = NO;
        
        [self setNeedsStatusBarAppearanceUpdate];
        _wmPlayer.fullScreenBtn.selected = NO;
        
    }];
    
}
-(void)toFullScreenWithInterfaceOrientation:(UIInterfaceOrientation )interfaceOrientation{
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    
    [_wmPlayer removeFromSuperview];
    _wmPlayer.transform = CGAffineTransformIdentity;
    if (interfaceOrientation==UIInterfaceOrientationLandscapeLeft) {
        _wmPlayer.transform = CGAffineTransformMakeRotation(-M_PI_2);
    }else if(interfaceOrientation==UIInterfaceOrientationLandscapeRight){
        _wmPlayer.transform = CGAffineTransformMakeRotation(M_PI_2);
    }
    _wmPlayer.frame = CGRectMake(0, 0, kScreenWidth, kScreenHeight);
    _wmPlayer.playerLayer.frame =  CGRectMake(0,0, kScreenHeight,kScreenWidth);
    
    [_wmPlayer.bottomView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(40);
        make.top.mas_equalTo(kScreenWidth-40);
        make.width.mas_equalTo(kScreenHeight);
    }];
    
    [_wmPlayer.closeBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(_wmPlayer).with.offset((-kScreenHeight/2));
        make.height.mas_equalTo(30);
        make.width.mas_equalTo(30);
        make.top.equalTo(_wmPlayer).with.offset(5);
        
    }];
    
    
    [[UIApplication sharedApplication].keyWindow addSubview:_wmPlayer];
    _wmPlayer.isFullscreen = YES;
    _wmPlayer.fullScreenBtn.selected = YES;
    [_wmPlayer bringSubviewToFront:_wmPlayer.bottomView];
    
}
-(void)closeTheVideo:(NSNotification *)obj{
    VideoCell *currentCell = (VideoCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:_currentIndexPath.row inSection:0]];
    [currentCell.playBtn.superview bringSubviewToFront:currentCell.playBtn];
    [self release_wmPlayer];
    [self setNeedsStatusBarAppearanceUpdate];
    
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self performSelector:@selector(loadData) withObject:nil afterDelay:1.0];
    
}
-(void)loadData{
    [self addHudWithMessage:@"加载中..."];
    SidModel *sidModl = [AppDelegate shareAppDelegate].sidArray[1];
    
    [[DataManager shareManager] getVideoListWithURLString:[NSString stringWithFormat:@"http://c.3g.163.com/nc/video/list/%@/y/0-10.html",sidModl.sid] ListID:sidModl.sid success:^(NSArray *listArray, NSArray *videoArray) {
        _dataSource =[NSMutableArray arrayWithArray:listArray];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self removeHud];
            [self.tableView reloadData];
            
            [self.tableView.mj_header endRefreshing];
        });
    } failed:^(NSError *error) {
        [self removeHud];
        [self.tableView.mj_header endRefreshing];
        
    }];
    
}

#pragma mark - 刷新
-(void)addMJRefresh{
    WS(weakSelf)
    __unsafe_unretained UITableView *tableView = self.tableView;
    // 下拉刷新
    tableView.mj_header= [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        if ([AppDelegate shareAppDelegate].sidArray.count>1) {
            SidModel *sidModl = [AppDelegate shareAppDelegate].sidArray[1];
            [weakSelf addHudWithMessage:@"加载中..."];
            [[DataManager shareManager] getVideoListWithURLString:[NSString stringWithFormat:@"http://c.3g.163.com/nc/video/list/%@/y/0-10.html",sidModl.sid] ListID:sidModl.sid success:^(NSArray *listArray, NSArray *videoArray) {
                _dataSource =[NSMutableArray arrayWithArray:listArray];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (_currentIndexPath.row>_dataSource.count) {
                        [weakSelf release_wmPlayer];
                    }
                    [weakSelf removeHud];
                    [tableView reloadData];
                    [tableView.mj_header endRefreshing];
                });
            } failed:^(NSError *error) {
                [weakSelf.tableView.mj_header endRefreshing];
                [weakSelf removeHud];
            }];
        }else{
            return ;
        }
    }];
    
    // 设置自动切换透明度(在导航栏下面自动隐藏)
    tableView.mj_header.automaticallyChangeAlpha = YES;
    // 上拉刷新
    tableView.mj_footer = [MJRefreshBackNormalFooter footerWithRefreshingBlock:^{
        SidModel *sidModl = [AppDelegate shareAppDelegate].sidArray[1];
        
        NSString *URLString = [NSString stringWithFormat:@"http://c.3g.163.com/nc/video/list/%@/y/%ld-10.html",sidModl.sid,_dataSource.count - _dataSource.count%10];
        [weakSelf addHudWithMessage:@"加载中..."];
        
        [[DataManager shareManager] getVideoListWithURLString:URLString ListID:sidModl.sid success:^(NSArray *listArray, NSArray *videoArray) {
            [_dataSource addObjectsFromArray:listArray];
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf removeHud];
                [tableView reloadData];
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

#pragma mark - UITableViewDataSource
- (NSInteger )numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger )tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *identifier = @"VideoCell";
    VideoCell *cell = (VideoCell *)[tableView dequeueReusableCellWithIdentifier:identifier];
    cell.model = [_dataSource objectAtIndex:indexPath.row];
    [cell.playBtn addTarget:self action:@selector(startPlayVideo:) forControlEvents:UIControlEventTouchUpInside];
    cell.playBtn.tag = indexPath.row;
    
    
    if (_wmPlayer&&_wmPlayer.superview) {
        if (indexPath.row==_currentIndexPath.row) {
            [cell.playBtn.superview sendSubviewToBack:cell.playBtn];
        }else{
            [cell.playBtn.superview bringSubviewToFront:cell.playBtn];
        }
        NSArray *indexpaths = [tableView indexPathsForVisibleRows];
        if (![indexpaths containsObject:_currentIndexPath]) {//复用
            
            if ([[UIApplication sharedApplication].keyWindow.subviews containsObject:_wmPlayer]) {
                _wmPlayer.hidden = NO;
            }else{
                _wmPlayer.hidden = YES;
            }
        }else{
            if ([cell.backgroundIV.subviews containsObject:_wmPlayer]) {
                [cell.backgroundIV addSubview:_wmPlayer];
                
                [_wmPlayer play];
                _wmPlayer.hidden = NO;
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
    VideoModel *   model = [_dataSource objectAtIndex:indexPath.row];
    MGDetailViewController *detailVC = [[MGDetailViewController alloc]init];
    detailVC.URLString  = model.m3u8_url;
    detailVC.title = model.title;
    //    detailVC.URLString = model.mp4_url;
    [self.navigationController pushViewController:detailVC animated:YES];
}

#pragma mark - scrollView delegate
/**
 *  拖拽tableView
 */
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if(scrollView ==self.tableView){
        VideoCell *cell = (VideoCell *)[self.tableView cellForRowAtIndexPath:_currentIndexPath];
        CGRect rectInSuperview = [cell.backgroundIV convertRect:cell.backgroundIV.frame toView:self.view];
        
        if (rectInSuperview.origin.y<-kIOS7DELTA-cell.frame.size.height||rectInSuperview.origin.y>self.tableView.frame.size.height+kIOS7DELTA) {//往上拖动
            
            
        }else{
            
        }
    }
}

/**
 *  释放_wmPlayer
 */
-(void)release_wmPlayer{
    [_wmPlayer.player.currentItem cancelPendingSeeks];
    [_wmPlayer.player.currentItem.asset cancelLoading];
    [_wmPlayer pause];
    
    //移除观察者
    [_wmPlayer.currentItem removeObserver:_wmPlayer forKeyPath:@"status"];
    
    [_wmPlayer removeFromSuperview];
    [_wmPlayer.playerLayer removeFromSuperlayer];
    [_wmPlayer.player replaceCurrentItemWithPlayerItem:nil];
    _wmPlayer.player = nil;
    _wmPlayer.currentItem = nil;
    //释放定时器，否侧不会调用_wmPlayer中的dealloc方法
    [_wmPlayer.autoDismissTimer invalidate];
    _wmPlayer.autoDismissTimer = nil;
    [_wmPlayer.durationTimer invalidate];
    _wmPlayer.durationTimer = nil;
    
    
    _wmPlayer.playOrPauseBtn = nil;
    _wmPlayer.playerLayer = nil;
    _wmPlayer = nil;
    
    _currentIndexPath = nil;
}
-(void)dealloc{
    NSLog(@"%@ dealloc",[self class]);
    [MGNotificationCenter removeObserver:self];
    [self release_wmPlayer];
}

#pragma mark - 开始播放
-(void)startPlayVideo:(UIButton *)sender{
    _currentIndexPath = [NSIndexPath indexPathForRow:sender.tag inSection:0];
    VideoCell *cell =nil;
    if ([UIDevice currentDevice].systemVersion.floatValue>=8||[UIDevice currentDevice].systemVersion.floatValue<7) {
        cell = (VideoCell *)sender.superview.superview;
        
    }else{//ios7系统 UITableViewCell上多了一个层级UITableViewCellScrollView
        cell = (VideoCell *)sender.superview.superview.subviews;
        
    }
    
    
    VideoModel *model = [_dataSource objectAtIndex:sender.tag];
    
    if (_wmPlayer) {
        [_wmPlayer removeFromSuperview];
        [_wmPlayer.player replaceCurrentItemWithPlayerItem:nil];
        [_wmPlayer setVideoURLStr:model.mp4_url];
        [_wmPlayer play];
        
    }else{
        _wmPlayer = [[WMPlayer alloc]initWithFrame:cell.backgroundIV.bounds videoURLStr:model.mp4_url];
        
    }
    [cell.backgroundIV addSubview:_wmPlayer];
    [cell.backgroundIV bringSubviewToFront:_wmPlayer];
    [cell.playBtn.superview sendSubviewToBack:cell.playBtn];
    [self.tableView reloadData];
    
}



@end
