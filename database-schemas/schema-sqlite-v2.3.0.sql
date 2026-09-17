-- ============================================================================
-- PHES-ODM v2.3.0 (archival) — SQLite schema
--
-- One-off archival schema, generated 2026-09 alongside the live v3.0.1 schema
-- because v2.3.0 (a v2-line patch release) shipped after v3.0.1 development
-- was already underway. Derived from schema-sqlite-v3.0.1.sql by removing
-- exactly what v2.3.0's dictionary-tables lack relative to v3.0.1 (confirmed
-- empirically, column-by-column, against both versions' real parts.csv/
-- sets.csv "table-membership triplet" columns, not assumed from the
-- changelog's prose alone):
--   - Whole tables dropped entirely: accessions, calculations, phActions,
--     polygonRelationships (v3.0.1's genomics/AMR/public-health-action
--     feature expansion, deliberately excluded from the v2.3.0 backport).
--   - `parts`: dropped the three table-membership columns per excluded
--     table above (12 columns total).
--   - `measures`: dropped epiWeek/epiWeekStart/epiYear/relDateStart/
--     relDateEnd/valTreat/pipelineID (the last was the calculations FK,
--     meaningless once that table is gone).
--   - `sites`: dropped siteLevel.
--   - `samples`: dropped collAppxT/collDate/epiWeek/epiWeekStart/epiYear.
-- Every other table's columns are byte-identical to v3.0.1's — this is a
-- pure subtraction, not a re-derivation; no v2.3.0-only column exists that
-- v3.0.1 lacks. Load-tested clean against a real SQLite database (schema
-- alone; a NOT NULL-only sanity load against a hand-built row also passed).
--
-- Otherwise a sibling of schema-postgres-v2.3.0.sql (see that file for the
-- non-dialect design notes) and of the dialect notes already established for
-- schema-sqlite-v3.0.1.sql: FK enforcement needs `PRAGMA foreign_keys = ON`
-- every connection; SQLite ALTER TABLE can't add a FK after the fact, so
-- every FK here (including the 14 self-referencing ones on `parts`) is
-- declared inline; DOUBLE PRECISION -> REAL; VARCHAR(n)/CHAR(n)/TIMESTAMP/
-- DATE lengths are kept for cross-dialect readability but not enforced
-- (type affinity only).
-- ============================================================================

PRAGMA foreign_keys = ON;


-- ============================================================================
-- SECTION 1: Dictionary look-up tables (green, per ERD)
-- ============================================================================

CREATE TABLE languages (
  lang          VARCHAR(30)  PRIMARY KEY,   -- ISO639-3 code
  "langFam"     VARCHAR(30)  NOT NULL,
  "langName"    VARCHAR(30)  NOT NULL,
  "natName"     VARCHAR(30)  NOT NULL,
  "iso6391"     VARCHAR(30)  NOT NULL,
  "iso6392T"    VARCHAR(30)  NOT NULL,
  "firstReleased" VARCHAR(30) NOT NULL,
  "lastUpdated"   VARCHAR(30) NOT NULL,
  changes       VARCHAR(30),
  notes         VARCHAR(1000)
);

CREATE TABLE countries (
  "isoCode"       CHAR(2)      PRIMARY KEY,  -- ISO 3166-1 alpha-2
  "isoCodeX"      CHAR(3),     -- ISO 3166-1 alpha-3
  "numCode"       CHAR(3),     -- ISO 3166-1 numeric
  tld             VARCHAR(20),  -- nullable: disputed/non-standard territories (e.g. Spratly Islands) have no TLD
  "nameEngl"      VARCHAR(75)  NOT NULL,
  "nameOfficial"  VARCHAR(200)  NOT NULL,
  sovereignty     VARCHAR(50)  NOT NULL,
  "countryExonym" VARCHAR(75),
  "capitalExonym" VARCHAR(150),
  "countryEndonym" VARCHAR(200),
  "capitalEndonym" TEXT,
  "langScript"    TEXT,
  phone           VARCHAR(75),
  utc             VARCHAR(75),
  "utcDST"        VARCHAR(75)
);

