// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.VAT.Setup;

/// <summary>
/// Immutable copy of <see cref="Exp. Report Line VAT Spec."/> written at the time the Expense
/// Report is posted. One row per VAT rate / VAT product posting group per posted line.
/// Rows with <see cref="Expense Report Line No."/> = 0 are the report-level aggregate
/// (one row per distinct VAT rate / VAT prod. posting group across all lines).
/// </summary>
table 6934 "Posted Exp. Rep. Line VAT Spec"
{
    Access = Internal;
    Caption = 'Posted Expense Report Line VAT Specification';
    DataClassification = CustomerContent;
    ReplicateData = false;

    fields
    {
        field(1; "Expense Report No."; Code[20])
        {
            Caption = 'Expense Report No.';
            TableRelation = "Posted Expense Report Header"."No.";
            NotBlank = true;
            ToolTip = 'Specifies the unique identifier of the posted expense report this VAT specification line belongs to.';
        }
        /// <summary>
        /// The posted expense report line this specification belongs to.
        /// 0 indicates a report-level aggregate row (totals per VAT rate across all lines).
        /// </summary>
        field(2; "Expense Report Line No."; Integer)
        {
            Caption = 'Expense Report Line No.';
            ToolTip = 'Specifies the line number of the posted expense report line this VAT specification line belongs to. A value of 0 indicates that this is a report-level aggregate line representing totals for the entire report.';
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
            ToolTip = 'Specifies the line number of this VAT specification line. This is used to uniquely identify multiple VAT specifications for the same expense report line when there are multiple VAT rates or product posting groups involved.';
        }
        field(10; "VAT %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'VAT %';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 100;
            ToolTip = 'Specifies the VAT percentage rate applied to this expense line for this VAT specification. This is used to calculate the VAT amount based on the VAT base amount.';
        }
        field(11; "VAT Base Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = "Currency Code";
            Caption = 'VAT Base Amount';
            ToolTip = 'Specifies the VAT base amount for this expense line and VAT specification. This is the amount on which the VAT percentage is applied to calculate the VAT amount.';
        }
        field(12; "VAT Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = "Currency Code";
            Caption = 'VAT Amount';
            ToolTip = 'Specifies the VAT amount for this expense line and VAT specification, calculated by applying the VAT percentage to the VAT base amount.';
        }
        field(13; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
            ToolTip = 'Specifies the total amount (including VAT) that the expense line consists of.';
        }
        field(14; "VAT Difference"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Difference';
            Editable = false;
            ToolTip = 'Specifies the difference in VAT amount calculated at the time of posting compared to the VAT amount calculated at the time of expense report approval. This can occur due to changes in exchange rates or VAT rates between approval and posting.';
        }
        field(15; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            ToolTip = 'Specifies the currency code of the amounts in this VAT specification line, based on ISO 4217 standard. This is used for proper formatting and calculations of the amounts.';
        }
        field(16; "Currency Factor"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Currency Factor';
            DecimalPlaces = 0 : 15;
            Editable = false;
            MinValue = 0;
            ToolTip = 'Specifies the currency factor used to convert amounts from the original transaction currency to the reporting currency (usually the company’s local currency) at the time of posting. This is used to calculate the amounts in local currency for reporting and VAT reclaim purposes.';
        }
        field(20; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
            ToolTip = 'Specifies the VAT business posting group associated with this VAT specification line, used to determine the VAT rules and rates applicable for this transaction based on the type of business activity.';
        }
        field(21; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";
            ToolTip = 'Specifies the VAT product posting group associated with this VAT specification line, used to determine the VAT rules and rates applicable for this transaction based on the type of product or service.';
        }
        field(24; "VAT Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'VAT Amount (LCY)';
            Editable = false;
            ToolTip = 'Specifies the VAT amount converted to local currency (LCY) using the currency factor at the time of posting. This is used for reporting and VAT reclaim purposes in the company’s local currency.';
        }
        field(25; "VAT Base Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'VAT Base Amount (LCY)';
            Editable = false;
            ToolTip = 'Specifies the VAT base amount converted to local currency (LCY) using the currency factor at the time of posting. This is used for reporting and VAT reclaim purposes in the company’s local currency.';
        }
        field(26; "Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Amount (LCY)';
            Editable = false;
            ToolTip = 'Specifies the total amount (including VAT) converted to local currency (LCY) using the currency factor at the time of posting. This is used for reporting and VAT reclaim purposes in the company’s local currency.';
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
            ToolTip = 'Specifies whether the VAT amount for this line is reclaimable.';
        }
        field(31; "Reclaim %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Reclaim %';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 100;
            ToolTip = 'Specifies the percentage of the VAT amount that is reclaimable. This is used to calculate the reclaimable VAT amount for this line.';
        }
        field(32; "Reclaim Reason"; Text[250])
        {
            Caption = 'Reclaim Reason';
            ToolTip = 'Specifies the reason why the VAT is reclaimable or not reclaimable for this line. This can be used for internal documentation and audit purposes when processing VAT reclaims.';
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
            ToolTip = 'Specifies the user ID of the person who approved the reclaim of the VAT amount for this line. This is used for audit purposes to track who approved the reclaim.';
        }
        field(35; "Reclaim Approved At"; DateTime)
        {
            Caption = 'Reclaim Approved At';
            Editable = false;
            ToolTip = 'Specifies the date and time when the reclaim of the VAT amount for this line was approved. This is used for audit purposes to track when the reclaim was approved.';
        }
        field(36; "Reclaim Justification"; Blob)
        {
            Caption = 'Reclaim Justification';
            ToolTip = 'Specifies the justification text for the reclaim of the VAT amount for this line, stored as a UTF-8 encoded blob. This allows for longer text than a standard string field and can include detailed explanations or notes regarding the reclaim.';
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
            ToolTip = 'Specifies the source of this VAT specification line, indicating how it was generated (e.g., from the original expense report line, from a correction, etc.). This can be used for tracking and reporting purposes to understand the origin of each VAT specification line.';
        }
        field(41; "Source Spec Line No."; Integer)
        {
            Caption = 'Source Spec Line No.';
            Editable = false;
            ToolTip = 'Specifies the line number of the source VAT specification line that this line was generated from, if applicable. This is used to trace back the origin of this VAT specification line to the original specification line it was based on, which can be helpful for auditing and troubleshooting purposes.';
        }
        field(42; Confidence; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Confidence';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 1;
            ToolTip = 'Specifies the confidence level of the VAT specification line, represented as a decimal value between 0 and 1. This can be used to indicate the reliability or accuracy of the VAT specification, especially in cases where it is generated based on machine learning predictions or incomplete data.';
        }
        field(43; "Reclaim Status"; Enum "Expense Reclaim Status")
        {
            Caption = 'Reclaim Status';
            Editable = false;
            ToolTip = 'Specifies whether the VAT reclaim for this row is pending, approved, or rejected.';
        }
    }

    keys
    {
        key(PK; "Expense Report No.", "Expense Report Line No.", "Line No.")
        {
            Clustered = true;
        }
        key(Secondary; "VAT Bus. Posting Group", "VAT Prod. Posting Group")
        {
        }
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
