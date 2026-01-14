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
        ServiceCommitment: Record "Subscription Line";
    begin
        ServiceCommitment.SetFilter("Subscription Contract No.", '<>%1', '');
        ServiceCommitment.SetFilter("Subscription Line End Date", '%1|>=%2', 0D, AnalysisDate);
        if ServiceCommitment.FindSet() then begin
            repeat
                CreateContractAnalysisEntry(ServiceCommitment, AnalysisDate);
            until ServiceCommitment.Next() = 0;
        end;
    end;

    local procedure CreateContractAnalysisEntry(ServiceCommitment: Record "Subscription Line"; AnalysisDate: Date)
    var
        ContractAnalysisEntry: Record "Sub. Contr. Analysis Entry";
    begin
        ContractAnalysisEntry.InitFromServiceCommitment(ServiceCommitment);
        ContractAnalysisEntry."Analysis Date" := AnalysisDate;
        ContractAnalysisEntry.CalculateMonthlyRecurringRevenue(ServiceCommitment);
        ContractAnalysisEntry.CalculateMonthlyRecurringCost(ServiceCommitment);
        ContractAnalysisEntry.Insert(true);
    end;
}