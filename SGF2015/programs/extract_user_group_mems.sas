/* Final SAS dataset output */
libname sgf2015 '/projects/SGF2015/data';
/* Extract all user/group/role metadata - requires administrator user */
%mduextr(libref=work);

/* Add additional attributes, restructure columns to fit standardized model for analysis */
proc sql;
  /* Group to group memberships */
  /* Note: groupmemgroups_info contains group/role objects and their parent(s) */
  /* id = parent or group listed in "member of" in SMC                         */
  /* memid = object                                                            */
  create table gginfo as
    select
      groupmemgroups_info.memId as object_id,
      groupmemgroups_info.memName as object_name,
      object.displayname as object_displayname,
      coalesceC(upcase(object.grpType),'GROUP') length=20 as object_type,
      object.description as object_description,
      groupmemgroups_info.id as parent_id,
      groupmemgroups_info.Name as parent_name,
      parent.displayname as parent_displayname,
      coalesceC(upcase(parent.grpType),'GROUP') length=20 as parent_type,
      parent.description as parent_description
    from groupmemgroups_info
      left join idgrps as parent on groupmemgroups_info.id = parent.keyid
      left join idgrps as object on groupmemgroups_info.memid = object.keyid
  ;
  /* User to group memberships */
  create table gpinfo as
    select
      groupmempersons_info.memId as object_id,
      groupmempersons_info.memName as object_name,
      usr.displayname as object_displayname,
      'USER' length=20 as object_type,
      groupmempersons_info.memDesc as object_description,
      usr.title as user_title,
      groupmempersons_info.id as parent_id,
      groupmempersons_info.name as parent_name,
      group.displayname as parent_displayname,
      coalesceC(upcase(group.grpType),'GROUP') length=20 as parent_type,
      group.description as parent_description
    from groupmempersons_info
      left join idgrps as group on groupmempersons_info.id = group.objid
      left join person as usr on groupmempersons_info.memid = usr.objid
  ;
quit;

/* Append both sets */
data sgf2015.metadata_user_object_rels;
  length 
    object_id $20 object_name $100 object_displayname $256 
    object_type $100 object_description $256 user_title $200 
    parent_id $20 parent_name $100 parent_displayname $256 
    parent_type $100 parent_description $256 relationship_type $20
  ;
  set 
    gpinfo(in=users)
    gginfo(in=groups)
    idgrps(in=terminating_groups drop=externalkey keyid 
      rename=
        (
          objid = object_id
          name = object_name
          displayname = object_displayname
          grpType = object_type
          description = object_description
        )
    )
  ;

  /* Cleanup */
  object_displayname = coalesceC(object_displayname,object_name);
  parent_displayname = coalesceC(parent_displayname,parent_name);
  if terminating_groups then object_type = coalesceC(upcase(object_type),'GROUP');
  
  /* Define relationships */
  if users then relationship_type = 'GROUP-USER';
    else if groups then relationship_type = CATS(upcase(parent_type),'-',upcase(object_type));
    else if terminating_groups then relationship_type = 'TERMINATING';

run;

proc sort data=sgf2015.metadata_user_object_rels threads;
  by object_id;
run;
