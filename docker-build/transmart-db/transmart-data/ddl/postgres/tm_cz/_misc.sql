--
-- Name: median(anyelement); Type: AGGREGATE; Schema: tm_cz; Owner: -
--
CREATE AGGREGATE median(anyarray) (
    SFUNC = array_larger,
    STYPE = anyarray,
    INITCOND = '{}',
    FINALFUNC = tm_cz._final_median
);

--
-- Name: median(double precision); Type: AGGREGATE; Schema: tm_cz; Owner: -
--
CREATE AGGREGATE median(double precision) (
    SFUNC = array_append,
    STYPE = double precision[],
    INITCOND = '{}',
    FINALFUNC = tm_cz._final_median
);


SET default_with_oids = false;

--
-- Name: emt_temp_seq; Type: SEQUENCE; Schema: tm_cz; Owner: -
--
CREATE SEQUENCE emt_temp_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 20;

--
-- Name: rtqalimits_testid_seq; Type: SEQUENCE; Schema: tm_cz; Owner: -
--
CREATE SEQUENCE rtqalimits_testid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 20;

--
-- Name: rtqastatslist_testid_seq; Type: SEQUENCE; Schema: tm_cz; Owner: -
--
CREATE SEQUENCE rtqastatslist_testid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 20;

--
-- Name: seq_child_rollup_id; Type: SEQUENCE; Schema: tm_cz; Owner: -
--
CREATE SEQUENCE seq_child_rollup_id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 20;

--
-- Name: seq_cz_test_category; Type: SEQUENCE; Schema: tm_cz; Owner: -
--
CREATE SEQUENCE seq_cz_test_category
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 2;

--
-- Name: seq_region_id; Type: SEQUENCE; Schema: tm_cz; Owner: -
--
CREATE SEQUENCE seq_region_id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

