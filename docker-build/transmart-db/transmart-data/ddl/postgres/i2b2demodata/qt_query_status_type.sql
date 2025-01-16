--
-- Name: qt_sq_qs_qsid; Type: SEQUENCE; Schema: i2b2demodata; Owner: -
--
CREATE SEQUENCE qt_sq_qs_qsid
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: qt_query_status_type; Type: TABLE; Schema: i2b2demodata; Owner: -
--
CREATE TABLE qt_query_status_type (
    status_type_id int NOT NULL,
    name character varying(100),
    description character varying(200)
);

--
-- Name: qt_query_status_type_pk; Type: CONSTRAINT; Schema: i2b2demodata; Owner: -
--
ALTER TABLE ONLY qt_query_status_type
    ADD CONSTRAINT qt_query_status_type_pk PRIMARY KEY (status_type_id);

