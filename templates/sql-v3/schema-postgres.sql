-- ============================================================================
-- PHES-ODM v3.0.1 — PostgreSQL schema
-- Generated from: odm_v3 LinkML schema + ODM_ERD_V3.0.1.pdf + dictionary-tables/ODM_parts.csv
-- Supersedes the stale V2-RC2 templates/ODM-mysql.sql (and src/lucid-mysql.sql).
--
-- DESIGN NOTES (read before reviewing table definitions):
--
-- 1. Enum/categorical strictness (per maintainer decision): LOOSE. Every column whose
--    legal values are drawn from an ODM "set" (mmaSet/unitSet/etc.) or a plain
--    enumeration (domains, classes, groups, ...) is constrained only by a foreign key
--    to parts(partID) — i.e. "this must be some real partID", not "this must be a
--    member of the *correct* set for this column". Enforcing the latter would require
--    ~100+ per-set lookup tables or per-column triggers (rejected as out of scope for
--    this pass — see conversation). Every literal value in these columns, including
--    the ODM's own missingness markers ('NA', 'nan', 'miss', 'null', 'nr', ...), is
--    itself a partID row in ODM_parts.csv (partType=missingness), so the FK holds for
--    those too.
--
-- 2. Free-text vs. partID-reference columns: the source LinkML is not internally
--    consistent about how it types "holds a partID by convention" columns — e.g.
--    `mmaSet`/`unitSet` are typed as real enum ranges, but `specimenSet`/
--    `compartmentSet` on the `parts` table are typed as plain `string` even though
--    every value in them is, in practice, a partID (of partType=specimenSets/
--    compartmentSets). This schema applies FKs based on semantic intent, not just the
--    LinkML's literal `range:`, and documents that judgment call per table below.
--    Genuine free text (descr, notes, summ, label, partDesc, partInstr, refLink,
--    latExp, equation, sourceCode, name) never gets an FK, even when the LinkML
--    unions it with `genMissingnessSet` — a free-text column can hold a missingness
--    marker as a literal string without needing the column constrained to *only*
--    partIDs.
--
-- 3. VARCHAR lengths are taken directly from each slot's `pattern: ^.{0,N}$` bound.
--    A few of these look too tight for realistic data (e.g. `geoWKT` at 63 chars for
--    well-known-text geometry) — that's a property of the source schema, not a
--    transcription error here; flagged inline where it looks surprising.
--
-- 4. Self-referencing FKs: `parts.partID` is referenced by many of `parts`' own
--    columns (domain, class, group, partType, mmaSet, unitSet, ...) since the
--    dictionary is self-describing (e.g. the partType "measurements" is itself a row
--    in `parts` with partType='partType'). This is a normal self-referencing FK, not a
--    cross-table cycle — but it means seed-data INSERT order (or deferred constraint
--    checking) matters. See seed-data file preamble for how this is handled.
--
-- 5. Table order below is dependency order (referenced tables first) as far as
--    possible; `parts`/`sets` have circular-ish self/mutual references by design and
--    are declared with their FKs added via ALTER TABLE at the end of each block so
--    CREATE TABLE order doesn't have to be perfect.
-- ============================================================================


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
  tld             VARCHAR(20)   NOT NULL,
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
-- design note 1; every FK marked "-> parts (partID reference by convention)" is the
-- semantic judgment call from design note 2.
CREATE TABLE parts (
  "partID"          VARCHAR(30)   PRIMARY KEY,
  "partLabel"       TEXT   NOT NULL,   -- CSV column is "partLabel", not "label" — see conversation
  "partType"        VARCHAR(30)   NOT NULL,   -- FK added below (self-ref)
  "partDesc"        VARCHAR(1000) NOT NULL,   -- free text
  "partInstr"       TEXT,             -- free text
  domain            VARCHAR(30)   NOT NULL,   -- FK -> parts (domains enum ∪ missingness)
  "specimenSet"     VARCHAR(30)   NOT NULL,   -- FK -> parts (partID reference by convention)
  "compartmentSet"  VARCHAR(30)   NOT NULL,   -- FK -> parts (partID reference by convention)
  "group"           VARCHAR(30)   NOT NULL,   -- FK -> parts (groups enum ∪ missingness)
  class             VARCHAR(30)   NOT NULL,   -- FK -> parts (classes enum ∪ missingness)
  nomenclature      VARCHAR(30),              -- FK -> parts (nomenclatures enum ∪ missingness)
  "ontologyRef"     VARCHAR(200),             -- free text (external ontology URL)
  "latExp"          VARCHAR(30),              -- free text (LaTeX expression)
  "mmaSet"          VARCHAR(30),              -- FK -> parts (mmaSets enum ∪ missingness)
  "unitSet"         VARCHAR(30),              -- FK -> parts (partID reference by convention)
  "aggregationScale" VARCHAR(30),             -- FK -> parts (aggregationScales enum ∪ missingness)
  "aggregationSet"  VARCHAR(30)   NOT NULL,   -- FK -> parts (aggregationSets enum ∪ missingness)
  "qualityIndSet"   VARCHAR(30),              -- FK -> parts (partID reference by convention)
  "missingnessSet"  VARCHAR(30),              -- FK -> parts (missingnessSets enum ∪ missingness)
  status            VARCHAR(30)   NOT NULL,   -- FK -> parts (statusSet enum)
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
  "phActions" VARCHAR(30), "phActionsRequired" VARCHAR(30), "phActionsOrder" INTEGER,
  calculations VARCHAR(30), "calculationsRequired" VARCHAR(30), "calculationsOrder" INTEGER,
  instruments VARCHAR(30), "instrumentsRequired" VARCHAR(30), "instrumentsOrder" INTEGER,
  "polygonRelationships" VARCHAR(30), "polygonRelationshipsRequired" VARCHAR(30), "polygonRelationshipsOrder" INTEGER,
  polygons VARCHAR(30), "polygonsRequired" VARCHAR(30), "polygonsOrder" INTEGER,
  accessions VARCHAR(30), "accessionsRequired" VARCHAR(30), "accessionsOrder" INTEGER,
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
  "dataType" VARCHAR(30) NOT NULL,         -- FK -> parts (dataTypes enum); CSV column is "dataType" (singular)
  "minValue"  VARCHAR(30),                 -- free text (numeric-as-string, "seeUnitVal" etc.)
  "maxValue"  VARCHAR(30),
  "minLength" INTEGER,
  "maxLength" INTEGER
);

