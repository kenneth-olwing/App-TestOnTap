HANDS-ON: SCALABILITY
=====================

1) OBJECTIVE

	The objective is to show how a suite that started out small and now has
	grown into a large/complex suite can be run more efficiently.

	This is not a panacea - there are many possible factors that will influence
	this feature. In particular, keep in mind that all tests in this example are
	completely fictitious - real life tests tend to take longer...

2) THE SUITES

	The large suite used here has 46 separate tests, where some have just single
	microtests, others use minor randomization for amount of microtests and
	sleep time between microtest.

	A variation of the 'Basic ordering' suite is also used to highlight a
	problem with the scalability approach.

	2.1) LARGESUITE-1

		This variant of the suite has only a basic configuration.

		Run the suite:

			testontap largesuite-1

		You'll find the suite will be run in random order, and likely will take
		somewhere between 100 and 120 seconds to complete.

		The way these particular tests are written, they have no
		interdependencies, so they can be run in parallel.

		So try turning on parallelization by telling TestOnTap how many job
		slots to allocate (default is just one); TestOnTap will try to keep that
		many jobs at work simultaneously.

		If nothing else hinders it, this will dramatically speed up the suite.
		Note that the amount of job slots is only controllable from the command
		line - e.g. setting it to high on a given host may slow down the suite
		simply because of overloading.

		Run the test again with 50 jobs slots (this is probably way too high
		for normal tests):

			testontap --jobs 50 largesuite-1

		However, there is a safety net - TestOnTap will not allow you to run a
		suite in parallel unless the suite declares which test actually are
		parallelizable. Thus, the first line is a warning:

			WARNING: No 'parallelizable' rule found ('--jobs 50' has no
			effect); all tests will run serially!

		And it again runs for the full amount of time - we need to configure the
		parallelizability.

	2.2) LARGESUITE-2

		This variant of the suite now has an added configuration:

			parallelizable = true

		This is in fact a query of test names that can be parallelized, but in
		this case we short circuit the query by matching every name with just
		'true'.

		Run the suite again:

			testontap --jobs 50 largesuite-2

		This time, the tests still - obviously - run in a jumbled order, but now
		the suite ends in the region of 42-50 seconds, slightly less than half
		the previous time.

		2.2.1) INCLUDING/SKIPPING TESTS

			The thing that stands out is that the suit typically ends with the
			test 'long.t', which is very long (e.g. coded to take about 40
			seconds).

			In some cases you might want to run just a subset of tests in a
			suite and so the flags '--include' or '--skip' can be used. Either
			on can be used, they both take a query so it comes down to which
			query is most natural to use (e.g. if you want to say 'I want to run
			this/these tests, '--include' is probably most natural, whereas 'I
			don't want to run this/these tests', '--skip' is more obvious).

			So remove the 'long.t' test from the equation:

				testontap --jobs 50 --skip 'eq(long.t)' largesuite-2

			This drops the running time down to about 12-15 seconds, a quite
			impressive drop.

	2.3) LARGESUITE-3

		A final variant of the suite now tries to take on another wrinkle on
		parallelization: what if you have tests that are parallelizable, but
		only to a certain point?
		
		For this need you may configure 'parallel groups', i.e. certain
		groupings of tests that may only run a maximum number concurrently so
		that even if you have 100 slots available, a group can be constrained
		to only use a fraction.

			[PARALLELGROUP max_2_small_at_a_time]
			match = regexp(small/)
			maxconcurrent = 2

		With this, we constrain all the 'small' tests to a maximum of 2 at a
		time.

		Run the suite again:

			testontap --jobs 50 largesuite-3

		It may not be obvious, but if you observe the 'small' tests you can
		see them run more staggered than in the previous (largesuite-2) run.

	2.4) SUITE

		This is basically the same as in the 'Basic ordering' hands-on, but with
		two changes:

			* It has been configured to allow parallelization for all tests
			* The 'testdb' tests have been slowed down slightly with a random
			wait

		Run the suite normally:

			testontap suite

		It still works fine, just takes a little longer, e.g. 5-10 seconds.

		Now turn on parallelization:

			testontap --jobs 50 suite

		As should be obvious, this destroys our careful setup with ordering
		based on naming - the deletedb test occurs before the testdb tests have
		completed.

		No manner of static ordering can fix this so another ordering mechanism
		is required.

3) EXTRA CREDIT

	Try changing the parallelizable directive in a suite to select only a subset
	of tests that are eligible for parallelization - it's possible to 
	create 'chokepoints' where only a single test is allowed to run.
	However, it also affects test ordering.

4) END

	As noted, parallelization is not possible for all suites depending on
	several factors, but if it is, there is the possibility of large time
	savings so a recommendation is always to strive to make the tests as
	independent as possible.

	However, where there is a need for a specific order for some or all of the
	tests in conjunction with parallelization, there is a need for another
	mechanism than just the 'order' configuration.
