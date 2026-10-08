codeunit 144526 "ERM Create Tax Calc. Item"
{
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        LibraryTaxAcc: Codeunit "Library - Tax Accounting";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryRandom: Codeunit "Library - Random";
        WrongFieldValueErr: Label 'Wrong value of field %1 in table %2.';

    [Test]
    [HandlerFunctions('TaxCalcItemEntriesHandler,TaxItemRegister13Handler,TaxItemRegister14Handler,TaxItemRegister23Handler,TaxItemRegister24Handler')]
    [Scope('OnPrem')]
    procedure CalculateTaxItemEntries()
    var
        Dimension: Record Dimension;
        DimValue: Record "Dimension Value";
        TaxRegSection: Record "Tax Register Section";
        TaxRegister: Record "Tax Register";
        TaxCalcItemEntry: Record "Tax Calc. Item Entry";
        TaxCalcDimCorrFilter: Record "Tax Calc. Dim. Corr. Filter";
        ItemLedgEntry: Record "Item Ledger Entry";
        CostTaxAmount: Decimal;
    begin
        TaxRegSection.FindFirst();
        LibraryTaxAcc.CreateTaxReg(TaxRegister, TaxRegSection.Code, DATABASE::"Tax Register Accumulation", 0);
        LibraryTaxAcc.CreateTaxCalcDimCorrFilter(TaxCalcDimCorrFilter, TaxRegSection.Code);
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimValue, Dimension.Code);
        LibraryTaxAcc.CreateTaxCalcDimFilter(TaxRegister."Section Code", TaxRegister."No.", 0, DimValue);

        CreateTaxCalcHeader(TaxRegister);
        CreateTaxCalcCorrespEntries(TaxRegSection.Code, TaxCalcDimCorrFilter."Corresp. Entry No.");

        ItemLedgEntry.SetRange("Posting Date", TaxRegSection."Starting Date", TaxRegSection."Ending Date");
        ItemLedgEntry.FindFirst();
        ItemLedgEntry.CalcFields("Cost Amount (Actual)");
        CostTaxAmount := CreateValueEntyWithExcludeCostForTA(ItemLedgEntry);

        TaxCalcItemEntry."Section Code" := TaxRegSection.Code;
        TaxCalcItemEntry."Starting Date" := TaxRegSection."Starting Date";
        TaxCalcItemEntry."Ending Date" := TaxRegSection."Ending Date";
        CODEUNIT.Run(CODEUNIT::"Create Tax Calc. Item Entries", TaxCalcItemEntry);

        VerifyTaxCalcItemEntry(ItemLedgEntry."Entry No.", ItemLedgEntry."Cost Amount (Actual)", CostTaxAmount);
        VerifyTaxCalcItemEntriesPage(TaxRegSection.Code);
        VerifyTaxItemRegister13Page(TaxRegSection.Code);
        VerifyTaxItemRegister14Page(TaxRegSection.Code);
        VerifyTaxItemRegister23Page(TaxRegSection.Code);
        VerifyTaxItemRegister24Page(TaxRegSection.Code);
    end;

    local procedure CreateTaxCalcHeader(TaxRegister: Record "Tax Register")
    var
        TaxCalcHeader: Record "Tax Calc. Header";
    begin
        TaxCalcHeader.Init();
        TaxCalcHeader."Section Code" := TaxRegister."Section Code";
        TaxCalcHeader."No." := TaxRegister."No.";
        TaxCalcHeader."Register ID" := LibraryUtility.GenerateGUID();
        TaxCalcHeader.Insert();
    end;

    local procedure CreateTaxCalcCorrespEntries(SectionCode: Code[10]; EntryNo: Integer)
    var
        InvPostSetup: Record "Inventory Posting Setup";
        TaxCalcCorrespEntry: Record "Tax Calc. G/L Corr. Entry";
    begin
        InvPostSetup.FindSet();
        repeat
            TaxCalcCorrespEntry.Init();
            TaxCalcCorrespEntry."Section Code" := SectionCode;
            TaxCalcCorrespEntry."Debit Account No." := InvPostSetup."Inventory Account";
            TaxCalcCorrespEntry."Credit Account No." := '';
            TaxCalcCorrespEntry."Register Type" := TaxCalcCorrespEntry."Register Type"::Item;
            TaxCalcCorrespEntry."Entry No." := EntryNo;
            if not TaxCalcCorrespEntry.Find() then
                TaxCalcCorrespEntry.Insert();
        until InvPostSetup.Next() = 0;
    end;

    local procedure CreateValueEntyWithExcludeCostForTA(ItemLedgEntry: Record "Item Ledger Entry"): Decimal
    var
        ItemCharge: Record "Item Charge";
        ValueEntry: Record "Value Entry";
        RecRef: RecordRef;
    begin
        ValueEntry.Init();
        RecRef.GetTable(ValueEntry);
        ValueEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, ValueEntry.FieldNo("Entry No."));
        ValueEntry."Item No." := ItemLedgEntry."Item No.";
        ValueEntry."Posting Date" := ItemLedgEntry."Posting Date";
        ValueEntry."Entry Type" := ValueEntry."Entry Type"::"Direct Cost";
        ValueEntry."Item Ledger Entry Type" := ItemLedgEntry."Entry Type";
        ValueEntry."Item Ledger Entry No." := ItemLedgEntry."Entry No.";
        LibraryInventory.CreateItemCharge(ItemCharge);
        ItemCharge."Exclude Cost for TA" := true;
        ItemCharge.Modify();
        ValueEntry."Item Charge No." := ItemCharge."No.";
        ValueEntry."Cost Amount (Actual)" := LibraryRandom.RandDec(100, 2);
        ValueEntry."Cost Posted to G/L" := ValueEntry."Cost Amount (Actual)";
        ValueEntry.Insert();
        exit(ValueEntry."Cost Amount (Actual)");
    end;

    local procedure VerifyTaxCalcItemEntry(EntryNo: Integer; CostAmount: Decimal; CostTaxAmount: Decimal)
    var
        TaxCalcItemEntry: Record "Tax Calc. Item Entry";
    begin
        TaxCalcItemEntry.SetRange("Ledger Entry No.", EntryNo);
        TaxCalcItemEntry.FindFirst();
        Assert.AreEqual(
          CostAmount + CostTaxAmount, TaxCalcItemEntry."Amount (Actual)",
          StrSubstNo(WrongFieldValueErr, TaxCalcItemEntry.TableCaption(), TaxCalcItemEntry.FieldCaption("Amount (Actual)")));
        Assert.AreEqual(
          CostAmount, TaxCalcItemEntry."Amount (Tax)",
          StrSubstNo(WrongFieldValueErr, TaxCalcItemEntry.TableCaption(), TaxCalcItemEntry.FieldCaption("Amount (Tax)")));
    end;

    local procedure VerifyTaxCalcItemEntriesPage(SectionCode: Code[10])
    var
        TaxCalcItemEntry: Record "Tax Calc. Item Entry";
        TaxCalcItemEntriesPage: Page "Tax Calc. Item Entries";
    begin
        TaxCalcItemEntry.SetRange("Section Code", SectionCode);
        TaxCalcItemEntriesPage.SetTableView(TaxCalcItemEntry);
        TaxCalcItemEntriesPage.Run();
        Clear(TaxCalcItemEntriesPage);
    end;

    local procedure VerifyTaxItemRegister13Page(SectionCode: Code[10])
    var
        TaxRegisterItemEntry: Record "Tax Register Item Entry";
        TaxRegister13ItemPage: Page "Tax Register (1.3) Item";
    begin
        TaxRegisterItemEntry.SetRange("Section Code", SectionCode);
        TaxRegister13ItemPage.SetTableView(TaxRegisterItemEntry);
        TaxRegister13ItemPage.Run();
        Clear(TaxRegister13ItemPage);
    end;

    local procedure VerifyTaxItemRegister14Page(SectionCode: Code[10])
    var
        TaxRegisterItemEntry: Record "Tax Register Item Entry";
        TaxRegister14ItemPage: Page "Tax Register (1.4) Item";
    begin
        TaxRegisterItemEntry.SetRange("Section Code", SectionCode);
        TaxRegister14ItemPage.SetTableView(TaxRegisterItemEntry);
        TaxRegister14ItemPage.Run();
        Clear(TaxRegister14ItemPage);
    end;

    local procedure VerifyTaxItemRegister23Page(SectionCode: Code[10])
    var
        TaxRegisterItemEntry: Record "Tax Register Item Entry";
        TaxRegister23ItemPage: Page "Tax Register (2.3) Item";
    begin
        TaxRegisterItemEntry.SetRange("Section Code", SectionCode);
        TaxRegister23ItemPage.SetTableView(TaxRegisterItemEntry);
        TaxRegister23ItemPage.Run();
        Clear(TaxRegister23ItemPage);
    end;

    local procedure VerifyTaxItemRegister24Page(SectionCode: Code[10])
    var
        TaxRegisterItemEntry: Record "Tax Register Item Entry";
        TaxRegister24ItemPage: Page "Tax Register (2.4) Item";
    begin
        TaxRegisterItemEntry.SetRange("Section Code", SectionCode);
        TaxRegister24ItemPage.SetTableView(TaxRegisterItemEntry);
        TaxRegister24ItemPage.Run();
        Clear(TaxRegister24ItemPage);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure TaxCalcItemEntriesHandler(var TaxCalcItemEntries: TestPage "Tax Calc. Item Entries")
    begin
        TaxCalcItemEntries.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure TaxItemRegister13Handler(var TaxRegister13Item: TestPage "Tax Register (1.3) Item")
    begin
        TaxRegister13Item.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure TaxItemRegister14Handler(var TaxRegister14Item: TestPage "Tax Register (1.4) Item")
    begin
        TaxRegister14Item.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure TaxItemRegister23Handler(var TaxRegister23Item: TestPage "Tax Register (2.3) Item")
    begin
        TaxRegister23Item.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure TaxItemRegister24Handler(var TaxRegister24Item: TestPage "Tax Register (2.4) Item")
    begin
        TaxRegister24Item.OK().Invoke();
    end;
}

