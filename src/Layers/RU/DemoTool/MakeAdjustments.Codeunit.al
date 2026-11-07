codeunit 101902 "Make Adjustments"
{

    trigger OnRun()
    begin
        // GenerateMap();
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";

    procedure Convert("Account No.": Code[20]): Code[20]
    begin
        exit("Account No.");
    end;

    // This Account is also used for Vendor and Customer posting grouppes
    procedure GetAdjustmentAccount(): Code[20]
    begin
        exit('999150');
    end;

    procedure AdjustDate(OriginalDate: Date): Date
    var
        TempDate: Date;
        WeekDay: Integer;
        MonthDay: Integer;
        Week: Integer;
        Month: Integer;
        Year: Integer;
    begin
        if DemoDataSetup.Get() then;
        if OriginalDate <> 0D then begin
            TempDate := CalcDate('<+92Y>', OriginalDate);
            WeekDay := Date2DWY(TempDate, 1);
            MonthDay := Date2DMY(TempDate, 1);
            Month := Date2DMY(TempDate, 2);
            Week := Date2DWY(TempDate, 2);
            Year := Date2DMY(TempDate, 3) + DemoDataSetup."Starting Year" - 1994;
            case Month of
                1, 3, 5, 7, 8, 10, 12:
                    if (MonthDay = 31) or (MonthDay = 1) then
                        exit(DMY2Date(MonthDay, Month, Year));
                2:
                    if (MonthDay = 28) or (MonthDay = 1) then
                        exit(DMY2Date(MonthDay, Month, Year));
                4, 6, 9, 11:
                    if (MonthDay = 30) or (MonthDay = 1) then
                        exit(DMY2Date(MonthDay, Month, Year));
            end;
            exit(DMY2Date(MonthDay, Month, Year));
        end;
        exit(0D);
    end;

    procedure VATCode("Code": Code[10]; Level: Integer): Code[10]
    begin
        DemoDataSetup.Get();
        case Level of
            0:
                exit(Code + '00');
            1:
                exit(Code + Format(DemoDataSetup."VAT Rate 1"));
            2:
                exit(Code + Format(DemoDataSetup."VAT Rate 2"));
        end;
    end;

    procedure VATText(Level: Integer): Text[30]
    begin
        DemoDataSetup.Get();
        case Level of
            0:
                exit('0%');
            1:
                exit(Format(DemoDataSetup."VAT Rate 1") + ' %');
            2:
                exit(Format(DemoDataSetup."VAT Rate 2") + ' %');
        end;
    end;

    procedure VATRate(Level: Integer): Decimal
    begin
        DemoDataSetup.Get();
        case Level of
            0:
                exit(0);
            1:
                exit(DemoDataSetup."VAT Rate 1");
            2:
                exit(DemoDataSetup."VAT Rate 2");
        end;
    end;
}

