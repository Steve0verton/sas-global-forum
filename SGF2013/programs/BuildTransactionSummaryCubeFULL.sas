/*************************************************************/
/*   Code Written by:                                        */
/*      Stephen Overton  (soverton@overtontechnologies.com)  */
/*                                                           */
/*   Builds a cube for testing and demo purposes using       */
/*   fake transaction data                                   */
/*************************************************************/
LIBNAME defiant ODBC READBUFF=30000 DATASRC=defiant SCHEMA=public;

%let cube = /Projects/SGF2013/Cubes/Transaction Summary;

%put ****** START cube build process ******;
proc olap
   CUBE                   = "&cube"
   DELETE;

   METASVR
      HOST        = "enterprise"
      PORT        = 8561
      OLAP_SCHEMA = "SASApp - OLAP Schema";

run;

options fullstimer fmterr;
options SASTRACE=',,,ds' sastraceloc=saslog nostsuffix;
%let syssumtrace=3;

proc options group=performance; run;

proc olap
   CUBE                   = "&cube"
   PATH                   = '/projects/SGF2013/cubes'
   DESCRIPTION            = 'Transaction Summary demo cube for SGF2013'
   FACT                   = defiant.FACT_TRANSACTIONS
   CONCURRENT             = 2
   ASYNCINDEXLIMIT        = 2
   MAXTHREADS             = 2
   EMPTY_CHAR             = '!UNKNOWN'
   TEST_LEVEL             = 26
