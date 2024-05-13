/****************************************************************************/
/* Code written by Stephen Overton (stephen.overton@gmail.com)              */
/* Original code and SAS Macros are provided with SAS Foundation.           */
/****************************************************************************/
/* Use the Meta* options to specify the metadata server connection options  */
/* where the user information will be loaded.                               */
/****************************************************************************/
/* network name/address of the metadata server. */
options metaserver=localhost 
/* Port Metadata Server is listening on.*/
metaport=8561               
/* Domain Qualified Userid for connection to metadata server. */
metauser="sasadm@saspw"  
/* Password for userid above. */
metapass="Admin123"         
 /* Protocol for Metadata Server.  */ 
metaprotocol=bridge          
/* Default location of user information is in the foundation repository. */
metarepository=foundation;  

/** Extract current metadata information and store in separate location for comparison **/
%mduextr(libref=work);

/** Macro to extract users selected from macro variables and create list for SQL **/
%macro user_list;
  %if %symexist(USER_COUNT) %then %do;
    %do i=1 %to &USER0;
      "&&USER&i"
    %end;
  %end;
  %else %do;
    "&USER"
  %end; 
%mend user_list;

/** Only keep users and groups that are selected from previous STP **/
proc sql;
  delete from &SAVE_importlibref..email
  where trim(keyid) NOT IN (%user_list);

  delete from &SAVE_importlibref..location
  where trim(keyid) NOT IN (%user_list);

  delete from &SAVE_importlibref..logins
  where trim(keyid) NOT IN (%user_list);

  delete from &SAVE_importlibref..person
  where trim(keyid) NOT IN (%user_list);

  /** Move users which are already in metadata **/
  create table excp_users as
    select * from &SAVE_importlibref..person person
    where trim(keyid) IN (
      select trim(keyid) from work.person where externalkey = 1
    );

  /** Remove users from incoming tables that are already in metadata **/
  delete from &SAVE_importlibref..person
  where trim(keyid) IN ( select keyid from excp_users );

  delete from &SAVE_importlibref..email
  where trim(keyid) IN ( select keyid from excp_users );

  delete from &SAVE_importlibref..location
  where trim(keyid) IN ( select keyid from excp_users );

  delete from &SAVE_importlibref..logins
  where trim(keyid) IN ( select keyid from excp_users );

  /** Get count of users imported **/
  select count(*) into :users_to_import from &SAVE_importlibref..person;

  /** For the scope of this paper, groups will not be imported. Remove all data related to groups. **/
  delete from &SAVE_importlibref..grpmems;
  delete from &SAVE_importlibref..idgrps;
quit;

/****************************************************************************
 ****************************************************************************
 **                                                                        **
 **  SECTION 5: %mduimpl reads the canonical datasets, generates           **
 **             XML representing metadata objects, and invokes PROC        **
 **             METADATA to load the metadata.                             **
 **                                                                        **
 ****************************************************************************
 ****************************************************************************/ 
%macro Execute_Load;
  /* if the _EXTRACTONLY macro is set, then return and don't do any load processing. */
  %if %symexist(_EXTRACTONLY) %then %return;
  /* if there are no users to import, the return and do not process empty tables */
  %if &users_to_import = 0 %then %return;
  %mduimplb(libref=&SAVE_importlibref,extidtag=&SAVE_ADExtIDTag);
%mend Execute_Load;
%Execute_Load;

ods listing close;
ods html body=_webout path=&_tmpcat(url=&_replay) style=Seaside parameters=("drilltarget"="_top");

/** Output Users Imported **/
TITLE1 "Users Imported";
proc report data=&SAVE_importlibref..PERSON nowd;
	column displayname name keyid title description;
	define displayname / group 'displayname' format=$256. missing order=formatted;
	define name / group 'name' format=$60. missing order=formatted;
	define keyid / group 'keyid' format=$200. missing order=formatted;
	define title / group 'title' format=$200. missing order=formatted;
	define description / group 'description' format=$200. missing order=formatted;
	run;
quit;
TITLE; FOOTNOTE;

/** Output Users Already in Metadata **/
TITLE1 "Users Already in Metadata";
proc report data=excp_users nowd;
	column displayname name keyid title description;
	define displayname / group 'displayname' format=$256. missing order=formatted;
	define name / group 'name' format=$60. missing order=formatted;
	define keyid / group 'keyid' format=$200. missing order=formatted;
	define title / group 'title' format=$200. missing order=formatted;
	define description / group 'description' format=$200. missing order=formatted;
	run;
quit;
TITLE; FOOTNOTE;

ods html close;
ods listing;

/** Kill the session to cleanup **/
%let rc=%sysfunc(stpsrv_session(delete));
