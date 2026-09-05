// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AuditFileExport;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Foundation.Company;
using Microsoft.Utilities;
using System.TestLibraries.Utilities;

codeunit 148006 "UT REP Export G/L FR"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

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
        AuditFileExportHeaderID: Integer;
        StartingDate: Date;
    begin
        Initialize();
        StartingDate := GetStartingDate();
        LibraryVariableStorage.Enqueue(GenerateAuditFileImmediatelyQst);
        AuditFileExportHeaderID := RunXMLExport('', StartingDate, StartingDate);
        VerifyError(AuditFileExportHeaderID, NoEntriesToExportErr);
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();

        if IsInitialized then
            exit;

        SetupXML();
        LibrarySetupStorage.Save(Database::"Company Information");
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
        AuditFileExportHeader.Validate("Parallel Processing", false);
        AuditFileExportHeader.Insert(true);
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