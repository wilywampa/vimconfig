#include <stdio.h>
#include <stdlib.h>
#include <process.h>

char *env[] = {"DISPLAY=localhost:0.0", NULL};

int main(int argc, char const* argv[])
{
    if (argc != 2)
        exit(1);

    const char *args[] = {"cygvim_wrapper", argv[1], NULL};

    spawnve(_P_NOWAIT, "cygvim_wrapper",
            (const char *const *)args,
            (const char *const *)env);

    return 0;
}
