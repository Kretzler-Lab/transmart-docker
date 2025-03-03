--
-- Name: de_rbm_annotation; Type: TABLE; Schema: deapp; Owner: -
--
CREATE TABLE de_rbm_annotation (
    id int NOT NULL,
    gpl_id character varying(50) NOT NULL,
    antigen_name character varying(200) NOT NULL,
    uniprot_id character varying(50),
    gene_symbol character varying(100),
    gene_id character varying(100),
    uniprot_name character varying(200)
);

--
-- Name: de_rbm_annotation_pk; Type: CONSTRAINT; Schema: deapp; Owner: -
--
ALTER TABLE ONLY de_rbm_annotation
    ADD CONSTRAINT de_rbm_annotation_pk PRIMARY KEY (id);

--
-- Name: tf_rbm_id_trigger(); Type: FUNCTION; Schema: deapp; Owner: -
--
CREATE FUNCTION tf_rbm_id_trigger() RETURNS trigger
    LANGUAGE plpgsql
AS $$
begin
    if new.id is null then
	select nextval('deapp.rbm_annotation_id') into new.id ;
    end if;
    return new;
end;
$$;

--
-- Name: rbm_id_trigger; Type: TRIGGER; Schema: deapp; Owner: -
--
CREATE TRIGGER rbm_id_trigger BEFORE INSERT ON de_rbm_annotation FOR EACH ROW EXECUTE PROCEDURE tf_rbm_id_trigger();

--
-- Name: rbm_annotation_id; Type: SEQUENCE; Schema: deapp; Owner: -
--
CREATE SEQUENCE rbm_annotation_id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

