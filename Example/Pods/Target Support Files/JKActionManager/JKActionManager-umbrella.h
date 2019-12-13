#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "JKActionManager.h"
#import "JKActionManagerMacro.h"
#import "JKBaseAction.h"
#import "JKGroupAction.h"
#import "JKSingleAction.h"

FOUNDATION_EXPORT double JKActionManagerVersionNumber;
FOUNDATION_EXPORT const unsigned char JKActionManagerVersionString[];

