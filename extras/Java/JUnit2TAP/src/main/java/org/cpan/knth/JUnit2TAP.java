package org.cpan.knth;

import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class JUnit2TAP
{
	static public void main(String... args)
	{
		List<String> classnames = new ArrayList<String>();
		int verbosity = 0;
		Pattern verbosityPattern = Pattern.compile("^verbosity=(\\d+)$");
		for (String arg : args)
		{
			Matcher m = verbosityPattern.matcher(arg);
			if (m.matches())
				verbosity = Integer.parseInt(m.group(1));
			else
				classnames.add(arg);
		}
		
		boolean ok = false;
		try
		{
			ok = JUnit2TAPRunner.run(verbosity, classnames.toArray(new String[0]));
		}
		catch (Exception e)
		{
			System.err.println(e);
		}

		System.exit(ok ? 0 : 1);
	}
}
