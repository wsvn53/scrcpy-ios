//
//  libusb.h - Dummy libusb header used for compile scrcpy
//  Scrcpy
//
//  Created by Ethan on 2021/12/1.
//

 /*
  * Public libusb header file
  * Copyright © 2001 Johannes Erdfelt <johannes@erdfelt.com>
  * Copyright © 2007-2008 Daniel Drake <dsd@gentoo.org>
  * Copyright © 2012 Pete Batard <pete@akeo.ie>
  * Copyright © 2012-2018 Nathan Hjelm <hjelmn@cs.unm.edu>
  * Copyright © 2014-2020 Chris Dickens <christopher.a.dickens@gmail.com>
  * For more information, please visit: http://libusb.info
  *
  * This library is free software; you can redistribute it and/or
  * modify it under the terms of the GNU Lesser General Public
  * License as published by the Free Software Foundation; either
  * version 2.1 of the License, or (at your option) any later version.
  *
  * This library is distributed in the hope that it will be useful,
  * but WITHOUT ANY WARRANTY; without even the implied warranty of
  * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  * Lesser General Public License for more details.
  *
  * You should have received a copy of the GNU Lesser General Public
  * License along with this library; if not, write to the Free Software
  * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
  */
  
 #ifndef LIBUSB_H
 #define LIBUSB_H
  
 #if defined(_MSC_VER)
 /* on MS environments, the inline keyword is available in C++ only */
 #if !defined(__cplusplus)
 #define inline __inline
 #endif
 /* ssize_t is also not available */
 #include <basetsd.h>
 typedef SSIZE_T ssize_t;
 #endif /* _MSC_VER */
  
 #include <limits.h>
 #include <stdint.h>
 #include <sys/types.h>
 #if !defined(_MSC_VER)
 #include <sys/time.h>
 #endif
 #include <time.h>
  
 #if defined(__STDC_VERSION__) && (__STDC_VERSION__ >= 199901L)
 #define ZERO_SIZED_ARRAY        /* [] - valid C99 code */
 #else
 #define ZERO_SIZED_ARRAY    0   /* [0] - non-standard, but usually working code */
 #endif /* __STDC_VERSION__ */
  
 /* 'interface' might be defined as a macro on Windows, so we need to
  * undefine it so as not to break the current libusb API, because
  * libusb_config_descriptor has an 'interface' member
  * As this can be problematic if you include windows.h after libusb.h
  * in your sources, we force windows.h to be included first. */
 #if defined(_WIN32) || defined(__CYGWIN__)
 #include <windows.h>
 #if defined(interface)
 #undef interface
 #endif
 #if !defined(__CYGWIN__)
 #include <winsock.h>
 #endif
 #endif /* _WIN32 || __CYGWIN__ */
  
 #if defined(__GNUC__) && (__GNUC__ > 4 || (__GNUC__ == 4 && __GNUC_MINOR__ >= 5))
 #define LIBUSB_DEPRECATED_FOR(f) __attribute__ ((deprecated ("Use " #f " instead")))
 #elif defined(__GNUC__) && (__GNUC__ >= 3)
 #define LIBUSB_DEPRECATED_FOR(f) __attribute__ ((deprecated))
 #else
 #define LIBUSB_DEPRECATED_FOR(f)
 #endif /* __GNUC__ */
  
 #if defined(__GNUC__)
 #define LIBUSB_PACKED __attribute__ ((packed))
 #else
 #define LIBUSB_PACKED
 #endif /* __GNUC__ */
  
 /* LIBUSB_CALL must be defined on both definition and declaration of libusb
  * functions. You'd think that declaration would be enough, but cygwin will
  * complain about conflicting types unless both are marked this way.
  * The placement of this macro is important too; it must appear after the
  * return type, before the function name. See internal documentation for
  * API_EXPORTED.
  */
 #if defined(_WIN32) || defined(__CYGWIN__)
 #define LIBUSB_CALL WINAPI
 #else
 #define LIBUSB_CALL
 #endif /* _WIN32 || __CYGWIN__ */
  
 #define LIBUSB_API_VERSION 0x01000108
  
 /* The following is kept for compatibility, but will be deprecated in the future */
 #define LIBUSBX_API_VERSION LIBUSB_API_VERSION
  
 #if defined(__cplusplus)
 extern "C" {
 #endif
  
 static inline uint16_t libusb_cpu_to_le16(const uint16_t x)
 {
     union {
         uint8_t  b8[2];
         uint16_t b16;
     } _tmp;
     _tmp.b8[1] = (uint8_t) (x >> 8);
     _tmp.b8[0] = (uint8_t) (x & 0xff);
     return _tmp.b16;
 }
  
 #define libusb_le16_to_cpu libusb_cpu_to_le16
  
 /* standard USB stuff */
  
 enum libusb_class_code {
     LIBUSB_CLASS_PER_INTERFACE = 0x00,
  
     LIBUSB_CLASS_AUDIO = 0x01,
  
     LIBUSB_CLASS_COMM = 0x02,
  
     LIBUSB_CLASS_HID = 0x03,
  
     LIBUSB_CLASS_PHYSICAL = 0x05,
  
     LIBUSB_CLASS_IMAGE = 0x06,
     LIBUSB_CLASS_PTP = 0x06, /* legacy name from libusb-0.1 usb.h */
  
     LIBUSB_CLASS_PRINTER = 0x07,
  
     LIBUSB_CLASS_MASS_STORAGE = 0x08,
  
     LIBUSB_CLASS_HUB = 0x09,
  
     LIBUSB_CLASS_DATA = 0x0a,
  
     LIBUSB_CLASS_SMART_CARD = 0x0b,
  
     LIBUSB_CLASS_CONTENT_SECURITY = 0x0d,
  
     LIBUSB_CLASS_VIDEO = 0x0e,
  
     LIBUSB_CLASS_PERSONAL_HEALTHCARE = 0x0f,
  
     LIBUSB_CLASS_DIAGNOSTIC_DEVICE = 0xdc,
  
     LIBUSB_CLASS_WIRELESS = 0xe0,
  
     LIBUSB_CLASS_MISCELLANEOUS = 0xef,
  
     LIBUSB_CLASS_APPLICATION = 0xfe,
  
     LIBUSB_CLASS_VENDOR_SPEC = 0xff
 };
  
 enum libusb_descriptor_type {
     LIBUSB_DT_DEVICE = 0x01,
  
     LIBUSB_DT_CONFIG = 0x02,
  
     LIBUSB_DT_STRING = 0x03,
  
     LIBUSB_DT_INTERFACE = 0x04,
  
     LIBUSB_DT_ENDPOINT = 0x05,
  
     LIBUSB_DT_BOS = 0x0f,
  
     LIBUSB_DT_DEVICE_CAPABILITY = 0x10,
  
     LIBUSB_DT_HID = 0x21,
  
     LIBUSB_DT_REPORT = 0x22,
  
     LIBUSB_DT_PHYSICAL = 0x23,
  
     LIBUSB_DT_HUB = 0x29,
  
     LIBUSB_DT_SUPERSPEED_HUB = 0x2a,
  
     LIBUSB_DT_SS_ENDPOINT_COMPANION = 0x30
 };
  
 /* Descriptor sizes per descriptor type */
 #define LIBUSB_DT_DEVICE_SIZE           18
 #define LIBUSB_DT_CONFIG_SIZE           9
 #define LIBUSB_DT_INTERFACE_SIZE        9
 #define LIBUSB_DT_ENDPOINT_SIZE         7
 #define LIBUSB_DT_ENDPOINT_AUDIO_SIZE       9   /* Audio extension */
 #define LIBUSB_DT_HUB_NONVAR_SIZE       7
 #define LIBUSB_DT_SS_ENDPOINT_COMPANION_SIZE    6
 #define LIBUSB_DT_BOS_SIZE          5
 #define LIBUSB_DT_DEVICE_CAPABILITY_SIZE    3
  
 /* BOS descriptor sizes */
 #define LIBUSB_BT_USB_2_0_EXTENSION_SIZE    7
 #define LIBUSB_BT_SS_USB_DEVICE_CAPABILITY_SIZE 10
 #define LIBUSB_BT_CONTAINER_ID_SIZE     20
  
 /* We unwrap the BOS => define its max size */
 #define LIBUSB_DT_BOS_MAX_SIZE              \
     (LIBUSB_DT_BOS_SIZE +               \
      LIBUSB_BT_USB_2_0_EXTENSION_SIZE +     \
      LIBUSB_BT_SS_USB_DEVICE_CAPABILITY_SIZE +  \
      LIBUSB_BT_CONTAINER_ID_SIZE)
  
 #define LIBUSB_ENDPOINT_ADDRESS_MASK        0x0f    /* in bEndpointAddress */
 #define LIBUSB_ENDPOINT_DIR_MASK        0x80
  
 enum libusb_endpoint_direction {
     LIBUSB_ENDPOINT_OUT = 0x00,
  
     LIBUSB_ENDPOINT_IN = 0x80
 };
  
 #define LIBUSB_TRANSFER_TYPE_MASK       0x03    /* in bmAttributes */
  
 enum libusb_endpoint_transfer_type {
     LIBUSB_ENDPOINT_TRANSFER_TYPE_CONTROL = 0x0,
  
     LIBUSB_ENDPOINT_TRANSFER_TYPE_ISOCHRONOUS = 0x1,
  
     LIBUSB_ENDPOINT_TRANSFER_TYPE_BULK = 0x2,
  
     LIBUSB_ENDPOINT_TRANSFER_TYPE_INTERRUPT = 0x3
 };
  
 enum libusb_standard_request {
     LIBUSB_REQUEST_GET_STATUS = 0x00,
  
     LIBUSB_REQUEST_CLEAR_FEATURE = 0x01,
  
     /* 0x02 is reserved */
  
     LIBUSB_REQUEST_SET_FEATURE = 0x03,
  
     /* 0x04 is reserved */
  
     LIBUSB_REQUEST_SET_ADDRESS = 0x05,
  
     LIBUSB_REQUEST_GET_DESCRIPTOR = 0x06,
  
     LIBUSB_REQUEST_SET_DESCRIPTOR = 0x07,
  
     LIBUSB_REQUEST_GET_CONFIGURATION = 0x08,
  
     LIBUSB_REQUEST_SET_CONFIGURATION = 0x09,
  
     LIBUSB_REQUEST_GET_INTERFACE = 0x0a,
  
     LIBUSB_REQUEST_SET_INTERFACE = 0x0b,
  
     LIBUSB_REQUEST_SYNCH_FRAME = 0x0c,
  
     LIBUSB_REQUEST_SET_SEL = 0x30,
  
     LIBUSB_SET_ISOCH_DELAY = 0x31
 };
  
 enum libusb_request_type {
     LIBUSB_REQUEST_TYPE_STANDARD = (0x00 << 5),
  
     LIBUSB_REQUEST_TYPE_CLASS = (0x01 << 5),
  
     LIBUSB_REQUEST_TYPE_VENDOR = (0x02 << 5),
  
     LIBUSB_REQUEST_TYPE_RESERVED = (0x03 << 5)
 };
  
 enum libusb_request_recipient {
     LIBUSB_RECIPIENT_DEVICE = 0x00,
  
     LIBUSB_RECIPIENT_INTERFACE = 0x01,
  
     LIBUSB_RECIPIENT_ENDPOINT = 0x02,
  
     LIBUSB_RECIPIENT_OTHER = 0x03
 };
  
 #define LIBUSB_ISO_SYNC_TYPE_MASK   0x0c
  
 enum libusb_iso_sync_type {
     LIBUSB_ISO_SYNC_TYPE_NONE = 0x0,
  
     LIBUSB_ISO_SYNC_TYPE_ASYNC = 0x1,
  
     LIBUSB_ISO_SYNC_TYPE_ADAPTIVE = 0x2,
  
     LIBUSB_ISO_SYNC_TYPE_SYNC = 0x3
 };
  
 #define LIBUSB_ISO_USAGE_TYPE_MASK  0x30
  
 enum libusb_iso_usage_type {
     LIBUSB_ISO_USAGE_TYPE_DATA = 0x0,
  
     LIBUSB_ISO_USAGE_TYPE_FEEDBACK = 0x1,
  
     LIBUSB_ISO_USAGE_TYPE_IMPLICIT = 0x2
 };
  
 enum libusb_supported_speed {
     LIBUSB_LOW_SPEED_OPERATION = (1 << 0),
  
     LIBUSB_FULL_SPEED_OPERATION = (1 << 1),
  
     LIBUSB_HIGH_SPEED_OPERATION = (1 << 2),
  
     LIBUSB_SUPER_SPEED_OPERATION = (1 << 3)
 };
  
 enum libusb_usb_2_0_extension_attributes {
     LIBUSB_BM_LPM_SUPPORT = (1 << 1)
 };
  
 enum libusb_ss_usb_device_capability_attributes {
     LIBUSB_BM_LTM_SUPPORT = (1 << 1)
 };
  
 enum libusb_bos_type {
     LIBUSB_BT_WIRELESS_USB_DEVICE_CAPABILITY = 0x01,
  
     LIBUSB_BT_USB_2_0_EXTENSION = 0x02,
  
     LIBUSB_BT_SS_USB_DEVICE_CAPABILITY = 0x03,
  
     LIBUSB_BT_CONTAINER_ID = 0x04
 };
  
 struct libusb_device_descriptor {
     uint8_t  bLength;
  
     uint8_t  bDescriptorType;
  
     uint16_t bcdUSB;
  
     uint8_t  bDeviceClass;
  
     uint8_t  bDeviceSubClass;
  
     uint8_t  bDeviceProtocol;
  
     uint8_t  bMaxPacketSize0;
  
     uint16_t idVendor;
  
     uint16_t idProduct;
  
     uint16_t bcdDevice;
  
     uint8_t  iManufacturer;
  
     uint8_t  iProduct;
  
     uint8_t  iSerialNumber;
  
     uint8_t  bNumConfigurations;
 };
  
 struct libusb_endpoint_descriptor {
     uint8_t  bLength;
  
     uint8_t  bDescriptorType;
  
     uint8_t  bEndpointAddress;
  
     uint8_t  bmAttributes;
  
     uint16_t wMaxPacketSize;
  
     uint8_t  bInterval;
  
     uint8_t  bRefresh;
  
     uint8_t  bSynchAddress;
  
     const unsigned char *extra;
  
     int extra_length;
 };
  
 struct libusb_interface_descriptor {
     uint8_t  bLength;
  
     uint8_t  bDescriptorType;
  
     uint8_t  bInterfaceNumber;
  
     uint8_t  bAlternateSetting;
  
     uint8_t  bNumEndpoints;
  
     uint8_t  bInterfaceClass;
  
     uint8_t  bInterfaceSubClass;
  
     uint8_t  bInterfaceProtocol;
  
     uint8_t  iInterface;
  
     const struct libusb_endpoint_descriptor *endpoint;
  
     const unsigned char *extra;
  
     int extra_length;
 };
  
 struct libusb_interface {
     const struct libusb_interface_descriptor *altsetting;
  
     int num_altsetting;
 };
  
 struct libusb_config_descriptor {
     uint8_t  bLength;
  
     uint8_t  bDescriptorType;
  
     uint16_t wTotalLength;
  
     uint8_t  bNumInterfaces;
  
     uint8_t  bConfigurationValue;
  
     uint8_t  iConfiguration;
  
     uint8_t  bmAttributes;
  
     uint8_t  MaxPower;
  
     const struct libusb_interface *interface;
  
     const unsigned char *extra;
  
     int extra_length;
 };
  
 struct libusb_ss_endpoint_companion_descriptor {
     uint8_t  bLength;
  
     uint8_t  bDescriptorType;
  
     uint8_t  bMaxBurst;
  
     uint8_t  bmAttributes;
  
     uint16_t wBytesPerInterval;
 };
  
 struct libusb_bos_dev_capability_descriptor {
     uint8_t  bLength;
  
     uint8_t  bDescriptorType;
  
     uint8_t  bDevCapabilityType;
  
     uint8_t  dev_capability_data[ZERO_SIZED_ARRAY];
 };
  
 struct libusb_bos_descriptor {
     uint8_t  bLength;
  
     uint8_t  bDescriptorType;
  
     uint16_t wTotalLength;
  
     uint8_t  bNumDeviceCaps;
  
     struct libusb_bos_dev_capability_descriptor *dev_capability[ZERO_SIZED_ARRAY];
 };
  
 struct libusb_usb_2_0_extension_descriptor {
     uint8_t  bLength;
  
     uint8_t  bDescriptorType;
  
     uint8_t  bDevCapabilityType;
  
     uint32_t bmAttributes;
 };
  
 struct libusb_ss_usb_device_capability_descriptor {
     uint8_t  bLength;
  
     uint8_t  bDescriptorType;
  
     uint8_t  bDevCapabilityType;
  
     uint8_t  bmAttributes;
  
     uint16_t wSpeedSupported;
  
     uint8_t  bFunctionalitySupport;
  
     uint8_t  bU1DevExitLat;
  
     uint16_t bU2DevExitLat;
 };
  
 struct libusb_container_id_descriptor {
     uint8_t  bLength;
  
     uint8_t  bDescriptorType;
  
     uint8_t  bDevCapabilityType;
  
     uint8_t  bReserved;
  
     uint8_t  ContainerID[16];
 };
  
 #if defined(_MSC_VER)
 #pragma pack(push, 1)
 #endif
 struct libusb_control_setup {
     uint8_t  bmRequestType;
  
     uint8_t  bRequest;
  
     uint16_t wValue;
  
     uint16_t wIndex;
  
     uint16_t wLength;
 } LIBUSB_PACKED;
 #if defined(_MSC_VER)
 #pragma pack(pop)
 #endif
  
 #define LIBUSB_CONTROL_SETUP_SIZE (sizeof(struct libusb_control_setup))
  
 /* libusb */
  
 struct libusb_context;
 struct libusb_device;
 struct libusb_device_handle;
  
 struct libusb_version {
     const uint16_t major;
  
     const uint16_t minor;
  
     const uint16_t micro;
  
     const uint16_t nano;
  
     const char *rc;
  
     const char *describe;
 };
  
 typedef struct libusb_context libusb_context;
  
 typedef struct libusb_device libusb_device;
  
  
 typedef struct libusb_device_handle libusb_device_handle;
  
 enum libusb_speed {
     LIBUSB_SPEED_UNKNOWN = 0,
  
     LIBUSB_SPEED_LOW = 1,
  
     LIBUSB_SPEED_FULL = 2,
  
     LIBUSB_SPEED_HIGH = 3,
  
     LIBUSB_SPEED_SUPER = 4,
  
     LIBUSB_SPEED_SUPER_PLUS = 5
 };
  
 enum libusb_error {
     LIBUSB_SUCCESS = 0,
  
     LIBUSB_ERROR_IO = -1,
  
     LIBUSB_ERROR_INVALID_PARAM = -2,
  
     LIBUSB_ERROR_ACCESS = -3,
  
     LIBUSB_ERROR_NO_DEVICE = -4,
  
     LIBUSB_ERROR_NOT_FOUND = -5,
  
     LIBUSB_ERROR_BUSY = -6,
  
     LIBUSB_ERROR_TIMEOUT = -7,
  
     LIBUSB_ERROR_OVERFLOW = -8,
  
     LIBUSB_ERROR_PIPE = -9,
  
     LIBUSB_ERROR_INTERRUPTED = -10,
  
     LIBUSB_ERROR_NO_MEM = -11,
  
     LIBUSB_ERROR_NOT_SUPPORTED = -12,
  
     /* NB: Remember to update LIBUSB_ERROR_COUNT below as well as the
        message strings in strerror.c when adding new error codes here. */
  
     LIBUSB_ERROR_OTHER = -99
 };
  
 /* Total number of error codes in enum libusb_error */
 #define LIBUSB_ERROR_COUNT 14
  
 enum libusb_transfer_type {
     LIBUSB_TRANSFER_TYPE_CONTROL = 0U,
  
     LIBUSB_TRANSFER_TYPE_ISOCHRONOUS = 1U,
  
     LIBUSB_TRANSFER_TYPE_BULK = 2U,
  
     LIBUSB_TRANSFER_TYPE_INTERRUPT = 3U,
  
     LIBUSB_TRANSFER_TYPE_BULK_STREAM = 4U
 };
  
 enum libusb_transfer_status {
     LIBUSB_TRANSFER_COMPLETED,
  
     LIBUSB_TRANSFER_ERROR,
  
     LIBUSB_TRANSFER_TIMED_OUT,
  
     LIBUSB_TRANSFER_CANCELLED,
  
     LIBUSB_TRANSFER_STALL,
  
     LIBUSB_TRANSFER_NO_DEVICE,
  
     LIBUSB_TRANSFER_OVERFLOW
  
     /* NB! Remember to update libusb_error_name()
        when adding new status codes here. */
 };
  
 enum libusb_transfer_flags {
     LIBUSB_TRANSFER_SHORT_NOT_OK = (1U << 0),
  
     LIBUSB_TRANSFER_FREE_BUFFER = (1U << 1),
  
     LIBUSB_TRANSFER_FREE_TRANSFER = (1U << 2),
  
     LIBUSB_TRANSFER_ADD_ZERO_PACKET = (1U << 3)
 };
  
 struct libusb_iso_packet_descriptor {
     unsigned int length;
  
     unsigned int actual_length;
  
     enum libusb_transfer_status status;
 };
  
 struct libusb_transfer;
  
 typedef void (LIBUSB_CALL *libusb_transfer_cb_fn)(struct libusb_transfer *transfer);
  
 struct libusb_transfer {
     libusb_device_handle *dev_handle;
  
     uint8_t flags;
  
     unsigned char endpoint;
  
     unsigned char type;
  
     unsigned int timeout;
  
     enum libusb_transfer_status status;
  
     int length;
  
     int actual_length;
  
     libusb_transfer_cb_fn callback;
  
     void *user_data;
  
     unsigned char *buffer;
  
     int num_iso_packets;
  
     struct libusb_iso_packet_descriptor iso_packet_desc[ZERO_SIZED_ARRAY];
 };
  
 enum libusb_capability {
     LIBUSB_CAP_HAS_CAPABILITY = 0x0000U,
  
     LIBUSB_CAP_HAS_HOTPLUG = 0x0001U,
  
     LIBUSB_CAP_HAS_HID_ACCESS = 0x0100U,
  
     LIBUSB_CAP_SUPPORTS_DETACH_KERNEL_DRIVER = 0x0101U
 };
  
 enum libusb_log_level {
     LIBUSB_LOG_LEVEL_NONE = 0,
  
     LIBUSB_LOG_LEVEL_ERROR = 1,
  
     LIBUSB_LOG_LEVEL_WARNING = 2,
  
     LIBUSB_LOG_LEVEL_INFO = 3,
  
     LIBUSB_LOG_LEVEL_DEBUG = 4
 };
  
 enum libusb_log_cb_mode {
     LIBUSB_LOG_CB_GLOBAL = (1 << 0),
  
     LIBUSB_LOG_CB_CONTEXT = (1 << 1)
 };
  
 typedef void (LIBUSB_CALL *libusb_log_cb)(libusb_context *ctx,
     enum libusb_log_level level, const char *str);
  
 int LIBUSB_CALL libusb_init(libusb_context **ctx);
 void LIBUSB_CALL libusb_exit(libusb_context *ctx);
 LIBUSB_DEPRECATED_FOR(libusb_set_option)
 void LIBUSB_CALL libusb_set_debug(libusb_context *ctx, int level);
 void LIBUSB_CALL libusb_set_log_cb(libusb_context *ctx, libusb_log_cb cb, int mode);
 const struct libusb_version * LIBUSB_CALL libusb_get_version(void);
 int LIBUSB_CALL libusb_has_capability(uint32_t capability);
 const char * LIBUSB_CALL libusb_error_name(int errcode);
 int LIBUSB_CALL libusb_setlocale(const char *locale);
 const char * LIBUSB_CALL libusb_strerror(int errcode);
  
 ssize_t LIBUSB_CALL libusb_get_device_list(libusb_context *ctx,
     libusb_device ***list);
 void LIBUSB_CALL libusb_free_device_list(libusb_device **list,
     int unref_devices);
 libusb_device * LIBUSB_CALL libusb_ref_device(libusb_device *dev);
 void LIBUSB_CALL libusb_unref_device(libusb_device *dev);
  
 int LIBUSB_CALL libusb_get_configuration(libusb_device_handle *dev,
     int *config);
 int LIBUSB_CALL libusb_get_device_descriptor(libusb_device *dev,
     struct libusb_device_descriptor *desc);
 int LIBUSB_CALL libusb_get_active_config_descriptor(libusb_device *dev,
     struct libusb_config_descriptor **config);
 int LIBUSB_CALL libusb_get_config_descriptor(libusb_device *dev,
     uint8_t config_index, struct libusb_config_descriptor **config);
 int LIBUSB_CALL libusb_get_config_descriptor_by_value(libusb_device *dev,
     uint8_t bConfigurationValue, struct libusb_config_descriptor **config);
 void LIBUSB_CALL libusb_free_config_descriptor(
     struct libusb_config_descriptor *config);
 int LIBUSB_CALL libusb_get_ss_endpoint_companion_descriptor(
     libusb_context *ctx,
     const struct libusb_endpoint_descriptor *endpoint,
     struct libusb_ss_endpoint_companion_descriptor **ep_comp);
 void LIBUSB_CALL libusb_free_ss_endpoint_companion_descriptor(
     struct libusb_ss_endpoint_companion_descriptor *ep_comp);
 int LIBUSB_CALL libusb_get_bos_descriptor(libusb_device_handle *dev_handle,
     struct libusb_bos_descriptor **bos);
 void LIBUSB_CALL libusb_free_bos_descriptor(struct libusb_bos_descriptor *bos);
 int LIBUSB_CALL libusb_get_usb_2_0_extension_descriptor(
     libusb_context *ctx,
     struct libusb_bos_dev_capability_descriptor *dev_cap,
     struct libusb_usb_2_0_extension_descriptor **usb_2_0_extension);
 void LIBUSB_CALL libusb_free_usb_2_0_extension_descriptor(
     struct libusb_usb_2_0_extension_descriptor *usb_2_0_extension);
 int LIBUSB_CALL libusb_get_ss_usb_device_capability_descriptor(
     libusb_context *ctx,
     struct libusb_bos_dev_capability_descriptor *dev_cap,
     struct libusb_ss_usb_device_capability_descriptor **ss_usb_device_cap);
 void LIBUSB_CALL libusb_free_ss_usb_device_capability_descriptor(
     struct libusb_ss_usb_device_capability_descriptor *ss_usb_device_cap);
 int LIBUSB_CALL libusb_get_container_id_descriptor(libusb_context *ctx,
     struct libusb_bos_dev_capability_descriptor *dev_cap,
     struct libusb_container_id_descriptor **container_id);
 void LIBUSB_CALL libusb_free_container_id_descriptor(
     struct libusb_container_id_descriptor *container_id);
 uint8_t LIBUSB_CALL libusb_get_bus_number(libusb_device *dev);
 uint8_t LIBUSB_CALL libusb_get_port_number(libusb_device *dev);
 int LIBUSB_CALL libusb_get_port_numbers(libusb_device *dev, uint8_t *port_numbers, int port_numbers_len);
 LIBUSB_DEPRECATED_FOR(libusb_get_port_numbers)
 int LIBUSB_CALL libusb_get_port_path(libusb_context *ctx, libusb_device *dev, uint8_t *path, uint8_t path_length);
 libusb_device * LIBUSB_CALL libusb_get_parent(libusb_device *dev);
 uint8_t LIBUSB_CALL libusb_get_device_address(libusb_device *dev);
 int LIBUSB_CALL libusb_get_device_speed(libusb_device *dev);
 int LIBUSB_CALL libusb_get_max_packet_size(libusb_device *dev,
     unsigned char endpoint);
 int LIBUSB_CALL libusb_get_max_iso_packet_size(libusb_device *dev,
     unsigned char endpoint);
  
 int LIBUSB_CALL libusb_wrap_sys_device(libusb_context *ctx, intptr_t sys_dev, libusb_device_handle **dev_handle);
 int LIBUSB_CALL libusb_open(libusb_device *dev, libusb_device_handle **dev_handle);
 void LIBUSB_CALL libusb_close(libusb_device_handle *dev_handle);
 libusb_device * LIBUSB_CALL libusb_get_device(libusb_device_handle *dev_handle);
  
 int LIBUSB_CALL libusb_set_configuration(libusb_device_handle *dev_handle,
     int configuration);
 int LIBUSB_CALL libusb_claim_interface(libusb_device_handle *dev_handle,
     int interface_number);
 int LIBUSB_CALL libusb_release_interface(libusb_device_handle *dev_handle,
     int interface_number);
  
 libusb_device_handle * LIBUSB_CALL libusb_open_device_with_vid_pid(
     libusb_context *ctx, uint16_t vendor_id, uint16_t product_id);
  
 int LIBUSB_CALL libusb_set_interface_alt_setting(libusb_device_handle *dev_handle,
     int interface_number, int alternate_setting);
 int LIBUSB_CALL libusb_clear_halt(libusb_device_handle *dev_handle,
     unsigned char endpoint);
 int LIBUSB_CALL libusb_reset_device(libusb_device_handle *dev_handle);
  
 int LIBUSB_CALL libusb_alloc_streams(libusb_device_handle *dev_handle,
     uint32_t num_streams, unsigned char *endpoints, int num_endpoints);
 int LIBUSB_CALL libusb_free_streams(libusb_device_handle *dev_handle,
     unsigned char *endpoints, int num_endpoints);
  
 unsigned char * LIBUSB_CALL libusb_dev_mem_alloc(libusb_device_handle *dev_handle,
     size_t length);
 int LIBUSB_CALL libusb_dev_mem_free(libusb_device_handle *dev_handle,
     unsigned char *buffer, size_t length);
  
 int LIBUSB_CALL libusb_kernel_driver_active(libusb_device_handle *dev_handle,
     int interface_number);
 int LIBUSB_CALL libusb_detach_kernel_driver(libusb_device_handle *dev_handle,
     int interface_number);
 int LIBUSB_CALL libusb_attach_kernel_driver(libusb_device_handle *dev_handle,
     int interface_number);
 int LIBUSB_CALL libusb_set_auto_detach_kernel_driver(
     libusb_device_handle *dev_handle, int enable);
  
 /* async I/O */
  
 static inline unsigned char *libusb_control_transfer_get_data(
     struct libusb_transfer *transfer)
 {
     return transfer->buffer + LIBUSB_CONTROL_SETUP_SIZE;
 }
  
 static inline struct libusb_control_setup *libusb_control_transfer_get_setup(
     struct libusb_transfer *transfer)
 {
     return (struct libusb_control_setup *)(void *)transfer->buffer;
 }
  
 static inline void libusb_fill_control_setup(unsigned char *buffer,
     uint8_t bmRequestType, uint8_t bRequest, uint16_t wValue, uint16_t wIndex,
     uint16_t wLength)
 {
     struct libusb_control_setup *setup = (struct libusb_control_setup *)(void *)buffer;
     setup->bmRequestType = bmRequestType;
     setup->bRequest = bRequest;
     setup->wValue = libusb_cpu_to_le16(wValue);
     setup->wIndex = libusb_cpu_to_le16(wIndex);
     setup->wLength = libusb_cpu_to_le16(wLength);
 }
  
 struct libusb_transfer * LIBUSB_CALL libusb_alloc_transfer(int iso_packets);
 int LIBUSB_CALL libusb_submit_transfer(struct libusb_transfer *transfer);
 int LIBUSB_CALL libusb_cancel_transfer(struct libusb_transfer *transfer);
 void LIBUSB_CALL libusb_free_transfer(struct libusb_transfer *transfer);
 void LIBUSB_CALL libusb_transfer_set_stream_id(
     struct libusb_transfer *transfer, uint32_t stream_id);
 uint32_t LIBUSB_CALL libusb_transfer_get_stream_id(
     struct libusb_transfer *transfer);
  
 static inline void libusb_fill_control_transfer(
     struct libusb_transfer *transfer, libusb_device_handle *dev_handle,
     unsigned char *buffer, libusb_transfer_cb_fn callback, void *user_data,
     unsigned int timeout)
 {
     struct libusb_control_setup *setup = (struct libusb_control_setup *)(void *)buffer;
     transfer->dev_handle = dev_handle;
     transfer->endpoint = 0;
     transfer->type = LIBUSB_TRANSFER_TYPE_CONTROL;
     transfer->timeout = timeout;
     transfer->buffer = buffer;
     if (setup)
         transfer->length = (int) (LIBUSB_CONTROL_SETUP_SIZE
             + libusb_le16_to_cpu(setup->wLength));
     transfer->user_data = user_data;
     transfer->callback = callback;
 }
  
 static inline void libusb_fill_bulk_transfer(struct libusb_transfer *transfer,
     libusb_device_handle *dev_handle, unsigned char endpoint,
     unsigned char *buffer, int length, libusb_transfer_cb_fn callback,
     void *user_data, unsigned int timeout)
 {
     transfer->dev_handle = dev_handle;
     transfer->endpoint = endpoint;
     transfer->type = LIBUSB_TRANSFER_TYPE_BULK;
     transfer->timeout = timeout;
     transfer->buffer = buffer;
     transfer->length = length;
     transfer->user_data = user_data;
     transfer->callback = callback;
 }
  
 static inline void libusb_fill_bulk_stream_transfer(
     struct libusb_transfer *transfer, libusb_device_handle *dev_handle,
     unsigned char endpoint, uint32_t stream_id,
     unsigned char *buffer, int length, libusb_transfer_cb_fn callback,
     void *user_data, unsigned int timeout)
 {
     libusb_fill_bulk_transfer(transfer, dev_handle, endpoint, buffer,
                   length, callback, user_data, timeout);
     transfer->type = LIBUSB_TRANSFER_TYPE_BULK_STREAM;
     libusb_transfer_set_stream_id(transfer, stream_id);
 }
  
 static inline void libusb_fill_interrupt_transfer(
     struct libusb_transfer *transfer, libusb_device_handle *dev_handle,
     unsigned char endpoint, unsigned char *buffer, int length,
     libusb_transfer_cb_fn callback, void *user_data, unsigned int timeout)
 {
     transfer->dev_handle = dev_handle;
     transfer->endpoint = endpoint;
     transfer->type = LIBUSB_TRANSFER_TYPE_INTERRUPT;
     transfer->timeout = timeout;
     transfer->buffer = buffer;
     transfer->length = length;
     transfer->user_data = user_data;
     transfer->callback = callback;
 }
  
 static inline void libusb_fill_iso_transfer(struct libusb_transfer *transfer,
     libusb_device_handle *dev_handle, unsigned char endpoint,
     unsigned char *buffer, int length, int num_iso_packets,
     libusb_transfer_cb_fn callback, void *user_data, unsigned int timeout)
 {
     transfer->dev_handle = dev_handle;
     transfer->endpoint = endpoint;
     transfer->type = LIBUSB_TRANSFER_TYPE_ISOCHRONOUS;
     transfer->timeout = timeout;
     transfer->buffer = buffer;
     transfer->length = length;
     transfer->num_iso_packets = num_iso_packets;
     transfer->user_data = user_data;
     transfer->callback = callback;
 }
  
 static inline void libusb_set_iso_packet_lengths(
     struct libusb_transfer *transfer, unsigned int length)
 {
     int i;
  
     for (i = 0; i < transfer->num_iso_packets; i++)
         transfer->iso_packet_desc[i].length = length;
 }
  
 static inline unsigned char *libusb_get_iso_packet_buffer(
     struct libusb_transfer *transfer, unsigned int packet)
 {
     int i;
     size_t offset = 0;
     int _packet;
  
     /* oops..slight bug in the API. packet is an unsigned int, but we use
      * signed integers almost everywhere else. range-check and convert to
      * signed to avoid compiler warnings. FIXME for libusb-2. */
     if (packet > INT_MAX)
         return NULL;
     _packet = (int) packet;
  
     if (_packet >= transfer->num_iso_packets)
         return NULL;
  
     for (i = 0; i < _packet; i++)
         offset += transfer->iso_packet_desc[i].length;
  
     return transfer->buffer + offset;
 }
  
 static inline unsigned char *libusb_get_iso_packet_buffer_simple(
     struct libusb_transfer *transfer, unsigned int packet)
 {
     int _packet;
  
     /* oops..slight bug in the API. packet is an unsigned int, but we use
      * signed integers almost everywhere else. range-check and convert to
      * signed to avoid compiler warnings. FIXME for libusb-2. */
     if (packet > INT_MAX)
         return NULL;
     _packet = (int) packet;
  
     if (_packet >= transfer->num_iso_packets)
         return NULL;
  
     return transfer->buffer + ((int) transfer->iso_packet_desc[0].length * _packet);
 }
  
 /* sync I/O */
  
 int LIBUSB_CALL libusb_control_transfer(libusb_device_handle *dev_handle,
     uint8_t request_type, uint8_t bRequest, uint16_t wValue, uint16_t wIndex,
     unsigned char *data, uint16_t wLength, unsigned int timeout);
  
 int LIBUSB_CALL libusb_bulk_transfer(libusb_device_handle *dev_handle,
     unsigned char endpoint, unsigned char *data, int length,
     int *actual_length, unsigned int timeout);
  
 int LIBUSB_CALL libusb_interrupt_transfer(libusb_device_handle *dev_handle,
     unsigned char endpoint, unsigned char *data, int length,
     int *actual_length, unsigned int timeout);
  
 static inline int libusb_get_descriptor(libusb_device_handle *dev_handle,
     uint8_t desc_type, uint8_t desc_index, unsigned char *data, int length)
 {
     return libusb_control_transfer(dev_handle, LIBUSB_ENDPOINT_IN,
         LIBUSB_REQUEST_GET_DESCRIPTOR, (uint16_t) ((desc_type << 8) | desc_index),
         0, data, (uint16_t) length, 1000);
 }
  
 static inline int libusb_get_string_descriptor(libusb_device_handle *dev_handle,
     uint8_t desc_index, uint16_t langid, unsigned char *data, int length)
 {
     return libusb_control_transfer(dev_handle, LIBUSB_ENDPOINT_IN,
         LIBUSB_REQUEST_GET_DESCRIPTOR, (uint16_t)((LIBUSB_DT_STRING << 8) | desc_index),
         langid, data, (uint16_t) length, 1000);
 }
  
 int LIBUSB_CALL libusb_get_string_descriptor_ascii(libusb_device_handle *dev_handle,
     uint8_t desc_index, unsigned char *data, int length);
  
 /* polling and timeouts */
  
 int LIBUSB_CALL libusb_try_lock_events(libusb_context *ctx);
 void LIBUSB_CALL libusb_lock_events(libusb_context *ctx);
 void LIBUSB_CALL libusb_unlock_events(libusb_context *ctx);
 int LIBUSB_CALL libusb_event_handling_ok(libusb_context *ctx);
 int LIBUSB_CALL libusb_event_handler_active(libusb_context *ctx);
 void LIBUSB_CALL libusb_interrupt_event_handler(libusb_context *ctx);
 void LIBUSB_CALL libusb_lock_event_waiters(libusb_context *ctx);
 void LIBUSB_CALL libusb_unlock_event_waiters(libusb_context *ctx);
 int LIBUSB_CALL libusb_wait_for_event(libusb_context *ctx, struct timeval *tv);
  
 int LIBUSB_CALL libusb_handle_events_timeout(libusb_context *ctx,
     struct timeval *tv);
 int LIBUSB_CALL libusb_handle_events_timeout_completed(libusb_context *ctx,
     struct timeval *tv, int *completed);
 int LIBUSB_CALL libusb_handle_events(libusb_context *ctx);
 int LIBUSB_CALL libusb_handle_events_completed(libusb_context *ctx, int *completed);
 int LIBUSB_CALL libusb_handle_events_locked(libusb_context *ctx,
     struct timeval *tv);
 int LIBUSB_CALL libusb_pollfds_handle_timeouts(libusb_context *ctx);
 int LIBUSB_CALL libusb_get_next_timeout(libusb_context *ctx,
     struct timeval *tv);
  
 struct libusb_pollfd {
     int fd;
  
     short events;
 };
  
 typedef void (LIBUSB_CALL *libusb_pollfd_added_cb)(int fd, short events,
     void *user_data);
  
 typedef void (LIBUSB_CALL *libusb_pollfd_removed_cb)(int fd, void *user_data);
  
 const struct libusb_pollfd ** LIBUSB_CALL libusb_get_pollfds(
     libusb_context *ctx);
 void LIBUSB_CALL libusb_free_pollfds(const struct libusb_pollfd **pollfds);
 void LIBUSB_CALL libusb_set_pollfd_notifiers(libusb_context *ctx,
     libusb_pollfd_added_cb added_cb, libusb_pollfd_removed_cb removed_cb,
     void *user_data);
  
 typedef int libusb_hotplug_callback_handle;
  
 typedef enum {
     LIBUSB_HOTPLUG_EVENT_DEVICE_ARRIVED = (1 << 0),
  
     LIBUSB_HOTPLUG_EVENT_DEVICE_LEFT = (1 << 1)
 } libusb_hotplug_event;
  
 typedef enum {
     LIBUSB_HOTPLUG_ENUMERATE = (1 << 0)
 } libusb_hotplug_flag;
  
 #define LIBUSB_HOTPLUG_NO_FLAGS 0
  
 #define LIBUSB_HOTPLUG_MATCH_ANY -1
  
 typedef int (LIBUSB_CALL *libusb_hotplug_callback_fn)(libusb_context *ctx,
     libusb_device *device, libusb_hotplug_event event, void *user_data);
  
 int LIBUSB_CALL libusb_hotplug_register_callback(libusb_context *ctx,
     int events, int flags,
     int vendor_id, int product_id, int dev_class,
     libusb_hotplug_callback_fn cb_fn, void *user_data,
     libusb_hotplug_callback_handle *callback_handle);
  
 void LIBUSB_CALL libusb_hotplug_deregister_callback(libusb_context *ctx,
     libusb_hotplug_callback_handle callback_handle);
  
 void * LIBUSB_CALL libusb_hotplug_get_user_data(libusb_context *ctx,
     libusb_hotplug_callback_handle callback_handle);
  
 enum libusb_option {
     LIBUSB_OPTION_LOG_LEVEL = 0,
  
     LIBUSB_OPTION_USE_USBDK = 1,
  
     LIBUSB_OPTION_WEAK_AUTHORITY = 2
 };
  
 int LIBUSB_CALL libusb_set_option(libusb_context *ctx, enum libusb_option option, ...);
  
 #if defined(__cplusplus)
 }
 #endif
  
 #endif
