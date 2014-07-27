all:
	windres cygvim.rc -O coff -o icon.res
	g++ -o cygvim cygvim.cpp -mwindows icon.res

clean:
	rm icon.res cygvim.exe
