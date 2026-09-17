/*
ODM V2-RC2 ERD from Lucid chart
Downloaded 2022-12-11
*/

CREATE TABLE `datasets` (
  `parDatasetID` varchar,
  `datasetID` varchar,
  `datasetDate` datetime,
  `name` varchar,
  `license` varchar,
  `descr` varchar,
  `refLink` varchar,
  `langID` int,
  `funderCont` varchar,
  `custodyCont` varchar,
  `funderID` varchar,
  `custodyID` varchar,
  `lastEdited` datetime,
  `notes` varchar,
  PRIMARY KEY (`datasetID`));

CREATE TABLE `countries` (
  `ISO2code` varchar,
  `ISO3code` varchar,
  `numCode` varchar,
  `TLD` varchar,
  `nameEngl` varchar,
  `nameLocal` varchar,
  `nameOfficial` varchar,
  `sovereignity` varchar,
  PRIMARY KEY (`ISO2code`)
);

CREATE TABLE `zones` (
  `ISO2code` varchar,
  `ISO2zone` varchar,
  `zoneName` varchar,
  PRIMARY KEY (`ISO2code`));

CREATE TABLE `addresses` (
  `addressID` varchar,
  `datasetID` varchar,
  `addL1` varchar,
  `addL2` varchar,
  `city` varchar,
  `stateProvReg` varchar,
  `pCode` varchar,
  `country` varchar,
  `lastEdited` datetime,
  `notes` varchar,
  PRIMARY KEY (`addressID`));

CREATE TABLE `organizations` (
  `organizationID` varchar,
  `datasetID` varchar,
  `addressID` varchar,
  `orgTypeID` varchar,
  `name` varchar,
  `descr` varchar,
  `lastEdited` datetime,
  `notes` varchar,
  PRIMARY KEY (`organizationID`));

CREATE TABLE `contacts` (
  `contactID` varchar,
  `datasetID` varchar,
  `organizationID` varchar,
  `firstName` varchar,
  `lastName` varchar,
  `email` varchar,
  `phone` varchar,
  `role` varchar,
  `lastEdited` datetime,
  `notes` varchar,
  PRIMARY KEY (`contactID`));

CREATE TABLE `sets` (
  `setID` varchar,
  `setType` varchar,
  `partID` varchar,
  `status` varchar,
  `firstReleased` datetime,
  `lastUpdated` datetime,
  `changes` varchar,
  `notes` varchar,
  PRIMARY KEY (`setID`)
);

CREATE TABLE `parts` (
  `partID` varchar,
  `partLabel` varchar,
  `partType` varchar,
  `shortName` varchar,
  `partDesc` varchar,
  `partInstr` varchar,
  `domainID` varchar,
  `specimenSet` varchar,
  `compSet` varchar,
  `groupID` varchar,
  `classID` varchar,
  `nomenclatureID` varchar,
  `ontologyRef` varchar,
  `latExp` varchar,
  `catSetID` varchar,
  `unitSetID` varchar,
  `aggScaleID` varchar,
  `aggSetID` varchar,
  `qualitySetID` varchar,
  `status` varchar,
  `firstReleased` datetime,
  `lastUpdated` datetime,
  `changes` varchar,
  `protocolSteps` varchar,
  `protocolStepsRequired` varchar,
  `protocolStepsOrder` int,
  `protocolOrg` varchar,
  `protocolOrgRequired` varchar,
  `protocolOrgOrder` int,
  `measures` varchar,
  `measuresRequired` varchar,
  `measuresOrder` int,
  `measureSets` varchar,
  `measureSetsRequired` varchar,
  `measureSetsOrder` int,
  `datasets` varchar,
  `datasetsRequired` varchar,
  `datasetsOrder` int,
  `sites` varchar,
  `sitesRequired` varchar,
  `sitesOrder` int,
  `samples` varchar,
  `samplesRequired` varchar,
  `samplesOrder` int,
  `addresses` varchar,
  `addressesRequired` varchar,
  `addressesOrder` int,
  `contacts` varchar,
  `contactsRequired` varchar,
  `contactsOrder` int,
  `organizations` varchar,
  `organizationsRequired` varchar,
  `organizationsOrder` int,
  `instruments` varchar,
  `instrumentsRequired` varchar,
  `instrumentsOrder` int,
  `polygons` varchar,
  `polygonsRequired` varchar,
  `polygonsOrder` int,
  `languages` varchar,
  `languagesOrder` int,
  `translations` varchar,
  `translationsOrder` int,
  `parts` varchar,
  `sets` varchar,
  `setsOrder` int,
  `qualityReports` varchar,
  `qualityReportsRequired` varchar,
  `qualityReportsOrder` int,
  `sampleRelationships` varchar,
  `sampleRelationshipsRequired` varchar,
  `sampleRelationshipsOrder` int,
  `protocols` varchar,
  `protocolsRequired` varchar,
  `protocolsOrder` int,
  `refLink` varchar,
  `dataType` varchar,
  `minValue` int,
  `maxValue` int,
  `minLength` int,
  `maxLength` int,
  PRIMARY KEY (`partID`));

