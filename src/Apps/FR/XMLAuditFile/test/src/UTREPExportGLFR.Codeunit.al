// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AuditFileExport;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Foundation.Company;
using Microsoft.Utilities;
using System.Security.AccessControl;
using System.TestLibraries.Utilities;

codeunit 148007 "UT REP Export G/L FR"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;
    RequiredTestIsolation = Codeunit;

    var
        Assert: Codeunit Assert;
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        IsInitialized: Boolean;
        NoEntriesToExportErr: Label 'There are no entries to export within the defined filter. The file was not created.';
        GenerateAuditFileImmediatelyQst: Label 'Since you did not schedule the audit file generation, it will be generated immediately which can take a while. Do you want to continue?';

    [Test]
    procedure MissingStartingDateErrTest()
    var
        AuditFileExportHeader: Record "Audit File Export Header";
        EndingDate: Date;
    begin
        Initialize();
        EndingDate := GetStartingDate();
        asserterror RunXMLExport('', 0D, EndingDate);
        Assert.ExpectedTestFieldError(AuditFileExportHeader.FieldCaption("Starting Date"), '');
    end;

    [Test]
    procedure MissingEndingDateErrTest()
    var
        AuditFileExportHeader: Record "Audit File Export Header";
        StartingDate: Date;
    begin
        Initialize();
        StartingDate := GetStartingDate();
        asserterror RunXMLExport('', StartingDate, 0D);
        Assert.ExpectedTestFieldError(AuditFileExportHeader.FieldCaption("Ending Date"), '');
    end;


    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure NoEntriesToExportError()
    var
        AuditFile: Record "Audit File";
        AuditFileExportHeaderID: Integer;
        StartingDate: Date;
    begin
        Initialize();
        StartingDate := GetStartingDate();
        LibraryVariableStorage.Enqueue(GenerateAuditFileImmediatelyQst);
        AuditFileExportHeaderID := RunXMLExport('', StartingDate, StartingDate);
        VerifyError(AuditFileExportHeaderID, NoEntriesToExportErr);
        AuditFile.SetRange("Export ID", AuditFileExportHeaderID);
        Assert.RecordIsEmpty(AuditFile);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure ExportEntriesWithinDateFilter()
    var
        GLEntry: Record "G/L Entry";
        AuditFile: Record "Audit File";
        AuditFileExportHeaderID: Integer;
        StartingDate: Date;
        ExpectedDocumentNo: Code[20];
        FileInStream: InStream;
        ExportDocument: XmlDocument;
        EntryNodes: XmlNodeList;
        DocumentNoNode: XmlNode;
    begin
        Initialize();
        StartingDate := GetStartingDate();
        InsertGLEntry(GLEntry, StartingDate);
        ExpectedDocumentNo := GLEntry."Document No.";
        InsertGLEntry(GLEntry, CalcDate('<-1D>', StartingDate));

        LibraryVariableStorage.Enqueue(GenerateAuditFileImmediatelyQst);
        AuditFileExportHeaderID := RunXMLExport('', StartingDate, StartingDate);

        AuditFile.SetRange("Export ID", AuditFileExportHeaderID);
        Assert.RecordCount(AuditFile, 1);
        AuditFile.FindFirst();
        AuditFile.CalcFields("File Content");
        AuditFile."File Content".CreateInStream(FileInStream);
        XmlDocument.ReadFrom(FileInStream, ExportDocument);
        ExportDocument.SelectNodes('/FichierAudit/EcritureComptable', EntryNodes);
        Assert.AreEqual(1, EntryNodes.Count(), 'Only entries within the posting date filter should be exported.');
        Assert.IsTrue(
            ExportDocument.SelectSingleNode('/FichierAudit/EcritureComptable/NoDocument', DocumentNoNode),
            'The exported entry must contain a document number.');
        Assert.AreEqual(ExpectedDocumentNo, DocumentNoNode.AsXmlElement().InnerText(), 'The wrong G/L entry was exported.');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure NoEntriesWithinDateFilterError()
    var
        GLEntry: Record "G/L Entry";
        AuditFile: Record "Audit File";
        AuditFileExportHeaderID: Integer;
        StartingDate: Date;
    begin
        Initialize();
        StartingDate := GetStartingDate();
        InsertGLEntry(GLEntry, CalcDate('<-1D>', StartingDate));

        LibraryVariableStorage.Enqueue(GenerateAuditFileImmediatelyQst);
        AuditFileExportHeaderID := RunXMLExport('', StartingDate, StartingDate);

        VerifyError(AuditFileExportHeaderID, NoEntriesToExportErr);
        AuditFile.SetRange("Export ID", AuditFileExportHeaderID);
        Assert.RecordIsEmpty(AuditFile);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure ExportFileNameIsIndependentOfLanguage()
    var
        AuditFileExportLine: Record "Audit File Export Line";
        DataHandlingXML: Codeunit "Data Handling XML";
        OriginalLanguage: Integer;
        FrenchFileName: Text;
        EnglishFileName: Text;
    begin
        AuditFileExportLine."Ending Date" := DMY2Date(9, 4, 2026);
        OriginalLanguage := GlobalLanguage();

        GlobalLanguage(1036);
        FrenchFileName := DataHandlingXML.GetFileNameForAuditFileExportLine(AuditFileExportLine);
        GlobalLanguage(1033);
        EnglishFileName := DataHandlingXML.GetFileNameForAuditFileExportLine(AuditFileExportLine);
        GlobalLanguage(OriginalLanguage);

        Assert.AreEqual('GLEntries_20260409.xml', FrenchFileName, 'The filename must use a file-safe invariant date.');
        Assert.AreEqual(FrenchFileName, EnglishFileName, 'The filename must not depend on the session language.');
    end;

    [Test]
    procedure MissingXMLFormatSetupShowsRecoveryError()
    var
        AuditFileExportHeader: Record "Audit File Export Header";
        AuditFileExportFormatSetup: Record "Audit File Export Format Setup";
    begin
        Initialize();
        AuditFileExportFormatSetup.Get("Audit File Export Format"::"GL Entries XML FR");
        AuditFileExportFormatSetup.Delete(true);

        asserterror AuditFileExportHeader.Validate("Audit File Export Format", "Audit File Export Format"::"GL Entries XML FR");

        Assert.ExpectedError('XML export format setup not found. Add the XML format in Audit File Export Format Setup, and then try again.');
        AuditFileExportFormatSetup.InitSetup("Audit File Export Format"::"GL Entries XML FR", '', false);
    end;

    [Test]
    procedure XMLVisibilityProviderHidesUnsupportedControls()
    var
        PageVisibilityXML: Codeunit "Page Visibility XML";
        FieldVisibility: Dictionary of [Text, Boolean];
        ActionVisibility: Dictionary of [Text, Boolean];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] The XML visibility provider hides unsupported fields and actions.
        Initialize();

        // [GIVEN] Audit document fields and actions are visible
        FieldVisibility.Add('Contact', true);
        FieldVisibility.Add('SplitByMonth', true);
        ActionVisibility.Add('DataCheck', true);

        // [WHEN] XML visibility is applied
        PageVisibilityXML.GetUIVisibility(FieldVisibility, ActionVisibility);

        // [THEN] XML-specific unsupported controls are hidden
        Assert.IsFalse(FieldVisibility.Get('Contact'), 'XML must hide contact.');
        Assert.IsFalse(FieldVisibility.Get('SplitByMonth'), 'XML must hide monthly splitting.');
        Assert.IsFalse(ActionVisibility.Get('DataCheck'), 'XML must hide data check.');
    end;

    [Test]
    procedure XMLExportPermissionsRequireDedicatedRole()
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
        ExpandedPermission: Record "Expanded Permission";
        StandardRoleXMLExportAccessErr: Label 'The standard role %1 must not grant XML export access.', Comment = '%1 - Permission set role ID';
        StandardRoleXMLGenerationAccessErr: Label 'The standard role %1 must not grant XML generation access.', Comment = '%1 - Permission set role ID';
    begin
        AggregatePermissionSet.SetRange("Role ID", 'XML Audit - Export');
        AggregatePermissionSet.FindFirst();
        ExpandedPermission.Get(AggregatePermissionSet."App ID", AggregatePermissionSet."Role ID", ExpandedPermission."Object Type"::XMLport, XmlPort::"Export G/L Entries FR");
        ExpandedPermission.TestField("Execute Permission", ExpandedPermission."Execute Permission"::Yes);
        ExpandedPermission.Get(AggregatePermissionSet."App ID", AggregatePermissionSet."Role ID", ExpandedPermission."Object Type"::Codeunit, Codeunit::"Generate File XML");
        ExpandedPermission.TestField("Execute Permission", ExpandedPermission."Execute Permission"::Yes);
        ExpandedPermission.Get(AggregatePermissionSet."App ID", AggregatePermissionSet."Role ID", ExpandedPermission."Object Type"::"Table Data", Database::"G/L Entry");
        ExpandedPermission.TestField("Read Permission", ExpandedPermission."Read Permission"::Indirect);

        AggregatePermissionSet.SetFilter("Role ID", '%1|%2|%3|%4|%5|%6',
            'D365 BASIC ISV', 'D365 BASIC', 'D365 READ', 'D365 TEAM MEMBER', 'INTELLIGENT CLOUD', 'LOCAL');
        AggregatePermissionSet.FindSet();
        repeat
            Assert.IsFalse(
                ExpandedPermission.Get(AggregatePermissionSet."App ID", AggregatePermissionSet."Role ID", ExpandedPermission."Object Type"::XMLport, XmlPort::"Export G/L Entries FR"),
                StrSubstNo(StandardRoleXMLExportAccessErr, AggregatePermissionSet."Role ID"));
            Assert.IsFalse(
                ExpandedPermission.Get(AggregatePermissionSet."App ID", AggregatePermissionSet."Role ID", ExpandedPermission."Object Type"::Codeunit, Codeunit::"Generate File XML"),
                StrSubstNo(StandardRoleXMLGenerationAccessErr, AggregatePermissionSet."Role ID"));
        until AggregatePermissionSet.Next() = 0;
    end;

    local procedure InsertGLEntry(var GLEntry: Record "G/L Entry"; PostingDate: Date)
    var
        EntryNo: Integer;
    begin
        GLEntry.Reset();
        GLEntry.LockTable();
        if GLEntry.FindLast() then
            EntryNo := GLEntry."Entry No.";
        GLEntry.Init();
        GLEntry."Entry No." := EntryNo + 1;
        GLEntry."Posting Date" := PostingDate;
        GLEntry."Document No." := Format(GLEntry."Entry No.");
        GLEntry.Insert();
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();

        if IsInitialized then
            exit;

        SetupXML();
        LibrarySetupStorage.Save(Database::"Company Information");
        LibrarySetupStorage.Save(Database::"Audit File Export Setup");
        Commit();

        IsInitialized := true;
    end;

    procedure SetupXML()
    var
        AuditFileExportSetup: Record "Audit File Export Setup";
        AuditFileExportFormatSetup: Record "Audit File Export Format Setup";
    begin
        AuditFileExportSetup.InitSetup("Audit File Export Format"::"GL Entries XML FR");
        AuditFileExportFormatSetup.InitSetup("Audit File Export Format"::"GL Entries XML FR", '', false);
    end;

    local procedure GetStartingDate(): Date
    var
        GLEntry: Record "G/L Entry";
        StartingDate: Date;
    begin
        StartingDate := WorkDate();
        repeat
            StartingDate := CalcDate('<+1D>', StartingDate);
            GLEntry.SetRange("Posting Date", StartingDate);
        until not GLEntry.FindFirst();
        exit(StartingDate);
    end;

    procedure CreateAuditFileExportDoc(var AuditFileExportHeader: Record "Audit File Export Header"; StartingDate: Date; EndingDate: Date)
    begin
        AuditFileExportHeader.Init();
        AuditFileExportHeader.Validate("Audit File Export Format", "Audit File Export Format"::"GL Entries XML FR");
        AuditFileExportHeader.Validate("Starting Date", StartingDate);
        AuditFileExportHeader.Validate("Ending Date", EndingDate);
        AuditFileExportHeader.Insert(true);
        AuditFileExportHeader.Validate("Parallel Processing", false);
        AuditFileExportHeader.Modify(true);
    end;

    local procedure RunXMLExport(GLAccountNoFilter: Text; StartDate: Date; EndDate: Date) AuditFileExportHeaderID: Integer
    var
        AuditFileExportHeader: Record "Audit File Export Header";
        GLAccount: Record "G/L Account";
        AuditFileExportMgt: Codeunit "Audit File Export Mgt.";
    begin
        GLAccount.SetFilter("No.", GLAccountNoFilter);
        CreateAuditFileExportDoc(
            AuditFileExportHeader, StartDate, EndDate);
        AuditFileExportMgt.StartExport(AuditFileExportHeader);
        AuditFileExportHeaderID := AuditFileExportHeader.ID;
    end;

    local procedure VerifyError(AuditFileExportHeaderID: Integer; ExpectedError: Text)
    var
        AuditFileExportLine: Record "Audit File Export Line";
        ActivityLog: Record "Activity Log";
        ErrorTextInStream: InStream;
        ErrorText: Text;
    begin
        AuditFileExportLine.SetRange(ID, AuditFileExportHeaderID);
        AuditFileExportLine.FindFirst();
        ActivityLog.SetRange("Record ID", AuditFileExportLine.RecordId());
        ActivityLog.FindLast();
        ActivityLog.CalcFields("Detailed Info");
        ActivityLog."Detailed Info".CreateInStream(ErrorTextInStream);
        ErrorTextInStream.ReadText(ErrorText);
        Assert.AreEqual(ExpectedError, ErrorText, '');
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), Question, '');
        Reply := true;
    end;
}