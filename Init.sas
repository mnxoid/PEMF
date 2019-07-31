options mstored sasmstore=TEMP;

/* Ici on met des variables qui doivent être utilisées dans les autres elements du flux de processus */
%let debug = FALSE;
%let debug_fusion = FALSE;
%let final_cleanup = FALSE;
/* Fin de zone de définition des variables */

proc sql;
	create table TEMP.MACRO as
	select *
	from DICTIONARY.MACROS
	where scope="GLOBAL";
quit;

/* Dans ce macro on met des macro fonctions utilisées dans les autres elements de flux du processus */
%macro load_stored_functions / store;
	%put #------------------------------------------#;
	%put | SAS Enterprise Guide                     |;
	%put | Parallel Execution Macro Framework       |;
	%put |                                          |;
	%put |                           made by mnxoid |;
	%put #------------------------------------------#;
	%put | Loading stored functions                 |;

	%put | > Loading load_libs(table)               |;
	%macro load_libs(table);
		data _null_;
			set &table.;
			x = libname(lname, lpath);
		run;
	%mend load_libs;

	%put | > Loading load_macros(table)             |;
	%macro load_macros(table);
		options nonotes;
		%put #------------------------------------------#;
		%put | Loading missing macro variables          |;
		ods exclude all;
		proc sql;
			create table MISSING_MACRO as
			select a.*
			from &table. a
				left join DICTIONARY.MACROS b
					on   a.name = b.name
					and a.scope = b.scope
			where b.name = "";
		quit;
		ods exclude none;
		data _null_;
			set MISSING_MACRO;
			call symputx(name, value, "G");
			x = "| > " || put(name, $38.) || " |";
			put x;
		run;
		%put | Missing macro variables loaded           |;
		%put #------------------------------------------#;
		options notes;
	%mend load_macros;


	%put | > Loading dbg_limit(nrows)               |;
	%macro dbg_limit(nrows);
		%if &debug eq TRUE %then %do;
			%str(fetch first &nrows. rows only)
		%end;
	%mend dbg_limit;

	%put | > Loading dbg_limit_obs(nrows)           |;
	%macro dbg_limit_obs(nrows);
		%if &debug eq TRUE %then %do;
			%str(outobs=&nrows.)
		%end;
	%mend dbg_limit_obs;

	%put | > Loading map(list, fn, index=FALSE)     |;
	%macro map(list, fn, index=FALSE);
		%local i;
		%do i=1 %to %sysfunc(countw(&list));
			%if &index=FALSE %then %do;
				%&fn.(%scan(&list, &i))
			%end; %else %do;
				%&fn.(%scan(&list, &i), &i)
			%end;
		%end;
	%mend map;

	%put | > Loading contains(list, x)              |;
	%macro contains(list, x);
		%eval(%sysfunc(findw(&list., &x.)) > 0)
	%mend contains;

	%put | > Loading get_vars(lib, table, var)      |;
	%macro get_vars(lib, table, var);
		options nonotes;
		%put #------------------------------------------#;
		%put | Getting variables:                       |;
		%global &var.;
		proc contents data=&lib..&table. out=__varlist (keep=name varnum) noprint;
		run;

		proc sql;
			select name into :&var.  separated by " "
			from __varlist
			order by varnum;
		quit;

		data _null_;
			set __varlist;
			x = "| > " || put(name, $38.) || " |";
			put x;
		run;
		%put #------------------------------------------#;
		options notes;
	%mend get_vars;

	%put | > Loading get_formats(lib, var)          |;
	%macro get_formats(lib, var);
		options nonotes;
		%put #------------------------------------------#;
		%put | Getting formats:                         |;
		%global &var.;
		proc format library=&lib. cntlout = __fmtlist;
		run;

		proc sql noprint;
			select distinct FMTNAME into :&var. separated by " " from __fmtlist;
		run;
		data _null_;
			set __fmtlist;
			if FMTNAME ne lag(FMTNAME) then do;
				x = "| > " || put(FMTNAME, $38.) || " |";
				put x;
			end;
		run;
		%put #------------------------------------------#;
		options notes;
	%mend get_formats;

	%put | Stored functions loaded                  |;
	%put #------------------------------------------#;
	options nomprint nosymbolgen;
%mend load_stored_functions;

options nomstored;
%SYSMSTORECLEAR;

proc catalog cat=TEMP.SASMACR;
	contents;
	run;
quit;
