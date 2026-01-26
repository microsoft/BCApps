// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Setup;

using Microsoft.EServices.EDocument;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Reporting;

codeunit 12197 "Service Company Initialize IT"
{
    var
        FatturaPA_ElectronicFormatTxt: Label 'FatturaPA';
        FatturaPA_ElectronicFormatDescriptionTxt: Label 'FatturaPA (Fattura elettronica)';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company-Initialize", 'OnAfterInitElectronicFormats', '', false, false)]
    local procedure OnAfterInitElectronicFormats()
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
    begin
        ElectronicDocumentFormat.InsertElectronicFormat(
          FatturaPA_ElectronicFormatTxt, FatturaPA_ElectronicFormatDescriptionTxt,
          CODEUNIT::"Export FatturaPA Document", 0, ElectronicDocumentFormat.Usage::"Service Credit Memo".AsInteger());

        ElectronicDocumentFormat.InsertElectronicFormat(
          FatturaPA_ElectronicFormatTxt, FatturaPA_ElectronicFormatDescriptionTxt,
          CODEUNIT::"FatturaPA Sales Validation", 0, ElectronicDocumentFormat.Usage::"Sales Validation".AsInteger());

        ElectronicDocumentFormat.InsertElectronicFormat(
          FatturaPA_ElectronicFormatTxt, FatturaPA_ElectronicFormatDescriptionTxt,
          CODEUNIT::"FatturaPA Service Validation", 0, ElectronicDocumentFormat.Usage::"Service Validation".AsInteger());
    end;
}