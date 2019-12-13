//
//  JKBaseAction.m
//  JKActionManager
//
//  Created by JackLee on 2019/12/13.
//

#import "JKBaseAction.h"
#import "JKActionManager.h"


@implementation JKBaseAction
- (void)start
{
    [JKActionManager addAction:self data:nil];
}

- (void)canel
{
    [JKActionManager removeAction:self];
}

- (void)cleanBlock
{
    
}
@end