CREATE TABLE `protocols` (
  `sourceProtocol` varchar,
  `protocolID` varchar,
  `datasetID` varchar,
  `name` varchar,
  `summ` varchar,
  `reflink` varchar,
  `organizationID` varchar,
  `contactID` varchar,
  `protocolVersion` varchar,
  `lastEdited` datetime,
  `notes` varchar,
  PRIMARY KEY (`protocolID`));

CREATE TABLE `samples` (
  `sampleID` varchar,
  `protocolID` varchar,
  `organizationID` varchar,
  `contactID` varchar,
  `siteID` varchar,
  `purposeID` varchar,
  `saMaterial` varchar,
  `datasetID` varchar,
  `origin` varchar,
  `repType` varchar,
  `collType` varchar,
  `collPer` float,
  `collNum` int,
  `pooled` bool,
  `collDT` datetime,
  `collDTStart` datetime,
  `collDTEnd` datetime,
  `sentDate` datetime,
  `recDate` datetime,
  `reportable` varchar,
  `lastEdited` datetime,
  `notes` varchar,
  PRIMARY KEY (`sampleID`));

CREATE TABLE `languages` (
  `langID` int,
  `langFam` varchar,
  `langName` varchar,
  `natName` varchar,
  `ISO6391` varchar,
  `ISO6392T` varchar,
  `ISO6392B` varchar,
  `ISO6393` varchar,
  `ISO6396` varchar,
  `firstRelased` datetime,
  `lastUpdated` datetime,
  `changes` varchar,
  `notes` varchar,
  PRIMARY KEY (`langID`)
);

CREATE TABLE `instruments` (
  `InstrumentID` varchar,
  `datasetID` varchar,
  `name` varchar,
  `model` varchar,
  `manufacturer` varchar,
  `contactID` varchar,
  `organizationID` varchar,
  `descr` varchar,
  `refLink` varchar,
  `instType` varchar,
  `insTypeOth` varchar,
  `index` int,
  `lastEdited` datetime,
  `notes` varchar,
  PRIMARY KEY (`InstrumentID`));

CREATE TABLE `protocolSteps` (
  `stepID` varchar,
  `methodID` varchar,
  `measureID` varchar,
  `summ` varchar,
  `sourceStep` varchar,
  `stepVer` varchar,
  `refLink` varchar,
  `organizationID` varchar,
  `contactID` varchar,
  `InstrumentID` varchar,
  `value` varchar,
  `unitID` varchar,
  `aggID` varchar,
  `lastEdited` datetime,
  `notes` varchar,
  PRIMARY KEY (`stepID`));

