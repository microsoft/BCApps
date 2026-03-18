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

/// <summary>
/// Stores VAT calculation data for document lines grouped by VAT identifier and calculation parameters.
/// Supports VAT amount calculations, invoice discounts, and non-deductible VAT processing for sales and purchase transactions.
/// </summary>
/// <remarks>
/// Primary temporary table used during VAT calculations and document posting.
/// Key integrations: VAT posting, invoice posting, sales/purchase document processing.
/// Extensibility: Multiple integration events for VAT calculation customization.
/// </remarks>
#pragma warning disable AS0109
table 290 "VAT Amount Line"
{
    Caption = 'VAT Amount Line';
    DataClassification = CustomerContent;
    TableType = Temporary;

    fields
    {
        /// <summary>
        /// VAT percentage used for VAT calculations on document lines with this VAT identifier.
        /// </summary>
        field(1; "VAT %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'VAT %';
            ToolTip = 'Specifies the VAT % that was used on the sales or purchase lines with this VAT Identifier.';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        /// <summary>
        /// Total net amount excluding VAT for document lines with this VAT identifier.
        /// </summary>
        field(2; "VAT Base"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'VAT Base';
            ToolTip = 'Specifies the total net amount (amount excluding VAT) for sales or purchase lines with a specific VAT Identifier.';
            Editable = false;
        }
        /// <summary>
        /// Total VAT amount calculated for document lines with this VAT identifier.
        /// </summary>
        field(3; "VAT Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'VAT Amount';
            ToolTip = 'Specifies the amount of VAT that is included in the total amount.';

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
        /// <summary>
        /// Total amount including VAT for document lines with this VAT identifier.
        /// </summary>
        field(4; "Amount Including VAT"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Amount Including VAT';
            ToolTip = 'Specifies the net amount, including VAT, for this line.';
            Editable = false;
        }
        /// <summary>
        /// VAT identifier that groups VAT posting setup combinations for VAT calculations.
        /// </summary>
        field(5; "VAT Identifier"; Code[20])
        {
            Caption = 'VAT Identifier';
            ToolTip = 'Specifies the VAT Identifier value.';
            Editable = false;
        }
        /// <summary>
        /// Total line amount before invoice discount for document lines with this VAT identifier.
        /// </summary>
        field(6; "Line Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Line Amount';
            ToolTip = 'Specifies the total amount for sales or purchase lines with a specific VAT identifier.';
            Editable = false;
        }
        /// <summary>
        /// Base amount eligible for invoice discount calculation.
        /// </summary>
        field(7; "Inv. Disc. Base Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Inv. Disc. Base Amount';
            ToolTip = 'Specifies the invoice discount base amount.';
            Editable = false;
        }
        /// <summary>
        /// Invoice discount amount applied to document lines with this VAT identifier.
        /// </summary>
        field(8; "Invoice Discount Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Invoice Discount Amount';
            ToolTip = 'Specifies the invoice discount amount for a specific VAT identifier.';

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
        /// <summary>
        /// VAT calculation method determining how VAT is calculated for this VAT identifier.
        /// </summary>
        field(9; "VAT Calculation Type"; Enum "Tax Calculation Type")
        {
            Caption = 'VAT Calculation Type';
            ToolTip = 'Specifies how VAT will be calculated for purchases or sales of items with this particular combination of VAT business posting group and VAT product posting group.';
            Editable = false;
        }
        /// <summary>
        /// Tax group code used for sales tax calculations in US localization.
        /// </summary>
        field(10; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            Editable = false;
            TableRelation = "Tax Group";
        }
        /// <summary>
        /// Quantity sum for document lines with this VAT identifier.
        /// </summary>
        field(11; Quantity; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        /// <summary>
        /// Indicates whether VAT amounts have been manually modified from calculated values.
        /// </summary>
        field(12; Modified; Boolean)
        {
            Caption = 'Modified';
        }
        /// <summary>
        /// Indicates use tax calculation for reverse charge VAT scenarios.
        /// </summary>
        field(13; "Use Tax"; Boolean)
        {
            Caption = 'Use Tax';
        }
        /// <summary>
        /// System-calculated VAT amount before manual adjustments or VAT differences.
        /// </summary>
        field(14; "Calculated VAT Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Calculated VAT Amount';
            ToolTip = 'Specifies the calculated VAT amount and is only used for reference when the user changes the VAT Amount manually.';
            Editable = false;
        }
        /// <summary>
        /// Difference between calculated VAT amount and manually entered VAT amount.
        /// </summary>
        field(15; "VAT Difference"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'VAT Difference';
            ToolTip = 'Specifies the difference between the calculated VAT amount and a VAT amount that you have entered manually.';
            Editable = false;
        }
        /// <summary>
        /// Indicates whether line amounts are positive values for proper VAT calculation grouping.
        /// </summary>
        field(16; Positive; Boolean)
        {
            Caption = 'Positive';
        }
        /// <summary>
        /// Indicates whether this VAT amount line includes prepayment amounts.
        /// </summary>
        field(17; "Includes Prepayment"; Boolean)
        {
            Caption = 'Includes Prepayment';
        }
        /// <summary>
        /// VAT clause code providing additional VAT reporting information and text.
        /// </summary>
        field(18; "VAT Clause Code"; Code[20])
        {
            Caption = 'VAT Clause Code';
            TableRelation = "VAT Clause";
        }
        /// <summary>
        /// Tax category code used for electronic VAT reporting and compliance.
        /// </summary>
        field(19; "Tax Category"; Code[10])
        {
            Caption = 'Tax Category';
        }
        /// <summary>
        /// Payment discount amount applied to document lines with this VAT identifier.
        /// </summary>
        field(20; "Pmt. Discount Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Pmt. Discount Amount';
            Editable = false;
        }
        /// <summary>
        /// Non-deductible VAT percentage for partial VAT deduction scenarios.
        /// </summary>
        field(6200; "Non-Deductible VAT %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Non-Deductible VAT %';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        /// <summary>
        /// VAT base amount that is non-deductible according to non-deductible VAT percentage.
        /// </summary>
        field(6201; "Non-Deductible VAT Base"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Non-Deductible VAT Base';
            ToolTip = 'Specifies the amount of the transaction for which VAT is not applied due to the type of goods or services purchased.';
            Editable = false;
        }
        /// <summary>
        /// VAT amount that is non-deductible and will be added to the expense or asset cost.
        /// </summary>
        field(6202; "Non-Deductible VAT Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Non-Deductible VAT Amount';
            ToolTip = 'Specifies the amount of VAT that is not deducted due to the type of goods or services purchased.';

            trigger OnValidate()
            begin
                NonDeductibleVAT.ValidateNonDeductibleVATInVATAmountLine(Rec);
            end;
        }
        /// <summary>
        /// System-calculated non-deductible VAT amount before manual adjustments.
        /// </summary>
        field(6203; "Calc. Non-Ded. VAT Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Calculated Non-Deductible VAT Amount';
            ToolTip = 'Specifies the calculated Non-Deductible VAT amount and is only used for reference when the user changes the Non-Deductible VAT Amount manually.';
            Editable = false;
        }
        /// <summary>
        /// VAT base amount that is deductible and can be claimed back from tax authorities.
        /// </summary>
        field(6204; "Deductible VAT Base"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Deductible VAT Base';
            ToolTip = 'Specifies the amount of the transaction for which VAT is applied due to the type of goods or services purchased.';
            Editable = false;
        }
        /// <summary>
        /// VAT amount that is deductible and can be claimed back from tax authorities.
        /// </summary>
        field(6205; "Deductible VAT Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Deductible VAT Amount';
            ToolTip = 'Specifies the amount of VAT that is deducted due to the type of goods or services purchased.';
            Editable = false;
        }
        /// <summary>
        /// Difference between calculated and manually entered non-deductible VAT amounts.
        /// </summary>
        field(6206; "Non-Deductible VAT Diff."; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
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

    /// <summary>
    /// Validates VAT difference against maximum allowed VAT difference limits.
    /// </summary>
    /// <param name="NewCurrencyCode">Currency code for VAT difference validation</param>
    /// <param name="NewAllowVATDifference">Whether VAT differences are allowed on this document</param>
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

    /// <summary>
    /// Inserts or updates VAT amount line with calculated amounts, combining with existing line if found.
    /// </summary>
    /// <returns>True if line was successfully inserted or updated, false if amounts are zero</returns>
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

    /// <summary>
    /// Retrieves VAT amount line by sequential number from the recordset.
    /// </summary>
    /// <param name="Number">Sequential number (1 for first line, otherwise next line)</param>
    procedure GetLine(Number: Integer)
    begin
        if Number = 1 then
            Find('-')
        else
            Next();
    end;

    /// <summary>
    /// Generates descriptive text for VAT amount display based on VAT percentage.
    /// </summary>
    /// <returns>Formatted text showing VAT percentage or generic "VAT Amount" text</returns>
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

    /// <summary>
    /// Calculates total line amount across all VAT amount lines with optional VAT subtraction.
    /// </summary>
    /// <param name="SubtractVAT">Whether to subtract VAT from line amounts</param>
    /// <param name="CurrencyCode">Currency code for rounding precision</param>
    /// <returns>Total line amount</returns>
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

    /// <summary>
    /// Calculates total VAT amount across all VAT amount lines in the recordset.
    /// </summary>
    /// <returns>Total VAT amount</returns>
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

    /// <summary>
    /// Calculates total invoice discount amount across all VAT amount lines.
    /// </summary>
    /// <returns>Total invoice discount amount</returns>
    procedure GetTotalInvDiscAmount(): Decimal
    begin
        CalcSums("Invoice Discount Amount");
        exit("Invoice Discount Amount");
    end;

    /// <summary>
    /// Calculates total invoice discount base amount with optional VAT subtraction.
    /// </summary>
    /// <param name="SubtractVAT">Whether to subtract VAT from base amounts</param>
    /// <param name="CurrencyCode">Currency code for rounding precision</param>
    /// <returns>Total invoice discount base amount</returns>
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

    /// <summary>
    /// Calculates total VAT base amount across all VAT amount lines.
    /// </summary>
    /// <returns>Total VAT base amount</returns>
    procedure GetTotalVATBase(): Decimal
    begin
        CalcSums("VAT Base");
        exit("VAT Base");
    end;

    /// <summary>
    /// Calculates total amount including VAT across all VAT amount lines.
    /// </summary>
    /// <returns>Total amount including VAT</returns>
    procedure GetTotalAmountInclVAT(): Decimal
    begin
        CalcSums("Amount Including VAT");
        exit("Amount Including VAT");
    end;

    /// <summary>
    /// Calculates total VAT discount amount based on rounding differences.
    /// </summary>
    /// <param name="CurrencyCode">Currency code for rounding precision</param>
    /// <param name="NewPricesIncludingVAT">Whether prices include VAT</param>
    /// <returns>Total VAT discount amount</returns>
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

    /// <summary>
    /// Checks whether any VAT amount line has been manually modified.
    /// </summary>
    /// <returns>True if any line has Modified flag set</returns>
    procedure GetAnyLineModified(): Boolean
    begin
        if Find('-') then
            repeat
                if Modified then
                    exit(true);
            until Next() = 0;
        exit(false);
    end;

    /// <summary>
    /// Distributes invoice discount amount proportionally across VAT amount lines.
    /// </summary>
    /// <param name="NewInvoiceDiscount">Total invoice discount to distribute</param>
    /// <param name="NewCurrencyCode">Currency code for calculations</param>
    /// <param name="NewPricesIncludingVAT">Whether prices include VAT</param>
    /// <param name="NewVATBaseDiscPct">VAT base discount percentage</param>
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

    /// <summary>
    /// Applies invoice discount percentage to VAT amount lines with proportional distribution.
    /// </summary>
    /// <param name="NewInvoiceDiscountPct">Invoice discount percentage to apply</param>
    /// <param name="NewCurrencyCode">Currency code for calculations</param>
    /// <param name="NewPricesIncludingVAT">Whether prices include VAT</param>
    /// <param name="CalcInvDiscPerVATID">Whether to calculate discount per VAT identifier</param>
    /// <param name="NewVATBaseDiscPct">VAT base discount percentage</param>
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

    /// <summary>
    /// Calculates line amount after subtracting invoice discount from original line amount.
    /// </summary>
    /// <returns>Net line amount used for VAT calculations</returns>
    procedure CalcLineAmount() LineAmount: Decimal
    begin
        LineAmount := "Line Amount" - "Invoice Discount Amount";

        OnAfterCalcLineAmount(Rec, LineAmount);
    end;

    /// <summary>
    /// Recalculates VAT amounts and VAT base based on current line amount and VAT parameters.
    /// </summary>
    /// <param name="NewCurrencyCode">Currency code for rounding precision</param>
    /// <param name="NewPricesIncludingVAT">Whether prices include VAT</param>
    /// <param name="NewVATBaseDiscPct">VAT base discount percentage</param>
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

    /// <summary>
    /// Converts VAT base amount from foreign currency to local currency using exchange rate.
    /// </summary>
    /// <param name="PostingDate">Date for exchange rate lookup</param>
    /// <param name="CurrencyCode">Foreign currency code</param>
    /// <param name="CurrencyFactor">Currency exchange factor</param>
    /// <returns>VAT base amount in local currency</returns>
    procedure GetBaseLCY(PostingDate: Date; CurrencyCode: Code[10]; CurrencyFactor: Decimal): Decimal
    begin
        exit(Round(CalcValueLCY("VAT Base", PostingDate, CurrencyCode, CurrencyFactor)));
    end;

    /// <summary>
    /// Calculates VAT amount in local currency by converting from foreign currency.
    /// </summary>
    /// <param name="PostingDate">Date for exchange rate lookup</param>
    /// <param name="CurrencyCode">Foreign currency code</param>
    /// <param name="CurrencyFactor">Currency exchange factor</param>
    /// <returns>VAT amount in local currency</returns>
    procedure GetAmountLCY(PostingDate: Date; CurrencyCode: Code[10]; CurrencyFactor: Decimal): Decimal
    begin
        exit(
          Round(CalcValueLCY("Amount Including VAT", PostingDate, CurrencyCode, CurrencyFactor)) -
          Round(CalcValueLCY("VAT Base", PostingDate, CurrencyCode, CurrencyFactor)));
    end;

    /// <summary>
    /// Deducts amounts from current VAT amount lines using corresponding lines from another recordset.
    /// </summary>
    /// <param name="VATAmountLineDeduct">VAT amount line recordset containing amounts to deduct</param>
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

    /// <summary>
    /// Updates VAT amount lines with calculated VAT amounts and totals based on currency, pricing settings, and tax configuration.
    /// Performs comprehensive VAT calculations including sales tax processing and currency conversions.
    /// </summary>
    /// <param name="TotalVATAmount">Total VAT amount calculated across all lines</param>
    /// <param name="Currency">Currency record for rounding and conversion</param>
    /// <param name="CurrencyFactor">Currency exchange factor for conversion calculations</param>
    /// <param name="PricesIncludingVAT">Whether prices include VAT or VAT is calculated on top</param>
    /// <param name="VATBaseDiscountPercHeader">VAT base discount percentage from document header</param>
    /// <param name="TaxAreaCode">Tax area code for sales tax calculations</param>
    /// <param name="TaxLiable">Whether the transaction is liable for sales tax</param>
    /// <param name="PostingDate">Posting date for tax rate determination</param>
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

    /// <summary>
    /// Copies VAT-related fields from posted purchase invoice line to create VAT amount line for analysis or reporting.
    /// </summary>
    /// <param name="PurchInvLine">Posted purchase invoice line containing VAT information to copy</param>
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
        "Pmt. Discount Amount" := PurchInvLine."Pmt. Discount Amount";
        Quantity := PurchInvLine."Quantity (Base)";
        "Calculated VAT Amount" :=
          PurchInvLine."Amount Including VAT" - PurchInvLine.Amount - PurchInvLine."VAT Difference";
        "VAT Difference" := PurchInvLine."VAT Difference";
        NonDeductibleVAT.CopyNonDedVATFromPurchInvLineToVATAmountLine(Rec, PurchInvLine);

        OnAfterCopyFromPurchInvLine(Rec, PurchInvLine);
    end;

    /// <summary>
    /// Copies VAT-related fields from posted purchase credit memo line to create VAT amount line for analysis or reporting.
    /// </summary>
    /// <param name="PurchCrMemoLine">Posted purchase credit memo line containing VAT information to copy</param>
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
        "Pmt. Discount Amount" := PurchCrMemoLine."Pmt. Discount Amount";
        Quantity := PurchCrMemoLine."Quantity (Base)";
        "Calculated VAT Amount" :=
          PurchCrMemoLine."Amount Including VAT" - PurchCrMemoLine.Amount - PurchCrMemoLine."VAT Difference";
        "VAT Difference" := PurchCrMemoLine."VAT Difference";
        NonDeductibleVAT.CopyNonDedVATFromPurchCrMemoLineToVATAmountLine(Rec, PurchCrMemoLine);

        OnAfterCopyFromPurchCrMemoLine(Rec, PurchCrMemoLine);
    end;

    /// <summary>
    /// Copies VAT-related fields from posted sales invoice line to create VAT amount line for analysis or reporting.
    /// </summary>
    /// <param name="SalesInvoiceLine">Posted sales invoice line containing VAT information to copy</param>
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
        "Pmt. Discount Amount" := SalesInvoiceLine."Pmt. Discount Amount";
        Quantity := SalesInvoiceLine."Quantity (Base)";
        "Calculated VAT Amount" :=
          SalesInvoiceLine."Amount Including VAT" - SalesInvoiceLine.Amount - SalesInvoiceLine."VAT Difference";
        "VAT Difference" := SalesInvoiceLine."VAT Difference";

        OnAfterCopyFromSalesInvLine(Rec, SalesInvoiceLine);
    end;

    /// <summary>
    /// Copies VAT-related fields from posted sales credit memo line to create VAT amount line for analysis or reporting.
    /// </summary>
    /// <param name="SalesCrMemoLine">Posted sales credit memo line containing VAT information to copy</param>
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
        "Pmt. Discount Amount" := SalesCrMemoLine."Pmt. Discount Amount";
        Quantity := SalesCrMemoLine."Quantity (Base)";
        "Calculated VAT Amount" := SalesCrMemoLine."Amount Including VAT" - SalesCrMemoLine.Amount - SalesCrMemoLine."VAT Difference";
        "VAT Difference" := SalesCrMemoLine."VAT Difference";

        OnAfterCopyFromSalesCrMemoLine(Rec, SalesCrMemoLine);
    end;

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
