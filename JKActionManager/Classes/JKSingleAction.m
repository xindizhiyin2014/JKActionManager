//
//  JKSingleAction.m
//  JKActionManager
//
//  Created by JackLee on 2019/12/13.
//

#import "JKSingleAction.h"

@implementation JKSingleAction
- (void)cleanBlock
{
    if (self.completeBlock) {
        self.completeBlock = nil;
    }
}
@end
