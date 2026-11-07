// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.IO.Peppol;

#if not CLEAN29
using Microsoft.eServices.EDocument.Formats;
using Microsoft.Sales.Document;
using Microsoft.Sales.Peppol;

#pragma warning disable AL0432, AS0072
codeunit 13921 "EDoc PEPPOL Validation DE"
{
    EventSubscriberInstance = Manual;
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced by interface-based DE PEPPOL implementations in the PEPPOL DE app ("PEPPOL30 DE Sales Validation" implements "PEPPOL30 Validation"). EDocumentDE now pushes the skip-Customer-VAT/GLN-check flag (computed from "E-Document DE Helper".HasRoutingNo) to "PEPPOL30 DE Context" so the new validation impl applies the same DE deviations (skip Customer GLN/VAT when a routing number is present, skip Your Reference, require Sell-to E-Mail).';
    ObsoleteTag = '29.0';

    var
        BuyerReference: Enum "E-Document Buyer Reference";

    [Obsolete('Replaced by "PEPPOL30 DE Context".SetSkipCustomerVATRegNoCheck pushed by EDocumentDE before invoking the W1 EDoc PEPPOL bridge.', '29.0')]
    procedure SetBuyerReference(NewBuyerReference: Enum "E-Document Buyer Reference")
    begin
        BuyerReference := NewBuyerReference;
    end;

    [Obsolete('Replaced by the conditional Customer GLN/VAT skip in "PEPPOL30 DE Sales Validation".CheckSalesDocumentDE.', '29.0')]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"PEPPOL Validation", 'OnCheckSalesDocumentOnBeforeCheckCustomerVATRegNo', '', false, false)]
    local procedure SkipCustomerVATRegNoCheck(var IsHandled: Boolean)
    begin
        if BuyerReference = BuyerReference::"Customer Reference" then
            IsHandled := true;
    end;

    [Obsolete('Replaced by the omitted Your Reference TestField in "PEPPOL30 DE Sales Validation".CheckSalesDocumentDE.', '29.0')]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"PEPPOL Validation", 'OnCheckSalesDocumentOnBeforeCheckYourReference', '', false, false)]
    local procedure SkipCheckOnCheckSalesDocumentOnBeforeCheckYourReference(var IsHandled: Boolean)
    begin
        IsHandled := true;
    end;

    [Obsolete('Replaced by the explicit Sell-to E-Mail TestField at the end of "PEPPOL30 DE Sales Validation".CheckSalesDocumentDE.', '29.0')]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"PEPPOL Validation", 'OnAfterCheckSalesDocument', '', false, false)]
    local procedure OnAfterCheckSalesDocument(SalesHeader: Record "Sales Header")
    begin
        SalesHeader.TestField("Sell-to E-Mail");
    end;
}
#pragma warning restore AL0432, AS0072
#endif
