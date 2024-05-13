/*------------------------------------------------------------------------------------------
  PROGRAMMER   : Stephen Overton (SAS Institute Partner) (soverton@overtontechnologies.com)
  PURPOSE      : Build Transaction Analysis OLAP cube. Cube summarizes transactions over
                 time by transaction date, party, account, type. Include custom analytical
                 measures, members, and sets using MDX. 

Support Notes:
- http://support.sas.com/kb/19/363.html
- http://support.sas.com/kb/38/978.html
- http://support.sas.com/documentation/cdl/en/biasag/61237/HTML/default/viewer.htm#a003145996.htm
- http://ftp.sas.com/techsup/download/hotfix/HF2/J46.html#48152

|------------------------------------------------------------------------------------------|
|  MAINTENANCE HISTORY                                                                     |
|------------------------------------------------------------------------------------------|
|  DATE    |     BY    | DESCRIPTION OF CHANGE                                             |
|----------|-----------|-------------------------------------------------------------------|  
| 3/18/13  |  SteveO   | Initial release
|-----------------------------------------------------------------------------------------*/
LIBNAME pgdev POSTGRES DATABASE="dev" SERVER=defiant SCHEMA=public 
  READBUFF=10000 USER=postgres  PASSWORD="{SAS002}1D5793391C1104E20E3CF4CD2A793E2B" ;

%let cube = /Projects/SGF2013/Cubes/Transaction Summary;
%let syscc=0;

%put ****** START cube build process ******;
proc olap
   CUBE                   = "&cube"
   DELETE;

   METASVR
      HOST        = "pegasus"
      PORT        = 8561
      OLAP_SCHEMA = "SASApp - OLAP Schema";

run;

options fullstimer fmterr;
options SASTRACE=',,,ds' sastraceloc=saslog nostsuffix;
%let syssumtrace=3;

proc options group=performance; run;

%errorcheck;
proc olap
   CUBE                   = "&cube"
   PATH                   = '/projects/SGF2013/cubes'
   DESCRIPTION            = 'Transaction Summary demo cube for SGF2013'
   FACT                   = pgdev.fact_transactions(obs=1000000)
   CONCURRENT             = 4
   ASYNCINDEXLIMIT        = 2
   MAXTHREADS             = 2
   EMPTY_CHAR             = '!UNKNOWN'
   TEST_LEVEL             = 26