;

   METASVR
      HOST        = "enterprise"
      PORT        = 8561
      OLAP_SCHEMA = "SASApp - OLAP Schema";

    DIMENSION Time
      CAPTION          = 'Time'
      TYPE             = TIME
      SORT_ORDER       = ASCENDING
      HIERARCHIES      = ( YMD YQMD MonthYear );

      HIERARCHY MonthYear 
         ALL_MEMBER = 'All Years'
         CAPTION    = 'Month Year'
         LEVELS     = ( 'Month Year'n )
         DEFAULT;

      HIERARCHY YMD 
         ALL_MEMBER = 'All Years'
         CAPTION    = 'Year > Month > Date'
         LEVELS     = ( Year Month Date );

      HIERARCHY YQMD 
         ALL_MEMBER = 'All Years'
         CAPTION    = 'Year > Qtr > Month > Date'
         LEVELS     = ( Year Quarter Month Date );

      LEVEL Year
         COLUMN         =  transaction_date
         FORMAT         =  YEAR4.
         TYPE           =  YEAR
         CAPTION        =  'Year'
         SORT_ORDER     =  ASCENDING;

      LEVEL Month
         COLUMN         =  transaction_date
         FORMAT         =  MONNAME3.
         TYPE           =  MONTHS
         CAPTION        =  'Month'
         SORT_ORDER     =  ASCENDING;

      LEVEL Date
         COLUMN         = transaction_date
         FORMAT         =  mmddyy10.
         TYPE           =  DAYS
         CAPTION        =  'Transaction Date'
         SORT_ORDER     =  ASCENDING;

      LEVEL Quarter
         COLUMN         =  transaction_date
         FORMAT         =  QTR1.
         TYPE           =  QUARTERS
         CAPTION        =  'Quarter'
         SORT_ORDER     =  ASCENDING;

      LEVEL 'Month Year'n
         COLUMN         =  transaction_date
         FORMAT         =  MONYY7.
         TYPE           =  MONTHS
         CAPTION        =  'Month Year'
         SORT_ORDER     =  ASCENDING;

   DIMENSION 'Transaction Type'n
      CAPTION          = 'Transaction Type'
      SORT_ORDER       = ASCENDING
      DIMTBL           = defiant.DIM_TRANSACTION_TYPE
      DIMKEY           = transaction_type_key
      FACTKEY          = transaction_type_key
      HIERARCHIES      = ( 'Transaction Type'n );

      HIERARCHY  'Transaction Type'n
         ALL_MEMBER = 'All Transaction Types'
         CAPTION    = 'Type > Category'
         LEVELS     = ( TransactionType TransactionCategory )
         DEFAULT;

      LEVEL TransactionType
         COLUMN         = transaction_type
         CAPTION        =  'Type'
         SORT_ORDER     =  ASCENDING;

      LEVEL TransactionCategory
         COLUMN         = transaction_category
         CAPTION        =  'Category'
         SORT_ORDER     =  ASCENDING;

   DIMENSION Location
      CAPTION          = 'Location'
      SORT_ORDER       = ASCENDING
      DIMTBL           = defiant.DIM_LOCATION
      DIMKEY           = location_key
      FACTKEY          = location_key
      HIERARCHIES      = ( Location );

      HIERARCHY Location 
         ALL_MEMBER = 'All States'
         CAPTION    = 'State > County > City'
         LEVELS     = ( State County City )
         DEFAULT;

      LEVEL State
         CAPTION        =  'State'
         SORT_ORDER     =  ASCENDING;

      LEVEL County
         CAPTION        =  'County'
         SORT_ORDER     =  ASCENDING;

      LEVEL City
         CAPTION        =  'City'
         SORT_ORDER     =  ASCENDING;

   DIMENSION 'Party Account'n
      CAPTION          = 'Party Account'
      SORT_ORDER       = ASCENDING
      DIMTBL           = defiant.DIM_PARTY_ACCOUNT
      DIMKEY           = party_account_key
      FACTKEY          = party_account_key
      HIERARCHIES      = ( 'Party Type > Party > Account'n 
                           'NAICS Code > Party > Account'n 
                           'Party > Account'n
                           'Type > NAICS > Party > Account'n
                            AccountNumber );

      HIERARCHY  'Party Type > Party > Account'n
         ALL_MEMBER = 'All Party Types'
         CAPTION    = 'Party Type > Party Number > Account Number'
         LEVELS     = ( 'Party Type'n 'Party Number'n 'Account Number'n )
         DEFAULT;

      HIERARCHY  'NAICS Code > Party > Account'n
         ALL_MEMBER = 'All NAICS Codes'
         CAPTION    = 'NAICS Code > Party Number > Account Number'
         LEVELS     = ( NAICS 'Party Number'n 'Account Number'n );

      HIERARCHY  'Party > Account'n
         ALL_MEMBER = 'All Party Numbers'
         CAPTION    = 'Party Number > Account Number'
         LEVELS     = ( 'Party Number'n 'Account Number'n );

      HIERARCHY  'Type > NAICS > Party > Account'n
         ALL_MEMBER = 'All Party Types'
         CAPTION    = 'Party Type > NAICS Code > Party Number > Account Number'
         LEVELS     = ( 'Party Type'n NAICS 'Party Number'n 'Account Number'n );

      HIERARCHY  AccountNumber
         ALL_MEMBER = 'All Account Numbers'
         CAPTION    = 'Account Number'
         LEVELS     = ( 'Account Number'n );

      LEVEL 'Party Number'n
         COLUMN         = party_number
         CAPTION        =  'Party Number'
         SORT_ORDER     =  ASCENDING
         EMPTY          = '!UNKNOWN';

      LEVEL 'Account Number'n
         COLUMN         = account_number
         CAPTION        =  'Account Number'
         SORT_ORDER     =  ASCENDING
         EMPTY          = '!UNKNOWN';

      LEVEL 'Party Type'n
         COLUMN         = party_type
         CAPTION        =  'Party Type'
         SORT_ORDER     =  ASCENDING
         EMPTY          = '!UNKNOWN';

      LEVEL NAICS
         COLUMN         = naics_code
         CAPTION        =  'NAICS Code'
         SORT_ORDER     =  ASCENDING
         EMPTY          = '!INDIVIDUAL';

   PROPERTY 'Party Name'n
      level='Party Number'n
      column=party_name
      hierarchy=('Party Type > Party > Account'n 
                 'NAICS Code > Party > Account'n 
                 'Party > Account'n
                 'Type > NAICS > Party > Account'n )
      caption='Party Name'
      description='Party Name'
   ;

   PROPERTY 'Account Name'n
      level='Account Number'n
      column=account_name
      hierarchy=('Party Type > Party > Account'n 
                 'NAICS Code > Party > Account'n 
                 'Party > Account'n
                 'Type > NAICS > Party > Account'n AccountNumber )
      caption='Account Name'
      description='Account Name'
   ;

   PROPERTY 'Account Open Date'n
      level='Account Number'n
      column=account_open_date
      hierarchy=('Party Type > Party > Account'n 
                 'NAICS Code > Party > Account'n 
                 'Party > Account'n
                 'Type > NAICS > Party > Account'n AccountNumber)
      caption='Account Open Date'
      description='Account Open Date'
   ;

   MEASURE 'Transaction Amount'n
      STAT        = SUM
      COLUMN      = transaction_amount
      CAPTION     = 'Transaction Amount'
      FORMAT      = DOLLAR22.0
      DEFAULT;

   MEASURE 'AVG Transaction Amount'n
      STAT        = AVG
      COLUMN      = transaction_amount
      CAPTION     = 'AVG Transaction Amount'
      FORMAT      = DOLLAR22.2;

   MEASURE 'Transaction Count'n
      STAT        = N
      COLUMN      = transaction_key
      CAPTION     = 'Transaction Count'
      FORMAT      = comma22.;

