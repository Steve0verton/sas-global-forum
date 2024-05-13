LIBNAME VALIBLA SASIOLA  TAG=HPS  PORT=10011 HOST="pegasus.zencos.com"  SIGNER="http://pegasus.zencos.com:7980/SASLASRAuthorization" ;
libname sgf16 '/projects/SGF2016/data';
%fcsautoexec(fcs_rpt=1);

data alerts(bufsize=256K);
  length ALERT_ID $20 ALERT_STATUS $64 ALERT_CREATE_DATE 8 SCENARIO_CATEGORY SCENARIO_SHORT_DESC SCENARIO_DESCRIPTION SCENARIO_NAME ALERT_DISPOSITION ALERT_INVESTIGATOR_USER_NAME
    SCENARIO_RUN_FREQUENCY SCENARIO_STATUS $100 INVESTIGATION_OUTCOME $50;
  /* Customer attributes */
  length PARTY_NUMBER $50 PARTY_NAME $200 PARTY_TYPE_DESC PARTY_CRR_BAND $50 PARTY_INDUSTRY_DESC $255 OCCUPATION_DESC $50 RESIDENCE_COUNTRY_CODE CITIZENSHIP_COUNTRY_CODE $10
         STREET_ADDRESS_1 STREET_CITY_NAME STREET_STATE_CODE STREET_POSTAL_CODE $40 MSB_IND PEP_IND NON_PROFIT_IND 8;
  length party_avg_mon_trans_amount party_avg_mon_cash_amount party_avg_mon_wire_amount party_avg_mon_trans_cnt party_avg_mon_cash_cnt party_avg_mon_wire_cnt high_risk_product_ind 8;
  format party_avg_mon_trans_amount party_avg_mon_cash_amount party_avg_mon_wire_amount dollar22.2 party_avg_mon_trans_cnt party_avg_mon_cash_cnt party_avg_mon_wire_cnt comma12.1;
  format high_risk_product_ind MSB_IND PEP_IND NON_PROFIT_IND ynbool.;
  label party_avg_mon_trans_amount='Party AVG Monthly Transaction Amount' 
  			party_avg_mon_cash_amount='Party AVG Monthly Cash Amount'
  		  party_avg_mon_wire_amount='Party AVG Monthly Wire Amount'
  		  party_avg_mon_trans_cnt='Party AVG Monthly Transaction Count'
  		  party_avg_mon_cash_cnt='Party AVG Monthly Cash Count'
  		  party_avg_mon_wire_cnt='Party AVG Monthly Wire Count'
  		  high_risk_product_ind='High Risk Product Indicator'
  		  investigation_outcome='Investigation Outcome'
  		  MSB_IND='MSB Indicator'
  		  PEP_IND='PEP Indicator'
  		  NON_PROFIT_IND='Non Profit Indicator'
  		  RESIDENCE_COUNTRY_CODE='Residence Country Code'
  		  CITIZENSHIP_COUNTRY_CODE='Citizenship Country Code'
  		  STREET_ADDRESS_1='Party Address 1'
  		  STREET_CITY_NAME='Party Address 2'
  		  STREET_STATE_CODE='Party Address State Code'
  		  STREET_POSTAL_CODE='Party Address Postal Code'
  		  OCCUPATION_DESC='Party Occupation'
  		  PARTY_NAME='Party Name'
  ;
  
  set sgf16.alert_reporting(keep=
     alert_id alert_status alert_create_date alert_disposition alert_investigator_user_name
     scenario_name scenario_short_desc scenario_description scenario_category scenario_run_frequency scenario_status
     party_number party_type_desc party_crr_band party_industry_desc
    );
  where not missing(party_number);

  /* Add in party data from CORE */
  if _n_ = 1 then do;
    declare hash party_data(DATASET:"FCS_RPT.RPT_PARTY_DIM_CURR"); 
    party_data.defineKey("PARTY_NUMBER");
    party_data.defineData("party_name","occupation_desc","residence_country_code","citizenship_country_code","street_address_1","street_city_name","street_state_code","street_postal_code");
    party_data.defineDone();
  end;
  rc_party_data = party_data.find(key:party_number);

  /* Define investigation outcome, key target variable to predict */
  seed = round(rand("Uniform")*100);
  if seed >=0 and seed < 90 then INVESTIGATION_OUTCOME='False Positive';
    else if seed >= 90 and seed < 96 then INVESTIGATION_OUTCOME='Investigation (NOSAR)';
    else if seed >= 96 then INVESTIGATION_OUTCOME='Investigation (SAR)';

  residence_country_code = substr(coalesceC(residence_country_code ,"US"),1,2);
  citizenship_country_code = substr(coalesceC(citizenship_country_code,"US"),1,2);
  
  /* Transaction amounts */
  select (party_type_desc );
    when ('INDIVIDUAL') do;
      party_avg_mon_trans_amount = round(rand("WEIBULL",1,.2)*10000);
      party_avg_mon_cash_amount = round(rand("WEIBULL",1,.5)*1000);
      party_avg_mon_wire_amount = round(rand("Uniform")*40) + 0;
      party_avg_mon_trans_cnt = round(rand("Uniform")*3) + 2;
      party_avg_mon_cash_cnt = round(rand("Uniform")*2) + 2;
      if rand('BERN',.1) then party_avg_mon_wire_cnt = 2; else party_avg_mon_wire_cnt = 0;
    end;
    when ('ORGANIZATION') do;
      if rand('BERN',.3) then party_avg_mon_trans_amount = round(rand("WEIBULL",1,.9)*5000)+80000; else party_avg_mon_trans_amount = round(rand("WEIBULL",1,.5)*10000);
      if rand('BERN',.3) then party_avg_mon_cash_amount = round(rand("WEIBULL",1,.7)*5000); else party_avg_mon_cash_amount = round(rand("WEIBULL",1,.5)*1000);
      if rand('BERN',.3) then party_avg_mon_wire_amount = round(rand("WEIBULL",1,.8)*4000)+50000; else party_avg_mon_wire_amount = round(rand("WEIBULL",1,.9)*7000)+5000;
      party_avg_mon_trans_cnt = round(rand("Uniform")*50) + 20;
      party_avg_mon_cash_cnt = round(rand("Uniform")*10) + 5;
      party_avg_mon_wire_cnt = round(rand("Uniform")*20) + 2;   
    end;
    otherwise;
  end;
  
  /* High risk products */ 
  if rand('BERN',.2) then high_risk_product_ind = 1; else high_risk_product_ind =0;
   
  /* Add risky segments */
  select (INVESTIGATION_OUTCOME);
    when ('Investigation (SAR)') do;
      if scenario_category = 'Cash Activity' then do;
        if party_type_desc = 'INDIVIDUAL' then do;
          do x = 1 to round(rand("Uniform")*5) + 5;
            alert_id = strip(put(1000000 + _N_ + x,10.));
            alert_create_date = alert_create_date + round(rand("Uniform")*10) + 5;
            alert_disposition = 'Create Investigation';
            /* Party segment - jeweler/, small number of PEPs, foreign high risk citizenships, more small transaction typologies */
            seed = round(rand("Uniform")*100);
            if seed >=0 and seed < 40 then occupation_desc='JEWELER';
              else if seed >= 40 and seed < 80 then occupation_desc='USER CAR DEALER';
              else if seed >= 80 then occupation_desc='RETAIL';
            if rand('BERN',.6) then pep_ind=1;
            if rand('BERN',.95) then high_risk_product_ind =1;
            scenario_short_desc = 'Large Cash Deposits';
            if seed >=0 and seed < 40 then citizenship_country_code='IR';
              else if seed >= 40 and seed < 80 then citizenship_country_code='YE';
              else if seed >= 80 then citizenship_country_code='KP'; 
            party_avg_mon_trans_amount = round(rand("WEIBULL",1.3,1.6)*1000) + 9500;
			      party_avg_mon_cash_amount = round(rand("WEIBULL",1.3,1.6)*1000) + 9500;
			      party_avg_mon_wire_amount = 0;
			      party_avg_mon_trans_cnt = round(rand("Uniform")*5) + 50;
			      party_avg_mon_cash_cnt = round(rand("Uniform")*10) + 40;
			      party_avg_mon_wire_cnt = 0;
            output;
          end;
        end; 
      end;
      if scenario_category = 'Wire Activity' then do;
        if party_type_desc = 'INDIVIDUAL' then do;
          do x = 1 to round(rand("Uniform")*2) + 1;
            alert_id = strip(put(1000000 + _N_ + x,10.));
            alert_create_date = alert_create_date + round(rand("Uniform")*10) + 10;
            alert_disposition = 'Create Investigation';
            /* Party segment - mostly high risk, attorney/professional/firearm dealer/travel agent, some PEPs, high risk citizenship */
            if rand('BERN',.9) then party_crr_band='HIGH'; else party_crr_band='MED';
            seed = round(rand("Uniform")*100);
            if seed >=0 and seed < 30 then occupation_desc='JEWELER';
              else if seed >= 30 and seed < 70 then occupation_desc='ATTORNEY';
              else if seed >= 70 then occupation_desc='REAL ESTATE BROKER';
            if rand('BERN',.7) then pep_ind=1;
            scenario_short_desc = 'Large Incoming Wires';
            if seed >=0 and seed < 60 then citizenship_country_code='KY';
              else if seed >= 60 and seed < 80 then citizenship_country_code='BR';
              else if seed >= 80 then citizenship_country_code='BB'; 
            party_avg_mon_trans_amount = round(rand("WEIBULL",1.3,1)*5000) + 15000;
			      party_avg_mon_cash_amount = 0;
			      party_avg_mon_wire_amount = round(rand("WEIBULL",1.3,1)*5000) + 15000;
			      party_avg_mon_trans_cnt = round(rand("Uniform")*5) + 50;
			      party_avg_mon_cash_cnt = 0;
			      party_avg_mon_wire_cnt = round(rand("Uniform")*10) + 40;
            output;
          end;
        end; else if party_type_desc = 'ORGANIZATION' then do;
          do x = 1 to round(rand("Uniform")*8) + 5;
            alert_id = strip(put(1000000 + _N_ + x,10.));
            alert_create_date = alert_create_date + round(rand("Uniform")*15) + 5;
            alert_disposition = 'Create Investigation';
            /* Party segment - mostly high risk, mix in some MSBs and non profits */
            if rand('BERN',.9) then party_crr_band='HIGH'; else party_crr_band='MED';
            if rand('BERN',.8) then msb_ind=1; else non_profit_ind=1;
            seed = round(rand("Uniform")*100);
            if seed >=0 and seed < 40 then party_industry_desc='INTERNET GAMBLING';
              else if seed >= 40 and seed < 80 then party_industry_desc='USED CAR DEALERSHIP';
              else if seed >= 80 then party_industry_desc='CONVENIENCE STORE';
            scenario_short_desc = 'High Velocity Funds - Wires Out';
            if msb_ind = 1 then party_industry_desc='MONEY SERVICE BUSINESS';
            if non_profit_ind=1 then party_industry_desc='NONPROFIT ORGANIZATION';
            party_avg_mon_trans_amount = round(rand("WEIBULL",1.3,1)*7000)+15000;
			      party_avg_mon_cash_amount = 0;
			      party_avg_mon_wire_amount = round(rand("WEIBULL",1.3,1)*7000)+15000;
			      party_avg_mon_trans_cnt = round(rand("Uniform")*5) + 50;
			      party_avg_mon_cash_cnt = 0;
			      party_avg_mon_wire_cnt = round(rand("Uniform")*10) + 80;
            output;
          end;
        end;
      end;
      if scenario_category = 'Structuring and Obfuscation' then do;
        if party_type_desc = 'INDIVIDUAL' then do;
          do x = 1 to round(rand("Uniform")*4) + 2;
            alert_id = strip(put(1000000 + _N_ + x,10.));
            alert_create_date = alert_create_date + round(rand("Uniform")*5) + 2;
            alert_disposition = 'Create Investigation';
            /* Party segment - have more Structured Deposits Across Locations, leave occupation more random, citizenship foreign */
            if rand('BERN',.75) then scenario_short_desc = 'Structured Deposits Across Locations';
            if rand('BERN',.75) then party_crr_band='HIGH'; else party_crr_band='MED';
            if rand('BERN',.95) then high_risk_product_ind =1;
            seed = round(rand("Uniform")*100);
            if seed >=0 and seed < 20 then occupation_desc='DOCTOR';
              else if seed >= 20 and seed < 80 then occupation_desc='REAL ESTATE BROKER';
              else if seed >= 80 then occupation_desc='RETAIL';
            scenario_short_desc = 'Multiple Branch Usage';
            if rand('BERN',.5) then pep_ind=1;
            if seed >=0 and seed < 40 then citizenship_country_code='IR';
              else if seed >= 40 and seed < 80 then citizenship_country_code='YE';
              else if seed >= 80 then citizenship_country_code='KP';
            party_avg_mon_trans_amount = round(rand("Uniform")*500) + 9000;
			      party_avg_mon_cash_amount = round(rand("Uniform")*500) + 9000;
			      party_avg_mon_wire_amount = 0;
			      party_avg_mon_trans_cnt = round(rand("Uniform")*5) + 50;
			      party_avg_mon_cash_cnt = round(rand("Uniform")*10) + 40;
			      party_avg_mon_wire_cnt = 0;
            output;
          end;
        end;
      end;
    end;
    
    when ('Investigation (NOSAR)') do;
      if scenario_category = 'Cash Activity' then do;
        if party_type_desc = 'INDIVIDUAL' then do;
          do x = 1 to round(rand("Uniform")*5) + 2;
            alert_id = strip(put(1000000 + _N_ + x,10.));
            alert_create_date = alert_create_date + round(rand("Uniform")*10) + 5;
            alert_disposition = 'Create Investigation';
            /* Party segment - jeweler/, small number of PEPs, foreign high risk citizenships, more small transaction typologies */
            seed = round(rand("Uniform")*100);
            if seed >=0 and seed < 40 then occupation_desc='JEWELER';
              else if seed >= 40 and seed < 80 then occupation_desc='USER CAR DEALER';
              else if seed >= 80 then occupation_desc='RETAIL';
            if rand('BERN',.5) then pep_ind=1;
            if rand('BERN',.6) then high_risk_product_ind =1;
            scenario_short_desc = 'High-Risk Currencies';
            if seed >=0 and seed < 40 then citizenship_country_code='BZ';
              else if seed >= 40 and seed < 80 then citizenship_country_code='YE';
              else if seed >= 80 then citizenship_country_code='EG'; 
            party_avg_mon_trans_amount = round(rand("Uniform")*500) + 9000;
			      party_avg_mon_cash_amount = round(rand("Uniform")*1000) + 5000;
			      party_avg_mon_wire_amount = 0;
			      party_avg_mon_trans_cnt = round(rand("Uniform")*5) + 20;
			      party_avg_mon_cash_cnt = round(rand("Uniform")*10) + 10;
			      party_avg_mon_wire_cnt = 0;
            output;
          end;
        end; 
      end;
      if scenario_category = 'Wire Activity' then do;
        if party_type_desc = 'INDIVIDUAL' then do;
          do x = 1 to round(rand("Uniform")*5) + 2;
            alert_id = strip(put(1000000 + _N_ + x,10.));
            alert_create_date = alert_create_date + round(rand("Uniform")*10) + 10;
            alert_disposition = 'Create Investigation';
            /* Party segment - mostly high risk, attorney/professional/firearm dealer/travel agent, some PEPs, high risk citizenship */
            if rand('BERN',.9) then party_crr_band='HIGH'; else party_crr_band='MED';
            seed = round(rand("Uniform")*100);
            if seed >=0 and seed < 40 then occupation_desc='JEWELER';
              else if seed >= 40 and seed < 80 then occupation_desc='ATTORNEY';
              else if seed >= 80 then occupation_desc='TRAVEL AGENT';
            if rand('BERN',.3) then pep_ind=1;
            if rand('BERN',.2) then high_risk_product_ind =1;
            scenario_short_desc = 'Foreign Wire Activity';
            if seed >=0 and seed < 60 then citizenship_country_code='KY';
              else if seed >= 60 and seed < 80 then citizenship_country_code='BR';
              else if seed >= 80 then citizenship_country_code='BB'; 
            party_avg_mon_trans_amount = round(rand("WEIBULL",1.3,1)*1000)+5000;
			      party_avg_mon_cash_amount = 0;
			      party_avg_mon_wire_amount = round(rand("WEIBULL",1.3,1)*1000)+5000;
			      party_avg_mon_trans_cnt = round(rand("Uniform")*5) + 20;
			      party_avg_mon_cash_cnt = 0;
			      party_avg_mon_wire_cnt = round(rand("Uniform")*5) + 10;
            output;
          end;
        end; else if party_type_desc = 'ORGANIZATION' then do;
          do x = 1 to round(rand("Uniform")*2) + 1;
            alert_id = strip(put(1000000 + _N_ + x,10.));
            alert_create_date = alert_create_date + round(rand("Uniform")*15) + 5;
            alert_disposition = 'Create Investigation';
            /* Party segment - mostly high risk, mix in some MSBs and non profits */
            if rand('BERN',.9) then party_crr_band='HIGH'; else party_crr_band='MED';
            if rand('BERN',.8) then msb_ind=1; else non_profit_ind=1;
            seed = round(rand("Uniform")*100);
            if seed >=0 and seed < 40 then party_industry_desc='CASINO';
              else if seed >= 40 and seed < 80 then party_industry_desc='GAS STATION';
              else if seed >= 80 then party_industry_desc='TRAVEL AGENCY';
            scenario_short_desc = 'High Velocity Funds - Wires Out';
            if msb_ind = 1 then party_industry_desc='MONEY SERVICE BUSINESS';
            if non_profit_ind=1 then party_industry_desc='NONPROFIT ORGANIZATION';
            party_avg_mon_trans_amount = round(rand("WEIBULL",1.3,1)*2000)+5000;
			      party_avg_mon_cash_amount = 0;
			      party_avg_mon_wire_amount = round(rand("WEIBULL",1.3,1)*2000)+5000;
			      party_avg_mon_trans_cnt = round(rand("Uniform")*5) + 30;
			      party_avg_mon_cash_cnt = 0;
			      party_avg_mon_wire_cnt = round(rand("Uniform")*5) + 20;
            output;
          end;
        end;
      end;
      if scenario_category = 'Structuring and Obfuscation' then do;
        if party_type_desc = 'INDIVIDUAL' then do;
          do x = 1 to round(rand("Uniform")*2) + 2;
            alert_id = strip(put(1000000 + _N_ + x,10.));
            alert_create_date = alert_create_date + round(rand("Uniform")*5) + 2;
            alert_disposition = 'Create Investigation';
            /* Party segment - have more Structured Deposits Across Locations, leave occupation more random, citizenship foreign */
            if rand('BERN',.65) then scenario_short_desc = 'Structured Deposits Across Locations';
            if rand('BERN',.55) then party_crr_band='HIGH'; else party_crr_band='MED';
            if rand('BERN',.3) then high_risk_product_ind =1;
            seed = round(rand("Uniform")*100);
            if seed >=0 and seed < 40 then occupation_desc='JEWELER';
              else if seed >= 40 and seed < 80 then occupation_desc='USER CAR DEALER';
              else if seed >= 80 then occupation_desc='RETAIL';
