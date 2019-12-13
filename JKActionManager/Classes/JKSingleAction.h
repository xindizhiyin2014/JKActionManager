//
//  JKSingleAction.h
//  JKActionManager
//
//  Created by JackLee on 2019/12/13.
//

#import "JKBaseAction.h"

NS_ASSUME_NONNULL_BEGIN

@interface JKSingleAction : JKBaseAction

@property (nonatomic, copy) void(^actionBlock)(id _Nullable data);
@property (nonatomic, copy, nullable) void(^completeBlock)(__kindof JKSingleAction *tmpAction);

@end

NS_ASSUME_NONNULL_END
