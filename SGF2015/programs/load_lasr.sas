LIBNAME source BASE "/projects/SGF2015/data";
LIBNAME VALIBLA SASIOLA  TAG=HPS  PORT=10011 HOST="pegasus.zencos.com"  SIGNER="http://pegasus.zencos.com:7980/SASLASRAuthorization" ;

%let syscc = 0;

/* Remove if exists */
%deleteifexists(VALIBLA, metadata_user_object_rels);

/* Load into LASR */
data VALIBLA.metadata_user_object_rels ( label="Metadata User Object Relationships" );
  set source.metadata_user_object_rels;
  label
    object_id = 'Object ID'
    object_name = 'Object Name'
    object_displayname = 'Object Display Name'
    object_type = 'Object Type'
    object_description = 'Object Description'
    user_title = 'User Title'
    parent_id = 'Parent ID'
    parent_name = 'Parent Name'
    parent_displayname = 'Parent Display Name'
    parent_type = 'Parent Type'
    parent_description = 'Parent Description'
    relationship_type = 'Relationship Type'
    relationship_count = 'Relationship Count'
  ;
  relationship_count = 1;
run;

%errorcheck;
/* Synchronize table registration */
%registerTable(LIBRARY=%str(/Projects/Visual Analytics LASR)
             , REPOSITORY=%str(Foundation)
             , TABLE=%str(metadata_user_object_rels)
             , FOLDER=%str(/Projects/SGF2015/LASR)
              );

