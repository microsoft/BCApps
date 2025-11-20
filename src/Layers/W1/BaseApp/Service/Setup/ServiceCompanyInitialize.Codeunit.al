// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Setup;

using Microsoft.Foundation.Company;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Reporting;
using Microsoft.Sales.Peppol;

codeunit 6475 "Service Company Initialize"
{
    Permissions = tabledata "Service Mgt. Setup" = i;

    var
        ServiceTxt: Label 'SERVICE', MaxLength = 10;
        ServiceManagementTxt: Label 'Service Management';
        PEPPOLBIS3_ElectronicFormatTxt: Label 'PEPPOL BIS3', Locked = true;
        PEPPOLBIS3_ElectronicFormatDescriptionTxt: Label 'PEPPOL BIS3 Format (Pan-European Public Procurement Online)';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company-Initialize", 'OnAfterInitSetupTables', '', false, false)]
    local procedure OnAfterInitSetupTables()
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
    begin
        if not ServiceMgtSetup.FindFirst() then begin
            ServiceMgtSetup.Init();
            ServiceMgtSetup.Insert();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company-Initialize", 'OnBeforeSourceCodeSetupInsert', '', false, false)]
    local procedure OnBeforeSourceCodeSetupInsert(var SourceCodeSetup: Record "Source Code Setup"; sender: Codeunit "Company-Initialize")
    begin
        sender.InsertSourceCode(SourceCodeSetup."Service Management", ServiceTxt, ServiceManagementTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company-Initialize", 'OnAfterInitElectronicFormats', '', false, false)]
    local procedure OnAfterInitElectronicFormats()
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
    begin
        ElectronicDocumentFormat.InsertElectronicFormat(
          PEPPOLBIS3_ElectronicFormatTxt, PEPPOLBIS3_ElectronicFormatDescriptionTxt,
          CODEUNIT::"Exp. Serv.Inv. PEPPOL BIS3.0", 0, ElectronicDocumentFormat.Usage::"Service Invoice".AsInteger());

        ElectronicDocumentFormat.InsertElectronicFormat(
          PEPPOLBIS3_ElectronicFormatTxt, PEPPOLBIS3_ElectronicFormatDescriptionTxt,
          CODEUNIT::"Exp. Serv.CrM. PEPPOL BIS3.0", 0, ElectronicDocumentFormat.Usage::"Service Credit Memo".AsInteger());

        ElectronicDocumentFormat.InsertElectronicFormat(
          PEPPOLBIS3_ElectronicFormatTxt, PEPPOLBIS3_ElectronicFormatDescriptionTxt,
          CODEUNIT::"PEPPOL Service Validation", 0, ElectronicDocumentFormat.Usage::"Service Validation".AsInteger());
    end;

}
