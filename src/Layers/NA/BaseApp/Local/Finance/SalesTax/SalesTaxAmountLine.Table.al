// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SalesTax;

using Microsoft.Finance.Currency;

table 10011 "Sales Tax Amount Line"
{
    Caption = 'Sales Tax Amount Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            TableRelation = "Tax Area";
        }
        field(2; "Tax Jurisdiction Code"; Code[10])
        {
            Caption = 'Tax Jurisdiction Code';
            TableRelation = "Tax Jurisdiction";
        }
        field(3; "Tax %"; Decimal)
        {
            Caption = 'Tax %';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(4; "Tax Base Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Tax Base Amount';
            Editable = false;
        }
        field(5; "Tax Amount"; Decimal)
        {
            Caption = 'Tax Amount';

            trigger OnValidate()
            begin
                TestField("Tax %");
                TestField("Tax Base Amount");
                if "Tax Amount" / "Tax Base Amount" < 0 then
                    Error(Text002, FieldCaption("Tax Amount"));
                "Tax Difference" := "Tax Difference" + "Tax Amount" - xRec."Tax Amount";
            end;
        }
        field(6; "Amount Including Tax"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount Including Tax';
            Editable = false;
        }
        field(7; "Line Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Line Amount';
            Editable = false;
        }
        field(10; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            Editable = false;
            TableRelation = "Tax Group";
        }
        field(11; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(12; Modified; Boolean)
        {
            Caption = 'Modified';
        }
        field(13; "Use Tax"; Boolean)
        {
            Caption = 'Use Tax';
        }
        field(14; "Calculated Tax Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Calculated Tax Amount';
            Editable = false;
        }
        field(15; "Tax Difference"; Decimal)
        {
            Caption = 'Tax Difference';
            Editable = false;
        }
        field(16; "Tax Type"; Option)
        {
            Caption = 'Tax Type';
            OptionCaption = 'Sales and Use Tax,Excise Tax,Sales Tax Only,Use Tax Only';
            OptionMembers = "Sales and Use Tax","Excise Tax","Sales Tax Only","Use Tax Only";
        }
        field(17; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
        }
        field(20; "Tax Area Code for Key"; Code[20])
        {
            Caption = 'Tax Area Code for Key';
            TableRelation = "Tax Area";
        }
        field(25; "Invoice Discount Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Invoice Discount Amount';
            Editable = false;
        }
        field(26; "Inv. Disc. Base Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Inv. Disc. Base Amount';
            Editable = false;
        }
        field(10010; "Expense/Capitalize"; Boolean)
        {
            Caption = 'Expense/Capitalize';
        }
        field(10020; "Print Order"; Integer)
        {
            Caption = 'Print Order';
        }
        field(10030; "Print Description"; Text[100])
        {
            Caption = 'Print Description';
        }
        field(10040; "Calculation Order"; Integer)
        {
            Caption = 'Calculation Order';
        }
        field(10041; "Round Tax"; Option)
        {
            Caption = 'Round Tax';
            Editable = false;
            OptionCaption = 'To Nearest,Up,Down';
            OptionMembers = "To Nearest",Up,Down;
        }
        field(10042; "Is Report-to Jurisdiction"; Boolean)
        {
            Caption = 'Is Report-to Jurisdiction';
            Editable = false;
        }
        field(10043; Positive; Boolean)
        {
            Caption = 'Positive';
        }
        field(10044; "Tax Base Amount FCY"; Decimal)
        {
            Caption = 'Tax Base Amount FCY';
        }
    }

    keys
    {
        key(Key1; "Tax Area Code for Key", "Tax Jurisdiction Code", "Tax %", "Tax Group Code", "Expense/Capitalize", "Tax Type", "Use Tax", Positive)
        {
            Clustered = true;
        }
        key(Key2; "Print Order", "Tax Area Code for Key", "Tax Jurisdiction Code")
        {
        }
        key(Key3; "Tax Area Code for Key", "Tax Group Code", "Tax Type", "Calculation Order")
        {
        }
    }

    fieldgroups
    {
    }

    var
        Currency: Record Currency;
        AllowTaxDifference: Boolean;
        PricesIncludingTax: Boolean;
        Text000: Label '%1% Tax';
        Text001: Label 'Tax Amount';
        Text002: Label '%1 must not be negative.';
        Text004: Label '%1 for %2 must not exceed %3 = %4.';

    procedure CheckTaxDifference(NewCurrencyCode: Code[10]; NewAllowTaxDifference: Boolean; NewPricesIncludingTax: Boolean)
    begin
        InitGlobals(NewCurrencyCode, NewAllowTaxDifference, NewPricesIncludingTax);
        if not AllowTaxDifference then
            TestField("Tax Difference", 0);
        if Abs("Tax Difference") > Currency."Max. VAT Difference Allowed" then
            Error(
              Text004, FieldCaption("Tax Difference"), Currency.Code,
              Currency.FieldCaption("Max. VAT Difference Allowed"), Currency."Max. VAT Difference Allowed");
    end;

    local procedure InitGlobals(NewCurrencyCode: Code[10]; NewAllowTaxDifference: Boolean; NewPricesIncludingTax: Boolean)
    begin
        SetCurrency(NewCurrencyCode);
        AllowTaxDifference := NewAllowTaxDifference;
        PricesIncludingTax := NewPricesIncludingTax;
    end;

    local procedure SetCurrency(CurrencyCode: Code[10])
    begin
        if CurrencyCode = '' then
            Currency.InitRoundingPrecision()
        else
            Currency.Get(CurrencyCode);
    end;

    procedure TaxAmountText(): Text[30]
    var
        TaxAmountLine2: Record "Sales Tax Amount Line";
        TaxAreaCount: Integer;
        TaxPercent: Decimal;
    begin
        if FindFirst() then begin
            TaxAmountLine2 := Rec;
            TaxAreaCount := 1;
            repeat
                if "Tax Area Code" <> TaxAmountLine2."Tax Area Code" then begin
                    TaxAreaCount := TaxAreaCount + 1;
                    TaxAmountLine2 := Rec;
                end;
                TaxPercent := TaxPercent + "Tax %";
            until Next() = 0;
        end;
        if TaxPercent <> 0 then
            exit(StrSubstNo(Text000, TaxPercent / TaxAreaCount));
        exit(Text001);
    end;

    procedure GetTotalLineAmount(SubtractTax: Boolean; CurrencyCode: Code[10]): Decimal
    var
        LineAmount: Decimal;
    begin
        if SubtractTax then
            SetCurrency(CurrencyCode);

        LineAmount := 0;

        if Find('-') then
            repeat
                if SubtractTax then
                    LineAmount :=
                      LineAmount + Round("Line Amount" / (1 + "Tax %" / 100), Currency."Amount Rounding Precision")
                else
                    LineAmount := LineAmount + "Line Amount";
            until Next() = 0;

        exit(LineAmount);
    end;

    procedure GetTotalTaxAmount(): Decimal
    var
        TaxAmount: Decimal;
        PrevJurisdiction: Code[10];
    begin
        TaxAmount := 0;
        if Find('-') then
            repeat
                if PrevJurisdiction <> "Tax Jurisdiction Code" then begin
                    if "Tax Area Code for Key" = '' then     // indicates Canada
                        TaxAmount := Round(TaxAmount);
                    PrevJurisdiction := "Tax Jurisdiction Code";
                end;
                TaxAmount := TaxAmount + "Tax Amount";
            until Next() = 0;
        exit(TaxAmount);
    end;

    procedure GetTotalTaxAmountFCY(): Decimal
    var
        TaxAmount: Decimal;
        PrevJurisdiction: Code[10];
    begin
        if FindSet() then
            repeat
                if PrevJurisdiction <> "Tax Jurisdiction Code" then begin
                    if "Tax Area Code for Key" = '' then     // indicates Canada
                        TaxAmount := Round(TaxAmount);
                    PrevJurisdiction := "Tax Jurisdiction Code";
                end;
                if "Tax Type" = "Tax Type"::"Excise Tax" then
                    TaxAmount := TaxAmount + "Tax Amount"
                else
                    TaxAmount := TaxAmount + ("Tax Base Amount FCY" * "Tax %" / 100);
            until Next() = 0;
        exit(TaxAmount);
    end;

    procedure GetTotalTaxBase(): Decimal
    var
        TaxBase: Decimal;
    begin
        TaxBase := 0;

        if Find('-') then
            repeat
                TaxBase := TaxBase + "Tax Base Amount";
            until Next() = 0;
        exit(TaxBase);
    end;

    procedure GetTotalAmountInclTax(): Decimal
    var
        AmountInclTax: Decimal;
    begin
        AmountInclTax := 0;

        if Find('-') then
            repeat
                AmountInclTax := AmountInclTax + "Amount Including Tax";
            until Next() = 0;
        exit(AmountInclTax);
    end;

    procedure GetAnyLineModified(): Boolean
    begin
        if Find('-') then
            repeat
                if Modified then
                    exit(true);
            until Next() = 0;
        exit(false);
    end;

    procedure GetTotalInvDiscAmount(): Decimal
    var
        InvDiscAmount: Decimal;
    begin
        InvDiscAmount := 0;
        if Find('-') then
            InvDiscAmount := "Invoice Discount Amount";
        exit(InvDiscAmount);
    end;

    procedure SetInvoiceDiscountPercent(NewInvoiceDiscountPct: Decimal; NewCurrencyCode: Code[10]; NewPricesIncludingVAT: Boolean; CalcInvDiscPerVATID: Boolean; NewVATBaseDiscPct: Decimal)
    var
        NewRemainder: Decimal;
    begin
        InitGlobals(NewCurrencyCode, false, NewPricesIncludingVAT);
        if Find('-') then
            repeat
                if "Inv. Disc. Base Amount" <> 0 then begin
                    NewRemainder :=
                      NewRemainder + NewInvoiceDiscountPct * "Inv. Disc. Base Amount" / 100;
                    Validate(
                      "Invoice Discount Amount", Round(NewRemainder, Currency."Amount Rounding Precision"));
                    if CalcInvDiscPerVATID then
                        NewRemainder := 0
                    else
                        NewRemainder := NewRemainder - "Invoice Discount Amount";
                    Modified := true;
                    Modify();
                end;
            until Next() = 0;
    end;

    procedure GetTotalInvDiscBaseAmount(SubtractVAT: Boolean; CurrencyCode: Code[10]): Decimal
    var
        InvDiscBaseAmount: Decimal;
    begin
        if SubtractVAT then
            SetCurrency(CurrencyCode);

        InvDiscBaseAmount := 0;

        if Find('-') then
            repeat
                if SubtractVAT then
                    InvDiscBaseAmount :=
                      InvDiscBaseAmount +
                      Round("Inv. Disc. Base Amount" / (1 + "Tax %" / 100), Currency."Amount Rounding Precision")
                else
                    InvDiscBaseAmount := InvDiscBaseAmount + "Inv. Disc. Base Amount";
            until Next() = 0;
        exit(InvDiscBaseAmount);
    end;

    procedure SetInvoiceDiscountAmount(NewInvoiceDiscount: Decimal; NewCurrencyCode: Code[10]; NewPricesIncludingVAT: Boolean; NewVATBaseDiscPct: Decimal)
    var
        TotalInvDiscBaseAmount: Decimal;
        NewRemainder: Decimal;
    begin
        InitGlobals(NewCurrencyCode, false, NewPricesIncludingVAT);
        TotalInvDiscBaseAmount := GetTotalInvDiscBaseAmount(false, Currency.Code);
        if TotalInvDiscBaseAmount = 0 then
            exit;
        Find('-');
        repeat
            if "Inv. Disc. Base Amount" <> 0 then begin
                if TotalInvDiscBaseAmount = 0 then
                    NewRemainder := 0
                else
                    NewRemainder :=
                      NewRemainder + NewInvoiceDiscount * "Inv. Disc. Base Amount" / TotalInvDiscBaseAmount;
                Validate(
                  "Invoice Discount Amount", Round(NewRemainder, Currency."Amount Rounding Precision"));
                NewRemainder := NewRemainder - "Invoice Discount Amount";
                Modify();
            end;
        until Next() = 0;
    end;
}

