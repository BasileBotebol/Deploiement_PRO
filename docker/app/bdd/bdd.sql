--
-- PostgreSQL database dump
--

-- Dumped from database version 11.2
-- Dumped by pg_dump version 11.2

-- Started on 2019-05-15 15:26:20

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
-- TOC entry 225 (class 1255 OID 17607)
-- Name: add_sous_cat_perso(integer, integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.add_sous_cat_perso(user_id integer, sous_cat_id integer)
    LANGUAGE sql
    AS $$INSERT INTO public.sous_categories_personnelles (utilisateur_id, sous_categorie_id)
VALUES (user_id, sous_cat_id);
$$;


ALTER PROCEDURE public.add_sous_cat_perso(user_id integer, sous_cat_id integer) OWNER TO postgres;

--
-- TOC entry 226 (class 1255 OID 17608)
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
-- TOC entry 3010 (class 0 OID 0)
-- Dependencies: 226
-- Name: PROCEDURE check_recurrences(user_id integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON PROCEDURE public.check_recurrences(user_id integer) IS 'Regarde si une recurrence doit avoir lieu';


--
-- TOC entry 227 (class 1255 OID 17609)
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
-- TOC entry 3011 (class 0 OID 0)
-- Dependencies: 227
-- Name: FUNCTION "modifSoldeExpense"(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public."modifSoldeExpense"() IS 'Modifie le solde de l''utilisateur lors d''une depense';


--
-- TOC entry 228 (class 1255 OID 17610)
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
-- TOC entry 3012 (class 0 OID 0)
-- Dependencies: 228
-- Name: FUNCTION "modifSoldeIncome"(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public."modifSoldeIncome"() IS 'Modifie le solde de l''utilisateur quand un revenu est cree';


--
-- TOC entry 229 (class 1255 OID 17611)
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
-- TOC entry 3013 (class 0 OID 0)
-- Dependencies: 229
-- Name: FUNCTION "transactionCreation"(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public."transactionCreation"() IS 'Creates a transaction when date is now';


SET default_tablespace = '';

SET default_with_oids = false;

--
-- TOC entry 196 (class 1259 OID 17612)
-- Name: categorie; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.categorie (
    categorie_id integer NOT NULL,
    nom character varying(50) NOT NULL,
    couleur smallint
);


ALTER TABLE public.categorie OWNER TO postgres;

--
-- TOC entry 197 (class 1259 OID 17615)
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
-- TOC entry 3015 (class 0 OID 0)
-- Dependencies: 197
-- Name: Categorie_categorie_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Categorie_categorie_id_seq" OWNED BY public.categorie.categorie_id;


--
-- TOC entry 198 (class 1259 OID 17617)
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
-- TOC entry 199 (class 1259 OID 17620)
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
-- TOC entry 3016 (class 0 OID 0)
-- Dependencies: 199
-- Name: Limite_limite_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Limite_limite_id_seq" OWNED BY public.limite.limite_id;


--
-- TOC entry 200 (class 1259 OID 17622)
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
-- TOC entry 201 (class 1259 OID 17628)
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
-- TOC entry 3017 (class 0 OID 0)
-- Dependencies: 201
-- Name: Modele_transaction_modele_transaction_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Modele_transaction_modele_transaction_id_seq" OWNED BY public.modele_transaction.modele_transaction_id;


--
-- TOC entry 202 (class 1259 OID 17630)
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
-- TOC entry 203 (class 1259 OID 17636)
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
-- TOC entry 3018 (class 0 OID 0)
-- Dependencies: 203
-- Name: Notification_notification_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Notification_notification_id_seq" OWNED BY public.notification.notification_id;


--
-- TOC entry 204 (class 1259 OID 17638)
-- Name: options; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.options (
    options_id integer NOT NULL,
    rappel_email boolean NOT NULL
);


ALTER TABLE public.options OWNER TO postgres;

--
-- TOC entry 205 (class 1259 OID 17641)
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
-- TOC entry 3019 (class 0 OID 0)
-- Dependencies: 205
-- Name: Options_options_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Options_options_id_seq" OWNED BY public.options.options_id;


--
-- TOC entry 206 (class 1259 OID 17643)
-- Name: pays; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pays (
    pays_id integer NOT NULL,
    nom character varying(50) NOT NULL
);


ALTER TABLE public.pays OWNER TO postgres;

--
-- TOC entry 207 (class 1259 OID 17646)
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
-- TOC entry 3020 (class 0 OID 0)
-- Dependencies: 207
-- Name: Pays_pays_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Pays_pays_id_seq" OWNED BY public.pays.pays_id;


--
-- TOC entry 208 (class 1259 OID 17648)
-- Name: recurence; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.recurence (
    recurence_id integer NOT NULL,
    periodicite character varying(20) NOT NULL
);


ALTER TABLE public.recurence OWNER TO postgres;

--
-- TOC entry 209 (class 1259 OID 17651)
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
-- TOC entry 3021 (class 0 OID 0)
-- Dependencies: 209
-- Name: Recurence_recurence_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Recurence_recurence_id_seq" OWNED BY public.recurence.recurence_id;


--
-- TOC entry 210 (class 1259 OID 17653)
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
-- TOC entry 211 (class 1259 OID 17656)
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
-- TOC entry 3022 (class 0 OID 0)
-- Dependencies: 211
-- Name: Sous_categorie_sous_categorie_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Sous_categorie_sous_categorie_id_seq" OWNED BY public.sous_categorie.sous_categorie_id;


--
-- TOC entry 212 (class 1259 OID 17658)
-- Name: statut; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.statut (
    statut_id integer NOT NULL,
    nom character varying(30) NOT NULL
);


ALTER TABLE public.statut OWNER TO postgres;

--
-- TOC entry 213 (class 1259 OID 17661)
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
-- TOC entry 3023 (class 0 OID 0)
-- Dependencies: 213
-- Name: Statut_statut_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Statut_statut_id_seq" OWNED BY public.statut.statut_id;


--
-- TOC entry 214 (class 1259 OID 17663)
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
-- TOC entry 215 (class 1259 OID 17666)
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
-- TOC entry 3024 (class 0 OID 0)
-- Dependencies: 215
-- Name: Transaction_transaction_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Transaction_transaction_id_seq" OWNED BY public.transaction.transaction_id;


--
-- TOC entry 216 (class 1259 OID 17668)
-- Name: type_transaction; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.type_transaction (
    type_transaction_id integer NOT NULL,
    type character varying(20) NOT NULL
);


ALTER TABLE public.type_transaction OWNER TO postgres;

--
-- TOC entry 217 (class 1259 OID 17671)
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
-- TOC entry 3025 (class 0 OID 0)
-- Dependencies: 217
-- Name: Type_transaction_type_transaction_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Type_transaction_type_transaction_id_seq" OWNED BY public.type_transaction.type_transaction_id;


--
-- TOC entry 218 (class 1259 OID 17673)
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
-- TOC entry 219 (class 1259 OID 17677)
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
-- TOC entry 3026 (class 0 OID 0)
-- Dependencies: 219
-- Name: Utilisateur_utilisateur_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Utilisateur_utilisateur_id_seq" OWNED BY public.utilisateur.utilisateur_id;


--
-- TOC entry 220 (class 1259 OID 17679)
-- Name: droit; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.droit (
    droit_id integer NOT NULL,
    nom character varying(20) NOT NULL
);


ALTER TABLE public.droit OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 17682)
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
-- TOC entry 3027 (class 0 OID 0)
-- Dependencies: 221
-- Name: droit_droit_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.droit_droit_id_seq OWNED BY public.droit.droit_id;


--
-- TOC entry 222 (class 1259 OID 17684)
-- Name: sous_categories_personnelles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sous_categories_personnelles (
    sous_categorie_id integer NOT NULL,
    utilisateur_id integer NOT NULL
);


ALTER TABLE public.sous_categories_personnelles OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 17687)
-- Name: test; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.test (
    testt integer NOT NULL,
    swag integer
);


ALTER TABLE public.test OWNER TO postgres;

--
-- TOC entry 224 (class 1259 OID 17690)
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
-- TOC entry 3028 (class 0 OID 0)
-- Dependencies: 224
-- Name: test_testt_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.test_testt_seq OWNED BY public.test.testt;


--
-- TOC entry 2774 (class 2604 OID 17692)
-- Name: categorie categorie_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categorie ALTER COLUMN categorie_id SET DEFAULT nextval('public."Categorie_categorie_id_seq"'::regclass);


--
-- TOC entry 2787 (class 2604 OID 17693)
-- Name: droit droit_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.droit ALTER COLUMN droit_id SET DEFAULT nextval('public.droit_droit_id_seq'::regclass);


--
-- TOC entry 2775 (class 2604 OID 17694)
-- Name: limite limite_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.limite ALTER COLUMN limite_id SET DEFAULT nextval('public."Limite_limite_id_seq"'::regclass);


--
-- TOC entry 2776 (class 2604 OID 17695)
-- Name: modele_transaction modele_transaction_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.modele_transaction ALTER COLUMN modele_transaction_id SET DEFAULT nextval('public."Modele_transaction_modele_transaction_id_seq"'::regclass);


--
-- TOC entry 2777 (class 2604 OID 17696)
-- Name: notification notification_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notification ALTER COLUMN notification_id SET DEFAULT nextval('public."Notification_notification_id_seq"'::regclass);


--
-- TOC entry 2778 (class 2604 OID 17697)
-- Name: options options_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.options ALTER COLUMN options_id SET DEFAULT nextval('public."Options_options_id_seq"'::regclass);


--
-- TOC entry 2779 (class 2604 OID 17698)
-- Name: pays pays_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pays ALTER COLUMN pays_id SET DEFAULT nextval('public."Pays_pays_id_seq"'::regclass);


--
-- TOC entry 2780 (class 2604 OID 17699)
-- Name: recurence recurence_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.recurence ALTER COLUMN recurence_id SET DEFAULT nextval('public."Recurence_recurence_id_seq"'::regclass);


--
-- TOC entry 2781 (class 2604 OID 17700)
-- Name: sous_categorie sous_categorie_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sous_categorie ALTER COLUMN sous_categorie_id SET DEFAULT nextval('public."Sous_categorie_sous_categorie_id_seq"'::regclass);


--
-- TOC entry 2782 (class 2604 OID 17701)
-- Name: statut statut_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.statut ALTER COLUMN statut_id SET DEFAULT nextval('public."Statut_statut_id_seq"'::regclass);


--
-- TOC entry 2788 (class 2604 OID 17702)
-- Name: test testt; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.test ALTER COLUMN testt SET DEFAULT nextval('public.test_testt_seq'::regclass);


--
-- TOC entry 2783 (class 2604 OID 17703)
-- Name: transaction transaction_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transaction ALTER COLUMN transaction_id SET DEFAULT nextval('public."Transaction_transaction_id_seq"'::regclass);


--
-- TOC entry 2784 (class 2604 OID 17704)
-- Name: type_transaction type_transaction_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.type_transaction ALTER COLUMN type_transaction_id SET DEFAULT nextval('public."Type_transaction_type_transaction_id_seq"'::regclass);


--
-- TOC entry 2786 (class 2604 OID 17705)
-- Name: utilisateur utilisateur_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.utilisateur ALTER COLUMN utilisateur_id SET DEFAULT nextval('public."Utilisateur_utilisateur_id_seq"'::regclass);


--
-- TOC entry 2976 (class 0 OID 17612)
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
-- TOC entry 3000 (class 0 OID 17679)
-- Dependencies: 220
-- Data for Name: droit; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.droit (droit_id, nom) FROM stdin;
1	Admin
2	Utilisateur
3	Conseiller
\.


--
-- TOC entry 2978 (class 0 OID 17617)
-- Dependencies: 198
-- Data for Name: limite; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.limite (limite_id, date, valeur, utilisateur_id, recurence_id, sous_categorie_id, categorie_id) FROM stdin;
\.


--
-- TOC entry 2980 (class 0 OID 17622)
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
\.


--
-- TOC entry 2982 (class 0 OID 17630)
-- Dependencies: 202
-- Data for Name: notification; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.notification (notification_id, titre, message, utilisateur_id) FROM stdin;
\.


--
-- TOC entry 2984 (class 0 OID 17638)
-- Dependencies: 204
-- Data for Name: options; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.options (options_id, rappel_email) FROM stdin;
1	f
2	t
\.


--
-- TOC entry 2986 (class 0 OID 17643)
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
-- TOC entry 2988 (class 0 OID 17648)
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
-- TOC entry 2990 (class 0 OID 17653)
-- Dependencies: 210
-- Data for Name: sous_categorie; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sous_categorie (sous_categorie_id, nom, categorie_id, is_global) FROM stdin;
100	Revenu	17	t
1	Loyer et intérêts hypothécaires	1	t
2	Assurance des bâtiments et assurance ménage	1	t
3	Frais de chauffage et charges annexes	1	t
4	Electricité et gaz	1	t
5	Frais relatifs à l'eau, aux eaux usées et aux ordures ménagères	1	t
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
-- TOC entry 3002 (class 0 OID 17684)
-- Dependencies: 222
-- Data for Name: sous_categories_personnelles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sous_categories_personnelles (sous_categorie_id, utilisateur_id) FROM stdin;
\.


--
-- TOC entry 2992 (class 0 OID 17658)
-- Dependencies: 212
-- Data for Name: statut; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.statut (statut_id, nom) FROM stdin;
1	Etudiant
2	Salarié
3	Autre
\.


--
-- TOC entry 3003 (class 0 OID 17687)
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
-- TOC entry 2994 (class 0 OID 17663)
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
\.


--
-- TOC entry 2996 (class 0 OID 17668)
-- Dependencies: 216
-- Data for Name: type_transaction; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.type_transaction (type_transaction_id, type) FROM stdin;
1	Depense
2	Revenue
\.


--
-- TOC entry 2998 (class 0 OID 17673)
-- Dependencies: 218
-- Data for Name: utilisateur; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.utilisateur (utilisateur_id, prenom, nom, email, pseudo, mdp, genre, anniversaire, cree_a, droit_id, statut_id, pays_id, options_id, solde) FROM stdin;
2	timmy	kun	timmy-timmy@lol.tg	MDR	$2y$10$ZCd.6iesPjZmQyzHmTub4uHbhLAPdXQzam5aebHE2b2hIHJBeI4TS	f	1995-05-02	2019-03-27 10:09:20.086713	2	2	210	2	0.00
3	Pierrick	Muller	pierrick.muller@heig-vd.ch	Socrate	$2y$10$26dtG0Q5X/gV0F96bdHa/.UntjLWfm1dVJGGTqF0M8ltFm9ExVuEm	\N	1999-12-25	2019-03-27 10:12:25.755226	3	1	210	1	0.00
7	tommy	gerardi	yolo@pgm.com	thorkal	$2a$10$8dwvTlS4IBnNHh7Tja3b2.WEXgiFxl3WS6yvdyI5rwJgc5XzkuNCW	f	1995-05-23	2019-04-26 12:03:23.404966	2	1	210	1	0.00
8	eno	gap	lel@test.lulz	qwertz	$2a$10$jfhahSTe4uP1A34aaqjcf.DgES0qlcoMWqso8EqHCNZbAMG5LOJSy	t	2019-05-04	2019-04-27 14:47:10.680539	2	2	16	2	-491.00
\.


--
-- TOC entry 3029 (class 0 OID 0)
-- Dependencies: 197
-- Name: Categorie_categorie_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Categorie_categorie_id_seq"', 17, true);


--
-- TOC entry 3030 (class 0 OID 0)
-- Dependencies: 199
-- Name: Limite_limite_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Limite_limite_id_seq"', 1, false);


--
-- TOC entry 3031 (class 0 OID 0)
-- Dependencies: 201
-- Name: Modele_transaction_modele_transaction_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Modele_transaction_modele_transaction_id_seq"', 51, true);


--
-- TOC entry 3032 (class 0 OID 0)
-- Dependencies: 203
-- Name: Notification_notification_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Notification_notification_id_seq"', 1, false);


--
-- TOC entry 3033 (class 0 OID 0)
-- Dependencies: 205
-- Name: Options_options_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Options_options_id_seq"', 3, true);


--
-- TOC entry 3034 (class 0 OID 0)
-- Dependencies: 207
-- Name: Pays_pays_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Pays_pays_id_seq"', 2, true);


--
-- TOC entry 3035 (class 0 OID 0)
-- Dependencies: 209
-- Name: Recurence_recurence_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Recurence_recurence_id_seq"', 6, true);


--
-- TOC entry 3036 (class 0 OID 0)
-- Dependencies: 211
-- Name: Sous_categorie_sous_categorie_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Sous_categorie_sous_categorie_id_seq"', 100, true);


--
-- TOC entry 3037 (class 0 OID 0)
-- Dependencies: 213
-- Name: Statut_statut_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Statut_statut_id_seq"', 3, true);


--
-- TOC entry 3038 (class 0 OID 0)
-- Dependencies: 215
-- Name: Transaction_transaction_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Transaction_transaction_id_seq"', 53, true);


--
-- TOC entry 3039 (class 0 OID 0)
-- Dependencies: 217
-- Name: Type_transaction_type_transaction_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Type_transaction_type_transaction_id_seq"', 2, true);


--
-- TOC entry 3040 (class 0 OID 0)
-- Dependencies: 219
-- Name: Utilisateur_utilisateur_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Utilisateur_utilisateur_id_seq"', 8, true);


--
-- TOC entry 3041 (class 0 OID 0)
-- Dependencies: 221
-- Name: droit_droit_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.droit_droit_id_seq', 3, true);


--
-- TOC entry 3042 (class 0 OID 0)
-- Dependencies: 224
-- Name: test_testt_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.test_testt_seq', 12, true);


--
-- TOC entry 2790 (class 2606 OID 17707)
-- Name: categorie Categorie_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categorie
    ADD CONSTRAINT "Categorie_pkey" PRIMARY KEY (categorie_id);


--
-- TOC entry 2794 (class 2606 OID 17709)
-- Name: limite Limite_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.limite
    ADD CONSTRAINT "Limite_pkey" PRIMARY KEY (limite_id);


--
-- TOC entry 2796 (class 2606 OID 17711)
-- Name: modele_transaction Modele_transaction_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.modele_transaction
    ADD CONSTRAINT "Modele_transaction_pkey" PRIMARY KEY (modele_transaction_id);


--
-- TOC entry 2798 (class 2606 OID 17713)
-- Name: notification Notification_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notification
    ADD CONSTRAINT "Notification_pkey" PRIMARY KEY (notification_id);


--
-- TOC entry 2800 (class 2606 OID 17715)
-- Name: options Options_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.options
    ADD CONSTRAINT "Options_pkey" PRIMARY KEY (options_id);


--
-- TOC entry 2802 (class 2606 OID 17717)
-- Name: pays Pays_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pays
    ADD CONSTRAINT "Pays_pkey" PRIMARY KEY (pays_id);


--
-- TOC entry 2806 (class 2606 OID 17719)
-- Name: recurence Recurence_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.recurence
    ADD CONSTRAINT "Recurence_pkey" PRIMARY KEY (recurence_id);


--
-- TOC entry 2810 (class 2606 OID 17721)
-- Name: sous_categorie Sous-categorie_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sous_categorie
    ADD CONSTRAINT "Sous-categorie_pkey" PRIMARY KEY (sous_categorie_id);


--
-- TOC entry 2814 (class 2606 OID 17723)
-- Name: statut Statut_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.statut
    ADD CONSTRAINT "Statut_pkey" PRIMARY KEY (statut_id);


--
-- TOC entry 2818 (class 2606 OID 17725)
-- Name: transaction Transaction_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transaction
    ADD CONSTRAINT "Transaction_pkey" PRIMARY KEY (transaction_id);


--
-- TOC entry 2820 (class 2606 OID 17727)
-- Name: type_transaction Type_transaction_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.type_transaction
    ADD CONSTRAINT "Type_transaction_pkey" PRIMARY KEY (type_transaction_id);


--
-- TOC entry 2824 (class 2606 OID 17729)
-- Name: utilisateur Utilisateur_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.utilisateur
    ADD CONSTRAINT "Utilisateur_pkey" PRIMARY KEY (utilisateur_id);


--
-- TOC entry 2830 (class 2606 OID 17731)
-- Name: droit droit_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.droit
    ADD CONSTRAINT droit_pkey PRIMARY KEY (droit_id);


--
-- TOC entry 2826 (class 2606 OID 17733)
-- Name: utilisateur emailUnique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.utilisateur
    ADD CONSTRAINT "emailUnique" UNIQUE (email);


--
-- TOC entry 2792 (class 2606 OID 17735)
-- Name: categorie nomCategorieUnique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categorie
    ADD CONSTRAINT "nomCategorieUnique" UNIQUE (nom);


--
-- TOC entry 2832 (class 2606 OID 17737)
-- Name: droit nomDroitUnique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.droit
    ADD CONSTRAINT "nomDroitUnique" UNIQUE (nom);


--
-- TOC entry 2812 (class 2606 OID 17739)
-- Name: sous_categorie nomEtIdUniqueSousCat; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sous_categorie
    ADD CONSTRAINT "nomEtIdUniqueSousCat" UNIQUE (nom, categorie_id);


--
-- TOC entry 2804 (class 2606 OID 17741)
-- Name: pays nomPaysUnique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pays
    ADD CONSTRAINT "nomPaysUnique" UNIQUE (nom);


--
-- TOC entry 2816 (class 2606 OID 17743)
-- Name: statut nomStatutUnique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.statut
    ADD CONSTRAINT "nomStatutUnique" UNIQUE (nom);


--
-- TOC entry 2808 (class 2606 OID 17745)
-- Name: recurence periodiciteUnique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.recurence
    ADD CONSTRAINT "periodiciteUnique" UNIQUE (periodicite);


--
-- TOC entry 2828 (class 2606 OID 17747)
-- Name: utilisateur pseudoUnique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.utilisateur
    ADD CONSTRAINT "pseudoUnique" UNIQUE (pseudo);


--
-- TOC entry 2834 (class 2606 OID 17749)
-- Name: test test_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.test
    ADD CONSTRAINT test_pkey PRIMARY KEY (testt);


--
-- TOC entry 2822 (class 2606 OID 17751)
-- Name: type_transaction typeTransactionUnique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.type_transaction
    ADD CONSTRAINT "typeTransactionUnique" UNIQUE (type);


--
-- TOC entry 2852 (class 2620 OID 17752)
-- Name: modele_transaction createTransaction; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "createTransaction" AFTER INSERT ON public.modele_transaction FOR EACH ROW WHEN ((new.date = CURRENT_DATE)) EXECUTE PROCEDURE public."transactionCreation"();


--
-- TOC entry 2853 (class 2620 OID 17753)
-- Name: transaction soldeModifExpense; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "soldeModifExpense" BEFORE INSERT ON public.transaction FOR EACH ROW EXECUTE PROCEDURE public."modifSoldeExpense"();


--
-- TOC entry 2854 (class 2620 OID 17754)
-- Name: transaction soldeModifIncome; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "soldeModifIncome" AFTER INSERT ON public.transaction FOR EACH ROW EXECUTE PROCEDURE public."modifSoldeIncome"();


--
-- TOC entry 2844 (class 2606 OID 17755)
-- Name: sous_categorie categorie_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sous_categorie
    ADD CONSTRAINT categorie_id FOREIGN KEY (categorie_id) REFERENCES public.categorie(categorie_id) ON UPDATE CASCADE ON DELETE SET DEFAULT;


--
-- TOC entry 2835 (class 2606 OID 17760)
-- Name: limite categorie_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.limite
    ADD CONSTRAINT categorie_id FOREIGN KEY (categorie_id) REFERENCES public.categorie(categorie_id);


--
-- TOC entry 2846 (class 2606 OID 17765)
-- Name: utilisateur droit_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.utilisateur
    ADD CONSTRAINT droit_id FOREIGN KEY (droit_id) REFERENCES public.droit(droit_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2845 (class 2606 OID 17770)
-- Name: transaction modele_transaction_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transaction
    ADD CONSTRAINT modele_transaction_id FOREIGN KEY (modele_transaction_id) REFERENCES public.modele_transaction(modele_transaction_id) ON UPDATE CASCADE;


--
-- TOC entry 2847 (class 2606 OID 17775)
-- Name: utilisateur options_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.utilisateur
    ADD CONSTRAINT options_id FOREIGN KEY (options_id) REFERENCES public.options(options_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 2848 (class 2606 OID 17780)
-- Name: utilisateur pays_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.utilisateur
    ADD CONSTRAINT pays_id FOREIGN KEY (pays_id) REFERENCES public.pays(pays_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 2836 (class 2606 OID 17785)
-- Name: limite recurence_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.limite
    ADD CONSTRAINT recurence_id FOREIGN KEY (recurence_id) REFERENCES public.recurence(recurence_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 2839 (class 2606 OID 17790)
-- Name: modele_transaction recurence_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.modele_transaction
    ADD CONSTRAINT recurence_id FOREIGN KEY (recurrence_id) REFERENCES public.recurence(recurence_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 2837 (class 2606 OID 17795)
-- Name: limite sous_categorie_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.limite
    ADD CONSTRAINT sous_categorie_id FOREIGN KEY (sous_categorie_id) REFERENCES public.sous_categorie(sous_categorie_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2840 (class 2606 OID 17800)
-- Name: modele_transaction sous_categorie_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.modele_transaction
    ADD CONSTRAINT sous_categorie_id FOREIGN KEY (sous_categorie_id) REFERENCES public.sous_categorie(sous_categorie_id) ON UPDATE CASCADE ON DELETE SET DEFAULT;


--
-- TOC entry 2850 (class 2606 OID 17805)
-- Name: sous_categories_personnelles sous_categorie_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sous_categories_personnelles
    ADD CONSTRAINT sous_categorie_id_fk FOREIGN KEY (sous_categorie_id) REFERENCES public.sous_categorie(sous_categorie_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2849 (class 2606 OID 17810)
-- Name: utilisateur statut_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.utilisateur
    ADD CONSTRAINT statut_id FOREIGN KEY (statut_id) REFERENCES public.statut(statut_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 2841 (class 2606 OID 17815)
-- Name: modele_transaction type_transaction_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.modele_transaction
    ADD CONSTRAINT type_transaction_id FOREIGN KEY (type_transaction_id) REFERENCES public.type_transaction(type_transaction_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 2843 (class 2606 OID 17820)
-- Name: notification utilisateur_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notification
    ADD CONSTRAINT utilisateur_id FOREIGN KEY (utilisateur_id) REFERENCES public.utilisateur(utilisateur_id) ON DELETE CASCADE;


--
-- TOC entry 2838 (class 2606 OID 17825)
-- Name: limite utilisateur_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.limite
    ADD CONSTRAINT utilisateur_id FOREIGN KEY (utilisateur_id) REFERENCES public.utilisateur(utilisateur_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2842 (class 2606 OID 17830)
-- Name: modele_transaction utilisateur_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.modele_transaction
    ADD CONSTRAINT utilisateur_id FOREIGN KEY (utilisateur_id) REFERENCES public.utilisateur(utilisateur_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2851 (class 2606 OID 17835)
-- Name: sous_categories_personnelles utilisateur_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sous_categories_personnelles
    ADD CONSTRAINT utilisateur_id_fk FOREIGN KEY (utilisateur_id) REFERENCES public.utilisateur(utilisateur_id);


--
-- TOC entry 3014 (class 0 OID 0)
-- Dependencies: 229
-- Name: FUNCTION "transactionCreation"(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public."transactionCreation"() FROM postgres;


-- Completed on 2019-05-15 15:26:21

--
-- PostgreSQL database dump complete
--