CREATE TABLE zones (
  "isoCode"  CHAR(2)      NOT NULL REFERENCES countries("isoCode"),
  "isoZone"  VARCHAR(6)   PRIMARY KEY,  -- ISO 3166-2
  "zoneName" VARCHAR(75)  NOT NULL
);

-- `parts` is the controlled vocabulary at the centre of the whole dictionary.
-- Every FK below marked "-> parts" is the "loose" categorical constraint from
-- schema-postgres.sql's design note 1; every FK marked "-> parts (partID reference
-- by convention)" is the semantic judgment call from design note 2. All 14 are
-- declared inline here (see dialect note B) instead of via ALTER TABLE.
CREATE TABLE parts (
  "partID"          VARCHAR(30)   PRIMARY KEY,
  "label"           TEXT   NOT NULL,
  "partType"        VARCHAR(30)   NOT NULL REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,
  "partDesc"        VARCHAR(1000) NOT NULL,   -- free text
  "partInstr"       TEXT,             -- free text
  "fKAliasID"       VARCHAR(30)   NOT NULL REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,  -- "NA" sentinel when not applicable, verified never blank across all 2345 rows
  domain            VARCHAR(30)   NOT NULL REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,  -- domains enum ∪ missingness
  "specimenSet"     VARCHAR(30)   NOT NULL REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,  -- partID reference by convention
  "compartmentSet"  VARCHAR(30)   NOT NULL REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,  -- partID reference by convention
  "group"           VARCHAR(30)   NOT NULL REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,  -- groups enum ∪ missingness
  class             VARCHAR(30)   NOT NULL REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,  -- classes enum ∪ missingness
  nomenclature      VARCHAR(30)   REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,            -- nomenclatures enum ∪ missingness
  "ontologyRef"     VARCHAR(200),             -- free text (external ontology URL)
  "latExp"          VARCHAR(30),              -- free text (LaTeX expression)
  "mmaSet"          VARCHAR(30)   REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,            -- mmaSets enum ∪ missingness
  "unitSet"         VARCHAR(30)   REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,            -- partID reference by convention
  "aggregationScale" VARCHAR(30)  REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,            -- aggregationScales enum ∪ missingness
  "aggregationSet"  VARCHAR(30)   NOT NULL REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,   -- aggregationSets enum ∪ missingness
  "qualityIndSet"   VARCHAR(30)   REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,            -- partID reference by convention
  "missingnessSet"  VARCHAR(30)   REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,            -- missingnessSets enum ∪ missingness
  status            VARCHAR(30)   NOT NULL REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,   -- statusSet enum
  "firstReleased"   VARCHAR(30)   NOT NULL,
  "lastUpdated"     VARCHAR(30)   NOT NULL,
  changes           TEXT,

  -- Table-membership triplets: <table>/<table>Required/<table>Order, one per
  -- reportable table this part can appear in as a column ('input'/'header'/'pK'/'fK').
  "protocolSteps" VARCHAR(30), "protocolStepsRequired" VARCHAR(30), "protocolStepsOrder" INTEGER,
  "protocolRelationships" VARCHAR(30), "protocolRelationshipsRequired" VARCHAR(30), "protocolRelationshipsOrder" INTEGER,
  measures VARCHAR(30), "measuresRequired" VARCHAR(30), "measuresOrder" INTEGER,
  "measureSets" VARCHAR(30), "measureSetsOrder" INTEGER, "measureSetsRequired" VARCHAR(30),
  datasets VARCHAR(30), "datasetsRequired" VARCHAR(30), "datasetsOrder" INTEGER,
  sites VARCHAR(30), "sitesRequired" VARCHAR(30), "sitesOrder" INTEGER,
  samples VARCHAR(30), "samplesRequired" VARCHAR(30), "samplesOrder" INTEGER,
  addresses VARCHAR(30), "addressesRequired" VARCHAR(30), "addressesOrder" INTEGER,
  contacts VARCHAR(30), "contactsRequired" VARCHAR(30), "contactsOrder" INTEGER,
  organizations VARCHAR(30), "organizationsRequired" VARCHAR(30), "organizationsOrder" INTEGER,
  instruments VARCHAR(30), "instrumentsRequired" VARCHAR(30), "instrumentsOrder" INTEGER,
  polygons VARCHAR(30), "polygonsRequired" VARCHAR(30), "polygonsOrder" INTEGER,
  languages VARCHAR(30), "languagesRequired" VARCHAR(30), "languagesOrder" INTEGER,
  translations VARCHAR(30), "translationsRequired" VARCHAR(30), "translationsOrder" INTEGER,
  parts VARCHAR(30), "partsRequired" VARCHAR(30), "partsOrder" INTEGER,
  sets VARCHAR(30), "setsRequired" VARCHAR(30), "setsOrder" INTEGER,
  "qualityReports" VARCHAR(30), "qualityReportsRequired" VARCHAR(30), "qualityReportsOrder" INTEGER,
  "sampleRelationships" VARCHAR(30), "sampleRelationshipsRequired" VARCHAR(30), "sampleRelationshipsOrder" INTEGER,
  protocols VARCHAR(30), "protocolsRequired" VARCHAR(30), "protocolsOrder" INTEGER,
  countries VARCHAR(30), "countriesRequired" VARCHAR(30), "countriesOrder" INTEGER,
  zones VARCHAR(30), "zonesRequired" VARCHAR(30), "zonesOrder" INTEGER,
  "wideNames" VARCHAR(30), "wideNamesRequired" VARCHAR(30), "wideNamesOrder" INTEGER,

  "refLink"   VARCHAR(255),               -- free text
  "dataType" VARCHAR(30) NOT NULL REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,  -- dataTypes enum
  "minValue"  VARCHAR(30),                 -- free text (numeric-as-string, "seeUnitVal" etc.)
  "maxValue"  VARCHAR(30),
  "minLength" INTEGER,
  "maxLength" INTEGER
);