;

   METASVR
      HOST        = "pegasus"
      PORT        = 8561
      OLAP_SCHEMA = "SASApp - OLAP Schema";

    DIMENSION 'Transaction Date'n
      CAPTION          = 'Transaction Date'
      TYPE             = TIME
      SORT_ORDER       = ASCENDING
      HIERARCHIES      = ( 'Month Year'n 'Year > Month'n  );

      HIERARCHY 'Month Year'n 
         ALL_MEMBER = 'All Years'
         CAPTION    = 'Month-Year'
         LEVELS     = ( MonthYear )
         DEFAULT;

      HIERARCHY 'Year > Month'n 
         ALL_MEMBER = 'All Years'
         CAPTION    = 'Year > Month'
         LEVELS     = ( Year Month );

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

      LEVEL MonthYear
         COLUMN         =  transaction_date
         FORMAT         =  MONYY7.
         TYPE           =  MONTHS
         CAPTION        =  'Month Year'
         SORT_ORDER     =  ASCENDING;

   DIMENSION 'Transaction Type'n
      CAPTION          = 'Transaction Type'
      SORT_ORDER       = ASCENDING
      DIMTBL           = pgdev.dim_transaction_type
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
      DIMTBL           = pgdev.dim_location
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
      DIMTBL           = pgdev.dim_party_account
      DIMKEY           = party_account_key
      FACTKEY          = party_account_key
      HIERARCHIES      = ( 'Party Type > Party > Account'n 
                           'NAICS Code > Party > Account'n 
                           'Party > Account'n
                           'Party Number'n
                           'Type > NAICS > Party > Account'n
                            'Account Number'n );

      HIERARCHY  'Party Type > Party > Account'n
         ALL_MEMBER = 'All Party Types'
         CAPTION    = 'Party Type > Party Number > Account Number'
         LEVELS     = ( PartyType PartyNumber AccountNumber )
         DEFAULT;

      HIERARCHY  'NAICS Code > Party > Account'n
         ALL_MEMBER = 'All NAICS Codes'
         CAPTION    = 'NAICS Code > Party Number > Account Number'
         LEVELS     = ( NAICS PartyNumber AccountNumber );

      HIERARCHY  'Party > Account'n
         ALL_MEMBER = 'All Party Numbers'
         CAPTION    = 'Party Number > Account Number'
         LEVELS     = ( PartyNumber AccountNumber );
 
      HIERARCHY  'Party Number'n
         ALL_MEMBER = 'All Party Numbers'
         CAPTION    = 'Party Number'
         LEVELS     = ( PartyNumber );

      HIERARCHY  'Type > NAICS > Party > Account'n
         ALL_MEMBER = 'All Party Types'
         CAPTION    = 'Party Type > NAICS Code > Party Number > Account Number'
         LEVELS     = ( PartyType NAICS PartyNumber AccountNumber );

      HIERARCHY  'Account Number'n
         ALL_MEMBER = 'All Account Numbers'
         CAPTION    = 'Account Number'
         LEVELS     = ( AccountNumber );

      LEVEL PartyNumber
         COLUMN         = party_number
         CAPTION        =  'Party Number'
         SORT_ORDER     =  ASCENDING
         EMPTY          = '!UNKNOWN';

      LEVEL AccountNumber
         COLUMN         = account_number
         CAPTION        =  'Account Number'
         SORT_ORDER     =  ASCENDING
         EMPTY          = '!UNKNOWN';

      LEVEL PartyType
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
      level=PartyNumber
      column=party_name
      hierarchy=('Party Type > Party > Account'n 
                 'NAICS Code > Party > Account'n 
                 'Party > Account'n
                 'Party Number'n
                 'Type > NAICS > Party > Account'n )
      caption='Party Name'
      description='Party Name'
   ;

   PROPERTY PartyType
      level=PartyNumber
      column=party_type
      hierarchy=('NAICS Code > Party > Account'n 
                 'Party > Account'n
                 'Party Number'n )
      caption='Party Type'
      description='Party Type'
   ;

   PROPERTY 'Account Name'n
      level=AccountNumber
      column=account_name
      hierarchy=('Party Type > Party > Account'n 
                 'NAICS Code > Party > Account'n 
                 'Party > Account'n
                 'Type > NAICS > Party > Account'n 'Account Number'n )
      caption='Account Name'
      description='Account Name'
   ;

   PROPERTY 'Account Open Date'n
      level=AccountNumber
      column=account_open_date
      hierarchy=('Party Type > Party > Account'n 
                 'NAICS Code > Party > Account'n 
                 'Party > Account'n
                 'Type > NAICS > Party > Account'n 'Account Number'n)
      caption='Account Open Date'
      description='Account Open Date'
   ;

   MEASURE 'Transaction Amount'n
      STAT        = SUM
      COLUMN      = transaction_amount
      CAPTION     = 'Transaction Amount'
      FORMAT      = DOLLAR24.0
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

