#pragma warning disable AA0247
codeunit 104153 "Upgrade - EFT"
{
    Subtype = Upgrade;

    trigger OnRun()
    begin
    end;

    trigger OnUpgradePerCompany()
    var
        HybridDeployment: Codeunit "Hybrid Deployment";
    begin
        if not HybridDeployment.VerifyCanStartUpgrade(CompanyName()) then
            exit;

        UpdateGenJournalLineEFTSequenceNo();
    end;

    local procedure UpdateGenJournalLineEFTSequenceNo()
    var
        EFTExport: Record "EFT Export";
        GenJournalLine: Record "Gen. Journal Line";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefCountry: Codeunit "Upgrade Tag Def - Country";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefCountry.GetGenJnlLineEFTExportSequenceNoUpgradeTag()) then
            exit;

        if EFTExport.FindSet() then
            repeat
                if GenJournalLine.Get(EFTExport."Journal Template Name", EFTExport."Journal Batch Name", EFTExport."Line No.") then
                    if GenJournalLine."EFT Export Sequence No." = 0 then begin
                        GenJournalLine."EFT Export Sequence No." := EFTExport."Sequence No.";
                        if GenJournalLine.Modify() then;
                    end;
            until EFTExport.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefCountry.GetGenJnlLineEFTExportSequenceNoUpgradeTag());
    end;
}
