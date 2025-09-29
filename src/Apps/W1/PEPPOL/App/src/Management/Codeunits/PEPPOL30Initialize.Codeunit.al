// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

using Microsoft.Foundation.Company;
using Microsoft.Foundation.Reporting;

/// <summary>
/// Initializes PEPPOL30 electronic document formats during company initialization.
/// </summary>
codeunit 37204 "PEPPOL30 Initialize"
{
    Access = Internal;

    /// <summary>
    /// Event subscriber for company initialization that sets up PEPPOL30 electronic document formats.
    /// </summary>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company-Initialize", OnAfterInitElectronicFormats, '', false, false)]
    local procedure CompanyInitialize_OnAfterInitElectronicFormats()
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
        PEPPOLBIS3_ElectronicFormatDescriptionTxt: Label 'PEPPOL BIS3 Format (Pan-European Public Procurement Online)';
        PEPPOLBIS3_ElectronicFormatTxt: Label 'PEPPOL30', Locked = true;
    begin
        ElectronicDocumentFormat.InsertElectronicFormat(
            PEPPOLBIS3_ElectronicFormatTxt, PEPPOLBIS3_ElectronicFormatDescriptionTxt,
            Codeunit::"Exp. Sales Inv. PEPPOL30", 0, ElectronicDocumentFormat.Usage::"Sales Invoice".AsInteger());

        ElectronicDocumentFormat.InsertElectronicFormat(
            PEPPOLBIS3_ElectronicFormatTxt, PEPPOLBIS3_ElectronicFormatDescriptionTxt,
            Codeunit::"Exp. Sales CrM. PEPPOL30", 0, ElectronicDocumentFormat.Usage::"Sales Credit Memo".AsInteger());

        ElectronicDocumentFormat.InsertElectronicFormat(
            PEPPOLBIS3_ElectronicFormatTxt, PEPPOLBIS3_ElectronicFormatDescriptionTxt,
            Codeunit::"PEPPOL30 Validation", 0, ElectronicDocumentFormat.Usage::"Sales Validation".AsInteger());

        ElectronicDocumentFormat.InsertElectronicFormat(
            PEPPOLBIS3_ElectronicFormatTxt, PEPPOLBIS3_ElectronicFormatDescriptionTxt,
            Codeunit::"Exp. Serv.Inv. PEPPOL30", 0, ElectronicDocumentFormat.Usage::"Service Invoice".AsInteger());

        ElectronicDocumentFormat.InsertElectronicFormat(
            PEPPOLBIS3_ElectronicFormatTxt, PEPPOLBIS3_ElectronicFormatDescriptionTxt,
            Codeunit::"Exp. Serv.CrM. PEPPOL30", 0, ElectronicDocumentFormat.Usage::"Service Credit Memo".AsInteger());

        ElectronicDocumentFormat.InsertElectronicFormat(
            PEPPOLBIS3_ElectronicFormatTxt, PEPPOLBIS3_ElectronicFormatDescriptionTxt,
            Codeunit::"PEPPOL30 Service Validation", 0, ElectronicDocumentFormat.Usage::"Service Validation".AsInteger());
    end;
}