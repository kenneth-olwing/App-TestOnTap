HANDS-ON: CONTROLLING THE SCAN
==============================

1) OBJECTIVE

	The objective is to illustrate that some suites may contain things that
	should be ignored by TestOnTap because they are not valid tests even if they
	might look like that using the active execmap.

	It's common in a test suite to bring along various test data that are
	intended to be used by the tests, not be executed as tests themselves.

2) THE SUITE

	The suite here is very simple, but contains a non-test file as well as a
	data subdirectory holding an unfinished test.

	2.1) SUITE-1

		Run the suite:

			testontap suite-1

		While the single test 'test.t' works as expected, there's a whole lot of
		errors concerning the test data/experimental.t. The obvious sign is
		reports of 'syntax error' causing the TAP harness to complain that it
		isn't too sure of what happened and that it can't really find any TAP
		nor any exit code, a fact also reported in the summary.

		The reason is of course that data/experimental.t is only just test data
		rather than a valid (Perl) program.

		We must avoid scanning the data directory.

	2.2) SUITE-2

		In this suite we've added a skip directive to the configuration:

			skip = regexp(^data/) or eq(INFO.txt)

		Yet again a query. Skip the 'data' directory and everything below it as
		well as the (otherwise ignored by default) INFO.txt file.

		Run the suite:

			testontap suite-2

		It now runs normally.

3) END

	Being clear in what you expect will help prevent weird problems later and
	may also make the suite scan faster.
