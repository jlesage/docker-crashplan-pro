#define _GNU_SOURCE
#include <dlfcn.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <ctype.h>
#include <sys/utsname.h>
#include <stdio.h>

static const char *extract_version(const char *str)
{
    static char version[128] = "";
    const char *p = str;

    if (*p == '\0') {
        return NULL;
    }
    else if (isdigit(*p)) {
        const char *version_start = p;
        int num_numbers = 0;
        int num_dots = 0;
        while (true) {
            if (isdigit(*p)) {
                num_numbers++;
                while(isdigit(*p)) p++;
            }
            if (*p == '.') {
                num_dots++;
                p++;
            }
            else if (*p == '-' && isdigit(*(p + 1))) {
                 p++;
            }
            else {
                break;
            }
        }
        if (num_dots == 2 && num_numbers >= 3) {
            if (*p == '\0' || *p == ' ' || *p == '-') {
                size_t version_str_len = p - version_start;
                if (version_str_len < sizeof(version)) {
                    strncpy(version, version_start, version_str_len);
                    return version;
                }
            }
        }
    }
    else {
        while (*p != '\0' && *p != ' ' && *p != '-') p++;
        return extract_version(++p);
    }
    return NULL;
}

static void init(void) __attribute__((constructor));

static int (*orig_uname)(struct utsname *buf);

/*
 * Constructor.
 *
 * Save pointer to the original uname function.
 */
static void init(void)
{
    orig_uname = dlsym(RTLD_NEXT, "uname");
}

/*
 * Wrapper for the uname function.
 */
int uname(struct utsname *buf)
{
    int rc = orig_uname(buf);
    if (rc == 0) {
        const char *version = extract_version(buf->release);
        if (version) {
            strncpy(buf->release, version, sizeof(buf->release));
        }
    }
    return rc;
}

/* This function is the entry point for the shared object.
   Running the library as a program will get here. */
int main (int argc, char *argv[]) {
    if (argc == 2) {
        const char *version = extract_version(argv[1]);
        printf("release: %s\n", version ? version : argv[1]);
    }
    return 0;
}
