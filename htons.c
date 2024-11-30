#include <stdio.h>
#include <stdlib.h>

int main(int argc, char **argv)
{
    int port = 0;
    if (argc >= 2)
    {
        port = strtol(argv[1], (char **)NULL, 10);
        if (port >= 0)
        {
            printf("htons(%d) = 0x%x\n", port, htons(port));
        }
    }
    return -1;
}