HANDS-ON: GUI TESTING
=====================

1) OBJECTIVE

	The objective is to show a very simple way of testing the 'Calculator' app
	in Windows.

	For this we use a copy of AutoIt (https://www.autoitscript.com/site/autoit).

	The au3 script used is fairly naive, and requires the use as either a
	compiled script (with /console) or an AutoIt3 executable marked as a CONSOLE
	application.

2) THE SUITE

	The suite 'suite' only contains a basic configuration mapping '.au3' files
	to the autoit executable, and the 'calculator.au3' script.

	It will attempt to start the Windows Calculator, generate three values and
	internally compute them as '(a + b) * c' and then do the same with the
	calculator, retrieve the calculator result and compare the two for a
	successful test.

3) RUN THE SUITE

	Run the suite:

		testontap -v suite

	Here we run it verbosely to see the numbers expected.

	Avoid touching anything while the test runs as it's sensitive to keeping the
	correct window active etc. Welcome to the world of GUI automation...:-)

6) END

	Automating a GUI is fairly tricky and requires some patience. Make sure to
	review the market for GUI automation tools if you want to use one.

