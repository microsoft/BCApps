#if not CLEAN28
codeunit 163529 "Create VAT Period CZL"
{
    ObsoleteState = Pending;
    ObsoleteTag = '28.0';
    ObsoleteReason = 'Replaced by Create VAT Return Period codeunit.';

    trigger OnRun()
    begin
        InsertData(MakeAdjustments.AdjustDate(19010101D), MakeAdjustments.AdjustDate(19040101D));
    end;

    var
        VATPeriodCZL: Record "VAT Period CZL";
        MakeAdjustments: Codeunit "Make Adjustments";

    procedure InsertData(StartingDate: Date; EndingDate: Date)
    begin
        while StartingDate <= EndingDate do begin
            VATPeriodCZL.Init();
            VATPeriodCZL.Validate("Starting Date", StartingDate);
            if (Date2DMY(StartingDate, 1) = 1) and (Date2DMY(StartingDate, 2) = 1) then
                VATPeriodCZL."New VAT Year" := true;
            VATPeriodCZL.Insert();
            StartingDate := CalcDate('<1M>', StartingDate);
        end;
    end;
}
#endif