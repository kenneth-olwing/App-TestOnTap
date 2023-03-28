HANDS-ON: QUICKSTART
====================

1) OBJECTIVE

	The objective is simply to try out the simplest possible test suite.

	It illustrates some basic facts and features about TestOnTap, but also shows
	that there are some things that while not absolutely necessary, a few more
	pieces are recommended.

2) THE SUITE

	The test suite can be called anything, here we use the name 'mycoolsuite';
	simply create a directory with that name.

	Here we try with a simple Perl script, but assuming we didn't have any other
	language to use, we could have used more native facilities - e.g. batch files
	for Windows and shell scripts for UNIX.

	2.1) config.testontap
	
		This is a file required to make TestOnTap acknowledge this as a suite.
		However, we can start with an empty file (well, just a comment :-)...:
		
			# empty
		
	2.2) mycooltest.pl

			print "1..1\n";
			print "ok 1 Hello world\n";

	It uses the absolute minimum of the testing protocol "TAP", generating a line
	with test plan (1..1 means 'I will execute one test'), and then a line reporting
	the results of that only 'test' as having gone ok, including a message.

3) RUN THE SUITE

	At this point, all you need to do is to run the testontap command and point
	it to the suite:

		testontap mycoolsuite

	TestOnTap will scan the suite and find all files it knows what to do with
	and execute them as tests.
	
4) EXPECTED RESULTS

	The expected output should be similar to this:
	
	WARNING: No id found, using generated 'c909bc9e-c2e4-11e7-8f58-dfe4414c0996'!
	WARNING: No execmap found, using internal default!
	mycooltest.pl .. ok
	All tests successful.
	Files=1, Tests=1,  0 wallclock secs ( 0.05 usr +  0.02 sys =  0.06 CPU)
	Result: PASS

5) EXTRA CREDIT

	Feel free to experiment, for example by turning the microtest into a fail
	('not ok' instead of 'ok').
	
	Also try running with a timer printout and/or verbose:
	
		testontap --timer mycoolsuite
		testontap --verbose mycoolsuite
	
6) END

	It should be clear that you could in principle start writing tests to
	your hearts content, in any language as long as you stick to the same
	pattern.
	
	But there are clearly some rough edges: some warnings about an id and an
	execmap, for example.