/*             scenario_short_desc = 'ATM Deposits at Multiple Locations'; */
            if seed >=0 and seed < 40 then citizenship_country_code='KZ';
              else if seed >= 40 and seed < 80 then citizenship_country_code='KW';
              else if seed >= 80 then citizenship_country_code='KG';
            party_avg_mon_trans_amount = round(rand("Uniform")*500) + 9000;
			      party_avg_mon_cash_amount = round(rand("Uniform")*100) + 9000;
			      party_avg_mon_wire_amount = 0;
			      party_avg_mon_trans_cnt = round(rand("Uniform")*5) + 10;
			      party_avg_mon_cash_cnt = round(rand("Uniform")*2) + 5;
			      party_avg_mon_wire_cnt = 0;
            output;
          end;
        end; else if party_type_desc = 'ORGANIZATION' then do;
          do x = 1 to round(rand("Uniform")*4) + 2;
            alert_id = strip(put(1000000 + _N_ + x,10.));
            alert_create_date = alert_create_date + round(rand("Uniform")*5) + 2;
            alert_disposition = 'Create Investigation';
            /* Party segment - have more Structured Deposits Across Locations, leave occupation more random, citizenship foreign */
/*             if rand('BERN',.75) then scenario_short_desc = 'Structured Deposits Across Locations'; */
            if rand('BERN',.55) then party_crr_band='HIGH'; else party_crr_band='MED';
            if rand('BERN',.2) then high_risk_product_ind =1;
            seed = round(rand("Uniform")*100);
            if seed >=0 and seed < 40 then occupation_desc='GAS STATION';
              else if seed >= 40 and seed < 80 then occupation_desc='REAL ESTATE BROKERAGE';
              else if seed >= 80 then occupation_desc='INTERNET GAMBLING';
            scenario_short_desc = 'Structured Withdrawals';
            if seed >=0 and seed < 40 then citizenship_country_code='KZ';
              else if seed >= 40 and seed < 80 then citizenship_country_code='KW';
              else if seed >= 80 then citizenship_country_code='KG';
            party_avg_mon_trans_amount = round(rand("Uniform")*500) + 9000;
			      party_avg_mon_cash_amount = round(rand("Uniform")*100) + 9000;
			      party_avg_mon_wire_amount = 0;
			      party_avg_mon_trans_cnt = round(rand("Uniform")*5) + 10;
			      party_avg_mon_cash_cnt = round(rand("Uniform")*2) + 5;
			      party_avg_mon_wire_cnt = 0;
            output;
          end;
        end;
        
      end;
    end;
    otherwise do;  /* false positives */
      if scenario_category = 'Cash Activity' then do;
        if party_type_desc = 'INDIVIDUAL' then do;
          do x = 1 to round(rand("Uniform")*3) + 4;
            alert_id = strip(put(1000000 + _N_ + x,10.));
            alert_create_date = alert_create_date + round(rand("Uniform")*10) + 5;
            alert_disposition = 'False Positive';
            /* Party segment - jeweler/, small number of PEPs, foreign high risk citizenships, more small transaction typologies */
            seed = round(rand("Uniform")*100);
            if seed >=0 and seed < 40 then occupation_desc='JEWELER';
              else if seed >= 40 and seed < 80 then occupation_desc='USER CAR DEALER';
              else if seed >= 80 then occupation_desc='UNEMPLOYED';
            if rand('BERN',.5) then pep_ind=1;
            scenario_short_desc = 'Large Cash Deposits';
            if seed >=0 and seed < 40 then citizenship_country_code='IR';
              else if seed >= 40 and seed < 80 then citizenship_country_code='YE';
              else if seed >= 80 then citizenship_country_code='US'; 
            party_avg_mon_trans_amount = round(rand("Uniform")*500) + 3200;
			      party_avg_mon_cash_amount = round(rand("Uniform")*100) + 2000;
			      party_avg_mon_wire_amount = 0;
			      party_avg_mon_trans_cnt = round(rand("Uniform")*5) + 5;
			      party_avg_mon_cash_cnt = round(rand("Uniform")*3) + 3;
			      party_avg_mon_wire_cnt = 0;
            output;
          end;
        end; 
      end;
      if scenario_category = 'Wire Activity' then do;
        if party_type_desc = 'ORGANIZATION' then do;
          do x = 1 to round(rand("Uniform")*3) + 1;
            alert_id = strip(put(1000000 + _N_ + x,10.));
            alert_create_date = alert_create_date + round(rand("Uniform")*15) + 5;
            alert_disposition = 'False Positive';
            /* Party segment - mostly high risk, mix in some MSBs and non profits */
            if rand('BERN',.8) then msb_ind=1; else non_profit_ind=1;
            seed = round(rand("Uniform")*100);
            if seed >=0 and seed < 40 then party_industry_desc='CASINO';
              else if seed >= 40 and seed < 80 then party_industry_desc='USED CAR DEALERSHIP';
              else if seed >= 80 then party_industry_desc='TRAVEL AGENCY';
            scenario_short_desc = 'Large Incoming Wires';
            if msb_ind = 1 then party_industry_desc='MONEY SERVICE BUSINESS';
            if non_profit_ind=1 then party_industry_desc='NONPROFIT ORGANIZATION';
            party_avg_mon_trans_amount = round(rand("WEIBULL",1.2,1)*500)+1000;
			      party_avg_mon_cash_amount = 0;
			      party_avg_mon_wire_amount = round(rand("WEIBULL",1.2,1)*500)+1000;
			      party_avg_mon_trans_cnt = round(rand("Uniform")*5) + 20;
			      party_avg_mon_cash_cnt = 0;
			      party_avg_mon_wire_cnt = round(rand("Uniform")*5) + 10;
            output;
          end;
        end;
      end;
      output;
    end;
  end;

  drop seed x rc_party_data;
run;

data alerts;
  set alerts;
  where alert_create_date < today();
run;

%deleteifexists(VALIBLA, SGF16_ALERTS);
data VALIBLA.SGF16_ALERTS ( label="SGF16 Alerts" );                                                                                                              
   set alerts;                                                                                                                                           
run;
%registerTable(LIBRARY=%str(/Projects/Visual Analytics LASR)
             , REPOSITORY=%str(Foundation)
             , TABLE=%str(SGF16_ALERTS)
             , FOLDER=%str(/Projects/SGF2016/LASR)
              );
