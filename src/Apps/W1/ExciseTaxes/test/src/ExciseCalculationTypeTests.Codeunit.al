// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExciseTaxes;

using Microsoft.ExciseTaxes;
using Microsoft.Inventory.Item;
using Microsoft.Sustainability.ExciseTax;

codeunit 148352 "Excise Calculation Type Tests"
{
    Subtype = Test;
    TestType = Uncategorized;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryExciseTax: Codeunit "Library - Excise Tax";
        LibraryRandom: Codeunit "Library - Random";
        IsInitialized: Boolean;
        TaxAmountMismatchLbl: Label 'Unexpected excise tax amount on the journal line';
        CalculationTypeMismatchLbl: Label 'Unexpected excise calculation type on the journal line';
        DutyRateMismatchLbl: Label 'Unexpected excise duty rate';
        DutyPercentMismatchLbl: Label 'Unexpected excise duty percentage on the journal line';
        SourceTypeMismatchLbl: Label 'Unexpected source type on the resolved excise duty rate';
        ItemCategoryMismatchLbl: Label 'Unexpected item category on the excise duty rate';
        RateNotFoundLbl: Label 'No effective excise duty rate was resolved';

    [Test]
    procedure SpecificRateCalculatesTaxFromQuantity()
    var
        Item: Record Item;
        ExciseJnlLine: Record "Sust. Excise Jnl. Line";
        ExciseTaxBasis: Enum "Excise Tax Basis";
        TaxTypeCode: Code[20];
        ExciseDuty: Decimal;
        SourceQty: Decimal;
    begin
        // [SCENARIO 626305] A specific rate charges the excise duty per unit and ignores the taxable amount.
        Initialize();
        ExciseDuty := LibraryRandom.RandDecInRange(1, 10, 2);
        SourceQty := LibraryRandom.RandIntInRange(2, 20);

        // [GIVEN] An item with an excise tax type that has a specific rate.
        TaxTypeCode := LibraryExciseTax.SetupTaxType(ExciseTaxBasis::Weight);
        LibraryExciseTax.CreateItemWithExciseTax(Item, TaxTypeCode);
        LibraryExciseTax.CreateExciseTaxRate(TaxTypeCode, "Excise Source Type"::Item, Item."No.", '', "Excise Calculation Type"::"Specific per Unit", ExciseDuty, 0, CalcDate('<-CY>', WorkDate()));

        // [WHEN] An excise journal line is created for the item and a taxable amount is entered.
        CreateExciseJournalLine(ExciseJnlLine, TaxTypeCode, Item."No.", SourceQty, LibraryRandom.RandDecInRange(100, 1000, 2));

        // [THEN] The tax amount only reflects the specific component.
        Assert.AreEqual("Excise Calculation Type"::"Specific per Unit", ExciseJnlLine."Excise Calculation Type", CalculationTypeMismatchLbl);
        Assert.AreEqual(ExciseDuty * SourceQty * ExciseJnlLine."Quantity for Excise Tax", ExciseJnlLine."Tax Amount", TaxAmountMismatchLbl);
    end;

    [Test]
    procedure AdValoremRateCalculatesTaxFromTaxableAmount()
    var
        Item: Record Item;
        ExciseJnlLine: Record "Sust. Excise Jnl. Line";
        ExciseTaxBasis: Enum "Excise Tax Basis";
        TaxTypeCode: Code[20];
        ExciseDutyPct: Decimal;
        TaxableAmount: Decimal;
    begin
        // [SCENARIO 626305] An ad valorem rate charges a percentage of the taxable amount.
        Initialize();
        ExciseDutyPct := LibraryRandom.RandDecInRange(1, 50, 2);
        TaxableAmount := LibraryRandom.RandDecInRange(100, 1000, 2);

        // [GIVEN] An item with an excise tax type that has an ad valorem rate.
        TaxTypeCode := LibraryExciseTax.SetupTaxType(ExciseTaxBasis::Weight);
        LibraryExciseTax.CreateItemWithExciseTax(Item, TaxTypeCode);
        LibraryExciseTax.CreateExciseTaxRate(TaxTypeCode, "Excise Source Type"::Item, Item."No.", '', "Excise Calculation Type"::"Ad valorem", 0, ExciseDutyPct, CalcDate('<-CY>', WorkDate()));

        // [WHEN] An excise journal line is created for the item with a taxable amount.
        CreateExciseJournalLine(ExciseJnlLine, TaxTypeCode, Item."No.", LibraryRandom.RandIntInRange(2, 20), TaxableAmount);

        // [THEN] The rate is applied as a percentage of the taxable amount and the per unit duty stays empty.
        Assert.AreEqual("Excise Calculation Type"::"Ad valorem", ExciseJnlLine."Excise Calculation Type", CalculationTypeMismatchLbl);
        Assert.AreEqual(0, ExciseJnlLine."Excise Duty", DutyRateMismatchLbl);
        Assert.AreEqual(ExciseDutyPct, ExciseJnlLine."Excise Duty %", DutyPercentMismatchLbl);
        Assert.AreEqual(ExciseDutyPct / 100 * TaxableAmount, ExciseJnlLine."Tax Amount", TaxAmountMismatchLbl);
    end;

    [Test]
    procedure HybridRateAddsSpecificAndAdValoremComponents()
    var
        Item: Record Item;
        ExciseJnlLine: Record "Sust. Excise Jnl. Line";
        ExciseTaxBasis: Enum "Excise Tax Basis";
        TaxTypeCode: Code[20];
        ExciseDuty: Decimal;
        ExciseDutyPct: Decimal;
        SourceQty: Decimal;
        TaxableAmount: Decimal;
    begin
        // [SCENARIO 626305] A hybrid rate charges both a per unit duty and a percentage of the taxable amount.
        Initialize();
        ExciseDuty := LibraryRandom.RandDecInRange(1, 10, 2);
        ExciseDutyPct := LibraryRandom.RandDecInRange(1, 50, 2);
        SourceQty := LibraryRandom.RandIntInRange(2, 20);
        TaxableAmount := LibraryRandom.RandDecInRange(100, 1000, 2);

        // [GIVEN] An item with an excise tax type that has a hybrid rate.
        TaxTypeCode := LibraryExciseTax.SetupTaxType(ExciseTaxBasis::Weight);
        LibraryExciseTax.CreateItemWithExciseTax(Item, TaxTypeCode);
        LibraryExciseTax.CreateExciseTaxRate(TaxTypeCode, "Excise Source Type"::Item, Item."No.", '', "Excise Calculation Type"::Hybrid, ExciseDuty, ExciseDutyPct, CalcDate('<-CY>', WorkDate()));

        // [WHEN] An excise journal line is created for the item with a taxable amount.
        CreateExciseJournalLine(ExciseJnlLine, TaxTypeCode, Item."No.", SourceQty, TaxableAmount);

        // [THEN] The tax amount is the sum of both components.
        Assert.AreEqual("Excise Calculation Type"::Hybrid, ExciseJnlLine."Excise Calculation Type", CalculationTypeMismatchLbl);
        Assert.AreEqual(
            ExciseDuty * SourceQty * ExciseJnlLine."Quantity for Excise Tax" + ExciseDutyPct / 100 * TaxableAmount,
            ExciseJnlLine."Tax Amount",
            TaxAmountMismatchLbl);
    end;

    [Test]
    procedure ItemCategoryRateIsAppliedToItemInThatCategory()
    var
        Item: Record Item;
        ExciseJnlLine: Record "Sust. Excise Jnl. Line";
        ExciseTaxBasis: Enum "Excise Tax Basis";
        TaxTypeCode: Code[20];
        ItemCategoryCode: Code[20];
        CategoryDutyPct: Decimal;
        TaxableAmount: Decimal;
    begin
        // [SCENARIO 626305] An item without its own rate is charged with the rate of its item category.
        Initialize();
        CategoryDutyPct := LibraryRandom.RandDecInRange(1, 50, 2);
        TaxableAmount := LibraryRandom.RandDecInRange(100, 1000, 2);

        // [GIVEN] An item that belongs to an item category which has an ad valorem rate.
        TaxTypeCode := LibraryExciseTax.SetupTaxType(ExciseTaxBasis::Weight);
        ItemCategoryCode := LibraryExciseTax.CreateItemCategory();
        LibraryExciseTax.CreateItemWithExciseTax(Item, TaxTypeCode);
        Item.Validate("Item Category Code", ItemCategoryCode);
        Item.Modify(true);
        LibraryExciseTax.CreateExciseTaxRate(TaxTypeCode, "Excise Source Type"::Item, '', ItemCategoryCode, "Excise Calculation Type"::"Ad valorem", 0, CategoryDutyPct, CalcDate('<-CY>', WorkDate()));

        // [WHEN] An excise journal line is created for the item.
        CreateExciseJournalLine(ExciseJnlLine, TaxTypeCode, Item."No.", LibraryRandom.RandIntInRange(2, 20), TaxableAmount);

        // [THEN] The category rate is used instead of the rate that applies to all items.
        Assert.AreEqual("Excise Calculation Type"::"Ad valorem", ExciseJnlLine."Excise Calculation Type", CalculationTypeMismatchLbl);
        Assert.AreEqual(CategoryDutyPct, ExciseJnlLine."Excise Duty %", DutyPercentMismatchLbl);
        Assert.AreEqual(CategoryDutyPct / 100 * TaxableAmount, ExciseJnlLine."Tax Amount", TaxAmountMismatchLbl);
    end;

    [Test]
    procedure ItemCategoryRateTakesPriorityOverGeneralRate()
    var
        Item: Record Item;
        ExciseTaxRate: Record "Excise Tax Rate";
        ExciseTaxBasis: Enum "Excise Tax Basis";
        TaxTypeCode: Code[20];
        ItemCategoryCode: Code[20];
        CategoryDuty: Decimal;
    begin
        // [SCENARIO 626305] A rate defined for the item category wins over the rate that applies to all items.
        Initialize();
        CategoryDuty := LibraryRandom.RandDecInRange(20, 30, 2);

        // [GIVEN] A tax type with a rate for all items and an additional rate for one item category.
        TaxTypeCode := LibraryExciseTax.SetupTaxType(ExciseTaxBasis::Weight);
        ItemCategoryCode := LibraryExciseTax.CreateItemCategory();
        LibraryExciseTax.CreateItemWithExciseTax(Item, TaxTypeCode);
        LibraryExciseTax.CreateExciseTaxRate(TaxTypeCode, "Excise Source Type"::Item, '', ItemCategoryCode, "Excise Calculation Type"::"Specific per Unit", CategoryDuty, 0, CalcDate('<-CY>', WorkDate()));

        // [WHEN] The effective rate is resolved for an item in that category.
        Assert.IsTrue(ExciseTaxRate.GetEffectiveExciseRate(TaxTypeCode, "Excise Source Type"::Item, Item."No.", ItemCategoryCode, WorkDate()), RateNotFoundLbl);

        // [THEN] The category rate is returned.
        Assert.AreEqual(CategoryDuty, ExciseTaxRate."Excise Duty", DutyRateMismatchLbl);
    end;

    [Test]
    procedure ItemRateTakesPriorityOverItemCategoryRate()
    var
        Item: Record Item;
        ExciseTaxRate: Record "Excise Tax Rate";
        ExciseTaxBasis: Enum "Excise Tax Basis";
        TaxTypeCode: Code[20];
        ItemCategoryCode: Code[20];
        ItemDuty: Decimal;
    begin
        // [SCENARIO 626305] A rate defined for a specific item wins over a rate defined for its item category.
        Initialize();
        ItemDuty := LibraryRandom.RandDecInRange(40, 50, 2);

        // [GIVEN] A tax type with a category rate and an item specific rate.
        TaxTypeCode := LibraryExciseTax.SetupTaxType(ExciseTaxBasis::Weight);
        ItemCategoryCode := LibraryExciseTax.CreateItemCategory();
        LibraryExciseTax.CreateItemWithExciseTax(Item, TaxTypeCode);
        LibraryExciseTax.CreateExciseTaxRate(TaxTypeCode, "Excise Source Type"::Item, '', ItemCategoryCode, "Excise Calculation Type"::"Specific per Unit", LibraryRandom.RandDecInRange(20, 30, 2), 0, CalcDate('<-CY>', WorkDate()));
        LibraryExciseTax.CreateExciseTaxRate(TaxTypeCode, "Excise Source Type"::Item, Item."No.", '', "Excise Calculation Type"::"Specific per Unit", ItemDuty, 0, CalcDate('<-CY>', WorkDate()));

        // [WHEN] The effective rate is resolved for that item in that category.
        Assert.IsTrue(ExciseTaxRate.GetEffectiveExciseRate(TaxTypeCode, "Excise Source Type"::Item, Item."No.", ItemCategoryCode, WorkDate()), RateNotFoundLbl);

        // [THEN] The item specific rate is returned.
        Assert.AreEqual(ItemDuty, ExciseTaxRate."Excise Duty", DutyRateMismatchLbl);
    end;

    [Test]
    procedure FixedAssetRateIgnoresItemCategoryRates()
    var
        ExciseTaxRate: Record "Excise Tax Rate";
        ExciseTaxBasis: Enum "Excise Tax Basis";
        TaxTypeCode: Code[20];
        ItemCategoryCode: Code[20];
    begin
        // [SCENARIO 626305] Item category rates never apply to fixed assets.
        Initialize();

        // [GIVEN] A tax type with an item category rate and a rate for all fixed assets.
        TaxTypeCode := LibraryExciseTax.SetupTaxType(ExciseTaxBasis::Weight);
        ItemCategoryCode := LibraryExciseTax.CreateItemCategory();
        LibraryExciseTax.CreateExciseTaxRate(TaxTypeCode, "Excise Source Type"::Item, '', ItemCategoryCode, "Excise Calculation Type"::"Specific per Unit", LibraryRandom.RandDecInRange(60, 70, 2), 0, CalcDate('<-CY>', WorkDate()));

        // [WHEN] The effective rate is resolved for a fixed asset, passing the category along.
        Assert.IsTrue(ExciseTaxRate.GetEffectiveExciseRate(TaxTypeCode, "Excise Source Type"::"Fixed Asset", '', ItemCategoryCode, WorkDate()), RateNotFoundLbl);

        // [THEN] The fixed asset rate is returned, not the category rate.
        Assert.AreEqual("Excise Source Type"::"Fixed Asset", ExciseTaxRate."Source Type", SourceTypeMismatchLbl);
        Assert.AreEqual('', ExciseTaxRate."Item Category Code", ItemCategoryMismatchLbl);
    end;

    [Test]
    procedure ChangingSourceTypeAwayFromItemClearsTheItemCategory()
    var
        ExciseTaxRate: Record "Excise Tax Rate";
        ExciseTaxBasis: Enum "Excise Tax Basis";
        TaxTypeCode: Code[20];
        ItemCategoryCode: Code[20];
    begin
        // [SCENARIO 626305] The item category is cleared automatically when the rate stops applying to items.
        Initialize();

        // [GIVEN] An item rate that applies to one item category.
        TaxTypeCode := LibraryExciseTax.SetupTaxType(ExciseTaxBasis::Weight);
        ItemCategoryCode := LibraryExciseTax.CreateItemCategory();
        ExciseTaxRate.Init();
        ExciseTaxRate."Excise Tax Type Code" := TaxTypeCode;
        ExciseTaxRate.Validate("Source Type", "Excise Source Type"::Item);
        ExciseTaxRate.Validate("Item Category Code", ItemCategoryCode);

        // [WHEN] The rate is changed to apply to fixed assets.
        ExciseTaxRate.Validate("Source Type", "Excise Source Type"::"Fixed Asset");

        // [THEN] The item category is cleared.
        Assert.AreEqual('', ExciseTaxRate."Item Category Code", ItemCategoryMismatchLbl);
    end;

    [Test]
    procedure ItemCategoryCodeIsNotAllowedForFixedAssetRates()
    var
        ExciseTaxRate: Record "Excise Tax Rate";
        ExciseTaxBasis: Enum "Excise Tax Basis";
        TaxTypeCode: Code[20];
        ItemCategoryCode: Code[20];
    begin
        // [SCENARIO 626305] An item category cannot be assigned to a fixed asset rate.
        Initialize();

        // [GIVEN] A rate for the fixed asset source type.
        TaxTypeCode := LibraryExciseTax.SetupTaxType(ExciseTaxBasis::Weight);
        ItemCategoryCode := LibraryExciseTax.CreateItemCategory();
        ExciseTaxRate.Init();
        ExciseTaxRate."Excise Tax Type Code" := TaxTypeCode;
        ExciseTaxRate.Validate("Source Type", "Excise Source Type"::"Fixed Asset");

        // [WHEN] An item category is entered.
        asserterror ExciseTaxRate.Validate("Item Category Code", ItemCategoryCode);

        // [THEN] The item category is rejected.
        Assert.ExpectedErrorCode('TestField');
    end;

    [Test]
    procedure ExciseDutyPercentIsNotAllowedForSpecificCalculationType()
    var
        ExciseTaxRate: Record "Excise Tax Rate";
        ExciseTaxBasis: Enum "Excise Tax Basis";
        TaxTypeCode: Code[20];
    begin
        // [SCENARIO 626305] A duty percentage cannot be set when the rate is calculated per unit.
        Initialize();

        // [GIVEN] A rate that is calculated per unit.
        TaxTypeCode := LibraryExciseTax.SetupTaxType(ExciseTaxBasis::Weight);
        ExciseTaxRate.Init();
        ExciseTaxRate."Excise Tax Type Code" := TaxTypeCode;
        ExciseTaxRate.Validate("Source Type", "Excise Source Type"::Item);
        ExciseTaxRate.Validate("Excise Calculation Type", "Excise Calculation Type"::"Specific per Unit");

        // [WHEN] A duty percentage is entered.
        asserterror ExciseTaxRate.Validate("Excise Duty %", LibraryRandom.RandDecInRange(1, 50, 2));

        // [THEN] The percentage is rejected.
        Assert.ExpectedError(ExciseTaxRate.FieldCaption("Excise Duty %"));
    end;

    [Test]
    procedure SwitchingToAdValoremClearsTheSpecificDutyRate()
    var
        ExciseTaxRate: Record "Excise Tax Rate";
        ExciseTaxBasis: Enum "Excise Tax Basis";
        TaxTypeCode: Code[20];
    begin
        // [SCENARIO 626305] Changing the calculation type clears the rate that no longer applies.
        Initialize();

        // [GIVEN] A rate with a per unit duty.
        TaxTypeCode := LibraryExciseTax.SetupTaxType(ExciseTaxBasis::Weight);
        ExciseTaxRate.Init();
        ExciseTaxRate."Excise Tax Type Code" := TaxTypeCode;
        ExciseTaxRate.Validate("Source Type", "Excise Source Type"::Item);
        ExciseTaxRate.Validate("Excise Duty", LibraryRandom.RandDecInRange(1, 10, 2));

        // [WHEN] The calculation type is changed to ad valorem.
        ExciseTaxRate.Validate("Excise Calculation Type", "Excise Calculation Type"::"Ad valorem");

        // [THEN] The per unit duty is cleared.
        Assert.AreEqual(0, ExciseTaxRate."Excise Duty", DutyRateMismatchLbl);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryExciseTax.CleanupExciseTaxData();

        if IsInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        IsInitialized := true;
    end;

    local procedure CreateExciseJournalLine(var ExciseJnlLine: Record "Sust. Excise Jnl. Line"; TaxTypeCode: Code[20]; ItemNo: Code[20]; SourceQty: Decimal; TaxableAmount: Decimal)
    var
        SustExciseJournalBatch: Record "Sust. Excise Journal Batch";
        SustainabilityExciseJournalMgt: Codeunit "Sust. Excise Journal Mgt.";
    begin
        SustExciseJournalBatch := SustainabilityExciseJournalMgt.GetASustainabilityJournalBatch();
        SustExciseJournalBatch.Validate(Type, SustExciseJournalBatch.Type::Excises);
        SustExciseJournalBatch.Validate("Excise Tax Type Filter", TaxTypeCode);
        SustExciseJournalBatch.Modify(true);

        ExciseJnlLine.Init();
        ExciseJnlLine."Journal Template Name" := SustExciseJournalBatch."Journal Template Name";
        ExciseJnlLine."Journal Batch Name" := SustExciseJournalBatch.Name;
        ExciseJnlLine."Line No." := 10000;
        ExciseJnlLine."Posting Date" := WorkDate();
        ExciseJnlLine.Validate("Excise Tax Type", TaxTypeCode);
        ExciseJnlLine.Validate("Source Type", ExciseJnlLine."Source Type"::Item);
        ExciseJnlLine.Validate("Source No.", ItemNo);
        ExciseJnlLine.Validate("Source Qty.", SourceQty);
        ExciseJnlLine.Validate("Excise Taxable Amount", TaxableAmount);
    end;
}

