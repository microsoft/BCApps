// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.DirectDebit;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Setup;
using System.IO;
using System.Utilities;

/// <summary>
/// Handles the export of SEPA direct debit collections to XML files in compliance with SEPA standards.
/// Validates bank account information, generates XML files using appropriate XMLPorts, and manages
/// the collection status throughout the export process.
/// </summary>
codeunit 1230 "SEPA DD-Export File"
{
    TableNo = "Direct Debit Collection Entry";

    trigger OnRun()
    var
        DirectDebitCollection: Record "Direct Debit Collection";
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        BankAccount: Record "Bank Account";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        DirectDebitCollectionEntry.Copy(Rec);
        GetDirectDebitCollection(Rec, DirectDebitCollection);
        DirectDebitCollection.TestField("To Bank Account No.");
        BankAccount.Get(DirectDebitCollection."To Bank Account No.");
        GeneralLedgerSetup.Get();
        if not GeneralLedgerSetup."SEPA Export w/o Bank Acc. Data" then
            BankAccount.TestField(IBAN)
        else
            if (BankAccount."Bank Account No." = '') or (BankAccount."Bank Branch No." = '') then
                if BankAccount.IBAN = '' then
                    Error(ExportWithoutIBANErr, BankAccount.TableCaption(), BankAccount."No.");

        DirectDebitCollection.LockTable();
        DirectDebitCollection.DeletePaymentFileErrors();
        Commit();
        if not Export(Rec, BankAccount.GetDDExportXMLPortID(), DirectDebitCollection.Identifier) then
            Error('');

        DirectDebitCollectionEntry.SetRange("Direct Debit Collection No.", DirectDebitCollection."No.");
        DirectDebitCollectionEntry.ModifyAll(Status, DirectDebitCollectionEntry.Status::"File Created");
        DirectDebitCollection.Status := DirectDebitCollection.Status::"File Created";
        DirectDebitCollection.Modify();
    end;

    var
        ExportToServerFile: Boolean;
        ExportWithoutIBANErr: Label 'Either the Bank Account No. and Bank Branch No. fields or the IBAN field must be filled in for %1 %2.', Comment = '%1= table name, %2=key field value. Example: Either the Bank Account No. and Bank Branch No. fields or the IBAN field must be filled in for Bank Account WWB-OPERATING.';
        FeatureNameTxt: label 'SEPA Direct Debit Export', locked = true;

    /// <summary>
    /// Returns the feature name for telemetry and logging purposes.
    /// </summary>
    /// <returns>Feature name for SEPA direct debit export functionality</returns>
    internal procedure FeatureName(): Text
    begin
        exit(FeatureNameTxt)
    end;

    local procedure Export(var DirectDebitCollectionEntry: Record "Direct Debit Collection Entry"; XMLPortID: Integer; FileName: Text) Result: Boolean
    var
        TempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
        OutStr: OutStream;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeExport(DirectDebitCollectionEntry, XMLPortID, FileName, Result, IsHandled);
        if IsHandled then
            exit(Result);

        TempBlob.CreateOutStream(OutStr);
        XMLPORT.Export(XMLPortID, OutStr, DirectDebitCollectionEntry);

        IsHandled := false;
        OnExportOnAfterXMLPortExport(TempBlob, Result, IsHandled);
        if IsHandled then
            exit(Result);

        exit(FileManagement.BLOBExport(TempBlob, StrSubstNo('%1.XML', FileName), not ExportToServerFile) <> '');
    end;

    local procedure GetDirectDebitCollection(var DirectDebitCollectionEntry: Record "Direct Debit Collection Entry"; var DirectDebitCollection: Record "Direct Debit Collection")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetDirectDebitCollection(DirectDebitCollectionEntry, DirectDebitCollection, IsHandled);
        if IsHandled then
            exit;

        DirectDebitCollectionEntry.TestField("Direct Debit Collection No.");
        DirectDebitCollection.Get(DirectDebitCollectionEntry."Direct Debit Collection No.");
    end;

    /// <summary>
    /// Enables server-side file export mode instead of client download.
    /// </summary>
    procedure EnableExportToServerFile()
    begin
        ExportToServerFile := true;
    end;

    /// <summary>
    /// Integration event that allows customization of direct debit collection retrieval logic.
    /// </summary>
    /// <param name="DirectDebitCollectionEntry">The collection entry being processed</param>
    /// <param name="DirectDebitCollection">The collection being retrieved</param>
    /// <param name="IsHandled">Whether the event has been handled by subscribers</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDirectDebitCollection(var DirectDebitCollectionEntry: Record "Direct Debit Collection Entry"; var DirectDebitCollection: Record "Direct Debit Collection"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event that allows customization of the export process before XML generation.
    /// </summary>
    /// <param name="DirectDebitCollectionEntry">The collection entry being exported</param>
    /// <param name="XMLPortID">ID of the XMLPort used for export</param>
    /// <param name="FileName">Name of the file being generated</param>
    /// <param name="Result">Result of the export operation</param>
    /// <param name="IsHandled">Whether the event has been handled by subscribers</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeExport(var DirectDebitCollectionEntry: Record "Direct Debit Collection Entry"; XMLPortID: Integer; FileName: Text; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event triggered after XML export is completed, allowing post-processing of the generated content.
    /// </summary>
    /// <param name="TempBlob">Temporary blob containing the exported XML data</param>
    /// <param name="Result">Result of the export operation</param>
    /// <param name="IsHandled">Whether the event has been handled by subscribers</param>
    [IntegrationEvent(false, false)]
    local procedure OnExportOnAfterXMLPortExport(var TempBlob: Codeunit "Temp Blob"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
}