%errorcheck;
%put ******** Define MDX *********;
proc olap;

   METASVR
      HOST        = "pegasus"
      PORT        = 8561
      OLAP_SCHEMA = "SASApp - OLAP Schema";

   /* Rolling month sets */
   DEFINE SET '[Transaction Summary].[Latest Month]' as 'Tail([Transaction Date].[Month Year].[MonthYear].members,1)';
   DEFINE SET '[Transaction Summary].[Rolling 3 Months]' as 'Tail([Transaction Date].[Month Year].[MonthYear].members,3)';
   DEFINE SET '[Transaction Summary].[Rolling 6 Months]' as 'Tail([Transaction Date].[Month Year].[MonthYear].members,6)';
   DEFINE SET '[Transaction Summary].[Rolling 12 Months]' as 'Tail([Transaction Date].[Month Year].[MonthYear].members,12)';
   DEFINE SET '[Transaction Summary].[Rolling 13 Months]' as 'Tail([Transaction Date].[Month Year].[MonthYear].members,13)';
   DEFINE SET '[Transaction Summary].[Rolling 18 Months]' as 'Tail([Transaction Date].[Month Year].[MonthYear].members,18)';
   DEFINE SET '[Transaction Summary].[Rolling 24 Months]' as 'Tail([Transaction Date].[Month Year].[MonthYear].members,24)';

   /* Rolling time aggregate members */
   DEFINE MEMBER '[Transaction Summary].[Transaction Date].[All Years].[Rolling 3 Months]' as 'Aggregate( Tail([Transaction Date].[Month Year].[MonthYear].members,3 ))';
   DEFINE MEMBER '[Transaction Summary].[Transaction Date].[All Years].[Rolling 6 Months]' as 'Aggregate( Tail([Transaction Date].[Month Year].[MonthYear].members,6 ))';
   DEFINE MEMBER '[Transaction Summary].[Transaction Date].[All Years].[Rolling 12 Months]' as 'Aggregate( Tail([Transaction Date].[Month Year].[MonthYear].members,12 ))';
   DEFINE MEMBER '[Transaction Summary].[Transaction Date].[All Years].[Rolling 18 Months]' as 'Aggregate( Tail([Transaction Date].[Month Year].[MonthYear].members,18 ))';
   DEFINE MEMBER '[Transaction Summary].[Transaction Date].[All Years].[Rolling 24 Months]' as 'Aggregate( Tail([Transaction Date].[Month Year].[MonthYear].members,24 ))';

   DEFINE SET '[Transaction Summary].[Rolling 3 Months Plus Summary]' as '
      {
         [Rolling 3 Months],
         [Transaction Date].[All Years].[Rolling 3 Months],
         [Transaction Date].[All Years].[Rolling 6 Months],
         [Transaction Date].[All Years].[Rolling 12 Months],
         [Transaction Date].[All Years].[Rolling 18 Months]
      }';

   DEFINE SET '[Transaction Summary].[Rolling 6 Months Plus Summary]' as '
      {
         [Rolling 6 Months],
         [Transaction Date].[All Years].[Rolling 3 Months],
         [Transaction Date].[All Years].[Rolling 6 Months],
         [Transaction Date].[All Years].[Rolling 12 Months],
         [Transaction Date].[All Years].[Rolling 18 Months]
      }';

   DEFINE SET '[Transaction Summary].[Rolling 12 Months Plus Summary]' as '
      {
         [Rolling 12 Months],
         [Transaction Date].[All Years].[Rolling 3 Months],
         [Transaction Date].[All Years].[Rolling 6 Months],
         [Transaction Date].[All Years].[Rolling 12 Months],
         [Transaction Date].[All Years].[Rolling 18 Months]
      }';

   DEFINE SET '[Transaction Summary].[Summary Month Totals]' as '
      {
         [Transaction Date].[All Years].[Rolling 3 Months],
         [Transaction Date].[All Years].[Rolling 6 Months],
         [Transaction Date].[All Years].[Rolling 12 Months],
         [Transaction Date].[All Years].[Rolling 18 Months]
      }';

   /**************** Peer Comparison using NAICS codes *********************/
   DEFINE MEMBER '[Transaction Summary].[Measures].[AVG NAICS Amt]' AS
    '([Party Account].[NAICS Code > Party > Account].CurrentMember.Parent,[Measures].[AVG Transaction Amount]), SOLVE_ORDER=0, format_string="dollar20.2"';
    /** TODO: add MDX to be dynamic on multiple hierarchies for better analysis */

   DEFINE MEMBER '[Transaction Summary].[Measures].[Diff NAICS AVG Amt]' AS
    '([Measures].[AVG Transaction Amount] - [Measures].[AVG NAICS Amt]), SOLVE_ORDER=1, format_string="dollar20.2"';

   DEFINE MEMBER '[Transaction Summary].[Measures].[%Diff NAICS AVG Trans Amt]' AS
    '[Measures].[Diff NAICS AVG Amt] / [Measures].[AVG NAICS Amt], SOLVE_ORDER=2, format_string="NLPCT8.2"';

   DEFINE SET '[Transaction Summary].[Party Comparison by NAICS]' as '[Party Account].[NAICS Code > Party > Account].[PartyNumber].Members';
   /** TODO: add MDX to remove parties with no NAICS code (individuals). Use the EXCEPT() function or minus operator */

   /***************** Peer Comparison using Party Type ******************/
   DEFINE MEMBER '[Transaction Summary].[Measures].[AVG Party Type Amt]' AS
    '([Party Account].[Party Type > Party > Account].CurrentMember.Parent,[Measures].[AVG Transaction Amount]), SOLVE_ORDER=0, format_string="dollar20.2"';

   DEFINE MEMBER '[Transaction Summary].[Measures].[Diff Party Type AVG Amt]' AS
    '([Measures].[AVG Transaction Amount] - [Measures].[AVG Party Type Amt]), SOLVE_ORDER=1, format_string="dollar20.2"';

   DEFINE MEMBER '[Transaction Summary].[Measures].[%Diff Party Type AVG Trans Amt]' AS
    '[Measures].[Diff Party Type AVG Amt] / [Measures].[AVG Party Type Amt], SOLVE_ORDER=2, format_string="NLPCT8.2"';

   DEFINE SET '[Transaction Summary].[Party Comparison by Type]' as '[Party Account].[Party Type > Party > Account].[PartyNumber].Members';

   /* Rolling Averages */
   DEFINE MEMBER '[Transaction Summary].[Measures].[AVG Trans Amt 3M Rolling]' AS
        'Avg(LastPeriods(3,[Transaction Date].[Month Year].CurrentMember),[Measures].[AVG Transaction Amount])';
   DEFINE MEMBER '[Transaction Summary].[Measures].[AVG Trans Amt 6M Rolling]' AS
        'Avg(LastPeriods(6,[Transaction Date].[Month Year].CurrentMember),[Measures].[AVG Transaction Amount])';
   DEFINE MEMBER '[Transaction Summary].[Measures].[AVG Trans Amt 12M Rolling]' AS
        'Avg(LastPeriods(12,[Transaction Date].[Month Year].CurrentMember),[Measures].[AVG Transaction Amount])';

   /* Percent Change */
   DEFINE MEMBER '[Transaction Summary].[Measures].[%Change Trans Amt]' AS
     '(([Transaction Date].[Month Year].CurrentMember,[Measures].[Transaction Amount])-([Transaction Date].[Month Year].CurrentMember.PrevMember,[Measures].[Transaction Amount]))/([Transaction Date].[Month Year].CurrentMember.PrevMember,[Measures].[Transaction Amount]), format_string="percent14.2"';
   DEFINE MEMBER '[Transaction Summary].[Measures].[%Change Trans Count]' AS
     '(([Transaction Date].[Month Year].CurrentMember,[Measures].[Transaction Count])-([Transaction Date].[Month Year].CurrentMember.PrevMember,[Measures].[Transaction Count]))/([Transaction Date].[Month Year].CurrentMember.PrevMember,[Measures].[Transaction Count]), format_string="percent14.2"';

