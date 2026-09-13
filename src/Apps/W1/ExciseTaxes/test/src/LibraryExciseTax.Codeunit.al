// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExciseTaxes;

using Microsoft.ExciseTaxes;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;

codeunit 148350 "Library - Excise Tax"
{
    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERM: Codeunit "Library - ERM";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        SourceSpecificRateMismatchLbl: Label 'Expected source-specific rate %1, but got %2', Comment = '%1 = Expected Rate, %2 = Actual Rate';

    procedure CreateExciseTaxType(TaxCode: Code[20]; TaxBasis: Enum "Excise Tax Basis"; IsEnabled: Boolean): Record "Excise Tax Type"
    var
        ExciseTaxType: Record "Excise Tax Type";
    begin
        if TaxCode = '' then
            TaxCode := GetTaxTypeCode();

        ExciseTaxType.Init();
        ExciseTaxType.Code := TaxCode;
        ExciseTaxType.Description := CopyStr(LibraryUtility.GenerateRandomText(100), 1, 100);
        ExciseTaxType."Tax Basis" := TaxBasis;
        ExciseTaxType.Enabled := IsEnabled;
        ExciseTaxType."Report Caption" := CopyStr(LibraryUtility.GenerateRandomText(50), 1, 50);
        ExciseTaxType.Insert(true);
        exit(ExciseTaxType);
    end;

    procedure CreateExciseTaxEntryPermission(TaxTypeCode: Code[20]; EntryType: Enum "Excise Entry Type"; IsAllowed: Boolean)
    var
        ExciseTaxEntryPermission: Record "Excise Tax Entry Permission";
    begin
        if TaxTypeCode = '' then
            TaxTypeCode := CopyStr(LibraryRandom.RandText(20), 1, 20);
        ExciseTaxEntryPermission.Init();
        ExciseTaxEntryPermission."Excise Tax Type Code" := TaxTypeCode;
        ExciseTaxEntryPermission."Excise Entry Type" := EntryType;
        ExciseTaxEntryPermission.Allowed := IsAllowed;
        ExciseTaxEntryPermission.Insert(true);
    end;

    procedure CreateExciseTaxItemRate(TaxTypeCode: Code[20]; ItemNo: Code[20]; ExciseDuty: Decimal; EffectiveFromDate: Date; RateDescription: Text[100]): Record "Excise Tax Rate"
    var
        ExciseTaxRate: Record "Excise Tax Rate";
    begin
        ExciseTaxRate.Init();
        ExciseTaxRate."Excise Tax Type Code" := TaxTypeCode;
        ExciseTaxRate."Source Type" := "Excise Source Type"::Item;
        ExciseTaxRate."Source No." := ItemNo;
        ExciseTaxRate."Excise Duty" := ExciseDuty;
        ExciseTaxRate."Effective From Date" := EffectiveFromDate;
        ExciseTaxRate.Description := RateDescription;
        ExciseTaxRate.Insert(true);
        exit(ExciseTaxRate);
    end;

    procedure CreateExciseTaxFARate(TaxTypeCode: Code[20]; FANo: Code[20]; ExciseDuty: Decimal; EffectiveFromDate: Date; RateDescription: Text[100]): Record "Excise Tax Rate"
    var
        ExciseTaxRate: Record "Excise Tax Rate";
    begin
        ExciseTaxRate.Init();
        ExciseTaxRate."Excise Tax Type Code" := TaxTypeCode;
        ExciseTaxRate."Source Type" := "Excise Source Type"::"Fixed Asset";
        ExciseTaxRate."Source No." := FANo;
        ExciseTaxRate."Excise Duty" := ExciseDuty;
        ExciseTaxRate."Effective From Date" := EffectiveFromDate;
        ExciseTaxRate.Description := RateDescription;
        ExciseTaxRate.Insert(true);
        exit(ExciseTaxRate);
    end;

    procedure CreateExciseTaxItemFARate(TaxTypeCode: Code[20]; SourceType: Enum "Excise Source Type"; SourceNo: Code[20]; ExciseDuty: Decimal; EffectiveFromDate: Date; RateDescription: Text[100]): Record "Excise Tax Rate"
    var
        ExciseTaxRate: Record "Excise Tax Rate";
    begin
        ExciseTaxRate.Init();
        ExciseTaxRate."Excise Tax Type Code" := TaxTypeCode;
        ExciseTaxRate."Source Type" := SourceType;
        ExciseTaxRate."Source No." := SourceNo;
        ExciseTaxRate."Excise Duty" := ExciseDuty;
        ExciseTaxRate."Effective From Date" := EffectiveFromDate;
        ExciseTaxRate.Description := RateDescription;
        ExciseTaxRate.Insert(true);
        exit(ExciseTaxRate);
    end;

    procedure CreateExciseTaxRate(TaxTypeCode: Code[20]; SourceType: Enum "Excise Source Type"; SourceNo: Code[20]; ItemCategoryCode: Code[20]; CalculationType: Enum "Excise Calculation Type"; ExciseDuty: Decimal; ExciseDutyPct: Decimal; EffectiveFromDate: Date): Record "Excise Tax Rate"
    var
        ExciseTaxRate: Record "Excise Tax Rate";
    begin
        ExciseTaxRate.Init();
        ExciseTaxRate."Excise Tax Type Code" := TaxTypeCode;
        ExciseTaxRate."Source Type" := SourceType;
        ExciseTaxRate."Source No." := SourceNo;
        ExciseTaxRate."Item Category Code" := ItemCategoryCode;
        ExciseTaxRate."Excise Calculation Type" := CalculationType;
        ExciseTaxRate."Excise Duty" := ExciseDuty;
        ExciseTaxRate."Excise Duty %" := ExciseDutyPct;
        ExciseTaxRate."Effective From Date" := EffectiveFromDate;
        ExciseTaxRate.Insert(true);
        exit(ExciseTaxRate);
    end;

    procedure CreateItemCategory(): Code[20]
    var
        ItemCategory: Record "Item Category";
    begin
        ItemCategory.Init();
        ItemCategory.Code := LibraryUtility.GenerateRandomCode(ItemCategory.FieldNo(Code), Database::"Item Category");
        ItemCategory.Insert(true);
        exit(ItemCategory.Code);
    end;

    procedure CreateItemWithExciseTax(var Item: Record Item; TaxTypeCode: Code[20])
    begin
        LibraryInventory.CreateItem(Item);
        CreateItemExciseTax(Item."No.", TaxTypeCode);
    end;

    procedure CreateItemExciseTax(ItemNo: Code[20]; TaxTypeCode: Code[20]): Record "Item Excise Tax"
    var
        ItemExciseTax: Record "Item Excise Tax";
        UnitOfMeasure: Record "Unit of Measure";
    begin
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        ItemExciseTax.Init();
        ItemExciseTax."Item No." := ItemNo;
        ItemExciseTax.Validate("Excise Tax Type Code", TaxTypeCode);
        ItemExciseTax.Validate("Quantity for Excise Tax", LibraryRandom.RandDec(1, 3));
        ItemExciseTax.Validate("Excise Unit of Measure Code", UnitOfMeasure.Code);
        ItemExciseTax.Insert(true);
        exit(ItemExciseTax);
    end;

    procedure CreateFixedAssetWithExciseTax(var FixedAsset: Record "Fixed Asset"; TaxTypeCode: Code[20])
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        FixedAsset.Validate("Excise Tax Type", TaxTypeCode);
        FixedAsset.Validate("Quantity for Excise Tax", LibraryRandom.RandDec(1, 3));
        FixedAsset.Validate("Excise Unit of Measure Code", UnitOfMeasure.Code);
        FixedAsset.Modify(true);
    end;

    procedure SetupTaxType(ExciseTaxBasis: Enum "Excise Tax Basis"): Code[20]
    var
        GLAccount: Record "G/L Account";
        PurchaseRate: Decimal;
        TaxTypeCode: Code[20];
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        PurchaseRate := LibraryRandom.RandDec(7, 2);
        TaxTypeCode := GetTaxTypeCode();
        CreateExciseTaxType(TaxTypeCode, ExciseTaxBasis, true);
        CreateExciseTaxEntryPermission(TaxTypeCode, "Excise Entry Type"::Purchase, true);
        CreateExciseTaxEntryPermission(TaxTypeCode, "Excise Entry Type"::Sale, true);
        CreateExciseTaxEntryPermission(TaxTypeCode, "Excise Entry Type"::"Positive Adjmt.", true);
        CreateExciseTaxEntryPermission(TaxTypeCode, "Excise Entry Type"::"Negative Adjmt.", true);
        CreateExciseTaxEntryPermission(TaxTypeCode, "Excise Entry Type"::Output, true);
        CreateExciseTaxEntryPermission(TaxTypeCode, "Excise Entry Type"::"Assembly Output", true);

        CreateExciseTaxItemFARate(TaxTypeCode, "Excise Source Type"::Item, '', PurchaseRate, CalcDate('<-CY>', WorkDate()), '');
        CreateExciseTaxItemFARate(TaxTypeCode, "Excise Source Type"::"Fixed Asset", '', PurchaseRate, CalcDate('<-CY>', WorkDate()), '');

        exit(TaxTypeCode);
    end;

    local procedure GetTaxTypeCode(): Code[20]
    var
        ExciseTaxType: Record "Excise Tax Type";
    begin
        exit(LibraryUtility.GenerateRandomCode(ExciseTaxType.FieldNo(Code), DATABASE::"Excise Tax Type"));
    end;

    procedure CalculateExpectedTaxAmount(ExciseDuty: Decimal; Quantity: Decimal; QtyForExciseTax: Decimal): Decimal
    begin
        exit((ExciseDuty / 100) * Quantity * QtyForExciseTax);
    end;

    procedure GetSourceSpecificRate(TaxTypeCode: Code[20]; SourceType: Enum "Excise Source Type"; SourceNo: Code[20]; EffectiveDate: Date): Decimal
    var
        ExciseTaxRate: Record "Excise Tax Rate";
    begin
        ExciseTaxRate.SetRange("Excise Tax Type Code", TaxTypeCode);
        ExciseTaxRate.SetRange("Source Type", SourceType);
        ExciseTaxRate.SetRange("Source No.", SourceNo);
        ExciseTaxRate.SetFilter("Effective From Date", '<=%1', EffectiveDate);
        if ExciseTaxRate.FindLast() then
            exit(ExciseTaxRate."Excise Duty");
        exit(0);
    end;

    procedure GetGeneralRate(TaxTypeCode: Code[20]): Decimal
    var
        ExciseTaxRate: Record "Excise Tax Rate";
    begin
        ExciseTaxRate.SetRange("Excise Tax Type Code", TaxTypeCode);
        ExciseTaxRate.SetRange("Source Type", "Excise Source Type"::" ");
        ExciseTaxRate.SetRange("Source No.", '');
        if ExciseTaxRate.FindFirst() then
            exit(ExciseTaxRate."Excise Duty");
        exit(0);
    end;

    procedure GetHierarchicalTaxRate(TaxTypeCode: Code[20]; SourceType: Enum "Excise Source Type"; SourceNo: Code[20]; EntryType: Enum "Excise Entry Type"; EffectiveDate: Date): Decimal
    var
        SourceSpecificRate: Decimal;
    begin
        SourceSpecificRate := GetSourceSpecificRate(TaxTypeCode, SourceType, SourceNo, EffectiveDate);
        if SourceSpecificRate <> 0 then
            exit(SourceSpecificRate);

        exit(GetGeneralRate(TaxTypeCode));
    end;

    procedure VerifySourceSpecificRateTakesPriority(TaxTypeCode: Code[20]; SourceType: Enum "Excise Source Type"; SourceNo: Code[20]; EntryType: Enum "Excise Entry Type"; EffectiveDate: Date; ExpectedSourceRate: Decimal)
    var
        ActualRate: Decimal;
    begin
        ActualRate := GetHierarchicalTaxRate(TaxTypeCode, SourceType, SourceNo, EntryType, EffectiveDate);
        if ActualRate <> ExpectedSourceRate then
            Error(SourceSpecificRateMismatchLbl, ExpectedSourceRate, ActualRate);
    end;

    procedure CleanupExciseTaxData()
    var
        ExciseTaxType: Record "Excise Tax Type";
        ExciseTaxEntryPermission: Record "Excise Tax Entry Permission";
        ExciseTaxRate: Record "Excise Tax Rate";
        ItemExciseTax: Record "Item Excise Tax";
    begin
        ExciseTaxType.DeleteAll();
        ExciseTaxEntryPermission.DeleteAll();
        ExciseTaxRate.DeleteAll();
        ItemExciseTax.DeleteAll();
    end;
}
