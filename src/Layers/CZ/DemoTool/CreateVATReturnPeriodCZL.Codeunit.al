codeunit 163534 "Create VAT Return Period CZL"
{

    trigger OnRun()
    begin
        InsertData(MakeAdjustments.AdjustDate(19030101D), MakeAdjustments.AdjustDate(19041231D));
    end;

    var
        VATReturnPeriod: Record "VAT Return Period";
        MakeAdjustments: Codeunit "Make Adjustments";

    procedure InsertData(StartingDate: Date; EndingDate: Date)
    begin
        while StartingDate <= EndingDate do begin
            VATReturnPeriod.Init();
            VATReturnPeriod.Validate("No.", '');
            VATReturnPeriod.Validate("Start Date", StartingDate);
            VATReturnPeriod.Validate("End Date", CalcDate('<1M-1D>', StartingDate));
            VATReturnPeriod.Validate("Due Date", CalcDate('<1M+24D>', StartingDate));
            VATReturnPeriod.Insert(true);
            StartingDate := CalcDate('<1M>', StartingDate);
        end;
    end;
}