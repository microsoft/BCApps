// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Calendar;

table 7604 "Where Used Base Calendar"
{
    Caption = 'Where Used Base Calendar';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Source Type"; Enum "Calendar Source Type")
        {
            Caption = 'Source Type';
            ToolTip = 'Specifies whether this customized calendar entry was set up for your company, a customer, vendor, location, shipping agent, or a service.';
            Editable = false;
        }
        field(2; "Source Code"; Code[20])
        {
            Caption = 'Source Code';
            ToolTip = 'Specifies the source identity of the business partner the customized calendar is set up for.';
            Editable = false;
        }
        field(3; "Additional Source Code"; Code[20])
        {
            Caption = 'Additional Source Code';
            ToolTip = 'Specifies the code of the shipping agent service if the Source Type field contains Shipping Agent.';
            Editable = false;
        }
        field(4; "Base Calendar Code"; Code[10])
        {
            Caption = 'Base Calendar Code';
            TableRelation = "Base Calendar";
        }
        field(5; "Source Name"; Text[50])
        {
            Caption = 'Source Name';
            ToolTip = 'Specifies the source name associated with this entry.';
            Editable = false;
        }
        field(6; "Customized Changes Exist"; Boolean)
        {
            Caption = 'Customized Changes Exist';
            ToolTip = 'Specifies that this entry has used the base calendar to create a customized calendar.';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Base Calendar Code", "Source Type", "Source Code", "Source Name")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

