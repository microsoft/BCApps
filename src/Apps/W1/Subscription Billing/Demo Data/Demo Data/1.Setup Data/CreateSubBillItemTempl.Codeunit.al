namespace Microsoft.SubscriptionBilling;

using Microsoft.DemoData.Finance;

codeunit 8122 "Create Sub. Bill. Item Templ."
{
    InherentEntitlements = X;
    InherentPermissions = X;
    trigger OnRun()
    var
        FinanceModuleSetup: Record "Finance Module Setup";
        CreatePostingGroup: Codeunit "Create Posting Groups";
        ContosoSubscriptionBilling: Codeunit "Contoso Subscription Billing";
    begin
        FinanceModuleSetup.Get();

        ContosoSubscriptionBilling.InsertItemTemplateData(SubscriptionItem(), SubscriptionItemLbl, Enum::"Item Service Commitment Type"::"Service Commitment Item", '', CreatePostingGroup.RetailPostingGroup(), FinanceModuleSetup."VAT Prod. Post Grp. Standard");
    end;

    procedure SubscriptionItem(): Code[20]
    begin
        exit(SubscriptionItemTok);
    end;

    var
        SubscriptionItemTok: Label 'SUBSCRIPTION', MaxLength = 20;
        SubscriptionItemLbl: Label 'Subscription Item', MaxLength = 100;
}
