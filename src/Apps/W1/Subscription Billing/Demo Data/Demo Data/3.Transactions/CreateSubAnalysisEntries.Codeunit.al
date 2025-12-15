namespace Microsoft.SubscriptionBilling;

codeunit 8123 "Create Sub. Analysis Entries"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    var
        SubBillingModuleSetup: Record "Sub. Billing Module Setup";
    begin
        SubBillingModuleSetup.Get();
        if not SubBillingModuleSetup."Create Sub. Analysis Entries" then
            exit;

        Report.Run(Report::"Create Contract Analysis");
    end;
}