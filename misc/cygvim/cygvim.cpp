#include <stdio.h>
#include <stdlib.h>
#include <process.h>
#include <windows.h>
#include <errno.h>

int main(int argc, char const* argv[])
{
    int retval;
    const char *filename;

    if (argc > 2)
        exit(1);
    else if (argc == 1)
    {
        OPENFILENAME ofn;
        char szFile[256];

        ZeroMemory(&ofn, sizeof(ofn));
        ofn.lStructSize = sizeof(ofn);
        ofn.hwndOwner = NULL;
        ofn.lpstrFile = szFile;
        ofn.lpstrFile[0] = '\0';
        ofn.nMaxFile = sizeof(szFile);
        ofn.lpstrFilter = "All\0*.*";
        ofn.nFilterIndex =1;
        ofn.lpstrFileTitle = NULL;
        ofn.nMaxFileTitle = 0;
        ofn.lpstrInitialDir=NULL;
        ofn.Flags = OFN_PATHMUSTEXIST|OFN_FILEMUSTEXIST;

        retval = GetOpenFileName(&ofn);
        if (!retval)
            exit(1);
        else
            filename = szFile;
    }
    else
    {
        filename = argv[1];
    }

    const char *args[] = {"cygvim_wrapper", filename, NULL};
    const char *env[]  = {"DISPLAY=localhost:0.0", NULL};

    char executable[1024];
    sprintf(executable, "/home/%s/bin/cygvim_wrapper", getenv("USERNAME"));

    retval = spawnve(_P_NOWAIT, executable, args, env);

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

        exit(1);
    }

    return 0;
}
