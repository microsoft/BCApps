namespace Microsoft.SubscriptionBilling;

codeunit 8123 "Create Sub. Analysis Entries"
{
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Sub. Contr. Analysis Entry" = ri,
                  tabledata "Subscription Line" = r;

    trigger OnRun()
    var
        SubBillingModuleSetup: Record "Sub. Billing Module Setup";
        AnalysisDate: Date;
    begin
        SubBillingModuleSetup.Get();
        if not SubBillingModuleSetup."Create Sub. Analysis Entries" then
            exit;

        AnalysisDate := CalcDate('<CY-2Y>', Today());
        CreateContractAnalysisEntries(AnalysisDate);

        AnalysisDate := CalcDate('<CY-1Y>', Today());
        CreateContractAnalysisEntries(AnalysisDate);

        AnalysisDate := Today();
        CreateContractAnalysisEntries(AnalysisDate);
    end;

    local procedure CreateContractAnalysisEntries(AnalysisDate: Date)
    var
        SubscriptionLine: Record "Subscription Line";
    begin
        SubscriptionLine.SetFilter("Subscription Contract No.", '<>%1', '');
        SubscriptionLine.SetFilter("Subscription Line End Date", '%1|>=%2', 0D, AnalysisDate);
        if SubscriptionLine.FindSet() then
            repeat
                CreateContractAnalysisEntry(SubscriptionLine, AnalysisDate);
            until SubscriptionLine.Next() = 0;
    end;

    local procedure CreateContractAnalysisEntry(SubscriptionLine: Record "Subscription Line"; AnalysisDate: Date)
    var
        SubContractAnalysisEntry: Record "Sub. Contr. Analysis Entry";
    begin
        SubContractAnalysisEntry.InitFromServiceCommitment(SubscriptionLine);
        SubContractAnalysisEntry."Analysis Date" := AnalysisDate;
        SubContractAnalysisEntry.CalculateMonthlyRecurringRevenue(SubscriptionLine);
        SubContractAnalysisEntry.CalculateMonthlyRecurringCost(SubscriptionLine);
        SubContractAnalysisEntry.Insert(true);
    end;
}