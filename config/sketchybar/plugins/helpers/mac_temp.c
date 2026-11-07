#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/IOKitLib.h>
#include <stdio.h>
#include <string.h>

typedef void *IOHIDEventSystemClientRef;
typedef void *IOHIDServiceClientRef;
typedef void *IOHIDEventRef;

IOHIDEventSystemClientRef IOHIDEventSystemClientCreate(CFAllocatorRef allocator);
int IOHIDEventSystemClientSetMatching(IOHIDEventSystemClientRef client, CFDictionaryRef match);
CFArrayRef IOHIDEventSystemClientCopyServices(IOHIDEventSystemClientRef client);
CFStringRef IOHIDServiceClientCopyProperty(IOHIDServiceClientRef service, CFStringRef key);
IOHIDEventRef IOHIDServiceClientCopyEvent(IOHIDServiceClientRef service, int64_t type, int32_t options, int64_t param);
double IOHIDEventGetFloatValue(IOHIDEventRef event, int32_t field);

int main(int argc, char **argv) {
    IOHIDEventSystemClientRef client = IOHIDEventSystemClientCreate(kCFAllocatorDefault);
    if (!client) {
        printf("--°C\n");
        return 0;
    }

    int page = 0xff00;
    int usage = 0x05;
    CFNumberRef pageNum = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &page);
    CFNumberRef usageNum = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &usage);

    CFStringRef keys[2] = { CFSTR("PrimaryUsagePage"), CFSTR("PrimaryUsage") };
    CFNumberRef values[2] = { pageNum, usageNum };
    CFDictionaryRef match = CFDictionaryCreate(kCFAllocatorDefault, (const void **)keys, (const void **)values, 2, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);

    IOHIDEventSystemClientSetMatching(client, match);
    CFArrayRef services = IOHIDEventSystemClientCopyServices(client);

    if (!services) {
        CFRelease(match);
        CFRelease(pageNum);
        CFRelease(usageNum);
        CFRelease(client);
        printf("--°C\n");
        return 0;
    }

    CFIndex count = CFArrayGetCount(services);
    double sum_temp = 0.0;
    int valid_count = 0;

    for (CFIndex i = 0; i < count; i++) {
        IOHIDServiceClientRef service = (IOHIDServiceClientRef)CFArrayGetValueAtIndex(services, i);
        IOHIDEventRef event = IOHIDServiceClientCopyEvent(service, 15, 0, 0);
        if (event) {
            double temp = IOHIDEventGetFloatValue(event, 15 << 16);
            if (temp > 10.0 && temp < 120.0) {
                sum_temp += temp;
                valid_count++;
            }
            CFRelease(event);
        }
    }

    if (valid_count > 0) {
        int avg = (int)((sum_temp / valid_count) + 0.5);
        printf("%d°C\n", avg);
    } else {
        printf("--°C\n");
    }

    CFRelease(match);
    CFRelease(pageNum);
    CFRelease(usageNum);
    CFRelease(services);
    CFRelease(client);
    return 0;
}
