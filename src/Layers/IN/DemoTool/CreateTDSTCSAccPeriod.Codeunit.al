codeunit 120542 "Create TDSTCS Acc. Period"
{
    trigger OnRun()

    begin
        DemoDataSetup.Get();
        InsertData('TDS/TCS', 20200401D, 20200430D, XFinancialYear, 'Q1', 'April', true, false, true);
        InsertData('TDS/TCS', 20200501D, 20200531D, XFinancialYear, 'Q1', 'May', false, false, false);
        InsertData('TDS/TCS', 20200601D, 20200630D, XFinancialYear, 'Q1', 'June', false, false, false);
        InsertData('TDS/TCS', 20200701D, 20200731D, XFinancialYear, 'Q2', 'July', false, false, false);
        InsertData('TDS/TCS', 20200801D, 20200831D, XFinancialYear, 'Q2', 'August', false, false, false);
        InsertData('TDS/TCS', 20200901D, 20200930D, XFinancialYear, 'Q2', 'September', false, false, false);
        InsertData('TDS/TCS', 20201001D, 20201031D, XFinancialYear, 'Q3', 'October', false, false, false);
        InsertData('TDS/TCS', 20201101D, 20201130D, XFinancialYear, 'Q3', 'November', false, false, false);
        InsertData('TDS/TCS', 20201201D, 20201231D, XFinancialYear, 'Q3', 'December', false, false, false);
        InsertData('TDS/TCS', 20210101D, 20210131D, XFinancialYear, 'Q4', 'January', false, false, false);
        InsertData('TDS/TCS', 20210201D, 20210228D, XFinancialYear, 'Q4', 'February', false, false, false);
        InsertData('TDS/TCS', 20210301D, 20210331D, XFinancialYear, 'Q4', 'March', false, false, false);
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        TaxAccountPeriod: Record "Tax Accounting Period";
        XFinancialYear: Label '2020-2021';



    procedure InsertData(
    TaxTypeCode: Code[10]; StatingDate: Date; EndDate: Date;
        FinancialYear: Code[10]; TaxQuarter: Code[10]; TaxName: Text[10]; NewFinYear: Boolean; Close: Boolean;
        DateLock: Boolean);
    begin
        DemoDataSetup.Get();
        TaxAccountPeriod.Init();
        TaxAccountPeriod."Tax Type Code" := TaxTypeCode;
        TaxAccountPeriod."Starting Date" := StatingDate;
        TaxAccountPeriod."Ending Date" := EndDate;
        TaxAccountPeriod."Financial Year" := FinancialYear;
        TaxAccountPeriod.Quarter := TaxQuarter;
        TaxAccountPeriod.Name := TaxName;
        TaxAccountPeriod."New Fiscal Year" := NewFinYear;
        TaxAccountPeriod.Closed := Close;
        TaxAccountPeriod."Date Locked" := DateLock;
        TaxAccountPeriod.Insert();
    end;
}