-- Self-referencing FKs added after the table exists (avoids ordering issues in DDL).
-- All are DEFERRABLE so a single-transaction bulk load doesn't have to be topologically
-- sorted by hand — see design note 4 and the seed-data file's transaction wrapper.
ALTER TABLE parts ADD CONSTRAINT fk_parts_partType   FOREIGN KEY ("partType")   REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE parts ADD CONSTRAINT fk_parts_domain      FOREIGN KEY (domain)       REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE parts ADD CONSTRAINT fk_parts_specimenSet FOREIGN KEY ("specimenSet") REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE parts ADD CONSTRAINT fk_parts_compartmentSet FOREIGN KEY ("compartmentSet") REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE parts ADD CONSTRAINT fk_parts_group        FOREIGN KEY ("group")     REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE parts ADD CONSTRAINT fk_parts_class        FOREIGN KEY (class)       REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE parts ADD CONSTRAINT fk_parts_nomenclature FOREIGN KEY (nomenclature) REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE parts ADD CONSTRAINT fk_parts_mmaSet       FOREIGN KEY ("mmaSet")    REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE parts ADD CONSTRAINT fk_parts_unitSet      FOREIGN KEY ("unitSet")   REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE parts ADD CONSTRAINT fk_parts_aggScale      FOREIGN KEY ("aggregationScale") REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE parts ADD CONSTRAINT fk_parts_aggSet        FOREIGN KEY ("aggregationSet")   REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE parts ADD CONSTRAINT fk_parts_qualIndSet    FOREIGN KEY ("qualityIndSet")    REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE parts ADD CONSTRAINT fk_parts_missingSet    FOREIGN KEY ("missingnessSet")   REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE parts ADD CONSTRAINT fk_parts_status        FOREIGN KEY (status)      REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE parts ADD CONSTRAINT fk_parts_dataType      FOREIGN KEY ("dataType")  REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED;

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
  changes         VARCHAR(50),
  notes           VARCHAR(1000)
);

CREATE INDEX idx_sets_setID  ON sets("setID");
CREATE INDEX idx_sets_partID ON sets("partID");

