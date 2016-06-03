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
/** 视频数据源 */
@property (nonatomic,strong) NSMutableArray *dataSource;
/** 视频播放器 */
@property (nonatomic,strong) WMPlayer *wmPlayer;
/** <#注释#> */
@property (nonatomic, assign) NSIndexPath *currentIndexPath;
/** 是否小屏幕 */
@property (nonatomic, assign) BOOL isSmallScreen;
/** 当前的VideoCell */
@property(nonatomic,retain)VideoCell *currentCell;
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

-(BOOL)prefersStatusBarHidden{
    if (self.wmPlayer) {
        if (self.wmPlayer.isFullscreen) {
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
-(void)videoDidFinished:(NSNotification *)notice{
    VideoCell *currentCell = (VideoCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.currentIndexPath.row inSection:0]];
    [currentCell.playBtn.superview bringSubviewToFront:currentCell.playBtn];
    [self.wmPlayer removeFromSuperview];
}

-(void)fullScreenBtnClick:(NSNotification *)notice{
    
}

-(void)closeTheVideo:(NSNotification *)obj{
    VideoCell *currentCell = (VideoCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.currentIndexPath.row inSection:0]];
    [currentCell.playBtn.superview bringSubviewToFront:currentCell.playBtn];
    [self releaseWMPlayer];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
}

/**
 *  释放WMPlayer
 */
-(void)releaseWMPlayer{
    [self.wmPlayer.player.currentItem cancelPendingSeeks];
    [self.wmPlayer.player.currentItem.asset cancelLoading];
    [self.wmPlayer.player pause];
    
    //移除观察者
    [self.wmPlayer.currentItem removeObserver:self.wmPlayer forKeyPath:@"status"];
    
    [self.wmPlayer removeFromSuperview];
    [self.wmPlayer.playerLayer removeFromSuperlayer];
    [self.wmPlayer.player replaceCurrentItemWithPlayerItem:nil];
    self.wmPlayer.player = nil;
    self.wmPlayer.currentItem = nil;
    //释放定时器，否侧不会调用WMPlayer中的dealloc方法
    [self.wmPlayer.autoDismissTimer invalidate];
    self.wmPlayer.autoDismissTimer = nil;
    [self.wmPlayer.durationTimer invalidate];
    self.wmPlayer.durationTimer = nil;
    
    self.wmPlayer.playOrPauseBtn = nil;
    self.wmPlayer.playerLayer = nil;
    self.wmPlayer = nil;
    
    self.currentIndexPath = nil;
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
    
    if (self.wmPlayer&&self.wmPlayer.superview) {
        if (indexPath.row==self.currentIndexPath.row) {
            [cell.playBtn.superview sendSubviewToBack:cell.playBtn];
        }else{
            [cell.playBtn.superview bringSubviewToFront:cell.playBtn];
        }
        NSArray *indexpaths = [tableView indexPathsForVisibleRows];
        if (![indexpaths containsObject:self.currentIndexPath]&&self.currentIndexPath!=nil) {//复用
            
            if ([[UIApplication sharedApplication].keyWindow.subviews containsObject:self.wmPlayer]) {
                self.wmPlayer.hidden = NO;
            }else{
                self.wmPlayer.hidden = YES;
                [cell.playBtn.superview bringSubviewToFront:cell.playBtn];
            }
        }else{
            if ([cell.backgroundIV.subviews containsObject:self.wmPlayer]) {
                [cell.backgroundIV addSubview:self.wmPlayer];
                
                [self.wmPlayer play];
                self.wmPlayer.hidden = NO;
            }
            
        }
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 274;
}


#pragma mark - UITableViewDelegate
/**
 *  拖拽tableView
 */
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if(scrollView == self.tableView){
        if (self.wmPlayer==nil) {
            return;
        }
        
        if (self.wmPlayer.superview) {
            CGRect rectInTableView = [self.tableView rectForRowAtIndexPath:self.currentIndexPath];
            CGRect rectInSuperview = [self.tableView convertRect:rectInTableView toView:[self.tableView superview]];
            NSLog(@"rectInSuperview = %@",NSStringFromCGRect(rectInSuperview));
            
            if (rectInSuperview.origin.y<-self.currentCell.backgroundIV.frame.size.height||rectInSuperview.origin.y>kScreenHeight-kNavbarHeight-kTabBarHeight) {//往上拖动
                [self releaseWMPlayer];
                [self.currentCell.playBtn.superview bringSubviewToFront:self.currentCell.playBtn];
            }
        }
        
    }
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

     
     

#pragma mark - 按钮监听操作
- (void)startPlayVideo:(UIButton *)sender{
    if ([UIDevice currentDevice].systemVersion.floatValue>=8||[UIDevice currentDevice].systemVersion.floatValue<7) {
        self.currentCell = (VideoCell *)sender.superview.superview;
        
    }else{//ios7系统 UITableViewCell上多了一个层级UITableViewCellScrollView
        self.currentCell = (VideoCell *)sender.superview.superview.subviews;
        
    }
    VideoModel *model = [self.dataSource objectAtIndex:sender.tag];
    
    if (self.wmPlayer) {
        [self.wmPlayer removeFromSuperview];
        [self.wmPlayer.player replaceCurrentItemWithPlayerItem:nil];
        [self.wmPlayer setVideoURLStr:model.mp4_url];
        [self.wmPlayer play];
        
    }else{
        self.wmPlayer = [[WMPlayer alloc]initWithFrame:self.currentCell.backgroundIV.bounds videoURLStr:model.mp4_url];
        
    }
    [self.currentCell.backgroundIV addSubview:self.wmPlayer];
    [self.currentCell.backgroundIV bringSubviewToFront:self.wmPlayer];
    [self.currentCell.playBtn.superview sendSubviewToBack:self.currentCell.playBtn];
    [self.tableView reloadData];
}
     
@end