CREATE TABLE `protocolRelationships` (
  `protocolIDContainer` varchar,
  `protocolIDObj` varchar,
  `stepIDObj` varchar,
  `relationshipID` varchar,
  `protocolIDSub` varchar,
  `stepIDSub` varchar,
  `lastEdited` datetime,
  `notes` varchar);

CREATE TABLE `sampleRelationships` (
  `sampleIDSub` varchar,
  `relationshipID` varchar,
  `sampleIDObj` varchar,
  `lastEdited` datetime,
  `notes` varchar);

CREATE TABLE `polygons` (
  `polygonID` varchar,
  `datasetID` varchar,
  `name` varchar,
  `descr` varchar,
  `polyPop` int,
  `geoType` varchar,
  `geoEPSG` varchar,
  `geoWKT` varchar,
  `fileLocation` varchar,
  `refLink` varchar,
  `organizationID` varchar,
  `contactID` varchar,
  `lastEdited` datetime,
  `notes` varchar,
  PRIMARY KEY (`polygonID`));

CREATE TABLE `sites` (
  `parSiteID` varchar,
  `siteID` varchar,
  `datasetID` varchar,
  `polygonID` varchar,
  `siteTypeID` varchar,
  `samShed` varchar,
  `addressID` varchar,
  `organizationID` varchar,
  `contactID` varchar,
  `name` varchar,
  `descr` varchar,
  `pHDept` varchar,
  `healthReg` varchar,
  `popServ` int,
  `geoLat` varchar,
  `geoLong` varchar,
  `geoEPSG` varchar,
  `lastEdited` datetime,
  `notes` varchar,
  PRIMARY KEY (`siteID`));

CREATE TABLE `translations` (
  `partID` varchar,
  `langID` int,
  `partLabel` varchar,
  `partDesc` varchar,
  `partInstr` varchar,
  `firstReleased` datetime,
  `lastUpdated` datetime,
  `changes` varchar,
  `notes` varchar);

CREATE TABLE `measureSets` (
  `measureSetRepID` varchar,
  `protocolID` varchar,
  `name` varchar,
  `organizationID` varchar,
  `contactID` varchar,
  `lastEdited` datetime,
  `notes` varchar,
  PRIMARY KEY (`measureSetRepID`));

CREATE TABLE `measures` (
  `measureRepID` varchar,
  `protocolID` varchar,
  `sampleID` varchar,
  `purposeID` varchar,
  `polygonID` varchar,
  `siteID` varchar,
  `datasetID` varchar,
  `measureSetRepID` varchar,
  `aDateStart` datetime,
  `aDateEnd` datetime,
  `reportDate` datetime,
  `specimenID` varchar,
  `fractionID` varchar,
  `groupID` varchar,
  `classID` varchar,
  `measureID` varchar,
  `value` varchar,
  `unitID` varchar,
  `aggID` varchar,
  `nomenclatureID` varchar,
  `index` int,
  `measureLic` varchar,
  `organizationID` varchar,
  `contactID` varchar,
  `refLink` varchar,
  `lastEdited` datetime,
  `notes` varchar,
  PRIMARY KEY (`measureRepID`));

CREATE TABLE `qualityReports` (
  `qualityID` varchar,
  `measureRepID` varchar,
  `sampleID` varchar,
  `measureSetRepID` varchar,
  `qualityFlag` varchar,
  `severity` int,
  `lastEdited` datetime,
  `notes` varchar,
  PRIMARY KEY (`qualityID`));
;
ALTER TABLE `datasets` ADD 
  FOREIGN KEY (`datasetID`) REFERENCES `datasets`(`parDatasetID`)
;
ALTER TABLE `zones` ADD 
  FOREIGN KEY (`ISO2code`) REFERENCES `countries`(`ISO2code`)
;
ALTER TABLE `addresses` ADD 
  FOREIGN KEY (`datasetID`) REFERENCES `datasets`(`datasetID`),
  FOREIGN KEY (`country`) REFERENCES `countries`(`ISO2code`),
  FOREIGN KEY (`stateProvReg`) REFERENCES `zones`(`ISO2zone`)
