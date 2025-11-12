// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using Microsoft.Finance.Currency;

table 329 "Currency for Reminder Level"
{
    Caption = 'Currency for Reminder Level';
    DataCaptionFields = "Reminder Terms Code", "No.";
    DrillDownPageID = "Currencies for Reminder Level";
    LookupPageID = "Currencies for Reminder Level";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Reminder Terms Code"; Code[10])
        {
            Caption = 'Reminder Terms Code';
            Editable = false;
            NotBlank = true;
            TableRelation = "Reminder Terms";
        }
        field(2; "No."; Integer)
        {
            Caption = 'No.';
            Editable = false;
        }
        field(3; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            NotBlank = true;
            TableRelation = Currency;
        }
        field(4; "Additional Fee"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Additional Fee';
            MinValue = 0;
        }
        field(5; "Add. Fee per Line"; Decimal)
        {
            Caption = 'Add. Fee per Line';
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

