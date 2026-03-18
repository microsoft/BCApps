// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Depreciation;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Ledger;

codeunit 5613 "Calculate Acq. Cost Depr."
{
    Permissions = TableData "FA Ledger Entry" = rimd;

    trigger OnRun()
    begin
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%1 field must not have a check mark because %2 is zero or negative for %3.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure DeprCalc(var DeprAmount: Decimal; var Custom1Amount: Decimal; FANo: Code[20]; DeprBookCode: Code[10]; LocalDeprBasis: Decimal; Custom1LocalDeprBasis: Decimal)
    var
        DeprBook: Record "Depreciation Book";
        FADeprBook: Record "FA Depreciation Book";
        DepreciationCalc: Codeunit "Depreciation Calculation";
        DeprBasis: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeprCalc(DeprAmount, Custom1Amount, FANo, DeprBookCode, LocalDeprBasis, Custom1LocalDeprBasis, IsHandled);
        if IsHandled then
            exit;

        DeprAmount := 0;
        Custom1Amount := 0;
        DeprBook.Get(DeprBookCode);
        if not FADeprBook.Get(FANo, DeprBookCode) then
            exit;
        FADeprBook.CalcFields(Depreciation, "Acquisition Cost", "Depreciable Basis");
        DeprBasis := FADeprBook."Depreciable Basis" - LocalDeprBasis;
        if DeprBasis <= 0 then
            CreateError(FANo, DeprBookCode);
        if DeprBasis > 0 then
            DeprAmount :=
              DepreciationCalc.CalcRounding(
                DeprBookCode, (FADeprBook.Depreciation * LocalDeprBasis) / DeprBasis);
        if DeprBook."Use Custom 1 Depreciation" and
           (FADeprBook."Depr. Ending Date (Custom 1)" > 0D)
        then begin
            DeprBasis := FADeprBook."Acquisition Cost" - Custom1LocalDeprBasis;
            FADeprBook.CalcFields("Custom 1");
            if DeprBasis <= 0 then
                CreateError(FANo, DeprBookCode);
            if DeprBasis > 0 then
                Custom1Amount :=
                  DepreciationCalc.CalcRounding(
                    DeprBookCode, (FADeprBook."Custom 1" * Custom1LocalDeprBasis) / DeprBasis);
        end;
    end;

    local procedure CreateError(FANo: Code[20]; DeprBookCode: Code[20])
    var
        GenJnlLine: Record "Gen. Journal Line";
        FA: Record "Fixed Asset";
        FADeprBook: Record "FA Depreciation Book";
        DepreciationCalc: Codeunit "Depreciation Calculation";
    begin
        FA."No." := FANo;
        Error(
          Text000,
          GenJnlLine.FieldCaption("Depr. Acquisition Cost"),
          FADeprBook.FieldCaption("Depreciable Basis"), DepreciationCalc.FAName(FA, DeprBookCode));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeprCalc(var DeprAmount: Decimal; var Custom1Amount: Decimal; FANo: Code[20]; DeprBookCode: Code[10]; LocalDeprBasis: Decimal; Custom1LocalDeprBasis: Decimal; var IsHandled: Boolean)
    begin
    end;
}