;
ALTER TABLE `organizations` ADD 
  FOREIGN KEY (`datasetID`) REFERENCES `datasets`(`datasetID`),
  FOREIGN KEY (`addressID`) REFERENCES `addresses`(`addressID`)
;
ALTER TABLE `contacts` ADD 
  FOREIGN KEY (`datasetID`) REFERENCES `datasets`(`datasetID`),
  FOREIGN KEY (`organizationID`) REFERENCES `organizations`(`organizationID`)
;
ALTER TABLE `parts` ADD 
  FOREIGN KEY (`specimenSet`) REFERENCES `sets`(`setID`),
  FOREIGN KEY (`qualitySetID`) REFERENCES `sets`(`setID`),
  FOREIGN KEY (`aggSetID`) REFERENCES `sets`(`setID`),
  FOREIGN KEY (`unitSetID`) REFERENCES `sets`(`setID`),
  FOREIGN KEY (`compSet`) REFERENCES `sets`(`setID`)
;
ALTER TABLE `protocols` ADD 
  FOREIGN KEY (`contactID`) REFERENCES `contacts`(`contactID`),
  FOREIGN KEY (`datasetID`) REFERENCES `datasets`(`datasetID`),
  FOREIGN KEY (`protocolID`) REFERENCES `protocols`(`sourceProtocol`),
  FOREIGN KEY (`organizationID`) REFERENCES `organizations`(`organizationID`)
;
ALTER TABLE `samples` ADD 
  FOREIGN KEY (`contactID`) REFERENCES `contacts`(`contactID`),
  FOREIGN KEY (`organizationID`) REFERENCES `organizations`(`organizationID`),
  FOREIGN KEY (`purposeID`) REFERENCES `parts`(`partID`),
  FOREIGN KEY (`protocolID`) REFERENCES `parts`(`partID`),
  FOREIGN KEY (`protocolID`) REFERENCES `protocols`(`protocolID`),
  FOREIGN KEY (`saMaterial`) REFERENCES `parts`(`partID`),
  FOREIGN KEY (`repType`) REFERENCES `parts`(`partID`),
  FOREIGN KEY (`collType`) REFERENCES `parts`(`partID`),
  FOREIGN KEY (`datasetID`) REFERENCES `datasets`(`datasetID`)
;
ALTER TABLE `instruments` ADD 
  FOREIGN KEY (`organizationID`) REFERENCES `organizations`(`organizationID`),
  FOREIGN KEY (`instType`) REFERENCES `parts`(`partID`),
  FOREIGN KEY (`datasetID`) REFERENCES `datasets`(`datasetID`),
  FOREIGN KEY (`contactID`) REFERENCES `contacts`(`contactID`)
;
ALTER TABLE `protocolSteps` ADD 
  FOREIGN KEY (`InstrumentID`) REFERENCES `instruments`(`InstrumentID`),
  FOREIGN KEY (`contactID`) REFERENCES `contacts`(`contactID`),
  FOREIGN KEY (`sourceStep`) REFERENCES `protocolSteps`(`stepID`),
  FOREIGN KEY (`organizationID`) REFERENCES `organizations`(`organizationID`),
  FOREIGN KEY (`aggID`) REFERENCES `parts`(`partID`),
  FOREIGN KEY (`unitID`) REFERENCES `parts`(`partID`)
;
ALTER TABLE `protocolRelationships` ADD 
  FOREIGN KEY (`protocolIDObj`) REFERENCES `protocols`(`protocolID`),
  FOREIGN KEY (`protocolIDContainer`) REFERENCES `protocols`(`protocolID`),
  FOREIGN KEY (`protocolIDSub`) REFERENCES `protocols`(`protocolID`),
  FOREIGN KEY (`stepIDObj`) REFERENCES `protocolSteps`(`stepID`),
  FOREIGN KEY (`stepIDSub`) REFERENCES `protocolSteps`(`stepID`)
