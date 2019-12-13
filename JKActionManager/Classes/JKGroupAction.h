//
//  JKGroupAction.h
//  JKActionManager
//
//  Created by JackLee on 2019/12/13.
//

#import "JKBaseAction.h"

NS_ASSUME_NONNULL_BEGIN

@interface JKBatchAction : JKBaseAction

@property (nonatomic, strong, readonly) NSMutableArray <__kindof JKBaseAction *>*actions;

@property (nonatomic, copy, nullable) void(^completeBlock)(__kindof JKBatchAction *batchAction, __kindof JKBaseAction * _Nullable failedAction);


+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)initWithArray:(NSArray <__kindof JKBaseAction *>*)array;

- (void)addAction:(__kindof JKBaseAction *)action;

@end

@interface JKChainAction : JKBaseAction

@property (nonatomic, strong, readonly) NSMutableArray *actions;

@property (nonatomic, copy, nullable) void(^completeBlock)(__kindof JKChainAction *chainAction, __kindof JKBaseAction * _Nullable failedAction);


+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)initWithArray:(NSArray <__kindof JKBaseAction *>*)array;

- (void)addAction:(__kindof JKBaseAction *)action;

@end

NS_ASSUME_NONNULL_END
