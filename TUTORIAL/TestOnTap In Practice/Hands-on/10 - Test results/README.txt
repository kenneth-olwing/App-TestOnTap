HANDS-ON: TEST RESULTS
======================

1) OBJECTIVE

	The objective is to run a simple suit and persist the overall results.

	Such results may be used/analyzed later.

2) THE SUITE

	The test suite is the same as in 'Arguments and environment'.
			
3) RUN THE SUITE

	For this hands-on, as discussed there are up to four flags that are of
	interest:
	
		* --archive
		* --savedirectory
		* --workdirectory
		* --define
		
	Run the suite (supply a convenient directory to save to):
	
		testontap --savedirectory /tmp suite fee fie foo
	
	The suite will be run as before, but the tree will be copied to /tmp with a
	generated name shown.
	
4) EXPECTED RESULTS

	The expected output should be like this, on all platforms:
	
		test.t .. ok
		All tests successful.
		Files=1, Tests=1,  0 wallclock secs ( 0.02 usr  0.24 sys +  0.01 cusr  0.01 csys =  0.28 CPU)
		Result: PASS
		Result saved to '/tmp/suite.20171027T072334Z.be12de60-bae7-11e7-aa30-82d16bfe0d21'

	Note the directory name. This consists of three parts, all also available in
	the tree.
	
		* The name of the suite: suite
			
			While this isn't necessarily unique and can be changed, it makes
			identification of a result easier.
			
		* A timestamp when the suite was run: 20171027T072334Z
		
			This is in ISO8601 format, more specifically date (YYYYMMDD), a
			separator (T), a time (HHMMSS) and lastly a timezone indicator
			(Z, i.e. UTC).
			
		* A 'run id': be12de60-bae7-11e7-aa30-82d16bfe0d21
		
			This is a UUID, giving this test run a unique identity (note
			that this is something different from the suite id).
			
	If using the --archive flag, the zip file would be named similarly and
	using the suffix '.zip'. It does contain the savedirectory with the
	same naming so unpacking the zip will look exactly as using --savedirectory
	would have stored it.
	
5) EXPLORING THE RESULT TREE

	The result tree will look like this:
	
		/tmp/suite.20171027T072334Z.be12de60-bae7-11e7-aa30-82d16bfe0d21
		+--suite
		\--testontap
		   +  env.json
		   +  meta.json
		   +--result
		   |  \  test.t.json
		   +  summary.json
		   +--tap
		   |  \  test.t.tap
		   \  testinfo.json

	Result files from testontap are always in json (UTF-8), except for the
	'.tap' files.
	
	Files in the testontap directory:
	
		* env.json – what the environment looked like when running tests
		* meta.json – various metadata about the test run
		* summary.json – a summary of statistics for all tests
		* testinfo.json – mostly information of a debugging nature

	Files in the 'result' directory:
	
		One for each of the tests, in the same structure – a summary of
		statistics for that particular test
		
	Files in the 'tap' directory:
	
		One for each of the tests, in the same structure but with '.tap'
		suffixed – the raw output for that particular test.
		
		In particular, note that it also contains the '#' lines even though they,
		were not shown when not verbose.
		
	Files in the 'suite' directory:
	
		Tests may write any information here that they deem interesting
		for future analysis

6) EXTRA CREDIT

	Open and examine the files in detail. More information on fields is
	available in https://metacpan.org/pod/App::TestOnTap.

7) END

	What to do with the results is up to you. A suggestion is to feed
	result archive files to a database and provide a web UI on top for
	visualization.


