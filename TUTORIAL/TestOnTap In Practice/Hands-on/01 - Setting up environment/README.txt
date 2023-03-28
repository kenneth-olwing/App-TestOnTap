HANDS-ON: SETTING UP ENVIRONMENT
================================

1) OBJECTIVE

	The objective is to be able to run the commands:

	* testontap –version
	* qgrep
	
	(The qgrep command is only relevant for this training; it has nothing to do
	with TestOnTap otherwise).

	Optionally, on Windows only, to run:
	
	* autoit3

	(This is to enable a later hands-on for automating a GUI)
	
	Note: if possible, it is recommended to use either of the Linux/UNIX/WSL
	installs below as some aspects of testontap (parallellization, in
	particular) is more efficient on that platform.

2) FALLBACK

	If, for time or other reasons, it’s not possible to complete the hands-on, a
	set of precompiled binaries are present that can be used
	directly:

	* bin\Windows and ÁutoIt (Windows)
	* bin/WSL (Windows Subsystem for Linux)
	* bin/RHEL (Red Hat Linux)

	Add the requisite path to the PATH environment variable, e.g. typically:

	* Red Hat Linux
		export PATH=<hands-on>/bin/RHEL:$PATH

	* WSL
		export PATH=<hands-on>/bin/WSL:$PATH

	* Windows
		set PATH=<hands-on>\bin\Windows;<hands-on>\AutoIt;%PATH%

	Verify that the commands in the objective works.

3) REQUIREMENTS

	A Perl installation of at least 5.10.1, preferably much later e.g. 5.24 or
	so (try perl –v  for information).

	* You must be able to install modules to it
	* Often you need a C compiler, e.g. gcc and make (on Windows, it may be
	dmake)

4) PERL, MAKE AND GCC

	Verify that you have access to the following, and for Perl especially, what
	version:

	* perl -version
	* gcc –v
	* make –v (dmake –V on Windows)

	In practice, this should always work in a UNIX/Linux/WSL environment, just
	verify that the Perl version is adequate. Installing Perl from the ground up
	is beyond the scope of this hands-on.

	On Windows it is generally the opposite. Unless you are absolutely certain
	that you have the right version and that you have the right to install
	modules in it, it is recommended to use the provided Strawberry Perl.
	Another possibility is ActivePerl.

	4.1) WINDOWS – STRAWBERRY PERL

		The zip file is from http://strawberryperl.com/, just unpack it in a
		convenient location (avoid path with spaces in it).

		This is a ’portable perl’ meaning that it can be moved around freely,
		and it also contains the gcc/make required.

		Execute the portableshell.bat file in the root of the unpack – the
		necessary environment variables have now been set.

		It is fully self-contained and you will also have the ability to install
		modules in it.

		Try the commands above to verify.

		4.2) Linux/UNIX/WSL

		Generally, you will not have the appropriate rights to install modules
		in the system Perl (and even if you have root privileges, you should be
		wary of installing modules outside the vendors official builds).

		To avoid this, a convenient method is to use a private location for
		modules in your home directory. This uses a few tricks to set up (See
		https://stackoverflow.com/questions/2980297/how-can-i-use-cpan-as-a-non-
		root-user for details on what happens); run the following commands (cut
		and paste to avoid missing a detail):

		wget -O- http://cpanmin.us | perl - -l ~/perl5 App::cpanminus local::lib
		eval $(perl -I ~/perl5/lib/perl5 -Mlocal::lib)
		echo 'eval $(perl -I ~/perl5/lib/perl5 -Mlocal::lib)' >> ~/.profile
		echo 'export MANPATH=$HOME/perl5/man:$MANPATH' >> ~/.profile

5) APP::TESTONTAP

	The simplest method is to use the Perl tools to automatically download and
	install the module and associated dependencies:

		cpanm App::TestOnTap

	Note: this will take a varying amount of time due to several factors,
	including hardware. On the Strawberry Perl on Windows (which has most
	modules up-to-date), a sample time would be ca 5-10 minutes. On an older
	Perl, it may take substantially longer due to the need to update more 
	modules.

6) EXTRA CREDIT

	If you have come this far, it is now possible to do the same thing as was
	prepared for the ’fallback’ above: create binaries of testontap.

	Now a ’hidden’ option in testontap can be used; it runs the ’pp’ command
	to pack a binary.

	Execute the following:

	testontap --_pp

	You should now have a file with a name with embedded version/platform
	information, e.g. typically ’testontap-0.043-linux-x86_64’. It can be
	renamed and placed in the PATH. It should be movable to any other path and,
	in theory, any other machine.

7) END

	In all cases, ensure the objectives are met before proceeding.
