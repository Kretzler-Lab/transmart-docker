--
-- Name: search_auth_user_sec_access_v; Type: VIEW; Schema: searchapp; Owner: -
--
CREATE VIEW searchapp.search_auth_user_sec_access_v AS
    (SELECT sasoa.auth_sec_obj_access_id AS search_auth_user_sec_access_id
	    , sasoa.auth_principal_id AS search_auth_user_id
	    , sasoa.secure_object_id AS search_secure_object_id
	    , sasoa.secure_access_level_id AS search_sec_access_level_id
       FROM searchapp.search_auth_user sau,
	    searchapp.search_auth_sec_object_access sasoa
      WHERE (sau.id = sasoa.auth_principal_id)
      UNION
     SELECT sasoa.auth_sec_obj_access_id AS search_auth_user_sec_access_id
	    , sagm.auth_user_id AS search_auth_user_id
	    , sasoa.secure_object_id AS search_secure_object_id
	    , sasoa.secure_access_level_id AS search_sec_access_level_id
       FROM searchapp.search_auth_group sag,
	    searchapp.search_auth_group_member sagm,
	    searchapp.search_auth_sec_object_access sasoa
      WHERE ((sag.id = sagm.auth_group_id)
	     AND (sag.id = sasoa.auth_principal_id)))
    UNION
    SELECT sasoa.auth_sec_obj_access_id AS search_auth_user_sec_access_id
	   , NULL::bigint AS search_auth_user_id
	   , sasoa.secure_object_id AS search_secure_object_id
	   , sasoa.secure_access_level_id AS search_sec_access_level_id
      FROM searchapp.search_auth_group sag,
	   searchapp.search_auth_sec_object_access sasoa
     WHERE (((sag.group_category)::text = 'EVERYONE_GROUP'::text)
	    AND (sag.id = sasoa.auth_principal_id));

