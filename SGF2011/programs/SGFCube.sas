/**********************************************************/
/*   Code Written by:                                     */
/*      Stephen Overton  (stephen.overton@gmail.com       */
/*      Bryan Stines     (btstines@gmail.com)             */
/*                                                        */
/*   Source data for this cube is derived from the SAS    */
/*   help data (Build Base Table.sas)                     */
/**********************************************************/

OPTIONS VALIDVARNAME=ANY FMTERR;
libname sgf2011 base '/projects/SGF2011/data'; 

/** The "current" time **/
%let maxdate = '06OCT2002'd;

/**** PREPROCESSING STEPS ****/

/* Generates 24 months inclusive of current month */
data rolling24months;
   length mdx $50;
   format date mmddyy10.;
   do x = 0 to 23;
      date = intnx('month', &maxdate , -1 * x);
    mdx = "[Time].[YM].[All YM].[" || strip(put(year(date),4.)) || "].[" || strip(put(date,monname9.)) || "]";
      output;
   end;
   drop x date;
run;
proc sql noprint;
  select mdx into :rolling24months_mdx separated by ', ' from rolling24months;
quit;
%put &rolling24months_mdx;

/* Generates 36 months inclusive of current month */
data rolling36months;
   length mdx $50;
   format date mmddyy10.;
   do x = 0 to 35;
      date = intnx('month', &maxdate , -1 * x);
    mdx = "[Time].[YM].[All YM].[" || strip(put(year(date),4.)) || "].[" || strip(put(date,monname9.)) || "]";
      output;
   end;
   drop x date;
run;
proc sql noprint;
  select mdx into :rolling36months_mdx separated by ', ' from rolling36months;
quit;
%put &rolling36months_mdx;

/* Generates current month and previous year month */
data monthPmonth;
   length year $4 mdx $100;
   format date date9.;
   date = intnx('month', &maxdate, -12);
   mdx = "[Time].[YM].[All YM].[" || strip(put(year(date),4.)) || "].[" || strip(put(date, monname9.)) || "]";
   output;
   date = intnx('month', &maxdate, 0);
   mdx = "[Time].[YM].[All YM].[" || strip(put(year(date),4.)) || "].[" || strip(put(date, monname9.)) || "]";
   output;
run;
proc sql noprint;
  select mdx into :monthPmonth_mdx separated by ', ' from monthPmonth;
quit;
%put &monthPmonth_mdx;

/******** Begin OLAP Code ********/
PROC OLAP
   CUBE                   = "/Projects/SGF2011/Cubes/SGF2011"
   MAX_RETRIES            = 3
   MAX_RETRY_WAIT         = 60
   MIN_RETRY_WAIT         = 30
   DELETE;


   METASVR
      HOST        = "pegasus"
      PORT        = 8561
      OLAP_SCHEMA = "SASApp - OLAP Schema";

RUN;

proc olap
   CUBE                   = "/Projects/SGF2011/Cubes/SGF2011"
   DATA                   = sgf2011.CUBEBASE
   MAX_RETRIES            = 3
   MAX_RETRY_WAIT         = 60
   MIN_RETRY_WAIT         = 30
   PATH                   = '/projects/SGF2011/cubes'
   DESCRIPTION            = 'Demo cube for SAS Global Forum 2011.'
