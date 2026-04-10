// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Shipping;

using Microsoft.Foundation.Calendar;

table 5790 "Shipping Agent Services"
{
    Caption = 'Shipping Agent Services';
    DrillDownPageID = "Shipping Agent Services";
    LookupPageID = "Shipping Agent Services";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Shipping Agent Code"; Code[10])
        {
            Caption = 'Shipping Agent Code';
            NotBlank = true;
            TableRelation = "Shipping Agent";
        }
        field(2; "Code"; Code[10])
        {
            Caption = 'Code';
            ToolTip = 'Specifies the shipping agent.';
            NotBlank = true;
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the shipping agent.';
        }
        field(4; "Shipping Time"; DateFormula)
        {
            Caption = 'Shipping Time';
            ToolTip = 'Specifies how long it takes from when the items are shipped from the warehouse to when they are delivered.';

            trigger OnValidate()
            var
                DateTest: Date;
            begin
                DateTest := CalcDate("Shipping Time", WorkDate());
                if DateTest < WorkDate() then
                    Error(Text000, FieldCaption("Shipping Time"));
            end;
        }
        field(7600; "Base Calendar Code"; Code[10])
        {
            Caption = 'Base Calendar Code';
            ToolTip = 'Specifies a customizable calendar for shipment planning that holds the shipping agent''s working days and holidays.';
            TableRelation = "Base Calendar";
        }
    }

    keys
    {
        key(Key1; "Shipping Agent Code", "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", Description, "Shipping Time")
        {
        }
    }

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'The %1 cannot be negative.';
#pragma warning restore AA0470
#pragma warning restore AA0074
}

