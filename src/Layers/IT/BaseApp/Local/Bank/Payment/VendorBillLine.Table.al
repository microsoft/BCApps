// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.WithholdingTax;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.Reminder;

table 12182 "Vendor Bill Line"
{
    Caption = 'Vendor Bill Line';
    Permissions = TableData "Vendor Ledger Entry" = m;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Vendor Bill List No."; Code[20])
        {
            Caption = 'Vendor Bill List No.';
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(5; Description; Text[45])
        {
            Caption = 'Description';
        }
        field(6; "Description 2"; Text[45])
        {
            Caption = 'Description 2';
        }
        field(10; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor;
        }
        field(11; "Vendor Name"; Text[100])
        {
            CalcFormula = lookup(Vendor.Name where("No." = field("Vendor No.")));
            Caption = 'Vendor Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12; "Vendor Bank Acc. No."; Code[20])
        {
            Caption = 'Vendor Bank Acc. No.';
            TableRelation = "Vendor Bank Account".Code where("Vendor No." = field("Vendor No."));
        }
        field(14; "Vendor Bill No."; Code[20])
        {
            Caption = 'Vendor Bill No.';
        }
        field(20; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
        }
        field(21; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = if ("Document Type" = const(Invoice)) "Purch. Inv. Header"
            else
            if ("Document Type" = const("Credit Memo")) "Purch. Cr. Memo Hdr."
            else
            if ("Document Type" = const("Finance Charge Memo")) "Finance Charge Memo Header"
            else
            if ("Document Type" = const(Reminder)) "Reminder Header";
        }
        field(22; "Document Occurrence"; Integer)
        {
            Caption = 'Document Occurrence';
        }
        field(23; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(24; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(25; "Instalment Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrCode();
            AutoFormatType = 1;
            Caption = 'Instalment Amount';
            Editable = false;
        }
        field(26; "Remaining Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrCode();
            AutoFormatType = 1;
            Caption = 'Remaining Amount';
            Editable = false;
        }
        field(27; "Amount to Pay"; Decimal)
        {
            AutoFormatExpression = GetCurrCode();
            AutoFormatType = 1;
            Caption = 'Amount to Pay';

            trigger OnValidate()
            begin
                if ("Amount to Pay" > "Remaining Amount") or
                   ("Amount to Pay" <= 0)
                then
                    Error(Text1130001,
                      FieldCaption("Amount to Pay"),
                      "Remaining Amount");

                if ("Withholding Tax Amount" <> 0) or ("Social Security Amount" <> 0) then
                    Message(Text12101, FieldCaption("Withholding Tax Amount"), FieldCaption("Social Security Amount"));
            end;
        }
        field(30; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        field(31; "Beneficiary Value Date"; Date)
        {
            Caption = 'Beneficiary Value Date';
        }
        field(34; "Cumulative Transfers"; Boolean)
        {
            Caption = 'Cumulative Transfers';
        }
        field(45; "Vendor Entry No."; Integer)
        {
            Caption = 'Vendor Entry No.';
        }
        field(50; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
        }
        field(60; "Transfer Type"; Option)
        {
            Caption = 'Transfer Type';
            OptionCaption = 'Transfer,Salary';
            OptionMembers = Transfer,Salary;
        }
        field(61; "Withholding Tax Amount"; Decimal)
        {
            Caption = 'Withholding Tax Amount';
            Editable = false;
        }
        field(62; "Social Security Amount"; Decimal)
        {
            Caption = 'Social Security Amount';
            Editable = false;
        }
        field(63; "Gross Amount to Pay"; Decimal)
        {
            Caption = 'Gross Amount to Pay';
            Editable = false;
        }
        field(64; "Manual Line"; Boolean)
        {
            Caption = 'Manual Line';
            Editable = false;
        }
        field(65; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                Rec.ShowDimensions();
            end;
        }
        field(66; "Has Payment Export Error"; Boolean)
        {
            CalcFormula = exist("Payment Jnl. Export Error Text" where("Journal Line No." = field("Line No."),
                                                                        "Document No." = field("Vendor Bill List No.")));
            Caption = 'Has Payment Export Error';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Vendor Bill List No.", "Line No.")
        {
            Clustered = true;
            SumIndexFields = "Amount to Pay";
        }
        key(Key2; "Vendor No.", "External Document No.", "Document Date")
        {
        }
        key(Key3; "Vendor Bill List No.", "Vendor No.", "Due Date", "Vendor Bank Acc. No.", "Cumulative Transfers")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        if not "Manual Line" then begin
            VendLedgEntry.Get("Vendor Entry No.");
            if VendLedgEntry.Open then begin
                VendLedgEntry."Vendor Bill List" := '';
                VendLedgEntry."Vendor Bill No." := '';
            end;
            VendLedgEntry.Modify();
        end;
        if GetVendBillWithhTax() then
            VendBillWithhTax.Delete();
        DeletePaymentFileErrors();
    end;

    trigger OnInsert()
    begin
        CreateVendBillWithhTax();
    end;

    var
        VendorBillHeader: Record "Vendor Bill Header";
        Text1130001: Label '%1 must not be less than zero or greater than %2.';
        VendBillWithhTax: Record "Vendor Bill Withholding Tax";
        DimMgt: Codeunit DimensionManagement;
        WithholdCode: Code[20];
        SocialSecurityCode: Code[20];
        Text12100: Label 'Invoice %1 does not exist.';
        Text12101: Label 'Please recalculate %1 and %2 from the Withholding - INPS.';

    [Scope('OnPrem')]
    procedure GetCurrCode(): Code[10]
    begin
        if VendorBillHeader.Get("Vendor Bill List No.") then
            exit(VendorBillHeader."Currency Code");
        exit('');
    end;

    [Scope('OnPrem')]
    procedure EditDimensions()
    begin
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet("Dimension Set ID", StrSubstNo('%1 %2 %3', "Document Type", "Document No.", "Line No."));
    end;

    [Scope('OnPrem')]
    procedure ShowDimensions()
    begin
        if "Manual Line" then
            EditDimensions()
        else
            ShowPurchInvDimensions();
    end;

    [Scope('OnPrem')]
    procedure ShowPurchInvDimensions()
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2 %3', TableCaption(), "Document No.", "Line No."));
    end;

    [Scope('OnPrem')]
    procedure ShowInvoice()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PostedPurchInv: Page "Posted Purchase Invoice";
    begin
        if not "Manual Line" then begin
            PurchInvHeader.Get("Document No.");
            PostedPurchInv.SetRecord(PurchInvHeader);
            PostedPurchInv.RunModal();
        end else
            Error(Text12100, "Document No.");
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
    procedure CreateVendBillWithhTax()
    var
        Vend: Record Vendor;
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
                        VendBillWithhTax."Social Security Code" := Vend."Social Security Code";
                        VendBillWithhTax.Validate("Withholding Tax Code", Vend."Withholding Tax Code");
                    end;
            end else
                if WithholdCode <> '' then begin
                    InitValues();
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

    [Scope('OnPrem')]
    procedure InitValues()
    begin
        VendBillWithhTax.Init();
        VendBillWithhTax."Vendor Bill List No." := "Vendor Bill List No.";
        VendBillWithhTax."Line No." := "Line No.";
        VendBillWithhTax."Document Date" := "Document Date";
        VendBillWithhTax."Invoice No." := "Document No.";
        VendBillWithhTax."Vendor No." := "Vendor No.";
        VendBillWithhTax."Payment Date" := VendorBillHeader."Posting Date";
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
    procedure DeletePaymentFileErrors()
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine."Journal Template Name" := '';
        GenJnlLine."Journal Batch Name" := '';
        GenJnlLine."Document No." := "Vendor Bill List No.";
        GenJnlLine."Line No." := "Line No.";
        GenJnlLine.DeletePaymentFileErrors();
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
