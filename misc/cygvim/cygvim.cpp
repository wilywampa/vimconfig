#include <stdio.h>
#include <stdlib.h>
#include <process.h>
#include <windows.h>
#include <errno.h>

int main(int argc, char const* argv[])
{
    if (argc != 2)
        exit(1);

    const char *args[] = {"cygvim_wrapper", argv[1], NULL};
    const char *env[]  = {"DISPLAY=localhost:0.0", NULL};

    char executable[1024];
    sprintf(executable, "/home/%s/bin/cygvim_wrapper", getenv("USERNAME"));

    int retval = spawnve(_P_NOWAIT, executable, args, env);

    if (retval == -1)
    {
        char err[256];
        sprintf(err, "%s", strerror(errno));
        ::MessageBox(NULL, err, "Error", MB_OK);

        if (errno == 2)
        {
            char path[2048];
            sprintf(path, "%s", getenv("PATH"));
            ::MessageBox(NULL, path, "PATH", MB_OK);
        }
    }

    return 0;
}
