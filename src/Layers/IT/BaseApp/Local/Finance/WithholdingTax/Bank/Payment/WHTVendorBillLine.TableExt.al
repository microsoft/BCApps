// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Finance.Currency;
using Microsoft.Finance.WithholdingTax;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;

tableextension 12182 "WHT Vendor Bill Line" extends "Vendor Bill Line"
{
    fields
    {
        field(61; "Withholding Tax Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrCode();
            AutoFormatType = 1;
            Caption = 'Withholding Tax Amount';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(62; "Social Security Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrCode();
            AutoFormatType = 1;
            Caption = 'Social Security Amount';
            DataClassification = CustomerContent;
            Editable = false;
        }
        modify("Amount to Pay")
        {
            trigger OnAfterValidate()
            begin
                if ("Withholding Tax Amount" <> 0) or ("Social Security Amount" <> 0) then
                    Message(RecalculateMsg, FieldCaption("Withholding Tax Amount"), FieldCaption("Social Security Amount"));
            end;
        }
    }

    trigger OnInsert()
    begin
        CreateVendBillWithhTax();
    end;

    trigger OnDelete()
    begin
        if GetVendBillWithhTax() then
            VendBillWithhTax.Delete();
    end;

    var
        VendBillWithhTax: Record "Vendor Bill Withholding Tax";
        WithholdCode: Code[20];
        SocialSecurityCode: Code[20];
        RecalculateMsg: Label 'Please recalculate %1 and %2 from the Withholding - INPS.', Comment = '%1 - Withholding Tax Amount, %2 - Social Security Amount';

    [Scope('OnPrem')]
    procedure CreateVendBillWithhTax()
    var
        Vend: Record Vendor;
        VendorBillHeader: Record "Vendor Bill Header";
        CompWithhTax: Record "Computed Withholding Tax";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        WithholdCodeLine: Record "Withhold Code Line";
    begin
        if Vend.Get("Vendor No.") then
            if not "Manual Line" and (Vend."Withholding Tax Code" = '') then
                exit;
        if VendorBillHeader.Get("Vendor Bill List No.") then;
        if not GetVendBillWithhTax() then begin
            if not "Manual Line" then begin
                CompWithhTax.Reset();
                CompWithhTax.SetCurrentKey("Vendor No.", "Document Date", "Document No.");
                CompWithhTax.SetRange("Vendor No.", "Vendor No.");
                CompWithhTax.SetRange("Document No.", "Document No.");
                if CompWithhTax.FindFirst() then begin
                    InitValues();
                    VendBillWithhTax."Payment Date" := VendorBillHeader."Posting Date";
                    VendBillWithhTax."Currency Code" := CompWithhTax."Currency Code";
                    VendBillWithhTax."External Document No." := CompWithhTax."External Document No.";
                    VendBillWithhTax."Related Date" := CompWithhTax."Related Date";
                    if CompWithhTax."Payment Date" <> 0D then
                        VendBillWithhTax."Payment Date" := CompWithhTax."Payment Date";
                    VendBillWithhTax."Withholding Tax Code" := CompWithhTax."Withholding Tax Code";
                    UpdateVendBillWithhTaxWHTAmounts(VendBillWithhTax, CompWithhTax);
                    UpdateVendBillWithhTaxSocSecAmounts(VendBillWithhTax);
                end else
                    if Vend.Get("Vendor No.") and (Vend."Withholding Tax Code" <> '') then begin
                        InitValues();
                        VendBillWithhTax."Payment Date" := VendorBillHeader."Posting Date";
                        VendBillWithhTax."Social Security Code" := Vend."Social Security Code";
                        VendBillWithhTax.Validate("Withholding Tax Code", Vend."Withholding Tax Code");
                    end;
            end else
                if WithholdCode <> '' then begin
                    InitValues();
                    VendBillWithhTax."Payment Date" := VendorBillHeader."Posting Date";
                    VendBillWithhTax."Currency Code" := VendorBillHeader."Currency Code";
                    VendBillWithhTax."External Document No." := "External Document No.";
                    VendBillWithhTax."Related Date" := VendorBillHeader."Posting Date";
                    VendBillWithhTax."Withholding Tax Code" := WithholdCode;
                    VendBillWithhTax."Social Security Code" := SocialSecurityCode;
                    VendBillWithhTax.Validate("Total Amount", "Amount to Pay");
                    VendBillWithhTax."Old Withholding Amount" := VendBillWithhTax."Withholding Tax Amount";
                    VendBillWithhTax."Old Free-Lance Amount" := VendBillWithhTax."Free-Lance Amount";
                end;
            OnCreateVendBillWithhTaxOnBeforeVendBillWithhTaxInsert(VendBillWithhTax, Vend);
            if VendBillWithhTax."Withholding Tax Code" <> '' then
                VendBillWithhTax.Insert();
            OnCreateVendBillWithhTaxOnAfterVendBillWithhTaxInsert(VendBillWithhTax);
        end;

        if ("Vendor Entry No." <> 0) and (VendBillWithhTax."Withholding Tax Amount" = 0) then begin
            VendorLedgerEntry.Get("Vendor Entry No.");
            WithholdCodeLine.SetRange("Withhold Code", VendBillWithhTax."Withholding Tax Code");
            if WithholdCodeLine.FindFirst() then
                if VendorLedgerEntry."Purchase (LCY)" <> 0 then
                    "Withholding Tax Amount" := -Round(
                        (VendorLedgerEntry."Purchase (LCY)" *
                        WithholdCodeLine."Taxable Base %" *
                        VendBillWithhTax."Withholding Tax %") / 10000,
                        GetCurrencyAmtRoundingPrecision(VendBillWithhTax."Currency Code"));
        end;

        if ("Withholding Tax Amount" = 0) or (VendBillWithhTax."Withholding Tax Amount" = 0) then
            "Withholding Tax Amount" := VendBillWithhTax."Withholding Tax Amount";

        "Social Security Amount" := VendBillWithhTax."Total Social Security Amount";
        "Amount to Pay" := "Remaining Amount" - "Withholding Tax Amount" - VendBillWithhTax."Free-Lance Amount";
    end;

    local procedure GetCurrencyAmtRoundingPrecision(CurrencyCode: Code[20]): Decimal
    var
        Currency: Record Currency;
    begin
        if CurrencyCode = '' then
            Currency.InitRoundingPrecision()
        else
            Currency.Get(CurrencyCode);

        exit(Currency."Amount Rounding Precision");
    end;

    local procedure UpdateVendBillWithhTaxWHTAmounts(var VendorBillWithholdingTax: Record "Vendor Bill Withholding Tax"; ComputedWithholdingTax: Record "Computed Withholding Tax")
    var
        TotalPaymentAmt: Decimal;
    begin
        OnBeforeUpdateVendBillWithhTaxWHTAmounts(VendorBillWithholdingTax, ComputedWithholdingTax);

        TotalPaymentAmt := CalcTotalAmountFromVendLedgEntry();
        if TotalPaymentAmt * "Remaining Amount" <> 0 then
            VendorBillWithholdingTax."Total Amount" := Abs(ComputedWithholdingTax."Total Amount");
        VendorBillWithholdingTax."Original Total Amount" := Abs(ComputedWithholdingTax."Total Amount");
        VendorBillWithholdingTax."Base - Excluded Amount" := ComputedWithholdingTax."Remaining - Excluded Amount";
        VendorBillWithholdingTax.Validate("Non Taxable Amount By Treaty", ComputedWithholdingTax."Non Taxable Remaining Amount");
        if ComputedWithholdingTax."WHT Amount Manual" <> 0 then
            VendorBillWithholdingTax."Withholding Tax Amount" := ComputedWithholdingTax."WHT Amount Manual";
        VendorBillWithholdingTax."Old Withholding Amount" := VendorBillWithholdingTax."Withholding Tax Amount";
        VendorBillWithholdingTax."Old Free-Lance Amount" := VendorBillWithholdingTax."Free-Lance Amount";

        OnAfterUpdateVendBillWithTaxWHTAmounts(VendorBillWithholdingTax, ComputedWithholdingTax);
    end;

    local procedure UpdateVendBillWithhTaxSocSecAmounts(var VendorBillWithholdingTax: Record "Vendor Bill Withholding Tax")
    var
        ComputedContribution: Record "Computed Contribution";
    begin
        ComputedContribution.SetCurrentKey("Vendor No.", "Document Date", "Document No.");
        ComputedContribution.SetRange("Vendor No.", "Vendor No.");
        ComputedContribution.SetRange("Document No.", "Document No.");
        if ComputedContribution.FindFirst() then begin
            VendorBillWithholdingTax."Social Security Code" := ComputedContribution."Social Security Code";
            VendorBillWithholdingTax.Validate("Gross Amount", ComputedContribution."Remaining Gross Amount");
            VendorBillWithholdingTax.Validate("Soc.Sec.Non Taxable Amount", ComputedContribution."Remaining Soc.Sec. Non Taxable");
            VendorBillWithholdingTax.Validate("Free-Lance Amount", ComputedContribution."Remaining Free-Lance Amount");
        end;
    end;

    local procedure CalcTotalAmountFromVendLedgEntry(): Decimal
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        TotalAmountABS: Decimal;
    begin
        VendorLedgerEntry.SetRange("Document Type", "Document Type");
        VendorLedgerEntry.SetRange("Document No.", "Document No.");
        VendorLedgerEntry.SetRange("Vendor No.", "Vendor No.");
        if VendorLedgerEntry.FindSet() then
            repeat
                VendorLedgerEntry.CalcFields(Amount);
                TotalAmountABS += Abs(VendorLedgerEntry.Amount);
            until VendorLedgerEntry.Next() = 0;
        exit(TotalAmountABS);
    end;

    [Scope('OnPrem')]
    procedure ShowVendorBillWithhTax(Open: Boolean)
    var
        VendBillWithholdTax: Page "Vendor Bill Withh. Tax";
    begin
        VendBillWithhTax.Get("Vendor Bill List No.", "Line No.");
        VendBillWithholdTax.SetRecord(VendBillWithhTax);
        VendBillWithholdTax.SetValues(Open);
        VendBillWithholdTax.RunModal();
    end;

    [Scope('OnPrem')]
    procedure InitValues()
    begin
        VendBillWithhTax.Init();
        VendBillWithhTax."Vendor Bill List No." := "Vendor Bill List No.";
        VendBillWithhTax."Line No." := "Line No.";
        VendBillWithhTax."Document Date" := "Document Date";
        VendBillWithhTax."Invoice No." := "Document No.";
        VendBillWithhTax."Vendor No." := "Vendor No.";
    end;

    procedure GetVendBillWithhTax(): Boolean
    begin
        if (VendBillWithhTax."Vendor Bill List No." = "Vendor Bill List No.") and
           (VendBillWithhTax."Line No." = "Line No.")
        then
            exit(true);
        if VendBillWithhTax.Get("Vendor Bill List No.", "Line No.") then
            exit(true);
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure SetWithholdCode(WithholdingCode: Code[20])
    begin
        WithholdCode := WithholdingCode;
    end;

    [Scope('OnPrem')]
    procedure SetSocialSecurityCode(SocSecCode: Code[20])
    begin
        SocialSecurityCode := SocSecCode;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateVendBillWithTaxWHTAmounts(var VendorBillWithholdingTax: Record "Vendor Bill Withholding Tax"; ComputedWithholdingTax: Record "Computed Withholding Tax")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateVendBillWithhTaxOnAfterVendBillWithhTaxInsert(var VendorBillWithholdingTax: Record "Vendor Bill Withholding Tax")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateVendBillWithhTaxOnBeforeVendBillWithhTaxInsert(var VendorBillWithholdingTax: Record "Vendor Bill Withholding Tax"; var Vendor: Record Vendor)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateVendBillWithhTaxWHTAmounts(var VendorBillWithholdingTax: Record "Vendor Bill Withholding Tax"; ComputedWithholdingTax: Record "Computed Withholding Tax")
    begin
    end;
}