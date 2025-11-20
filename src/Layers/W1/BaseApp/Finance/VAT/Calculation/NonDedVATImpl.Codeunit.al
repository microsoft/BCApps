// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Calculation;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Deferral;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Setup;
using Microsoft.FixedAssets.Ledger;
using Microsoft.Foundation.Enums;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using Microsoft.Foundation.Company;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Project.Job;

/// <summary>
/// Defines the implementation of Non-Deductible VAT
/// </summary>
codeunit 6201 "Non-Ded. VAT Impl."
{
    Access = Internal;
    Permissions = tabledata "VAT Setup" = r;

    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        NonDeductibleVAT: Codeunit "Non-Deductible VAT";
        FCYValueExceedsLimitErr: Label '%1 for %2 must not exceed %3 = %4.', Comment = '%1, %3 = Field caption, %2 = currency code, %4 = decimal value';
        LCYValueExceedsLimitErr: Label '%1 must not exceed %2 = %3.', Comment = '%1, %2 = Field caption, %3 = decimal value';
        TotalExceedsLimitErr: Label 'The total %1 for a document must not exceed the value %2 in the %3 field.', Comment = '%1, %2 = decimal values; %3 = field caption';
        CannotBeNegativeErr: Label 'cannot be negative';
        PrepaymentsWithNDVATErr: Label 'You cannot post prepayment that contains Non-Deductible VAT.';
        UnrealizedVATWithNDVATErr: Label 'You cannot post unrealized VAT that contains Non-Deductible VAT.';
        DifferentNonDedVATRatesSameVATIdentifierErr: Label 'You cannot set different Non-Deductible VAT % for the combinations of business and product groups with the same VAT identifier.\The following combination with the same VAT identifier has different Non-Deductible VAT %: business group %1, product group %2', Comment = '%1, %2 - codes';

    procedure IsNonDeductibleVATEnabled(): Boolean
    var
        VATSetup: Record "VAT Setup";
    begin
        if not VATSetup.Get() then
            exit(false);
        exit(VATSetup."Enable Non-Deductible VAT");
    end;

    procedure ShowNonDeductibleVATInLines(): Boolean
    var
        VATSetup: Record "VAT Setup";
    begin
        if not IsNonDeductibleVATEnabled() then
            exit(false);
        VATSetup.Get();
        exit(VATSetup."Show Non-Ded. VAT In Lines");
    end;

    procedure OpenVATPostingSetupPage(Notification: Notification)
    var
        VATPostingSetupPage: Page "VAT Posting Setup";
    begin
        VATPostingSetupPage.Run();
    end;

    procedure GetNonDeductibleVATAmount(GenJournalLine: Record "Gen. Journal Line"): Decimal
    begin
        if not IsNonDeductibleVATEnabled() then
            exit(0);
        exit(GenJournalLine."Non-Deductible VAT Amount");
    end;

    procedure GetNonDeductibleVATAmount(PurchaseLine: Record "Purchase Line"): Decimal
    begin
        exit(PurchaseLine."Non-Deductible VAT Amount");
    end;

    procedure GetNonDeductibleVATPct(VATBusPostGroupCode: Code[20]; VATProdPostGroupCode: Code[20]; GeneralPostingType: Enum "General Posting Type"): Decimal
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        if not IsNonDeductibleVATEnabled() then
            exit(0);
        if not VATPostingSetup.Get(VATBusPostGroupCode, VATProdPostGroupCode) then
            exit(0);
        exit(GetNonDeductibleVATPct(VATPostingSetup, GeneralPostingType));
    end;

    procedure GetNonDeductibleVATPct(VATPostingSetup: Record "VAT Posting Setup"; GeneralPostingType: Enum "General Posting Type") NonDeductibleVATPct: Decimal
    var
        IsHandled: Boolean;
    begin
        if not IsNonDeductibleVATEnabled() then
            exit(0);
        NonDeductibleVAT.OnBeforeGetNonDeductibleVATPct(NonDeductibleVATPct, VATPostingSetup, GeneralPostingType, IsHandled);
        if IsHandled then
            exit(NonDeductibleVATPct);
        if not (VATPostingSetup."VAT Calculation Type" in [VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", VATPostingSetup."VAT Calculation Type"::"Full VAT"]) then
            exit(0);
        if (VATPostingSetup."Allow Non-Deductible VAT" = VATPostingSetup."Allow Non-Deductible VAT"::"Do not allow") or (GeneralPostingType <> GeneralPostingType::Purchase) then
            exit(0);
        exit(VATPostingSetup."Non-Deductible VAT %");
    end;

    procedure GetNonDeductibleVATPct(VATBusPostGroupCode: Code[20]; VATProdPostGroupCode: Code[20]; DeferralDocType: Enum "Deferral Document Type") NonDeductibleVATPct: Decimal
    var
        IsHandled: Boolean;
    begin
        NonDeductibleVAT.OnBeforeGetNonDeductibleVATPctForDeferrals(NonDeductibleVATPct, VATBusPostGroupCode, VATProdPostGroupCode, DeferralDocType, IsHandled);
        if IsHandled then
            exit(NonDeductibleVATPct);
        exit(GetNonDeductibleVATPct(VATBusPostGroupCode, VATProdPostGroupCode, GetGeneralPostingTypeFromDeferralDocType(DeferralDocType)));
    end;

    procedure GetNonDeductibleVATAccForDeferrals(DeferralDocType: Enum "Deferral Document Type"; PostingGLAccountNo: Code[20]; VATPostingSetup: Record "VAT Posting Setup") VATAcc: Code[20]
    var
        GeneralPostingType: Enum "General Posting Type";
    begin
        case GetGeneralPostingTypeFromDeferralDocType(DeferralDocType) of
            GeneralPostingType::" ":
                VATAcc := PostingGLAccountNo;
            GeneralPostingType::Purchase:
                VATAcc := VATPostingSetup."Non-Ded. Purchase VAT Account";
        end;
        if VATAcc = '' then
            VATAcc := PostingGLAccountNo;
        exit(VATAcc);
    end;

    local procedure GetGeneralPostingTypeFromDeferralDocType(DeferralDocType: Enum "Deferral Document Type") GeneralPostingType: Enum "General Posting Type"
    begin
        case DeferralDocType of
            DeferralDocType::"G/L":
                exit(GeneralPostingType::" ");
            DeferralDocType::Purchase:
                exit(GeneralPostingType::Purchase);
            DeferralDocType::Sales:
                exit(GeneralPostingType::Sale);
        end;
    end;

    procedure SetNonDeductiblePct(var PurchaseLine: Record "Purchase Line")
    begin
        if not IsNonDeductibleVATEnabled() then
            exit;
        PurchaseLine.Validate("Non-Deductible VAT %", GetNonDeductibleVATPct(PurchaseLine));
    end;

    procedure Init(var NonDedVATBase: Decimal; var NonDedVATAmount: Decimal; var NonDedVATBaseACY: Decimal; var NonDedVATAmountACY: Decimal; var NonDedVATDiff: Decimal; PurchaseLine: Record "Purchase Line"; PurchaseLineACY: Record "Purchase Line")
    begin
        NonDedVATBase := PurchaseLine."Non-Deductible VAT Base";
        NonDedVATAmount := PurchaseLine."Non-Deductible VAT Amount";
        NonDedVATBaseACY := PurchaseLineACY."Non-Deductible VAT Base";
        NonDedVATAmountACY := PurchaseLineACY."Non-Deductible VAT Amount";
        NonDedVATDiff := PurchaseLine."Non-Deductible VAT Diff.";
    end;

    procedure InitNonDeductibleVATDiff(var PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine."Non-Deductible VAT Diff." := 0;
    end;

    procedure Update(var PurchaseLine: Record "Purchase Line"; var TempVATAmountLineRemainder: Record "VAT Amount Line" temporary; Currency: Record Currency)
    var
        IsHandled: Boolean;
    begin
        if not IsNonDeductibleVATEnabled() then
            exit;
        NonDeductibleVAT.OnBeforeUpdateNonDeductibleAmountsWithRoundingInPurchLine(PurchaseLine, TempVATAmountLineRemainder, Currency, IsHandled);
        if IsHandled then
            exit;
        UpdateNonDeductibleAmountsWithRounding(
            PurchaseLine."Non-Deductible VAT Base", PurchaseLine."Non-Deductible VAT Amount", TempVATAmountLineRemainder."Non-Deductible VAT Base", TempVATAmountLineRemainder."Non-Deductible VAT Amount",
            PurchaseLine."VAT Base Amount", PurchaseLine."Amount Including VAT" - PurchaseLine."VAT Base Amount" - PurchaseLine."VAT Difference", PurchaseLine."Non-Deductible VAT %", Currency);
    end;

    procedure Update(var PurchaseLine: Record "Purchase Line"; Currency: Record Currency)
    var
        IsHandled: Boolean;
    begin
        if not IsNonDeductibleVATEnabled() then
            exit;
        NonDeductibleVAT.OnBeforeUpdateNonDeductibleAmountsInPurchLine(PurchaseLine, Currency, IsHandled);
        if IsHandled then
            exit;
        UpdateNonDeductibleAmounts(
            PurchaseLine."Non-Deductible VAT Base", PurchaseLine."Non-Deductible VAT Amount", PurchaseLine."VAT Base Amount",
            PurchaseLine."Amount Including VAT" - PurchaseLine."VAT Base Amount" - PurchaseLine."VAT Difference", PurchaseLine."Non-Deductible VAT %", Currency."Amount Rounding Precision");
    end;

    procedure Update(var PurchaseLine: Record "Purchase Line"; Part: Decimal; Total: Decimal; AmountRoundingPrecision: Decimal)
    var
        Factor: Decimal;
        IsHandled: Boolean;
    begin
        NonDeductibleVAT.OnBeforeUpdateNonDeductibleAmountsWithFactorInPurchLine(PurchaseLine, Part, Total, AmountRoundingPrecision, IsHandled);
        if IsHandled then
            exit;
        if Total = 0 then
            Factor := 0
        else
            Factor := Part / Total;
        PurchaseLine."Non-Deductible VAT Base" := Round(PurchaseLine."Non-Deductible VAT Base" * Factor, AmountRoundingPrecision);
        PurchaseLine."Non-Deductible VAT Amount" := Round(PurchaseLine."Non-Deductible VAT Amount" * Factor, AmountRoundingPrecision);
    end;

    procedure DivideNonDeductibleVATInPurchaseLine(var PurchaseLine: Record "Purchase Line"; var VATAmountLineRemainder: Record "VAT Amount Line"; VATAmountLine: Record "VAT Amount Line"; Currency: Record Currency; Part: Decimal; Total: Decimal)
    var
        Factor: Decimal;
        IsHandled: Boolean;
    begin
        NonDeductibleVAT.OnBeforeDivideNonDeductibleVATInPurchaseLine(PurchaseLine, VATAmountLineRemainder, VATAmountLine, Currency, Part, Total, IsHandled);
        if IsHandled then
            exit;
        if Total = 0 then
            Factor := 0
        else
            Factor := Part / Total;
        VATAmountLineRemainder."Non-Deductible VAT Base" := VATAmountLineRemainder."Non-Deductible VAT Base" + VATAmountLine."Non-Deductible VAT Base" * Factor;
        PurchaseLine."Non-Deductible VAT Base" := Round(VATAmountLineRemainder."Non-Deductible VAT Base", Currency."Amount Rounding Precision");
        VATAmountLineRemainder."Non-Deductible VAT Base" := VATAmountLineRemainder."Non-Deductible VAT Base" - PurchaseLine."Non-Deductible VAT Base";
        VATAmountLineRemainder."Non-Deductible VAT Amount" := VATAmountLineRemainder."Non-Deductible VAT Amount" + VATAmountLine."Non-Deductible VAT Amount" * Factor;
        PurchaseLine."Non-Deductible VAT Amount" := Round(VATAmountLineRemainder."Non-Deductible VAT Amount", Currency."Amount Rounding Precision");
        VATAmountLineRemainder."Non-Deductible VAT Amount" := VATAmountLineRemainder."Non-Deductible VAT Amount" - PurchaseLine."Non-Deductible VAT Amount";
    end;

    procedure ValidateVATAmountInVATAmountLine(var VATAmountLine: Record "VAT Amount Line")
    var
        IsHandled: Boolean;
    begin
        if not IsNonDeductibleVATEnabled() then
            exit;
        NonDeductibleVAT.OnBeforeValidateVATAmountInVATAmountLine(VATAmountLine, IsHandled);
        if IsHandled then
            exit;
        if VATAmountLine."Non-Deductible VAT %" = 100 then
            VATAmountLine.Validate("Non-Deductible VAT Amount", VATAmountLine."VAT Amount");
        VATAmountLine."Deductible VAT Amount" := VATAmountLine."VAT Amount" - VATAmountLine."Non-Deductible VAT Amount";
        if VATAmountLine."Deductible VAT Amount" < 0 then
            VATAmountLine.FieldError("Deductible VAT Amount", CannotBeNegativeErr);
    end;

    procedure ValidateNonDeductibleVATInVATAmountLine(var VATAmountLine: Record "VAT Amount Line")
    var
        IsHandled: Boolean;
    begin
        if not IsNonDeductibleVATEnabled() then
            exit;
        NonDeductibleVAT.OnBeforeValidateNonDeductibleVATInVATAmountLine(VATAmountLine, IsHandled);
        if IsHandled then
            exit;
        VATAmountLine."Non-Deductible VAT Diff." := VATAmountLine."Non-Deductible VAT Amount" - VATAmountLine."Calc. Non-Ded. VAT Amount";
        VATAmountLine."Deductible VAT Amount" := VATAmountLine."VAT Amount" - VATAmountLine."Non-Deductible VAT Amount";
        if VATAmountLine."Deductible VAT Amount" < 0 then
            VATAmountLine.FieldError("Deductible VAT Amount", CannotBeNegativeErr);
    end;

    procedure Update(var VATAmountLine: Record "VAT Amount Line"; Currency: Record Currency)
    var
        IsHandled: Boolean;
    begin
        if not IsNonDeductibleVATEnabled() then
            exit;
        NonDeductibleVAT.OnBeforeUpdateNonDeductibleAmountsInVATAmountLine(VATAmountLine, Currency, IsHandled);
        if IsHandled then
            exit;
        UpdateNonDeductibleAmounts(
            VATAmountLine."Non-Deductible VAT Base", VATAmountLine."Non-Deductible VAT Amount", VATAmountLine."VAT Base",
            VATAmountLine."Amount Including VAT" - VATAmountLine."VAT Base", VATAmountLine."Non-Deductible VAT %", Currency."Amount Rounding Precision");
        VATAmountLine."Calc. Non-Ded. VAT Amount" := VATAmountLine."Non-Deductible VAT Amount";
        VATAmountLine."Non-Deductible VAT Diff." := 0;
    end;

    procedure UpdateNonDeductibleAmountsWithDiffInVATAmountLine(var VATAmountLine: Record "VAT Amount Line"; Currency: Record Currency)
    var
        IsHandled: Boolean;
    begin
        if not IsNonDeductibleVATEnabled() then
            exit;
        NonDeductibleVAT.OnBeforeUpdateNonDeductibleAmountsWithDiffInVATAmountLine(VATAmountLine, Currency, IsHandled);
        if IsHandled then
            exit;
        UpdateNonDeductibleAmounts(
            VATAmountLine."Non-Deductible VAT Base", VATAmountLine."Non-Deductible VAT Amount", VATAmountLine."VAT Base",
            VATAmountLine."Amount Including VAT" - VATAmountLine."VAT Base" - VATAmountLine."VAT Difference", VATAmountLine."Non-Deductible VAT %", Currency."Amount Rounding Precision");
        VATAmountLine."Calc. Non-Ded. VAT Amount" := VATAmountLine."Non-Deductible VAT Amount";
        VATAmountLine."Non-Deductible VAT Amount" += VATAmountLine."Non-Deductible VAT Diff.";
    end;

    procedure SetNonDedVATAmountInPurchLine(var PurchaseLine: Record "Purchase Line"; NonDeductibleVATAmount: Decimal)
    var
        IsHandled: Boolean;
    begin
        if not IsNonDeductibleVATEnabled() then
            exit;
        NonDeductibleVAT.OnBeforeSetNonDedVATAmountInPurchLine(PurchaseLine, NonDeductibleVATAmount, IsHandled);
        if IsHandled then
            exit;
        PurchaseLine."Non-Deductible VAT Amount" := NonDeductibleVATAmount;
    end;

    procedure SetNonDedVATAmountDiffInPurchLine(var PurchaseLine: Record "Purchase Line"; var VATAmountLineRemainder: Record "VAT Amount Line"; var VATDifference: Decimal; VATAmountLine: Record "VAT Amount Line"; Currency: Record Currency; Part: Decimal; Total: Decimal)
    var
        IsHandled: Boolean;
    begin
        if not IsNonDeductibleVATEnabled() then
            exit;
        NonDeductibleVAT.OnBeforeSetNonDedVATAmountDiffInPurchLine(PurchaseLine, VATAmountLineRemainder, VATDifference, VATAmountLine, Currency, Part, Total, IsHandled);
        if IsHandled then
            exit;
        if Total = 0 then
            VATDifference := 0
        else
            VATDifference :=
                VATAmountLineRemainder."Non-Deductible VAT Diff." + VATAmountLine."Non-Deductible VAT Diff." * Part / Total;
        PurchaseLine."Non-Deductible VAT Diff." := Round(VATDifference, Currency."Amount Rounding Precision");
        VATAmountLineRemainder."Non-Deductible VAT Diff." := VATDifference - PurchaseLine."Non-Deductible VAT Diff.";
    end;

    procedure SetNonDeductibleVATAmount(var VATEntry: Record "VAT Entry"; NonDedVATAmount: Decimal; NonDedVATAmountACY: Decimal)
    begin
        VATEntry."Non-Deductible VAT Amount" := NonDedVATAmount;
        VATEntry."Non-Deductible VAT Amount ACY" := NonDedVATAmountACY;
    end;

    procedure SetNonDeductibleVATBase(var VATEntry: Record "VAT Entry"; NonDedVATBase: Decimal; NonDedVATBaseACY: Decimal)
    begin
        VATEntry."Non-Deductible VAT Base" := NonDedVATBase;
        VATEntry."Non-Deductible VAT Base ACY" := NonDedVATBaseACY;
    end;

    procedure GetNonDedVATAmountFromVATAmountLine(var VATAmountLineRemainder: Record "VAT Amount Line"; VATAmountLine: Record "VAT Amount Line"; Currency: Record Currency; Part: Decimal; Total: Decimal) NDVATAmount: Decimal
    var
        Factor: Decimal;
        IsHandled: Boolean;
    begin
        if not IsNonDeductibleVATEnabled() then
            exit(0);
        NonDeductibleVAT.OnBeforeGetNonDedVATAmountFromVATAmountLine(NDVATAmount, VATAmountLineRemainder, VATAmountLine, Currency, Part, Total, IsHandled);
        if IsHandled then
            exit(NDVATAmount);
        if Total = 0 then
            Factor := 0
        else
            Factor := Part / Total;
        VATAmountLineRemainder."Non-Deductible VAT Amount" :=
            VATAmountLineRemainder."Non-Deductible VAT Amount" +
            VATAmountLine."Non-Deductible VAT Amount" * Factor;
        NDVATAmount := Round(VATAmountLineRemainder."Non-Deductible VAT Amount", Currency."Amount Rounding Precision");
        VATAmountLineRemainder."Non-Deductible VAT Amount" := VATAmountLineRemainder."Non-Deductible VAT Amount" - NDVATAmount;
        exit(NDVATAmount);
    end;

    procedure AddNonDedAmountsOfPurchLineToVATAmountLine(var VATAmountLine: Record "VAT Amount Line"; var VATAmountLineRemainder: Record "VAT Amount Line"; PurchaseLine: Record "Purchase Line"; Currency: Record Currency; Part: Decimal; Total: Decimal)
    var
        Factor: Decimal;
        IsHandled: Boolean;
    begin
        if not IsNonDeductibleVATEnabled() then
            exit;
        NonDeductibleVAT.OnBeforeAddNonDedAmountsOfPurchLineToVATAmountLine(VATAmountLine, VATAmountLineRemainder, PurchaseLine, Currency, Part, Total, IsHandled);
        if IsHandled then
            exit;
        if Total = 0 then
            Factor := 0
        else
            Factor := Part / Total;
        VATAmountLine."Non-Deductible VAT Base" += VATAmountLineRemainder."Non-Deductible VAT Base" + PurchaseLine."Non-Deductible VAT Base" * Factor;
        VATAmountLine."Non-Deductible VAT Amount" += VATAmountLineRemainder."Non-Deductible VAT Amount" + PurchaseLine."Non-Deductible VAT Amount" * Factor;
        VATAmountLine."Deductible VAT Base" += VATAmountLineRemainder."Deductible VAT Base" + (PurchaseLine."VAT Base Amount" - PurchaseLine."Non-Deductible VAT Base") * Factor;
        VATAmountLine."Deductible VAT Amount" += VATAmountLineRemainder."Deductible VAT Amount" + (PurchaseLine."Amount Including VAT" - PurchaseLine.Amount - PurchaseLine."Non-Deductible VAT Amount") * Factor;
        VATAmountLine."Calc. Non-Ded. VAT Amount" += VATAmountLineRemainder."Calc. Non-Ded. VAT Amount" + (PurchaseLine."Non-Deductible VAT Amount" - PurchaseLine."Non-Deductible VAT Diff.") * Factor;

        VATAmountLineRemainder."Non-Deductible VAT Base" := VATAmountLine."Non-Deductible VAT Base" - Round(VATAmountLine."Non-Deductible VAT Base", Currency."Amount Rounding Precision");
        VATAmountLineRemainder."Non-Deductible VAT Amount" := VATAmountLine."Non-Deductible VAT Amount" - Round(VATAmountLine."Non-Deductible VAT Amount", Currency."Amount Rounding Precision");
        VATAmountLineRemainder."Deductible VAT Base" := VATAmountLine."Deductible VAT Base" - Round(VATAmountLine."Deductible VAT Base", Currency."Amount Rounding Precision");
        VATAmountLineRemainder."Deductible VAT Amount" := VATAmountLine."Deductible VAT Amount" - Round(VATAmountLine."Deductible VAT Amount", Currency."Amount Rounding Precision");
        VATAmountLineRemainder."Calc. Non-Ded. VAT Amount" := VATAmountLine."Calc. Non-Ded. VAT Amount" - Round(VATAmountLine."Calc. Non-Ded. VAT Amount", Currency."Amount Rounding Precision");

        VATAmountLine."Non-Deductible VAT Base" := Round(VATAmountLine."Non-Deductible VAT Base", Currency."Amount Rounding Precision");
        VATAmountLine."Non-Deductible VAT Amount" := Round(VATAmountLine."Non-Deductible VAT Amount", Currency."Amount Rounding Precision");
        VATAmountLine."Deductible VAT Base" := Round(VATAmountLine."Deductible VAT Base", Currency."Amount Rounding Precision");
        VATAmountLine."Deductible VAT Amount" := Round(VATAmountLine."Deductible VAT Amount", Currency."Amount Rounding Precision");
        VATAmountLine."Calc. Non-Ded. VAT Amount" := Round(VATAmountLine."Calc. Non-Ded. VAT Amount", Currency."Amount Rounding Precision");
        VATAmountLine."Non-Deductible VAT Diff." += PurchaseLine."Non-Deductible VAT Diff.";
    end;

    procedure CopyNonDedVATFromPurchInvLineToVATAmountLine(var VATAmountLine: Record "VAT Amount Line"; PurchInvLine: Record "Purch. Inv. Line")
    var
        IsHandled: Boolean;
    begin
        if not IsNonDeductibleVATEnabled() then
            exit;
        NonDeductibleVAT.OnBeforeCopyNonDedVATFromPurchInvLineToVATAmountLine(VATAmountLine, PurchInvLine, IsHandled);
        if IsHandled then
            exit;
        VATAmountLine."Non-Deductible VAT %" := PurchInvLine."Non-Deductible VAT %";
        VATAmountLine."Non-Deductible VAT Base" := PurchInvLine."Non-Deductible VAT Base";
        VATAmountLine."Non-Deductible VAT Amount" := PurchInvLine."Non-Deductible VAT Amount";
        VATAmountLine."Non-Deductible VAT Diff." := PurchInvLine."Non-Deductible VAT Diff.";
        VATAmountLine."Calc. Non-Ded. VAT Amount" := PurchInvLine."Non-Deductible VAT Amount" - PurchInvLine."Non-Deductible VAT Diff.";
        VATAmountLine."Deductible VAT Base" := VATAmountLine."VAT Base" - VATAmountLine."Non-Deductible VAT Base";
        VATAmountLine."Deductible VAT Amount" := VATAmountLine."VAT Amount" - VATAmountLine."Non-Deductible VAT Amount";
    end;

    procedure CopyNonDedVATFromPurchCrMemoLineToVATAmountLine(var VATAmountLine: Record "VAT Amount Line"; PurchCrMemoLine: Record "Purch. Cr. Memo Line")
    var
        IsHandled: Boolean;
    begin
        if not IsNonDeductibleVATEnabled() then
            exit;
        NonDeductibleVAT.OnBeforeCopyNonDedVATFromPurchCrMemoLineToVATAmountLine(VATAmountLine, PurchCrMemoLine, IsHandled);
        if IsHandled then
            exit;
        VATAmountLine."Non-Deductible VAT %" := PurchCrMemoLine."Non-Deductible VAT %";
        VATAmountLine."Non-Deductible VAT Base" := PurchCrMemoLine."Non-Deductible VAT Base";
        VATAmountLine."Non-Deductible VAT Amount" := PurchCrMemoLine."Non-Deductible VAT Amount";
        VATAmountLine."Non-Deductible VAT Diff." := PurchCrMemoLine."Non-Deductible VAT Diff.";
        VATAmountLine."Calc. Non-Ded. VAT Amount" := PurchCrMemoLine."Non-Deductible VAT Amount" - PurchCrMemoLine."Non-Deductible VAT Diff.";
        VATAmountLine."Deductible VAT Base" := VATAmountLine."VAT Base" - VATAmountLine."Non-Deductible VAT Base";
        VATAmountLine."Deductible VAT Amount" := VATAmountLine."VAT Amount" - VATAmountLine."Non-Deductible VAT Amount";
    end;

    procedure CopyNonDedVATAmountFromGenJnlLineToGLEntry(var GLEntry: Record "G/L Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
        if GenJournalLine."Gen. Posting Type" <> GenJournalLine."Gen. Posting Type"::Purchase then
            exit;
        if not (GenJournalLine."VAT Posting" in [GenJournalLine."VAT Posting"::"Automatic VAT Entry", GenJournalLine."VAT Posting"::"Manual VAT Entry"]) then
            exit;
        GLEntry."Non-Deductible VAT Amount" := GenJournalLine."Non-Deductible VAT Amount LCY";
        GLEntry."Non-Deductible VAT Amount ACY" := GenJournalLine."Non-Deductible VAT Amount ACY";
    end;

    procedure CopyNonDedVATFromGenJnlLineToFALedgEntry(var FALedgEntry: Record "FA Ledger Entry"; GenJnlLine: Record "Gen. Journal Line")
    begin
        FALedgEntry."Non-Ded. VAT FA Cost" := GenJnlLine."Non-Ded. VAT FA Cost";
    end;

    procedure CopyNonDedVATFromGenJnlLineToJobJnlLine(var JobJnlLine: Record "Job Journal Line"; GenJnlLine: Record "Gen. Journal Line")
    var
        Job: Record Job;
        CurrencyFactor, NonDedVATAmountLCY, UnitCost, UnitCostLCY, TotalCost, TotalCostLCY : Decimal;
    begin
        if not UseNonDeductibleVATAmountForJobCost() then
            exit;
        if not Job.Get(JobJnlLine."Job No.") then
            exit;
        NonDedVATAmountLCY := GenJnlLine."Non-Deductible VAT Amount LCY";
        if GenJnlLine."Currency Code" <> Job."Currency Code" then begin
            CurrencyFactor := GenJnlLine.GetGenJnlLineToJobCurrencyFactor();
            NonDedVATAmountLCY := Round(GenJnlLine."Non-Deductible VAT Amount" * CurrencyFactor);
        end;
        UnitCostLCY := Round(NonDedVATAmountLCY / JobJnlLine.Quantity);
        UnitCost := Round(GenJnlLine."Non-Deductible VAT Amount" / JobJnlLine.Quantity);
        TotalCostLCY := NonDedVATAmountLCY;
        TotalCost := GenJnlLine."Non-Deductible VAT Amount";
        if JobJnlLine."Unit Cost" > 0 then begin
            UnitCostLCY := Abs(UnitCostLCY);
            UnitCost := Abs(UnitCost);
            TotalCostLCY := Abs(TotalCostLCY);
            TotalCost := Abs(TotalCost);
        end;
        JobJnlLine."Unit Cost (LCY)" += UnitCostLCY;
        JobJnlLine."Unit Cost" += UnitCost;
        JobJnlLine."Total Cost (LCY)" += TotalCostLCY;
        JobJnlLine."Total Cost" += TotalCost;
    end;

    procedure CheckPrepmtWithNonDeductubleVATInPurchaseLine(PurchaseLine: Record "Purchase Line")
    begin
        if (PurchaseLine."Prepayment %" <> 0) and (PurchaseLine."Non-Deductible VAT %" <> 0) then
            error(PrepaymentsWithNDVATErr);
    end;

    procedure CheckPrepmtVATPostingSetup(VATPostingSetup: Record "VAT Posting Setup")
    begin
        if (VATPostingSetup."Allow Non-Deductible VAT" = VATPostingSetup."Allow Non-Deductible VAT"::Allow) and (VATPostingSetup."Non-Deductible VAT %" <> 0) then
            error(PrepaymentsWithNDVATErr);
    end;

    procedure CheckUnrealizedVATWithNonDeductibleVATInVATPostingSetup(VATPostingSetup: Record "VAT Posting Setup")
    begin
        if (VATPostingSetup."Unrealized VAT Type" <> VATPostingSetup."Unrealized VAT Type"::" ") and (VATPostingSetup."Non-Deductible VAT %" <> 0) and (VATPostingSetup."Allow Non-Deductible VAT" = VATPostingSetup."Allow Non-Deductible VAT"::Allow) then
            error(UnrealizedVATWithNDVATErr);
    end;

    procedure CheckVATPostingSetupChangeIsAllowed(VATPostingSetup: Record "VAT Posting Setup")
    var
        ExistingVATPostingSetup: Record "VAT Posting Setup";
        IsHandled: Boolean;
    begin
        if not IsNonDeductibleVATEnabled() then
            exit;
        NonDeductibleVAT.OnBeforeCheckVATPostingSetupChangeIsAllowed(VATPostingSetup, IsHandled);
        if IsHandled then
            exit;
        if VATPostingSetup."Allow Non-Deductible VAT" = VATPostingSetup."Allow Non-Deductible VAT"::"Do Not Allow" then
            exit;
        ExistingVATPostingSetup.SetRange("VAT Identifier", VATPostingSetup."VAT Identifier");
        ExistingVATPostingSetup.SetRange("Allow Non-Deductible VAT", VATPostingSetup."Allow Non-Deductible VAT"::Allow);
        if ExistingVATPostingSetup.FindSet() then
            repeat
                if (ExistingVATPostingSetup."VAT Bus. Posting Group" <> VATPostingSetup."VAT Bus. Posting Group") or (ExistingVATPostingSetup."VAT Prod. Posting Group" <> VATPostingSetup."VAT Prod. Posting Group") then
                    if ExistingVATPostingSetup."Non-Deductible VAT %" <> VATPostingSetup."Non-Deductible VAT %" then
                        error(DifferentNonDedVATRatesSameVATIdentifierErr, ExistingVATPostingSetup."VAT Bus. Posting Group", ExistingVATPostingSetup."VAT Prod. Posting Group");
            until ExistingVATPostingSetup.Next() = 0;
        CheckUnrealizedVATWithNonDeductibleVATInVATPostingSetup(VATPostingSetup);
    end;

    procedure CheckNonDeductibleVATPctIsAllowed(PurchaseLine: Record "Purchase Line")
    var
        IsHandled: Boolean;
    begin
        if not IsNonDeductibleVATEnabled() then
            exit;
        NonDeductibleVAT.OnBeforeCheckNonDeductibleVATPctIsAllowed(PurchaseLine, IsHandled);
        if IsHandled then
            exit;

        if PurchaseLine."Non-Deductible VAT %" = 0 then
            exit;
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseLine."Document No.");
        PurchaseLine.SetFilter("Line No.", '<>%1', PurchaseLine."Line No.");
        PurchaseLine.SetRange("VAT Identifier", PurchaseLine."VAT Identifier");
        PurchaseLine.SetFilter("Non-Deductible VAT %", '<>%1', PurchaseLine."Non-Deductible VAT %");
        if PurchaseLine.FindFirst() then
            error(DifferentNonDedVATRatesSameVATIdentifierErr, PurchaseLine."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group");
    end;

    procedure CheckNonDeductibleVATAmountDiff(var TempVATAmountLine: Record "VAT Amount Line" temporary; xTempVATAmountLine: Record "VAT Amount Line" temporary; AllowVATDifference: Boolean; Currency: Record Currency)
    var
        CurrVATAmountLine: Record "VAT Amount Line";
        TotalVATDifference: Decimal;
    begin
        if not IsNonDeductibleVATEnabled() then
            exit;
        if not AllowVATDifference then
            TempVATAmountLine.TestField("Non-Deductible VAT Diff.", 0);
        if Abs(TempVATAmountLine."Non-Deductible VAT Diff.") > Currency."Max. VAT Difference Allowed" then
            if Currency.Code <> '' then begin
                GeneralLedgerSetup.GetRecordOnce();
                if Abs(TempVATAmountLine."Non-Deductible VAT Diff.") > GeneralLedgerSetup."Max. VAT Difference Allowed" then
                    Error(
                      LCYValueExceedsLimitErr, TempVATAmountLine.FieldCaption("Non-Deductible VAT Diff."),
                      GeneralLedgerSetup.FieldCaption("Max. VAT Difference Allowed"), GeneralLedgerSetup."Max. VAT Difference Allowed");
            end else
                Error(
                    FCYValueExceedsLimitErr, TempVATAmountLine.FieldCaption("Non-Deductible VAT Diff."), Currency.Code,
                    Currency.FieldCaption("Max. VAT Difference Allowed"), Currency."Max. VAT Difference Allowed");
        CurrVATAmountLine := TempVATAmountLine;
        TotalVATDifference := Abs(TempVATAmountLine."Non-Deductible VAT Diff.") - Abs(xTempVATAmountLine."Non-Deductible VAT Diff.");
        if TempVATAmountLine.Find('-') then
            repeat
                TotalVATDifference := TotalVATDifference + Abs(TempVATAmountLine."Non-Deductible VAT Diff.");
            until TempVATAmountLine.Next() = 0;
        TempVATAmountLine := CurrVATAmountLine;
        if TotalVATDifference > Currency."Max. VAT Difference Allowed" then
            Error(
              TotalExceedsLimitErr, TempVATAmountLine.FieldCaption("Non-Deductible VAT Diff."),
              Currency."Max. VAT Difference Allowed", Currency.FieldCaption("Max. VAT Difference Allowed"));
    end;

    procedure Increment(var TotalVATAmountLine: Record "VAT Amount Line"; VATAmountLine: Record "VAT Amount Line")
    begin
        TotalVATAmountLine."Non-Deductible VAT Amount" += VATAmountLine."Non-Deductible VAT Amount";
        TotalVATAmountLine."Non-Deductible VAT Base" += VATAmountLine."Non-Deductible VAT Base";
        TotalVATAmountLine."Non-Deductible VAT Diff." += VATAmountLine."Non-Deductible VAT Diff.";
        TotalVATAmountLine."Calc. Non-Ded. VAT Amount" += VATAmountLine."Calc. Non-Ded. VAT Amount";
        TotalVATAmountLine."Deductible VAT Base" += VATAmountLine."Deductible VAT Base";
        TotalVATAmountLine."Deductible VAT Amount" += VATAmountLine."Deductible VAT Amount";
    end;

    procedure DeductNonDedValuesFromVATAmountLine(var TotalVATAmountLine: Record "VAT Amount Line"; VATAmountLineDeduct: Record "VAT Amount Line")
    begin
        TotalVATAmountLine."Non-Deductible VAT Amount" -= VATAmountLineDeduct."Non-Deductible VAT Amount";
        TotalVATAmountLine."Non-Deductible VAT Base" -= VATAmountLineDeduct."Non-Deductible VAT Base";
        TotalVATAmountLine."Non-Deductible VAT Diff." -= VATAmountLineDeduct."Non-Deductible VAT Diff.";
        TotalVATAmountLine."Calc. Non-Ded. VAT Amount" -= VATAmountLineDeduct."Calc. Non-Ded. VAT Amount";
        TotalVATAmountLine."Deductible VAT Base" += VATAmountLineDeduct."Deductible VAT Base";
        TotalVATAmountLine."Deductible VAT Amount" += VATAmountLineDeduct."Deductible VAT Amount";
    end;

    procedure Reverse(var PurchaseLine: Record "Purchase Line")
    begin
        if not IsNonDeductibleVATEnabled() then
            exit;

        PurchaseLine."Non-Deductible VAT Base" := -PurchaseLine."Non-Deductible VAT Base";
        PurchaseLine."Non-Deductible VAT Amount" := -PurchaseLine."Non-Deductible VAT Amount";
    end;

    procedure Reverse(var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        if not IsNonDeductibleVATEnabled() then
            exit;
        InvoicePostingBuffer."Non-Deductible VAT Base" := -InvoicePostingBuffer."Non-Deductible VAT Base";
        InvoicePostingBuffer."Non-Deductible VAT Amount" := -InvoicePostingBuffer."Non-Deductible VAT Amount";
        InvoicePostingBuffer."Non-Deductible VAT Base ACY" := -InvoicePostingBuffer."Non-Deductible VAT Base ACY";
        InvoicePostingBuffer."Non-Deductible VAT Amount ACY" := -InvoicePostingBuffer."Non-Deductible VAT Amount ACY";
        InvoicePostingBuffer."Non-Deductible VAT Diff." := -InvoicePostingBuffer."Non-Deductible VAT Diff.";
    end;

    procedure Reverse(var GLEntry: Record "G/L Entry"; GLEntryToReverse: Record "G/L Entry")
    begin
        GLEntry."Non-Deductible VAT Amount" := -GLEntryToReverse."Non-Deductible VAT Amount";
        GLEntry."Non-Deductible VAT Amount ACY" := -GLEntryToReverse."Non-Deductible VAT Amount ACY";
    end;

    procedure Reverse(var VATEntry: Record "VAT Entry")
    begin
        VATEntry."Non-Deductible VAT Base" := -VATEntry."Non-Deductible VAT Base";
        VATEntry."Non-Deductible VAT Amount" := -VATEntry."Non-Deductible VAT Amount";
        VATEntry."Non-Deductible VAT Base ACY" := -VATEntry."Non-Deductible VAT Base ACY";
        VATEntry."Non-Deductible VAT Amount ACY" := -VATEntry."Non-Deductible VAT Amount ACY";
        VATEntry."Non-Deductible VAT Diff." := -VATEntry."Non-Deductible VAT Diff.";
        VATEntry."Non-Deductible VAT Diff. ACY" := -VATEntry."Non-Deductible VAT Diff. ACY";
    end;

    procedure Increment(var TotalPurchaseLine: Record "Purchase Line"; PurchaseLine: Record "Purchase Line")
    begin
        if not IsNonDeductibleVATEnabled() then
            exit;

        TotalPurchaseLine."Non-Deductible VAT Base" += PurchaseLine."Non-Deductible VAT Base";
        TotalPurchaseLine."Non-Deductible VAT Amount" += PurchaseLine."Non-Deductible VAT Amount";
    end;

    procedure Increment(var TotalInvoicePostingBuffer: Record "Invoice Posting Buffer"; InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        if not IsNonDeductibleVATEnabled() then
            exit;

        TotalInvoicePostingBuffer."Non-Deductible VAT Base" += InvoicePostingBuffer."Non-Deductible VAT Base";
        TotalInvoicePostingBuffer."Non-Deductible VAT Amount" += InvoicePostingBuffer."Non-Deductible VAT Amount";
        TotalInvoicePostingBuffer."Non-Deductible VAT Base ACY" += InvoicePostingBuffer."Non-Deductible VAT Base ACY";
        TotalInvoicePostingBuffer."Non-Deductible VAT Amount ACY" += InvoicePostingBuffer."Non-Deductible VAT Amount ACY";
        TotalInvoicePostingBuffer."Non-Deductible VAT Diff." += InvoicePostingBuffer."Non-Deductible VAT Diff.";
    end;

    procedure IsNonDedFALedgEntryInFirstAcquisition(FALedgEntry: Record "FA Ledger Entry"): Boolean
    var
        AdjacentFALedgEntry: Record "FA Ledger Entry";
    begin
        if not FALedgEntry."Non-Ded. VAT FA Cost" then
            exit(false);
        AdjacentFALedgEntry.ReadIsolation := IsolationLevel::ReadCommitted;
        AdjacentFALedgEntry.SetRange("FA No.", FALedgEntry."FA No.");
        AdjacentFALedgEntry.SetFilter("Transaction No.", '<>%1', FALedgEntry."Transaction No.");
        AdjacentFALedgEntry.SetRange("Non-Ded. VAT FA Cost", false);
        exit(AdjacentFALedgEntry.IsEmpty());
    end;

    procedure Update(var TotalNonDedVATBase: Decimal; var TotalNonDedVATAmount: Decimal; var TotalNonDedVATBaseACY: Decimal; var TotalNonDedVATAmountACY: Decimal; var TotalNonDedVATDiff: Decimal; InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        TotalNonDedVATBase -= InvoicePostingBuffer."Non-Deductible VAT Base";
        TotalNonDedVATAmount -= InvoicePostingBuffer."Non-Deductible VAT Amount";
        TotalNonDedVATBaseACY -= InvoicePostingBuffer."Non-Deductible VAT Base ACY";
        TotalNonDedVATAmountACY -= InvoicePostingBuffer."Non-Deductible VAT Amount ACY";
        TotalNonDedVATDiff -= InvoicePostingBuffer."Non-Deductible VAT Diff.";
    end;

    procedure SetNonDeductibleVAT(var InvoicePostingBuffer: Record "Invoice Posting Buffer"; TotalNonDedVATBase: Decimal; TotalNonDedVATAmount: Decimal; TotalNonDedVATBaseACY: Decimal; TotalNonDedVATAmountACY: Decimal; TotalNonDedVATDiff: Decimal)
    begin
        InvoicePostingBuffer."Non-Deductible VAT Base" := TotalNonDedVATBase;
        InvoicePostingBuffer."Non-Deductible VAT Amount" := TotalNonDedVATAmount;
        InvoicePostingBuffer."Non-Deductible VAT Base ACY" := TotalNonDedVATBaseACY;
        InvoicePostingBuffer."Non-Deductible VAT Amount ACY" := TotalNonDedVATAmountACY;
        InvoicePostingBuffer."Non-Deductible VAT Diff." := TotalNonDedVATDiff;
    end;

    procedure RoundNonDeductibleVAT(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; TotalPurchaseLine: Record "Purchase Line"; TotalPurchaseLineLCY: Record "Purchase Line")
    var
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        if not IsNonDeductibleVATEnabled() then
            exit;

        if PurchaseLine."Non-Deductible VAT %" = 100 then begin
            PurchaseLine."Non-Deductible VAT Base" := PurchaseLine."VAT Base Amount";
            PurchaseLine."Non-Deductible VAT Amount" := PurchaseLine."Amount Including VAT" - PurchaseLine."VAT Base Amount";
            exit;
        end;
        PurchaseLine."Non-Deductible VAT Base" :=
            Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                    PurchaseHeader.GetUseDate(), PurchaseHeader."Currency Code",
                    TotalPurchaseLine."Non-Deductible VAT Base", PurchaseHeader."Currency Factor")) -
            TotalPurchaseLineLCY."Non-Deductible VAT Base";
        PurchaseLine."Non-Deductible VAT Amount" :=
            Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                    PurchaseHeader.GetUseDate(), PurchaseHeader."Currency Code",
                    TotalPurchaseLine."Non-Deductible VAT Amount", PurchaseHeader."Currency Factor")) -
            TotalPurchaseLineLCY."Non-Deductible VAT Amount";
    end;

    procedure ClearNonDeductibleVAT(var PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine."Non-Deductible VAT Base" := 0;
        PurchaseLine."Non-Deductible VAT Amount" := 0;
    end;

    procedure ClearNonDeductibleVAT(var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        InvoicePostingBuffer."Non-Deductible VAT Base" := 0;
        InvoicePostingBuffer."Non-Deductible VAT Base ACY" := 0;
        InvoicePostingBuffer."Non-Deductible VAT Amount" := 0;
        InvoicePostingBuffer."Non-Deductible VAT Amount ACY" := 0;
        InvoicePostingBuffer."Non-Deductible VAT Diff." := 0;
    end;

    procedure Update(var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var ReminderInvoicePostingBuffer: Record "Invoice Posting Buffer"; AmountRoundingPrecision: Decimal)
    begin
        if not IsNonDeductibleVATEnabled() then
            exit;
        AmountRoundingPrecision := GetInvPostBufferAmountRoundingPrecision(AmountRoundingPrecision);
        InvoicePostingBuffer."Non-Deductible VAT Amount" :=
            GetNonDeductibleAmount(
                InvoicePostingBuffer."VAT Amount", InvoicePostingBuffer."Non-Deductible VAT %", AmountRoundingPrecision, ReminderInvoicePostingBuffer."Non-Deductible VAT Amount");
        InvoicePostingBuffer."Non-Deductible VAT Amount ACY" :=
            GetNonDeductibleAmount(
                InvoicePostingBuffer."VAT Amount (ACY)", InvoicePostingBuffer."Non-Deductible VAT %", AmountRoundingPrecision, ReminderInvoicePostingBuffer."Non-Deductible VAT Amount ACY");
        InvoicePostingBuffer."Non-Deductible VAT Base" :=
            GetNonDeductibleAmount(
                InvoicePostingBuffer."VAT Base Amount", InvoicePostingBuffer."Non-Deductible VAT %", AmountRoundingPrecision, ReminderInvoicePostingBuffer."Non-Deductible VAT Base");
        InvoicePostingBuffer."Non-Deductible VAT Base ACY" :=
            GetNonDeductibleAmount(
                InvoicePostingBuffer."VAT Base Amount (ACY)", InvoicePostingBuffer."Non-Deductible VAT %", AmountRoundingPrecision, ReminderInvoicePostingBuffer."Non-Deductible VAT Base ACY");
    end;

    procedure ValidateNonDedVATPctInGenJnlLine(var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine.Validate("Non-Deductible VAT %", GetNonDeductibleVATPct(GenJournalLine));
    end;

    procedure ValidateBalNonDedVATPctInGenJnlLine(var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine.Validate("Bal. Non-Ded. VAT %", GetBalNonDeductibleVATPct(GenJournalLine));
    end;

    procedure Calculate(var GenJournalLine: Record "Gen. Journal Line"; Currency: Record Currency)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        CurrExchRate: Record "Currency Exchange Rate";
        IsHandled: Boolean;
    begin
        if not IsNonDeductibleVATEnabled() then
            exit;
        NonDeductibleVAT.OnBeforeCalcNonDedAmountsInGenJnlLine(GenJournalLine, Currency, IsHandled);
        if IsHandled then
            exit;
        if not (GenJournalLine."VAT Calculation Type" in [GenJournalLine."VAT Calculation Type"::"Normal VAT", GenJournalLine."VAT Calculation Type"::"Reverse Charge VAT", GenJournalLine."VAT Calculation Type"::"Full VAT"]) then
            exit;
        if not VATPostingSetup.Get(GenJournalLine."VAT Bus. Posting Group", GenJournalLine."VAT Prod. Posting Group") then
            exit;
        GenJournalLine.Validate("Non-Deductible VAT Base",
            Round(GenJournalLine."VAT Base Amount" * GetNonDedVATPctFromGenJournalLine(GenJournalLine) / 100, Currency."Amount Rounding Precision"));
        if GenJournalLine."VAT Calculation Type" = GenJournalLine."VAT Calculation Type"::"Reverse Charge VAT" then
            GenJournalLine.Validate("Non-Deductible VAT Amount",
                Round(GenJournalLine."Non-Deductible VAT Base" * VATPostingSetup."VAT %" / 100, Currency."Amount Rounding Precision"))
        else
            GenJournalLine.Validate("Non-Deductible VAT Amount",
                Round((GenJournalLine.Amount - GenJournalLine."VAT Base Amount") * GetNonDedVATPctFromGenJournalLine(GenJournalLine) / 100, Currency."Amount Rounding Precision"));
        if GenJournalLine."Currency Code" = '' then begin
            GenJournalLine.Validate("Non-Deductible VAT Base LCY", GenJournalLine."Non-Deductible VAT Base");
            GenJournalLine.Validate("Non-Deductible VAT Amount LCY", GenJournalLine."Non-Deductible VAT Amount");
            exit;
        end;
        GenJournalLine.Validate(
            "Non-Deductible VAT Base LCY",
            Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                    GenJournalLine."Posting Date", GenJournalLine."Currency Code", GenJournalLine."Non-Deductible VAT Base", GenJournalLine."Currency Factor")));
        GenJournalLine.Validate(
            "Non-Deductible VAT Amount LCY",
            Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                    GenJournalLine."Posting Date", GenJournalLine."Currency Code", GenJournalLine."Non-Deductible VAT Amount", GenJournalLine."Currency Factor")));
    end;

    procedure CalculateBalAcc(var GenJournalLine: Record "Gen. Journal Line"; Currency: Record Currency)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        CurrExchRate: Record "Currency Exchange Rate";
        IsHandled: Boolean;
    begin
        if not IsNonDeductibleVATEnabled() then
            exit;
        NonDeductibleVAT.OnBeforeCalcBalNonDedAmountsInGenJnlLine(GenJournalLine, Currency, IsHandled);
        if IsHandled then
            exit;
        if not (GenJournalLine."Bal. VAT Calculation Type" in [GenJournalLine."Bal. VAT Calculation Type"::"Normal VAT", GenJournalLine."Bal. VAT Calculation Type"::"Reverse Charge VAT"]) then
            exit;
        if not VATPostingSetup.Get(GenJournalLine."Bal. VAT Bus. Posting Group", GenJournalLine."Bal. VAT Prod. Posting Group") then
            exit;
        GenJournalLine.Validate("Bal. Non-Ded. VAT Base",
            Round(GenJournalLine."Bal. VAT Base Amount" * GetBalNonDedVATPctFromGenJournalLine(GenJournalLine) / 100, Currency."Amount Rounding Precision"));
        if GenJournalLine."Bal. VAT Calculation Type" = GenJournalLine."Bal. VAT Calculation Type"::"Reverse Charge VAT" then
            GenJournalLine.Validate("Bal. Non-Ded. VAT Amount",
                Round(GenJournalLine."Bal. Non-Ded. VAT Base" * VATPostingSetup."VAT %" / 100, Currency."Amount Rounding Precision"))
        else
            GenJournalLine.Validate("Bal. Non-Ded. VAT Amount",
                Round((-GenJournalLine."Bal. VAT Base Amount" - GenJournalLine.Amount) * GetBalNonDedVATPctFromGenJournalLine(GenJournalLine) / 100, Currency."Amount Rounding Precision"));
        if GenJournalLine."Currency Code" = '' then begin
            GenJournalLine.Validate("Bal. Non-Ded. VAT Base LCY", GenJournalLine."Bal. Non-Ded. VAT Base");
            GenJournalLine.Validate("Bal. Non-Ded. VAT Amount LCY", GenJournalLine."Bal. Non-Ded. VAT Amount");
            exit;
        end;
        GenJournalLine.Validate(
            "Bal. Non-Ded. VAT Base LCY",
            Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                    GenJournalLine."Posting Date", GenJournalLine."Currency Code", GenJournalLine."Bal. Non-Ded. VAT Base", GenJournalLine."Currency Factor")));
        GenJournalLine.Validate(
            "Bal. Non-Ded. VAT Amount LCY",
            Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                    GenJournalLine."Posting Date", GenJournalLine."Currency Code", GenJournalLine."Bal. Non-Ded. VAT Amount", GenJournalLine."Currency Factor")));
    end;

    procedure Calculate(var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    var
        Currency: Record Currency;
    begin
        if not IsNonDeductibleVATEnabled() then
            exit;
        Currency.InitRoundingPrecision();
        UpdateNonDeductibleAmounts(
            InvoicePostingBuffer."Non-Deductible VAT Base", InvoicePostingBuffer."Non-Deductible VAT Amount", InvoicePostingBuffer."VAT Base Amount",
            InvoicePostingBuffer."VAT Amount", InvoicePostingBuffer."Non-Deductible VAT %", Currency."Amount Rounding Precision");
        UpdateNonDeductibleAmounts(
            InvoicePostingBuffer."Non-Deductible VAT Base ACY", InvoicePostingBuffer."Non-Deductible VAT Amount ACY", InvoicePostingBuffer."VAT Base Amount (ACY)",
            InvoicePostingBuffer."VAT Amount (ACY)", InvoicePostingBuffer."Non-Deductible VAT %", Currency."Amount Rounding Precision");
    end;

    procedure Calculate(var NonDeductibleBaseAmount: Decimal; var NonDeductibleVATAmount: Decimal; var NonDeductibleVATAmtPerUnit: Decimal; var NonDeductibleVATAmtPerUnitLCY: Decimal; var NDVATAmountRounding: Decimal; var NDVATBaseRounding: Decimal; PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line")
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        VATAmount: Decimal;
        BaseAmount: Decimal;
    begin
        if not IsNonDeductibleVATEnabled() then
            exit;

        NonDeductibleVATAmount := 0;
        NonDeductibleBaseAmount := 0;
        NonDeductibleVATAmtPerUnit := 0;
        NonDeductibleVATAmtPerUnitLCY := 0;
        if PurchaseLine."VAT Calculation Type" = PurchaseLine."VAT Calculation Type"::"Reverse Charge VAT" then
            VATAmount := CalcRevChargeVATAmountInPurchLine(PurchaseLine)
        else
            VATAmount := PurchaseLine."Amount Including VAT" - PurchaseLine.Amount;
        BaseAmount := PurchaseLine.Amount;
        GeneralLedgerSetup.GetRecordOnce();
        AdjustVATAmountsWithNonDeductibleVATPct(VATAmount, BaseAmount, NonDeductibleVATAmount, NonDeductibleBaseAmount, PurchaseLine."Non-Deductible VAT %", GeneralLedgerSetup."Amount Rounding Precision", NDVATAmountRounding, NDVATBaseRounding);
        NonDeductibleVATAmtPerUnitLCY := NonDeductibleVATAmount / PurchaseLine."Qty. to Invoice";
        if PurchaseLine."Currency Code" = '' then
            NonDeductibleVATAmtPerUnit := NonDeductibleVATAmtPerUnitLCY
        else
            NonDeductibleVATAmtPerUnit :=
                CurrencyExchangeRate.ExchangeAmtLCYToFCY(
                    PurchaseHeader."Posting Date",
                    PurchaseLine."Currency Code",
                    NonDeductibleVATAmtPerUnitLCY,
                    PurchaseHeader."Currency Factor");
    end;

    local procedure CalcRevChargeVATAmountInPurchLine(PurchaseLine: Record "Purchase Line") VATAmount: Decimal;
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Currency: Record Currency;
    begin
        VATPostingSetup.Get(PurchaseLine."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group");
        Currency.Initialize(PurchaseLine."Currency Code", true);
        VATAmount :=
            Round(
                PurchaseLine.Amount * VATPostingSetup."VAT %" / 100,
                Currency."Amount Rounding Precision", Currency.VATRoundingDirection());
    end;

    procedure Copy(var InvoicePostingBuffer: Record "Invoice Posting Buffer"; PurchaseLine: Record "Purchase Line")
    begin
        InvoicePostingBuffer."Non-Deductible VAT %" := PurchaseLine."Non-Deductible VAT %";
        InvoicePostingBuffer."Non-Deductible VAT Base" := PurchaseLine."Non-Deductible VAT Base";
        InvoicePostingBuffer."Non-Deductible VAT Amount" := PurchaseLine."Non-Deductible VAT Amount";
        InvoicePostingBuffer."Non-Deductible VAT Diff." := PurchaseLine."Non-Deductible VAT Diff.";
    end;

    procedure Copy(var VATEntry: Record "VAT Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
        VATEntry."Non-Deductible VAT %" := GenJournalLine."Non-Deductible VAT %";
        VATEntry."Non-Deductible VAT Base" := GenJournalLine."Non-Deductible VAT Base LCY";
        VATEntry."Non-Deductible VAT Amount" := GenJournalLine."Non-Deductible VAT Amount LCY";
        VATEntry."Non-Deductible VAT Diff." := GenJournalLine."Non-Deductible VAT Diff.";
    end;

    procedure SetNonDedVATInVATEntry(var VATEntry: Record "VAT Entry"; NonDedBase: Decimal; NonDedVATAmount: Decimal; SrcCurrNonDedBaseAmount: Decimal; SrcCurrNonDedVATAmount: Decimal; NonDedVATDiff: Decimal; NonDedVATDiffACY: Decimal)
    begin
        VATEntry."Non-Deductible VAT Base" := NonDedBase;
        VATEntry."Non-Deductible VAT Amount" := NonDedVATAmount;
        VATEntry."Non-Deductible VAT Base ACY" := SrcCurrNonDedBaseAmount;
        VATEntry."Non-Deductible VAT Amount ACY" := SrcCurrNonDedVATAmount;
        VATEntry."Non-Deductible VAT Diff." := NonDedVATDiff;
        VATEntry."Non-Deductible VAT Diff. ACY" := NonDedVATDiffACY;
    end;

    procedure ClearNonDedVATACYInVATEntry(var VATEntry: Record "VAT Entry")
    begin
        VATEntry."Non-Deductible VAT Base ACY" := 0;
        VATEntry."Non-Deductible VAT Amount ACY" := 0;
    end;

    procedure Copy(var GenJournalLine: Record "Gen. Journal Line"; InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        GenJournalLine."Non-Deductible VAT %" := InvoicePostingBuffer."Non-Deductible VAT %";
        GenJournalLine."Non-Deductible VAT Base" := InvoicePostingBuffer."Non-Deductible VAT Base";
        GenJournalLine."Non-Deductible VAT Amount" := InvoicePostingBuffer."Non-Deductible VAT Amount";
        GenJournalLine."Non-Deductible VAT Base LCY" := InvoicePostingBuffer."Non-Deductible VAT Base";
        GenJournalLine."Non-Deductible VAT Amount LCY" := InvoicePostingBuffer."Non-Deductible VAT Amount";
        GenJournalLine."Non-Deductible VAT Base ACY" := InvoicePostingBuffer."Non-Deductible VAT Base ACY";
        GenJournalLine."Non-Deductible VAT Amount ACY" := InvoicePostingBuffer."Non-Deductible VAT Amount ACY";
        GenJournalLine."Non-Deductible VAT Diff." := InvoicePostingBuffer."Non-Deductible VAT Diff.";
    end;

    procedure ExchangeAccGLJournalLine(var GenJournalLine: Record "Gen. Journal Line"; CopiedGenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine."Non-Deductible VAT %" := CopiedGenJournalLine."Bal. Non-Ded. VAT %";
        GenJournalLine."Non-Deductible VAT Base" := CopiedGenJournalLine."Bal. Non-Ded. VAT Base";
        GenJournalLine."Non-Deductible VAT Amount" := CopiedGenJournalLine."Bal. Non-Ded. VAT Amount";
        GenJournalLine."Non-Deductible VAT Base LCY" := CopiedGenJournalLine."Bal. Non-Ded. VAT Base LCY";
        GenJournalLine."Non-Deductible VAT Amount LCY" := CopiedGenJournalLine."Bal. Non-Ded. VAT Amount LCY";
        GenJournalLine."Bal. Non-Ded. VAT %" := CopiedGenJournalLine."Non-Deductible VAT %";
        GenJournalLine."Bal. Non-Ded. VAT Base" := CopiedGenJournalLine."Non-Deductible VAT Base";
        GenJournalLine."Bal. Non-Ded. VAT Amount" := CopiedGenJournalLine."Non-Deductible VAT Amount";
        GenJournalLine."Bal. Non-Ded. VAT Base LCY" := CopiedGenJournalLine."Non-Deductible VAT Base LCY";
        GenJournalLine."Bal. Non-Ded. VAT Amount LCY" := CopiedGenJournalLine."Non-Deductible VAT Amount LCY";
    end;

    procedure AdjustVATAmountsFromGenJnlLine(var VATAmount: Decimal; var BaseAmount: Decimal; var VATAmountACY: Decimal; var BaseAmountACY: Decimal; var GenJournalLine: Record "Gen. Journal Line")
    var
        IsHandled: Boolean;
    begin
        if not IsNonDeductibleVATEnabled() then
            exit;
        NonDeductibleVAT.OnBeforeAdjustVATAmountsFromGenJnlLine(VATAmount, BaseAmount, VATAmountACY, BaseAmountACY, GenJournalLine, IsHandled);
        if IsHandled then
            exit;
        GeneralLedgerSetup.GetRecordOnce();
        UpdateNonDeductibleAmounts(GenJournalLine."Non-Deductible VAT Base ACY", GenJournalLine."Non-Deductible VAT Amount ACY", BaseAmountACY, VATAmountACY, GetNonDedVATPctFromGenJournalLine(GenJournalLine), GeneralLedgerSetup."Amount Rounding Precision");
        AdjustVATAmounts(VATAmountACY, BaseAmountACY, GenJournalLine."Non-Deductible VAT Amount ACY", GenJournalLine."Non-Deductible VAT Base ACY");
        if IsNormalVATInvoiceForVendor(GenJournalLine) then
            UpdateNonDeductibleAmounts(GenJournalLine."Non-Deductible VAT Base LCY", GenJournalLine."Non-Deductible VAT Amount LCY", BaseAmount, VATAmount, GetNonDedVATPctFromGenJournalLine(GenJournalLine), GeneralLedgerSetup."Amount Rounding Precision");
        AdjustVATAmounts(VATAmount, BaseAmount, GenJournalLine."Non-Deductible VAT Amount LCY", GenJournalLine."Non-Deductible VAT Base LCY");
    end;

    local procedure AdjustVATAmountsWithNonDeductibleVATPct(var VATAmount: Decimal; var BaseAmount: Decimal; var NondeductibleVATAmount: Decimal; var NondeductibleBaseAmount: Decimal; NonDeductiblePct: Decimal; AmountRoundingPrecision: Decimal; var NonDedVATAmountRounding: Decimal; var NonDedVATBaseRounding: Decimal)
    begin
        if not IsNonDeductibleVATEnabled() then
            exit;

        if NonDeductiblePct = 0 then
            exit;

        NondeductibleVATAmount := GetNonDeductibleAmount(VATAmount, NonDeductiblePct, AmountRoundingPrecision, NonDedVATAmountRounding);
        VATAmount -= NondeductibleVATAmount;

        NondeductibleBaseAmount := GetNonDeductibleAmount(BaseAmount, NonDeductiblePct, AmountRoundingPrecision, NonDedVATBaseRounding);
        BaseAmount -= NondeductibleBaseAmount;
    end;

    local procedure AdjustVATAmounts(var VATAmount: Decimal; var BaseAmount: Decimal; NondeductibleVATAmount: Decimal; NondeductibleBaseAmount: Decimal)
    begin
        if not IsNonDeductibleVATEnabled() then
            exit;

        VATAmount -= NondeductibleVATAmount;
        BaseAmount -= NondeductibleBaseAmount;
    end;

    procedure GetNonDeductibleAmount(Amount: Decimal; NonDeductiblePercent: Decimal; AmountRoundingPrecision: Decimal; var Rounding: Decimal) Result: Decimal
    var
        UnroundedValue: Decimal;
    begin
        if NonDeductiblePercent = 0 then
            exit(0);

        if NonDeductiblePercent = 100 then
            exit(Amount);

        UnroundedValue := Rounding + Amount * NonDeductiblePercent / 100;
        Result := Round(UnroundedValue, AmountRoundingPrecision, '=');
        Rounding := UnroundedValue - Result;
    end;

    procedure GetNonDeductibleVATBaseBothCurrencies(var NonDedVATBase: Decimal; var NonDedVATBaseACY: Decimal; VATEntry: Record "VAT Entry")
    begin
        NonDedVATBase := VATEntry."Non-Deductible VAT Base";
        NonDedVATBaseACY := VATEntry."Non-Deductible VAT Base ACY";
    end;

    procedure AdjustRoundingForInvoicePostingBufferUpdate(var RoundingInvoicePostingBuffer: Record "Invoice Posting Buffer"; var CurrInvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        AdjustRoundingFieldsPair(
            RoundingInvoicePostingBuffer."Non-Deductible VAT Amount", CurrInvoicePostingBuffer."Non-Deductible VAT Amount", CurrInvoicePostingBuffer."Non-Deductible VAT Amount ACY");
        AdjustRoundingFieldsPair(
            RoundingInvoicePostingBuffer."Non-Deductible VAT Base", CurrInvoicePostingBuffer."Non-Deductible VAT Base", CurrInvoicePostingBuffer."Non-Deductible VAT Base ACY");
    end;

    procedure GetNonDeductibleVATAmountForItemCost(PurchaseLine: Record "Purchase Line"): Decimal
    var
        VATSetup: Record "VAT Setup";
        Currency: Record Currency;
    begin
        if not VATSetup.Get() then
            exit(0);
        if not VATSetup."Use For Item Cost" then
            exit;
        if PurchaseLine."VAT Calculation Type" = PurchaseLine."VAT Calculation Type"::"Reverse Charge VAT" then begin
            PurchaseLine."Amount Including VAT" := PurchaseLine.Amount + CalcRevChargeVATAmountInPurchLine(PurchaseLine);
            Currency.Initialize(PurchaseLine."Currency Code", true);
            Update(PurchaseLine, Currency);
        end;
        exit(PurchaseLine."Non-Deductible VAT Amount");
    end;

    procedure UseNonDeductibleVATAmountForFixedAssetCost(): Boolean
    var
        VATSetup: Record "VAT Setup";
    begin
        if not VATSetup.Get() then
            exit(false);
        exit(VATSetup."Use For Fixed Asset Cost");
    end;

    procedure UseNonDeductibleVATAmountForJobCost(): Boolean
    var
        VATSetup: Record "VAT Setup";
    begin
        if not VATSetup.Get() then
            exit(false);
        exit(VATSetup."Use For Job Cost");
    end;

    procedure ApplyRoundingForFinalPostingFromInvoicePostingBuffer(var RoundingInvoicePostingBuffer: Record "Invoice Posting Buffer"; var CurrInvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        ApplyRoundingValueForFinalPosting(RoundingInvoicePostingBuffer."Non-Deductible VAT Amount", CurrInvoicePostingBuffer."Non-Deductible VAT Amount");
        ApplyRoundingValueForFinalPosting(RoundingInvoicePostingBuffer."Non-Deductible VAT Base", CurrInvoicePostingBuffer."Non-Deductible VAT Base");
    end;

    local procedure AdjustRoundingFieldsPair(var TotalRoundingAmount: Decimal; var AmountLCY: Decimal; AmountFCY: Decimal)
    begin
        if (AmountLCY <> 0) and (AmountFCY = 0) then begin
            TotalRoundingAmount += AmountLCY;
            AmountLCY := 0;
        end;
    end;

    local procedure ApplyRoundingValueForFinalPosting(var Rounding: Decimal; var Value: Decimal)
    begin
        if (Rounding <> 0) and (Value <> 0) then begin
            Value += Rounding;
            Rounding := 0;
        end;
    end;

    local procedure UpdateNonDeductibleAmounts(var NonDeductibleBase: Decimal; var NonDeductibleAmount: Decimal; VATBase: Decimal; VATAmount: Decimal; NonDeductibleVATPct: Decimal; AmountRoundingPrecision: Decimal)
    begin
        if not IsNonDeductibleVATEnabled() then begin
            NonDeductibleBase := 0;
            NonDeductibleAmount := 0;
            exit;
        end;
        NonDeductibleBase :=
            Round(VATBase * NonDeductibleVATPct / 100, AmountRoundingPrecision);
        NonDeductibleAmount :=
            Round(VATAmount * NonDeductibleVATPct / 100, AmountRoundingPrecision);
    end;

    local procedure UpdateNonDeductibleAmountsWithRounding(var NonDeductibleBase: Decimal; var NonDeductibleAmount: Decimal; var NonDedVATBaseRounding: Decimal; var NonDedVATAmountRounding: Decimal; VATBase: Decimal; VATAmount: Decimal; NonDeductibleVATPct: Decimal; Currency: Record Currency)
    begin
        if not IsNonDeductibleVATEnabled() then
            exit;

        if NonDeductibleVATPct = 0 then
            exit;

        NonDeductibleAmount := GetNonDeductibleAmount(VATAmount, NonDeductibleVATPct, Currency."Amount Rounding Precision", NonDedVATAmountRounding);
        NonDeductibleBase := GetNonDeductibleAmount(VATBase, NonDeductibleVATPct, Currency."Amount Rounding Precision", NonDedVATBaseRounding);
    end;

    local procedure GetNonDeductibleVATPct(PurchaseLine: Record "Purchase Line") NonDeductibleVATPct: Decimal
    var
        GeneralPostingType: Enum "General Posting Type";
        IsHandled: Boolean;
    begin
        NonDeductibleVAT.OnBeforeGetNonDeductibleVATPctForPurchLine(NonDeductibleVATPct, PurchaseLine, IsHandled);
        if IsHandled then
            exit(NonDeductibleVATPct);
        exit(GetNonDeductibleVATPct(PurchaseLine."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group", GeneralPostingType::Purchase));
    end;

    local procedure GetNonDeductibleVATPct(GenJournalLine: Record "Gen. Journal Line") NonDeductibleVATPct: Decimal
    var
        VATPostingSetup: Record "VAT Posting Setup";
        IsHandled: Boolean;
    begin
        if not IsNonDeductibleVATEnabled() then
            exit;
        NonDeductibleVAT.OnBeforeGetNonDedVATPctForGenJnlLine(NonDeductibleVATPct, GenJournalLine, IsHandled);
        if IsHandled then
            exit(NonDeductibleVATPct);
        if not (GenJournalLine."VAT Calculation Type" in [GenJournalLine."VAT Calculation Type"::"Normal VAT", GenJournalLine."VAT Calculation Type"::"Reverse Charge VAT", GenJournalLine."VAT Calculation Type"::"Full VAT"]) then
            exit(0);
        if not VATPostingSetup.Get(GenJournalLine."VAT Bus. Posting Group", GenJournalLine."VAT Prod. Posting Group") then
            exit(0);
        exit(GetNonDeductibleVATPct(VATPostingSetup, GenJournalLine."Gen. Posting Type"));
    end;

    local procedure GetBalNonDeductibleVATPct(GenJournalLine: Record "Gen. Journal Line") NonDeductibleVATPct: Decimal
    var
        VATPostingSetup: Record "VAT Posting Setup";
        IsHandled: Boolean;
    begin
        if not IsNonDeductibleVATEnabled() then
            exit;
        NonDeductibleVAT.OnBeforeGetBalNonDedVATPctForGenJnlLine(NonDeductibleVATPct, GenJournalLine, IsHandled);
        if IsHandled then
            exit(NonDeductibleVATPct);
        if not (GenJournalLine."Bal. VAT Calculation Type" in [GenJournalLine."Bal. VAT Calculation Type"::"Normal VAT", GenJournalLine."Bal. VAT Calculation Type"::"Reverse Charge VAT"]) then
            exit(0);
        if not VATPostingSetup.Get(GenJournalLine."Bal. VAT Bus. Posting Group", GenJournalLine."Bal. VAT Prod. Posting Group") then
            exit(0);
        exit(GetNonDeductibleVATPct(VATPostingSetup, GenJournalLine."Bal. Gen. Posting Type"));
    end;

    local procedure GetNonDedVATPctFromGenJournalLine(GenJournalLine: Record "Gen. Journal Line"): Decimal
    begin
        exit(GenJournalLine."Non-Deductible VAT %");
    end;

    local procedure GetBalNonDedVATPctFromGenJournalLine(GenJournalLine: Record "Gen. Journal Line"): Decimal
    begin
        exit(GenJournalLine."Bal. Non-Ded. VAT %");
    end;

    local procedure GetInvPostBufferAmountRoundingPrecision(DocAmountRoundingPrecision: Decimal): Decimal
    begin
        GeneralLedgerSetup.GetRecordOnce();
        if GeneralLedgerSetup."Amount Rounding Precision" > DocAmountRoundingPrecision then
            exit(GeneralLedgerSetup."Amount Rounding Precision");
        exit(DocAmountRoundingPrecision);
    end;

    local procedure IsNormalVATInvoiceForVendor(GenJournalLine: Record "Gen. Journal Line"): Boolean
    var
        Vendor: Record Vendor;
    begin
        if (GenJournalLine."Document Type" = GenJournalLine."Document Type"::Invoice) and
            (GenJournalLine."VAT Calculation Type" = GenJournalLine."VAT Calculation Type"::"Normal VAT") and
            (Vendor.Get(GenJournalLine."Bill-to/Pay-to No.") and (Vendor."Prices Including VAT")) then
            exit(true);
        exit(false);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company-Initialize", 'OnCompanyInitialize', '', false, false)]
    local procedure CreateVATSetupOnCompanyInitialize()
    var
        VATSetup: Record "VAT Setup";
    begin
        if VATSetup.Get() then
            exit;
        VATSetup.Insert(true);
    end;
}