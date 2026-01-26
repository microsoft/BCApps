// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Bank.BankAccount;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.Reporting;
using Microsoft.Service.Document;
using Microsoft.Service.Posting;
using Microsoft.Service.Setup;
using System.Utilities;

codeunit 12181 "FatturaPA Service Validation"
{
    TableNo = "Service Header";

    trigger OnRun()
    var
        FatturaDocHelper: Codeunit "Fattura Doc. Helper";
        HeaderRecRef: RecordRef;
    begin
        ErrorMessage.SetContext(Rec);
        ErrorMessage.ClearLog();

        HeaderRecRef.GetTable(Rec);
        FatturaDocHelper.CheckMandatoryFields(HeaderRecRef, ErrorMessage);
        ValidateServiceHeaderFields(Rec);

        if ErrorMessage.HasErrors(false) then
            ErrorMessage.ShowErrorMessages(true);
    end;

    var
        ErrorMessage: Record "Error Message";

    local procedure ValidateServiceHeaderFields(ServiceHeader: Record "Service Header")
    var
        PaymentMethod: Record "Payment Method";
        PaymentTerms: Record "Payment Terms";
    begin
        // Service Header mandatory fields
        if ErrorMessage.LogIfEmpty(ServiceHeader,
             ServiceHeader.FieldNo("Payment Method Code"), ErrorMessage."Message Type"::Error) = 0
        then begin
            if PaymentMethod.Get(ServiceHeader."Payment Method Code") then;
            ErrorMessage.LogIfEmpty(PaymentMethod,
              PaymentMethod.FieldNo("Fattura PA Payment Method"), ErrorMessage."Message Type"::Error);
        end;

        if (ErrorMessage.LogIfEmpty(ServiceHeader, ServiceHeader.FieldNo("Payment Terms Code"),
              ErrorMessage."Message Type"::Error) = 0) and PaymentTerms.Get(ServiceHeader."Payment Terms Code")
        then
            ErrorMessage.LogIfEmpty(PaymentTerms, PaymentTerms.FieldNo("Fattura Payment Terms Code"),
              ErrorMessage."Message Type"::Error);

        OnAfterValidateServiceHeaderFields(ServiceHeader);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateServiceHeaderFields(ServiceHeader: Record "Service Header")
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Service-Post", 'OnBeforePostWithLines', '', false, false)]
    local procedure OnBeforePostWithLines(var PassedServHeader: Record "Service Header"; var PassedServLine: Record "Service Line"; var PassedShip: Boolean; var PassedConsume: Boolean; var PassedInvoice: Boolean)
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
        DummyElectronicDocumentFormat: Record "Electronic Document Format";
        FatturaPASalesValidation: Codeunit "FatturaPA Sales Validation";
        ServFatturaSubscribers: Codeunit "Serv. Fattura Subscribers";
    begin
        ServiceMgtSetup.Get();
        if not ServiceMgtSetup."Validate Document On Posting" then begin
            ServFatturaSubscribers.AssignFatturaDocTypeFromVATPostingSetupToServiceHeader(PassedServHeader, false);
            exit;
        end;

        FatturaPASalesValidation.AutoValidateDocument(
          PassedServHeader, PassedServHeader."Customer No.", DummyElectronicDocumentFormat.Usage::"Service Validation".AsInteger());
        ServFatturaSubscribers.AssignFatturaDocTypeFromVATPostingSetupToServiceHeader(PassedServHeader, true);
    end;
}

