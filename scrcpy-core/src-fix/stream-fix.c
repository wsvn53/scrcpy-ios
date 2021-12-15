//
//  stream-fix.c
//  scrcpy-core
//
//  Created by Ethan on 2021/12/11.
//

#include "ffmpeg-hw.h"

#define stream_join(...)     stream_join_orig(__VA_ARGS__)

#include "stream.c"

#undef stream_join

/**
 * Handle stream_join to close net socket before wait stream thread exit
 */
void
stream_join(struct stream *stream) {
    LOGD("Closing stream socket.");
    net_close(stream->socket);
    stream_join_orig(stream);
}
