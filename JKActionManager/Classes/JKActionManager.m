//
//  JKActionManager.m
//  JKActionManager
//
//  Created by JackLee on 2019/12/13.
//

#import "JKActionManager.h"
#import "JKKVOHelper.h"
#import "JKDataHelper.h"
#include <sys/sysctl.h>
#import <mach/mach.h>

#pragma mark - - JKBatchAction category - -

@interface JKBatchAction(JKPrivate)

@property (nonatomic, copy, nullable) void(^afterCompleteBlock)(__kindof JKBatchAction *batchAction, __kindof JKBaseAction * _Nullable failedAction);

@end

@implementation JKBatchAction(JKPrivate)
@dynamic afterCompleteBlock;

@end

#pragma mark - - JKChainAction category - -

@interface JKChainAction(JKPrivate)

@property (nonatomic, copy, nullable) void(^afterCompleteBlock)(__kindof JKChainAction *batchAction, __kindof JKBaseAction * _Nullable failedAction);

@end

@implementation JKChainAction(JKPrivate)
@dynamic afterCompleteBlock;

@end

@interface JKActionManager ()

@property (nonatomic, strong) NSOperationQueue *queue;
@property (nonatomic, strong) NSLock *lock;
@property (nonatomic, strong) NSMutableDictionary <NSString *,__kindof NSOperation *>*operationDic;
@property (nonatomic, strong, readwrite) NSMutableArray <__kindof JKSingleAction *>*actions;
@property (nonatomic, strong, readwrite) NSMutableArray <__kindof JKBatchAction *>*batchActions;
@property (nonatomic, strong, readwrite) NSMutableArray <__kindof JKChainAction *>*chainActions;

@end

@implementation JKActionManager

static JKActionManager *_manager = nil;
+ (instancetype)sharedManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _manager = [[self alloc] init];
    });
    return _manager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _queue = [[NSOperationQueue alloc] init];
        NSUInteger count = [self cpuCoreCount];
        if (count == 0) {
            count = 1;
        }
        _queue.maxConcurrentOperationCount = 3 * count;
        _lock = [NSLock new];
        _operationDic = [NSMutableDictionary new];
        _actions = [NSMutableArray new];
        _batchActions = [NSMutableArray new];
        _chainActions = [NSMutableArray new];
    }
    return self;
}

+ (void)addAction:(__kindof JKBaseAction *)action
             data:(nullable id)data
{
    if (!action) {
#if DEBUG
         NSAssert(NO, @"action can not be nil");
#endif
         return;
    }
    if (action.status != JKActionStatusReady) {
    #if DEBUG
         NSAssert(NO, @"make sure action's status be JKActionStatusReady");
    #endif
         return;
    }
    if ([action isKindOfClass:[JKSingleAction class]]) {
            JKSingleAction *singleAction = (JKSingleAction *)action;
            if (!singleAction.completeBlock) {
                singleAction.completeBlock = ^(__kindof JKSingleAction * _Nonnull tmpAction) {
                    tmpAction.status = JKActionStatusFinish;
                    [self updateOperationPriority];
                };
            }
            [self addJKAction:singleAction data:data];
        } else if ([action isKindOfClass:[JKBatchAction class]]) {
            JKBatchAction *batchAction = (JKBatchAction *)action;
            if (batchAction.actions.count == 0) {
#if DEBUG
                NSAssert(NO, @"batchAction.actions.count must be bigger than zero");
#endif
                return;
            }
            [self addBatchAction:batchAction data:data];
        } else if ([action isKindOfClass:[JKChainAction class]]) {
            JKChainAction *chainAction = (JKChainAction *)action;
            if (chainAction.actions.count == 0) {
#if DEBUG
                NSAssert(NO, @"chainAction.actions.count must be bigger than zero");
#endif
                return;
            }
            [self addChainAction:chainAction data:data];
        } else {
    #if DEBUG
            NSAssert(NO, @"no support this kind of action");
    #endif
            return;
        }
}

