codeunit 163531 "Create Tax Depr. Group CZF"
{

    trigger OnRun()
    begin
        InsertData('1_R', WorkDate(), X1R, 0, 3, 0, 0, 20, 40, 33.3, 0, 0, 0, 0);
        InsertData('1_R10', WorkDate(), X1R10, 0, 3, 0, 0, 30, 35, 33.3, 0, 0, 0, 0);
        InsertData('1_R15', WorkDate(), X1R15, 0, 3, 0, 0, 35, 32.5, 33.3, 0, 0, 0, 0);
        InsertData('1_R20', WorkDate(), X1R20, 0, 3, 0, 0, 40, 30, 33.3, 0, 0, 0, 0);
        InsertData('1_Z', WorkDate(), X1Z, 1, 3, 0, 0, 0, 0, 0, 3, 4, 3, 0);
        InsertData('1_Z10', WorkDate(), X1Z10, 1, 3, 0, 0, 0, 0, 0, 3, 4, 3, 10);
        InsertData('1_Z15', WorkDate(), X1Z15, 1, 3, 0, 0, 0, 0, 0, 3, 4, 3, 15);
        InsertData('1_Z20', WorkDate(), X1Z20, 1, 3, 0, 0, 0, 0, 0, 3, 4, 3, 20);
        InsertData('2_R', WorkDate(), X2R, 0, 5, 0, 0, 11, 22.25, 20, 0, 0, 0, 0);
        InsertData('2_R10', WorkDate(), X2R10, 0, 5, 0, 0, 21, 19.75, 20, 0, 0, 0, 0);
        InsertData('2_R15', WorkDate(), X2R15, 0, 5, 0, 0, 26, 18.5, 20, 0, 0, 0, 0);
        InsertData('2_R20', WorkDate(), X2R20, 0, 5, 0, 0, 31, 17.25, 20, 0, 0, 0, 0);
        InsertData('2_Z', WorkDate(), X2Z, 1, 5, 0, 0, 0, 0, 0, 5, 6, 5, 0);
        InsertData('2_Z10', WorkDate(), X2Z10, 1, 5, 0, 0, 0, 0, 0, 5, 6, 5, 10);
        InsertData('2_Z15', WorkDate(), X2Z15, 1, 5, 0, 0, 0, 0, 0, 5, 6, 5, 15);
        InsertData('2_Z20', WorkDate(), X2Z20, 1, 5, 0, 0, 0, 0, 0, 5, 6, 5, 20);
        InsertData('3_R', WorkDate(), X3R, 0, 10, 0, 0, 5.5, 10.5, 10, 0, 0, 0, 0);
        InsertData('3_R10', WorkDate(), X3R10, 0, 10, 0, 0, 15.4, 9.4, 10, 0, 0, 0, 0);
        InsertData('3_R15', WorkDate(), X3R15, 0, 10, 0, 0, 19, 9, 10, 0, 0, 0, 0);
        InsertData('3_R20', WorkDate(), X3R20, 0, 10, 0, 0, 24.4, 8.4, 10, 0, 0, 0, 0);
        InsertData('3_Z', WorkDate(), X3Z, 1, 10, 0, 0, 0, 0, 0, 10, 11, 10, 0);
        InsertData('3_Z10', WorkDate(), X3Z10, 1, 10, 0, 0, 0, 0, 0, 10, 11, 10, 10);
        InsertData('3_Z15', WorkDate(), X3Z15, 1, 10, 0, 0, 0, 0, 0, 10, 11, 10, 15);
        InsertData('3_Z20', WorkDate(), X3Z20, 1, 10, 0, 0, 0, 0, 0, 10, 11, 10, 20);
        InsertData('4_R', WorkDate(), X4R, 0, 20, 0, 0, 2.15, 5.15, 5, 0, 0, 0, 0);
        InsertData('4_Z', WorkDate(), X4Z, 1, 20, 0, 0, 0, 0, 0, 20, 21, 20, 0);
        InsertData('5_R', WorkDate(), X5R, 0, 30, 0, 0, 1.4, 3.4, 3.4, 0, 0, 0, 0);
        InsertData('5_Z', WorkDate(), X5Z, 1, 30, 0, 0, 0, 0, 0, 30, 31, 30, 0);
        InsertData('6_R', WorkDate(), X6R, 0, 50, 0, 0, 1.02, 2.02, 2, 0, 0, 0, 0);
        InsertData('6_Z', WorkDate(), X6Z, 1, 50, 0, 0, 0, 0, 0, 50, 51, 50, 0);
        InsertData('N_18', WorkDate(), XN18, 2, 0, 18, 9, 0, 0, 0, 0, 0, 0, 0);
        InsertData('N_36', WorkDate(), XN36, 2, 0, 36, 18, 0, 0, 0, 0, 0, 0, 0);
        InsertData('N_60', WorkDate(), XN60, 2, 0, 60, 36, 0, 0, 0, 0, 0, 0, 0);
        InsertData('N_72', WorkDate(), XN72, 2, 0, 72, 36, 0, 0, 0, 0, 0, 0, 0);
    end;

    var
        TaxDepreciationGroupCZF: Record "Tax Depreciation Group CZF";
        X1R: Label '1st Tax Depreciation Group - Straight-Line Depreciation';
        X1R10: Label '1st Tax Depreciation Group - Straight-Line Depreciation, 10% Increased Depreciation 1st Year';
        X1R15: Label '1st Tax Depreciation Group - Straight-Line Depreciation, 15% Increased Depreciation 1st Year';
        X1R20: Label '1st Tax Depreciation Group - Straight-Line Depreciation, 20% Increased Depreciation 1st Year';
        X1Z: Label '1st Tax Depreciation Group - Declining-Balance Depreciation';
        X1Z10: Label '1st Tax Depreciation Group - Declining-Balance Depreciation, 10% Increased Depreciation 1st Year';
        X1Z15: Label '1st Tax Depreciation Group - Declining-Balance Depreciation, 15% Increased Depreciation 1st Year';
        X1Z20: Label '1st Tax Depreciation Group - Declining-Balance Depreciation, 20% Increased Depreciation 1st Year';
        X2R: Label '2nd Tax Depreciation Group - Straight-Line Depreciation';
        X2R10: Label '2nd Tax Depreciation Group - Straight-Line Depreciation, 10% Increased Depreciation 1st Year';
        X2R15: Label '2nd Tax Depreciation Group - Straight-Line Depreciation, 15% Increased Depreciation 1st Year';
        X2R20: Label '2nd Tax Depreciation Group - Straight-Line Depreciation, 20% Increased Depreciation 1st Year';
        X2Z: Label '2nd Tax Depreciation Group - Declining-Balance Depreciation';
        X2Z10: Label '2nd Tax Depreciation Group - Declining-Balance Depreciation, 10% Increased Depreciation 1st Year';
        X2Z15: Label '2nd Tax Depreciation Group - Declining-Balance Depreciation, 15% Increased Depreciation 1st Year';
        X2Z20: Label '2nd Tax Depreciation Group - Declining-Balance Depreciation, 20% Increased Depreciation 1st Year';
        X3R: Label '3rd Tax Depreciation Group - Straight-Line Depreciation';
        X3R10: Label '3rd Tax Depreciation Group - Straight-Line Depreciation, 10% Increased Depreciation 1st Year';
        X3R15: Label '3rd Tax Depreciation Group - Straight-Line Depreciation, 15% Increased Depreciation 1st Year';
        X3R20: Label '3rd Tax Depreciation Group - Straight-Line Depreciation, 20% Increased Depreciation 1st Year';
        X3Z: Label '3rd Tax Depreciation Group - Declining-Balance Depreciation';
        X3Z10: Label '3rd Tax Depreciation Group - Declining-Balance Depreciation, 10% Increased Depreciation 1st Year';
        X3Z15: Label '3rd Tax Depreciation Group - Declining-Balance Depreciation, 15% Increased Depreciation 1st Year';
        X3Z20: Label '3rd Tax Depreciation Group - Declining-Balance Depreciation, 20% Increased Depreciation 1st Year';
        X4R: Label '4th Tax Depreciation Group - Straight-Line Depreciation';
        X4Z: Label '4th Tax Depreciation Group - Declining-Balance Depreciation';
        X5R: Label '5th Tax Depreciation Group - Straight-Line Depreciation';
        X5Z: Label '5th Tax Depreciation Group - Declining-Balance Depreciation';
        X6R: Label '6th Tax Depreciation Group - Straight-Line Depreciation';
        X6Z: Label '6th Tax Depreciation Group - Declining-Balance Depreciation';
        XN18: Label 'Intangible Fixed Assets - Straight-Line 18 Months';
        XN36: Label 'Intangible Fixed Assets - Straight-Line 36 Months';
        XN60: Label 'Intangible Fixed Assets - Straight-Line 60 Months';
        XN72: Label 'Intangible Fixed Assets - Straight-Line 72 Months';

    procedure InsertData("Code": Code[10]; "Starting Date": Date; Description: Text[100]; "Depreciation Type": Option; "No. of Depreciation Years": Integer; "No. of Depreciation Months": Decimal; "Min. Months After Appreciation": Decimal; "Straight First Year": Decimal; "Straight Next Years": Decimal; "Straight Appreciation": Decimal; "Declining First Year": Decimal; "Declining Next Years": Decimal; "Declining Appreciation": Decimal; "Declining Depr. Increase %": Decimal)
    begin
        TaxDepreciationGroupCZF.Init();
        TaxDepreciationGroupCZF.Validate(Code, Code);
        TaxDepreciationGroupCZF.Validate("Starting Date", "Starting Date");
        TaxDepreciationGroupCZF.Validate(Description, Description);
        TaxDepreciationGroupCZF.Validate("Depreciation Type", "Depreciation Type");

        if "No. of Depreciation Years" <> 0 then
            TaxDepreciationGroupCZF.Validate("No. of Depreciation Years", "No. of Depreciation Years")
        else
            TaxDepreciationGroupCZF.Validate("No. of Depreciation Months", "No. of Depreciation Months");

        TaxDepreciationGroupCZF.Validate("Min. Months After Appreciation", "Min. Months After Appreciation");
        TaxDepreciationGroupCZF.Validate("Straight First Year", "Straight First Year");
        TaxDepreciationGroupCZF.Validate("Straight Next Years", "Straight Next Years");
        TaxDepreciationGroupCZF.Validate("Straight Appreciation", "Straight Appreciation");
        TaxDepreciationGroupCZF.Validate("Declining First Year", "Declining First Year");
        TaxDepreciationGroupCZF.Validate("Declining Next Years", "Declining Next Years");
        TaxDepreciationGroupCZF.Validate("Declining Appreciation", "Declining Appreciation");
        TaxDepreciationGroupCZF.Validate("Declining Depr. Increase %", "Declining Depr. Increase %");
        TaxDepreciationGroupCZF.Insert();
    end;
}

