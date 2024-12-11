CREATE SEQUENCE searchapp.data_attestation_id_seq;
CREATE TABLE searchapp.data_attestation (data_attestation_id int8 NOT NULL DEFAULT nextval('searchapp.data_attestation_id_seq'::regclass), auth_user_id int8 NULL, last_date_agreed timestamp NULL);
GRANT ALL ON TABLE searchapp.data_attestation to biomart_user;
CREATE OR REPLACE FUNCTION "i2b2metadata"."add_tooltips"(IN filename varchar, IN add_frontslashes bool, IN add_endslashes bool)
  RETURNS SETOF "pg_catalog"."text" AS $BODY$

DECLARE
	num_rows int;
	message TEXT;
	tooltip_row RECORD;
	this_nodepath TEXT;

BEGIN
	SET standard_conforming_strings = ON;
	CREATE TEMP TABLE tooltip(nodepath text, tooltip_text text);
	CREATE TEMP TABLE tooltip_results(nodepath text);
	EXECUTE 'COPY tooltip FROM ' || quote_literal(filename) || ' WITH CSV QUOTE ''"'' HEADER;';

	FOR tooltip_row IN SELECT * FROM tooltip LOOP
		IF add_endslashes THEN
			this_nodepath = tooltip_row.nodepath || '\';
		ELSE
			this_nodepath = tooltip_row.nodepath;
		END IF;

		PERFORM c_fullname FROM i2b2metadata.i2b2
		WHERE c_fullname = this_nodepath;

		IF FOUND THEN
			UPDATE i2b2metadata.i2b2
			SET c_tooltip = tooltip_row.tooltip_text
			WHERE c_fullname = this_nodepath;

			PERFORM path FROM i2b2metadata.i2b2_tags
			WHERE path = this_nodepath;

			IF FOUND THEN
				UPDATE i2b2metadata.i2b2_tags
				SET tag = tooltip_row.tooltip_text
				WHERE path = this_nodepath;
			ELSE
				INSERT INTO i2b2metadata.i2b2_tags("path", tag, tag_type, tags_idx)
				VALUES(this_nodepath,tooltip_row.tooltip_text,'Details', 0);
			END IF;

		ELSE
			INSERT INTO tooltip_results(nodepath) VALUES(this_nodepath);
		END IF;

	END LOOP;
RETURN QUERY EXECUTE 'SELECT * FROM tooltip_results;';
DISCARD TEMP;
END;

$BODY$
  LANGUAGE 'plpgsql' VOLATILE COST 100
 ROWS 1000
;