+ (void)removeAction:(__kindof JKBaseAction *)action
{
    if ([action isKindOfClass:[JKSingleAction class]]) {
        [self removeJKAction:action];
    } else if ([action isKindOfClass:[JKBatchAction class]]) {
        [self removeBatchAction:action];
    } else if ([action isKindOfClass:[JKChainAction class]]) {
        [self removeChainAction:action];
    } else {
    #if DEBUG
            NSAssert(NO, @"no support this kind of action");
    #endif
        return;
    }
}

+ (void)removeAllActions
{
    [[JKActionManager sharedManager].lock lock];
    NSArray *actions = [[JKActionManager sharedManager].actions copy];
    [[JKActionManager sharedManager].batchActions removeAllObjects];
    [[JKActionManager sharedManager].chainActions removeAllObjects];
    [[JKActionManager sharedManager].lock unlock];
    
    for (__kindof JKSingleAction *action in actions) {
        [self removeAction:action];
    }
}

+ (void)addJKAction:(JKSingleAction *)action
               data:(nullable id)data
{
    [[JKActionManager sharedManager].lock lock];
    NSOperationQueue *queue = [JKActionManager sharedManager].queue;
    NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        if(action.actionBlock){
            action.actionBlock(data);
        }
    }];
    
   if ([self isVeryCriticalCodition]){
        operation.queuePriority = NSOperationQueuePriorityVeryLow;
    } else if ([self isCriticalCodition]) {
       operation.queuePriority = NSOperationQueuePriorityLow;
    } else {
        operation.queuePriority = NSOperationQueuePriorityNormal;
    }
    [self observeOperation:operation action:action];
    NSString *key = [NSString stringWithFormat:@"%p",action];
    [[JKActionManager sharedManager].operationDic setValue:operation forKey:key];
    [[JKActionManager sharedManager].actions addObject:action];
    [queue addOperation:operation];
    [[JKActionManager sharedManager].lock unlock];
}

+ (void)addBatchAction:(JKBatchAction *)batchAction
                  data:(nullable id)data
{
   [[JKActionManager sharedManager].batchActions addObject:batchAction];
   __block NSInteger successCount = 0;
   for (__kindof JKBaseAction *tmpAction in batchAction.actions) {
       if ([tmpAction isKindOfClass:[JKSingleAction class]]) {
           JKSingleAction *action = (JKSingleAction *)tmpAction;
           action.completeBlock = ^(__kindof JKSingleAction *tmpAction) {
               tmpAction.status = JKActionStatusFinish;
               [self updateOperationPriority];
               if (!tmpAction.error) {
                   successCount++;
                   if (successCount == batchAction.actions.count) {
                       [self batchActionComplete:batchAction failedAction:nil];
                   }
               } else {
                   [self batchActionComplete:batchAction failedAction:tmpAction];
               }
           };
       } else if ([tmpAction isKindOfClass:[JKChainAction class]]) {
           JKChainAction *chainAction = (JKChainAction *)tmpAction;
           chainAction.afterCompleteBlock = ^(__kindof JKChainAction * _Nonnull chainAction, __kindof JKBaseAction * _Nullable failedAction) {
               [self updateOperationPriority];
               if (!failedAction) {
                   successCount++;
                   if (successCount == batchAction.actions.count) {
                       [self batchActionComplete:batchAction failedAction:nil];
                   }

               } else {
                   [self batchActionComplete:batchAction failedAction:failedAction];
               }
           };
       }
       [self addAction:tmpAction data:data];
   }
}

+ (void)addChainAction:(JKChainAction *)chainAction
                  data:(nullable id)data
{
   [[JKActionManager sharedManager].chainActions addObject:chainAction];
   [self startActionInChainAction:chainAction successCount:0 data:data];
}

+ (void)removeJKAction:(JKSingleAction *)action
{
    [[JKActionManager sharedManager].lock lock];
    NSString *key = [NSString stringWithFormat:@"%p",action];
    NSBlockOperation *operaion = [[JKActionManager sharedManager].operationDic objectForKey:key];
    [operaion cancel];
    [[JKActionManager sharedManager].operationDic removeObjectForKey:key];
    [[JKActionManager sharedManager].actions removeObject:action];
    [[JKActionManager sharedManager].lock unlock];
}

