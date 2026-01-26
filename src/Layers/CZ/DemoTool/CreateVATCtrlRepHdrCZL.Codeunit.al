codeunit 163536 "Create VAT Ctrl. Rep. Hdr. CZL"
{

    trigger OnRun()
    begin
        StartDate := MakeAdjustments.AdjustDate(19030101D);

        InsertData(Date2DMY(StartDate, 3), 0, 1);
    end;

    var
        CreateVATStatementName: Codeunit "Create VAT Statement Name";
        MakeAdjustments: Codeunit "Make Adjustments";
        StartDate: Date;

    procedure InsertData(Year: Integer; ReportPeriod: Option; PeriodNo: Integer)
    var
        VATControlReportHeaderCZL: Record "VAT Ctrl. Report Header CZL";
    begin
        VATControlReportHeaderCZL.Init();
        VATControlReportHeaderCZL.Validate("VAT Statement Template Name", CreateVATStatementName.GetVAT('XVAT'));
        VATControlReportHeaderCZL.Validate("VAT Statement Name", CreateVATStatementName.GetVAT('XVAT19'));
        VATControlReportHeaderCZL.Insert(true);
        VATControlReportHeaderCZL.Validate(Year, Year);
        VATControlReportHeaderCZL.Validate("Period No.", PeriodNo);
        VATControlReportHeaderCZL.Validate("Report Period", ReportPeriod);
        VATControlReportHeaderCZL.Validate("Created Date", VATControlReportHeaderCZL."Start Date");
        VATControlReportHeaderCZL.Description := StrSubstNo('%1/%2', PeriodNo, Year);
        VATControlReportHeaderCZL.Modify();
    end;
}
