namespace Microsoft.SubscriptionBilling;

using System.Threading;

codeunit 8014 "Auto Contract Billing"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    var
        BillingTemplate: Record "Billing Template";
    begin
        BillingTemplate.Get(Rec."Record ID to Process");
        BillingTemplate.BillContractsAutomatically();
    end;
}
