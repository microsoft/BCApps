// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;

/// <summary>
/// Per-VAT-rate breakdown attached to an <see cref="Expense Report Line"/>. One row per VAT
/// rate / VAT product posting group on the receipt. This is the posting unit for VAT — the
/// ExpensePostMgt loop emits one Gen. Journal line per spec row when at least one row exists,
/// instead of using the line-level VAT fields. Reclaim approval also lives here, so an
/// approver can approve / reject / override each rate independently (e.g. on a hotel receipt:
/// reclaim room VAT but reject minibar VAT).
/// </summary>
table 6922 "Expense Report Line VAT Spec."
{
    Access = Internal;
    Caption = 'Expense Report Line VAT Specification';
    DataClassification = CustomerContent;
    LookupPageId = "Expense Report Line VAT Spec.";
    DrillDownPageId = "Expense Report Line VAT Spec.";
    ReplicateData = false;

    fields
    {
        field(1; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = "Expense Report Header"."No.";
            ToolTip = 'Specifies the document number of the associated expense report.';
            NotBlank = true;
        }
        field(2; "Document Line No."; Integer)
        {
            Caption = 'Document Line No.';
            ToolTip = 'Specifies the line number of the associated expense report line.';
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
            ToolTip = 'Specifies the line number of this VAT specification.';
        }
        field(10; "VAT %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'VAT %';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 100;
            ToolTip = 'Specifies the VAT rate.';

            trigger OnValidate()
            begin
                InitializeCurrency();
                "VAT Amount" := Round(Amount * "VAT %" / (100 + "VAT %"), Currency."Amount Rounding Precision", Currency.VATRoundingDirection());
                "VAT Base Amount" := Round(Amount - "VAT Amount", Currency."Amount Rounding Precision");
                "VAT Difference" := 0;
                "VAT Amount (LCY)" := CalcVATAmountLCY();
                "VAT Base Amount (LCY)" := "Amount (LCY)" - "VAT Amount (LCY)";
                UpdateReimbursementAmounts();
            end;
        }
        field(11; "VAT Base Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = "Currency Code";
            Caption = 'VAT Base Amount';
            ToolTip = 'Specifies the net amount this VAT rate applies to.';
        }
        field(12; "VAT Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = "Currency Code";
            Caption = 'VAT Amount';
            ToolTip = 'Specifies the VAT amount for this rate.';
        }
        field(13; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
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
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Difference';
            ToolTip = 'Specifies the difference between the calculated VAT amount and a VAT amount that you have entered manually.';
            Editable = false;
        }
        field(15; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            ToolTip = 'Specifies the currency code for the amounts in this VAT specification line. If empty, amounts are in local currency.';
        }
        field(16; "Currency Factor"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Currency Factor';
            DecimalPlaces = 0 : 15;
            Editable = false;
            MinValue = 0;
            ToolTip = 'Specifies the currency factor used to convert amounts to the local currency.';
        }
        field(20; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
            ToolTip = 'Specifies the VAT business posting group used when posting this rate.';
        }
        field(21; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";
            ToolTip = 'Specifies the VAT product posting group used when posting this rate.';
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
            ToolTip = 'Specifies the VAT amount in local currency for this rate.';
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
            ToolTip = 'Specifies the net amount in local currency this VAT rate applies to.';
        }
        /// <summary>
        /// Transaction amount converted to local currency using exchange rates and currency factors.
        /// </summary>
        field(26; "Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Amount (LCY)';
            ToolTip = 'Specifies the total amount in local currency for this expense line.';

            trigger OnValidate()
            begin
                if "Currency Code" = '' then begin
                    Amount := "Amount (LCY)";
                    Validate(Amount);
                end else begin
                    TestField("Amount (LCY)");
                    TestField(Amount);
                    "Currency Factor" := Amount / "Amount (LCY)";
                end;

                Validate("VAT %");
            end;
        }
        field(27; "Expense Category"; Code[20])
        {
            Caption = 'Expense Category';
            TableRelation = "Expense Category".Code;
            ToolTip = 'Specifies the expense category associated with this VAT specification line, used to identify the type of expense for reporting and VAT reclaim purposes.';

            trigger OnValidate()
            var
                ExpenseCategory: Record "Expense Category";
            begin
                if "Expense Category" = '' then
                    exit;
                if ExpenseCategory.Get("Expense Category") then begin
                    ExpenseCategory.TestField(Inactive, false);
                    if "Expense Subcategory" <> '' then
                        exit;
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
            ToolTip = 'Specifies the expense subcategory associated with this VAT specification line, providing a more detailed classification within the expense category.';

            trigger OnValidate()
            var
                ExpenseCategory: Record "Expense Category";
                ExpenseSubcategory: Record "Expense Subcategory";
            begin
                if "Expense Subcategory" <> '' then begin
                    if ExpenseSubcategory.Get("Expense Category", "Expense Subcategory") then begin
                        ExpenseSubcategory.TestField(Inactive, false);
                        "VAT Prod. Posting Group" := ExpenseSubcategory."VAT Prod. Posting Group";
                        "VAT %" := ExpenseSubcategory."Default VAT %";
                        Validate("VAT %");
                    end;
                end else
                    if "Expense Category" <> '' then
                        if ExpenseCategory.Get("Expense Category") then begin
                            ExpenseCategory.TestField(Inactive, false);
                            "VAT Prod. Posting Group" := ExpenseCategory."VAT Prod. Posting Group";
                            "VAT %" := ExpenseCategory."Default VAT %";
                            Validate("VAT %");
                        end;
            end;
        }
        field(30; Reclaimable; Boolean)
        {
            Caption = 'Reclaimable';
            ToolTip = 'Specifies whether this VAT amount is reclaimable.';

            trigger OnValidate()
            begin
                if not Reclaimable then begin
                    Validate("Reclaim %", 0);
                    "Reclaim Status" := "Reclaim Status"::Rejected;
                end;
            end;
        }
        field(31; "Reclaim %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Reclaim %';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 100;
            ToolTip = 'Specifies the reclaim percentage for partial deductibility.';

            trigger OnValidate()
            begin
                if "Reclaim %" <> xRec."Reclaim %" then
                    "Reclaim Status" := "Reclaim Status"::"Pending";

                UpdateReclaimAmounts();
            end;
        }
        field(32; "Reclaim Reason"; Text[250])
        {
            Caption = 'Reclaim Reason';
            ToolTip = 'Specifies a short reason supplied with the reclaim suggestion.';
        }
        field(33; "Reclaim Approved"; Boolean)
        {
            Caption = 'Reclaim Approved';
            Editable = false;
            ObsoleteReason = 'Use "Reclaim Status" field instead.';
#if not CLEAN29
            ObsoleteState = Pending;
            ObsoleteTag = '29.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '32.0';
#endif
            ToolTip = 'Specifies whether reclaim has been approved for this VAT row.';
        }
        field(34; "Reclaim Approved By"; Code[50])
        {
            Caption = 'Reclaim Approved By';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
            ToolTip = 'Specifies the user who approved the reclaim.';
        }
        field(35; "Reclaim Approved At"; DateTime)
        {
            Caption = 'Reclaim Approved At';
            Editable = false;
            ToolTip = 'Specifies when the reclaim was approved.';
        }
        field(36; "Reclaim Justification"; Blob)
        {
            Caption = 'Reclaim Justification';
            ToolTip = 'Specifies the justification for the reclaim.';
        }
        field(37; "Reclaim VAT Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Currency Code";
            Caption = 'Reclaim VAT Amount';
            Editable = false;
            ToolTip = 'Specifies the reclaim amount calculated based on the reclaim percentage.';
        }
        field(38; "Reclaim VAT Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Reclaim VAT Amount (LCY)';
            Editable = false;
            ToolTip = 'Specifies the reclaim amount in local currency calculated based on the reclaim percentage.';
        }
        field(40; Source; Enum "Expense VAT Spec Source")
        {
            Caption = 'Source';
            ToolTip = 'Specifies the provenance of this row (Agent / Manual / Override).';
        }
        field(41; "Source Spec Line No."; Integer)
        {
            Caption = 'Source Spec Line No.';
            Editable = false;
        }
        field(42; Confidence; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Confidence';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 1;
            ToolTip = 'Specifies the agent confidence (0..1) for this row.';
        }
        field(43; "Reclaim Status"; Enum "Expense Reclaim Status")
        {
            Caption = 'Reclaim Status';
            Editable = false;
            ToolTip = 'Specifies whether the VAT reclaim for this row is pending, approved, or rejected.';

            trigger OnValidate()
            var
                NewReclaimStatus: Enum "Expense Reclaim Status";
            begin
                NewReclaimStatus := "Reclaim Status";
                case "Reclaim Status" of
                    NewReclaimStatus::Approved:
                        Rec.Validate("Reclaim %");
                    NewReclaimStatus::Rejected:
                        Rec.Validate("Reclaim %", 0);
                end;
                "Reclaim Status" := NewReclaimStatus;
                Rec."Reclaim Approved By" := CopyStr(UserId(), 1, MaxStrLen(Rec."Reclaim Approved By"));
                Rec."Reclaim Approved At" := CurrentDateTime();
            end;
        }
        /// <summary>
        /// VAT amount converted to local currency for accounting and reporting purposes.
        /// </summary>
        field(50; "VAT Base Amount (RCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = GetReimbursementCurrencyCode();
            Caption = 'VAT Base Amount (RCY)';
            DataClassification = CustomerContent;
            Editable = false;
            ToolTip = 'Specifies the VAT base amount in reimbursement currency for this rate.';
        }
        field(51; "VAT Amount (RCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = GetReimbursementCurrencyCode();
            Caption = 'VAT Amount (RCY)';
            DataClassification = CustomerContent;
            Editable = false;
            ToolTip = 'Specifies the VAT amount in reimbursement currency for this rate.';
        }
        field(52; "Amount (RCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = GetReimbursementCurrencyCode();
            Caption = 'Amount (RCY)';
            DataClassification = CustomerContent;
            Editable = false;
            ToolTip = 'Specifies the total amount in reimbursement currency for this rate.';
        }
        field(53; "Reclaim VAT Amount (RCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = GetReimbursementCurrencyCode();
            Caption = 'Reclaim VAT Amount (RCY)';
            DataClassification = CustomerContent;
            Editable = false;
            ToolTip = 'Specifies the reclaim VAT amount in reimbursement currency for this rate.';
        }
    }

    keys
    {
        key(PK; "Document No.", "Document Line No.", "Line No.")
        {
            Clustered = true;
        }
        key(Reclaim; "Document No.", Reclaimable, "Reclaim Status") { }
    }

    var
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";

    local procedure CalcVATAmountLCY(): Decimal
    var
        LCYCurrency: Record Currency;
        VATAmountLCY: Decimal;
    begin
        if "Currency Code" = '' then
            exit("VAT Amount");

        LCYCurrency.InitRoundingPrecision();
        InitializeCurrency();

        "VAT Difference" :=
            "VAT Amount" -
            Round(Amount * "VAT %" / (100 + "VAT %"), Currency."Amount Rounding Precision", Currency.VATRoundingDirection());

        if "VAT Difference" = 0 then
            VATAmountLCY := Round("Amount (LCY)" * "VAT %" / (100 + "VAT %"), LCYCurrency."Amount Rounding Precision", LCYCurrency.VATRoundingDirection())
        else begin
            GetExpenseReportLine();
            VATAmountLCY :=
                Round(
                    CurrencyExchangeRate.ExchangeAmtFCYToLCY(ExpenseReportLine."Expense Date", "Currency Code", "VAT Amount", "Currency Factor"),
                    LCYCurrency."Amount Rounding Precision", LCYCurrency.VATRoundingDirection());
        end;

        exit(VATAmountLCY);
    end;

    local procedure GetExpenseReportHeader()
    begin
        if "Document No." <> ExpenseReportHeader."No." then begin
            ExpenseReportHeader.SetLoadFields("Reimbursement Currency Code");
            ExpenseReportHeader.Get("Document No.");
        end;
    end;

    local procedure GetExpenseReportLine()
    begin
        if ("Document No." <> ExpenseReportLine."Document No.") or ("Document Line No." <> ExpenseReportLine."Line No.") then begin
            ExpenseReportLine.SetLoadFields("Expense Date");
            ExpenseReportLine.Get("Document No.", "Document Line No.");
        end;
    end;

    local procedure GetReimbursementCurrencyCode(): Code[20]
    begin
        GetExpenseReportHeader();
        exit(ExpenseReportHeader."Reimbursement Currency Code");
    end;

    local procedure InitializeCurrency()
    begin
        if "Currency Code" = '' then begin
            Clear(Currency);
            Currency.InitRoundingPrecision();
        end else
            if "Currency Code" <> Currency.Code then begin
                Currency.Get("Currency Code");
                Currency.TestField("Amount Rounding Precision");
            end;
    end;

    local procedure UpdateReclaimAmounts()
    begin
        GetExpenseReportHeader();
        UpdateReclaimAmounts(ExpenseReportHeader."Reimbursement Currency Code");
    end;

    local procedure UpdateReclaimAmounts(ReimbursementCurrencyCode: Code[10])
    var
        GLSetup: Record "General Ledger Setup";
        ReimbursementCurrency: Record Currency;
        CurrencyAmountRoundingPrecision: Decimal;
        LCYAmountRoundingPrecision: Decimal;
        ReimbursementAmountRoundingPrecision: Decimal;
    begin
        GLSetup.Get();
        LCYAmountRoundingPrecision := GLSetup."Amount Rounding Precision";
        CurrencyAmountRoundingPrecision := LCYAmountRoundingPrecision;
        if ("Currency Code" <> '') and Currency.Get("Currency Code") then
            CurrencyAmountRoundingPrecision := Currency."Amount Rounding Precision";

        ReimbursementCurrency.Initialize(ReimbursementCurrencyCode);
        ReimbursementAmountRoundingPrecision := ReimbursementCurrency."Amount Rounding Precision";

        "Reclaim VAT Amount" := Round("VAT Amount" * "Reclaim %" / 100, CurrencyAmountRoundingPrecision);
        "Reclaim VAT Amount (LCY)" := Round("VAT Amount (LCY)" * "Reclaim %" / 100, LCYAmountRoundingPrecision);
        "Reclaim VAT Amount (RCY)" := Round("VAT Amount (RCY)" * "Reclaim %" / 100, ReimbursementAmountRoundingPrecision);
    end;

    internal procedure UpdateReimbursementAmounts()
    begin
        GetExpenseReportHeader();
        UpdateReimbursementAmounts(ExpenseReportHeader);
    end;

    internal procedure UpdateReimbursementAmounts(NewExpenseReportHeader: Record "Expense Report Header")
    var
        ReimbursementCurrency: Record Currency;
    begin
        ReimbursementCurrency.Initialize(NewExpenseReportHeader."Reimbursement Currency Code");

        if NewExpenseReportHeader."Reimbursement Currency Code" = '' then begin
            "VAT Base Amount (RCY)" := "VAT Base Amount (LCY)";
            "VAT Amount (RCY)" := "VAT Amount (LCY)";
            "Amount (RCY)" := "Amount (LCY)";
        end else begin
            "VAT Base Amount (RCY)" :=
                Round(
                    CurrencyExchangeRate.ExchangeAmtLCYToFCY(
                        NewExpenseReportHeader."Posting Date", NewExpenseReportHeader."Reimbursement Currency Code",
                        "VAT Base Amount (LCY)", NewExpenseReportHeader."Reimbursement Currency Factor"),
                    ReimbursementCurrency."Amount Rounding Precision");
            "VAT Amount (RCY)" :=
                Round(
                    CurrencyExchangeRate.ExchangeAmtLCYToFCY(
                        NewExpenseReportHeader."Posting Date", NewExpenseReportHeader."Reimbursement Currency Code",
                        "VAT Amount (LCY)", NewExpenseReportHeader."Reimbursement Currency Factor"),
                    ReimbursementCurrency."Amount Rounding Precision");
            "Amount (RCY)" := "VAT Base Amount (RCY)" + "VAT Amount (RCY)";
        end;

        UpdateReclaimAmounts(NewExpenseReportHeader."Reimbursement Currency Code");
    end;

    local procedure ValidateAmount()
    begin
        InitializeCurrency();
        if "Currency Code" = '' then
            "Amount (LCY)" := Amount
        else begin
            GetExpenseReportLine();
            "Amount (LCY)" := Round(
                CurrencyExchangeRate.ExchangeAmtFCYToLCY(ExpenseReportLine."Expense Date", "Currency Code", Amount, "Currency Factor"));
        end;

        Amount := Round(Amount, Currency."Amount Rounding Precision");
        Validate("VAT %");
    end;

    /// <summary>Stores a UTF-8 reclaim justification text into the blob.</summary>
    procedure SetJustification(NewText: Text)
    var
        OutStream: OutStream;
    begin
        Clear(Rec."Reclaim Justification");
        if NewText = '' then
            exit;
        Rec."Reclaim Justification".CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(NewText);
    end;

    /// <summary>Reads the reclaim justification blob as text.</summary>
    procedure GetJustification() Result: Text
    var
        InStream: InStream;
    begin
        CalcFields(Rec."Reclaim Justification");
        if not Rec."Reclaim Justification".HasValue() then
            exit('');
        Rec."Reclaim Justification".CreateInStream(InStream, TextEncoding::UTF8);
        InStream.ReadText(Result);
    end;
}
