#pragma warning disable AA0247
#if not CLEAN27
codeunit 104153 "UPG Per. VAT Settl. Entry IT"
{
    Subtype = Upgrade;
    ObsoleteReason = 'This upgrade is only needed for older versions, new versions will not contain the table to move data from.';
    ObsoleteState = Pending;
    ObsoleteTag = '27.0';

    trigger OnRun()
    begin
    end;

    trigger OnUpgradePerCompany()
    var
        HybridDeployment: Codeunit "Hybrid Deployment";
    begin
        if not HybridDeployment.VerifyCanStartUpgrade(CompanyName()) then
            exit;

        UpgradePeriodicVATSettlementEntry();
    end;

    procedure UpgradePeriodicVATSettlementEntry();
    var
        PeriodicSettlementVATEntry: Record "Periodic Settlement VAT Entry";
        PeriodicSettlVATEntry: Record "Periodic VAT Settlement Entry";
        FeatureKey: Record "Feature Key";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTags: Codeunit "Upgrade Tag Def - Country";
        DataTransfer: DataTransfer;
        ITCalcAndPostPerActivityCodeTok: Label 'ITCalcAndPostPerActivityCode', Locked = true, Comment = 'Tag for the feature ITCalcAndPostPerActivityCode';
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTags.GetPeriodicVATSettlementEntryUpgradeTag()) then
            exit;

        // Upgrade only if there are no feature key for ITCalcAndPostPerActivityCode  
        if FeatureKey.Get(ITCalcAndPostPerActivityCodeTok) then
            exit;

        DataTransfer.SetTables(Database::"Periodic Settlement VAT Entry", Database::"Periodic VAT Settlement Entry");

        DataTransfer.AddFieldValue(PeriodicSettlementVATEntry.FieldNo("VAT Period"), PeriodicSettlVATEntry.FieldNo("VAT Period"));
        DataTransfer.AddFieldValue(PeriodicSettlementVATEntry.FieldNo("VAT Settlement"), PeriodicSettlVATEntry.FieldNo("VAT Settlement"));
        DataTransfer.AddFieldValue(PeriodicSettlementVATEntry.FieldNo("Add-Curr. VAT Settlement"), PeriodicSettlVATEntry.FieldNo("Add-Curr. VAT Settlement"));
        DataTransfer.AddFieldValue(PeriodicSettlementVATEntry.FieldNo("Prior Period Input VAT"), PeriodicSettlVATEntry.FieldNo("Prior Period Input VAT"));
        DataTransfer.AddFieldValue(PeriodicSettlementVATEntry.FieldNo("Prior Period Output VAT"), PeriodicSettlVATEntry.FieldNo("Prior Period Output VAT"));
        DataTransfer.AddFieldValue(PeriodicSettlementVATEntry.FieldNo("Add Curr. Prior Per. Inp. VAT"), PeriodicSettlVATEntry.FieldNo("Add Curr. Prior Per. Inp. VAT"));
        DataTransfer.AddFieldValue(PeriodicSettlementVATEntry.FieldNo("Add Curr. Prior Per. Out VAT"), PeriodicSettlVATEntry.FieldNo("Add Curr. Prior Per. Out VAT"));
        DataTransfer.AddFieldValue(PeriodicSettlementVATEntry.FieldNo("Paid Amount"), PeriodicSettlVATEntry.FieldNo("Paid Amount"));
        DataTransfer.AddFieldValue(PeriodicSettlementVATEntry.FieldNo("Advanced Amount"), PeriodicSettlVATEntry.FieldNo("Advanced Amount"));
        DataTransfer.AddFieldValue(PeriodicSettlementVATEntry.FieldNo("Add-Curr. Paid. Amount"), PeriodicSettlVATEntry.FieldNo("Add-Curr. Paid. Amount"));
        DataTransfer.AddFieldValue(PeriodicSettlementVATEntry.FieldNo("Add-Curr. Advanced Amount"), PeriodicSettlVATEntry.FieldNo("Add-Curr. Advanced Amount"));
        DataTransfer.AddFieldValue(PeriodicSettlementVATEntry.FieldNo("Bank Code"), PeriodicSettlVATEntry.FieldNo("Bank Code"));
        DataTransfer.AddFieldValue(PeriodicSettlementVATEntry.FieldNo("Paid Date"), PeriodicSettlVATEntry.FieldNo("Paid Date"));
        DataTransfer.AddFieldValue(PeriodicSettlementVATEntry.FieldNo(Description), PeriodicSettlVATEntry.FieldNo(Description));
        DataTransfer.AddFieldValue(PeriodicSettlementVATEntry.FieldNo("VAT Period Closed"), PeriodicSettlVATEntry.FieldNo("VAT Period Closed"));
        DataTransfer.AddFieldValue(PeriodicSettlementVATEntry.FieldNo("Prior Year Input VAT"), PeriodicSettlVATEntry.FieldNo("Prior Year Input VAT"));
        DataTransfer.AddFieldValue(PeriodicSettlementVATEntry.FieldNo("Prior Year Output VAT"), PeriodicSettlVATEntry.FieldNo("Prior Year Output VAT"));
        DataTransfer.AddFieldValue(PeriodicSettlementVATEntry.FieldNo("Add Curr.Prior Year Inp. VAT"), PeriodicSettlVATEntry.FieldNo("Add Curr.Prior Year Inp. VAT"));
        DataTransfer.AddFieldValue(PeriodicSettlementVATEntry.FieldNo("Add Curr.Prior Year Out. VAT"), PeriodicSettlVATEntry.FieldNo("Add Curr.Prior Year Out. VAT"));
        DataTransfer.AddFieldValue(PeriodicSettlementVATEntry.FieldNo("Payable VAT Variation"), PeriodicSettlVATEntry.FieldNo("Payable VAT Variation"));
        DataTransfer.AddFieldValue(PeriodicSettlementVATEntry.FieldNo("Deductible VAT Variation"), PeriodicSettlVATEntry.FieldNo("Deductible VAT Variation"));
        DataTransfer.AddFieldValue(PeriodicSettlementVATEntry.FieldNo("Tax Debit Variation"), PeriodicSettlVATEntry.FieldNo("Tax Debit Variation"));
        DataTransfer.AddFieldValue(PeriodicSettlementVATEntry.FieldNo("Tax Credit Variation"), PeriodicSettlVATEntry.FieldNo("Tax Credit Variation"));
        DataTransfer.AddFieldValue(PeriodicSettlementVATEntry.FieldNo("Unpaid VAT Previous Periods"), PeriodicSettlVATEntry.FieldNo("Unpaid VAT Previous Periods"));
        DataTransfer.AddFieldValue(PeriodicSettlementVATEntry.FieldNo("Tax Debit Variation Interest"), PeriodicSettlVATEntry.FieldNo("Tax Debit Variation Interest"));
        DataTransfer.AddFieldValue(PeriodicSettlementVATEntry.FieldNo("Omit VAT Payable Interest"), PeriodicSettlVATEntry.FieldNo("Omit VAT Payable Interest"));
        DataTransfer.AddFieldValue(PeriodicSettlementVATEntry.FieldNo("Credit VAT Compensation"), PeriodicSettlVATEntry.FieldNo("Credit VAT Compensation"));
        DataTransfer.AddFieldValue(PeriodicSettlementVATEntry.FieldNo("Special Credit"), PeriodicSettlVATEntry.FieldNo("Special Credit"));

        OnUpgradePeriodicVATSettlementEntryOnBeforeCopyRows(PeriodicSettlementVATEntry, PeriodicSettlVATEntry, DataTransfer);
        DataTransfer.CopyRows();

        UpgradeTag.SetUpgradeTag(UpgradeTags.GetPeriodicVATSettlementEntryUpgradeTag());
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpgradePeriodicVATSettlementEntryOnBeforeCopyRows(var PeriodicSettlementVATEntry: Record "Periodic Settlement VAT Entry"; var PeriodicSettlVATEntry: Record "Periodic VAT Settlement Entry"; var DataTransfer: DataTransfer)
    begin
    end;
}
#endif