run;

%put ******** Define MDX *********;
proc olap;

   METASVR
      HOST        = "enterprise"
      PORT        = 8561
      OLAP_SCHEMA = "SASApp - OLAP Schema";

   /* Rolling month sets */
   DEFINE SET '[Transaction Summary].[Rolling 3 Months]' as 'Tail([Time].[MonthYear].[Month Year].members,3)';
   DEFINE SET '[Transaction Summary].[Rolling 6 Months]' as 'Tail([Time].[MonthYear].[Month Year].members,6)';
   DEFINE SET '[Transaction Summary].[Rolling 12 Months]' as 'Tail([Time].[MonthYear].[Month Year].members,12)';
   DEFINE SET '[Transaction Summary].[Rolling 18 Months]' as 'Tail([Time].[MonthYear].[Month Year].members,18)';
   DEFINE SET '[Transaction Summary].[Rolling 24 Months]' as 'Tail([Time].[MonthYear].[Month Year].members,24)';

   /* Rolling time aggregate members */
   DEFINE MEMBER '[Transaction Summary].[Time].[MonthYear].[All Years].[Rolling 3 Months]' as 'Aggregate( Tail([Time].[MonthYear].[Month Year].members,3 ))';
   DEFINE MEMBER '[Transaction Summary].[Time].[MonthYear].[All Years].[Rolling 6 Months]' as 'Aggregate( Tail([Time].[MonthYear].[Month Year].members,6 ))';
   DEFINE MEMBER '[Transaction Summary].[Time].[MonthYear].[All Years].[Rolling 12 Months]' as 'Aggregate( Tail([Time].[MonthYear].[Month Year].members,12 ))';
   DEFINE MEMBER '[Transaction Summary].[Time].[MonthYear].[All Years].[Rolling 18 Months]' as 'Aggregate( Tail([Time].[MonthYear].[Month Year].members,18 ))';
   DEFINE MEMBER '[Transaction Summary].[Time].[MonthYear].[All Years].[Rolling 24 Months]' as 'Aggregate( Tail([Time].[MonthYear].[Month Year].members,24 ))';

   DEFINE SET '[Transaction Summary].[Rolling 6 Months Plus Summary]' as '
      {
         [Rolling 6 Months],
         [Time].[MonthYear].[All Years].[Rolling 3 Months],
         [Time].[MonthYear].[All Years].[Rolling 6 Months],
         [Time].[MonthYear].[All Years].[Rolling 12 Months]
      }';

   DEFINE SET '[Transaction Summary].[Rolling 12 Months Plus Summary]' as '
      {
         [Rolling 12 Months],
         [Time].[MonthYear].[All Years].[Rolling 3 Months],
         [Time].[MonthYear].[All Years].[Rolling 6 Months],
         [Time].[MonthYear].[All Years].[Rolling 12 Months]
      }';

   DEFINE SET '[Transaction Summary].[Summary Month Totals]' as '
      {
         [Time].[MonthYear].[All Years].[Rolling 3 Months],
         [Time].[MonthYear].[All Years].[Rolling 6 Months],
         [Time].[MonthYear].[All Years].[Rolling 12 Months]
      }';

   /**************** Peer Comparison using NAICS codes *********************/
   DEFINE Member '[Transaction Summary].[Measures].[AVG NAICS Amt]' AS
    '([Party Account].[NAICS Code > Party > Account].CurrentMember.Parent,[Measures].[AVG Transaction Amount]), SOLVE_ORDER=0, format_string="dollar20.2"';
    /** TODO: add MDX to be dynamic on multiple hierarchies for better analysis */

   DEFINE Member '[Transaction Summary].[Measures].[Diff NAICS AVG Amt]' AS
    '([Measures].[AVG Transaction Amount] - [Measures].[AVG NAICS Amt]), SOLVE_ORDER=1, format_string="dollar20.2"';

   DEFINE Member '[Transaction Summary].[Measures].[%Diff NAICS AVG Trans Amt]' AS
    '[Measures].[Diff NAICS AVG Amt] / [Measures].[AVG NAICS Amt], SOLVE_ORDER=2, format_string="NLPCT8.2"';

   DEFINE SET '[Transaction Summary].[Party Comparison by NAICS]' as '[Party Account].[NAICS Code > Party > Account].[Party Number].Members';
   /** TODO: add MDX to remove parties with no NAICS code (individuals). Use the EXCEPT() function or minus operator */

   /***************** Peer Comparison using Party Type ******************/
   DEFINE Member '[Transaction Summary].[Measures].[AVG Party Type Amt]' AS
    '([Party Account].[Party Type > Party > Account].CurrentMember.Parent,[Measures].[AVG Transaction Amount]), SOLVE_ORDER=0, format_string="dollar20.2"';

   DEFINE Member '[Transaction Summary].[Measures].[Diff Party Type AVG Amt]' AS
    '([Measures].[AVG Transaction Amount] - [Measures].[AVG Party Type Amt]), SOLVE_ORDER=1, format_string="dollar20.2"';

   DEFINE Member '[Transaction Summary].[Measures].[%Diff Party Type AVG Trans Amt]' AS
    '[Measures].[Diff Party Type AVG Amt] / [Measures].[AVG Party Type Amt], SOLVE_ORDER=2, format_string="NLPCT8.2"';

   DEFINE SET '[Transaction Summary].[Party Comparison by Type]' as '[Party Account].[Party Type > Party > Account].[Party Number].Members';

   /******  TODO add rolling averages and percent change **/

