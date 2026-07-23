namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.Company;
using System.Environment;
using System.Privacy;
using System.Upgrade;

codeunit 13611 "Elec. VAT Decl. Install"
{
    Access = Internal;
    Subtype = Install;

    var
        VersionLbl: Label 'DK Ele.VAT', Locked = true;
        VATReturnPeriodNoSeriesCodeLbl: Label 'DKVATPERIOD', Locked = true;
        VATReturnPeriodNoSeriesDescLbl: Label 'VAT Return Periods';
        VATReturnPeriodStartNoLbl: Label 'DKVATPER-0001', Locked = true;
        VATReturnPeriodEndNoLbl: Label 'DKVATPER-9999', Locked = true;

    trigger OnInstallAppPerCompany()
    var
        AppInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(AppInfo);
        if (AppInfo.DataVersion() <> Version.Create('0.0.0.0')) then
            exit;

        SetupElecVATDecl();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company-Initialize", 'OnCompanyInitialize', '', false, false)]
    local procedure CompanyInitialize()
    begin
        SetupElecVATDecl();
    end;

    local procedure SetupElecVATDecl()
    begin
        ApplyEvaluationClassificationsForPrivacy();
        InsertVATReportsConfiguration();
        UpdateVATReportSetup();
        InsertEmptySetup();

        SetAllUpgradeTags();
    end;

    local procedure ApplyEvaluationClassificationsForPrivacy()
    var
        Company: Record Company;
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
    begin
        Company.Get(CompanyName());
        if not Company."Evaluation Company" then
            exit;

        DataClassificationMgt.SetTableFieldsToNormal(Database::"Elec. VAT Decl. Setup");
    end;

    local procedure InsertVATReportsConfiguration()
    var
        VATReportsConfiguration: Record "VAT Reports Configuration";
    begin
        VATReportsConfiguration.Init();
        VATReportsConfiguration.Validate("VAT Report Type", VATReportsConfiguration."VAT Report Type"::"VAT Return");
        VATReportsConfiguration.Validate("VAT Report Version", GetVATReportVersion());
        VATReportsConfiguration.Validate("Suggest Lines Codeunit ID", Codeunit::"VAT Report Suggest Lines");
        VATReportsConfiguration.Validate("Validate Codeunit ID", Codeunit::"Elec. VAT Decl. Validate");
        VATReportsConfiguration.Validate("Content Codeunit ID", Codeunit::"Elec. VAT Decl. Create");
        VATReportsConfiguration.Validate("Submission Codeunit ID", Codeunit::"Elec. VAT Decl. Submit");
        VATReportsConfiguration.Validate("Response Handler Codeunit ID", Codeunit::"Elec. VAT Decl. Check Status");
        if VATReportsConfiguration.Insert(true) then;
    end;

    local procedure UpdateVATReportSetup()
    var
        VATReportSetup: Record "VAT Report Setup";
    begin
        if not VATReportSetup.Get() then
            VATReportSetup.Insert();

        VATReportSetup."Report Version" := GetVATReportVersion();
        VATReportSetup.Validate("Manual Receive Period CU ID", Codeunit::"Elec. VAT Decl. Get Periods");
        if not NoSeriesHasLines(VATReportSetup."VAT Return Period No. Series") then
            VATReportSetup.Validate("VAT Return Period No. Series", InitVATReturnPeriodNoSeries());
        if VATReportSetup.Modify() then;
    end;

    local procedure NoSeriesHasLines(NoSeriesCode: Code[20]): Boolean
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        if NoSeriesCode = '' then
            exit(false);

        NoSeriesLine.SetRange("Series Code", NoSeriesCode);
        exit(not NoSeriesLine.IsEmpty());
    end;

    local procedure InitVATReturnPeriodNoSeries(): Code[20]
    var
        NoSeries: Record "No. Series";
        SeriesCode: Code[20];
        StartNo: Code[20];
        EndNo: Code[20];
    begin
        SeriesCode := CopyStr(VATReturnPeriodNoSeriesCodeLbl, 1, MaxStrLen(SeriesCode));
        StartNo := CopyStr(VATReturnPeriodStartNoLbl, 1, MaxStrLen(StartNo));
        EndNo := CopyStr(VATReturnPeriodEndNoLbl, 1, MaxStrLen(EndNo));
        if not NoSeries.Get(SeriesCode) then
            InsertNoSeries(
                SeriesCode,
                CopyStr(VATReturnPeriodNoSeriesDescLbl, 1, MaxStrLen(NoSeries.Description)),
                StartNo,
                EndNo);
        if not NoSeriesHasLines(SeriesCode) then
            InsertNoSeriesLine(
                SeriesCode,
                StartNo,
                EndNo);

        exit(SeriesCode);
    end;

    local procedure InsertNoSeries(NoSeriesCode: Code[20]; NoSeriesDescription: Text[100]; StartingNo: Code[20]; EndingNo: Code[20])
    var
        NoSeries: Record "No. Series";
    begin
        NoSeries.Init();
        NoSeries.Code := NoSeriesCode;
        NoSeries.Description := CopyStr(NoSeriesDescription, 1, MaxStrLen(NoSeries.Description));
        NoSeries."Default Nos." := true;
        NoSeries."Manual Nos." := false;
        NoSeries.Insert();
        InsertNoSeriesLine(NoSeriesCode, StartingNo, EndingNo);
    end;

    local procedure InsertNoSeriesLine(NoSeriesCode: Code[20]; StartingNo: Code[20]; EndingNo: Code[20])
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        NoSeriesLine.Init();
        NoSeriesLine."Series Code" := NoSeriesCode;
        NoSeriesLine."Line No." := 10000;
        NoSeriesLine.Validate("Starting No.", StartingNo);
        NoSeriesLine.Validate("Ending No.", EndingNo);
        NoSeriesLine.Validate("Increment-by No.", 1);
        NoSeriesLine.Insert(true);
    end;

    local procedure GetVATReportVersion(): Code[10]
    begin
        exit(CopyStr(VersionLbl, 1, 10));
    end;

    local procedure InsertEmptySetup()
    var
        ElecVATDeclSetup: Record "Elec. VAT Decl. Setup";
    begin
        if not ElecVATDeclSetup.Get() then
            ElecVATDeclSetup.Insert(true);

        ElecVATDeclSetup."Use Azure Key Vault" := true;
        if ElecVATDeclSetup.Modify(true) then;
    end;

    local procedure SetAllUpgradeTags()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        ElecVATDeclUpgrade: Codeunit "Elec. VAT Decl. Upgrade";
    begin
        if not UpgradeTag.HasUpgradeTag(ElecVATDeclUpgrade.GetElecVATDeclAKVSetupUpgradeTag()) then
            UpgradeTag.SetUpgradeTag(ElecVATDeclUpgrade.GetElecVATDeclAKVSetupUpgradeTag());
    end;
}