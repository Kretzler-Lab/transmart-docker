--
-- Name: search_taxonomy_level2; Type: VIEW; Schema: searchapp; Owner: -
--
CREATE VIEW searchapp.search_taxonomy_level2 AS
    SELECT st.term_id
	   , st.term_name
	   , stl1.category_name
      FROM searchapp.search_taxonomy_rels str,
	   searchapp.search_taxonomy st,
	   searchapp.search_taxonomy_level1 stl1
     WHERE ((str.parent_id = stl1.term_id)
	    AND (str.child_id = st.term_id));

