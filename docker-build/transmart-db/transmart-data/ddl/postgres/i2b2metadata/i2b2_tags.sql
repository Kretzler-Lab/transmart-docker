--
-- Name: i2b2_tags; Type: TABLE; Schema: i2b2metadata; Owner: -
--
CREATE TABLE i2b2_tags (
    tag_id integer NOT NULL,
    path character varying(400) NOT NULL,
    tag character varying(1000),
    tag_type character varying(400) NOT NULL,
    tags_idx integer NOT NULL
);

--
-- Name: i2b2_tags_path_tag_type_key; Type: CONSTRAINT; Schema: i2b2metadata; Owner: -
--
ALTER TABLE ONLY i2b2_tags
    ADD CONSTRAINT i2b2_tags_path_tag_type_key UNIQUE (path, tag_type);

--
-- Name: tf_trg_i2b2_tag_id(); Type: FUNCTION; Schema: i2b2metadata; Owner: -
--
CREATE FUNCTION tf_trg_i2b2_tag_id() RETURNS trigger
    LANGUAGE plpgsql
AS $$
begin
    if new.tag_id is null then
	select nextval('i2b2metadata.seq_i2b2_tag_id') into new.tag_id ;
    end if;
    return new;
end;
$$;


SET default_with_oids = false;

--
-- Name: trg_i2b2_tag_id; Type: TRIGGER; Schema: i2b2metadata; Owner: -
--
CREATE TRIGGER trg_i2b2_tag_id BEFORE INSERT ON i2b2_tags FOR EACH ROW EXECUTE PROCEDURE tf_trg_i2b2_tag_id();

--
-- Name: seq_i2b2_tag_id; Type: SEQUENCE; Schema: i2b2metadata; Owner: -
--
CREATE SEQUENCE seq_i2b2_tag_id
    START WITH 1789
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

