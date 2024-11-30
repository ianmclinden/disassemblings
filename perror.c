/**
 * `perror.c`
 * ianmclinden, 2024
 *
 * Print the error message translation for a given error code.
 *
 * Useful for fast translating from command-line programs.
 */

#include <stdio.h>
#include <errno.h>
#include <stdlib.h>

int main(int argc, char **argv)
{
    int errno_raw = 0;

    if (argc >= 2)
    {
        errno_raw = strtol(argv[1], (char **)NULL, 10);
        // Lazy negative conversion in case the shell returns negative codes
        errno = (errno_raw >= 0) ? errno_raw : -errno_raw;

        if (errno != 0)
        {
            printf("Error (%d): ", errno_raw);
            fflush(stdout);
            perror("");
        }
    }
    return 0;
}