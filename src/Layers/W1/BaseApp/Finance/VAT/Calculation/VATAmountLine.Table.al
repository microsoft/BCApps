// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Calculation;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Clause;
using Microsoft.Foundation.Enums;
using Microsoft.Purchases.History;
using Microsoft.Sales.History;

#pragma warning disable AS0109
table 290 "VAT Amount Line"
{
    Caption = 'VAT Amount Line';
    DataClassification = CustomerContent;
#if not CLEAN25
    ObsoleteReason = 'Table will be made Temporary.';
    ObsoleteState = Pending;
    ObsoleteTag = '25.0';
#else
    TableType = Temporary;
#endif

    fields
    {
        field(1; "VAT %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'VAT %';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(2; "VAT Base"; Decimal)
        {
            Caption = 'VAT Base';
            Editable = false;
        }
        field(3; "VAT Amount"; Decimal)
        {
            Caption = 'VAT Amount';

            trigger OnValidate()
            begin
                TestField("VAT %");
                TestField("VAT Base");
                if "VAT Amount" / "VAT Base" < 0 then
                    Error(Text002, FieldCaption("VAT Amount"));
                "VAT Difference" := "VAT Amount" - "Calculated VAT Amount";
                NonDeductibleVAT.ValidateVATAmountInVATAmountLine(Rec);
            end;
        }
        field(4; "Amount Including VAT"; Decimal)
        {
            Caption = 'Amount Including VAT';
            Editable = false;
        }
        field(5; "VAT Identifier"; Code[20])
        {
            Caption = 'VAT Identifier';
            Editable = false;
        }
        field(6; "Line Amount"; Decimal)
        {
            Caption = 'Line Amount';
            Editable = false;
        }
        field(7; "Inv. Disc. Base Amount"; Decimal)
        {
            Caption = 'Inv. Disc. Base Amount';
            Editable = false;
        }
        field(8; "Invoice Discount Amount"; Decimal)
        {
            Caption = 'Invoice Discount Amount';

            trigger OnValidate()
            begin
                TestField("Inv. Disc. Base Amount");
                if "Invoice Discount Amount" / "Inv. Disc. Base Amount" > 1 then
                    Error(
                      InvoiceDiscAmtIsGreaterThanBaseAmtErr,
                      FieldCaption("Invoice Discount Amount"), "Inv. Disc. Base Amount");
                "VAT Base" := CalcLineAmount();
            end;
        }
        field(9; "VAT Calculation Type"; Enum "Tax Calculation Type")
        {
            Caption = 'VAT Calculation Type';
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
            AutoFormatType = 0;
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
        field(14; "Calculated VAT Amount"; Decimal)
        {
            Caption = 'Calculated VAT Amount';
            Editable = false;
        }
        field(15; "VAT Difference"; Decimal)
        {
            Caption = 'VAT Difference';
            Editable = false;
        }
        field(16; Positive; Boolean)
        {
            Caption = 'Positive';
        }
        field(17; "Includes Prepayment"; Boolean)
        {
            Caption = 'Includes Prepayment';
        }
        field(18; "VAT Clause Code"; Code[20])
        {
            Caption = 'VAT Clause Code';
            TableRelation = "VAT Clause";
        }
        field(19; "Tax Category"; Code[10])
        {
            Caption = 'Tax Category';
        }
        field(20; "Pmt. Discount Amount"; Decimal)
        {
            Caption = 'Pmt. Discount Amount';
            Editable = false;
        }
        field(6200; "Non-Deductible VAT %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Non-Deductible VAT %';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(6201; "Non-Deductible VAT Base"; Decimal)
        {
            Caption = 'Non-Deductible VAT Base';
            Editable = false;
        }
        field(6202; "Non-Deductible VAT Amount"; Decimal)
        {
            Caption = 'Non-Deductible VAT Amount';

            trigger OnValidate()
            begin
                NonDeductibleVAT.ValidateNonDeductibleVATInVATAmountLine(Rec);
            end;
        }
        field(6203; "Calc. Non-Ded. VAT Amount"; Decimal)
        {
            Caption = 'Calculated Non-Deductible VAT Amount';
            Editable = false;
        }
        field(6204; "Deductible VAT Base"; Decimal)
        {
            Caption = 'Deductible VAT Base';
            Editable = false;
        }
        field(6205; "Deductible VAT Amount"; Decimal)
        {
            Caption = 'Deductible VAT Amount';
            Editable = false;
        }
        field(6206; "Non-Deductible VAT Diff."; Decimal)
        {
            Caption = 'Non-Deductible VAT Difference';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "VAT Identifier", "VAT Calculation Type", "Tax Group Code", "Use Tax", Positive)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        Currency: Record Currency;
        NonDeductibleVAT: Codeunit "Non-Deductible VAT";
        AllowVATDifference: Boolean;
        GlobalsInitialized: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%1% VAT';
#pragma warning restore AA0470
        Text001: Label 'VAT Amount';
#pragma warning disable AA0470
        Text002: Label '%1 must not be negative.';
        Text004: Label '%1 for %2 must not exceed %3 = %4.';
        Text005: Label '%1 must not exceed %2 = %3.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0470
        InvoiceDiscAmtIsGreaterThanBaseAmtErr: Label 'The maximum %1 that you can apply is %2.', Comment = '1 Invoice Discount Amount that should be set 2 Maximum Amount that you can assign';
#pragma warning restore AA0470

    procedure CheckVATDifference(NewCurrencyCode: Code[10]; NewAllowVATDifference: Boolean)
    var
        GLSetup: Record "General Ledger Setup";
    begin
        InitGlobals(NewCurrencyCode, NewAllowVATDifference);
        if not AllowVATDifference then
            TestField("VAT Difference", 0);
        if Abs("VAT Difference") > Currency."Max. VAT Difference Allowed" then
            if NewCurrencyCode <> '' then
                Error(
                  Text004, FieldCaption("VAT Difference"), Currency.Code,
                  Currency.FieldCaption("Max. VAT Difference Allowed"), Currency."Max. VAT Difference Allowed")
            else begin
                if GLSetup.Get() then;
                if Abs("VAT Difference") > GLSetup."Max. VAT Difference Allowed" then
                    Error(
                      Text005, FieldCaption("VAT Difference"),
                      GLSetup.FieldCaption("Max. VAT Difference Allowed"), GLSetup."Max. VAT Difference Allowed");
            end;

        OnAfterCheckVATDifference(Rec, NewCurrencyCode, NewAllowVATDifference);
    end;

    local procedure InitGlobals(NewCurrencyCode: Code[10]; NewAllowVATDifference: Boolean)
    begin
        if GlobalsInitialized then
            exit;

        Currency.Initialize(NewCurrencyCode);
        AllowVATDifference := NewAllowVATDifference;
        GlobalsInitialized := true;
    end;

    procedure InsertLine() Result: Boolean
    var
        VATAmountLine: Record "VAT Amount Line";
        IsHandled: Boolean;
        SkipZeroVatAmounts: Boolean;
    begin
        IsHandled := false;
        Result := true;
        SkipZeroVatAmounts := true;
        OnInsertLine(Rec, IsHandled, Result, SkipZeroVatAmounts);
        if IsHandled then
            exit(Result);

        if (("VAT Base" = 0) or ("Amount Including VAT" = 0)) and SkipZeroVatAmounts then
            exit(false);

        Validate(Positive, "Line Amount" >= 0);
        OnInsertLineOnAfterValidatePositive(Rec);
        VATAmountLine := Rec;
        if Find() then begin
            "Line Amount" += VATAmountLine."Line Amount";
            "Inv. Disc. Base Amount" += VATAmountLine."Inv. Disc. Base Amount";
            "Invoice Discount Amount" += VATAmountLine."Invoice Discount Amount";
            Quantity += VATAmountLine.Quantity;
            "VAT Base" += VATAmountLine."VAT Base";
            "Amount Including VAT" += VATAmountLine."Amount Including VAT";
            "VAT Difference" += VATAmountLine."VAT Difference";
            "Pmt. Discount Amount" += VATAmountLine."Pmt. Discount Amount";
            "VAT Amount" := "Amount Including VAT" - "VAT Base";
            "Calculated VAT Amount" += VATAmountLine."Calculated VAT Amount";
            NonDeductibleVAT.Increment(Rec, VATAmountLine);
            OnInsertLineOnBeforeModify(Rec, VATAmountLine);
            Modify();
        end else begin
            "VAT Amount" := "Amount Including VAT" - "VAT Base";
            OnInsertLineOnBeforeInsert(Rec, VATAmountLine);
            Insert();
        end;

        exit(true);
    end;

#if not CLEAN26
    [Obsolete('Replaced by procedures using Source Record.', '26.0')]
    procedure InsertNewLine(VATIdentifier: Code[20]; VATCalcType: Enum "Tax Calculation Type"; TaxGroupCode: Code[20]; UseTax: Boolean; TaxRate: Decimal; IsPositive: Boolean; IsPrepayment: Boolean; NonDeductibleVATPct: Decimal)
    begin
        Rec.Init();
        Rec."VAT Identifier" := VATIdentifier;
        Rec."VAT Calculation Type" := VATCalcType;
        Rec."Tax Group Code" := TaxGroupCode;
        Rec."Use Tax" := UseTax;
        Rec."VAT %" := TaxRate;
        Rec.Modified := true;
        Rec.Positive := IsPositive;
        Rec."Includes Prepayment" := IsPrepayment;
        Rec."Non-Deductible VAT %" := NonDeductibleVATPct;
        Rec.Insert();
    end;
#endif

    procedure GetLine(Number: Integer)
    begin
        if Number = 1 then
            Find('-')
        else
            Next();
    end;

    procedure VATAmountText() Result: Text[30]
    var
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        FullCount: Integer;
        VATPercentage: Decimal;
    begin
        VATPercentage := 0;
        FullCount := Count;
        if FullCount = 1 then begin
            FindFirst();
            if "VAT %" <> 0 then
                VATPercentage := "VAT %";
        end else
            if FullCount > 1 then begin
                CopyFromRec(TempVATAmountLine);
                TempVATAmountLine.FindFirst();
                if TempVATAmountLine."VAT %" <> 0 then begin
                    TempVATAmountLine.SetRange("VAT %", TempVATAmountLine."VAT %");
                    if TempVATAmountLine.Count = FullCount then
                        VATPercentage := TempVATAmountLine."VAT %";
                end;
            end;
        if VATPercentage = 0 then
            Result := Text001
        else
            Result := StrSubstNo(Text000, VATPercentage);
        OnAfterVATAmountText(VATPercentage, FullCount, Result);
    end;

    procedure GetTotalLineAmount(SubtractVAT: Boolean; CurrencyCode: Code[10]): Decimal
    var
        LineAmount: Decimal;
    begin
        if SubtractVAT then
            Currency.Initialize(CurrencyCode);

        LineAmount := 0;

        if Find('-') then
            repeat
                if SubtractVAT then
                    LineAmount :=
                      LineAmount + Round("Line Amount" / (1 + "VAT %" / 100), Currency."Amount Rounding Precision")
                else
                    LineAmount := LineAmount + "Line Amount";
            until Next() = 0;

        exit(LineAmount);
    end;

    procedure GetTotalVATAmount() VATAmount: Decimal
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetTotalVATAmount(Rec, VATAmount, IsHandled);
        if IsHandled then
            exit(VATAmount);

        CalcSums("VAT Amount");
        exit("VAT Amount");
    end;

    procedure GetTotalInvDiscAmount(): Decimal
    begin
        CalcSums("Invoice Discount Amount");
        exit("Invoice Discount Amount");
    end;

    procedure GetTotalInvDiscBaseAmount(SubtractVAT: Boolean; CurrencyCode: Code[10]): Decimal
    var
        InvDiscBaseAmount: Decimal;
    begin
        if SubtractVAT then
            Currency.Initialize(CurrencyCode);

        InvDiscBaseAmount := 0;

        if Find('-') then
            repeat
                if SubtractVAT then
                    InvDiscBaseAmount :=
                      InvDiscBaseAmount +
                      Round("Inv. Disc. Base Amount" / (1 + "VAT %" / 100), Currency."Amount Rounding Precision")
                else
                    InvDiscBaseAmount := InvDiscBaseAmount + "Inv. Disc. Base Amount";
            until Next() = 0;
        exit(InvDiscBaseAmount);
    end;

    procedure GetTotalVATBase(): Decimal
    begin
        CalcSums("VAT Base");
        exit("VAT Base");
    end;

    procedure GetTotalAmountInclVAT(): Decimal
    begin
        CalcSums("Amount Including VAT");
        exit("Amount Including VAT");
    end;

    procedure GetTotalVATDiscount(CurrencyCode: Code[10]; NewPricesIncludingVAT: Boolean): Decimal
    var
        VATDiscount: Decimal;
        VATBase: Decimal;
    begin
        Currency.Initialize(CurrencyCode);

        VATDiscount := 0;

        if Find('-') then
            repeat
                if NewPricesIncludingVAT then
                    VATBase += CalcLineAmount() * "VAT %" / (100 + "VAT %")
                else
                    VATBase += "VAT Base" * "VAT %" / 100;
                VATDiscount :=
                  VATDiscount +
                  Round(
                    VATBase,
                    Currency."Amount Rounding Precision", Currency.VATRoundingDirection()) -
                  "VAT Amount" + "VAT Difference";
                VATBase := VATBase - Round(VATBase, Currency."Amount Rounding Precision", Currency.VATRoundingDirection());
            until Next() = 0;
        exit(VATDiscount);
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

    procedure SetInvoiceDiscountAmount(NewInvoiceDiscount: Decimal; NewCurrencyCode: Code[10]; NewPricesIncludingVAT: Boolean; NewVATBaseDiscPct: Decimal)
    var
        TotalInvDiscBaseAmount: Decimal;
        NewRemainder: Decimal;
    begin
        InitGlobals(NewCurrencyCode, false);
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
                if "Invoice Discount Amount" <> Round(NewRemainder, Currency."Amount Rounding Precision") then begin
                    Validate(
                      "Invoice Discount Amount", Round(NewRemainder, Currency."Amount Rounding Precision"));
                    CalcVATFields(NewCurrencyCode, NewPricesIncludingVAT, NewVATBaseDiscPct);
                    Modified := true;
                    Modify();
                end;
                NewRemainder := NewRemainder - "Invoice Discount Amount";
            end;
        until Next() = 0;
    end;

    procedure SetInvoiceDiscountPercent(NewInvoiceDiscountPct: Decimal; NewCurrencyCode: Code[10]; NewPricesIncludingVAT: Boolean; CalcInvDiscPerVATID: Boolean; NewVATBaseDiscPct: Decimal)
    var
        NewRemainder: Decimal;
    begin
        InitGlobals(NewCurrencyCode, false);
        if Find('-') then
            repeat
                if "Inv. Disc. Base Amount" <> 0 then begin
                    NewRemainder :=
                      NewRemainder + NewInvoiceDiscountPct * "Inv. Disc. Base Amount" / 100;
                    if "Invoice Discount Amount" <> Round(NewRemainder, Currency."Amount Rounding Precision") then begin
                        Validate(
                          "Invoice Discount Amount", Round(NewRemainder, Currency."Amount Rounding Precision"));
                        CalcVATFields(NewCurrencyCode, NewPricesIncludingVAT, NewVATBaseDiscPct);
                        "VAT Difference" := 0;
                        Modified := true;
                        Modify();
                    end;
                    if CalcInvDiscPerVATID then
                        NewRemainder := 0
                    else
                        NewRemainder := NewRemainder - "Invoice Discount Amount";
                end;
            until Next() = 0;
    end;

    local procedure GetCalculatedVAT(NewCurrencyCode: Code[10]; NewPricesIncludingVAT: Boolean; NewVATBaseDiscPct: Decimal): Decimal
    begin
        InitGlobals(NewCurrencyCode, false);

        if NewPricesIncludingVAT then
            exit(
              Round(
                CalcLineAmount() * "VAT %" / (100 + "VAT %") * (1 - NewVATBaseDiscPct / 100),
                Currency."Amount Rounding Precision", Currency.VATRoundingDirection()));

        exit(
          Round(
            CalcLineAmount() * "VAT %" / 100 * (1 - NewVATBaseDiscPct / 100),
            Currency."Amount Rounding Precision", Currency.VATRoundingDirection()));
    end;

    procedure CalcLineAmount() LineAmount: Decimal
    begin
        LineAmount := "Line Amount" - "Invoice Discount Amount";

        OnAfterCalcLineAmount(Rec, LineAmount);
    end;

    procedure CalcVATFields(NewCurrencyCode: Code[10]; NewPricesIncludingVAT: Boolean; NewVATBaseDiscPct: Decimal)
    begin
        OnBeforeCalcVATFields(Rec, NewVATBaseDiscPct);
        InitGlobals(NewCurrencyCode, false);

        "VAT Amount" := GetCalculatedVAT(NewCurrencyCode, NewPricesIncludingVAT, NewVATBaseDiscPct);

        if NewPricesIncludingVAT then begin
            if NewVATBaseDiscPct = 0 then begin
                "Amount Including VAT" := CalcLineAmount();
                "VAT Base" := "Amount Including VAT" - "VAT Amount";
            end else begin
                "VAT Base" :=
                  Round(CalcLineAmount() / (1 + "VAT %" / 100), Currency."Amount Rounding Precision");
                "Amount Including VAT" := "VAT Base" + "VAT Amount";
            end;
        end else begin
            "VAT Base" := CalcLineAmount();
            "Amount Including VAT" := "VAT Base" + "VAT Amount";
        end;
        "Calculated VAT Amount" := "VAT Amount";
        "VAT Difference" := 0;
        NonDeductibleVAT.Update(Rec, Currency);
        Modified := true;

        OnAfterCalcVATFields(Rec, NewPricesIncludingVAT, NewVATBaseDiscPct, Currency);
    end;

    local procedure CalcValueLCY(Value: Decimal; PostingDate: Date; CurrencyCode: Code[10]; CurrencyFactor: Decimal): Decimal
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        exit(CurrencyExchangeRate.ExchangeAmtFCYToLCY(PostingDate, CurrencyCode, Value, CurrencyFactor));
    end;

    procedure GetBaseLCY(PostingDate: Date; CurrencyCode: Code[10]; CurrencyFactor: Decimal): Decimal
    begin
        exit(Round(CalcValueLCY("VAT Base", PostingDate, CurrencyCode, CurrencyFactor)));
    end;

    procedure GetAmountLCY(PostingDate: Date; CurrencyCode: Code[10]; CurrencyFactor: Decimal): Decimal
    begin
        exit(
          Round(CalcValueLCY("Amount Including VAT", PostingDate, CurrencyCode, CurrencyFactor)) -
          Round(CalcValueLCY("VAT Base", PostingDate, CurrencyCode, CurrencyFactor)));
    end;

    procedure DeductVATAmountLine(var VATAmountLineDeduct: Record "VAT Amount Line")
    begin
        if FindSet() then
            repeat
                VATAmountLineDeduct := Rec;
                if VATAmountLineDeduct.Find() then begin
                    "VAT Base" -= VATAmountLineDeduct."VAT Base";
                    "VAT Amount" -= VATAmountLineDeduct."VAT Amount";
                    "Amount Including VAT" -= VATAmountLineDeduct."Amount Including VAT";
                    "Line Amount" -= VATAmountLineDeduct."Line Amount";
                    "Inv. Disc. Base Amount" -= VATAmountLineDeduct."Inv. Disc. Base Amount";
                    "Invoice Discount Amount" -= VATAmountLineDeduct."Invoice Discount Amount";
                    "Calculated VAT Amount" -= VATAmountLineDeduct."Calculated VAT Amount";
                    "VAT Difference" -= VATAmountLineDeduct."VAT Difference";
                    NonDeductibleVAT.DeductNonDedValuesFromVATAmountLine(Rec, VATAmountLineDeduct);
                    OnDeductVATAmountLineOnBeforeModify(Rec, VATAmountLineDeduct);
                    Modify();
                end;
            until Next() = 0;
    end;

    internal procedure ApplyNonDeductibleVAT(NonDeductibleVAT: Decimal)
    begin
        "VAT Base" += NonDeductibleVAT;
        "VAT Amount" -= NonDeductibleVAT;
        "Line Amount" += NonDeductibleVAT;
        OnApplyNonDeductibleVATOnBeforeModify(Rec, NonDeductibleVAT);
        Modify();
    end;

#if not CLEAN25
    [Obsolete('Replaced by procedures using Source Record.', '25.0')]
    procedure SumLine(LineAmount: Decimal; InvDiscAmount: Decimal; VATDifference: Decimal; AllowInvDisc: Boolean; Prepayment: Boolean)
    begin
        "Line Amount" += LineAmount;
        if AllowInvDisc then
            "Inv. Disc. Base Amount" += LineAmount;
        "Invoice Discount Amount" += InvDiscAmount;
        "VAT Difference" += VATDifference;
        if Prepayment then
            "Includes Prepayment" := true;
        Modify();
    end;
#endif

    procedure UpdateLines(var TotalVATAmount: Decimal; Currency: Record Currency; CurrencyFactor: Decimal; PricesIncludingVAT: Boolean; VATBaseDiscountPercHeader: Decimal; TaxAreaCode: Code[20]; TaxLiable: Boolean; PostingDate: Date)
    var
        PrevVATAmountLine: Record "VAT Amount Line";
        SalesTaxCalculate: Codeunit "Sales Tax Calculate";
        VATBaseDiscountPerc: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateLines(Rec, TotalVATAmount, Currency, CurrencyFactor, PricesIncludingVAT, VATBaseDiscountPercHeader, TaxAreaCode, TaxLiable, PostingDate, IsHandled);
        if IsHandled then
            exit;

        if FindSet() then
            repeat
                if (PrevVATAmountLine."VAT Identifier" <> "VAT Identifier") or
                   (PrevVATAmountLine."VAT Calculation Type" <> "VAT Calculation Type") or
                   (PrevVATAmountLine."Tax Group Code" <> "Tax Group Code") or
                   (PrevVATAmountLine."Use Tax" <> "Use Tax")
                then
                    PrevVATAmountLine.Init();
                OnUpdateLinesOnAfterInitPrevVATAmountLine(PrevVATAmountLine, Currency, PricesIncludingVAT, VATBaseDiscountPerc, Rec);

                VATBaseDiscountPerc := GetVATBaseDiscountPerc(VATBaseDiscountPercHeader);
                if PricesIncludingVAT then
                    case "VAT Calculation Type" of
                        "VAT Calculation Type"::"Normal VAT",
                        "VAT Calculation Type"::"Reverse Charge VAT":
                            begin
                                "VAT Base" :=
                                  CalcLineAmount() / (1 + "VAT %" / 100) - "VAT Difference";
                                OnUpdateLinesOnAfterCalcVATBase(Rec, Currency, PricesIncludingVAT);
                                "VAT Amount" :=
                                  "VAT Difference" +
                                  Round(
                                    PrevVATAmountLine."VAT Amount" +
                                    (CalcLineAmount() - "VAT Base" - "VAT Difference") *
                                    (1 - VATBaseDiscountPerc / 100),
                                    Currency."Amount Rounding Precision", Currency.VATRoundingDirection());
                                if VATBaseDiscountPerc <> 0 then
                                    "VAT Base" := Round("VAT Base", Currency."Amount Rounding Precision")
                                else
                                    "VAT Base" := CalcLineAmount() - "VAT Amount";
                                OnUpdateLinesOnAfterCalcVATAmount(Rec, PrevVATAmountLine, Currency, VATBaseDiscountPerc, PricesIncludingVAT);
                                "Amount Including VAT" := "VAT Base" + "VAT Amount";
                                OnUpdateLinesOnAfterCalcAmountIncludingVATNormalVAT(Rec, PrevVATAmountLine, Currency, VATBaseDiscountPerc, PricesIncludingVAT);
                                if Positive then
                                    PrevVATAmountLine.Init()
                                else begin
                                    PrevVATAmountLine := Rec;
                                    PrevVATAmountLine."VAT Amount" :=
                                      (CalcLineAmount() - "VAT Base" - "VAT Difference") *
                                      (1 - VATBaseDiscountPerc / 100);
                                    PrevVATAmountLine."VAT Amount" :=
                                      PrevVATAmountLine."VAT Amount" -
                                      Round(PrevVATAmountLine."VAT Amount", Currency."Amount Rounding Precision", Currency.VATRoundingDirection());
                                end;
                            end;
                        "VAT Calculation Type"::"Full VAT":
                            begin
                                "VAT Base" := 0;
                                "VAT Amount" := "VAT Difference" + CalcLineAmount();
                                "Amount Including VAT" := "VAT Amount";
                            end;
                        "VAT Calculation Type"::"Sales Tax":
                            begin
                                "Amount Including VAT" := CalcLineAmount();
                                if "Use Tax" then
                                    "VAT Base" := "Amount Including VAT"
                                else
                                    "VAT Base" :=
                                      Round(
                                        SalesTaxCalculate.ReverseCalculateTax(
                                          TaxAreaCode, "Tax Group Code", TaxLiable, PostingDate, "Amount Including VAT", Quantity, CurrencyFactor),
                                        Currency."Amount Rounding Precision");
                                OnAfterSalesTaxCalculateReverseCalculateTax(Rec, Currency, TaxAreaCode, TaxLiable, PostingDate, CurrencyFactor);
                                "VAT Amount" := "VAT Difference" + "Amount Including VAT" - "VAT Base";
                                if "VAT Base" = 0 then
                                    "VAT %" := 0
                                else
                                    "VAT %" := Round(100 * "VAT Amount" / "VAT Base", 0.00001);
                            end;
                    end
                else
                    case "VAT Calculation Type" of
                        "VAT Calculation Type"::"Normal VAT",
                        "VAT Calculation Type"::"Reverse Charge VAT":
                            begin
                                "VAT Base" := CalcLineAmount();
                                OnUpdateLinesOnAfterCalcVATBase(Rec, Currency, PricesIncludingVAT);
                                "VAT Amount" :=
                                  "VAT Difference" +
                                  Round(
                                    PrevVATAmountLine."VAT Amount" +
                                    "VAT Base" * "VAT %" / 100 * (1 - VATBaseDiscountPerc / 100),
                                    Currency."Amount Rounding Precision", Currency.VATRoundingDirection());
                                OnUpdateLinesOnAfterCalcVATAmount(Rec, PrevVATAmountLine, Currency, VATBaseDiscountPerc, PricesIncludingVAT);
                                "Amount Including VAT" := CalcLineAmount() + "VAT Amount";
                                OnUpdateLinesOnAfterCalcAmountIncludingVATNormalVAT(Rec, PrevVATAmountLine, Currency, VATBaseDiscountPerc, PricesIncludingVAT);
                                NonDeductibleVAT.UpdateNonDeductibleAmountsWithDiffInVATAmountLine(Rec, Currency);
                                if Positive then
                                    PrevVATAmountLine.Init()
                                else
                                    if not "Includes Prepayment" then begin
                                        PrevVATAmountLine := Rec;
                                        PrevVATAmountLine."VAT Amount" :=
                                          "VAT Base" * "VAT %" / 100 * (1 - VATBaseDiscountPerc / 100);
                                        OnUpdateLinesOnAfterCalcPreVATAmountline(Rec, PrevVATAmountLine, Currency, VATBaseDiscountPerc);
                                        PrevVATAmountLine."VAT Amount" :=
                                          PrevVATAmountLine."VAT Amount" -
                                          Round(PrevVATAmountLine."VAT Amount", Currency."Amount Rounding Precision", Currency.VATRoundingDirection());
                                    end;
                            end;
                        "VAT Calculation Type"::"Full VAT":
                            begin
                                "VAT Base" := 0;
                                "VAT Amount" := "VAT Difference" + CalcLineAmount();
                                "Amount Including VAT" := "VAT Amount";
                            end;
                        "VAT Calculation Type"::"Sales Tax":
                            begin
                                OnUpdateLinesOnBeforeCalcSalesTaxVatBase(Rec);
                                "VAT Base" := CalcLineAmount();
                                OnUpdateLinesOnAfterCalcVATBaseSalesTax(Rec, Currency, PricesIncludingVAT);
                                if "Use Tax" then
                                    "VAT Amount" := 0
                                else
                                    "VAT Amount" :=
                                      SalesTaxCalculate.CalculateTax(
                                        TaxAreaCode, "Tax Group Code", TaxLiable, PostingDate, "VAT Base", Quantity, CurrencyFactor);
                                OnAfterSalesTaxCalculateCalculateTax(Rec, Currency, TaxAreaCode, TaxLiable, PostingDate, CurrencyFactor);
                                if "VAT Base" = 0 then
                                    "VAT %" := 0
                                else
                                    "VAT %" := Round(100 * "VAT Amount" / "VAT Base", 0.00001);
                                "VAT Amount" :=
                                  "VAT Difference" +
                                  Round("VAT Amount", Currency."Amount Rounding Precision", Currency.VATRoundingDirection());
                                "Amount Including VAT" := "VAT Base" + "VAT Amount";
                            end;
                    end;

                TotalVATAmount -= "VAT Amount";
                "Calculated VAT Amount" := "VAT Amount" - "VAT Difference";
                Modify();
            until Next() = 0;
    end;

    local procedure CopyFromRec(var TempVATAmountLine: Record "VAT Amount Line" temporary)
    var
        VATAmountLineCopy: Record "VAT Amount Line";
    begin
        if not IsTemporary() then begin
            VATAmountLineCopy.Copy(Rec);
            if VATAmountLineCopy.FindSet() then
                repeat
                    TempVATAmountLine := VATAmountLineCopy;
                    TempVATAmountLine.Insert();
                until VATAmountLineCopy.Next() = 0;
        end else
            TempVATAmountLine.Copy(Rec, true);
    end;

    procedure CopyFromPurchInvLine(PurchInvLine: Record "Purch. Inv. Line")
    begin
        "VAT Identifier" := PurchInvLine."VAT Identifier";
        "VAT Calculation Type" := PurchInvLine."VAT Calculation Type";
        "Tax Group Code" := PurchInvLine."Tax Group Code";
        "Use Tax" := PurchInvLine."Use Tax";
        "VAT %" := PurchInvLine."VAT %";
        "VAT Base" := PurchInvLine.Amount;
        "VAT Amount" := PurchInvLine."Amount Including VAT" - PurchInvLine.Amount;
        "Amount Including VAT" := PurchInvLine."Amount Including VAT";
        "Line Amount" := PurchInvLine."Line Amount";
        OnCopyFromPurchInvLineOnAfterSetLineAmount(Rec, PurchInvLine);
        if PurchInvLine."Allow Invoice Disc." then
            "Inv. Disc. Base Amount" := PurchInvLine."Line Amount";
        "Invoice Discount Amount" := PurchInvLine."Inv. Discount Amount";
        Quantity := PurchInvLine."Quantity (Base)";
        "Calculated VAT Amount" :=
          PurchInvLine."Amount Including VAT" - PurchInvLine.Amount - PurchInvLine."VAT Difference";
        "VAT Difference" := PurchInvLine."VAT Difference";
        NonDeductibleVAT.CopyNonDedVATFromPurchInvLineToVATAmountLine(Rec, PurchInvLine);

        OnAfterCopyFromPurchInvLine(Rec, PurchInvLine);
    end;

    procedure CopyFromPurchCrMemoLine(PurchCrMemoLine: Record "Purch. Cr. Memo Line")
    begin
        "VAT Identifier" := PurchCrMemoLine."VAT Identifier";
        "VAT Calculation Type" := PurchCrMemoLine."VAT Calculation Type";
        "Tax Group Code" := PurchCrMemoLine."Tax Group Code";
        "Use Tax" := PurchCrMemoLine."Use Tax";
        "VAT %" := PurchCrMemoLine."VAT %";
        "VAT Base" := PurchCrMemoLine.Amount;
        "VAT Amount" := PurchCrMemoLine."Amount Including VAT" - PurchCrMemoLine.Amount;
        "Amount Including VAT" := PurchCrMemoLine."Amount Including VAT";
        "Line Amount" := PurchCrMemoLine."Line Amount";
        OnCopyFromPurchCrMemoLineOnAfterSetLineAmount(Rec, PurchCrMemoLine);
        if PurchCrMemoLine."Allow Invoice Disc." then
            "Inv. Disc. Base Amount" := PurchCrMemoLine."Line Amount";
        "Invoice Discount Amount" := PurchCrMemoLine."Inv. Discount Amount";
        Quantity := PurchCrMemoLine."Quantity (Base)";
        "Calculated VAT Amount" :=
          PurchCrMemoLine."Amount Including VAT" - PurchCrMemoLine.Amount - PurchCrMemoLine."VAT Difference";
        "VAT Difference" := PurchCrMemoLine."VAT Difference";
        NonDeductibleVAT.CopyNonDedVATFromPurchCrMemoLineToVATAmountLine(Rec, PurchCrMemoLine);

        OnAfterCopyFromPurchCrMemoLine(Rec, PurchCrMemoLine);
    end;

    procedure CopyFromSalesInvLine(SalesInvoiceLine: Record "Sales Invoice Line")
    begin
        "VAT Identifier" := SalesInvoiceLine."VAT Identifier";
        "VAT Calculation Type" := SalesInvoiceLine."VAT Calculation Type";
        "Tax Group Code" := SalesInvoiceLine."Tax Group Code";
        "VAT %" := SalesInvoiceLine."VAT %";
        "VAT Base" := SalesInvoiceLine.Amount;
        "VAT Amount" := SalesInvoiceLine."Amount Including VAT" - SalesInvoiceLine.Amount;
        "Amount Including VAT" := SalesInvoiceLine."Amount Including VAT";
        "Line Amount" := SalesInvoiceLine."Line Amount";
        if SalesInvoiceLine."Allow Invoice Disc." then
            "Inv. Disc. Base Amount" := SalesInvoiceLine."Line Amount";
        "Invoice Discount Amount" := SalesInvoiceLine."Inv. Discount Amount";
        Quantity := SalesInvoiceLine."Quantity (Base)";
        "Calculated VAT Amount" :=
          SalesInvoiceLine."Amount Including VAT" - SalesInvoiceLine.Amount - SalesInvoiceLine."VAT Difference";
        "VAT Difference" := SalesInvoiceLine."VAT Difference";

        OnAfterCopyFromSalesInvLine(Rec, SalesInvoiceLine);
    end;

    procedure CopyFromSalesCrMemoLine(SalesCrMemoLine: Record "Sales Cr.Memo Line")
    begin
        "VAT Identifier" := SalesCrMemoLine."VAT Identifier";
        "VAT Calculation Type" := SalesCrMemoLine."VAT Calculation Type";
        "Tax Group Code" := SalesCrMemoLine."Tax Group Code";
        "VAT %" := SalesCrMemoLine."VAT %";
        "VAT Base" := SalesCrMemoLine.Amount;
        "VAT Amount" := SalesCrMemoLine."Amount Including VAT" - SalesCrMemoLine.Amount;
        "Amount Including VAT" := SalesCrMemoLine."Amount Including VAT";
        "Line Amount" := SalesCrMemoLine."Line Amount";
        if SalesCrMemoLine."Allow Invoice Disc." then
            "Inv. Disc. Base Amount" := SalesCrMemoLine."Line Amount";
        "Invoice Discount Amount" := SalesCrMemoLine."Inv. Discount Amount";
        Quantity := SalesCrMemoLine."Quantity (Base)";
        "Calculated VAT Amount" := SalesCrMemoLine."Amount Including VAT" - SalesCrMemoLine.Amount - SalesCrMemoLine."VAT Difference";
        "VAT Difference" := SalesCrMemoLine."VAT Difference";

        OnAfterCopyFromSalesCrMemoLine(Rec, SalesCrMemoLine);
    end;

#if not CLEAN25
    [Obsolete('Replaced by procedure CopyToVATAmountLine in table Service Invoice Line', '25.0')]
    procedure CopyFromServInvLine(ServiceInvoiceLine: Record Microsoft.Service.History."Service Invoice Line")
    begin
        "VAT Identifier" := ServiceInvoiceLine."VAT Identifier";
        "VAT Calculation Type" := ServiceInvoiceLine."VAT Calculation Type";
        "Tax Group Code" := ServiceInvoiceLine."Tax Group Code";
        "VAT %" := ServiceInvoiceLine."VAT %";
        "VAT Base" := ServiceInvoiceLine.Amount;
        "VAT Amount" := ServiceInvoiceLine."Amount Including VAT" - ServiceInvoiceLine.Amount;
        "Amount Including VAT" := ServiceInvoiceLine."Amount Including VAT";
        "Line Amount" := ServiceInvoiceLine."Line Amount";
        if ServiceInvoiceLine."Allow Invoice Disc." then
            "Inv. Disc. Base Amount" := ServiceInvoiceLine."Line Amount";
        "Invoice Discount Amount" := ServiceInvoiceLine."Inv. Discount Amount";
        Quantity := ServiceInvoiceLine."Quantity (Base)";
        "Calculated VAT Amount" :=
          ServiceInvoiceLine."Amount Including VAT" - ServiceInvoiceLine.Amount - ServiceInvoiceLine."VAT Difference";
        "VAT Difference" := ServiceInvoiceLine."VAT Difference";

        OnAfterCopyFromServInvLine(Rec, ServiceInvoiceLine);
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by procedure CopyToVATAmountLine in table Service Cr.Memo Line', '25.0')]
    procedure CopyFromServCrMemoLine(ServiceCrMemoLine: Record Microsoft.Service.History."Service Cr.Memo Line")
    begin
        "VAT Identifier" := ServiceCrMemoLine."VAT Identifier";
        "VAT Calculation Type" := ServiceCrMemoLine."VAT Calculation Type";
        "Tax Group Code" := ServiceCrMemoLine."Tax Group Code";
        "VAT %" := ServiceCrMemoLine."VAT %";
        "VAT Base" := ServiceCrMemoLine.Amount;
        "VAT Amount" := ServiceCrMemoLine."Amount Including VAT" - ServiceCrMemoLine.Amount;
        "Amount Including VAT" := ServiceCrMemoLine."Amount Including VAT";
        "Line Amount" := ServiceCrMemoLine."Line Amount";
        if ServiceCrMemoLine."Allow Invoice Disc." then
            "Inv. Disc. Base Amount" := ServiceCrMemoLine."Line Amount";
        "Invoice Discount Amount" := ServiceCrMemoLine."Inv. Discount Amount";
        Quantity := ServiceCrMemoLine."Quantity (Base)";
        "Calculated VAT Amount" :=
          ServiceCrMemoLine."Amount Including VAT" - ServiceCrMemoLine.Amount - ServiceCrMemoLine."VAT Difference";
        "VAT Difference" := ServiceCrMemoLine."VAT Difference";

        OnAfterCopyFromServCrMemoLine(Rec, ServiceCrMemoLine);
    end;
#endif

    local procedure GetVATBaseDiscountPerc(VATBaseDiscountPerc: Decimal) NewVATBaseDiscountPerc: Decimal
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetVATBaseDiscountPerc(Rec, VATBaseDiscountPerc, NewVATBaseDiscountPerc, IsHandled);
        if not IsHandled then
            NewVATBaseDiscountPerc := VATBaseDiscountPerc;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcLineAmount(var VATAmountLine: Record "VAT Amount Line"; var LineAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckVATDifference(VATAmountLine: Record "VAT Amount Line"; NewCurrencyCode: Code[10]; NewAllowVATDifference: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromPurchInvLine(var VATAmountLine: Record "VAT Amount Line"; PurchInvLine: Record "Purch. Inv. Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromPurchCrMemoLine(var VATAmountLine: Record "VAT Amount Line"; PurchCrMemoLine: Record "Purch. Cr. Memo Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromSalesInvLine(var VATAmountLine: Record "VAT Amount Line"; SalesInvoiceLine: Record "Sales Invoice Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromSalesCrMemoLine(var VATAmountLine: Record "VAT Amount Line"; SalesCrMemoLine: Record "Sales Cr.Memo Line")
    begin
    end;

#if not CLEAN25
    internal procedure RunOnAfterCopyFromServInvLine(var VATAmountLine: Record "VAT Amount Line"; ServiceInvoiceLine: Record Microsoft.Service.History."Service Invoice Line")
    begin
        OnAfterCopyFromServInvLine(VATAmountLine, ServiceInvoiceLine);
    end;

    [Obsolete('Replaced by event OnAfterCopyToVATAmountLine in table Service Invoice Line', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromServInvLine(var VATAmountLine: Record "VAT Amount Line"; ServiceInvoiceLine: Record Microsoft.Service.History."Service Invoice Line")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnAfterCopyFromServCrMemoLine(var VATAmountLine: Record "VAT Amount Line"; ServiceCrMemoLine: Record Microsoft.Service.History."Service Cr.Memo Line")
    begin
        OnAfterCopyFromServCrMemoLine(VATAmountLine, ServiceCrMemoLine);
    end;

    [Obsolete('Replaced by event OnAfterCopyToVATAmountLine in table Service Cr.Memo Line', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromServCrMemoLine(var VATAmountLine: Record "VAT Amount Line"; ServiceCrMemoLine: Record Microsoft.Service.History."Service Cr.Memo Line")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesTaxCalculateCalculateTax(var VATAmountLine: Record "VAT Amount Line"; Currency: Record Currency; TaxAreaCode: Code[20]; TaxLiable: Boolean; PostingDate: Date; CurrencyFactor: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesTaxCalculateReverseCalculateTax(var VATAmountLine: Record "VAT Amount Line"; Currency: Record Currency; TaxAreaCode: Code[20]; TaxLiable: Boolean; PostingDate: Date; CurrencyFactor: Decimal)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterVATAmountText(VATPercentage: Decimal; FullCount: Integer; var Result: Text[30])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetTotalVATAmount(var VATAmountLine: Record "VAT Amount Line"; var VATAmount: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertLineOnAfterValidatePositive(var VATAmountLine: Record "VAT Amount Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertLineOnBeforeInsert(var VATAmountLine: Record "VAT Amount Line"; var FromVATAmountLine: Record "VAT Amount Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertLineOnBeforeModify(var VATAmountLine: Record "VAT Amount Line"; FromVATAmountLine: Record "VAT Amount Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertLine(var VATAmountLine: Record "VAT Amount Line"; var IsHandled: Boolean; var Result: Boolean; var SkipZeroVatAmounts: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateLinesOnAfterCalcVATAmount(var VATAmountLine: Record "VAT Amount Line"; PrevVATAmountLine: Record "VAT Amount Line"; var Currency: Record Currency; VATBaseDiscountPerc: Decimal; PricesIncludingVAT: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateLinesOnAfterCalcAmountIncludingVATNormalVAT(var VATAmountLine: Record "VAT Amount Line"; PrevVATAmountLine: Record "VAT Amount Line"; var Currency: Record Currency; VATBaseDiscountPerc: Decimal; PricesIncludingVAT: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateLinesOnBeforeCalcSalesTaxVatBase(var VATAmountLine: Record "VAT Amount Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateLinesOnAfterCalcVATBase(var VATAmountLine: Record "VAT Amount Line"; Currency: Record Currency; PricesIncludingVAT: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateLinesOnAfterCalcVATBaseSalesTax(var VATAmountLine: Record "VAT Amount Line"; Currency: Record Currency; PricesIncludingVAT: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcVATFields(var VATAmountLine: Record "VAT Amount Line"; NewPricesIncludingVAT: Boolean; NewVATBaseDiscPct: Decimal; Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcVATFields(var VATAmountLine: Record "VAT Amount Line"; var NewVATBaseDiscPct: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeductVATAmountLineOnBeforeModify(var VATAmountLine: Record "VAT Amount Line"; VATAmountLineDeduct: Record "VAT Amount Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetVATBaseDiscountPerc(var VATAmountLine: Record "VAT Amount Line"; VATBaseDiscountPerc: Decimal; var NewVATBaseDiscountPerc: decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateLinesOnAfterInitPrevVATAmountLine(var PrevVATAmountLine: Record "VAT Amount Line"; Currency: Record Currency; PricesIncludingVAT: Boolean; var VATBaseDiscountPerc: Decimal; var VATAmountLine: Record "VAT Amount Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyNonDeductibleVATOnBeforeModify(var VATAmountLine: Record "VAT Amount Line"; NonDeductibleVAT: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromPurchInvLineOnAfterSetLineAmount(var VATAmountLine: Record "VAT Amount Line"; var PurchInvLine: Record "Purch. Inv. Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromPurchCrMemoLineOnAfterSetLineAmount(var VATAmountLine: Record "VAT Amount Line"; var PurchCrMemoLine: Record "Purch. Cr. Memo Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeUpdateLines(var VATAmountLine: Record "VAT Amount Line"; var TotalVATAmount: Decimal; Currency: Record Currency; CurrencyFactor: Decimal; PricesIncludingVAT: Boolean; VATBaseDiscountPercHeader: Decimal; TaxAreaCode: Code[20]; TaxLiable: Boolean; PostingDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateLinesOnAfterCalcPreVATAmountline(var VATAmountLine: Record "VAT Amount Line"; var PreVATAmountLine: Record "VAT Amount Line"; var Currency: Record Currency; VATBaseDiscountPerc: Decimal)
    begin
    end;
}
