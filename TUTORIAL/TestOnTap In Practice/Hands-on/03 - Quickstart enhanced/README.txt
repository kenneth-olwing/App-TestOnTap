HANDS-ON: QUICKSTART ENHANCED
=============================

1) OBJECTIVE

	The objective is to flesh out the previous hands-on with a minimal
	configuration.

	It illustrates how to fix the perceived issues.

2) THE SUITE

	The test suite can be called anything, here we use the name 'mycoolsuite',
	simply create a directory with that name.

	This suite example is very similar to before but is now properly configured.
	The test script is the same, except that it now uses a different extension
	(.t) - it's still a normal Perl file, the ’.t’ suffix is just common for
	tests in that world. It also contains a readme text file.

	2.1) README.txt

			This is our cool suite

	2.2) mycooltest.t

		This is a Perl file intended for any environment having a Perl
		interpreter:

			print "1..1\n";
			print "ok 1 Hello everyone\n";

	2.3) config.testontap

		This file contains configuration directives for TestOnTap:

			# unique id, don’t reuse this one!
			id = 7392112d-b3f0-11e7-a969-d7d08a113f8a

			# express an execmap so we know exactly what is run
			execmap = t-files

			[EXECMAP t-files]
			match = regexp(\.t$)
			cmd = perl

	The configuration, briefly, declares an id to be used as the suite id (and
	thus should never be reused elsewhere, nor changed as long as the suite
	remains logically the same suite. It also is explicit in what files are
	counted as tests and how they should be executed.

3) RUN THE SUITE

	At this point, all you need to do is to run the testontap command and point
	it to the suite:

		testontap mycoolsuite

	TestOnTap will scan the suite and find all files it knows what to do with
	and execute them as tests. This time however, the execmap in use only knows
	about files ending in '.t', so only that test is executed, using 'perl'.

4) EXPECTED RESULTS

	The expected output should be like this, on all platforms:

		mycooltest.t .. ok
		All tests successful.
		Files=1, Tests=1,  0 wallclock secs ( 0.04 usr  0.16 sys +  0.00 cusr
		0.01 csys =  0.21 CPU)
		Result: PASS

	Note that the warning is gone.

5) EXTRA CREDIT

	Feel free to experiment, perhaps by adding more '.t' files.

	You may also package a suite in a zip file. If you have the 'zip' command,
	try:

		zip -r mycoolsuite.zip mycoolsuite

	The zip file can now be used directly with identical results:

		testontap mycoolsuite.zip

	Assuming you had a webserver, you could even read it directly from that,
	e.g.:

		testontap http://somewhere/suites/mycoolsuite.zip

6) END

	The suite is now more clean, and again, this could be all you need to
	write all the tests you need.

