/*************************************************************/
/*   Code Written by:                                        */
/*      Stephen Overton  (soverton@overtontechnologies.com)  */
/*                                                           */
/*   Builds a cube for testing and demo purposes using       */
/*   fake transaction data                                   */
/*************************************************************/
LIBNAME postgres ODBC READBUFF=5000 DATASRC=dev SCHEMA=public;

%let cube = /Projects/SGF2013/Cubes/Transaction Summary;

%put ****** DIVIDE source data into segments to load ******;
proc sql threads;
  /* transaction_date is used to segment data to load cube */
  create table segments as
    select distinct transaction_date from postgres.FACT_TRANSACTIONS order by transaction_date desc;
  /* insert segments into macro list to interate through */
  select transaction_date into :segment1 - :segment999999 from segments;
  /* get the number of records for counter for loop */
  select count(transaction_date) into :segment_count from segments;
quit;
%put Segments to loop through &segment_count;

%put ****** DEFINE first segment ******;
proc sql threads;
  create table SGF2013.FACT_TRANSACTIONS_SEGMENT as
    select * from postgres.FACT_TRANSACTIONS
      where transaction_date = &segment1;
quit;

/** Ensure segment tables exist in metadata for OLAP server  **/
libname _temp meta repname="Foundation" library="SGF2013" metaout=data;
proc metalib;
  omr (library="SGF2013"
  metarepository="Foundation");
  select("FACT_TRANSACTIONS_SEGMENT");
  update_rule=(delete);
  report;
run;
libname _temp clear;

%put ****** START cube build process ******;
proc olap
   CUBE                   = "&cube"
   DELETE;

   METASVR
      HOST        = "vSAS"
      PORT        = 8561
      OLAP_SCHEMA = "SASApp - OLAP Schema";

run;

options fullstimer;
options SASTRACE=',,,ds' sastraceloc=saslog nostsuffix;
%let syssumtrace=3;

proc options group=performance; run;

proc olap
   CUBE                   = "&cube"
   /* Store in special location for space */
   PATH                   = '/data/cubes'
   DESCRIPTION            = 'Transaction Summary demo cube for SGF2013'
   FACT                   = SGF2013.FACT_TRANSACTIONS_SEGMENT
   CONCURRENT             = 4
   ASYNCINDEXLIMIT        = 2
   MAXTHREADS             = 2
   TEST_LEVEL             = 26
;

   METASVR
      HOST        = "vSAS"
      PORT        = 8561
      OLAP_SCHEMA = "SASApp - OLAP Schema";

    DIMENSION Time
      CAPTION          = 'Time'
      TYPE             = TIME
      SORT_ORDER       = ASCENDING
      HIERARCHIES      = ( YMD YQMD MonthYear );

      HIERARCHY YMD 
         ALL_MEMBER = 'All Years'
         CAPTION    = 'Year > Month > Date'
         LEVELS     = ( Year Month Date )
         DEFAULT;

      HIERARCHY YQMD 
         ALL_MEMBER = 'All Years'
         CAPTION    = 'Year > Qtr > Month > Date'
         LEVELS     = ( Year Quarter Month Date );

      HIERARCHY MonthYear 
         ALL_MEMBER = 'All Years'
         CAPTION    = 'Month Year'
         LEVELS     = ( 'Month Year'n );

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

   DIMENSION Location
      CAPTION          = 'Location'
      SORT_ORDER       = ASCENDING
      DIMTBL           = postgres.DIM_LOCATION
      DIMKEY           = location_key
      FACTKEY          = location_key
      HIERARCHIES      = ( Location );

      HIERARCHY Location 
         ALL_MEMBER = 'All States'
         CAPTION    = 'State > City'
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

   DIMENSION 'Transaction Type'n
      CAPTION          = 'Transaction Type'
      SORT_ORDER       = ASCENDING
      DIMTBL           = postgres.DIM_TRANSACTION_TYPE
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

   DIMENSION 'Party Account'n
      CAPTION          = 'Party Account'
      SORT_ORDER       = ASCENDING
      DIMTBL           = postgres.DIM_PARTY_ACCOUNT
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
         SORT_ORDER     =  ASCENDING;

      LEVEL 'Account Number'n
         COLUMN         = account_number
         CAPTION        =  'Account Number'
         SORT_ORDER     =  ASCENDING;

      LEVEL 'Party Type'n
         COLUMN         = party_type
         CAPTION        =  'Party Type'
         SORT_ORDER     =  ASCENDING;

      LEVEL NAICS
         COLUMN         = naics_code
         CAPTION        =  'NAICS Code'
         SORT_ORDER     =  ASCENDING;

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

   MEASURE 'AVG Transaction'n
      STAT        = AVG
      COLUMN      = transaction_amount
      CAPTION     = 'Transaction Amount'
      FORMAT      = DOLLAR22.2;

   MEASURE 'Transaction Count'n
      STAT        = N
      COLUMN      = transaction_key
      CAPTION     = 'Transaction Count'
      FORMAT      = comma22.;

