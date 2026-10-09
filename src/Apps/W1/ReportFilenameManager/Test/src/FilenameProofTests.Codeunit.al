// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 50165 "Filename Proof Tests"
{
    // The proofs as tests, one per thing being proven, so a regression fails a run instead of
    // writing a line into a log that nobody has to read.
    //
    // Each test notes where the log has got to, runs one proof, and then insists that every
    // verdict that proof wrote is a pass. The verdicts stay in the log as evidence - what
    // changes is that they are now a gate.

    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure RouteIndependence()
    var
        ReportFilenameProof: Codeunit "Report Filename Proof";
    begin
        Prepare();
        ReportFilenameProof.ProveRouteIndependence();
        AssertPassed();
    end;

    [Test]
    procedure MistypedPlaceholderIsRefusedAtSave()
    var
        ReportFilenameProof: Codeunit "Report Filename Proof";
    begin
        Prepare();
        ReportFilenameProof.ProveBadPlaceholderIsRefusedAtSave();
        AssertPassed();
    end;

    [Test]
    procedure BindingResolvesByFieldNumber()
    var
        ReportFilenameProof: Codeunit "Report Filename Proof";
    begin
        Prepare();
        ReportFilenameProof.ProveBindingResolvesByFieldNumber();
        AssertPassed();
    end;

    [Test]
    procedure RoutesAgreeUnderALanguageSwitch()
    var
        ReportFilenameProof: Codeunit "Report Filename Proof";
    begin
        Prepare();
        ReportFilenameProof.ProveLanguageInvariance();
        AssertPassed();
    end;

    [Test]
    procedure ATranslatedCaptionBindsAcrossLanguages()
    var
        ReportFilenameProof: Codeunit "Report Filename Proof";
    begin
        Prepare();
        ReportFilenameProof.ProveTranslatedCaptionBinding();
        AssertPassed();
    end;

    [Test]
    procedure TheReportCaptionFollowsTheDocument()
    var
        ReportFilenameProof: Codeunit "Report Filename Proof";
    begin
        Prepare();
        ReportFilenameProof.ProveReportCaptionFollowsDocument();
        AssertPassed();
    end;

    [Test]
    procedure HopAmountFormatAndComputedTotal()
    var
        ReportFilenameProof: Codeunit "Report Filename Proof";
    begin
        Prepare();
        ReportFilenameProof.ProveComplexPlaceholders();
        AssertPassed();
    end;

    [Test]
    procedure TheSourceTableFilterSelectsPatterns()
    var
        FilenameProofReminders: Codeunit "Filename Proof Reminders";
    begin
        Prepare();
        FilenameProofReminders.ProveSourceTableFilter();
        AssertPassed();
    end;

    [Test]
    procedure TheScheduledRouteNamesItsOutput()
    var
        FilenameProofScheduled: Codeunit "Filename Proof Scheduled";
    begin
        Prepare();
        FilenameProofScheduled.ProveScheduledRoute();
        AssertPassed();
    end;

    [Test]
    procedure AttachAsPdfNamesItsAttachment()
    var
        FilenameProofAttachment: Codeunit "Filename Proof Attachment";
    begin
        Prepare();
        FilenameProofAttachment.ProveAttachmentRoute();
        AssertPassed();
    end;

    [Test]
    procedure ASavePatternDoesNotNameTheAttachment()
    var
        FilenameProofAttachment: Codeunit "Filename Proof Attachment";
    begin
        Prepare();
        FilenameProofAttachment.ProveSaveDoesNotNameTheAttachment();
        AssertPassed();
    end;

    [Test]
    procedure SendToDiskNamesACustomerDocument()
    var
        FilenameProofSaveToDisk: Codeunit "Filename Proof Save To Disk";
    begin
        Prepare();
        FilenameProofSaveToDisk.ProveCustomerDocument();
        AssertPassed();
    end;

    [Test]
    procedure SendToDiskNamesAVendorDocument()
    var
        FilenameProofSaveToDisk: Codeunit "Filename Proof Save To Disk";
    begin
        Prepare();
        FilenameProofSaveToDisk.ProveVendorDocument();
        AssertPassed();
    end;

    [Test]
    procedure TheZippedPdfIsNamedForACustomer()
    var
        FilenameProofZipEntry: Codeunit "Filename Proof Zip Entry";
    begin
        Prepare();
        FilenameProofZipEntry.ProveCustomerZip();
        AssertPassed();
    end;

    [Test]
    procedure TheZippedPdfIsNamedForAVendor()
    var
        FilenameProofZipEntry: Codeunit "Filename Proof Zip Entry";
    begin
        Prepare();
        FilenameProofZipEntry.ProveVendorZip();
        AssertPassed();
    end;

    [Test]
    procedure TheElectronicDocumentIsNamedOnDisk()
    var
        FilenameProofElecDoc: Codeunit "Filename Proof Elec. Doc.";
    begin
        Prepare();
        FilenameProofElecDoc.ProveDiskElectronicDocument();
        AssertPassed();
    end;

    [Test]
    procedure ANameAnotherAppGivesTheElectronicDocumentStands()
    var
        FilenameProofElecDoc: Codeunit "Filename Proof Elec. Doc.";
    begin
        Prepare();
        FilenameProofElecDoc.ProveAnotherAppsNameStands();
        AssertPassed();
    end;

    [Test]
    procedure TheZipOfAPdfAndAnElectronicDocumentIsNamed()
    var
        FilenameProofElecDoc: Codeunit "Filename Proof Elec. Doc.";
    begin
        Prepare();
        FilenameProofElecDoc.ProveZipOfBoth();
        AssertPassed();
    end;

    [Test]
    procedure TwoElectronicDocumentsInOneZipAreNamed()
    var
        FilenameProofElecDoc: Codeunit "Filename Proof Elec. Doc.";
    begin
        Prepare();
        FilenameProofElecDoc.ProveTwoDocumentsInOneZip();
        AssertPassed();
    end;

    [Test]
    procedure TheElectronicDocumentServiceKeepsBusinessCentralsName()
    var
        FilenameProofElecDoc: Codeunit "Filename Proof Elec. Doc.";
    begin
        Prepare();
        FilenameProofElecDoc.ProveServiceDeliveryIsNotRenamed();
        AssertPassed();
    end;

    [Test]
    procedure AZipEntryLeftBehindCannotNameAnotherDocument()
    var
        FilenameProofZipEntry: Codeunit "Filename Proof Zip Entry";
    begin
        Prepare();
        FilenameProofZipEntry.ProveAStaleEntryCannotNameAnotherDocument();
        AssertPassed();
    end;

    [Test]
    procedure SendToDiskNamesASelectionAfterAllOfIt()
    var
        FilenameProofSaveToDisk: Codeunit "Filename Proof Save To Disk";
    begin
        Prepare();
        FilenameProofSaveToDisk.ProveASelectionOfSeveralInvoices();
        AssertPassed();
    end;

    [Test]
    procedure AZippedSelectionIsNamedAfterAllOfIt()
    var
        FilenameProofZipEntry: Codeunit "Filename Proof Zip Entry";
    begin
        Prepare();
        FilenameProofZipEntry.ProveASelectionInOneZip();
        AssertPassed();
    end;

    [Test]
    procedure TheMaximalPatternIsIdenticalOnEveryRoute()
    var
        FilenameProofMaximal: Codeunit "Filename Proof Maximal";
    begin
        Prepare();
        FilenameProofMaximal.ProveMaximalCase();
        AssertPassed();
    end;

    [Test]
    procedure AMixedBatchIsLeftUnnamed()
    var
        FilenameProofMaximal: Codeunit "Filename Proof Maximal";
    begin
        Prepare();
        FilenameProofMaximal.ProveMixedBatchDeclines();
        AssertPassed();
    end;

    [Test]
    procedure ValuesCollapseAndNamesAreTruncated()
    var
        FilenameProofMaximal: Codeunit "Filename Proof Maximal";
    begin
        Prepare();
        FilenameProofMaximal.ProveValueCollapseAndTruncation();
        AssertPassed();
    end;

    [Test]
    procedure ThePickerStaysUsable()
    var
        FilenameProofPicker: Codeunit "Filename Proof Picker";
    begin
        Prepare();
        FilenameProofPicker.ProvePickerIsUsable();
        AssertPassed();
    end;

    [Test]
    procedure ARunKeepsItsWholeSelection()
    var
        FilenameProofRun: Codeunit "Filename Proof Run";
    begin
        Prepare();
        FilenameProofRun.ProveARunKeepsItsWholeSelection();
        AssertPassed();
    end;

    [Test]
    procedure AnUnfilteredRunIsStillNamed()
    var
        FilenameProofRun: Codeunit "Filename Proof Run";
    begin
        Prepare();
        FilenameProofRun.ProveAnUnfilteredRunIsStillNamed();
        AssertPassed();
    end;

    [Test]
    procedure AConditionMustHoldForTheWholeRun()
    var
        FilenameProofRun: Codeunit "Filename Proof Run";
    begin
        Prepare();
        FilenameProofRun.ProveAConditionMustHoldForTheWholeRun();
        AssertPassed();
    end;

    [Test]
    procedure ARunWithTwoLanguagesPicksOne()
    var
        FilenameProofRun: Codeunit "Filename Proof Run";
    begin
        Prepare();
        FilenameProofRun.ProveARunWithTwoLanguagesPicksOne();
        AssertPassed();
    end;

    [Test]
    procedure AFilterCanBeTested()
    var
        FilenameProofRun: Codeunit "Filename Proof Run";
    begin
        Prepare();
        FilenameProofRun.ProveAFilterCanBeTested();
        AssertPassed();
    end;

    [Test]
    procedure TheExampleDoesNotImplyOneRecord()
    var
        FilenameProofRun: Codeunit "Filename Proof Run";
    begin
        Prepare();
        FilenameProofRun.ProveTheExampleDoesNotImplyOneRecord();
        AssertPassed();
    end;

    [Test]
    procedure EveryReportFitsTheModel()
    var
        FilenameProofRun: Codeunit "Filename Proof Run";
    begin
        Prepare();
        FilenameProofRun.ProveEveryReportFitsTheModel();
        AssertPassed();
    end;

    [Test]
    procedure TheNamingHookNamesTheFile()
    var
        FilenameProofRun: Codeunit "Filename Proof Run";
    begin
        Prepare();
        FilenameProofRun.ProveTheNamingHookNamesTheFile();
        AssertPassed();
    end;

    [Test]
    procedure TheSwitchTurnsNamingOffAndOn()
    var
        FilenameProofRun: Codeunit "Filename Proof Run";
    begin
        Prepare();
        FilenameProofRun.ProveTheSwitchTurnsNamingOff();
        AssertPassed();
    end;

    [Test]
    procedure ANameSomebodyElseSetSurvivesTheChain()
    var
        FilenameProofRun: Codeunit "Filename Proof Run";
    begin
        Prepare();
        FilenameProofRun.ProveTheHookLeavesAnAlreadyNamedFileAlone();
        AssertPassed();
    end;

    [Test]
    procedure AnotherSubscribersNameIsNotOverridden()
    var
        FilenameProofRun: Codeunit "Filename Proof Run";
    begin
        Prepare();
        FilenameProofRun.ProveOurGuardStandsDownForAnotherSubscriber();
        AssertPassed();
    end;

    [Test]
    procedure ARepeatedNameInOneBatchIsNumbered()
    var
        FilenameBatchMeasure: Codeunit "Filename Batch Measure";
    begin
        Prepare();
        FilenameBatchMeasure.ProveRepeatedNamesAreNumbered();
        AssertPassed();
    end;

    [Test]
    procedure AReminderBaseApplicationNamesKeepsItsName()
    var
        FilenameProofRun: Codeunit "Filename Proof Run";
    begin
        Prepare();
        FilenameProofRun.ProveAReminderBaseApplicationNamesKeepsItsName();
        AssertPassed();
    end;

    [Test]
    procedure OneSelectionGetsOneName()
    var
        FilenameProofRun: Codeunit "Filename Proof Run";
    begin
        Prepare();
        FilenameProofRun.ProveOneSelectionGetsOneName();
        AssertPassed();
    end;

    [Test]
    procedure TheExampleShowsBothShapesOfARun()
    var
        FilenameProofRun: Codeunit "Filename Proof Run";
    begin
        Prepare();
        FilenameProofRun.ProveTheExampleShowsBothShapesOfARun();
        AssertPassed();
    end;

    [Test]
    procedure ARunOverSeveralRelatedRecordsIsNamed()
    var
        FilenameProofRun: Codeunit "Filename Proof Run";
    begin
        Prepare();
        FilenameProofRun.ProveARunOverSeveralRelatedRecordsIsNamed();
        AssertPassed();
    end;

    [Test]
    procedure AHiddenSubjectIsFound()
    var
        FilenameProofRun: Codeunit "Filename Proof Run";
    begin
        Prepare();
        FilenameProofRun.ProveAHiddenSubjectIsFound();
        AssertPassed();
    end;

    [Test]
    procedure AFinancialReportIsNamedAfterItself()
    var
        FilenameProofRun: Codeunit "Filename Proof Run";
    begin
        Prepare();
        FilenameProofRun.ProveAFinancialReportIsNamedAfterItself();
        AssertPassed();
    end;

    [Test]
    procedure AnUnidentifiedFinancialReportRunIsNotNamed()
    var
        FilenameProofRun: Codeunit "Filename Proof Run";
    begin
        Prepare();
        FilenameProofRun.ProveAnUnidentifiedFinancialReportRunIsNotNamed();
        AssertPassed();
    end;

    [Test]
    procedure AScheduledFinancialReportIsNamed()
    var
        FilenameProofRun: Codeunit "Filename Proof Run";
    begin
        Prepare();
        FilenameProofRun.ProveAScheduledFinancialReportIsNamed();
        AssertPassed();
    end;

    [Test]
    procedure TheKindOfDocumentIsNamedInItsOwnLanguage()
    var
        FilenameProofRun: Codeunit "Filename Proof Run";
    begin
        Prepare();
        FilenameProofRun.ProveTheKindOfDocumentIsNamedInItsOwnLanguage();
        AssertPassed();
    end;

    [Test]
    procedure TheKindOfDocumentDeclinesOnALanguageMismatch()
    var
        FilenameProofRun: Codeunit "Filename Proof Run";
    begin
        Prepare();
        FilenameProofRun.ProveTheKindOfDocumentDeclinesOnALanguageMismatch();
        AssertPassed();
    end;

    [Test]
    procedure APatternWithNoReportStillShowsAnExample()
    var
        FilenameProofRun: Codeunit "Filename Proof Run";
    begin
        Prepare();
        FilenameProofRun.ProveAPatternWithNoReportStillShowsAnExample();
        AssertPassed();
    end;

    /// <summary>
    /// Refuses to run anywhere the proofs could destroy a real configuration, notes where the
    /// log has got to, and pins the session language so that a pattern authored with an English
    /// caption is authored in English whoever runs the test.
    /// </summary>
    local procedure Prepare()
    var
        FilenameProofGuard: Codeunit "Filename Proof Guard";
        FilenameProofGate: Codeunit "Filename Proof Gate";
        FilenameProofSupport: Codeunit "Filename Proof Support";
    begin
        FilenameProofGuard.AssertSafeEnvironment();
        BaselineEntryNo := FilenameProofGate.Baseline();
        GlobalLanguage(FilenameProofSupport.EnglishLanguageId());
    end;

    local procedure AssertPassed()
    var
        FilenameProofGate: Codeunit "Filename Proof Gate";
    begin
        FilenameProofGate.AssertAllVerdictsPassed(BaselineEntryNo);
    end;

    var
        BaselineEntryNo: Integer;
}
