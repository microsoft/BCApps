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
        }
        field(28; "Expense Subcategory"; Code[20])
        {
            Caption = 'Expense Subcategory';
            TableRelation = "Expense Subcategory".Code where("Expense Category Code" = field("Expense Category"));
            ToolTip = 'Specifies the expense subcategory associated with this VAT specification line, providing a more detailed classification within the expense category.';
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
            var
                Currency: Record Currency;
                GLSetup: Record "General Ledger Setup";
                CurrAmountRoundingPrecision: Decimal;
                LCYAmountRoundingPrecision: Decimal;
            begin
                if "Reclaim %" <> xRec."Reclaim %" then
                    "Reclaim Status" := "Reclaim Status"::"Pending";

                GLSetup.Get();
                LCYAmountRoundingPrecision := GLSetup."Amount Rounding Precision";
                CurrAmountRoundingPrecision := LCYAmountRoundingPrecision;
                if ("Currency Code" <> '') and Currency.Get("Currency Code") then
                    CurrAmountRoundingPrecision := Currency."Amount Rounding Precision";
                "Reclaim VAT Amount" := Round("VAT Amount" * "Reclaim %" / 100, CurrAmountRoundingPrecision);
                "Reclaim VAT Amount (LCY)" := Round("VAT Amount (LCY)" * "Reclaim %" / 100, LCYAmountRoundingPrecision);
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
    }

    keys
    {
        key(PK; "Document No.", "Document Line No.", "Line No.")
        {
            Clustered = true;
        }
        key(Reclaim; "Document No.", Reclaimable, "Reclaim Status") { }
    }

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