CREATE TABLE translations (
  "translationID" VARCHAR(50)  PRIMARY KEY,
  lang            VARCHAR(30)  NOT NULL REFERENCES languages(lang),
  "partID"        VARCHAR(30)  NOT NULL REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,
  "partLabel"     TEXT  NOT NULL,   -- free text (translated); CSV column is "partLabel", not "label"
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
-- *Name/*Input column pairs each reference a part loosely (by convention, per note 2)
-- but the LinkML doesn't range-type them as parts, so they're left unconstrained here
-- to match; add FKs later if you want them enforced.
CREATE TABLE "wideNames" (
  "wideName"        VARCHAR(100)  PRIMARY KEY,
  label             VARCHAR(100)  NOT NULL,
  "charLength"      VARCHAR(30),
  description       VARCHAR(1000) NOT NULL,   -- free text; CSV column is "description", not "descr"
  source            VARCHAR(30)  NOT NULL,
  "wideMeasure"      VARCHAR(60),
  "wideProtocol"     VARCHAR(30),
  "wideAttribute"    VARCHAR(30),
  "wideNameType"     VARCHAR(30),
  "reportTableName"  VARCHAR(30),
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
  index             VARCHAR(50),             -- free text, any_of[string, genMissingnessSet]
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
  index          VARCHAR(50),
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
  "geoEPSG"        DOUBLE PRECISION NOT NULL,
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

CREATE TABLE "polygonRelationships" (
  "polygonRelID"      VARCHAR(50) PRIMARY KEY,
  "polygonIDSubject"  VARCHAR(50) NOT NULL REFERENCES polygons("polygonID"),
  "relationshipID"    VARCHAR(30) REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,
  "polygonIDObject"   VARCHAR(50) NOT NULL REFERENCES polygons("polygonID"),
  "lastEdited"        TIMESTAMP,
  notes               VARCHAR(1000)
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
  "siteLevel"      VARCHAR(30)  REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,
  "addressID"      VARCHAR(30)  REFERENCES addresses("addressID"),
  "organizationID" VARCHAR(100) REFERENCES organizations("organizationID"),
  "contactID"      VARCHAR(30)  NOT NULL REFERENCES contacts("contactID"),
  name             VARCHAR(30),
  descr            VARCHAR(1000),
  "repOrg1"        VARCHAR(30),
  "repOrg2"        VARCHAR(30),
  "healthRegion"   VARCHAR(30),
  "geoLat"         DOUBLE PRECISION,
  "geoLong"        DOUBLE PRECISION,
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
  "collPer"        DOUBLE PRECISION NOT NULL CHECK ("collPer" >= 1),
  "collNum"        INTEGER      NOT NULL CHECK ("collNum" >= 1),
  pooled           VARCHAR(30)  REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,
  "collDT"         TIMESTAMP    NOT NULL,
  "collDTStart"    TIMESTAMP,
  "collDTEnd"      TIMESTAMP,
  "collDate"       DATE,
  "collAppxT"      VARCHAR(50)  REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,
  "epiWeekStart"   DATE,
  "epiWeek"        INTEGER      CHECK ("epiWeek" BETWEEN 1 AND 52),
  "epiYear"        INTEGER      CHECK ("epiYear" BETWEEN 1900 AND 3000),
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

-- pipelineID/calculationID resolution follows the fix proposed in
-- https://odm.discourse.group/t/pipelineid-primary-key-x-foreign-key-issues/200 :
-- calculationID is the sole PK; pipelineID is redefined as an FK to calculationID
-- rather than a plain shared (non-unique) grouping label. Each pipeline gets one
-- "header" row — calcType='pipelineHeader', treatmentID NULL — whose own
-- calculationID is the value every row in that pipeline (including the header
-- itself) uses as pipelineID. That makes pipelineID a normal self-referencing FK
-- (valid target: calculationID is unique), and lets measures.pipelineID FK
-- straight into this table instead of being unconstrained.
-- NOTE: 'pipelineHeader' does not yet exist as a partID under calcTypeSet in the
-- live ODM_parts.csv — it needs to be added (via add-odm-part) before any header
-- row can actually be inserted under the loose FK on calcType.
CREATE TABLE calculations (
  "calculationID" VARCHAR(30) PRIMARY KEY,
  "pipelineID"    VARCHAR(30) NOT NULL,  -- FK added below (self-ref to calculationID)
  "treatmentID"   VARCHAR(30),           -- nullable: NULL only on the pipeline's header row
  name            VARCHAR(30),
  "calcType"      VARCHAR(30) REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,
  standard        VARCHAR(30) REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,
  summary         TEXT,
  "order"         INTEGER     CHECK ("order" BETWEEN 0 AND 100),
  equation        VARCHAR(300),
  "refLink"       VARCHAR(255),
  "sourceCode"    TEXT,
  "lastEdited"    TIMESTAMP,
  notes           VARCHAR(1000),
  -- CASE WHEN guarantees this always evaluates to TRUE/FALSE, never NULL. An
  -- earlier OR-based version (avoiding `IS DISTINCT FROM` for portability) was
  -- caught by empirical testing to silently accept calcType=NULL AND
  -- treatmentID=NULL: that expression evaluated to NULL rather than FALSE for
  -- that combination, and SQL's CHECK treats a NULL result as "satisfied," not
  -- "violated" — a real logic bug, not just a portability nitpick.
  -- COALESCE(...,'') makes the branch condition itself NULL-safe too, so
  -- calcType=NULL correctly routes to the ELSE branch as originally intended.
  CONSTRAINT chk_calculations_header CHECK (
    CASE WHEN COALESCE("calcType", '') = 'pipelineHeader'
         THEN "treatmentID" IS NULL
         ELSE "treatmentID" IS NOT NULL
    END
  )
);

ALTER TABLE calculations ADD CONSTRAINT fk_calculations_pipelineID
  FOREIGN KEY ("pipelineID") REFERENCES calculations("calculationID") DEFERRABLE INITIALLY DEFERRED;

CREATE INDEX idx_calculations_pipelineID ON calculations("pipelineID");

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
  "epiWeekStart"    DATE,
  "epiWeek"         INTEGER     CHECK ("epiWeek" BETWEEN 1 AND 52),
  "epiYear"         INTEGER     CHECK ("epiYear" BETWEEN 1900 AND 3000),
  "relDateStart"    TIMESTAMP,
  "relDateEnd"      TIMESTAMP,
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
  "valTreat"        VARCHAR(30) REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,
  "pipelineID"      VARCHAR(30) REFERENCES calculations("calculationID"),  -- valid now:
                                   -- pipelineID values are calculationIDs of pipeline
                                   -- "header" rows, see calculations table comment.
  nomenclature      VARCHAR(30) REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,
  index             VARCHAR(50),
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
CREATE INDEX idx_measures_pipelineID ON measures("pipelineID");

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

CREATE TABLE accessions (
  "accessIndexID"  VARCHAR(30) PRIMARY KEY,
  "measureRepID"    VARCHAR(30) REFERENCES measures("measureRepID"),
  "measureSetRepID" VARCHAR(30) REFERENCES "measureSets"("measureSetRepID"),
  "phActionID"      VARCHAR(30),  -- FK added after phActions is created
  "dataHost"        VARCHAR(50) NOT NULL REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,
  "organizationID"  VARCHAR(100) REFERENCES organizations("organizationID"),
  "accessNum"       VARCHAR(50) NOT NULL,
  "hostVersion"     VARCHAR(50),
  "lastEdited"      TIMESTAMP,
  notes             VARCHAR(1000)
);

CREATE TABLE "phActions" (
  "actionGrpID"     VARCHAR(30),
  "phActionID"      VARCHAR(30) PRIMARY KEY,
  "measureRepID"    VARCHAR(30) REFERENCES measures("measureRepID"),
  "measureSetRepID" VARCHAR(30) REFERENCES "measureSets"("measureSetRepID"),
  "organizationID"  VARCHAR(100) REFERENCES organizations("organizationID"),
  "siteID"          VARCHAR(30) REFERENCES sites("siteID"),
  "actionType"      VARCHAR(50) REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,
  action            VARCHAR(50) REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,
  "threatTarget"    VARCHAR(50) REFERENCES parts("partID") DEFERRABLE INITIALLY DEFERRED,
  "actionDT"        TIMESTAMP,
  "relDateStart"    TIMESTAMP,
  "relDateEnd"      TIMESTAMP,
  "lastEdited"      TIMESTAMP,
  notes             VARCHAR(1000)
);

ALTER TABLE accessions ADD CONSTRAINT fk_accessions_phAction FOREIGN KEY ("phActionID") REFERENCES "phActions"("phActionID");


-- ============================================================================
-- End of schema. See seed-postgres.sql (once approved) for the ~18k rows of
-- reference-table data (parts, sets, translations, languages, wideNames,
-- countries, zones), and schema-sqlite.sql / schema-mysql.sql for the other two
-- dialect variants (to follow, per agreed sequencing).
-- ============================================================================