;

   METASVR
      HOST        = "pegasus"
      PORT        = 8561
      OLAP_SCHEMA = "SASApp - OLAP Schema";

   DIMENSION Time
      CAPTION          = 'Time'
      TYPE             = TIME
      SORT_ORDER       = ASCENDING
      HIERARCHIES      = (YM YQM );

      HIERARCHY YM 
         ALL_MEMBER = 'All YM'
         CAPTION    = 'YM'
         LEVELS     = ( Year Month )
         DEFAULT;

      HIERARCHY YQM 
         ALL_MEMBER = 'All YQM'
         CAPTION    = 'YQM'
         LEVELS     = ( Year Quarter Month );

      LEVEL Year
         COLUMN         =  date
         FORMAT         =  YEAR4.
         TYPE           =  YEAR
         CAPTION        =  'Year'
         SORT_ORDER     =  ASCENDING;

      LEVEL Month
         COLUMN         =  date
         FORMAT         =  MONNAME9.
         TYPE           =  MONTHS
         CAPTION        =  'Month'
         SORT_ORDER     =  ASCENDING;

      LEVEL Quarter
         COLUMN         =  date
         FORMAT         =  QTR2.
         TYPE           =  QUARTERS
         CAPTION        =  'Quarter'
         SORT_ORDER     =  ASCENDING;

   DIMENSION Location
      CAPTION          = 'Location'
      SORT_ORDER       = ASCENDING
      HIERARCHIES      = ( Location );

      HIERARCHY Location 
         ALL_MEMBER = 'All Location'
         CAPTION    = 'Location'
         LEVELS     = ( regionName )
         DEFAULT;

      LEVEL regionName
         CAPTION        =  'Sales Region'
         SORT_ORDER     =  ASCENDING;

   DIMENSION Product
      CAPTION          = 'Product'
      SORT_ORDER       = ASCENDING
      HIERARCHIES      = ( Product );

      HIERARCHY Product 
         ALL_MEMBER = 'All Product'
         CAPTION    = 'Product'
         LEVELS     = (productLine productName )
         DEFAULT;

      LEVEL productLine
         CAPTION        =  'Product Line'
         SORT_ORDER     =  ASCENDING;

      LEVEL productName
         CAPTION        =  'Product Name'
         SORT_ORDER     =  ASCENDING;

   DIMENSION ValueType 
      CAPTION          = 'Type'
      SORT_ORDER       = ASCENDING
      HIERARCHIES      = ( ValueType ) ;

      HIERARCHY ValueType 
         ALL_MEMBER = 'All Type'
         CAPTION    = 'Type'
         LEVELS     = ( Type ) DEFAULT;

   MEASURE 'Total Sales'n
      format      = dollar20.0
      STAT        = SUM
      COLUMN      = sales
      CAPTION     = 'Total Sales'
      DEFAULT;

   MEASURE 'Minimum Sales'n
      STAT        = MIN
      COLUMN      = sales
      CAPTION     = 'Minimum Sales';

   MEASURE 'Maximum Sales'n
      format      = dollar20.
      STAT        = MAX
      COLUMN      = sales
      CAPTION     = 'Maximum Sales';

   MEASURE 'Average Sales ($)'n
      format      = dollar20.
      STAT        = AVG
      COLUMN      = sales
      CAPTION     = 'Average Sales ($)';

   MEASURE monthdays
      STAT        = max
      format      = dollar8.
      COLUMN      = monthdays
      CAPTION     = 'monthdays';

   MEASURE yeardays
      STAT        = max
      format      = dollar8.
      COLUMN      = yeardays
      CAPTION     = 'yeardays';

   MEASURE quarterdays
      STAT        = max
      format      = dollar8.
      COLUMN      = quarterdays
      CAPTION     = 'quarterdays';

   MEASURE 'Maximum Employees'n
      STAT        = max
      format      = comma8.
      COLUMN      = employee
      CAPTION     = 'Maximum Employees';

   /************************** Custom measures **********/
   DEFINE Member "[SGF2011].[Measures].[TimeLevel]" AS 
     'iif([Time].[YQM].currentmember.level.Ordinal > 0, "YQM",
        iif([Time].[YM].currentmember.level.Ordinal > 0, "YM",
          "UNKNOWN" ))';

   /** Simple employee count, more advanced later **/
