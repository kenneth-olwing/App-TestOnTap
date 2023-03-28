HANDS-ON: ARGUMENTS AND ENVIRONMENT
===================================

1) OBJECTIVE

	This hands-on shows how the user can pass information to the tests in a
	suite using the arguments on the command line and the inherited environment.
	It also shows how a suite can provide a command that can manipulate the data
	before the suite starts executing tests (e.g. in order to precheck things,
	ensure all required things are set, scrub an environment variable etc).

	These are the principal ways to make a suite 'variable', i.e. pass
	'instructions' to it.

2) THE SUITE

	The suite contains a simple 'test' that uses TAP 'notes' to print the
	arguments and environment it sees. Since this is not normally passed through
	the harness, you must request verboseness.

	2.1) SUITE-1

		Run the suite:

			testontap --verbose suite-1 fee fie foo 'arg with spaces'

		You will find sections for arguments and environment, printed with the
		hashmark prefix ('#').

		Note especially the TestOnTap variables that are always passed:

			* TESTONTAP_SUITE_DIR

				This is the path to the suites root directory. It may be used by
				tests to assist them in navigating the tree, e.g. to find data
				files it needs.

			* TESTONTAP_TMP_DIR

				This is a path to an (initially) empty directory. It is free for
				the tests to use as they see fit, and so can be used to pass
				information between each other. Upon conclusion, TestOnTap will
				clean it up (but for debugging needs, a flag can be used to keep
				it).

			* TESTONTAP_SAVE_DIR

				Similar to the tmp directory, but will be kept as part of the
				results (assuming they are saved at all, e.g. using --archive).
				It’s up to any later presentation mechanism to pull out suite
				specific files for presentation.

		2.2) SUITE-2

			This suite has been outfitted with a Perl script called
			'preprocess.pl' and a configuration that a) skips it from being
			scanned, but most importantly b) is mentioned in the preprocess
			directive:

				preprocess = perl preprocess.pl

			I.e. just giving the appropriate command line to use. Notice that
			this makes it simple to test directly by hand.

			Such a script is required to, if it wants to change either the
			arguments or environment to pass on, to simply print that in a
			certain format and TestOnTap will adjust before starting the tests.
			See https://metacpan.org/pod/App::TestOnTap for details in the
			format.

			This particular script is simple and is looking for the text 'FIXME'
			in the arguments and environment values. If it finds it, the text
			will be replaced with 'DONE':

				export MYTEST=FIXME
				testontap --verbose suite-2 fee FIXME foo

			Note: the above can be simplified to setting an environment variable
			just for the given command:
			
				MYTEST=FIXME testontap --verbose suite-2 fee FIXME foo
				
			The argument list should now be 'fee DONE foo', and the environment
			variable MYTEST should be equal to 'DONE'.

3) END

	Massaging the arguments and environment is likely not to be needed by most,
	but the feature is there if needed.
	
	For completeness, a configuration of 'postprocess' is also possible. It
	will run last and can be used for various forms of cleanup not done as
	part of testing (e.g. consider a run that only runs a specific test using
	--include, which will run dependencies, but no other tests after).
