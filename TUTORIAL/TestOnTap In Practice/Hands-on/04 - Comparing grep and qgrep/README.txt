HANDS-ON: COMPARING GREP AND QGREP
==================================

1) OBJECTIVE

	The objective is to provide a simple way to evaluate the Grep::Query
	language, not to advocate replacement of grep in any way.

2) THE LIST_OF_ANT_TREE FILE

	The list_of_ant_tree file is provided as something to use as material
	to search in. It was produced on a Linux host with this:
	
		find /ant -printf '"%p" ' | xargs ls -dp >list_of_ant_tree
		
	The main idea here is to ensure all directories end with '/' in order
	to help searching the material.
	
3) SOME EXAMPLES

	Below are some example queries, first using grep and then qgrep.
	
	Find all directory lines:
	
		* grep '/$' list_of_ant_tree
		
		* qgrep 'regexp(/$)' list_of_ant_tree
	
	This simple example makes the qgrep command slightly more complex than for
	grep, but since it's using a 'function', it hints that there are more
	possibilities.
	
	Find a specific line:
	
		* grep '^/ant/etc/ant-bootstrap.jar$' list_of_ant_tree
		
		* qgrep 'eq(/ant/etc/ant-bootstrap.jar)' list_of_ant_tree
		
			Instead of making an exact regexp, we do a string compare using the 'eq()' operator.
	
	Searching for lines containing either 'xalan' or 'bcel':
	
		* grep 'xalan\|bcel' list_of_ant_tree
		
			For grep, the '|' must be escaped. Use 'egrep' to avoid that.
			
		* qgrep
		
			This will be shown in two variants. The first is basically the same
			as grep:
			
				qgrep 'regexp(xalan|bcel)' list_of_ant_tree
				
			However, since it's a language with logical operators, this will
			work equally well and may be clearer to some:
			
				qgrep 'regexp(xalan) or regexp(bcel)' list_of_ant_tree

			It is not quite as efficient however, but is not normally
			detectable.
			
	Finding lines that match more than one thing can sometimes be challenging
	to write a single regexp for, so with grep it's sometimes easier to just
	string a pipeline together with simpler regexps that whittles down the
	input:
	
		* grep '\.html$' list_of_ant_tree | grep -v '[A-Z]'
		
			Yes, this can be written simpler, but imagine more complex regexps...
			
		* qgrep 'regexp(\.html$) and not regexp([A-Z])' list_of_ant_tree
		
			With qgrep, it's natural to use a logic expression.
			
	Here's a contrived example:
	
		* grep ???
		
			 I don't know how to express this in a (oneliner) grep...
	
		* qgrep 'not regexp(/$) and (regexp(apache) and not (regexp(\.html$) or (regexp(\.pom$) and not regexp(xalan))))' list_of_ant_tree
		
4) EXTRA CREDIT

	Experiment with other queries.

5) END

	In this case, most examples are contrived and although qgrep might
	sometimes provide an edge in complex situations, this is not the
	point.
	
	The library function interpreting the query is embedded in TestOnTap
	and so it allows users to provide succinct and readable queries for
	various things.
