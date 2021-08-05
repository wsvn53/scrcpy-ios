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

void reset_PeepEvents (void);
void stop_PeepEvents (void);

// remvoe all render layers
void fix_remove_opengl_layers(void);

#endif /* fix_h */
