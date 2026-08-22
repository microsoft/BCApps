// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AuditFileExport;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using System.Telemetry;
using System.Utilities;

codeunit 10811 "Generate File XML"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        StartingDate: Date;
        EndingDate: Date;
        ProgressDialog: Dialog;
        FRGeneralLedgerXMLTok: Label 'FR Export General Ledger Entries to XML File', Locked = true;
        FRGLXMLFrameworkTok: Label 'FR General Ledger Entries XML generated via Audit File Export Framework';
        NoEntriesToExportErr: Label 'There are no entries to export within the defined filter. The file was not created.';
        CreateFileTxt: label 'Creating FEC audit file\';
        ProcessTransactionsTxt: label 'Processing transactions: #1###', Comment = '#1 - percent of processed G/L Entries';

    procedure GenerateXMLFile(AuditFileExportLine: Record "Audit File Export Line"; var TempBlob: Codeunit "Temp Blob")
    var
        AuditFileExportHeader: Record "Audit File Export Header";
        GLEntry: Record "G/L Entry";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ExportGLEntries: XmlPort "Export G/L Entries FR";
        OutStream: OutStream;
    begin
        AuditFileExportHeader.Get(AuditFileExportLine.ID);
        CheckGLEntriesExist(AuditFileExportHeader);
        InitGlobalVariables(AuditFileExportHeader);

        OpenProgressDialog(CreateFileTxt + ProcessTransactionsTxt);

        TempBlob.CreateOutStream(OutStream);
        GLEntry.SetCurrentKey("Posting Date", "G/L Account No.", "Dimension Set ID");
        GLEntry.SetRange("Posting Date", StartingDate, EndingDate);
        ExportGLEntries.InitializeRequest(GLEntry, StartingDate, EndingDate);
        ExportGLEntries.SetDestination(OutStream);
        ExportGLEntries.Export();

        FeatureTelemetry.LogUptake('0000QPP', FRGeneralLedgerXMLTok, Enum::"Feature Uptake Status"::"Used");
        FeatureTelemetry.LogUsage('0000QPQ', FRGeneralLedgerXMLTok, FRGLXMLFrameworkTok);
    end;

    local procedure CheckGLEntriesExist(AuditFileExportHeader: Record "Audit File Export Header")
    var
        GLEntry: Record "G/L Entry";
        GLAccount: Record "G/L Account";
        GLAccNoFilter: Text;
    begin
        if GLAccount.GetFilter("No.") <> '' then
            GLAccNoFilter := GLAccount.GetFilter("No.");

        GLEntry.SetCurrentKey("Posting Date", "G/L Account No.", "Dimension Set ID");
        GLEntry.SetRange("Posting Date", AuditFileExportHeader."Starting Date", AuditFileExportHeader."Ending Date");
        GLEntry.SetFilter("G/L Account No.", GLAccNoFilter);
        if GLEntry.IsEmpty() then
            Error(NoEntriesToExportErr);
    end;

    local procedure OpenProgressDialog(DialogContent: Text)
    begin
        if GuiAllowed() then
            ProgressDialog.Open(DialogContent);
    end;

    procedure InitGlobalVariables(AuditFileExportHeader: Record "Audit File Export Header")
    begin
        StartingDate := AuditFileExportHeader."Starting Date";
        EndingDate := AuditFileExportHeader."Ending Date";
    end;
}
