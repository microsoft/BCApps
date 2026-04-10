// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using Microsoft.Finance.Currency;

/// <summary>
/// Stores currency-specific additional fee and line fee amounts for reminder levels.
/// </summary>
table 329 "Currency for Reminder Level"
{
    Caption = 'Currency for Reminder Level';
    DataCaptionFields = "Reminder Terms Code", "No.";
    DrillDownPageID = "Currencies for Reminder Level";
    LookupPageID = "Currencies for Reminder Level";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Specifies the reminder terms to which this currency fee configuration belongs.
        /// </summary>
        field(1; "Reminder Terms Code"; Code[10])
        {
            Caption = 'Reminder Terms Code';
            Editable = false;
            NotBlank = true;
            TableRelation = "Reminder Terms";
        }
        /// <summary>
        /// Specifies the reminder level number within the terms.
        /// </summary>
        field(2; "No."; Integer)
        {
            Caption = 'No.';
            Editable = false;
        }
        /// <summary>
        /// Specifies the currency for which this fee configuration applies.
        /// </summary>
        field(3; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            ToolTip = 'Specifies the code for the currency in which you want to set up additional fees for reminders.';
            NotBlank = true;
            TableRelation = Currency;
        }
        /// <summary>
        /// Specifies the additional fee amount in the specified currency for this reminder level.
        /// </summary>
        field(4; "Additional Fee"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Additional Fee';
            ToolTip = 'Specifies the amount of the additional fee in foreign currency that will be added on the reminder.';
            MinValue = 0;
        }
        /// <summary>
        /// Specifies the line fee amount in the specified currency for this reminder level.
        /// </summary>
        field(5; "Add. Fee per Line"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Add. Fee per Line';
            ToolTip = 'Specifies that the fee is distributed on individual reminder lines.';
            MinValue = 0;
        }
    }

    keys
    {
        key(Key1; "Reminder Terms Code", "No.", "Currency Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