run;

%put ******* Build Performance Aggregates *******;
/* Base level aggregates  */
proc olap 
   CUBE= "&cube"
   CONCURRENT             = 4
   ASYNCINDEXLIMIT        = 2
   MAXTHREADS             = 2
   TEST_LEVEL             = 26;

   METASVR
      HOST        = "pegasus"
      PORT        = 8561
      OLAP_SCHEMA = "SASApp - OLAP Schema";

   AGGREGATION MonthYear TransactionType TransactionCategory PartyType NAICS PartyNumber AccountNumber
      / NAME      = 'Base Reporting 1';
   AGGREGATION MonthYear  State County City PartyType NAICS PartyNumber AccountNumber
      / NAME      = 'Base Reporting 2';
   AGGREGATION Year Month TransactionType TransactionCategory PartyType NAICS PartyNumber AccountNumber
      / NAME      = 'Base Reporting 3';
   AGGREGATION Year Month  State County City PartyType NAICS PartyNumber AccountNumber
      / NAME      = 'Base Reporting 4';

run;

/* Mid level aggregates */
proc olap 
   CUBE= "&cube"
   CONCURRENT             = 4
   ASYNCINDEXLIMIT        = 2
   MAXTHREADS             = 2
   TEST_LEVEL             = 26;

   METASVR
      HOST        = "pegasus"
      PORT        = 8561
      OLAP_SCHEMA = "SASApp - OLAP Schema";

   AGGREGATION MonthYear PartyType NAICS PartyNumber AccountNumber
      / NAME      = 'Month Year Reporting 1';
   AGGREGATION MonthYear State County City
      / NAME      = 'Month Year Reporting 2';
   AGGREGATION MonthYear State
      / NAME      = 'Month Year Reporting 3';
   AGGREGATION MonthYear TransactionType TransactionCategory
      / NAME      = 'Month Year Reporting 4';
   AGGREGATION MonthYear TransactionType TransactionCategory State County City
      / NAME      = 'Month Year Reporting 5';
   AGGREGATION MonthYear NAICS
      / NAME      = 'Month Year Reporting 6';
   AGGREGATION MonthYear NAICS PartyNumber
      / NAME      = 'Month Year Reporting 7';
   AGGREGATION MonthYear PartyType
      / NAME      = 'Month Year Reporting 8';
   AGGREGATION MonthYear PartyType NAICS 
      / NAME      = 'Month Year Reporting 9';
   AGGREGATION MonthYear NAICS PartyType PartyNumber 
      /  NAME     = 'Month Year Reporting 10';
   AGGREGATION MonthYear AccountNumber
      / NAME      = 'Month Year Reporting 11';
   AGGREGATION MonthYear PartyNumber 
      / NAME      = 'Month Year Reporting 12';
   AGGREGATION MonthYear TransactionType 
      / NAME      = 'Month Year Reporting 13';
   AGGREGATION MonthYear PartyType PartyNumber 
      / NAME      = 'Month Year Reporting 14';
   AGGREGATION MonthYear TransactionType TransactionCategory NAICS PartyNumber 
      / NAME      = 'Month Year Reporting 15';
   AGGREGATION MonthYear TransactionType TransactionCategory NAICS
      / NAME      = 'Month Year Reporting 16';

   AGGREGATION Year Month PartyType NAICS PartyNumber AccountNumber
      / NAME      = 'Year Month Reporting 1';
   AGGREGATION Year Month State County City
      / NAME      = 'Year Month Reporting 2';
   AGGREGATION Year Month State
      / NAME      = 'Year Month Reporting 3';
   AGGREGATION Year Month TransactionType TransactionCategory
      / NAME      = 'Year Month Reporting 4';
   AGGREGATION Year Month TransactionType TransactionCategory State County City
      / NAME      = 'Year Month Reporting 5';
   AGGREGATION Year Month NAICS
      / NAME      = 'Year Month Reporting 6';
   AGGREGATION Year Month NAICS PartyNumber
      / NAME      = 'Year Month Reporting 7';
   AGGREGATION Year Month PartyType
      / NAME      = 'Year Month Reporting 8';
   AGGREGATION Year Month PartyType NAICS 
      / NAME      = 'Year Month Reporting 9';
   AGGREGATION Year Month NAICS PartyType PartyNumber 
      /  NAME     = 'Year Month Reporting 10';
   AGGREGATION Year Month AccountNumber
      / NAME      = 'Year Month Reporting 11';
   AGGREGATION Year Month PartyNumber 
      / NAME      = 'Year Month Reporting 12';
   AGGREGATION Year Month TransactionType 
      / NAME      = 'Year Month Reporting 13';
   AGGREGATION Year Month PartyType PartyNumber 
      / NAME      = 'Year Month Reporting 14';
   AGGREGATION Year Month TransactionType TransactionCategory NAICS PartyNumber 
      / NAME      = 'Year Month Reporting 15';
   AGGREGATION Year Month TransactionType TransactionCategory NAICS
      / NAME      = 'Year Month Reporting 16';

