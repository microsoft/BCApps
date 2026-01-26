// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Company;

using Microsoft.Bank.Payment;
using Microsoft.Bank.Setup;
using Microsoft.EServices.EDocument;
using Microsoft.Foundation.Reporting;

codeunit 12196 "Company Initialize IT"
{
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
        CompanyInitialize: Codeunit "Company-Initialize";
        FatturaPA_ElectronicFormatTxt: Label 'FatturaPA';
        FatturaPA_ElectronicFormatDescriptionTxt: Label 'FatturaPA (Fattura elettronica)';
        LegacyCTBankExportCodeTxt: Label 'BONIFICI';
        LegacyCTBankExportNameTxt: Label 'Vendor Bills Floppy Payment File';
        LegacyDDBankExportCodeTxt: Label 'EFFETTI';
        LegacyDDBankExportNameTxt: Label 'Customer Bills Floppy Payment File';


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company-Initialize", 'OnAfterInitBankExportImportSetup', '', false, false)]
    local procedure OnAfterInitBankExportImportSetup()
    begin
        CompanyInitialize.InsertBankExportImportSetup(
            LegacyCTBankExportCodeTxt, LegacyCTBankExportNameTxt, BankExportImportSetup.Direction::Export,
            CODEUNIT::"Vendor Bills Floppy", 0, 0);
        CompanyInitialize.InsertBankExportImportSetup(
            LegacyDDBankExportCodeTxt, LegacyDDBankExportNameTxt, BankExportImportSetup.Direction::Export,
            CODEUNIT::"Customer Bills Floppy", 0, 0);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company-Initialize", 'OnAfterInitElectronicFormats', '', false, false)]
    local procedure OnAfterInitElectronicFormats()
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
    begin
        // FatturaPA
        ElectronicDocumentFormat.InsertElectronicFormat(
          FatturaPA_ElectronicFormatTxt, FatturaPA_ElectronicFormatDescriptionTxt,
          CODEUNIT::"Export FatturaPA Document", 0, ElectronicDocumentFormat.Usage::"Sales Invoice".AsInteger());

        ElectronicDocumentFormat.InsertElectronicFormat(
          FatturaPA_ElectronicFormatTxt, FatturaPA_ElectronicFormatDescriptionTxt,
          CODEUNIT::"Export FatturaPA Document", 0, ElectronicDocumentFormat.Usage::"Sales Credit Memo".AsInteger());

        ElectronicDocumentFormat.InsertElectronicFormat(
          FatturaPA_ElectronicFormatTxt, FatturaPA_ElectronicFormatDescriptionTxt,
          CODEUNIT::"Export FatturaPA Document", 0, ElectronicDocumentFormat.Usage::"Service Invoice".AsInteger());
    end;
}