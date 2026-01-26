codeunit 101254 "Create VAT Report Configs"
{

    trigger OnRun()
    var
        VATReportsConfiguration: Record "VAT Reports Configuration";
        VATReportSetup: Record "VAT Report Setup";
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

        VATReportsConfiguration.Init();
        VATReportsConfiguration."VAT Report Type" := VATReportsConfiguration."VAT Report Type"::"VAT Return";
        VATReportsConfiguration."VAT Report Version" := 'CZ';
        VATReportsConfiguration."Suggest Lines Codeunit ID" := Codeunit::"VAT Report Suggest Lines CZL";
        VATReportsConfiguration."Content Codeunit ID" := Codeunit::"VAT Report Export CZL";
        VATReportsConfiguration."Submission Codeunit ID" := Codeunit::"VAT Report Submit CZL";
        VATReportsConfiguration."Validate Codeunit ID" := Codeunit::"VAT Report Validate CZL";
        VATReportsConfiguration."VAT Statement Template" := CreateVATStatementTemplate.GetVATName();
        VATReportsConfiguration."VAT Statement Name" := CreateVATStatementName.GetVAT('XVAT19');
        VATReportsConfiguration.Insert();

        VATReportSetup.Get();
        VATReportSetup."Report Version" := VATReportsConfiguration."VAT Report Version";
        Evaluate(VATReportSetup."Period Reminder Calculation", '<5D>');
        VATReportSetup."Report VAT Note" := true;
        VATReportSetup.Modify();

        CreateReportNoSeries();
    end;

    var
        CreateNoSeries: Codeunit "Create No. Series";
        CreateVATStatementTemplate: Codeunit "Create VAT Statement Template";
        CreateVATStatementName: Codeunit "Create VAT Statement Name";
        MakeAdjustments: Codeunit "Make Adjustments";
        ECSLCodeTxt: Label 'ECSL', Locked = true;
        ECSLDescription: Label 'EC Sales List reports.';
        ECSLStart: Label 'ECSL-0001', Locked = true;
        ECSLEnd: Label 'ECSL-9999', Locked = true;
        VATReportCodeTxt: Label 'DPH-P', Locked = true;
        VATReportDescriptionTxt: Label 'VAT Returns';
        VATReportPrefixTxt: Label 'PDPH', Locked = true;
        VATReturnPeriodCodeTxt: Label 'DPH-O', Locked = true;
        VATReturnPeriodDescTxt: Label 'VAT Return Periods';
        VATReturnPeriodStartTxt: Label 'ODPH00001', Locked = true;
        VATReturnPeriodEndTxt: Label 'ODPH99999', Locked = true;

    local procedure CreateReportNoSeries()
    var
        VATReportSetup: Record "VAT Report Setup";
        NoSeries: Record "No. Series";
        ECSLCode: Code[20];
        StartingDate: Date;
        StartingNo: Code[20];
        EndingNo: Code[20];
    begin
        ECSLCode := ECSLCodeTxt;
        CreateNoSeries.InitBaseSeries(ECSLCode, ECSLCode, ECSLDescription, ECSLStart, ECSLEnd, '', '', 1);

        CreateNoSeries.InsertSeries(VATReportCodeTxt, VATReportDescriptionTxt, false);
        CreateNoSeries.InsertSeries(VATReturnPeriodCodeTxt, VATReturnPeriodDescTxt, false);

        StartingDate := MakeAdjustments.AdjustDate(19030101D);
        StartingNo := StrSubstNo('%1%2%3', VATReportPrefixTxt, Format(StartingDate, 0, '<Year>'), '01');
        EndingNo := StrSubstNo('%1%2%3', VATReportPrefixTxt, Format(StartingDate, 0, '<Year>'), '99');
        CreateNoSeries.InsertSeriesLine(VATReportCodeTxt, 10000, StartingDate, StartingNo, EndingNo, '', '', 1, "No. Series Implementation"::Normal);

        StartingDate := MakeAdjustments.AdjustDate(19040101D);
        StartingNo := StrSubstNo('%1%2%3', VATReportPrefixTxt, Format(StartingDate, 0, '<Year>'), '01');
        EndingNo := StrSubstNo('%1%2%3', VATReportPrefixTxt, Format(StartingDate, 0, '<Year>'), '99');
        CreateNoSeries.InsertSeriesLine(VATReportCodeTxt, 20000, StartingDate, StartingNo, EndingNo, '', '', 1, "No. Series Implementation"::Normal);

        CreateNoSeries.InsertSeriesLine(
            VATReturnPeriodCodeTxt, 10000, 0D, VATReturnPeriodStartTxt, VATReturnPeriodEndTxt, '', '', 1, "No. Series Implementation"::Normal);

        VATReportSetup.Get();

        NoSeries.Get(ECSLCode);
        VATReportSetup.Validate("No. Series", NoSeries.Code);

        NoSeries.Get(VATReportCodeTxt);
        VATReportSetup.Validate("VAT Return No. Series", NoSeries.Code);

        NoSeries.Get(VATReturnPeriodCodeTxt);
        VATReportSetup.Validate("VAT Return Period No. Series", NoSeries.Code);

        VATReportSetup.Modify();
    end;
}

