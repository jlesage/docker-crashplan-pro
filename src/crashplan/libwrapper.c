#define _GNU_SOURCE
#include <dlfcn.h>
#include <stdlib.h>
#include <string.h>
#include <sys/utsname.h>
#include <stdio.h>
#include <netdb.h>

#define DIM(a) (sizeof(a)/sizeof(a[0]))

static const char *deny_domain_names[] = {
    "download.code42.com",
};

static void init(void) __attribute__((constructor));

/*
 * Constructor.
 *
 * This function is called when the library is loaded.
 */
static void init(void)
{
}

/*
 * Wrapper for the `uname` function.
 */
int uname(struct utsname *buf)
{
#ifdef DEBUG
    printf("OVERRIDING uname\n");
#endif

    // Get the original function.
    static int (*f)() = NULL;
    if (f == NULL) {
        f = dlsym (RTLD_NEXT, "uname");
    }

    // Invoke the original function.
    int rc = f(buf);
    if (rc != 0) {
        return rc;
    }

    // Override the kernel version.
    {
        const char* env = getenv("CRASHPLAN_KERNEL_RELEASE");
        // Fallback on valid linux kernel version for Ubuntu 20.04.
        // https://packages.ubuntu.com/focal-updates/linux-image-generic
        const char *version = env ? env : "5.4.0-96-generic";
        strncpy(buf->release, version, sizeof(buf->release));
    }
    return rc;
}

/*
 * Wrapper for the `getaddrinfo` function.
 */
int getaddrinfo(const char *node, const char *service,
		const struct addrinfo *hints,
		struct addrinfo **res)
{
#ifdef DEBUG
    printf("OVERRIDING getaddrinfo: '%s'\n", node ? node : "null");
#endif

    // Get the original function.
    static int (*f)() = NULL;
    if (f == NULL) {
        f = dlsym (RTLD_NEXT, "getaddrinfo");
    }

    // Check if the DNS name is allowed.
    for (int i = 0; i < DIM(deny_domain_names); i++) {
        if (strcmp(node, deny_domain_names[i]) == 0) {
            return EAI_FAIL;
        }
    }

    // Invoke the original function.
    return f(node, service, hints, res);
}

