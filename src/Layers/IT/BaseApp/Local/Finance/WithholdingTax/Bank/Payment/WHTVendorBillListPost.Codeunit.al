// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.WithholdingTax;
using Microsoft.Purchases.Payables;

codeunit 12243 "WHT Vendor Bill List - Post"
{

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Vendor Bill List - Post", 'OnAfterPostVendorBillLine', '', true, true)]
    local procedure OnAfterPostVendorBillLine(VendorBillHeader: Record "Vendor Bill Header"; VendorBillLine: Record "Vendor Bill Line"; VendLedgEntry: Record "Vendor Ledger Entry"; GenJnlLine: Record "Gen. Journal Line"; BillCode: Record Bill; TaxType: Option " ",Withhold,"Free Lance",Company; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    var
        VendBillWithhTax: Record "Vendor Bill Withholding Tax";
        TempWithholdingSocSec: Record "Tmp Withholding Contribution" temporary;
        WithholdingSocSec: Codeunit "Withholding - Contribution";
    begin
        if VendBillWithhTax.Get(VendorBillLine."Vendor Bill List No.", VendorBillLine."Line No.") then begin
            if (VendBillWithhTax."Withholding Tax Code" <> '') and (VendBillWithhTax."Withholding Tax Amount" <> 0) then
                PostTax(VendorBillHeader, VendorBillLine, VendBillWithhTax, VendLedgEntry, BillCode, TaxType::Withhold, GenJnlPostLine);
            if (VendBillWithhTax."Social Security Code" <> '') and (VendBillWithhTax."Free-Lance Amount" <> 0) then
                PostTax(VendorBillHeader, VendorBillLine, VendBillWithhTax, VendLedgEntry, BillCode, TaxType::"Free Lance", GenJnlPostLine);
            if (VendBillWithhTax."Social Security Code" <> '') and (VendBillWithhTax."Company Amount" <> 0) then
                PostTax(VendorBillHeader, VendorBillLine, VendBillWithhTax, VendLedgEntry, BillCode, TaxType::Company, GenJnlPostLine);

            OnAfterPostTax(VendorBillHeader, VendorBillLine, VendBillWithhTax, VendLedgEntry, BillCode, TaxType, GenJnlPostLine);

            TempWithholdingSocSec.TransferFields(VendBillWithhTax);
            WithholdingSocSec.PostPayments(TempWithholdingSocSec, GenJnlLine, true);
        end;
    end;

    local procedure PostTax(VendorBillHeader: Record "Vendor Bill Header"; VendorBillLine: Record "Vendor Bill Line"; VendorBillWithholdingTax: Record "Vendor Bill Withholding Tax"; VendLedgEntry: Record "Vendor Ledger Entry"; Bill: Record Bill; TaxType: Option " ",Withhold,"Free Lance",Company; var sender: Codeunit "Gen. Jnl.-Post Line")
    var
        GenJnlLine: Record "Gen. Journal Line";
        WithholdCode: Record "Withhold Code";
        ContributionCode: Record "Contribution Code";
        VendorBillListPost: Codeunit "Vendor Bill List - Post";
    begin
        GenJnlLine.Init();
        GenJnlLine.Validate("Posting Date", VendorBillHeader."Posting Date");
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;
        GenJnlLine."Document No." := VendorBillHeader."Vendor Bill List No.";
        GenJnlLine."Document Date" := VendorBillHeader."List Date";
        GenJnlLine."External Document No." := VendorBillLine."Vendor Bill List No.";
        case TaxType of
            TaxType::Withhold:
                begin
                    WithholdCode.Get(VendorBillWithholdingTax."Withholding Tax Code");
                    GenJnlLine."Account Type" := GenJnlLine."Account Type"::Vendor;
                    GenJnlLine.Validate("Account No.", VendorBillLine."Vendor No.");
                    GenJnlLine.Validate(Amount, VendorBillLine."Withholding Tax Amount");
                    WithholdCode.TestField("Withholding Taxes Payable Acc.");
                    GenJnlLine."Bal. Account No." := WithholdCode."Withholding Taxes Payable Acc.";
                end;
            TaxType::"Free Lance":
                begin
                    ContributionCode.Get(VendorBillWithholdingTax."Social Security Code");
                    GenJnlLine."Account Type" := GenJnlLine."Account Type"::Vendor;
                    GenJnlLine.Validate("Account No.", VendorBillLine."Vendor No.");
                    GenJnlLine.Validate(Amount, VendorBillWithholdingTax."Free-Lance Amount");
                    ContributionCode.TestField("Social Security Payable Acc.");
                    GenJnlLine."Bal. Account No." := ContributionCode."Social Security Payable Acc.";
                end;
            TaxType::Company:
                begin
                    ContributionCode.Get(VendorBillWithholdingTax."Social Security Code");
                    GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
                    ContributionCode.TestField("Social Security Charges Acc.");
                    GenJnlLine.Validate("Account No.", ContributionCode."Social Security Charges Acc.");
                    GenJnlLine.Validate(Amount, VendorBillWithholdingTax."Company Amount");
                    ContributionCode.TestField("Social Security Payable Acc.");
                    GenJnlLine."Bal. Account No." := ContributionCode."Social Security Payable Acc.";
                end;
        end;
        GenJnlLine.Validate("Currency Code", VendorBillHeader."Currency Code");
        if not VendorBillLine."Manual Line" then begin
            GenJnlLine.Validate("Salespers./Purch. Code", VendLedgEntry."Purchaser Code");
            VendorBillListPost.ApplyInvAndUpdateLedgEntry(GenJnlLine, VendorBillLine, TaxType);
        end;
        GenJnlLine.Description := Bill.Description;
        GenJnlLine."Source Code" := Bill."Vend. Bill Source Code";
        GenJnlLine."System-Created Entry" := true;
        GenJnlLine."Reason Code" := VendorBillHeader."Reason Code";
        GenJnlLine."Shortcut Dimension 1 Code" := VendLedgEntry."Global Dimension 1 Code";
        GenJnlLine."Shortcut Dimension 2 Code" := VendLedgEntry."Global Dimension 2 Code";
        if not VendorBillLine."Manual Line" then
            GenJnlLine."Dimension Set ID" := VendLedgEntry."Dimension Set ID"
        else
            GenJnlLine."Dimension Set ID" := VendorBillLine."Dimension Set ID";

        OnBeforePostWithholdingTax(GenJnlLine, VendorBillHeader, VendorBillLine, VendLedgEntry, VendorBillWithholdingTax);
        sender.RunWithCheck(GenJnlLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostTax(var VendorBillHeader: Record "Vendor Bill Header"; var VendorBillLine: Record "Vendor Bill Line"; var VendBillWithhTax: Record "Vendor Bill Withholding Tax"; var VendLedgEntry: Record "Vendor Ledger Entry"; BillCode: Record Bill; TaxType: Option; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostWithholdingTax(var GenJnlLine: Record "Gen. Journal Line"; VendorBillHeader: Record "Vendor Bill Header"; VendorBillLine: Record "Vendor Bill Line"; VendLedgEntry: Record "Vendor Ledger Entry"; VendorBillWithholdingTax: Record "Vendor Bill Withholding Tax")
    begin
    end;
}