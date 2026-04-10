// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.FinanceCharge;

/// <summary>
/// Stores beginning and ending text lines for finance charge memos per finance charge terms code.
/// </summary>
table 301 "Finance Charge Text"
{
    Caption = 'Finance Charge Text';
    DrillDownPageID = "Finance Charge Text";
    LookupPageID = "Finance Charge Text";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Specifies the finance charge terms code that this text line belongs to.
        /// </summary>
        field(1; "Fin. Charge Terms Code"; Code[10])
        {
            Caption = 'Fin. Charge Terms Code';
            ToolTip = 'Specifies the code for the involved finance charges in case of late payment.';
            NotBlank = true;
            TableRelation = "Finance Charge Terms";
        }
        /// <summary>
        /// Specifies whether this text appears at the beginning or end of the finance charge memo.
        /// </summary>
        field(2; Position; Option)
        {
            Caption = 'Position';
            ToolTip = 'Specifies whether the text will appear at the beginning or the end of the finance charge memo.';
            OptionCaption = 'Beginning,Ending';
            OptionMembers = Beginning,Ending;
        }
        /// <summary>
        /// Specifies the line number used to order multiple text lines within the same position.
        /// </summary>
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        /// <summary>
        /// Contains the text content that will appear on the finance charge memo, which may include placeholders for dynamic values.
        /// </summary>
        field(4; Text; Text[100])
        {
            Caption = 'Text';
            ToolTip = 'Specifies the text that you want to insert in the finance charge memo.';
        }
    }

    keys
    {
        key(Key1; "Fin. Charge Terms Code", Position, "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

