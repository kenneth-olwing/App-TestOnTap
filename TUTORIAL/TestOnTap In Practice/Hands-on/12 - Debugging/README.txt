HANDS-ON: DEBUGGING
===================

1) OBJECTIVE

	The objective of this hands-on is to show how tests in a suite can be
	debugged.

	We're obviously testing to find bugs in a given product. However, tests are
	code too, and sometimes it can be difficult to figure out if the product
	actually have a bug or if it the test itself that is misinterpreting
	something - in short, tests may the code containing a bug.

	A large part of interpreting a test failure is to ascertain where the
	problem lies. Two main techniques exist:

		* Print statements

			The tried and true method: embed output in the tests to trace what
			happens at various places.

		* Real-time debugging

			Sometimes the above is not enough - in trickier cases, you might
			need to follow the test execution in real-time, single-stepping
			instructions.

2) THE SUITE

	The test suite is a large suite variant.

	Run the suite:

		testontap largesuite

	Clearly, two of the tests stand out as reporting failures (yes, I know,
	the	problems are quite contrived, but for educational purposes they'll
	have to do :-). The summary shows clearly which tests failed and which
	microtests allowing us to have a chance of navigating the code.

		* xeq_cmd.t fails the only test it has

			The test is labeled 'Correct exit code'. It looks like it's trying
			to execute some external command, but gets back an unexpected exit
			code.

		* verify_sqrt.t fails two of three tests

			The failing tests are labeled '2 equals 2' and 'Product equals
			2.0000000000000000 (decimal string)'. For some reason some
			comparisons fails when verifying the operations of sqrt().

	2.3) XEQ_CMD.T

		The interesting code looks like this:

			my $cmd = qq/perl -e "print q(Hello world\n); exit(42):"/;
			my @output = qx($cmd 2>&1);
			my $exitcode = $? >> 8;

			my $not = $exitcode == 42 ? '' : 'not ';
			print "${not}ok 1 - Correct exit code\n";

			open(my $fh, '>', "$ENV{TESTONTAP_TMP_DIR}/xeqcmd.log") or die $!;
			print $fh "Got exitcode: '$exitcode'\n";
			print $fh "OUTPUT:\n";
			print $fh "======\n";
			print $fh @output;
			close($fh);

		Basically, it runs a command, capturing the output and the exit code.
		It tests the exit code for the expected value which is what triggers
		the failure. However, it also uses the TESTONTAP_TMP_DIR environment
		variable to write a simple log of what happened here.
		
		Let's zero in on that test. In order to capture the log, we need to see
		the result tree, but since the 'tmp' part is not preserved in a result
		archive, we need to see the raw work tree:
		
			testontap --workdirectory /tmp/xeq_cmd_work --include 'regexp(xeq)' largesuite
			
		Checking the log reveals the problem:
		
			Got exitcode: '255'
			OUTPUT:
			======
			syntax error at -e line 2, near "):"
			  (Might be a runaway multi-line () string starting on line 1)
			Execution of -e aborted due to compilation errors.

		It's a simple syntax error; it should end with a semicolon rather than
		a colon:
		
			my $cmd = qq/perl -e "print q(Hello world\n); exit(42);"/;

		Rerunning it after fixing should make it pass and the log should be clean.

	2.3) VERIFY_SQRT.T

		The interesting code looks like this:
		
			my $product = sqrt(2) * sqrt(2);

			my $not = $product == 2 ? '' : 'not ';
			print "${not}ok 1 - $product equals 2\n";

			my $intproduct = int($product);
			$not = $intproduct == 2 ? '' : 'not ';
			print "${not}ok 2 - Product equals 2 (integer number)\n";

			my $stringproduct = sprintf("%.16f", $product);
			$not = $stringproduct eq '2.0000000000000000' ?  '' : 'not ';
			print "${not}ok 3 - Product equals 2.0000000000000000 (decimal string)\n";

		No logging in this code, except for the labels. And that is
		interesting: when comparing the product to '2', it fails. Yet, the
		message prints just '2'.
		
		To accurately track down find the problem we need to attach the Perl
		command line debugger (a graphical debugger would work too, but with
		a different approach). However, the Perl debugger needs to allow
		interaction with the debugged program, while leaving stdout/err
		untouched. When using TestOnTap, it attaches a TAP 'harness' that
		interprets the test protocol.
		
		So, the first requirement is to remove that, and this mode is reached
		using --no-harness flag:
		
			testontap --include 'regexp(sqrt)' --no-harness largesuite
			
		The flag disables the harness, but also other things such as timers,
		parallelization, verboseness etc. It doesn't disable dependencies
		however, since 'init.t' is run despite the --include.
		
		If you like, try the above without the --include flag, and you'll
		see every test spew it's output, as they look in the raw.
		
		The output clearly shows how a test is run, in this case, slightly
		simplified 'perl verify_sqrt.t'. This obviously comes from the execmap
		in the configuration. To use the Perl debugger however, we need to 
		start the script with 'perl -d'. How do we get that to happen? There
		are two assumptions:
		
			* We don't want to change/edit the suite
			* We don't want to debug every test (e.g. any dependencies)
			
		The solution is to use an override for the configuration in the suite with
		a custom one. Copying the suites config.testontap to debug.cfg we
		can make the following changes to the execmapping:

			...
			# add a new execmap in front of the previous
			execmap = files_to_debug t-files

			# here it is
			[EXECMAP files_to_debug]
			match = eq(verify_sqrt.t)
			cmd = perl -d

			# this is as before
			[EXECMAP t-files]
			match = regexp(\.t$)
			cmd = perl
			...

		This execmap will only give the special command for the exact test
		using the rules in 'files_to_debug'. Any other test will be resolved
		by the rules in 't-files', just as before.
		
		Now run it:
		
			testontap --include 'regexp(sqrt)' --no-harness --configuration debug.cfg largesuite
		
		Notice that init.t is run normally, but verify_sqrt.t is loaded into
		the debugger, and it's now waiting on the first executable line, line
		number 4. Run the script to the last line (19):
		
			c 19
		
		It now shows us positioned at line 19, and it has just evaluated a 
		comparison that somehow fails. Check the result of the comparison:
		
			x $not
			
		This prints the contents of the $not variable - it is 'not ',
		indicating that the comparison failed. Hmm. Print the product:
		
			x $product
			
		It shows the integer 2. So it should be the same as the float
		value. What is that?
		
			x $stringproduct
			
		And this shows the problem: it's not a 2 with 16 decimals of 0, it ends
		with a 4. This is a result from the fact that sqrt(2) is not an exact
		value, and multiplying the two values causes a floating point
		imperfection.
		
3) END

	This shows that tests are not always bugfree and that we may need various
	mechanisms to root them out.
