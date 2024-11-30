/**
 * `login.c`
 * ianmclinden, 2024
 *
 * A fake authentication framwork, for dissasembling.
 */

#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <stdlib.h>

#define MAX_USERNAME (128)
#define MAX_PASSWORD (128)
#define LOGIN_ATTEMPTS (3)

typedef struct
{
    const char *name;
    const char *password;
} user_t;

const user_t users[] = {
    {.name = "ian", .password = "pass"},
    {.name = NULL, .password = NULL},
};

int try_authenticate(const char *username, const char *pass)
{
    const user_t *user = NULL;
    for (int i = 0; &users[i] != NULL && users[i].name != NULL; i++)
    {
        user = &users[i];
        if (strlen(username) == strlen(user->name) &&
            strlen(pass) == strlen(user->password) &&
            0 == strncmp(username, user->name, strlen(username)) &&
            0 == strncmp(pass, user->password, strlen(pass)))
        {
            return 0;
        }
        user++;
    }
    return -1;
}

int main(int argc, char **argv)
{
    char username[MAX_USERNAME], *password;
    int login_attempts = LOGIN_ATTEMPTS;

    if (argc >= 2)
    {
        login_attempts = strtol(argv[1], (char **)NULL, 10);
        if (login_attempts <= 0 || login_attempts > 5)
        {
            printf("Invalid login attempts: '%s' [1..=5]\n\n", argv[1]);
            printf("Usage:\tlogin <ATTEMPTS>\n");
            return -1;
        }
    }

    printf("Log in: \n");

    for (int i = 0; i < login_attempts; i++)
    {
        printf("User: ");
        if (fgets(username, MAX_USERNAME, stdin))
        {
            username[strcspn(username, "\n")] = 0;

            if (NULL != (password = getpass("Pass: ")))
            {
                password[strcspn(password, "\n")] = 0;
                if (try_authenticate((const char *)username, (const char *)password) == 0)
                {
                    printf("Welcome, %s\n", username);
                    return 0;
                }
                else
                {
                    printf("Incorrect\n\n");
                }
            }
        }
    }
    printf("Login failed, try again later\n");
}