run;

%put ******* Build Performance Aggregates *******;
proc olap 
   CUBE= "&cube"
   CONCURRENT             = 4
   ASYNCINDEXLIMIT        = 2
   MAXTHREADS             = 2
   TEST_LEVEL             = 26;

   METASVR
      HOST        = "enterprise"
      PORT        = 8561
      OLAP_SCHEMA = "SASApp - OLAP Schema";

   AGGREGATION 'Month Year'n 'Party Type'n NAICS 'Party Number'n 'Account Number'n
      / NAME      = 'Month Year Reporting 1';
   AGGREGATION 'Month Year'n State County City
      / NAME      = 'Month Year Reporting 2';
   AGGREGATION 'Month Year'n TransactionType TransactionCategory
      / NAME      = 'Month Year Reporting 3';
   AGGREGATION 'Month Year'n TransactionType TransactionCategory 'Party Type'n NAICS 'Party Number'n 'Account Number'n
      / NAME      = 'Month Year Reporting 4';
   AGGREGATION 'Month Year'n NAICS
      / NAME      = 'Month Year Reporting 5';
   AGGREGATION 'Month Year'n NAICS 'Party Number'n
      / NAME      = 'Month Year Reporting 6';
   AGGREGATION 'Month Year'n 'Party Type'n
      / NAME      = 'Month Year Reporting 7';
   AGGREGATION 'Month Year'n NAICS 'Party Type'n
      / NAME      = 'Month Year Reporting 8';
   AGGREGATION 'Month Year'n NAICS 'Party Number'n 'Party Type'n
      /  NAME     = 'Month Year Reporting 9';

run;
proc olap 
   CUBE= "&cube"
   CONCURRENT             = 4
   ASYNCINDEXLIMIT        = 2
   MAXTHREADS             = 2
   TEST_LEVEL             = 26;

   METASVR
      HOST        = "enterprise"
      PORT        = 8561
      OLAP_SCHEMA = "SASApp - OLAP Schema";

   AGGREGATION Year Month 'Party Type'n NAICS 'Party Number'n 'Account Number'n
      / NAME      = 'Year Month Reporting 1';
   AGGREGATION Year Month State County City
      / NAME      = 'Year Month Reporting 2';
   AGGREGATION Year Month TransactionType TransactionCategory
      / NAME      = 'Year Month Reporting 3';
   AGGREGATION Year Month TransactionType TransactionCategory 'Party Type'n NAICS 'Party Number'n 'Account Number'n
      / NAME      = 'Year Month Reporting 4';
   AGGREGATION Year Month NAICS
      / NAME      = 'Year Month Reporting 5';
   AGGREGATION Year Month NAICS 'Party Number'n
      / NAME      = 'Year Month Reporting 6';
   AGGREGATION Year Month 'Party Type'n
      / NAME      = 'Year Month Reporting 7';
   AGGREGATION Year Month NAICS 'Party Type'n
      / NAME      = 'Year Month Reporting 8';
   AGGREGATION Year Month NAICS 'Party Number'n 'Party Type'n
      /  NAME     = 'Year Month Reporting 9';

run;
proc olap 
   CUBE= "&cube"
   CONCURRENT             = 4
   ASYNCINDEXLIMIT        = 2
   MAXTHREADS             = 2
   TEST_LEVEL             = 26;

   METASVR
      HOST        = "enterprise"
      PORT        = 8561
      OLAP_SCHEMA = "SASApp - OLAP Schema";

   /* Top Level Aggregates */
   AGGREGATION 'Month Year'n  
      / NAME      = 'Top Month Year';
   AGGREGATION Year Month 
      / NAME      = 'Top Year Month';
   AGGREGATION State Year
      / NAME      = 'State Year';

run;