CREATE INDEX idx_parts_partType ON parts("partType");
CREATE INDEX idx_parts_domain   ON parts(domain);
CREATE INDEX idx_parts_group    ON parts("group");
CREATE INDEX idx_parts_class    ON parts(class);

-- `sets` maps parts into named groups (unit sets, mma/category sets, etc.).
-- setID and partID both reference parts(partID); setType is documentation-only
-- (mirrors the referenced setID's own partType) rather than a separate FK target.
CREATE TABLE sets (
  "setCompID"     VARCHAR(60)  PRIMARY KEY,             -- computed: setID || '_' || partID
  "setID"         VARCHAR(30)  NOT NULL REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,
  "setType"       VARCHAR(30)  NOT NULL,                -- documentation only, see note above
  "partID"        VARCHAR(30)  NOT NULL REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,
  label           VARCHAR(150)  NOT NULL,                -- denormalized copy of parts.label at write time
  enumeration     INTEGER      NOT NULL,
  status          VARCHAR(30)  NOT NULL REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,
  "firstReleased" VARCHAR(30)  NOT NULL,
  "lastUpdated"   VARCHAR(30)  NOT NULL,
  changes         TEXT,  -- free text; longest live value is 74 chars (parts.csv's own maxLength for "changes" was corrected 30->100 to match)
  notes           VARCHAR(1000)
);

CREATE INDEX idx_sets_setID  ON sets("setID");
CREATE INDEX idx_sets_partID ON sets("partID");

CREATE TABLE translations (
  "translationID" VARCHAR(50)  PRIMARY KEY,
  lang            VARCHAR(30)  NOT NULL REFERENCES languages(lang),
  "partID"        VARCHAR(30)  NOT NULL REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,
  "label"         TEXT  NOT NULL,   -- free text (translated)
  "partDesc"      VARCHAR(1000) NOT NULL,  -- free text (translated)
  "partInstr"     TEXT,            -- free text (translated)
  "firstReleased" VARCHAR(30)  NOT NULL,
  "lastUpdated"   VARCHAR(30)  NOT NULL,
  changes         TEXT,
  notes           VARCHAR(1000)
);

CREATE INDEX idx_translations_partID ON translations("partID");
CREATE INDEX idx_translations_lang   ON translations(lang);

-- wideNames rows are keyed by their own synthetic wideName, not by parts — the
-- *Name/*Input column pairs each reference a part loosely (by convention, per
-- schema-postgres.sql design note 2) but the LinkML doesn't range-type them as
-- parts, so they're left unconstrained here to match; add FKs later if you want
-- them enforced.
CREATE TABLE "wideNames" (
  "wideName"        VARCHAR(100)  PRIMARY KEY,
  label             VARCHAR(100)  NOT NULL,
  "charLength"      VARCHAR(30),
  descr             VARCHAR(1000) NOT NULL,   -- free text
  source            VARCHAR(30)  NOT NULL,
  "wideMeasure"      VARCHAR(60),
  "wideProtocol"     VARCHAR(30),
  "wideAttribute"    VARCHAR(30),
  "wideNameType"     VARCHAR(30),
  "reportTableName"  VARCHAR(60),  -- widened from 30: live value "Quality reports table Shorthand" is 31 chars (parts.csv's own maxLength for "reportTableName" was corrected 30->40 to match)
  "reportTableInput" VARCHAR(30),
  "partTypeName"     VARCHAR(30),
  "partTypeInput"    VARCHAR(30),
  "compartmentName"  VARCHAR(30),
  "compartmentInput" VARCHAR(30),
  "specimenName"     VARCHAR(30),
  "specimenInput"    VARCHAR(30),
  "fractionName"     VARCHAR(60),
  "fractionInput"    VARCHAR(30),
  "measureName"      VARCHAR(60),
  "measureInput"     VARCHAR(100),
  "methodName"       VARCHAR(30),
  "methodInput"      VARCHAR(30),
  "unitName"         VARCHAR(30),
  "unitInput"        VARCHAR(30),
  "aggregationName"  VARCHAR(60),
  "aggregationInput" VARCHAR(30),
  "index"           VARCHAR(50),             -- free text, any_of[string, genMissingnessSet]
  "attributeName"    VARCHAR(60),
  "attributeInput"   VARCHAR(30),
  tag                VARCHAR(10)   -- sparse boolean-ish flag column found in the live CSV
                                    -- during seed generation, missing from the initial
                                    -- LinkML-derived schema — only 4/131 rows populated ('1')
);


-- ============================================================================
-- SECTION 2: Program-description tables (yellow, per ERD)
-- ============================================================================

CREATE TABLE addresses (
  "addressID"    VARCHAR(30)  PRIMARY KEY,
  "addL1"        VARCHAR(30)  NOT NULL,
  "addL2"        VARCHAR(30),
  city           VARCHAR(30)  NOT NULL,
  "stateProvReg" VARCHAR(30)  NOT NULL,
  "pCode"        VARCHAR(30),
  country        VARCHAR(30)  NOT NULL,
  "lastEdited"   TIMESTAMP,
  notes          VARCHAR(1000)
);

CREATE TABLE organizations (
  "organizationID" VARCHAR(100) PRIMARY KEY,
  name             VARCHAR(30),
  descr            VARCHAR(1000),
  "addressID"      VARCHAR(30)  NOT NULL REFERENCES addresses("addressID"),
  "orgType"        VARCHAR(30)  REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,
  "orgLevel"       VARCHAR(30)  REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,
  "orgSector"      VARCHAR(30)  REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,
  "lastEdited"     TIMESTAMP,
  notes            VARCHAR(1000)
);

CREATE TABLE contacts (
  "contactID"      VARCHAR(30)  PRIMARY KEY,
  "organizationID" VARCHAR(100) REFERENCES organizations("organizationID"),
  "firstName"      VARCHAR(30),
  "lastName"       VARCHAR(30),
  email            VARCHAR(100) NOT NULL,
  "coPhone"        VARCHAR(30),
  role             VARCHAR(30),
  "lastEdited"     TIMESTAMP,
  notes            VARCHAR(1000)
);

-- funderCont/custodyCont/funderID/custodyID: LinkML types these as generic strings,
-- but per their own descriptions they hold contact/organization IDs ("Use Contact ID
-- to populate this field" / "Use Organization ID to populate this field") — FK'd per
-- maintainer decision, overriding the LinkML's loose literal typing.
CREATE TABLE datasets (
  "parDatasetID"   VARCHAR(30),
  "datasetID"      VARCHAR(30)  PRIMARY KEY,
  "datasetDate"    TIMESTAMP,
  name             VARCHAR(30),
  license          VARCHAR(30)  NOT NULL REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,
  descr            VARCHAR(1000),
  "refLink"        VARCHAR(255),
  lang             VARCHAR(30)  REFERENCES languages(lang),
  "funderCont"     VARCHAR(30)  REFERENCES contacts("contactID"),
  "custodyCont"    VARCHAR(30)  REFERENCES contacts("contactID"),
  "funderID"       VARCHAR(100) REFERENCES organizations("organizationID"),  -- widened to match organizationID's declared length
  "custodyID"      VARCHAR(100) NOT NULL REFERENCES organizations("organizationID"),
  "originalFormat" VARCHAR(30)  REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,
  "lastEdited"     TIMESTAMP,
  notes            VARCHAR(1000),
  FOREIGN KEY ("parDatasetID") REFERENCES datasets("datasetID")
);

CREATE TABLE instruments (
  "instrumentID" VARCHAR(30)  PRIMARY KEY,
  name           VARCHAR(30),
  model          VARCHAR(100) NOT NULL,
  manufacturer   VARCHAR(100),
  descr          VARCHAR(1000),
  "refLink"      VARCHAR(255),
  "insType"      VARCHAR(30)  NOT NULL REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,
  "insTypeOth"   VARCHAR(1000),
  "index"        VARCHAR(50),
  "lastEdited"   TIMESTAMP,
  notes          VARCHAR(1000)
);

CREATE TABLE protocols (
  "sourceProtocol"  VARCHAR(30),
  "protocolID"      VARCHAR(30)  PRIMARY KEY,
  name              VARCHAR(30),
  summ              VARCHAR(1000),
  "refLink"         VARCHAR(255),
  "organizationID"  VARCHAR(100) REFERENCES organizations("organizationID"),
  "contactID"       VARCHAR(30)  REFERENCES contacts("contactID"),
  "protocolVersion" INTEGER,
  "lastEdited"      TIMESTAMP,
  notes             VARCHAR(1000),
  FOREIGN KEY ("sourceProtocol") REFERENCES protocols("protocolID")
);

CREATE TABLE "protocolSteps" (
  "stepID"        VARCHAR(30)  PRIMARY KEY,
  method          VARCHAR(30)  REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,
  measure         VARCHAR(100) REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,
  summ            VARCHAR(1000),
  "sourceStep"    VARCHAR(30),
  "stepVer"       VARCHAR(50),
  "refLink"       VARCHAR(255),
  "organizationID" VARCHAR(100) REFERENCES organizations("organizationID"),
  "contactID"     VARCHAR(30)  REFERENCES contacts("contactID"),
  "instrumentID"  VARCHAR(30)  REFERENCES instruments("instrumentID"),
  value           VARCHAR(100),
  unit            VARCHAR(30)  REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,
  aggregation     VARCHAR(30)  REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,
  "lastEdited"    TIMESTAMP,
  notes           VARCHAR(1000),
  FOREIGN KEY ("sourceStep") REFERENCES "protocolSteps"("stepID")
);

CREATE TABLE "protocolRelationships" (
  "protocolRelationshipsID" VARCHAR(50) PRIMARY KEY,
  "protocolIDContainer"     VARCHAR(30) NOT NULL,
  "protocolIDObj"           VARCHAR(30),
  "stepIDObj"               VARCHAR(30),
  "relationshipID"          VARCHAR(30) NOT NULL REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,
  "protocolIDSub"           VARCHAR(30),
  "stepIDSub"               VARCHAR(30),
  "lastEdited"              TIMESTAMP,
  notes                     VARCHAR(1000),
  FOREIGN KEY ("protocolIDContainer") REFERENCES protocols("protocolID"),
  FOREIGN KEY ("protocolIDObj")       REFERENCES protocols("protocolID"),
  FOREIGN KEY ("stepIDObj")           REFERENCES "protocolSteps"("stepID"),
  FOREIGN KEY ("protocolIDSub")       REFERENCES protocols("protocolID"),
  FOREIGN KEY ("stepIDSub")           REFERENCES "protocolSteps"("stepID")
);

CREATE TABLE polygons (
  "polygonID"      VARCHAR(30)  PRIMARY KEY,
  "datasetID"      VARCHAR(30)  REFERENCES datasets("datasetID"),
  name             VARCHAR(30),
  descr            VARCHAR(1000),
  "geoType"        VARCHAR(30)  NOT NULL REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,
  "geoEPSG"        REAL         NOT NULL,
  "geoWKT"         TEXT         NOT NULL,  -- source LinkML's pattern caps this at 63 chars
                                            -- ("^.{0,63}$"), too short for realistic WKT
                                            -- geometry text — widened to TEXT per maintainer
                                            -- decision, deliberately overriding that bound.
  "fileLocation"   TEXT,
  "refLink"        VARCHAR(255),
  "organizationID" VARCHAR(100) REFERENCES organizations("organizationID"),
  "contactID"      VARCHAR(30)  REFERENCES contacts("contactID"),
  "poLic"          VARCHAR(50)  REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,
  "lastEdited"     TIMESTAMP,
  notes            VARCHAR(1000)
);


-- ============================================================================
-- SECTION 3: Results tables (blue, per ERD)
-- ============================================================================

CREATE TABLE sites (
  "parSiteID"      VARCHAR(30),
  "siteID"         VARCHAR(30)  PRIMARY KEY,
  "datasetID"      VARCHAR(30)  REFERENCES datasets("datasetID"),
  "polygonID"      VARCHAR(30)  REFERENCES polygons("polygonID"),
  "siteType"       VARCHAR(30)  NOT NULL REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,
  "sampleShed"     VARCHAR(30)  NOT NULL REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,
  "addressID"      VARCHAR(30)  REFERENCES addresses("addressID"),
  "organizationID" VARCHAR(100) REFERENCES organizations("organizationID"),
  "contactID"      VARCHAR(30)  NOT NULL REFERENCES contacts("contactID"),
  name             VARCHAR(30),
  descr            VARCHAR(1000),
  "repOrg1"        VARCHAR(30),
  "repOrg2"        VARCHAR(30),
  "healthRegion"   VARCHAR(30),
  "geoLat"         REAL,
  "geoLong"        REAL,
  "geoEPSG"        VARCHAR(30),
  "lastEdited"     TIMESTAMP,
  notes            VARCHAR(1000),
  FOREIGN KEY ("parSiteID") REFERENCES sites("siteID")
);

CREATE TABLE samples (
  "sampleID"       VARCHAR(30)  PRIMARY KEY,
  "protocolID"     VARCHAR(30)  REFERENCES protocols("protocolID"),
  "organizationID" VARCHAR(100) REFERENCES organizations("organizationID"),
  "contactID"      VARCHAR(30)  REFERENCES contacts("contactID"),
  "siteID"         VARCHAR(30)  NOT NULL REFERENCES sites("siteID"),
  purpose          VARCHAR(30)  REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,
  "saMaterial"     VARCHAR(30)  NOT NULL REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,
  "datasetID"      VARCHAR(30)  REFERENCES datasets("datasetID"),
  origin           VARCHAR(30)  REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,
  "repType"        VARCHAR(30)  REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,
  "collType"       VARCHAR(30)  NOT NULL REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,
  "collPer"        REAL         NOT NULL CHECK ("collPer" >= 1),
  "collNum"        INTEGER      NOT NULL CHECK ("collNum" >= 1),
  pooled           VARCHAR(30)  REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,
  "collDT"         TIMESTAMP    NOT NULL,
  "collDTStart"    TIMESTAMP,
  "collDTEnd"      TIMESTAMP,
  "sentDate"       TIMESTAMP,
  "recDate"        TIMESTAMP,
  reportable       VARCHAR(30)  REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,
  "lastEdited"     TIMESTAMP,
  notes            VARCHAR(1000)
);

CREATE TABLE "sampleRelationships" (
  "sampleRelationshipsID" VARCHAR(50) PRIMARY KEY,
  "sampleIDSubject"       VARCHAR(30) NOT NULL REFERENCES samples("sampleID"),
  "relationshipID"        VARCHAR(30) NOT NULL REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,
  "sampleIDObject"        VARCHAR(30) NOT NULL REFERENCES samples("sampleID"),
  "lastEdited"            TIMESTAMP,
  notes                   VARCHAR(1000)
);

CREATE TABLE "measureSets" (
  "measureSetRepID" VARCHAR(30) PRIMARY KEY,
  "protocolID"      VARCHAR(30) REFERENCES protocols("protocolID"),
  name              VARCHAR(30),
  "organizationID"  VARCHAR(100) REFERENCES organizations("organizationID"),
  "contactID"       VARCHAR(30) REFERENCES contacts("contactID"),
  "lastEdited"      TIMESTAMP,
  notes             VARCHAR(1000)
);

CREATE TABLE measures (
  "measureRepID"    VARCHAR(30) PRIMARY KEY,
  "protocolID"      VARCHAR(30) REFERENCES protocols("protocolID"),
  "sampleID"        VARCHAR(30) NOT NULL REFERENCES samples("sampleID"),
  purpose           VARCHAR(30) REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,
  "polygonID"       VARCHAR(30) REFERENCES polygons("polygonID"),
  "siteID"          VARCHAR(30) REFERENCES sites("siteID"),
  "datasetID"       VARCHAR(30) REFERENCES datasets("datasetID"),
  "measureSetRepID" VARCHAR(30) REFERENCES "measureSets"("measureSetRepID"),
  name              VARCHAR(30),
  "aDateStart"      TIMESTAMP,
  "aDateEnd"        TIMESTAMP   NOT NULL,
  "reportDate"      TIMESTAMP,
  compartment       VARCHAR(30) REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,
  specimen          VARCHAR(30) NOT NULL REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,
  fraction          VARCHAR(30) REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,
  "group"           VARCHAR(30) REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,
  class             VARCHAR(30) REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,
  measure           VARCHAR(100) NOT NULL REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,
  value             VARCHAR(100) NOT NULL,
  unit              VARCHAR(30) NOT NULL REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,
  aggregation       VARCHAR(30) NOT NULL REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,
  nomenclature      VARCHAR(30) REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,
  "index"           VARCHAR(50),
  "measureLic"      VARCHAR(30) REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,
  reportable        VARCHAR(30) REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,
  "organizationID"  VARCHAR(100) REFERENCES organizations("organizationID"),
  "contactID"       VARCHAR(30) REFERENCES contacts("contactID"),
  "refLink"         VARCHAR(255),
  "lastEdited"      TIMESTAMP,
  notes             VARCHAR(1000)
);

CREATE INDEX idx_measures_sampleID   ON measures("sampleID");
CREATE INDEX idx_measures_measure    ON measures(measure);
CREATE INDEX idx_measures_siteID     ON measures("siteID");

CREATE TABLE "qualityReports" (
  "qualityReportID" VARCHAR(30) PRIMARY KEY,
  "measureRepID"    VARCHAR(30) REFERENCES measures("measureRepID"),
  "sampleID"        VARCHAR(30) REFERENCES samples("sampleID"),
  "measureSetRepID" VARCHAR(30) REFERENCES "measureSets"("measureSetRepID"),
  "qualityFlag"     VARCHAR(30) NOT NULL REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,
  severity          VARCHAR(30) REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,
  "lastEdited"      TIMESTAMP,
  notes             VARCHAR(1000)
);

-- ============================================================================
-- End of schema. See seed-sqlite.sql (once approved) for the ~18k rows of
-- reference-table data (parts, sets, translations, languages, wideNames,
-- countries, zones).
-- ============================================================================
