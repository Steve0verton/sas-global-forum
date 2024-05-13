/*------------------------------------------------------------------------------------------
  PROGRAMMER   : Stephen Overton (SAS Institute Partner) (soverton@overtontechnologies.com)
  PURPOSE      : Build fake bank transactions for SGF13 
|-----------------------------------------------------------------------------------------*/
LIBNAME defiant POSTGRES  INSERTBUFF=1000  READBUFF=1000  DATABASE=dev 
   PRESERVE_COL_NAMES=YES  PRESERVE_TAB_NAMES=YES  DBCOMMIT=1000
   SERVER=defiant  SCHEMA=public  USER=enterprise  PASSWORD="{SAS002}1D5793391C1104E20E3CF4CD2A793E2B" ;
/* For bulk loading (without buffering) */
/*LIBNAME defiant POSTGRES  DATABASE=dev  AUTOCOMMIT=YES*/
/*   PRESERVE_COL_NAMES=YES  PRESERVE_TAB_NAMES=YES */
/*   SERVER=defiant  SCHEMA=public  USER=enterprise  PASSWORD="{SAS002}1D5793391C1104E20E3CF4CD2A793E2B" ;*/

%dbug(level=2);
proc options; run;
%let syscc=0;

/**** Generate a ton of transactions from Jan 1, 2010 - Dec 31, 2012 ****/
/* Get initial keys to generate data for */
proc sql threads;
  select max(party_account_key) into :accounts from defiant.dim_party_account;
quit; 

%errorcheck;
data stg_fact_transactions (bufsize=1M);
  length transaction_type_key party_account_key location_key transaction_date transaction_amount 8;
  do transaction_date = '01JAN2010'd to '31DEC2012'd; 
    do cycle = 1 to (9000 + round(rand("Uniform")*100)); /* cycle */ 
      /* Create a couple random transactions in a given */
      do t = 1 to (round(rand("Uniform")*6)+1);
        transaction_type_key = (round(rand("Uniform")*12) + 1);
        location_key = (round(rand("Uniform")*19999) + 1);
        transaction_amount = (round(rand("Uniform")*100) + round(rand("Uniform"),.01));
        party_account_key = round(rand("Uniform")*(&accounts-1))+1;
        output;
      end;
      /* Create a random set of suspicious high transactions 5% of the time each day */
      if rand('BERN',.05)=1 then do t = 1 to (round(rand("Uniform")*2)+1);
        transaction_type_key = (round(rand("Uniform")*12) + 1);
        location_key = (round(rand("Uniform")*19999) + 1);
        transaction_amount = ((round(rand("Uniform")*30000) + 10000) + round(rand("Uniform"),.01));
        output;
      end;
      /* Create suspicious very high transaction data 2 percent of the time each day */
      if rand('BERN',.02)=1 then do;
        transaction_type_key = (round(rand("Uniform")*12) + 1);
        location_key = (round(rand("Uniform")*19999) + 1);
        transaction_amount = ((round(rand("Uniform")*500000) + 50000) + round(rand("Uniform"),.01));
        output;
      end;
    end;
  end;
  drop t cycle;
run;

/* Sort */
/*proc sort data=stg_fact_transactions threads;*/
/*  by transaction_date;*/
/*run;*/

/* Add PK */
data stg_fact_transactions;
  transaction_key = _N_;
  set stg_fact_transactions;
run;

%errorcheck;
/* Insert into fact table */
proc append base=defiant.fact_transactions
  ( bulkload=yes
    bl_datafile="/tmp/data" 
    bl_logfile="/tmp/bulkload_log" 
    BL_LOAD_METHOD=APPEND
  ) 
  data=stg_fact_transactions; 
run;

