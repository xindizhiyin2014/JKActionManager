//
//  JKBaseAction.h
//  JKActionManager
//
//  Created by JackLee on 2019/12/13.
//

#import <Foundation/Foundation.h>
#import "JKActionManagerMacro.h"

NS_ASSUME_NONNULL_BEGIN

@interface JKBaseAction : NSObject
@property (nonatomic, assign) JKActionStatus status;
@property (nonatomic, strong, nullable) id result;
@property (nonatomic, strong, nullable) NSError *error;

- (void)start;

- (void)canel;

- (void)cleanBlock;

@end

NS_ASSUME_NONNULL_END