/*DEFINE Member "[SGF2011].[Measures].[Employee Count]" AS*/
/*  'iif(isleaf([Time].[YM].CurrentMember),*/
/*     [Measures].[Maximum Employees], */
/*     ([Time].[YM].LastChild, [Measures].[Maximum Employees])*/
/*   ),  format="comma8."';*/

   DEFINE Member "[SGF2011].[Measures].[Employee Count]" AS
    'iif(isleaf([Time].[YM].CurrentMember) OR isleaf([Time].[YQM].CurrentMember),[Measures].[Maximum Employees] , 
  iif([Time].[YQM].CurrentMember.Level.Name = "Quarter", iif([Measures].[TimeLevel] = "YQM", ([Time].[YQM].LastChild, [Measures].[Maximum Employees]), null),
    iif([Time].[YQM].CurrentMember.Level.Name = "Year" OR [Time].[YM].CurrentMember.Level.Name = "Year",
      iif([Measures].[TimeLevel] = "YM", ([Time].[YM].LastChild, [Measures].[Maximum Employees]), iif([Measures].[TimeLevel] = "YQM", ([Time].[YQM].LastChild.LastChild, [Measures].[Maximum Employees]), null)), null))
),  format="comma8.0"';
   
   /* Sales annualization */
   DEFINE Member "[SGF2011].[Measures].[Monthly Annualization]" AS 
     '([Measures].[Total Sales] / [Measures].[monthdays]) * [Measures].[yeardays], format="dollar20.0"';

   DEFINE Member "[SGF2011].[Measures].[Quarter Annualization]" AS 
     '([Measures].[Total Sales] / [Measures].[quarterdays]) * [Measures].[yeardays], format="dollar20.0"';

   DEFINE Member "[SGF2011].[Measures].[Annualized Sales]" AS 
     'iif([Time].[YQM].CurrentMember.Level.Name="Month", [Measures].[Monthly Annualization] , 
        iif([Time].[YQM].CurrentMember.Level.Name="Quarter",[Measures].[Quarter Annualization], [Measures].[Total Sales]
        )), format="dollar20.0" ' ;

   /** Percent of Total - Kept simple without dynamic hierarchy selection since measure above demonstrates it **/
   DEFINE Member "[SGF2011].[Measures].[Percent of Total Sales]" AS 
   '([Product].[Product].CurrentMember, [Measures].[Total Sales])/
    iif(([Product].[Product].CurrentMember.Parent, [Measures].[Total Sales]) = 0 OR ([Product].[Product].CurrentMember.Parent, [Measures].[Total Sales]) = NULL,
      ([Product].[Product].CurrentMember, [Measures].[Total Sales]),
      ([Product].[Product].CurrentMember.Parent, [Measures].[Total Sales])),FORMAT_STRING="PERCENT10.2" ' ;

   DEFINE Member "[SGF2011].[Measures].[Restricted Total Sales]" AS 
     'iif([Measures].[Total Sales]<50000,NULL,[Measures].[Total Sales]),FORMAT_STRING = "DOLLAR20.0"';

   /******************** Calculated Members *********************/
   /* manual 12 month rolling aggregation */
   DEFINE MEMBER "[SGF2011].[Time].[YM].[All YM].[12 Months]" AS
      'Aggregate(
       {
         [Time].[YM].[All YM].[2001].[November],
         [Time].[YM].[All YM].[2001].[December],
         [Time].[YM].[All YM].[2002].[January],
         [Time].[YM].[All YM].[2002].[February],
         [Time].[YM].[All YM].[2002].[March],
         [Time].[YM].[All YM].[2002].[April],
         [Time].[YM].[All YM].[2002].[May],
         [Time].[YM].[All YM].[2002].[June],
         [Time].[YM].[All YM].[2002].[July],
         [Time].[YM].[All YM].[2002].[August],
         [Time].[YM].[All YM].[2002].[September],
         [Time].[YM].[All YM].[2002].[October]
       })';

   /* pre-processing 24 month rolling aggregation */
   DEFINE MEMBER "[SGF2011].[Time].[YM].[All YM].[24 Months]" AS
      "Aggregate( {&rolling24months_mdx} )";

   /* pre-processing 36 month rolling aggregation */
   DEFINE MEMBER "[SGF2011].[Time].[YM].[All YM].[36 Months]" AS
      "Aggregate( {&rolling36months_mdx} )";

   /* Grouping years into a bucket */
   DEFINE MEMBER "[SGF2011].[Time].[YM].[All YM].[Pre 2000]" as 'Aggregate( {[Time].[YM].[All YM].[1998], [Time].[YM].[All YM].[1999]} )';

   /********************** Custom Member Sets ***********************/

   /* pre-processing current month and prior year month comparison */
   DEFINE SET '[SGF2011].[Latest Month and PY Month]' as "{&monthPmonth_mdx}";

   /* groups custom member above with a member set */
   DEFINE SET '[SGF2011].[Special Year View]' as "
      {
         [Time].[YM].[All YM].[Pre 2000],
         [Time].[YM].[All YM].[2000],
         [Time].[YM].[All YM].[2001],
         [Time].[YM].[All YM].[2002]
      }";

   /** Rolling time based member sets **/
   DEFINE SET '[SGF2011].[Last 6 Quarters]' as "Tail([Time].[YQM].[Quarter].AllMembers ,6)";

   DEFINE SET '[SGF2011].[Rolling 6 Months]' as "Tail([Time].[YM].[MONTH].AllMembers ,6)";

   DEFINE SET '[SGF2011].[Rolling 13 Months]' as "Tail([Time].[YM].[MONTH].AllMembers ,13)";

RUN;


PROC OLAP CUBE= "/Projects/SGF2011/Cubes/SGF2011";

   METASVR
      HOST        = "pegasus"
      PORT        = 8561
      OLAP_SCHEMA = "SASApp - OLAP Schema";

   AGGREGATION Year Month productLine productName regionName
      / NAME      = 'Monthly Reporting 1';
   AGGREGATION Year Month regionName Type
      / NAME      = 'Monthly Reporting 2';
   AGGREGATION Year Month productLine Type
      / NAME      = 'Monthly Reporting 3';
   AGGREGATION Year Month  
      / NAME      = 'Top Month Level';

RUN;