+ (void)removeBatchAction:(JKBatchAction *)batchAction
{
    [[JKActionManager sharedManager].lock lock];
    NSArray *actions = [batchAction.actions copy];
    [[JKActionManager sharedManager].batchActions removeObject:batchAction];
    [[JKActionManager sharedManager].lock unlock];

    for (__kindof JKBaseAction *action in actions) {
        if ([action isKindOfClass:[JKSingleAction class]]) {
            [self removeJKAction:action];
        } else if ([action isKindOfClass:[JKChainAction class]]) {
            [self removeChainAction:action];
        }
    }
}

+ (void)removeChainAction:(JKChainAction *)chainAction
{
    [[JKActionManager sharedManager].lock lock];
    NSArray *actions = [chainAction.actions copy];
    [[JKActionManager sharedManager].chainActions removeObject:chainAction];
    [[JKActionManager sharedManager].lock unlock];
    
    for (__kindof JKBaseAction *action in actions) {
        if ([action isKindOfClass:[JKSingleAction class]]) {
            [self removeJKAction:action];
        } else if ([action isKindOfClass:[JKBatchAction class]]) {
            [self removeBatchAction:action];
        }
    }
}

#pragma mark - - private - -

+ (BOOL)isCriticalCodition
{
    float cpuUsage = [self cpuUsage];
    return cpuUsage >= 0.35;
}

+ (BOOL)isVeryCriticalCodition
{
    float cpuUsage = [self cpuUsage];
    return cpuUsage >= 0.5;
}

+ (BOOL)isRecoverConditiion
{
    float cpuUsage = [self cpuUsage];
    return cpuUsage <= 0.2;
}

+ (void)observeOperation:(NSBlockOperation *)operation
                  action:(__kindof JKSingleAction *)action
{
    [operation jk_addObserver:operation
                  forKeyPaths:@[@"cancelled",@"executing"]
                      options:NSKeyValueObservingOptionNew context:nil
              withDetailBlock:^(NSString * _Nonnull keyPath, NSDictionary * _Nonnull change, void * _Nonnull context) {
        if ([keyPath isEqualToString:@"executing"]) {
            BOOL executing = [change jk_boolForKey:@"new"];
            if (executing) {
                action.status = JKActionStatusExecuting;
            }
        } else if ([keyPath isEqualToString:@"cancelled"]) {
            BOOL cancelled = [change jk_boolForKey:@"new"];
            if (cancelled) {
                action.status = JKActionStatusCancel;
            }
        }
    }];
}

+ (void)batchActionComplete:(__kindof JKBatchAction *)batchAction
               failedAction:(nullable __kindof JKBaseAction *)faileAction
{
    batchAction.status = JKActionStatusFinish;
    if (batchAction.completeBlock) {
        batchAction.completeBlock(batchAction, faileAction);
    }
    if (batchAction.afterCompleteBlock) {
        batchAction.afterCompleteBlock(batchAction, faileAction);
    }
}

+ (void)chainActionComplete:(__kindof JKChainAction *)chainAction
               failedAction:(nullable __kindof JKBaseAction *)faileAction
{
    chainAction.status = JKActionStatusFinish;
    if (chainAction.completeBlock) {
        chainAction.completeBlock(chainAction, nil);
    }
    if (chainAction.afterCompleteBlock) {
        chainAction.afterCompleteBlock(chainAction, nil);
    }
}

