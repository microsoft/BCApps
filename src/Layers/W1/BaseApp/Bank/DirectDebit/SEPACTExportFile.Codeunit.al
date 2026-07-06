// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.DirectDebit;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Payment;
using Microsoft.Finance.GeneralLedger.Journal;
using System.IO;
using System.Utilities;

/// <summary>
/// Handles the export of SEPA credit transfer payments to XML files in compliance with SEPA standards.
/// Processes general journal lines for credit transfers, validates payment information, and generates
/// XML files using appropriate XMLPorts for bank submission.
/// </summary>
codeunit 1220 "SEPA CT-Export File"
{
    Permissions = TableData "Data Exch. Field" = rimd;
    TableNo = "Gen. Journal Line";

    trigger OnRun()
    var
        BankAccount: Record "Bank Account";
        ExpUserFeedbackGenJnl: Codeunit "Exp. User Feedback Gen. Jnl.";
    begin
        Rec.LockTable();
        BankAccount.Get(Rec."Bal. Account No.");
        if Export(Rec, BankAccount.GetPaymentExportXMLPortID()) then
            ExpUserFeedbackGenJnl.SetExportFlagOnGenJnlLine(Rec);
    end;

    var
        ExportToServerFile: Boolean;
        FeatureNameTxt: label 'SEPA Credit Transfer Export', locked = true;

    internal procedure FeatureName(): Text
    begin
        exit(FeatureNameTxt)
    end;

    /// <summary>
    /// Exports SEPA credit transfer data from general journal lines to XML format.
    /// Creates credit transfer register entry and manages file output to server or client.
    /// </summary>
    /// <param name="GenJnlLine">General journal lines containing payment data to export</param>
    /// <param name="XMLPortID">XML port ID to use for export processing</param>
    /// <returns>True if export completed successfully</returns>
    procedure Export(var GenJnlLine: Record "Gen. Journal Line"; XMLPortID: Integer) Result: Boolean
    var
        CreditTransferRegister: Record "Credit Transfer Register";
        TempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
        OutStr: OutStream;
        UseCommonDialog: Boolean;
        FileCreated: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeExtport(GenJnlLine, XMLPortID, Result, IsHandled);
        if IsHandled then
            exit(Result);

        TempBlob.CreateOutStream(OutStr);
        XMLPORT.Export(XMLPortID, OutStr, GenJnlLine);

        CreditTransferRegister.FindLast();
        UseCommonDialog := not ExportToServerFile;
        OnBeforeBLOBExport(TempBlob, CreditTransferRegister, UseCommonDialog, FileCreated, IsHandled);
        if not IsHandled then
            FileCreated :=
                FileManagement.BLOBExport(TempBlob, StrSubstNo('%1.XML', CreditTransferRegister.Identifier), UseCommonDialog) <> '';
        if FileCreated then
            SetCreditTransferRegisterToFileCreated(CreditTransferRegister, TempBlob);

        exit(CreditTransferRegister.Status = CreditTransferRegister.Status::"File Created");
    end;

    local procedure SetCreditTransferRegisterToFileCreated(var CreditTransferRegister: Record "Credit Transfer Register"; var TempBlob: Codeunit "Temp Blob")
    var
        RecordRef: RecordRef;
    begin
        CreditTransferRegister.Status := CreditTransferRegister.Status::"File Created";
        RecordRef.GetTable(CreditTransferRegister);
        TempBlob.ToRecordRef(RecordRef, CreditTransferRegister.FieldNo("Exported File"));
        RecordRef.SetTable(CreditTransferRegister);
        CreditTransferRegister.Modify();
    end;

    /// <summary>
    /// Enables export to server file instead of client download.
    /// </summary>
    procedure EnableExportToServerFile()
    begin
        ExportToServerFile := true;
    end;

    /// <summary>
    /// Integration event raised before BLOB export operation during credit transfer file creation.
    /// Enables custom file handling or modification of export parameters.
    /// </summary>
    /// <param name="TempBlob">Temporary BLOB containing the export data</param>
    /// <param name="CreditTransferRegister">Credit transfer register record being processed</param>
    /// <param name="UseComonDialog">Whether to use common dialog for file operations</param>
    /// <param name="FieldCreated">Set to true if file was created by subscriber</param>
    /// <param name="IsHandled">Set to true to skip standard BLOB export processing</param>
    /// <remarks>
    /// Raised from Export procedure before writing BLOB data to file.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeBLOBExport(var TempBlob: Codeunit "Temp Blob"; CreditTransferRegister: Record "Credit Transfer Register"; UseComonDialog: Boolean; var FieldCreated: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before starting SEPA credit transfer export process.
    /// Enables custom export handling or validation before standard processing.
    /// </summary>
    /// <param name="GenJnlLine">General journal lines to be exported</param>
    /// <param name="XMLPortID">XML port ID for export processing</param>
    /// <param name="Result">Set to true if export was successful</param>
    /// <param name="IsHandled">Set to true to skip standard export processing</param>
    /// <remarks>
    /// Raised from Export procedure before starting standard SEPA export operations.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeExtport(var GenJnlLine: Record "Gen. Journal Line"; XMLPortID: Integer; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
}

