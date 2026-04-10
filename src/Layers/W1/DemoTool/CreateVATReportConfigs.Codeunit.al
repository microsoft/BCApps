codeunit 101254 "Create VAT Report Configs"
{

    trigger OnRun()
    var
        VATReportsConfiguration: Record "VAT Reports Configuration";
    begin
        VATReportsConfiguration.Init();
        VATReportsConfiguration."VAT Report Type" := VATReportsConfiguration."VAT Report Type"::"EC Sales List";
        VATReportsConfiguration."VAT Report Version" := 'CURRENT';
        VATReportsConfiguration."Suggest Lines Codeunit ID" := CODEUNIT::"EC Sales List Suggest Lines";
        VATReportsConfiguration."Validate Codeunit ID" := CODEUNIT::"ECSL Report Validate";
        VATReportsConfiguration.Insert();

        VATReportsConfiguration.Init();
        VATReportsConfiguration."VAT Report Type" := VATReportsConfiguration."VAT Report Type"::"VAT Return";
        VATReportsConfiguration."VAT Report Version" := 'CURRENT';
        VATReportsConfiguration."Suggest Lines Codeunit ID" := CODEUNIT::"VAT Report Suggest Lines";
        VATReportsConfiguration."Validate Codeunit ID" := CODEUNIT::"VAT Report Validate";
        VATReportsConfiguration.Insert();
        CreateReportNoSeries();
    end;

    var
        CreateNoSeries: Codeunit "Create No. Series";
        ECSLCodeTxt: Label 'ECSL', Locked = true;
        ECSLDescription: Label 'EC Sales List reports.';
        ECSLStart: Label 'ECSL-0001', Locked = true;
        ECSLEnd: Label 'ECSL-9999', Locked = true;
        VATReportCodeTxt: Label 'VATREPORTS', Locked = true;
        VATReportDescription: Label 'VAT Returns reports.';
        VATReportStart: Label 'VATRET-0001', Locked = true;
        VATReportEnd: Label 'VATRET-9999', Locked = true;
        VATReturnPeriodCodeTxt: Label 'VATPERIODS', Locked = true;
        VATReturnPeriodDescTxt: Label 'VAT Return Periods';
        VATReturnPeriodStartTxt: Label 'VATPER-0001', Locked = true;
        VATReturnPeriodEndTxt: Label 'VATPER-9999', Locked = true;

    local procedure CreateReportNoSeries()
    var
        VATReportSetup: Record "VAT Report Setup";
        NoSeries: Record "No. Series";
        ECSLCode: Code[20];
        VATReportCode: Code[20];
        VATReturnPeriodCode: Code[20];
    begin
        ECSLCode := ECSLCodeTxt;
        CreateNoSeries.InitBaseSeries(ECSLCode, ECSLCode, ECSLDescription, ECSLStart, ECSLEnd, '', '', 1);
        VATReportCode := VATReportCodeTxt;
        CreateNoSeries.InitBaseSeries(VATReportCode, VATReportCode, VATReportDescription, VATReportStart, VATReportEnd, '', '', 1);
        VATReturnPeriodCode := VATReturnPeriodCodeTxt;
        CreateNoSeries.InitBaseSeries(
          VATReturnPeriodCode, VATReturnPeriodCode, VATReturnPeriodDescTxt, VATReturnPeriodStartTxt, VATReturnPeriodEndTxt, '', '', 1);

        VATReportSetup.Get();

        NoSeries.Get(ECSLCode);
        VATReportSetup.Validate("No. Series", NoSeries.Code);

        NoSeries.Get(VATReportCode);
        VATReportSetup.Validate("VAT Return No. Series", NoSeries.Code);

        NoSeries.Get(VATReturnPeriodCode);
        VATReportSetup.Validate("VAT Return Period No. Series", NoSeries.Code);

        VATReportSetup.Modify();
    end;
}

