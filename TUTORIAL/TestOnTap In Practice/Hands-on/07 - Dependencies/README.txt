HANDS-ON: DEPENDENCIES
======================

1) OBJECTIVE

	The objective is to demonstrate how the addition of dependencies between
	tests can make a suite retain order even when being run parallelized.

2) THE SUITES

	The suites are based on a variation of the first 'Basic ordering' suite,
	e.g. they are not divided into subdirectories in order to rely on sorted
	order (but the 'natural' order is configured) and there are more testdb
	tests.

	2.1) SUITE-1

		Run the suite with and without parallelization:

			testontap suite-1
			testontap --jobs 50 suite-1

		It's clear that in either case, ordering is not as desired. And, as
		we've seen, even if we reintroduce the subdirectory organization,
		ordering will not work in the face of parallelization.

		We need to declare dependencies.

	2.2) SUITE-2

		Dependencies are declared with multiple 'DEPENDENCY' sections in the
		configuration. The workhorse is, again, queries to make selections.

		TestOnTap will calculate a proper run order that takes all
		dependencies into account. If dependencies end up declaring a circle
		(e.g. A depends on B depends on C depends on A), it's an error.

		2.2.1) DEPENDENCY SECTIONS

			Recall that the rules are fairly simple: createdb must run first and
			deletedb must run last, all testdb are fair game for running in any
			order.

			The following is added to the configuration:

				[DEPENDENCY First]
				match		= not eq(createdb.t)
				dependson	= eq(createdb.t)

				[DEPENDENCY Last]
				match		= eq(deletedb.t)
				dependson	= not eq(deletedb.t)

			As can be seen, a dependency section is typically named ('First' and
			'Last'). This is only used for error reporting (e.g. the circle
			dependency above).

			They contain two keys, 'match' and 'dependson', both of which should
			be queries.

			The match query should select one or more tests, and those will have
			a dependency on whatever tests are selected by the dependson query.

			Now run the suite with a varying amount of job slots:

				testontap --jobs=1 suite-2
				testontap --jobs=2 suite-2
				testontap --jobs=5 suite-2
				testontap --jobs=50 suite-2

			Observe the behavior - in all cases the desired order for createdb
			and deletedb is maintained. The testdb tests however run in
			different orders all the time. This is because a) it is sensitive to
			how many slots are in use, and b) it depends on how long time each
			test runs for, and c) it depends on if a given test is
			parallelizable or not.

			So scheduling of tests occurs when a job slot becomes available, and
			then the next eligible test is dispatched. In those cases there are
			more than one eligible test possible, then and only then, the sort
			order is used as an arbitrator.

		2.2.2) INCLUDING/SKIPPING TESTS

			Another aspect that is affected is using the '--include' or '--skip'
			mechanism. Consider the desire to run only a specific test:

				testontap --jobs 50 --include 'eq(testdb5.t)' suite-2

			Regardless of the query, dependencies are always followed. In this
			case the createdb test is also executed.

3) EXTRA CREDIT

	Create a chokepoint in the tests by specifying a testdb test that is not
	parallelizable. What happens?

	Consider the utility of using '--order random'. Why would this be useful?
	
4) END

	With a simple declarative mechanism, we can ensure a test order in a suite
	that will work in all cases.

