all:
	windres cygvim.rc -O coff -o icon.res
	gcc -o cygvim cygvim.c -mwindows icon.res

clean:
	rm icon.res cygvim.exe
