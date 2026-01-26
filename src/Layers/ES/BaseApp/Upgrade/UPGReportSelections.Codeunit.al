#pragma warning disable AA0247
codeunit 104107 "Upg Report Selections"
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

        UpdateReportSelections();
    end;

    local procedure UpdateReportSelections()
    var
        ReportSelections: Record "Report Selections";
        TempReportSelections: Record "Report Selections";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefCountry: Codeunit "Upgrade Tag Def - Country";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefCountry.GetUpdateReportSelectionsTag()) then
            exit;

        TempReportSelections.DeleteAll();

        ReportSelections.SetRange(Usage, 58, 59);
        if ReportSelections.FindSet() then
            repeat
                TempReportSelections := ReportSelections;
                case ReportSelections.Usage.AsInteger() of
                    58:
                        TempReportSelections.Usage := "Report Selection Usage".FromInteger(100);
                    59:
                        TempReportSelections.Usage := "Report Selection Usage".FromInteger(101);
                end;
                TempReportSelections.Insert();
            until ReportSelections.Next() = 0;

        TempReportSelections.Reset();
        if TempReportSelections.FindSet() then begin
            repeat
                ReportSelections := TempReportSelections;
                ReportSelections.Insert();
            until TempReportSelections.Next() = 0;

            ReportSelections.SetRange(Usage, 58, 59);
            ReportSelections.DeleteAll();
        end;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefCountry.GetUpdateReportSelectionsTag());
    end;
}

