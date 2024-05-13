/****************************************************************************/
/* Use the Meta* options to specify the metadata server connection options  */
/* where the user information will be loaded.                               */
/****************************************************************************/
options metaserver=localhost /* network name/address of the      */
                                        /*   metadata server.               */
                                        
        metaport=8561               /* Port Metadata Server is listening on.*/

        metauser="sasadm@saspw"  /* Domain Qualified Userid for          */
                                    /*   connection to metadata server.     */

        metapass="Admin123"         /* Password for userid above.           */
 
        metaprotocol=bridge         /* Protocol for Metadata Server.        */  

        metarepository=foundation;  /* Default location of user information */
                                    /*   is in the foundation repository.   */

options mprint mlogic;
/** Extract current metadata information and store in separate location for comparison **/
libname mdextr 'C:\SAS\WORK\mdextract';
%mduextr(libref=mdextr);
libname sgf2012 'C:\SAS Projects\SGF2012\data';

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
  where keyid NOT IN (%user_list);

  /** Remove groups not associated with users by removing group associations first **/
  delete from &SAVE_importlibref..grpmems
  where memkeyid NOT IN (%user_list);

  /** Then inner join to only keep groups with selected users **/
  delete from &SAVE_importlibref..idgrps
  where trim(keyid) NOT IN (
    select trim(idgrps.keyid)
    from
      &SAVE_importlibref..grpmems grpsmems inner join &SAVE_importlibref..idgrps idgrps
        on grpsmems.grpkeyid = idgrps.keyid
    );

  /** Then remove groups which already exist in metadata **/
  delete from &SAVE_importlibref..idgrps
  where trim(keyid) IN (
    select trim(group_info.ExtId_Identifier)
    from mdextr.group_info
    );

  create table sgf2012.idgrps as select * from &SAVE_importlibref..idgrps;
  create table sgf2012.grpmems as select * from &SAVE_importlibref..grpmems;

  delete from &SAVE_importlibref..location
  where keyid NOT IN (%user_list);

  delete from &SAVE_importlibref..logins
  where keyid NOT IN (%user_list);

  delete from &SAVE_importlibref..person
  where keyid NOT IN (%user_list);
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

ods html close;
ods listing;

/** Cleanup library with extracted metadata **/
proc datasets library=mdextr kill;
run;
quit;

/** Kill the session to cleanup **/
%let rc=%sysfunc(stpsrv_session(delete));