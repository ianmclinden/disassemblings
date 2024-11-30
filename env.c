/**
 * `env.c`
 * ianmclinden, 2024
 *
 * Print all environment variables
 */

#include <stdio.h>
#include <fcntl.h>

int main(__attribute__((unused)) int argc,
         __attribute__((unused)) char **argv,
         char **envp)
{
    printf("Environment Vars:\n");
    while (*envp)
    {
        printf("%s\n", *envp++);
    }

    return 0;
}
