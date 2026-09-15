// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GST.Purchase;

using Microsoft.Finance.Deferral;
using Microsoft.Finance.GST.Base;
using Microsoft.Finance.TaxEngine.TaxTypeHandler;
using Microsoft.Purchases.Document;

codeunit 18083 "GST Purchase Deferral"
{
    // For purchase lines where the GST credit is not available (Non-Availment), the GST amount is
    // loaded onto the line value (cost). The deferral schedule must therefore be calculated on the
    // line amount plus the loaded GST amount, instead of only the line amount.

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnAfterGetDeferralAmount', '', false, false)]
    local procedure AddNonAvailmentGSTToDeferralAmount(PurchaseLine: Record "Purchase Line"; var DeferralAmount: Decimal)
    var
        GSTAmountLoaded: Decimal;
    begin
        if PurchaseLine."Deferral Code" = '' then
            exit;

        if PurchaseLine."GST Credit" <> PurchaseLine."GST Credit"::"Non-Availment" then
            exit;

        GSTAmountLoaded := GetNonAvailmentGSTLoadedAmount(PurchaseLine);
        if GSTAmountLoaded = 0 then
            exit;

        if DeferralAmount < 0 then
            DeferralAmount -= GSTAmountLoaded
        else
            DeferralAmount += GSTAmountLoaded;
    end;

    /// <summary>
    /// Recreates the deferral schedule for the purchase line so it reflects the current GST amount
    /// loaded on the line. Used after GST is recalculated on a line that already has a deferral code.
    /// </summary>
    /// <param name="PurchaseLine">Purchase line for which the deferral schedule must be refreshed.</param>
    procedure UpdateDeferralSchedule(var PurchaseLine: Record "Purchase Line")
    var
        DeferralHeader: Record "Deferral Header";
    begin
        if PurchaseLine."Deferral Code" = '' then
            exit;

        if not DeferralHeader.Get(
            Enum::"Deferral Document Type"::Purchase, '', '',
            PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.")
        then
            exit;

        PurchaseLine.UpdateDeferralAmounts();
    end;

    local procedure GetNonAvailmentGSTLoadedAmount(PurchaseLine: Record "Purchase Line") GSTAmountLoaded: Decimal
    var
        GSTSetup: Record "GST Setup";
        GSTGroup: Record "GST Group";
    begin
        if not GSTSetup.Get() then
            exit(0);

        GSTSetup.TestField("GST Tax Type");

        GSTAmountLoaded := GetLineTaxAmount(GSTSetup."GST Tax Type", PurchaseLine.RecordId);

        if (GSTSetup."Cess Tax Type" <> '') and GSTGroup.Get(PurchaseLine."GST Group Code") and
            (GSTGroup."Cess Credit" = GSTGroup."Cess Credit"::"Non-Availment")
        then
            GSTAmountLoaded += GetLineTaxAmount(GSTSetup."Cess Tax Type", PurchaseLine.RecordId);

        exit(Abs(GSTAmountLoaded));
    end;

    local procedure GetLineTaxAmount(TaxType: Code[20]; PurchaseLineTaxID: RecordId) TaxAmount: Decimal
    var
        TaxTransactionValue: Record "Tax Transaction Value";
    begin
        TaxTransactionValue.SetCurrentKey("Tax Record ID", "Tax Type");
        TaxTransactionValue.SetRange("Tax Type", TaxType);
        TaxTransactionValue.SetRange("Tax Record ID", PurchaseLineTaxID);
        TaxTransactionValue.SetFilter(Percent, '<>%1', 0);
        if TaxTransactionValue.FindSet() then
            repeat
                TaxAmount += RoundGSTAmount(TaxType, TaxTransactionValue."Value ID", TaxTransactionValue."Amount (LCY)");
            until TaxTransactionValue.Next() = 0;
    end;

    local procedure RoundGSTAmount(TaxType: Code[20]; ID: Integer; TaxAmt: Decimal): Decimal
    var
        TaxComponent: Record "Tax Component";
        GSTRoundingDirection: Text[1];
    begin
        TaxComponent.SetRange("Tax Type", TaxType);
        TaxComponent.SetRange(ID, ID);
        TaxComponent.SetFilter("Rounding Precision", '<>%1', 0);
        if TaxComponent.FindFirst() then begin
            case TaxComponent.Direction of
                TaxComponent.Direction::Nearest:
                    GSTRoundingDirection := '=';
                TaxComponent.Direction::Up:
                    GSTRoundingDirection := '>';
                TaxComponent.Direction::Down:
                    GSTRoundingDirection := '<';
            end;

            exit(Round(TaxAmt, TaxComponent."Rounding Precision", GSTRoundingDirection));
        end;

        exit(TaxAmt);
    end;
}