run;

/* Top level aggregates */
proc olap 
   CUBE= "&cube"
   CONCURRENT             = 4
   ASYNCINDEXLIMIT        = 2
   MAXTHREADS             = 2
   TEST_LEVEL             = 26;

   METASVR
      HOST        = "pegasus"
      PORT        = 8561
      OLAP_SCHEMA = "SASApp - OLAP Schema";

   AGGREGATION MonthYear  
      / NAME      = 'Top Month Year';
   AGGREGATION Year Month 
      / NAME      = 'Top Year Month';
   AGGREGATION NAICS
      / NAME      = 'NAICS';
   AGGREGATION NAICS PartyNumber
      / NAME      = 'NAICS Party Number';
   AGGREGATION State County City
      / NAME      = 'State County City';
   AGGREGATION State
      / NAME      = 'State';
   AGGREGATION TransactionType
      / NAME      = 'Transaction Type';
   AGGREGATION PartyType PartyNumber 
      / NAME      = 'Party Type Number';
   AGGREGATION PartyType 
      / NAME      = 'Party Type';
   AGGREGATION PartyType PartyNumber AccountNumber 
      / NAME      = 'Party Type Number Account';
   AGGREGATION PartyNumber 
      /  NAME     = 'Party Number';
   AGGREGATION AccountNumber 
      /  NAME     = 'Account Number';
   AGGREGATION PartyNumber AccountNumber
      /  NAME     = 'Party Account';
   AGGREGATION PartyNumber AccountNumber
      /  NAME     = 'Party Account';
   AGGREGATION TransactionType TransactionCategory NAICS
      /  NAME     = 'TranType TranCategory NAICS';

run;
