--
-- Name: am_tag_template; Type: TABLE; Schema: amapp; Owner: -
--
CREATE TABLE am_tag_template (
    tag_template_id int NOT NULL,
    tag_template_name character varying(200) NOT NULL,
    tag_template_type character varying(50) NOT NULL,
    tag_template_subtype character varying(50),
    active_ind boolean NOT NULL
);

--
-- Name: am_tag_template_pk; Type: CONSTRAINT; Schema: amapp; Owner: -
--
ALTER TABLE ONLY am_tag_template
    ADD CONSTRAINT am_tag_template_pk PRIMARY KEY (tag_template_id);

--
-- Name: tf_trg_am_tag_template_id(); Type: FUNCTION; Schema: amapp; Owner: -
--
CREATE FUNCTION tf_trg_am_tag_template_id() RETURNS trigger
    LANGUAGE plpgsql
AS $$
begin
    if new.tag_template_id is null then
	select nextval('amapp.seq_amapp_data_id') into new.tag_template_id ;
    end if;
    return new;
end;
$$;

--
-- Name: trg_am_tag_template_id; Type: TRIGGER; Schema: amapp; Owner: -
--
CREATE TRIGGER trg_am_tag_template_id BEFORE INSERT ON am_tag_template FOR EACH ROW EXECUTE PROCEDURE tf_trg_am_tag_template_id();

