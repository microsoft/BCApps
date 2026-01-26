codeunit 120555 "Create FA With Depr. Book IN"
{
    trigger OnRun()
    begin
        CreateFixedAssets();
        CreateFixedAssetDepreciationBooks();
        CreateFixedAssetShifts();
    end;

    var
        FASetup: Record "FA Setup";
        XCOMPANY: Label 'COMPANY', Locked = true;
        XINCOMETAX: Label 'INCOME TAX', Locked = true;
        XFA000100: Label 'FA000100', Locked = true;
        XMotorcar: Label 'Motor Car', Locked = true;
        XTANGIBLE: Label 'TANGIBLE', Locked = true;
        XMACHINERY: Label 'MACHINERY', Locked = true;
        XBLUE: Label 'BLUE', Locked = true;
        XBLOCK05: Label 'BLOCK 05', Locked = true;
        XFA000110: Label 'FA000110', Locked = true;
        XMachine: Label 'Machinery', Locked = true;

    local procedure CreateFixedAssets()
    begin
        FASetup.Get();
        InsertDataFA(XFA000100, XMotorcar, XTANGIBLE, XMACHINERY, XBLUE, XBLOCK05, true);
        InsertDataFA(XFA000110, XMachine, XTANGIBLE, XMACHINERY, XBLUE, XBLOCK05, false);
        UpdateFASetupLastNoUsed(FASetup."Fixed Asset Nos.", XFA000110);
    end;

    local procedure InsertDataFA(No: Code[20]; Description: Text[30]; FAClassCode: Code[10]; FASubclassCode: Code[10]; FALocationCode: Code[10]; FABlocCode: Code[10]; AddlDep: Boolean)
    var
        FixedAsset: Record "Fixed Asset";
    begin
        FixedAsset.Init();
        FixedAsset."No." := No;
        FixedAsset.Description := Description;
        FixedAsset."Search Description" := Description;
        FixedAsset.Validate("FA Class Code", FAClassCode);
        FixedAsset.Validate("FA Subclass Code", FASubclassCode);
        FixedAsset.Validate("FA Location Code", FALocationCode);
        FixedAsset.Validate("FA Block Code", FABlocCode);
        FixedAsset.Validate("Add. Depr. Applicable", AddlDep);
        FixedAsset.Validate("GST Credit", FixedAsset."GST Credit"::Availment);
        FixedAsset.Insert(true);
    end;

    local procedure CreateFixedAssetDepreciationBooks()
    var
        DeprMethod: Enum "Depreciation Method";
        FABookType: Enum "Fixed Asset Book Type";
    begin
        InsertDataFADeprBook(XFA000100, XCOMPANY, XMACHINERY, XBLOCK05, DeprMethod::"Straight-Line", 20210401D, 10, 120, 0, 20310331D, FABookType::" ");
        InsertDataFADeprBook(XFA000100, XINCOMETAX, XMACHINERY, XBLOCK05, DeprMethod::"Declining-Balance 1", 20210401D, 0, 0, 15, 0D, FABookType::"Income Tax");

        InsertDataFADeprBook(XFA000110, XCOMPANY, XMACHINERY, XBLOCK05, DeprMethod::"Straight-Line", 20210401D, 0, 0, 0, 0D, FABookType::" ");
        InsertDataFADeprBook(XFA000110, XINCOMETAX, XMACHINERY, XBLOCK05, DeprMethod::"Declining-Balance 1", 20210401D, 0, 0, 15, 0D, FABookType::"Income Tax");
    end;

    local procedure InsertDataFADeprBook(
        No: Code[20];
        DeprBookCode: Code[10];
        FAPostingGroup: Code[20];
        FABlockCode: Code[10];
        DeprMethod: Enum "Depreciation Method";
        DeprStartDate: Date;
        DeprYear: Decimal;
        DeprMonth: Decimal;
        DeclBal: Decimal;
        DeprEndDate: Date;
        FABookType: Enum "Fixed Asset Book Type")
    var
        FADeprBook: Record "FA Depreciation Book";
    begin
        FADeprBook.Init();
        FADeprBook.Validate("FA No.", No);
        FADeprBook.Validate("Depreciation Book Code", DeprBookCode);
        FADeprBook.Validate("FA Posting Group", FAPostingGroup);
        FADeprBook.Validate("FA Block Code", FABlockCode);
        FADeprBook.Validate("Depreciation Method", DeprMethod);
        FADeprBook."Depreciation Starting Date" := DeprStartDate;
        FADeprBook."No. of Depreciation Years" := DeprYear;
        FADeprBook."No. of Depreciation Months" := DeprMonth;
        FADeprBook."Declining-Balance %" := DeclBal;
        FADeprBook."Depreciation Ending Date" := DeprEndDate;
        FADeprBook."Use FA Ledger Check" := true;
        FADeprBook."FA Book Type" := FABookType;
        FADeprBook.Insert(true);
    end;

    local procedure CreateFixedAssetShifts()
    var
        DeprMethod: Enum "Depreciation Method";
        ShiftType: Enum "Shift Type";
        IndstryType: Enum "Industry Type";
    begin
        InsertDataFAShift(XFA000110, XCOMPANY, 10000, XMACHINERY, DeprMethod::"Straight-Line", 20210401D, 10, 0.5, 6, 20210930D, ShiftType::Double, IndstryType::Seasonal);
        InsertDataFAShift(XFA000110, XCOMPANY, 20000, XMACHINERY, DeprMethod::"Straight-Line", 20211001D, 20, 0.5, 6, 20220331D, ShiftType::Triple, IndstryType::"Non Seasonal");
    end;

    local procedure InsertDataFAShift(
        No: Code[20];
        DeprBookCode: Code[10];
        LineNo: Integer;
        FAPostingGroup: Code[20];
        DeprMethod: Enum "Depreciation Method";
        DeprStartDate: Date;
        StrLine: Decimal;
        DeprYear: Decimal;
        DeprMonth: Decimal;
        DeprEndDate: Date;
        ShiftType: Enum "Shift Type";
        IndstryType: Enum "Industry Type")
    var
        FAShift: Record "Fixed Asset Shift";
    begin
        FAShift.Init();
        FAShift.Validate("FA No.", No);
        FAShift.Validate("Depreciation Book Code", DeprBookCode);
        FAShift.Validate("Line No.", LineNo);
        FAShift.Validate("Fixed Asset Posting Group", FAPostingGroup);
        FAShift.Validate("Depreciation Method", DeprMethod);
        FAShift."Depreciation Starting Date" := DeprStartDate;
        FAShift."Straight-Line %" := StrLine;
        FAShift."No. of Depreciation Years" := DeprYear;
        FAShift."No. of Depreciation Months" := DeprMonth;
        FAShift."Depreciation ending Date" := DeprEndDate;
        FAShift."Shift Type" := ShiftType;
        FAShift."Industry Type" := IndstryType;
        FAShift."Use FA Ledger Check" := true;
        FAShift.Insert(true);
    end;

    local procedure UpdateFASetupLastNoUsed(NoSeriesCode: Code[20]; LastNoUsed: Code[20])
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        if NoSeriesLine.Get(NoSeriesCode, 10000) then begin
            NoSeriesLine."Last No. Used" := LastNoUsed;
            NoSeriesLine.Modify();
        end;
    end;
}