+ (NSUInteger)startActionInChainAction:(__kindof JKChainAction *)chainAction
                          successCount:(NSUInteger)lastSuccessCount
                                  data:(nullable id)data
{
    __block NSInteger successCount = lastSuccessCount;
    __kindof JKBaseAction *baseAction = (__kindof JKBaseAction *)[chainAction.actions jk_objectWithIndex:successCount];
    if (baseAction) {
        if ([baseAction isKindOfClass:[JKSingleAction class]]) {
            JKSingleAction *action = (JKSingleAction *)baseAction;
            action.completeBlock = ^(__kindof JKSingleAction * _Nonnull tmpAction) {
                tmpAction.status = JKActionStatusFinish;
                [self updateOperationPriority];
                if (!tmpAction.error) {
                    successCount++;
                    if (successCount < chainAction.actions.count) {
                        successCount = [self startActionInChainAction:chainAction successCount:successCount data:tmpAction.result];
                    } else {
                        [self chainActionComplete:chainAction failedAction:nil];
                    }
                } else {
                   [self chainActionComplete:chainAction failedAction:tmpAction];
                }
            };
        } else if ([baseAction isKindOfClass:[JKBatchAction class]]) {
            JKBatchAction *batchAction = (JKBatchAction *)baseAction;
            batchAction.afterCompleteBlock = ^(__kindof JKBatchAction * _Nonnull batchAction, __kindof JKBaseAction * _Nullable failedAction) {
                [self updateOperationPriority];
                if (!failedAction) {
                    successCount++;
                    if (successCount < chainAction.actions.count) {
                        [self batchActionComplete:batchAction failedAction:nil];
                        successCount = [self startActionInChainAction:chainAction successCount:successCount data:batchAction.result];
                    } else {
                        [self chainActionComplete:chainAction failedAction:nil];
                    }
                } else {
                   [self chainActionComplete:chainAction failedAction:failedAction];
                }
            };
        }
        [self addAction:baseAction data:data];
    }
    return successCount;
}

+ (void)updateOperationPriority
{
    if ([self isRecoverConditiion]) {
        [self updateOperationPriorityWithQueueOperations:[JKActionManager sharedManager].queue.operations];
    }
}

+ (void)updateOperationPriorityWithQueueOperations:(NSArray *)operations
{
    for (__kindof NSOperation *operation in operations) {
        if (operation.queuePriority < NSOperationQueuePriorityNormal && operation.ready) {
          operation.queuePriority = NSOperationQueuePriorityNormal;
        }
    }
}


/// the cpu core count
- (NSUInteger)cpuCoreCount
{
    unsigned int ncpu;
    size_t len = sizeof(ncpu);
    sysctlbyname("hw.ncpu", &ncpu, &len, NULL, 0);
    return ncpu;
}


/// the usage of the cpu
+ (float)cpuUsage
{
    kern_return_t kr;
       task_info_data_t tinfo;
       mach_msg_type_number_t task_info_count;

       task_info_count = TASK_INFO_MAX;
       kr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)tinfo, &task_info_count);
       if (kr != KERN_SUCCESS) {
           return -1;
       }

       task_basic_info_t      basic_info;
       thread_array_t         thread_list;
       mach_msg_type_number_t thread_count;

       thread_info_data_t     thinfo;
       mach_msg_type_number_t thread_info_count;

       thread_basic_info_t basic_info_th;
       uint32_t stat_thread = 0; // Mach threads

       basic_info = (task_basic_info_t)tinfo;

       // get threads in the task
      kr = task_threads(mach_task_self(), &thread_list, &thread_count);
       if (kr != KERN_SUCCESS) {
           return -1;
       }
       if (thread_count > 0)
           stat_thread += thread_count;

       long tot_sec = 0;
       long tot_usec = 0;
       float tot_cpu = 0;
       int j;

       for (j = 0; j < thread_count; j++)
       {
           thread_info_count = THREAD_INFO_MAX;
           kr = thread_info(thread_list[j], THREAD_BASIC_INFO,
                            (thread_info_t)thinfo, &thread_info_count);
           if (kr != KERN_SUCCESS) {
               return -1;
           }

           basic_info_th = (thread_basic_info_t)thinfo;

           if (!(basic_info_th->flags & TH_FLAGS_IDLE)) {
               tot_sec = tot_sec + basic_info_th->user_time.seconds + basic_info_th->system_time.seconds;
               tot_usec = tot_usec + basic_info_th->user_time.microseconds + basic_info_th->system_time.microseconds;
               tot_cpu = tot_cpu + basic_info_th->cpu_usage / (float)TH_USAGE_SCALE * 100.0;
           }

       } // for each thread

       kr = vm_deallocate(mach_task_self(), (vm_offset_t)thread_list, thread_count * sizeof(thread_t));
       assert(kr == KERN_SUCCESS);

       return tot_cpu / 100;
}
@end