;
ALTER TABLE `sampleRelationships` ADD 
  FOREIGN KEY (`sampleIDObj`) REFERENCES `samples`(`sampleID`),
  FOREIGN KEY (`sampleIDSub`) REFERENCES `samples`(`sampleID`),
  FOREIGN KEY (`relationshipID`) REFERENCES `parts`(`partID`)
;
ALTER TABLE `polygons` ADD 
  FOREIGN KEY (`contactID`) REFERENCES `contacts`(`contactID`),
  FOREIGN KEY (`datasetID`) REFERENCES `datasets`(`datasetID`),
  FOREIGN KEY (`organizationID`) REFERENCES `organizations`(`organizationID`)
;
ALTER TABLE `sites` ADD 
  FOREIGN KEY (`polygonID`) REFERENCES `polygons`(`polygonID`),
  FOREIGN KEY (`organizationID`) REFERENCES `organizations`(`organizationID`),
  FOREIGN KEY (`siteID`) REFERENCES `sites`(`parSiteID`),
  FOREIGN KEY (`datasetID`) REFERENCES `datasets`(`datasetID`),
  FOREIGN KEY (`siteTypeID`) REFERENCES `parts`(`partID`)
;
ALTER TABLE `translations` ADD 
  FOREIGN KEY (`partID`) REFERENCES `parts`(`partID`),
  FOREIGN KEY (`langID`) REFERENCES `languages`(`langID`)
;
ALTER TABLE `measureSets` ADD 
  FOREIGN KEY (`protocolID`) REFERENCES `protocols`(`protocolID`),
  FOREIGN KEY (`contactID`) REFERENCES `contacts`(`contactID`),
  FOREIGN KEY (`organizationID`) REFERENCES `organizations`(`organizationID`)
;
ALTER TABLE `measures` ADD 
  FOREIGN KEY (`datasetID`) REFERENCES `datasets`(`datasetID`),
  FOREIGN KEY (`contactID`) REFERENCES `contacts`(`contactID`),
  FOREIGN KEY (`siteID`) REFERENCES `sites`(`siteID`),
  FOREIGN KEY (`sampleID`) REFERENCES `samples`(`sampleID`),
  FOREIGN KEY (`organizationID`) REFERENCES `organizations`(`organizationID`),
  FOREIGN KEY (`fractionID`) REFERENCES `parts`(`partID`),
  FOREIGN KEY (`polygonID`) REFERENCES `polygons`(`polygonID`),
  FOREIGN KEY (`unitID`) REFERENCES `parts`(`partID`),
  FOREIGN KEY (`groupID`) REFERENCES `parts`(`partID`),
  FOREIGN KEY (`measureID`) REFERENCES `parts`(`partID`),
  FOREIGN KEY (`classID`) REFERENCES `parts`(`partID`),
  FOREIGN KEY (`measureLic`) REFERENCES `parts`(`partID`),
  FOREIGN KEY (`purposeID`) REFERENCES `parts`(`partID`),
  FOREIGN KEY (`measureSetRepID`) REFERENCES `measureSets`(`measureSetRepID`),
  FOREIGN KEY (`specimenID`) REFERENCES `parts`(`partID`),
  FOREIGN KEY (`nomenclatureID`) REFERENCES `parts`(`partID`),
  FOREIGN KEY (`protocolID`) REFERENCES `protocols`(`protocolID`),
  FOREIGN KEY (`aggID`) REFERENCES `parts`(`partID`)
;
ALTER TABLE `qualityReports` ADD 
  FOREIGN KEY (`measureSetRepID`) REFERENCES `measureSets`(`measureSetRepID`),
  FOREIGN KEY (`sampleID`) REFERENCES `samples`(`sampleID`),
  FOREIGN KEY (`qualityID`) REFERENCES `parts`(`partID`),
  FOREIGN KEY (`measureRepID`) REFERENCES `measures`(`measureRepID`)
;