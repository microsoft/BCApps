namespace Microsoft.SubscriptionBilling;

using Microsoft.Purchases.Document;

codeunit 148456 "Rec. Billing Purch. Hdr. Sub."
{
    SingleInstance = true;
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", OnBeforeValidateEvent, "Pay-to Vendor No.", false, false)]
    local procedure OnBeforePayToVendorNoValidate(var Rec: Record "Purchase Header"; CurrFieldNo: Integer)
    begin
        if not Rec."Recurring Billing" then
            Error(RecurringBillingMustBeTrueBeforePayToVendorErr);
    end;

    var
        RecurringBillingMustBeTrueBeforePayToVendorErr: Label '"Recurring Billing" must be true on Purchase Header before "Pay-to Vendor No." is validated.', Locked = true;
}
