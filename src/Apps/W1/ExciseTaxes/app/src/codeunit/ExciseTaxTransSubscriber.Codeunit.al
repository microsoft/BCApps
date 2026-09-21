// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExciseTaxes;

using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Sustainability.ExciseTax;

codeunit 7413 "Excise Tax Trans Subscriber"
{
    [EventSubscriber(ObjectType::Table, Database::"Sust. Excise Taxes Trans. Log", OnAfterCopyFromSustainabilityExciseJnlLine, '', false, false)]
    local procedure OnAfterCopyFromSustainabilityExciseJnlLine(var SustExciseTaxesTransactionLog: Record "Sust. Excise Taxes Trans. Log"; SustainabilityExciseJnlLine: Record "Sust. Excise Jnl. Line")
    var
        ExciseTaxCalculation: Codeunit "Excise Tax Calculation";
    begin
        if not ExciseTaxCalculation.IsExciseTaxEntry(SustainabilityExciseJnlLine) then
            exit;

        SustExciseTaxesTransactionLog."Excise Tax Type" := SustainabilityExciseJnlLine."Excise Tax Type";
        SustExciseTaxesTransactionLog."Excise Duty" := SustainabilityExciseJnlLine."Excise Duty";
        SustExciseTaxesTransactionLog."Excise Calculation Type" := SustainabilityExciseJnlLine."Excise Calculation Type";
        SustExciseTaxesTransactionLog."Excise Duty %" := SustainabilityExciseJnlLine."Excise Duty %";
        SustExciseTaxesTransactionLog."Excise Taxable Amount" := SustainabilityExciseJnlLine."Excise Taxable Amount";
        SustExciseTaxesTransactionLog."Item Category Code" := SustainabilityExciseJnlLine."Item Category Code";
        SustExciseTaxesTransactionLog."Tax Amount" := SustainabilityExciseJnlLine."Tax Amount";
        SustExciseTaxesTransactionLog."Quantity for Excise Tax" := SustainabilityExciseJnlLine."Quantity for Excise Tax";
        SustExciseTaxesTransactionLog."Excise Unit of Measure Code" := SustainabilityExciseJnlLine."Excise Unit of Measure Code";
        SustExciseTaxesTransactionLog."Excise Entry Type" := SustainabilityExciseJnlLine."Excise Entry Type";
        SustExciseTaxesTransactionLog."FA Ledger Entry No." := SustainabilityExciseJnlLine."FA Ledger Entry No.";
        ExciseTaxCalculation.UpdateFALedgerEntryExciseTaxInfo(SustExciseTaxesTransactionLog);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sustainability Excise Post Mgt", OnAfterInsertExciseTaxesTransactionLog, '', false, false)]
    local procedure OnAfterInsertExciseTaxesTransactionLog(var SustExciseTaxesTransactionLog: Record "Sust. Excise Taxes Trans. Log"; SustainabilityExciseJnlLine: Record "Sust. Excise Jnl. Line")
    var
        ExciseTaxCalculation: Codeunit "Excise Tax Calculation";
    begin
        if not ExciseTaxCalculation.IsExciseTaxEntry(SustainabilityExciseJnlLine) then
            exit;

        ExciseTaxCalculation.UpdateItemLedgerEntryExciseTaxInfo(SustExciseTaxesTransactionLog);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sust. Excise Jnl.-Check", OnBeforeTestEmissionAmount, '', false, false)]
    local procedure OnBeforeTestEmissionAmount(SustainabilityExciseJnlLine: Record "Sust. Excise Jnl. Line"; var IsHandled: Boolean)
    var
        ExciseTaxCalculation: Codeunit "Excise Tax Calculation";
    begin
        if ExciseTaxCalculation.IsExciseTaxEntry(SustainabilityExciseJnlLine) then
            IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sust. Excise Jnl. Line", OnValidateSourceNoBeforeTestFieldPartnerNo, '', false, false)]
    local procedure OnValidateSourceNoBeforeTestFieldPartnerNo(var SustainabilityExciseJnlLine: Record "Sust. Excise Jnl. Line"; var IsHandled: Boolean)
    var
        ExciseTaxCalculation: Codeunit "Excise Tax Calculation";
    begin
        if ExciseTaxCalculation.IsExciseTaxEntry(SustainabilityExciseJnlLine) then
            IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sust. Excise Jnl. Line", OnValidateSustainabilityExciseJournalLineByFieldOnBeforeShowUnsupportedEntryError, '', false, false)]
    local procedure OnValidateSustainabilityExciseJournalLineByFieldOnBeforeShowUnsupportedEntryError(var ExciseJournalLine: Record "Sust. Excise Jnl. Line"; var IsHandled: Boolean)
    var
        ExciseTaxCalculation: Codeunit "Excise Tax Calculation";
    begin
        if ExciseTaxCalculation.IsExciseTaxEntry(ExciseJournalLine) then
            IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sust. Excise Jnl. Line", OnAfterCopyFromItem, '', false, false)]
    local procedure OnAfterCopyFromItem(var ExciseJournalLine: Record "Sust. Excise Jnl. Line"; Item: Record Item)
    var
        ItemExciseTax: Record "Item Excise Tax";
        ExciseTaxCalculation: Codeunit "Excise Tax Calculation";
    begin
        if not ExciseTaxCalculation.IsExciseTaxEntry(ExciseJournalLine) then
            exit;

        if ItemExciseTax.Get(Item."No.", ExciseJournalLine."Excise Tax Type") then begin
            ExciseJournalLine.Validate("Excise Unit of Measure Code", ItemExciseTax."Excise Unit of Measure Code");
            ExciseJournalLine.Validate("Quantity for Excise Tax", ItemExciseTax."Quantity for Excise Tax");
        end;
        ExciseJournalLine.Validate("Item Category Code", Item."Item Category Code");
        ApplyExciseRate(ExciseJournalLine, Item."Item Category Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sust. Excise Jnl. Line", OnAfterCopyFromFixedAsset, '', false, false)]
    local procedure OnAfterCopyFromFixedAsset(var ExciseJournalLine: Record "Sust. Excise Jnl. Line"; FixedAsset: Record "Fixed Asset")
    var
        ExciseTaxCalculation: Codeunit "Excise Tax Calculation";
    begin
        if not ExciseTaxCalculation.IsExciseTaxEntry(ExciseJournalLine) then
            exit;

        ExciseJournalLine.TestField("Excise Tax Type");
        ExciseJournalLine.Validate("Excise Unit of Measure Code", FixedAsset."Excise Unit of Measure Code");
        ExciseJournalLine.Validate("Quantity for Excise Tax", FixedAsset."Quantity for Excise Tax");
        ApplyExciseRate(ExciseJournalLine, '');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Excise Tax Calculation", OnAfterUpdateExciseJournalLineFromItemLedgerEntry, '', false, false)]
    local procedure OnAfterUpdateExciseJournalLineFromItemLedgerEntry(var ExciseJournalLine: Record "Sust. Excise Jnl. Line"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
        ApplyExciseRate(ExciseJournalLine, ItemLedgerEntry."Item Category Code");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sust. Excise Jnl.-Check", OnAfterCheckSustainabilityExciseJournalLine, '', false, false)]
    local procedure OnAfterCheckSustainabilityExciseJournalLine(SustainabilityExciseJnlLine: Record "Sust. Excise Jnl. Line")
    var
        ExciseTaxCalculation: Codeunit "Excise Tax Calculation";
    begin
        if not ExciseTaxCalculation.IsExciseTaxEntry(SustainabilityExciseJnlLine) then
            exit;

        case SustainabilityExciseJnlLine."Excise Calculation Type" of
            "Excise Calculation Type"::"Ad valorem":
                TestAdValoremFields(SustainabilityExciseJnlLine);
            "Excise Calculation Type"::Hybrid:
                begin
                    SustainabilityExciseJnlLine.TestField("Excise Duty", ErrorInfo.Create());
                    SustainabilityExciseJnlLine.TestField("Quantity for Excise Tax", ErrorInfo.Create());
                    TestAdValoremFields(SustainabilityExciseJnlLine);
                end;
        end;
    end;

    local procedure TestAdValoremFields(SustainabilityExciseJnlLine: Record "Sust. Excise Jnl. Line")
    begin
        SustainabilityExciseJnlLine.TestField("Excise Duty %", ErrorInfo.Create());
        SustainabilityExciseJnlLine.TestField("Excise Taxable Amount", ErrorInfo.Create());
    end;

    local procedure ApplyExciseRate(var ExciseJournalLine: Record "Sust. Excise Jnl. Line"; ItemCategoryCode: Code[20])
    var
        ExciseTaxRate: Record "Excise Tax Rate";
        ExciseSourceType: Enum "Excise Source Type";
    begin
        ExciseSourceType := ExciseTaxRate.ConvertSustSourceTypeToExciseSourceType(ExciseJournalLine."Source Type");
        if not ExciseTaxRate.GetEffectiveExciseRate(ExciseJournalLine."Excise Tax Type", ExciseSourceType, ExciseJournalLine."Source No.", ItemCategoryCode, ExciseJournalLine."Posting Date") then
            Clear(ExciseTaxRate);

        ExciseJournalLine.Validate("Excise Calculation Type", ExciseTaxRate."Excise Calculation Type");
        ExciseJournalLine.Validate("Excise Duty %", ExciseTaxRate."Excise Duty %");
        ExciseJournalLine.Validate("Excise Duty", ExciseTaxRate."Excise Duty");

        if ExciseJournalLine."Excise Calculation Type" = ExciseJournalLine."Excise Calculation Type"::"Specific per Unit" then
            ExciseJournalLine.Validate("Excise Taxable Amount", 0);
    end;
}