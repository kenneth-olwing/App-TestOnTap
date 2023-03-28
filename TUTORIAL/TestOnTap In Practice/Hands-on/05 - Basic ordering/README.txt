HANDS-ON: BASIC ORDERING
========================

1) OBJECTIVE

	To demonstrate how tests in a suite by default run in an unpredictable
	order and how to make the order predictable by configuration.

	Not all suites need a predictable order, but for those that do, this
	is one way to achieve it.

2) THE SUITE

	The suite consists of the following tests:

		createdb.t
		testdb1.t
		testdb2.t
		testdb10.t
		deletedb.t

	The important ordering here is that:

		* The createdb test must always run first
		* The testdb tests may run in any order
		* The deletedb test must always run last

	3.1) SUITE-1

		This suite contains a minimum configuration (suite id) and an execmap.

		3.1.1) DEFAULT 'ORDER'

			Run suite-1 multiple times:

				testontap suite-1
				testontap suite-1
				testontap suite-1
				...

			Observing the output, it's likely that the order of the tests are
			ever-changing and thus frequently wrong, compared to the desired
			order.

			This is how TestOnTap works by default - the suite is scanned for
			eligible tests and then executed in a non-predictable order.

			The solution is to request a specific order.

		3.1.2) ALPHABETIC ORDER

			To test for the order we want, use a command line argument, again
			multiple times:

				testontap --order alphabetic suite-1
				testontap --order alphabetic suite-1
				testontap --order alphabetic suite-1
				...

			The order is now the same every time, i.e. it's now predictable.
			However, the order is obviously still wrong as the names simply
			doesn't sort right - the deletedb test always follow createdb test
			rather than after all testdb tests.

			The solution is obviously to rename the tests so they sort
			correctly. Since TestOnTap allows any shape or form of the suite
			tree, here we will use this fact (there are other ways to rename the
			tests, but with some caveats - e.g. numbering can trip you up).

	3.2) SUITE-2

		This is basically the same suite, except:

			* Configured order

				To avoid having to use the command line flag every time the
				order has been put in the configuration

			* Three subdirectories A, B and C have been created

				The tests have been organized into the subdirectories making
				their names be:

					A/createdb.t
					B/testdb1.t
					B/testdb2.t
					B/testdb10.t
					C/deletedb.t

		Run suite-2 repeatedly:

			testontap suite-2
			testontap suite-2
			testontap suite-2
			...

		As can be seen, it's now predictable and correct.


4) EXTRA CREDIT

	One little niggling detail may disturb a sensitive eye: notice that the
	alphabetic sort order doesn't do a good job with the numbered tests - the
	order is 1, 10, 2 when it would be more natural with 1, 2, 10.

	A common and adequate solution would be to rename them using 01, 02, 10,
	so they show up in that order. However, TestOnTap also has a sort order
	called 'natural'. Test suite-2 from the command line and then reconfigure it
	to use this order.

5) END

	The lesson here is that if the suite has an ordering requirement it is up to
	you to make that happen, using some work and some features from TestOnTap.

	However, it should be obvious that this is a fairly crude mechanism that can
	become cumbersome. And worse, it will break down in the face of another
	feature...



