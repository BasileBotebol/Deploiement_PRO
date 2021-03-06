--
-- PostgreSQL database dump
--

-- Dumped from database version 11.2
-- Dumped by pg_dump version 11.2

-- Started on 2019-05-27 10:45:58

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 225 (class 1255 OID 18079)
-- Name: add_sous_cat_perso(integer, integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.add_sous_cat_perso(user_id integer, sous_cat_id integer)
    LANGUAGE sql
    AS $$INSERT INTO public.sous_categories_personnelles (utilisateur_id, sous_categorie_id)
VALUES (user_id, sous_cat_id);
$$;


ALTER PROCEDURE public.add_sous_cat_perso(user_id integer, sous_cat_id integer) OWNER TO postgres;

--
-- TOC entry 226 (class 1255 OID 18080)
-- Name: check_limits(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_limits() RETURNS trigger
    LANGUAGE plpgsql
    AS $$DECLARE
	cat Integer;
	id_limite Integer;
	total_limit Integer;
	id_transaction Integer;
	val_t Integer;
	temps Interval;
	rec Integer;
	val_lim Integer;
	id_user Integer;
	cat_name varchar;
BEGIN
	SELECT ca.categorie_id, mt.utilisateur_id FROM public.modele_transaction AS mt INTO cat, id_user
	INNER JOIN public.sous_categorie AS sc USING (sous_categorie_id)
	INNER JOIN public.categorie AS ca USING (categorie_id)
	WHERE modele_transaction_id = NEW.modele_transaction_id AND type_transaction_id != 2;
	raise notice 'Value cat: %', cat;
	raise notice 'Value user_id: %', id_user;
	IF cat IS NOT NULL THEN
		FOR id_limite IN SELECT limite_id FROM public.limite WHERE categorie_id = cat AND utilisateur_id  = id_user
		LOOP
			total_limit := 0;
			SELECT recurence_id, valeur FROM public.limite WHERE limite_id = id_limite INTO rec, val_lim;
			IF rec = 1 THEN temps = interval '1 year';
			ELSIF rec = 2 THEN temps = interval '1 month';
			ELSIF rec = 3 THEN temps = interval '7 days';
			ELSIF rec = 4 THEN temps = interval '1 day';
			ELSIF rec = 5 THEN temps = interval '3 months';
			ELSIF rec = 6 THEN temps = interval '6 months';
			END IF;
			raise notice 'Value recurrence: %', rec;
			FOR id_transaction IN
			SELECT transaction_id FROM public.transaction AS tr
			INNER JOIN public.modele_transaction AS mt USING (modele_transaction_id)
			INNER JOIN public.sous_categorie AS sc USING (sous_categorie_id)
			INNER JOIN public.categorie AS ca USING (categorie_id)	
			WHERE sc.categorie_id = cat AND mt.utilisateur_id = id_user AND mt.type_transaction_id != 2 AND tr.date > (CURRENT_DATE - temps)
			LOOP
				SELECT valeur FROM public.transaction WHERE transaction_id = id_transaction INTO val_t;
				total_limit := total_limit + val_t;
			END LOOP;
			raise notice 'Value total_limit: %', total_limit;
			IF total_limit > val_lim THEN
				SELECT nom FROM public.categorie WHERE cat = categorie_id INTO cat_name;
				INSERT INTO public.notification (titre, message, utilisateur_id)
				VALUES ('Limit broken', CONCAT('In category : ',cat_name), id_user);
			END IF;
		END LOOP;
	END IF;
RETURN NEW;
END$$;


ALTER FUNCTION public.check_limits() OWNER TO postgres;

--
-- TOC entry 3012 (class 0 OID 0)
-- Dependencies: 226
-- Name: FUNCTION check_limits(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.check_limits() IS 'cree une notification si une transaction depasse une limite';


--
-- TOC entry 227 (class 1255 OID 18081)
-- Name: check_recurrences(integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.check_recurrences(user_id integer)
    LANGUAGE plpgsql
    AS $$DECLARE 
	modele_id Integer;
	last_payment date;
	solde_timestamp NUMERIC(10,2);
	type_rec Integer;
	montant Integer;
	type_transaction Integer;
BEGIN
	FOR modele_id IN
		SELECT modele_transaction_id, recurrence_id, valeur AS montant FROM public.modele_transaction WHERE utilisateur_id = user_id AND recurrence_id IS NOT NULL
	LOOP 
		SELECT solde INTO solde_timestamp FROM public.utilisateur WHERE user_id = utilisateur_id;
		SELECT valeur, recurrence_id, type_transaction_id FROM public.modele_transaction WHERE modele_transaction_id = modele_id INTO montant, type_rec, type_transaction;
		SELECT MAX(date) INTO last_payment FROM public.transaction WHERE modele_transaction_id = modele_id;
		IF type_rec = 1 THEN
			WHILE last_payment + interval '1 year' <= CURRENT_DATE
			LOOP
				IF type_transaction = 1 THEN
					solde_timestamp := solde_timestamp - montant;
				ELSIF type_transaction = 2 THEN
					solde_timestamp := solde_timestamp + montant;
				END IF;
				INSERT INTO public.transaction (valeur, date, modele_transaction_id, timestamp_solde)
				VALUES (montant, last_payment + interval '1 year', modele_id, solde_timestamp);
				last_payment := last_payment + interval '1 year';
				
			END LOOP;
		ELSIF type_rec = 2 THEN
			WHILE last_payment + interval '1 month' <= CURRENT_DATE
			LOOP
				IF type_transaction = 1 THEN
					solde_timestamp := solde_timestamp - montant;
				ELSIF type_transaction = 2 THEN
					solde_timestamp := solde_timestamp + montant;
				END IF;
				INSERT INTO public.transaction (valeur, date, modele_transaction_id, timestamp_solde)
				VALUES (montant, last_payment + interval '1 month', modele_id, solde_timestamp);
				last_payment := last_payment + interval '1 month';
			END LOOP;
		ELSIF type_rec = 3 THEN
			WHILE last_payment + integer '7' <= CURRENT_DATE
			LOOP
				IF type_transaction = 1 THEN
					solde_timestamp := solde_timestamp - montant;
				ELSIF type_transaction = 2 THEN
					solde_timestamp := solde_timestamp + montant;
				END IF;
				INSERT INTO public.transaction (valeur, date, modele_transaction_id, timestamp_solde)
				VALUES (montant, last_payment + integer '7', modele_id, solde_timestamp);
				last_payment := last_payment + integer '7';
			END LOOP;
			ELSIF type_rec = 4 THEN
			WHILE last_payment + integer '1' <= CURRENT_DATE
			LOOP
				IF type_transaction = 1 THEN
					solde_timestamp := solde_timestamp - montant;
				ELSIF type_transaction = 2 THEN
					solde_timestamp := solde_timestamp + montant;
				END IF;
				INSERT INTO public.transaction (valeur, date, modele_transaction_id, timestamp_solde)
				VALUES (montant, last_payment + integer '1', modele_id, solde_timestamp);
				last_payment := last_payment + integer '1';
			END LOOP;
			ELSIF type_rec = 5 THEN
			WHILE last_payment + interval '3 month' <= CURRENT_DATE
			LOOP
				IF type_transaction = 1 THEN
					solde_timestamp := solde_timestamp - montant;
				ELSIF type_transaction = 2 THEN
					solde_timestamp := solde_timestamp + montant;
				END IF;
				INSERT INTO public.transaction (valeur, date, modele_transaction_id, timestamp_solde)
				VALUES (montant, last_payment + interval '3 month', modele_id, solde_timestamp);
				last_payment := last_payment + interval '3 month';
			END LOOP;
			ELSIF type_rec = 6 THEN
			WHILE last_payment + interval '6 month' <= CURRENT_DATE
			LOOP
				IF type_transaction = 1 THEN
					solde_timestamp := solde_timestamp - montant;
				ELSIF type_transaction = 2 THEN
					solde_timestamp := solde_timestamp + montant;
				END IF;
				INSERT INTO public.transaction (valeur, date, modele_transaction_id, timestamp_solde)
				VALUES (montant, last_payment + interval '6 month', modele_id, solde_timestamp);
				last_payment := last_payment + interval '6 month';
			END LOOP;
		END IF;
	END LOOP;
END;
	$$;


ALTER PROCEDURE public.check_recurrences(user_id integer) OWNER TO postgres;

--
-- TOC entry 3013 (class 0 OID 0)
-- Dependencies: 227
-- Name: PROCEDURE check_recurrences(user_id integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON PROCEDURE public.check_recurrences(user_id integer) IS 'Regarde si une recurrence doit avoir lieu';


--
-- TOC entry 240 (class 1255 OID 18082)
-- Name: modifSoldeExpense(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public."modifSoldeExpense"() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
UPDATE public.utilisateur AS util
SET solde = solde - NEW.valeur
FROM public.modele_transaction AS mt 
WHERE NEW.modele_transaction_id = mt.modele_transaction_id AND mt.type_transaction_id = 1 AND mt.utilisateur_id = util.utilisateur_id;
RETURN NEW;
END;
$$;


ALTER FUNCTION public."modifSoldeExpense"() OWNER TO postgres;

--
-- TOC entry 3014 (class 0 OID 0)
-- Dependencies: 240
-- Name: FUNCTION "modifSoldeExpense"(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public."modifSoldeExpense"() IS 'Modifie le solde de l''utilisateur lors d''une depense';


--
-- TOC entry 241 (class 1255 OID 18083)
-- Name: modifSoldeIncome(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public."modifSoldeIncome"() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
UPDATE public.utilisateur as util
SET solde = solde + NEW.valeur
FROM public.modele_transaction AS mt 
WHERE NEW.modele_transaction_id = mt.modele_transaction_id AND mt.type_transaction_id = 2 AND mt.utilisateur_id = util.utilisateur_id;
RETURN NEW;
END;
$$;


ALTER FUNCTION public."modifSoldeIncome"() OWNER TO postgres;

--
-- TOC entry 3015 (class 0 OID 0)
-- Dependencies: 241
-- Name: FUNCTION "modifSoldeIncome"(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public."modifSoldeIncome"() IS 'Modifie le solde de l''utilisateur quand un revenu est cree';


--
-- TOC entry 242 (class 1255 OID 18084)
-- Name: transactionCreation(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public."transactionCreation"() RETURNS trigger
    LANGUAGE plpgsql
    AS $$DECLARE
	solde_timestamp NUMERIC(10,2);
BEGIN
SELECT solde FROM public.utilisateur WHERE NEW.utilisateur_id = utilisateur_id INTO solde_timestamp;
IF NEW.type_transaction_id = 1
	THEN solde_timestamp = solde_timestamp - NEW.valeur;
	END IF;
IF NEW.type_transaction_id = 2
	THEN solde_timestamp = solde_timestamp + NEW.valeur;
	END IF;
INSERT INTO public.transaction (valeur, date, modele_transaction_id, timestamp_solde)
VALUES(NEW.valeur, NOW(), NEW.modele_transaction_id, solde_timestamp);
RETURN NEW;
END;
$$;


ALTER FUNCTION public."transactionCreation"() OWNER TO postgres;

--
-- TOC entry 3016 (class 0 OID 0)
-- Dependencies: 242
-- Name: FUNCTION "transactionCreation"(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public."transactionCreation"() IS 'Creates a transaction when date is now';


SET default_tablespace = '';

SET default_with_oids = false;

--
-- TOC entry 196 (class 1259 OID 18085)
-- Name: categorie; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.categorie (
    categorie_id integer NOT NULL,
    nom character varying(50) NOT NULL,
    couleur smallint
);


ALTER TABLE public.categorie OWNER TO postgres;

--
-- TOC entry 197 (class 1259 OID 18088)
-- Name: Categorie_categorie_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."Categorie_categorie_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."Categorie_categorie_id_seq" OWNER TO postgres;

--
-- TOC entry 3018 (class 0 OID 0)
-- Dependencies: 197
-- Name: Categorie_categorie_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Categorie_categorie_id_seq" OWNED BY public.categorie.categorie_id;


--
-- TOC entry 198 (class 1259 OID 18090)
-- Name: limite; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.limite (
    limite_id integer NOT NULL,
    date date NOT NULL,
    valeur numeric(10,2) NOT NULL,
    utilisateur_id integer NOT NULL,
    recurence_id integer NOT NULL,
    sous_categorie_id integer,
    categorie_id integer NOT NULL
);


ALTER TABLE public.limite OWNER TO postgres;

--
-- TOC entry 199 (class 1259 OID 18093)
-- Name: Limite_limite_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."Limite_limite_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."Limite_limite_id_seq" OWNER TO postgres;

--
-- TOC entry 3019 (class 0 OID 0)
-- Dependencies: 199
-- Name: Limite_limite_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Limite_limite_id_seq" OWNED BY public.limite.limite_id;


--
-- TOC entry 200 (class 1259 OID 18095)
-- Name: modele_transaction; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.modele_transaction (
    modele_transaction_id integer NOT NULL,
    valeur numeric(10,2) NOT NULL,
    date date NOT NULL,
    note text,
    utilisateur_id integer NOT NULL,
    sous_categorie_id integer NOT NULL,
    type_transaction_id integer NOT NULL,
    recurrence_id integer
);


ALTER TABLE public.modele_transaction OWNER TO postgres;

--
-- TOC entry 201 (class 1259 OID 18101)
-- Name: Modele_transaction_modele_transaction_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."Modele_transaction_modele_transaction_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."Modele_transaction_modele_transaction_id_seq" OWNER TO postgres;

--
-- TOC entry 3020 (class 0 OID 0)
-- Dependencies: 201
-- Name: Modele_transaction_modele_transaction_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Modele_transaction_modele_transaction_id_seq" OWNED BY public.modele_transaction.modele_transaction_id;


--
-- TOC entry 202 (class 1259 OID 18103)
-- Name: notification; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notification (
    notification_id integer NOT NULL,
    titre character varying(30) NOT NULL,
    message character varying,
    utilisateur_id integer NOT NULL
);


ALTER TABLE public.notification OWNER TO postgres;

--
-- TOC entry 203 (class 1259 OID 18109)
-- Name: Notification_notification_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."Notification_notification_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."Notification_notification_id_seq" OWNER TO postgres;

--
-- TOC entry 3021 (class 0 OID 0)
-- Dependencies: 203
-- Name: Notification_notification_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Notification_notification_id_seq" OWNED BY public.notification.notification_id;


--
-- TOC entry 204 (class 1259 OID 18111)
-- Name: options; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.options (
    options_id integer NOT NULL,
    rappel_email boolean NOT NULL
);


ALTER TABLE public.options OWNER TO postgres;

--
-- TOC entry 205 (class 1259 OID 18114)
-- Name: Options_options_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."Options_options_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."Options_options_id_seq" OWNER TO postgres;

--
-- TOC entry 3022 (class 0 OID 0)
-- Dependencies: 205
-- Name: Options_options_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Options_options_id_seq" OWNED BY public.options.options_id;


--
-- TOC entry 206 (class 1259 OID 18116)
-- Name: pays; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pays (
    pays_id integer NOT NULL,
    nom character varying(50) NOT NULL
);


ALTER TABLE public.pays OWNER TO postgres;

--
-- TOC entry 207 (class 1259 OID 18119)
-- Name: Pays_pays_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."Pays_pays_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."Pays_pays_id_seq" OWNER TO postgres;

--
-- TOC entry 3023 (class 0 OID 0)
-- Dependencies: 207
-- Name: Pays_pays_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Pays_pays_id_seq" OWNED BY public.pays.pays_id;


--
-- TOC entry 208 (class 1259 OID 18121)
-- Name: recurence; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.recurence (
    recurence_id integer NOT NULL,
    periodicite character varying(20) NOT NULL
);


ALTER TABLE public.recurence OWNER TO postgres;

--
-- TOC entry 209 (class 1259 OID 18124)
-- Name: Recurence_recurence_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."Recurence_recurence_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."Recurence_recurence_id_seq" OWNER TO postgres;

--
-- TOC entry 3024 (class 0 OID 0)
-- Dependencies: 209
-- Name: Recurence_recurence_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Recurence_recurence_id_seq" OWNED BY public.recurence.recurence_id;


--
-- TOC entry 210 (class 1259 OID 18126)
-- Name: sous_categorie; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sous_categorie (
    sous_categorie_id integer NOT NULL,
    nom character varying(70) NOT NULL,
    categorie_id integer NOT NULL,
    is_global boolean NOT NULL
);


ALTER TABLE public.sous_categorie OWNER TO postgres;

--
-- TOC entry 211 (class 1259 OID 18129)
-- Name: Sous_categorie_sous_categorie_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."Sous_categorie_sous_categorie_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."Sous_categorie_sous_categorie_id_seq" OWNER TO postgres;

--
-- TOC entry 3025 (class 0 OID 0)
-- Dependencies: 211
-- Name: Sous_categorie_sous_categorie_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Sous_categorie_sous_categorie_id_seq" OWNED BY public.sous_categorie.sous_categorie_id;


--
-- TOC entry 212 (class 1259 OID 18131)
-- Name: statut; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.statut (
    statut_id integer NOT NULL,
    nom character varying(30) NOT NULL
);


ALTER TABLE public.statut OWNER TO postgres;

--
-- TOC entry 213 (class 1259 OID 18134)
-- Name: Statut_statut_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."Statut_statut_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."Statut_statut_id_seq" OWNER TO postgres;

--
-- TOC entry 3026 (class 0 OID 0)
-- Dependencies: 213
-- Name: Statut_statut_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Statut_statut_id_seq" OWNED BY public.statut.statut_id;


--
-- TOC entry 214 (class 1259 OID 18136)
-- Name: transaction; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.transaction (
    transaction_id integer NOT NULL,
    valeur numeric(10,2) NOT NULL,
    date date NOT NULL,
    modele_transaction_id integer NOT NULL,
    timestamp_solde numeric(10,2) NOT NULL
);


ALTER TABLE public.transaction OWNER TO postgres;

--
-- TOC entry 215 (class 1259 OID 18139)
-- Name: Transaction_transaction_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."Transaction_transaction_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."Transaction_transaction_id_seq" OWNER TO postgres;

--
-- TOC entry 3027 (class 0 OID 0)
-- Dependencies: 215
-- Name: Transaction_transaction_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Transaction_transaction_id_seq" OWNED BY public.transaction.transaction_id;


--
-- TOC entry 216 (class 1259 OID 18141)
-- Name: type_transaction; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.type_transaction (
    type_transaction_id integer NOT NULL,
    type character varying(20) NOT NULL
);


ALTER TABLE public.type_transaction OWNER TO postgres;

--
-- TOC entry 217 (class 1259 OID 18144)
-- Name: Type_transaction_type_transaction_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."Type_transaction_type_transaction_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."Type_transaction_type_transaction_id_seq" OWNER TO postgres;

--
-- TOC entry 3028 (class 0 OID 0)
-- Dependencies: 217
-- Name: Type_transaction_type_transaction_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Type_transaction_type_transaction_id_seq" OWNED BY public.type_transaction.type_transaction_id;


--
-- TOC entry 218 (class 1259 OID 18146)
-- Name: utilisateur; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.utilisateur (
    utilisateur_id integer NOT NULL,
    prenom character varying(30) NOT NULL,
    nom character varying(30) NOT NULL,
    email character varying(50) NOT NULL,
    pseudo character varying(20) NOT NULL,
    mdp character varying(60) NOT NULL,
    genre boolean,
    anniversaire date NOT NULL,
    cree_a timestamp without time zone DEFAULT now(),
    droit_id integer NOT NULL,
    statut_id integer,
    pays_id integer,
    options_id integer NOT NULL,
    solde numeric(10,2) NOT NULL
);


ALTER TABLE public.utilisateur OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 18150)
-- Name: Utilisateur_utilisateur_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."Utilisateur_utilisateur_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."Utilisateur_utilisateur_id_seq" OWNER TO postgres;

--
-- TOC entry 3029 (class 0 OID 0)
-- Dependencies: 219
-- Name: Utilisateur_utilisateur_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Utilisateur_utilisateur_id_seq" OWNED BY public.utilisateur.utilisateur_id;


--
-- TOC entry 220 (class 1259 OID 18152)
-- Name: droit; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.droit (
    droit_id integer NOT NULL,
    nom character varying(20) NOT NULL
);


ALTER TABLE public.droit OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 18155)
-- Name: droit_droit_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.droit_droit_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.droit_droit_id_seq OWNER TO postgres;

--
-- TOC entry 3030 (class 0 OID 0)
-- Dependencies: 221
-- Name: droit_droit_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.droit_droit_id_seq OWNED BY public.droit.droit_id;


--
-- TOC entry 222 (class 1259 OID 18157)
-- Name: sous_categories_personnelles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sous_categories_personnelles (
    sous_categorie_id integer NOT NULL,
    utilisateur_id integer NOT NULL
);


ALTER TABLE public.sous_categories_personnelles OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 18160)
-- Name: test; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.test (
    testt integer NOT NULL,
    swag integer
);


ALTER TABLE public.test OWNER TO postgres;

--
-- TOC entry 224 (class 1259 OID 18163)
-- Name: test_testt_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.test_testt_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.test_testt_seq OWNER TO postgres;

--
-- TOC entry 3031 (class 0 OID 0)
-- Dependencies: 224
-- Name: test_testt_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.test_testt_seq OWNED BY public.test.testt;


--
-- TOC entry 2775 (class 2604 OID 18165)
-- Name: categorie categorie_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categorie ALTER COLUMN categorie_id SET DEFAULT nextval('public."Categorie_categorie_id_seq"'::regclass);


--
-- TOC entry 2788 (class 2604 OID 18166)
-- Name: droit droit_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.droit ALTER COLUMN droit_id SET DEFAULT nextval('public.droit_droit_id_seq'::regclass);


--
-- TOC entry 2776 (class 2604 OID 18167)
-- Name: limite limite_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.limite ALTER COLUMN limite_id SET DEFAULT nextval('public."Limite_limite_id_seq"'::regclass);


--
-- TOC entry 2777 (class 2604 OID 18168)
-- Name: modele_transaction modele_transaction_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.modele_transaction ALTER COLUMN modele_transaction_id SET DEFAULT nextval('public."Modele_transaction_modele_transaction_id_seq"'::regclass);


--
-- TOC entry 2778 (class 2604 OID 18169)
-- Name: notification notification_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notification ALTER COLUMN notification_id SET DEFAULT nextval('public."Notification_notification_id_seq"'::regclass);


--
-- TOC entry 2779 (class 2604 OID 18170)
-- Name: options options_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.options ALTER COLUMN options_id SET DEFAULT nextval('public."Options_options_id_seq"'::regclass);


--
-- TOC entry 2780 (class 2604 OID 18171)
-- Name: pays pays_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pays ALTER COLUMN pays_id SET DEFAULT nextval('public."Pays_pays_id_seq"'::regclass);


--
-- TOC entry 2781 (class 2604 OID 18172)
-- Name: recurence recurence_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.recurence ALTER COLUMN recurence_id SET DEFAULT nextval('public."Recurence_recurence_id_seq"'::regclass);


--
-- TOC entry 2782 (class 2604 OID 18173)
-- Name: sous_categorie sous_categorie_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sous_categorie ALTER COLUMN sous_categorie_id SET DEFAULT nextval('public."Sous_categorie_sous_categorie_id_seq"'::regclass);


--
-- TOC entry 2783 (class 2604 OID 18174)
-- Name: statut statut_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.statut ALTER COLUMN statut_id SET DEFAULT nextval('public."Statut_statut_id_seq"'::regclass);


--
-- TOC entry 2789 (class 2604 OID 18175)
-- Name: test testt; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.test ALTER COLUMN testt SET DEFAULT nextval('public.test_testt_seq'::regclass);


--
-- TOC entry 2784 (class 2604 OID 18176)
-- Name: transaction transaction_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transaction ALTER COLUMN transaction_id SET DEFAULT nextval('public."Transaction_transaction_id_seq"'::regclass);


--
-- TOC entry 2785 (class 2604 OID 18177)
-- Name: type_transaction type_transaction_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.type_transaction ALTER COLUMN type_transaction_id SET DEFAULT nextval('public."Type_transaction_type_transaction_id_seq"'::regclass);


--
-- TOC entry 2787 (class 2604 OID 18178)
-- Name: utilisateur utilisateur_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.utilisateur ALTER COLUMN utilisateur_id SET DEFAULT nextval('public."Utilisateur_utilisateur_id_seq"'::regclass);


--
-- TOC entry 2978 (class 0 OID 18085)
-- Dependencies: 196
-- Data for Name: categorie; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.categorie (categorie_id, nom, couleur) FROM stdin;
4	Vacances et voyages	\N
5	Autres depenses	\N
13	Retraits	\N
1	Logement et énergie	\N
2	Ménage	\N
3	Dépenses personnelles	\N
6	Santé	\N
7	Déplacements, voiture et transport	\N
8	Communication et médias	\N
10	Loisirs, sports et passe-temps	\N
11	Impôts et charges	\N
12	Epargne, prévoyance et placements	\N
16	Autres dépenses	\N
9	Sans catégorisation	\N
17	Revenu	\N
\.


--
-- TOC entry 3002 (class 0 OID 18152)
-- Dependencies: 220
-- Data for Name: droit; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.droit (droit_id, nom) FROM stdin;
1	Admin
2	Utilisateur
3	Conseiller
\.


--
-- TOC entry 2980 (class 0 OID 18090)
-- Dependencies: 198
-- Data for Name: limite; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.limite (limite_id, date, valeur, utilisateur_id, recurence_id, sous_categorie_id, categorie_id) FROM stdin;
1	2019-05-18	10.00	8	4	\N	10
2	2019-05-18	20.00	8	1	\N	6
\.


--
-- TOC entry 2982 (class 0 OID 18095)
-- Dependencies: 200
-- Data for Name: modele_transaction; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.modele_transaction (modele_transaction_id, valeur, date, note, utilisateur_id, sous_categorie_id, type_transaction_id, recurrence_id) FROM stdin;
25	40.00	2019-05-02	popolette	8	98	2	\N
26	45.00	2019-05-02	popolette	8	98	2	\N
27	50.00	2019-05-02	popolette	8	98	2	\N
28	96.00	2019-05-02	popoletteHHAHA	8	98	2	\N
29	340.00	2019-05-01	popoletteHHAHA	8	98	2	\N
31	1.00	2019-05-04	testAddSolde	8	98	2	\N
32	70.00	2019-05-04	testAddExpense	8	98	1	\N
33	31.00	2019-05-04		8	34	1	\N
34	10.00	2019-05-04		8	24	1	\N
38	60.00	2019-05-04	test Timestampt solde	8	98	2	\N
39	60.00	2019-05-04	test Timestampt solde	8	98	1	\N
40	60.00	2019-05-04	test Timestampt solde	8	98	1	\N
41	90.00	2019-05-04	test Timestampt solde soin	8	98	1	\N
42	90.00	2019-05-04	test Timestampt solde soin	8	98	1	\N
43	100.00	2019-05-04	test Timestampt solde soin	8	98	2	\N
44	100.00	2019-05-04	test Timestampt solde soin	8	98	2	\N
45	150.00	2019-05-05	koi	8	98	1	\N
46	100.00	2019-05-13	Mdr	8	35	1	\N
47	12.00	2019-05-13		8	9	1	4
48	1.00	2019-05-13	23	8	43	1	4
49	3.00	2019-05-10	test recurrences	8	1	1	4
50	4.00	2019-02-10	test recurrences mois	8	1	1	2
51	5.00	2019-02-10	test recurrences mois timestamp correctif	8	1	1	2
52	200.00	2019-05-10	test_recurrence_site	8	98	1	4
58	20.00	2019-05-18	swag notif check	8	61	1	4
59	20.00	2019-05-18	swag notif check2	8	61	1	4
60	20.00	2019-05-18	swag notif check3	8	61	1	4
61	20.00	2019-05-18	swag notif check4	8	61	1	4
63	20.00	2019-05-18	swag notif check6	8	61	1	4
64	20.00	2019-05-18	swag notif check7	8	61	1	4
65	50.00	2019-05-18		8	38	1	\N
66	60.00	2019-05-18	testtttt notifff	8	38	1	\N
67	150.00	2019-05-27	popolette	9	1	1	\N
68	100.00	2019-05-27		9	2	1	\N
69	80.00	2019-05-27		9	3	1	\N
70	60.00	2019-05-27		9	4	1	\N
71	120.00	2019-05-27		9	6	1	\N
73	150.00	2018-01-01		9	8	1	\N
74	210.00	2018-01-01		9	9	1	\N
75	400.00	2018-01-01		9	10	1	\N
76	200.00	2018-01-01		9	11	1	\N
77	50.00	2018-01-01		9	12	1	\N
78	40.00	2018-01-01		9	13	1	\N
81	50.00	2018-01-01		9	15	1	\N
82	100.00	2018-01-01		9	16	1	\N
83	30.00	2018-01-01		9	17	1	\N
84	70.00	2018-01-01		9	18	1	\N
85	130.00	2018-01-01		9	19	1	\N
86	400.00	2018-01-01		9	20	1	\N
87	250.00	2018-01-01		9	23	1	\N
88	120.00	2018-01-01		9	24	1	\N
89	200.00	2018-01-01		9	25	1	\N
91	110.00	2018-01-01		9	26	1	\N
92	200.00	2018-01-01		9	27	1	\N
93	130.00	2018-01-01		9	28	1	\N
94	230.00	2018-01-01		9	28	1	\N
95	30.00	2018-01-01		9	29	1	\N
96	340.00	2018-01-01		9	30	1	\N
97	40.00	2018-01-01		9	31	1	\N
98	50.00	2018-01-01		9	32	1	\N
99	100.00	2018-01-01		9	33	1	\N
100	150.00	2018-01-01		9	34	1	\N
101	250.00	2018-01-01		9	35	1	\N
102	200.00	2018-01-01		9	36	1	\N
103	220.00	2018-01-01		9	37	1	\N
104	60.00	2018-01-01		9	38	1	\N
107	50.00	2018-01-01		9	39	1	\N
109	500.00	2018-01-01		9	40	1	\N
113	200.00	2018-01-01		9	40	1	\N
116	220.00	2018-01-01		9	41	1	\N
117	420.00	2018-01-01		9	42	1	\N
118	320.00	2018-01-01		9	43	1	\N
119	20.00	2018-01-01		9	44	1	\N
120	200.00	2018-01-01		9	58	1	\N
121	250.00	2018-01-01		9	62	1	\N
122	350.00	2018-01-01		9	71	1	\N
125	1050.00	2018-01-01		9	82	1	\N
127	250.00	2018-01-01		9	90	1	\N
128	500.00	2018-01-01		9	95	1	\N
129	450.00	2018-01-01		9	98	1	\N
\.


--
-- TOC entry 2984 (class 0 OID 18103)
-- Dependencies: 202
-- Data for Name: notification; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.notification (notification_id, titre, message, utilisateur_id) FROM stdin;
1	Limit broken	You have spent too much in a category	8
2	Limit broken	Loisirs, sports et passe-temps	8
3	Limit broken	In category : Loisirs, sports et passe-temps	8
4	Limit broken	In category : Loisirs, sports et passe-temps	8
5	Limit broken	In category : Loisirs, sports et passe-temps	8
6	Limit broken	In category : Loisirs, sports et passe-temps	8
7	Limit broken	In category : Loisirs, sports et passe-temps	8
8	Limit broken	In category : Loisirs, sports et passe-temps	8
9	Limit broken	In category : Loisirs, sports et passe-temps	8
10	Limit broken	In category : Loisirs, sports et passe-temps	8
11	Limit broken	In category : Loisirs, sports et passe-temps	8
12	Limit broken	In category : Loisirs, sports et passe-temps	8
13	Limit broken	In category : Loisirs, sports et passe-temps	8
14	Limit broken	In category : Santé	8
\.


--
-- TOC entry 2986 (class 0 OID 18111)
-- Dependencies: 204
-- Data for Name: options; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.options (options_id, rappel_email) FROM stdin;
1	f
2	t
\.


--
-- TOC entry 2988 (class 0 OID 18116)
-- Dependencies: 206
-- Data for Name: pays; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pays (pays_id, nom) FROM stdin;
1	Afghanistan
2	Albania
3	Antarctica
4	Algeria
5	American Samoa
6	Andorra
7	Angola
8	Antigua and Barbuda
9	Azerbaijan
10	Argentina
11	Australia
12	Austria
13	Bahamas
14	Bahrain
15	Bangladesh
16	Armenia
17	Barbados
18	Belgium
19	Bermuda
20	Bhutan
21	Bolivia
22	Bosnia and Herzegovina
23	Botswana
24	Bouvet Island
25	Brazil
26	Belize
27	British Indian Ocean Territory
28	Solomon Islands
29	British Virgin Islands
30	Brunei Darussalam
31	Bulgaria
32	Myanmar
33	Burundi
34	Belarus
35	Cambodia
36	Cameroon
37	Canada
38	Cape Verde
39	Cayman Islands
40	Central African
41	Sri Lanka
42	Chad
43	Chile
44	China
45	Taiwan
46	Christmas Island
47	Cocos (Keeling) Islands
48	Colombia
49	Comoros
50	Mayotte
51	Republic of the Congo
52	The Democratic Republic Of The Congo
53	Cook Islands
54	Costa Rica
55	Croatia
56	Cuba
57	Cyprus
58	Czech Republic
59	Benin
60	Denmark
61	Dominica
62	Dominican Republic
63	Ecuador
64	El Salvador
65	Equatorial Guinea
66	Ethiopia
67	Eritrea
68	Estonia
69	Faroe Islands
70	Falkland Islands
71	South Georgia and the South Sandwich Islands
72	Fiji
73	Finland
74	Aland Islands
75	France
76	French Guiana
77	French Polynesia
78	French Southern Territories
79	Djibouti
80	Gabon
81	Georgia
82	Gambia
83	Occupied Palestinian Territory
84	Germany
85	Ghana
86	Gibraltar
87	Kiribati
88	Greece
89	Greenland
90	Grenada
91	Guadeloupe
92	Guam
93	Guatemala
94	Guinea
95	Guyana
96	Haiti
97	Heard Island and McDonald Islands
98	Vatican City State
99	Honduras
100	Hong Kong
101	Hungary
102	Iceland
103	India
104	Indonesia
105	Islamic Republic of Iran
106	Iraq
107	Ireland
108	Israel
109	Italy
110	Cote d'Ivoire
111	Jamaica
112	Japan
113	Kazakhstan
114	Jordan
115	Kenya
116	Democratic People's Republic of Korea
117	Republic of Korea
118	Kuwait
119	Kyrgyzstan
120	Lao People's Democratic Republic
121	Lebanon
122	Lesotho
123	Latvia
124	Liberia
125	Libyan Arab Jamahiriya
126	Liechtenstein
127	Lithuania
128	Luxembourg
129	Macao
130	Madagascar
131	Malawi
132	Malaysia
133	Maldives
134	Mali
135	Malta
136	Martinique
137	Mauritania
138	Mauritius
139	Mexico
140	Monaco
141	Mongolia
142	Republic of Moldova
143	Montserrat
144	Morocco
145	Mozambique
146	Oman
147	Namibia
148	Nauru
149	Nepal
150	Netherlands
151	Netherlands Antilles
152	Aruba
153	New Caledonia
154	Vanuatu
155	New Zealand
156	Nicaragua
157	Niger
158	Nigeria
159	Niue
160	Norfolk Island
161	Norway
162	Northern Mariana Islands
163	United States Minor Outlying Islands
164	Federated States of Micronesia
165	Marshall Islands
166	Palau
167	Pakistan
168	Panama
169	Papua New Guinea
170	Paraguay
171	Peru
172	Philippines
173	Pitcairn
174	Poland
175	Portugal
176	Guinea-Bissau
177	Timor-Leste
178	Puerto Rico
179	Qatar
180	Reunion
181	Romania
182	Russian Federation
183	Rwanda
184	Saint Helena
185	Saint Kitts and Nevis
186	Anguilla
187	Saint Lucia
188	Saint-Pierre and Miquelon
189	Saint Vincent and the Grenadines
190	San Marino
191	Sao Tome and Principe
192	Saudi Arabia
193	Senegal
194	Seychelles
195	Sierra Leone
196	Singapore
197	Slovakia
198	Vietnam
199	Slovenia
200	Somalia
201	South Africa
202	Zimbabwe
203	Spain
204	Western Sahara
205	Sudan
206	Suriname
207	Svalbard and Jan Mayen
208	Swaziland
209	Sweden
210	Switzerland
211	Syrian Arab Republic
212	Tajikistan
213	Thailand
214	Togo
215	Tokelau
216	Tonga
217	Trinidad and Tobago
218	United Arab Emirates
219	Tunisia
220	Turkey
221	Turkmenistan
222	Turks and Caicos Islands
223	Tuvalu
224	Uganda
225	Ukraine
226	The Former Yugoslav Republic of Macedonia
227	Egypt
228	United Kingdom
229	Isle of Man
230	United Republic Of Tanzania
231	United States
232	U.S. Virgin Islands
233	Burkina Faso
234	Uruguay
235	Uzbekistan
236	Venezuela
237	Wallis and Futuna
238	Samoa
239	Yemen
240	Serbia and Montenegro
241	Zambia
\.


--
-- TOC entry 2990 (class 0 OID 18121)
-- Dependencies: 208
-- Data for Name: recurence; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.recurence (recurence_id, periodicite) FROM stdin;
1	Annuel
4	Quotidien
5	Trimestriel
6	Semestriel
2	Mensuel
3	Hebdomadaire
\.


--
-- TOC entry 2992 (class 0 OID 18126)
-- Dependencies: 210
-- Data for Name: sous_categorie; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sous_categorie (sous_categorie_id, nom, categorie_id, is_global) FROM stdin;
100	Revenu	17	t
1	Loyer et intérêts hypothécaires	1	t
2	Assurance des bâtiments et assurance ménage	1	t
3	Frais de chauffage et charges annexes	1	t
4	Electricité et gaz	1	t
6	Entretien et réparations	1	t
8	Aménagement et mobilier	1	t
9	Outils et jardin	1	t
10	Divers	1	t
11	Personal liability insurance	1	t
12	Electronique de divertissement	1	t
13	Alimentation et boissons	2	t
14	Articles d'hygiène et de cosmétique	2	t
15	Articles et accessoires ménagers	2	t
16	Appareils ménagers	2	t
17	Aide ménagère et garde des enfants	2	t
18	Enfants et famille	2	t
19	Animaux de compagnie	2	t
20	Articles de bureau et prestations de services	2	t
22	Divers	2	t
23	Vêtements, chaussures et accessoires	3	t
24	Soin du corps et bien-être	3	t
25	Restauration (snacks, restaurants et bars)	3	t
26	Formation et formation continue	3	t
27	Dépenses et frais professionnels	3	t
28	Responsabilité civile privée	3	t
29	Cadeaux	3	t
30	Dons	3	t
31	Tabac	3	t
32	Divers	3	t
33	Hébergement et hôtel	4	t
34	Frais de voyages et d'avion	4	t
35	Excursions et sorties	4	t
36	Offres et prestations de services	4	t
37	Divers	4	t
38	Caisse maladie et assurance accidents	6	t
39	Médicaments	6	t
40	Prestations de médecin	6	t
41	Prestations hospitalières et thérapies	6	t
42	Prestations de soins et cures	6	t
43	Divers	6	t
44	Transports publics (billets et abonnements)	7	t
45	Véhicule (voiture, moto et vélo)	7	t
46	Assurance véhicule	7	t
47	Carburant (essence, diesel, gaz)	7	t
48	Service et réparations	7	t
49	Frais de garage et de stationnement (loyer)	7	t
50	Leasing	7	t
51	Taxes de transport	7	t
52	Divers	7	t
53	Vehicle tax and fees	7	t
54	Téléphone, Internet et télévision	8	t
55	Téléphonie mobile	8	t
56	Redevances radio et télévision	8	t
57	Abonnements de journaux et magazines	8	t
58	Multimédia (musique, vidéo et applications)	8	t
59	Caméscopes, appareils photo, appareils électroniques et accessoires	8	t
60	Divers	8	t
61	Sorties, culture et cinéma	10	t
62	Livres et littérature	10	t
64	Activités	10	t
65	Manifestations	10	t
66	Equipement de sport et de loisirs	10	t
67	Cotisations aux associations et fédérations	10	t
68	Articles de jeux et fournitures de loisirs	10	t
69	Photographie	10	t
70	Divers	10	t
71	Impôts fédéraux	11	t
72	Impôts communaux et cantonaux	11	t
73	Impôt anticipé	11	t
74	Taxe d'exemption de l'obligation de servir	11	t
75	Taxes	11	t
76	Divers	11	t
77	Prévoyance privée	12	t
78	Placements directs (papiers-valeurs et devises)	12	t
79	Vacances et loisirs	12	t
80	Propriété du logement	12	t
81	Aménagement et mobilier	12	t
82	Véhicule	12	t
83	Electronique de divertissement	12	t
84	Assurance vie	12	t
85	Impôts	12	t
86	Divers	12	t
87	Dons	16	t
88	Prestations et frais de services bancaires	16	t
89	Facture et frais de carte de crédit	16	t
90	Frais de poste	16	t
91	Intérêts sur les emprunts et intérêts débiteurs	16	t
92	Frais d'encaissement et de poursuite	16	t
93	Remboursements	16	t
94	Divers	16	t
95	Bancomat	13	t
96	Guichet (agence)	13	t
98	Sans catégorisation	9	t
\.


--
-- TOC entry 3004 (class 0 OID 18157)
-- Dependencies: 222
-- Data for Name: sous_categories_personnelles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sous_categories_personnelles (sous_categorie_id, utilisateur_id) FROM stdin;
\.


--
-- TOC entry 2994 (class 0 OID 18131)
-- Dependencies: 212
-- Data for Name: statut; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.statut (statut_id, nom) FROM stdin;
1	Etudiant
2	Salarié
3	Autre
\.


--
-- TOC entry 3005 (class 0 OID 18160)
-- Dependencies: 223
-- Data for Name: test; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.test (testt, swag) FROM stdin;
1	3
2	4
3	30
4	40
5	69
6	69
7	70
8	70
9	70
10	70
11	22
12	22
\.


--
-- TOC entry 2996 (class 0 OID 18136)
-- Dependencies: 214
-- Data for Name: transaction; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.transaction (transaction_id, valeur, date, modele_transaction_id, timestamp_solde) FROM stdin;
25	60.00	2019-05-04	38	-110.00
26	60.00	2019-05-04	39	-50.00
27	60.00	2019-05-04	40	-110.00
28	90.00	2019-05-04	41	-260.00
29	90.00	2019-05-04	42	-350.00
30	100.00	2019-05-04	43	-250.00
31	100.00	2019-05-04	44	-150.00
32	150.00	2019-05-05	45	-300.00
33	100.00	2019-05-13	46	-400.00
34	12.00	2019-05-13	47	-412.00
35	1.00	2019-05-13	48	-413.00
36	12.00	2019-05-14	47	-413.00
37	1.00	2019-05-14	48	-425.00
38	3.00	2019-05-10	49	-426.00
39	3.00	2019-05-11	49	-429.00
40	3.00	2019-05-12	49	-432.00
41	3.00	2019-05-13	49	-435.00
42	3.00	2019-05-14	49	-438.00
43	12.00	2019-05-15	47	-441.00
44	1.00	2019-05-15	48	-453.00
45	3.00	2019-05-15	49	-454.00
46	3.00	2019-02-10	50	-426.00
47	4.00	2019-03-10	50	-460.00
48	4.00	2019-04-10	50	-464.00
49	4.00	2019-05-10	50	-468.00
50	4.00	2019-02-10	51	-426.00
51	5.00	2019-03-10	51	-481.00
52	5.00	2019-04-10	51	-486.00
53	5.00	2019-05-10	51	-491.00
54	12.00	2019-05-16	47	-503.00
55	12.00	2019-05-17	47	-515.00
56	12.00	2019-05-18	47	-527.00
57	1.00	2019-05-16	48	-528.00
58	1.00	2019-05-17	48	-529.00
59	1.00	2019-05-18	48	-530.00
60	3.00	2019-05-16	49	-533.00
61	3.00	2019-05-17	49	-536.00
62	3.00	2019-05-18	49	-539.00
64	200.00	2019-05-10	52	10.00
65	200.00	2019-05-11	52	-939.00
66	200.00	2019-05-12	52	-1139.00
67	200.00	2019-05-13	52	-1339.00
68	200.00	2019-05-14	52	-1539.00
69	200.00	2019-05-15	52	-1739.00
70	200.00	2019-05-16	52	-1939.00
71	200.00	2019-05-17	52	-2139.00
72	200.00	2019-05-18	52	-2339.00
78	20.00	2019-05-18	58	-2359.00
79	20.00	2019-05-18	59	-2379.00
80	20.00	2019-05-18	60	-2399.00
81	20.00	2019-05-18	61	-2419.00
83	20.00	2019-05-18	63	-2439.00
84	20.00	2019-05-18	64	-2459.00
85	300.00	2018-05-10	64	10.00
87	1050.00	2018-07-10	59	10.00
88	150.00	2018-08-10	59	10.00
89	1500.00	2018-09-10	59	10.00
91	1900.00	2018-11-10	59	10.00
92	3000.00	2018-12-10	59	10.00
93	100.00	2019-01-10	59	10.00
94	860.00	2019-02-10	59	10.00
95	50.00	2019-05-18	65	-12969.00
96	60.00	2019-05-18	66	-13029.00
97	150.00	2019-05-27	67	9850.00
98	150.00	2018-05-01	67	10.00
99	100.00	2019-05-27	68	9600.00
101	80.00	2019-05-27	69	9420.00
103	60.00	2019-05-27	70	9280.00
105	120.00	2019-05-27	71	9100.00
108	150.00	2018-05-01	73	10.00
109	210.00	2018-06-01	74	10.00
110	400.00	2018-07-01	75	10.00
111	200.00	2018-08-01	76	10.00
112	50.00	2018-09-01	77	10.00
113	40.00	2018-10-01	78	10.00
117	50.00	2018-11-01	81	10.00
118	100.00	2018-12-01	82	10.00
119	30.00	2019-01-01	83	10.00
120	70.00	2019-02-01	84	10.00
121	130.00	2019-03-01	85	10.00
122	400.00	2019-04-01	86	10.00
123	250.00	2019-05-01	87	10.00
124	120.00	2018-09-01	88	10.00
125	200.00	2018-10-01	89	10.00
100	100.00	2018-06-01	68	10.00
102	80.00	2018-07-01	69	10.00
104	60.00	2018-08-01	70	10.00
106	120.00	2018-09-01	71	10.00
128	200.00	2018-12-01	91	10.00
129	130.00	2018-12-01	92	10.00
130	230.00	2019-01-01	93	10.00
131	30.00	2019-02-01	94	10.00
132	340.00	2019-03-01	95	10.00
133	40.00	2019-04-01	96	10.00
134	50.00	2019-04-01	97	10.00
135	100.00	2019-05-01	98	10.00
136	150.00	2018-06-01	99	10.00
137	250.00	2018-07-01	100	10.00
138	200.00	2018-08-01	101	10.00
139	220.00	2018-09-01	102	10.00
140	60.00	2018-10-01	103	10.00
143	50.00	2018-10-01	104	10.00
146	500.00	2018-11-01	104	10.00
151	200.00	2018-12-01	109	10.00
154	220.00	2019-01-01	113	10.00
155	420.00	2019-02-01	117	10.00
156	320.00	2019-03-01	118	10.00
157	20.00	2019-04-01	119	10.00
158	200.00	2018-06-01	120	10.00
159	250.00	2018-06-01	121	10.00
160	350.00	2018-09-01	122	10.00
162	1050.00	2018-10-01	125	10.00
164	250.00	2018-12-01	127	10.00
165	500.00	2019-01-01	128	10.00
166	450.00	2018-08-01	129	10.00
\.


--
-- TOC entry 2998 (class 0 OID 18141)
-- Dependencies: 216
-- Data for Name: type_transaction; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.type_transaction (type_transaction_id, type) FROM stdin;
1	Depense
2	Revenue
\.


--
-- TOC entry 3000 (class 0 OID 18146)
-- Dependencies: 218
-- Data for Name: utilisateur; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.utilisateur (utilisateur_id, prenom, nom, email, pseudo, mdp, genre, anniversaire, cree_a, droit_id, statut_id, pays_id, options_id, solde) FROM stdin;
2	timmy	kun	timmy-timmy@lol.tg	MDR	$2y$10$ZCd.6iesPjZmQyzHmTub4uHbhLAPdXQzam5aebHE2b2hIHJBeI4TS	f	1995-05-02	2019-03-27 10:09:20.086713	2	2	210	2	0.00
3	Pierrick	Muller	pierrick.muller@heig-vd.ch	Socrate	$2y$10$26dtG0Q5X/gV0F96bdHa/.UntjLWfm1dVJGGTqF0M8ltFm9ExVuEm	\N	1999-12-25	2019-03-27 10:12:25.755226	3	1	210	1	0.00
7	tommy	gerardi	yolo@pgm.com	thorkal	$2a$10$8dwvTlS4IBnNHh7Tja3b2.WEXgiFxl3WS6yvdyI5rwJgc5XzkuNCW	f	1995-05-23	2019-04-26 12:03:23.404966	2	1	210	1	0.00
8	eno	gap	lel@test.lulz	qwertz	$2a$10$jfhahSTe4uP1A34aaqjcf.DgES0qlcoMWqso8EqHCNZbAMG5LOJSy	t	2019-05-04	2019-04-27 14:47:10.680539	2	2	16	2	-13029.00
9	demo	demo	demo@demo.ch	demo	$2a$10$Q2Xe5C3w6rTWv37eXVXYh.aWqbV6zdWdQOOEdG6cWG4fAHBentqVe	t	1998-09-20	2019-05-27 08:49:43.153842	2	1	15	1	860.00
\.


--
-- TOC entry 3032 (class 0 OID 0)
-- Dependencies: 197
-- Name: Categorie_categorie_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Categorie_categorie_id_seq"', 17, true);


--
-- TOC entry 3033 (class 0 OID 0)
-- Dependencies: 199
-- Name: Limite_limite_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Limite_limite_id_seq"', 2, true);


--
-- TOC entry 3034 (class 0 OID 0)
-- Dependencies: 201
-- Name: Modele_transaction_modele_transaction_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Modele_transaction_modele_transaction_id_seq"', 129, true);


--
-- TOC entry 3035 (class 0 OID 0)
-- Dependencies: 203
-- Name: Notification_notification_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Notification_notification_id_seq"', 14, true);


--
-- TOC entry 3036 (class 0 OID 0)
-- Dependencies: 205
-- Name: Options_options_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Options_options_id_seq"', 3, true);


--
-- TOC entry 3037 (class 0 OID 0)
-- Dependencies: 207
-- Name: Pays_pays_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Pays_pays_id_seq"', 2, true);


--
-- TOC entry 3038 (class 0 OID 0)
-- Dependencies: 209
-- Name: Recurence_recurence_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Recurence_recurence_id_seq"', 6, true);


--
-- TOC entry 3039 (class 0 OID 0)
-- Dependencies: 211
-- Name: Sous_categorie_sous_categorie_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Sous_categorie_sous_categorie_id_seq"', 100, true);


--
-- TOC entry 3040 (class 0 OID 0)
-- Dependencies: 213
-- Name: Statut_statut_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Statut_statut_id_seq"', 3, true);


--
-- TOC entry 3041 (class 0 OID 0)
-- Dependencies: 215
-- Name: Transaction_transaction_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Transaction_transaction_id_seq"', 166, true);


--
-- TOC entry 3042 (class 0 OID 0)
-- Dependencies: 217
-- Name: Type_transaction_type_transaction_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Type_transaction_type_transaction_id_seq"', 2, true);


--
-- TOC entry 3043 (class 0 OID 0)
-- Dependencies: 219
-- Name: Utilisateur_utilisateur_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Utilisateur_utilisateur_id_seq"', 9, true);


--
-- TOC entry 3044 (class 0 OID 0)
-- Dependencies: 221
-- Name: droit_droit_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.droit_droit_id_seq', 3, true);


--
-- TOC entry 3045 (class 0 OID 0)
-- Dependencies: 224
-- Name: test_testt_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.test_testt_seq', 12, true);


--
-- TOC entry 2791 (class 2606 OID 18180)
-- Name: categorie Categorie_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categorie
    ADD CONSTRAINT "Categorie_pkey" PRIMARY KEY (categorie_id);


--
-- TOC entry 2795 (class 2606 OID 18182)
-- Name: limite Limite_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.limite
    ADD CONSTRAINT "Limite_pkey" PRIMARY KEY (limite_id);


--
-- TOC entry 2797 (class 2606 OID 18184)
-- Name: modele_transaction Modele_transaction_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.modele_transaction
    ADD CONSTRAINT "Modele_transaction_pkey" PRIMARY KEY (modele_transaction_id);


--
-- TOC entry 2799 (class 2606 OID 18186)
-- Name: notification Notification_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notification
    ADD CONSTRAINT "Notification_pkey" PRIMARY KEY (notification_id);


--
-- TOC entry 2801 (class 2606 OID 18188)
-- Name: options Options_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.options
    ADD CONSTRAINT "Options_pkey" PRIMARY KEY (options_id);


--
-- TOC entry 2803 (class 2606 OID 18190)
-- Name: pays Pays_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pays
    ADD CONSTRAINT "Pays_pkey" PRIMARY KEY (pays_id);


--
-- TOC entry 2807 (class 2606 OID 18192)
-- Name: recurence Recurence_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.recurence
    ADD CONSTRAINT "Recurence_pkey" PRIMARY KEY (recurence_id);


--
-- TOC entry 2811 (class 2606 OID 18194)
-- Name: sous_categorie Sous-categorie_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sous_categorie
    ADD CONSTRAINT "Sous-categorie_pkey" PRIMARY KEY (sous_categorie_id);


--
-- TOC entry 2815 (class 2606 OID 18196)
-- Name: statut Statut_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.statut
    ADD CONSTRAINT "Statut_pkey" PRIMARY KEY (statut_id);


--
-- TOC entry 2819 (class 2606 OID 18198)
-- Name: transaction Transaction_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transaction
    ADD CONSTRAINT "Transaction_pkey" PRIMARY KEY (transaction_id);


--
-- TOC entry 2821 (class 2606 OID 18200)
-- Name: type_transaction Type_transaction_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.type_transaction
    ADD CONSTRAINT "Type_transaction_pkey" PRIMARY KEY (type_transaction_id);


--
-- TOC entry 2825 (class 2606 OID 18202)
-- Name: utilisateur Utilisateur_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.utilisateur
    ADD CONSTRAINT "Utilisateur_pkey" PRIMARY KEY (utilisateur_id);


--
-- TOC entry 2831 (class 2606 OID 18204)
-- Name: droit droit_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.droit
    ADD CONSTRAINT droit_pkey PRIMARY KEY (droit_id);


--
-- TOC entry 2827 (class 2606 OID 18206)
-- Name: utilisateur emailUnique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.utilisateur
    ADD CONSTRAINT "emailUnique" UNIQUE (email);


--
-- TOC entry 2793 (class 2606 OID 18208)
-- Name: categorie nomCategorieUnique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categorie
    ADD CONSTRAINT "nomCategorieUnique" UNIQUE (nom);


--
-- TOC entry 2833 (class 2606 OID 18210)
-- Name: droit nomDroitUnique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.droit
    ADD CONSTRAINT "nomDroitUnique" UNIQUE (nom);


--
-- TOC entry 2813 (class 2606 OID 18212)
-- Name: sous_categorie nomEtIdUniqueSousCat; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sous_categorie
    ADD CONSTRAINT "nomEtIdUniqueSousCat" UNIQUE (nom, categorie_id);


--
-- TOC entry 2805 (class 2606 OID 18214)
-- Name: pays nomPaysUnique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pays
    ADD CONSTRAINT "nomPaysUnique" UNIQUE (nom);


--
-- TOC entry 2817 (class 2606 OID 18216)
-- Name: statut nomStatutUnique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.statut
    ADD CONSTRAINT "nomStatutUnique" UNIQUE (nom);


--
-- TOC entry 2809 (class 2606 OID 18218)
-- Name: recurence periodiciteUnique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.recurence
    ADD CONSTRAINT "periodiciteUnique" UNIQUE (periodicite);


--
-- TOC entry 2829 (class 2606 OID 18220)
-- Name: utilisateur pseudoUnique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.utilisateur
    ADD CONSTRAINT "pseudoUnique" UNIQUE (pseudo);


--
-- TOC entry 2835 (class 2606 OID 18222)
-- Name: test test_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.test
    ADD CONSTRAINT test_pkey PRIMARY KEY (testt);


--
-- TOC entry 2823 (class 2606 OID 18224)
-- Name: type_transaction typeTransactionUnique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.type_transaction
    ADD CONSTRAINT "typeTransactionUnique" UNIQUE (type);


--
-- TOC entry 2853 (class 2620 OID 18225)
-- Name: modele_transaction createTransaction; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "createTransaction" AFTER INSERT ON public.modele_transaction FOR EACH ROW WHEN ((new.date = CURRENT_DATE)) EXECUTE PROCEDURE public."transactionCreation"();


--
-- TOC entry 2854 (class 2620 OID 18226)
-- Name: transaction limit; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "limit" AFTER INSERT ON public.transaction FOR EACH ROW EXECUTE PROCEDURE public.check_limits();


--
-- TOC entry 3046 (class 0 OID 0)
-- Dependencies: 2854
-- Name: TRIGGER "limit" ON transaction; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER "limit" ON public.transaction IS 'checks limits';


--
-- TOC entry 2855 (class 2620 OID 18227)
-- Name: transaction soldeModifExpense; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "soldeModifExpense" BEFORE INSERT ON public.transaction FOR EACH ROW EXECUTE PROCEDURE public."modifSoldeExpense"();


--
-- TOC entry 2856 (class 2620 OID 18228)
-- Name: transaction soldeModifIncome; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "soldeModifIncome" AFTER INSERT ON public.transaction FOR EACH ROW EXECUTE PROCEDURE public."modifSoldeIncome"();


--
-- TOC entry 2845 (class 2606 OID 18229)
-- Name: sous_categorie categorie_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sous_categorie
    ADD CONSTRAINT categorie_id FOREIGN KEY (categorie_id) REFERENCES public.categorie(categorie_id) ON UPDATE CASCADE ON DELETE SET DEFAULT;


--
-- TOC entry 2836 (class 2606 OID 18234)
-- Name: limite categorie_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.limite
    ADD CONSTRAINT categorie_id FOREIGN KEY (categorie_id) REFERENCES public.categorie(categorie_id);


--
-- TOC entry 2847 (class 2606 OID 18239)
-- Name: utilisateur droit_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.utilisateur
    ADD CONSTRAINT droit_id FOREIGN KEY (droit_id) REFERENCES public.droit(droit_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2846 (class 2606 OID 18244)
-- Name: transaction modele_transaction_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transaction
    ADD CONSTRAINT modele_transaction_id FOREIGN KEY (modele_transaction_id) REFERENCES public.modele_transaction(modele_transaction_id) ON UPDATE CASCADE;


--
-- TOC entry 2848 (class 2606 OID 18249)
-- Name: utilisateur options_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.utilisateur
    ADD CONSTRAINT options_id FOREIGN KEY (options_id) REFERENCES public.options(options_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 2849 (class 2606 OID 18254)
-- Name: utilisateur pays_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.utilisateur
    ADD CONSTRAINT pays_id FOREIGN KEY (pays_id) REFERENCES public.pays(pays_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 2837 (class 2606 OID 18259)
-- Name: limite recurence_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.limite
    ADD CONSTRAINT recurence_id FOREIGN KEY (recurence_id) REFERENCES public.recurence(recurence_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 2840 (class 2606 OID 18264)
-- Name: modele_transaction recurence_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.modele_transaction
    ADD CONSTRAINT recurence_id FOREIGN KEY (recurrence_id) REFERENCES public.recurence(recurence_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 2838 (class 2606 OID 18269)
-- Name: limite sous_categorie_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.limite
    ADD CONSTRAINT sous_categorie_id FOREIGN KEY (sous_categorie_id) REFERENCES public.sous_categorie(sous_categorie_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2841 (class 2606 OID 18274)
-- Name: modele_transaction sous_categorie_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.modele_transaction
    ADD CONSTRAINT sous_categorie_id FOREIGN KEY (sous_categorie_id) REFERENCES public.sous_categorie(sous_categorie_id) ON UPDATE CASCADE ON DELETE SET DEFAULT;


--
-- TOC entry 2851 (class 2606 OID 18279)
-- Name: sous_categories_personnelles sous_categorie_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sous_categories_personnelles
    ADD CONSTRAINT sous_categorie_id_fk FOREIGN KEY (sous_categorie_id) REFERENCES public.sous_categorie(sous_categorie_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2850 (class 2606 OID 18284)
-- Name: utilisateur statut_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.utilisateur
    ADD CONSTRAINT statut_id FOREIGN KEY (statut_id) REFERENCES public.statut(statut_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 2842 (class 2606 OID 18289)
-- Name: modele_transaction type_transaction_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.modele_transaction
    ADD CONSTRAINT type_transaction_id FOREIGN KEY (type_transaction_id) REFERENCES public.type_transaction(type_transaction_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 2844 (class 2606 OID 18294)
-- Name: notification utilisateur_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notification
    ADD CONSTRAINT utilisateur_id FOREIGN KEY (utilisateur_id) REFERENCES public.utilisateur(utilisateur_id) ON DELETE CASCADE;


--
-- TOC entry 2839 (class 2606 OID 18299)
-- Name: limite utilisateur_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.limite
    ADD CONSTRAINT utilisateur_id FOREIGN KEY (utilisateur_id) REFERENCES public.utilisateur(utilisateur_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2843 (class 2606 OID 18304)
-- Name: modele_transaction utilisateur_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.modele_transaction
    ADD CONSTRAINT utilisateur_id FOREIGN KEY (utilisateur_id) REFERENCES public.utilisateur(utilisateur_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2852 (class 2606 OID 18309)
-- Name: sous_categories_personnelles utilisateur_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sous_categories_personnelles
    ADD CONSTRAINT utilisateur_id_fk FOREIGN KEY (utilisateur_id) REFERENCES public.utilisateur(utilisateur_id);


--
-- TOC entry 3017 (class 0 OID 0)
-- Dependencies: 242
-- Name: FUNCTION "transactionCreation"(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public."transactionCreation"() FROM postgres;


-- Completed on 2019-05-27 10:45:59

--
-- PostgreSQL database dump complete
--

