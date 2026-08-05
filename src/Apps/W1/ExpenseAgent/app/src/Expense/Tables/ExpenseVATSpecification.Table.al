// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.Currency;
using Microsoft.Finance.VAT.Setup;

/// <summary>
/// Per-VAT-rate breakdown of an <see cref="Expense"/> as captured from the original invoice.
/// One row per (VAT rate, VAT product posting group) combination on the receipt.
/// This is the source of truth for the receipt's VAT box; Expense Report Lines are derived
/// from these specifications when the expense is pushed into a report.
/// </summary>
table 6918 "Expense VAT Specification"
{
    Access = Internal;
    Caption = 'Expense VAT Specification';
    DataClassification = CustomerContent;
    LookupPageId = "Expense VAT Specification";
    DrillDownPageId = "Expense VAT Specification";
    ReplicateData = false;

    fields
    {
        field(1; "Expense No."; Code[20])
        {
            Caption = 'Expense No.';
            TableRelation = Expense."No.";
            NotBlank = true;
            ToolTip = 'Specifies the number of the expense this VAT specification line belongs to.';

            trigger OnValidate()
            begin
                GetExpense();
                if Expense."Expense Category" <> '' then
                    Validate("Expense Category", "Expense Category");
                if Expense."Expense Subcategory" <> '' then
                    Validate("Expense Subcategory", "Expense Subcategory");
            end;
        }
        field(2; "Line No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'Line No.';
            ToolTip = 'Specifies the line number of the VAT specification entry within the expense.';
        }
        field(10; "VAT %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'VAT %';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 100;
            ToolTip = 'Specifies the VAT percentage applied to this expense line. Changing this value recalculates the VAT amount and VAT base amount.';

            trigger OnValidate()
            begin
                InitializeCurrency();
                "VAT Amount" := Round(Amount * "VAT %" / (100 + "VAT %"), Currency."Amount Rounding Precision", Currency.VATRoundingDirection());
                "VAT Base Amount" := Round(Amount - "VAT Amount", Currency."Amount Rounding Precision");
                "VAT Difference" := 0;
                "VAT Amount (LCY)" := CalcVATAmountLCY();
                "VAT Base Amount (LCY)" := "Amount (LCY)" - "VAT Amount (LCY)";
            end;
        }
        field(11; "VAT Base Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = GetCurrencyCode();
            Caption = 'VAT Base Amount';
            ToolTip = 'Specifies the amount that the VAT percentage is calculated from, i.e. the total amount excluding VAT.';
        }
        field(12; "VAT Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = GetCurrencyCode();
            Caption = 'VAT Amount';
            ToolTip = 'Specifies the VAT amount calculated for this expense line based on the VAT percentage and base amount.';
        }
        /// <summary>
        /// Transaction amount in the specified currency including VAT where applicable.
        /// </summary>
        field(13; Amount; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Amount';
            ToolTip = 'Specifies the total amount (including VAT) that the expense line consists of.';

            trigger OnValidate()
            begin
                ValidateAmount();
            end;
        }
        /// <summary>
        /// Calculated difference between expected and actual VAT amount allowing for VAT tolerance variations.
        /// </summary>
        field(14; "VAT Difference"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'VAT Difference';
            ToolTip = 'Specifies the difference between the calculated VAT amount and a VAT amount that you have entered manually.';
            Editable = false;
        }
        field(20; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
            ToolTip = 'Specifies the VAT business posting group that determines the VAT rate and VAT calculation method used for this expense line.';
        }
        field(21; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";
            ToolTip = 'Specifies the VAT product posting group that determines the VAT rate and VAT calculation method used for this expense line.';
        }
        /// <summary>
        /// VAT amount converted to local currency for accounting and reporting purposes.
        /// </summary>
        field(24; "VAT Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'VAT Amount (LCY)';
            Editable = false;
            ToolTip = 'Specifies the VAT amount converted to local currency for accounting and VAT reporting purposes.';
        }
        /// <summary>
        /// VAT base amount converted to local currency for accounting and VAT reporting purposes.
        /// </summary>
        field(25; "VAT Base Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'VAT Base Amount (LCY)';
            Editable = false;
            ToolTip = 'Specifies the VAT base amount converted to local currency for accounting and VAT reporting purposes.';
        }
        /// <summary>
        /// Transaction amount converted to local currency using exchange rates and currency factors.
        /// </summary>
        field(26; "Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Amount (LCY)';
            ToolTip = 'Specifies the total expense amount (including VAT) converted to local currency using the applicable exchange rate.';

            trigger OnValidate()
            begin
                GetExpense();
                if Expense."Currency Code" = '' then begin
                    Amount := "Amount (LCY)";
                    Validate(Amount);
                end else begin
                    TestField("Amount (LCY)");
                    TestField(Amount);
                    Expense."Currency Factor" := Amount / "Amount (LCY)";
                end;

                Validate("VAT %");
            end;
        }
        field(27; "Expense Category"; Code[20])
        {
            Caption = 'Expense Category';
            TableRelation = "Expense Category".Code;
            ToolTip = 'Specifies the expense category for this VAT specification line. When set, the default VAT posting group and VAT percentage are copied from the category unless a subcategory is also specified.';

            trigger OnValidate()
            var
                ExpenseCategory: Record "Expense Category";
            begin
                if "Expense Category" = '' then
                    exit;
                if "Expense Subcategory" <> '' then
                    exit;
                if ExpenseCategory.Get("Expense Category") then begin
                    "VAT Prod. Posting Group" := ExpenseCategory."VAT Prod. Posting Group";
                    "VAT %" := ExpenseCategory."Default VAT %";
                    Validate("VAT %");
                end;
            end;
        }
        field(28; "Expense Subcategory"; Code[20])
        {
            Caption = 'Expense Subcategory';
            TableRelation = "Expense Subcategory".Code where("Expense Category Code" = field("Expense Category"));
            ToolTip = 'Specifies the expense subcategory for this VAT specification line. When set, the VAT posting group and VAT percentage are copied from the subcategory, overriding any values from the expense category.';

            trigger OnValidate()
            var
                ExpenseSubcategory: Record "Expense Subcategory";
                ExpenseCategory: Record "Expense Category";
            begin
                if "Expense Subcategory" <> '' then begin
                    if ExpenseSubcategory.Get("Expense Category", "Expense Subcategory") then begin
                        "VAT Prod. Posting Group" := ExpenseSubcategory."VAT Prod. Posting Group";
                        "VAT %" := ExpenseSubcategory."Default VAT %";
                        Validate("VAT %");
                    end;
                end else
                    if "Expense Category" <> '' then
                        if ExpenseCategory.Get("Expense Category") then begin
                            "VAT Prod. Posting Group" := ExpenseCategory."VAT Prod. Posting Group";
                            "VAT %" := ExpenseCategory."Default VAT %";
                            Validate("VAT %");
                        end;
            end;
        }
        field(40; Source; Enum "Expense VAT Spec Source")
        {
            Caption = 'Source';
            ToolTip = 'Specifies how this VAT specification line was created, for example whether it was entered manually or extracted automatically from a receipt.';
        }
        field(41; Confidence; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Confidence';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 1;
            ToolTip = 'Specifies the confidence score (0–1) of the automatically extracted VAT data, indicating how certain the AI is about the captured values.';
        }
        field(42; Reasoning; Blob)
        {
            Caption = 'Reasoning';
            ToolTip = 'Specifies the AI reasoning text that explains how the VAT specification values were determined from the receipt or invoice.';
        }
    }

    keys
    {
        key(PK; "Expense No.", "Line No.")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
        if "VAT Bus. Posting Group" = '' then begin
            ExpenseAgentSetup.Get();
            ExpenseAgentSetup.TestField("Default VAT Bus. Posting Group");
            "VAT Bus. Posting Group" := ExpenseAgentSetup."Default VAT Bus. Posting Group";
        end;
    end;

    var
        Currency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
        Expense: Record Expense;
        ExpenseAgentSetup: Record "Expense Agent Setup";

    local procedure CalcVATAmountLCY(): Decimal
    var
        LCYCurrency: Record Currency;
        VATAmountLCY: Decimal;
    begin
        GetExpense();
        if Expense."Currency Code" = '' then
            exit("VAT Amount");

        Expense.TestField("Expense Date");

        LCYCurrency.InitRoundingPrecision();
        InitializeCurrency();

        "VAT Difference" :=
            "VAT Amount" -
            Round(
                Amount * "VAT %" / (100 + "VAT %"), Currency."Amount Rounding Precision", Currency.VATRoundingDirection());

        if "VAT Difference" = 0 then
            VATAmountLCY := Round("Amount (LCY)" * "VAT %" / (100 + "VAT %"), LCYCurrency."Amount Rounding Precision", LCYCurrency.VATRoundingDirection())
        else
            VATAmountLCY :=
                Round(
                    CurrExchRate.ExchangeAmtFCYToLCY(Expense."Expense Date", Expense."Currency Code", "VAT Amount", Expense."Currency Factor"),
                    LCYCurrency."Amount Rounding Precision", LCYCurrency.VATRoundingDirection());

        exit(VATAmountLCY);
    end;

    /// <summary>
    /// Initializes the Currency record from the parent Expense for rounding calculations.
    /// </summary>
    /// <remarks>
    /// If the expense has no currency code, the default rounding precision is used.
    /// An error will be raised if the retrieved currency does not have amount rounding precision set.
    /// </remarks>
    protected procedure InitializeCurrency()
    begin
        GetExpense();
        if Expense."Currency Code" = '' then begin
            Clear(Currency);
            Currency.InitRoundingPrecision();
        end else
            if Expense."Currency Code" <> Currency.Code then begin
                Currency.Get(Expense."Currency Code");
                Currency.TestField("Amount Rounding Precision");
            end;
    end;

    protected procedure GetCurrencyCode(): Code[20]
    begin
        GetExpense();
        exit(Expense."Currency Code");
    end;

    protected procedure GetExpense()
    begin
        if "Expense No." <> Expense."No." then
            Expense.Get("Expense No.");
    end;

    local procedure ValidateAmount()
    begin
        InitializeCurrency();
        if Expense."Currency Code" = '' then
            "Amount (LCY)" := Amount
        else
            "Amount (LCY)" := Round(
                CurrExchRate.ExchangeAmtFCYToLCY(Expense."Expense Date", Expense."Currency Code", Amount, Expense."Currency Factor"));

        Amount := Round(Amount, Currency."Amount Rounding Precision");

        Validate("VAT %");
    end;

    /// <summary>
    /// Stores a UTF-8 reasoning string into the Reasoning blob.
    /// </summary>
    procedure SetReasoning(NewReasoning: Text)
    var
        OutStream: OutStream;
    begin
        Clear(Reasoning);
        Reasoning.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(NewReasoning);
    end;

    /// <summary>
    /// Reads the Reasoning blob as a UTF-8 string.
    /// </summary>
    procedure GetReasoning() Result: Text
    var
        InStream: InStream;
    begin
        CalcFields(Rec.Reasoning);
        if not Rec.Reasoning.HasValue() then
            exit('');
        Rec.Reasoning.CreateInStream(InStream, TextEncoding::UTF8);
        InStream.ReadText(Result);
    end;
}
