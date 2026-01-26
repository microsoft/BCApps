codeunit 120554 "Create FA Depr. Setups IN"
{

    trigger OnRun()
    begin
        CreateFAAccountingPeriod();
        ModifyDefaultDepreciationBook();
        InsertDepreciationBookIncomeTax();
        CreateFABlocks();
    end;

    var
        XINCOMETAX: Label 'INCOME TAX', Locked = true;
        XIncomeTaxBook: Label 'Income Tax Book', Locked = true;
        XTANGIBLE: Label 'TANGIBLE', Locked = true;
        XINTANGIBLE: Label 'INTANGIBLE', Locked = true;
        XBLOCK01: Label 'BLOCK 01', Locked = true;
        XBLOCK02: Label 'BLOCK 02', Locked = true;
        XBLOCK03: Label 'BLOCK 03', Locked = true;
        XBLOCK04: Label 'BLOCK 04', Locked = true;
        XBLOCK05: Label 'BLOCK 05', Locked = true;
        XBLOCK06: Label 'BLOCK 06', Locked = true;
        XBLOCK07: Label 'BLOCK 07', Locked = true;
        XBLOCK08: Label 'BLOCK 08', Locked = true;
        XBLOCK09: Label 'BLOCK 09', Locked = true;
        XBLOCK10: Label 'BLOCK 10', Locked = true;
        XBLOCK11: Label 'BLOCK 11', Locked = true;
        XBLOCK12: Label 'BLOCK 12', Locked = true;
        XBLOCK13: Label 'BLOCK 13', Locked = true;
        XBLOCK14: Label 'BLOCK 14', Locked = true;
        XBLOCK15: Label 'BLOCK 15', Locked = true;
        XBLOCK16: Label 'BLOCK 16', Locked = true;
        XBLOCK17: Label 'BLOCK 17', Locked = true;
        XBLOCK18: Label 'BLOCK 18', Locked = true;
        XBLOCK19: Label 'BLOCK 19', Locked = true;

    local procedure CreateFAAccountingPeriod()
    var
        CA: Codeunit "Make Adjustments";
        StartDate: Date;
        EndDate: Date;
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

        For Year := StaringYear to EndingYear do begin
            StartDate := DMY2Date(1, 4, Year);
            EndDate := DMY2Date(31, 3, (Year + 1));
            InsertDataFAAccPeriod(StartDate, EndDate);
        end;
    end;

    local procedure InsertDataFAAccPeriod("Starting Date": Date; "Ending Date": Date)
    var
        FAAccountingPeriodIncTax: Record "FA Accounting Period Inc. Tax";
        YearStartDate: Date;
    begin
        YearStartDate := "Starting Date";
        while "Starting Date" <= "Ending Date" do begin
            FAAccountingPeriodIncTax.Init();
            FAAccountingPeriodIncTax.Validate("Starting Date", "Starting Date");
            if (Date2DMY("Starting Date", 1) = 1) and
               (Date2DMY("Starting Date", 2) = 4)
            then
                FAAccountingPeriodIncTax."New Fiscal Year" := true;
            FAAccountingPeriodIncTax.Name := FORMAT(FAAccountingPeriodIncTax."Starting Date", 0, '<Month Text>');
            FAAccountingPeriodIncTax.Insert();
            "Starting Date" := CalcDate('<1M>', "Starting Date");
        end;
    end;

    local procedure ModifyDefaultDepreciationBook()
    var
        FASetup: Record "FA Setup";
        DepreciationBook: Record "Depreciation Book";
    begin
        FASetup.Get();
        if DepreciationBook.Get(FASetup."Default Depr. Book") then begin
            DepreciationBook."No. of Days Non Seasonal" := 240;
            DepreciationBook."No. of Days Seasonal" := 180;
            DepreciationBook.Modify();
        end;
    end;

    local procedure InsertDepreciationBookIncomeTax()
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        DepreciationBook.Init();
        DepreciationBook.Code := XINCOMETAX;
        DepreciationBook.Description := XIncomeTaxBook;
        DepreciationBook."Disposal Calculation Method" := DepreciationBook."Disposal Calculation Method"::Net;
        DepreciationBook."Use Same FA+G/L Posting Dates" := true;
        DepreciationBook."Use FA Ledger Check" := true;
        DepreciationBook."FA Book Type" := DepreciationBook."FA Book Type"::"Income Tax";
        DepreciationBook."Depr. Threshold Days" := 180;
        DepreciationBook."Depr. Reduction %" := 50;
        DepreciationBook.Insert(true);
    end;

    local procedure CreateFABlocks()
    begin
        InsertDataFABlock(XTANGIBLE, XBLOCK01, 'Residential buildings', 5, 0);
        InsertDataFABlock(XTANGIBLE, XBLOCK02, 'Office,Factory,Godowns,Hotels', 10, 0);
        InsertDataFABlock(XTANGIBLE, XBLOCK03, 'Wooden Structures,', 100, 0);
        InsertDataFABlock(XTANGIBLE, XBLOCK04, 'Furniture', 10, 0);
        InsertDataFABlock(XTANGIBLE, XBLOCK05, 'Plant and Machinery', 15, 20);
        InsertDataFABlock(XTANGIBLE, XBLOCK06, 'Ocean going ships,Vessels', 20, 0);
        InsertDataFABlock(XTANGIBLE, XBLOCK07, 'Buses,taxies on hire,Lorries', 30, 0);
        InsertDataFABlock(XTANGIBLE, XBLOCK08, 'Plant and machinery Aeroplanes', 40, 0);
        InsertDataFABlock(XTANGIBLE, XBLOCK09, 'Containers made of glass', 50, 0);
        InsertDataFABlock(XTANGIBLE, XBLOCK10, 'Computers including softwares', 60, 0);
        InsertDataFABlock(XTANGIBLE, XBLOCK11, 'Energy saving devices', 80, 0);
        InsertDataFABlock(XTANGIBLE, XBLOCK12, 'Air pollution control equipm..', 100, 0);

        InsertDataFABlock(XINTANGIBLE, XBLOCK13, 'Know-how', 25, 0);
        InsertDataFABlock(XINTANGIBLE, XBLOCK14, 'Patents', 25, 0);
        InsertDataFABlock(XINTANGIBLE, XBLOCK15, 'Copy rights', 25, 0);
        InsertDataFABlock(XINTANGIBLE, XBLOCK16, 'Trade marks', 25, 0);
        InsertDataFABlock(XINTANGIBLE, XBLOCK17, 'Licences', 25, 0);
        InsertDataFABlock(XINTANGIBLE, XBLOCK18, 'Franchises', 25, 0);
        InsertDataFABlock(XINTANGIBLE, XBLOCK19, 'Other rights', 25, 0);
    end;

    local procedure InsertDataFABlock(FAClassCode: Code[10]; FABlockCode: Code[10]; Description: Text[30]; Depr: Decimal; AddlDepr: Decimal)
    var
        FixedAssetBlock: Record "Fixed Asset Block";
    begin
        if not FixedAssetBlock.Get(FAClassCode, FABlockCode) then begin
            FixedAssetBlock.Init();
            FixedAssetBlock."FA Class Code" := FAClassCode;
            FixedAssetBlock.Code := FABlockCode;
            FixedAssetBlock.Description := Description;
            FixedAssetBlock."Depreciation %" := Depr;
            FixedAssetBlock."Add. Depreciation %" := AddlDepr;
            FixedAssetBlock.Insert(true);
        end;
    end;
}
