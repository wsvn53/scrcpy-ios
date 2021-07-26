//
//  fix.h
//  libscrcpy
//
//  Created by Ethan on 2021/7/7.
//

#ifndef fix_h
#define fix_h

#import <stdio.h>

#define   kSDLDidCreateRendererNotification   @"kSDLDidCreateRendererNotification"

// reset process_wait status
void process_wait_reset(void);
void process_wait_stop(void);

#endif /* fix_h */
