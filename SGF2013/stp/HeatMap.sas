/** Get measures from cube**/
%put **** Getting data from Cube...;
proc sql;
connect to olap (host= "enterprise" port=5451);

	/*	Pull key metrics to show */
	create table TransactionsByState as select * from connection to olap
	(
	  SELECT {[Measures].[Transaction Amount] } ON COLUMNS,
           {[Location].[All States].Children } ON ROWS
    FROM [Transaction Summary]
    WHERE [Transaction Month Year].[All Years].[Rolling 18 Months]
	)
	;

disconnect from olap;
quit;

data TransactionsByState;
  set TransactionsByState (rename=('Transaction Amount'n=TransactionAmount State=STATECODE));
run;

/*Get map data from internal SAS library*/
data mapbase;
	merge maps.us maps.us2(keep=state statecode);
	by state;
	statecode = upcase(statecode);
run;


ods listing close;
ods html body=_webout path=&_tmpcat(url=&_replay) style=Seaside parameters=("drilltarget"="_top") codebase="http://www2.sas.com/codebase/graph/v92/sasgraph.exe#version=9,2";

/* To have the SASgraph component load automatically in the browser use this code base command with the ODS statement: */
/*codebase="http://www2.sas.com/codebase/graph/v92/sasgraph.exe#version=9,2"*/
 
goptions device=ACTIVEX hsize=5in vsize=3in;
Legend1
      CSHADOW=GRAY
      LABEL=(FONT='Microsoft Sans Serif' HEIGHT=12pt);
TITLE;
TITLE1 "Yesterday &measure by Region";
*TITLE2 "&max_date";
FOOTNOTE;

proc gmap all map=mapbase data=TransactionsByState;
	id statecode;
	choro TransactionAmount / discrete ;
run;
quit;

ods html close;
ods listing;

/*%stpend;*/