run;

/*** Macro to iterate through remaining segments and load cube ***/
%macro LoadSegmentsIntoCube;
/* incrementally load cube by updating a view in each step then incrementally adding data to the cube */
%do x=2 %to &segment_count;
  /* if no errors (warnings can exist) then proceed */
  %if &syserr. eq 0 or &syserr. eq 4 %then %do;

    /* update segmented data */
    %put ****** Load next segment into table to incrementally load cube for segment = &&segment&x ******;
    proc sql threads;
      create table SGF2013.FACT_TRANSACTIONS_SEGMENT as
        select * from postgres.FACT_TRANSACTIONS
          where transaction_date = &&segment&x
      ;
    quit;
   
    /* Incrementally update cube */
    %put ****** LOAD cube for snapshot = &&segment&x ******;
    proc olap
      CUBE                   = "&cube"
      DATA                   = SGF2013.FACT_TRANSACTIONS_SEGMENT
      ADD_DATA
      UPDATE_INPLACE
      IGNORE_MISSING_DIMKEYS = VERBOSE
      ;
  
    METASVR
        HOST        = "vSAS"
        PORT        = 8561
        OLAP_SCHEMA = "SASApp - OLAP Schema";
  
      /*** IMPORTANT: Update this list if new dimensions are added ****/
      DIMENSION Location UPDATE_DIMENSION = MEMBERS;
      DIMENSION Time UPDATE_DIMENSION = MEMBERS;
      DIMENSION 'Party Account'n UPDATE_DIMENSION = MEMBERS;
      DIMENSION 'Transaction Type'n UPDATE_DIMENSION = MEMBERS;
  
    run;
  
    %put ******** Coalesce NWAY **********;
    proc olap
      CUBE                   = "&cube"
       COALESCE_AGGREGATIONS;
  
      METASVR
          HOST        = "vSAS"
          PORT        = 8561
          OLAP_SCHEMA = "SASApp - OLAP Schema";
  
    run;

    %put ****** FINISH loading for snapshot = &&segment&x ******;
  %end;
  %else %do; /* if errors exist */
    %put *********** ERRORS DETECTED: ABORTING **********;
    %abort cancel;
  %end;

%end;
%mend LoadSegmentsIntoCube;

/* disable log during macro */
options nosource;

/** Execute macro **/
%LoadSegmentsIntoCube;

/* re-enable log */
options source;

%put ******** Define MDX *********;
proc olap CUBE= "&cube";

   METASVR
      HOST        = "vSAS"
      PORT        = 8561
      OLAP_SCHEMA = "SASApp - OLAP Schema";

   /* Rolling month sets */
   DEFINE SET "[Transaction Summary].[Rolling 12 Months]" as "Tail([Time].[MonthYear].[Month Year].AllMembers ,12)";
   DEFINE SET "[Transaction Summary].[Rolling 24 Months]" as "Tail([Time].[MonthYear].[Month Year].AllMembers ,24)";
   DEFINE SET "[Transaction Summary].[Rolling 36 Months]" as "Tail([Time].[MonthYear].[Month Year].AllMembers ,36)";

   /* Rolling time aggregate members */
   DEFINE MEMBER "[Transaction Summary].[Time].[YMD].[All Years].[Rolling 12 Months]" as 'Aggregate( Tail([Time].[MonthYear].[Month Year].AllMembers ,12) )';
   DEFINE MEMBER "[Transaction Summary].[Time].[YMD].[All Years].[Rolling 24 Months]" as 'Aggregate( Tail([Time].[MonthYear].[Month Year].AllMembers ,24) )';
   DEFINE MEMBER "[Transaction Summary].[Time].[YMD].[All Years].[Rolling 36 Months]" as 'Aggregate( Tail([Time].[MonthYear].[Month Year].AllMembers ,36) )';

run;

%put ******* Build Performance Aggregates *******;
proc olap CUBE= "&cube";

   METASVR
      HOST        = "vSAS"
      PORT        = 8561
      OLAP_SCHEMA = "SASApp - OLAP Schema";

   AGGREGATION 'Month Year'n 'Party Number'n 'Party Type'n NAICS TransactionType TransactionCategory City County State
      / NAME      = 'Month Year Reporting Base 1';
   AGGREGATION 'Month Year'n 'Party Number'n 'Party Type'n NAICS TransactionType TransactionCategory
      / NAME      = 'Month Year Reporting 1';
   AGGREGATION 'Month Year'n 'Party Number'n 'Account Number'n
      / NAME      = 'Month Year Reporting 2';
   AGGREGATION 'Month Year'n State City
      / NAME      = 'Month Year Reporting 3';
   AGGREGATION 'Month Year'n  
      / NAME      = 'Top Month Year';

run;
