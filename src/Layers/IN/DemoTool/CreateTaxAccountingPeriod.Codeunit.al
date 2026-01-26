codeunit 120538 "Create Tax Accounting Period"
{
    trigger OnRun()
    var
        Year: Integer;
        StaringYear: Integer;
        EndingYear: Integer;
        PeriodStartDate: Date;
        PeriodEndDate: Date;
    begin
        PeriodStartDate := CA.AdjustDate(19010101D);
        PeriodEndDate := CA.AdjustDate(19041201D);
        StaringYear := Date2DMY(PeriodStartDate, 3);
        EndingYear := Date2DMY(PeriodEndDate, 3);

        CreateTaxTypeSetup();
        DemoDataSetup.Get();

        For Year := StaringYear to EndingYear do begin
            StartDate := DMY2Date(1, 4, Year);
            EndDate := DMY2Date(31, 3, (Year + 1));
            InsertData('GST', StartDate, EndDate);
            InsertData('TDS/TCS', StartDate, EndDate);
        end;
        UpdateGSTCreditMemoLockPeriod('GST');
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        TaxAccountPeriod: Record "Tax Accounting Period";
        CA: Codeunit "Make Adjustments";
        StartDate: Date;
        EndDate: Date;

    procedure InsertData(TaxTypeCode: Code[20]; "Starting Date": Date; "Ending Date": Date)
    var
        YearStartDate: Date;
    begin
        YearStartDate := "Starting Date";
        while "Starting Date" <= "Ending Date" do begin
            TaxAccountPeriod.Init();
            TaxAccountPeriod."Tax Type Code" := TaxTypeCode;
            TaxAccountPeriod.Validate("Starting Date", "Starting Date");
            if (Date2DMY("Starting Date", 1) = 1) and
               (Date2DMY("Starting Date", 2) = 4)
            then
                TaxAccountPeriod."New Fiscal Year" := true;
            TaxAccountPeriod.Name := FORMAT(TaxAccountPeriod."Starting Date", 0, '<Month Text>');
            TaxAccountPeriod."Ending Date" := CalcDate('<CM>', TaxAccountPeriod."Starting Date");
            case Date2DMY("Starting Date", 2) of
                4, 5, 6:
                    TaxAccountPeriod.Quarter := 'Q1';
                7, 8, 9:
                    TaxAccountPeriod.Quarter := 'Q2';
                10, 11, 12:
                    TaxAccountPeriod.Quarter := 'Q3';
                1, 2, 3:
                    TaxAccountPeriod.Quarter := 'Q4';
            end;
            TaxAccountPeriod."Financial Year" := Strsubstno('%1-%2', Date2DMY(YearStartDate, 3), Date2DMY("Ending Date", 3));
            TaxAccountPeriod.Insert();
            "Starting Date" := CalcDate('<1M>', "Starting Date");
        end;
    end;

    local procedure UpdateGSTCreditMemoLockPeriod(TaxTypeCode: Code[20])
    var
        TaxAccPeriod: Record "Tax Accounting Period";
    begin
        if TaxTypeCode = 'GST' then begin
            TaxAccountPeriod.SetRange("Tax Type Code", TaxTypeCode);
            if TaxAccountPeriod.FindSet() then
                repeat
                    if TaxAccountPeriod.Quarter in ['Q1', 'Q2'] then begin
                        TaxAccPeriod.Reset();
                        TaxAccPeriod.SetRange("Tax Type Code", TaxTypeCode);
                        TaxAccPeriod.SetRange("Financial Year", TaxAccountPeriod."Financial Year");
                        TaxAccPeriod.SetRange(Quarter, 'Q2');
                        if TaxAccPeriod.FindLast() then begin
                            TaxAccountPeriod."Credit Memo Locking Date" := TaxAccPeriod."Ending Date";
                            TaxAccountPeriod.Modify();
                        end;
                    end;
                    if TaxAccountPeriod.Quarter in ['Q3', 'Q4'] then begin
                        TaxAccPeriod.Reset();
                        TaxAccPeriod.SetRange("Tax Type Code", TaxTypeCode);
                        TaxAccPeriod.SetRange("Financial Year", TaxAccountPeriod."Financial Year");
                        TaxAccPeriod.SetRange(Quarter, 'Q4');
                        if TaxAccPeriod.FindLast() then begin
                            TaxAccountPeriod."Credit Memo Locking Date" := TaxAccPeriod."Ending Date";
                            TaxAccountPeriod.Modify();
                        end;
                    end;
                until TaxAccountPeriod.Next() = 0;
        end;
    end;

    procedure CreateTaxTypeSetup()
    var
        TCSSetup: Record "TCS Setup";
        TDSSetup: Record "TDS Setup";
        GSTSetup: Record "GST Setup";
    begin
        if TCSSetup.Get() then begin
            TCSSetup."Tax Type" := 'TCS';
            TCSSetup.Modify();
        end else begin
            TCSSetup.Init();
            TCSSetup."Tax Type" := 'TCS';
            TCSSetup.Insert();
        end;

        if TDSSetup.Get() then begin
            TDSSetup."Tax Type" := 'TDS';
            TDSSetup.Modify();
        end else begin
            TDSSetup.Init();
            TDSSetup."Tax Type" := 'TDS';
            TDSSetup.Insert();
        end;

        if GSTSetup.Get() then begin
            GSTSetup."GST Tax Type" := 'GST';
            GSTSetup."Cess Tax Type" := 'GST CESS';
            GSTSetup.Modify();
        end else begin
            GSTSetup.Init();
            GSTSetup."GST Tax Type" := 'GST';
            GSTSetup."Cess Tax Type" := 'GST CESS';
            GSTSetup.Insert();
        end;
    end;
}
