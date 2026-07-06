namespace Microsoft.eServices.EDocument.IO.Peppol;

#if not CLEAN29
using Microsoft.eServices.EDocument.Formats;
#endif
using Microsoft.Sales.Document;
using Microsoft.Sales.Peppol;

codeunit 13921 "EDoc PEPPOL Validation DE"
{
    EventSubscriberInstance = Manual;

    var
        SkipVATRegNoCheck: Boolean;

#if not CLEAN29
#pragma warning disable AL0432
    var
        BuyerReference: Enum "E-Document Buyer Reference";

    [Obsolete('Use SetSkipVATRegNoCheck procedure instead.', '29.0')]
    procedure SetBuyerReference(NewBuyerReference: Enum "E-Document Buyer Reference")
    begin
        BuyerReference := NewBuyerReference;
    end;
#pragma warning restore AL0432
#endif

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"PEPPOL Validation", 'OnCheckSalesDocumentOnBeforeCheckCustomerVATRegNo', '', false, false)]
    local procedure SkipCustomerVATRegNoCheck(var IsHandled: Boolean)
    begin
        if SkipVATRegNoCheck then
            IsHandled := true;
#if not CLEAN29
#pragma warning disable AL0432
        if BuyerReference = BuyerReference::"Customer Reference" then
            IsHandled := true;
#pragma warning restore AL0432
#endif
    end;

    internal procedure SetSkipVATRegNoCheck(NewSkipVATRegNoCheck: Boolean)
    begin
        SkipVATRegNoCheck := NewSkipVATRegNoCheck;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"PEPPOL Validation", 'OnCheckSalesDocumentOnBeforeCheckYourReference', '', false, false)]
    local procedure SkipCheckOnCheckSalesDocumentOnBeforeCheckYourReference(var IsHandled: Boolean)
    begin
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"PEPPOL Validation", 'OnAfterCheckSalesDocument', '', false, false)]
    local procedure OnAfterCheckSalesDocument(SalesHeader: Record "Sales Header")
    begin
        SalesHeader.TestField("Sell-to E-Mail");
    end;
}