--
-- Name: search_taxonomy_terms_cats; Type: VIEW; Schema: searchapp; Owner: -
--
CREATE VIEW searchapp.search_taxonomy_terms_cats AS
    SELECT DISTINCT union_results.term_id
		    , union_results.term_name
		    , union_results.category_name
      FROM ((((
	  SELECT search_taxonomy_level1.term_id
		 , search_taxonomy_level1.term_name
		 , search_taxonomy_level1.category_name
	    FROM searchapp.search_taxonomy_level1
	   UNION
	  SELECT search_taxonomy_level2.term_id
		 , search_taxonomy_level2.term_name
		 , search_taxonomy_level2.category_name
	    FROM searchapp.search_taxonomy_level2)
	    UNION
	    SELECT search_taxonomy_level3.term_id
	    , search_taxonomy_level3.term_name
	    , search_taxonomy_level3.category_name
	    FROM searchapp.search_taxonomy_level3)
	    UNION
	    SELECT search_taxonomy_level4.term_id
	    , search_taxonomy_level4.term_name
	    , search_taxonomy_level4.category_name
	    FROM searchapp.search_taxonomy_level4)
	    UNION
	    SELECT search_taxonomy_level5.term_id
	    , search_taxonomy_level5.term_name
	    , search_taxonomy_level5.category_name
	    FROM searchapp.search_taxonomy_level5)
	       union_results;

