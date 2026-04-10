// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Opportunity;

table 5094 "Close Opportunity Code"
{
    Caption = 'Close Opportunity Code';
    DataCaptionFields = "Code", Description;
    DataClassification = CustomerContent;
    LookupPageID = "Close Opportunity Codes";

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            ToolTip = 'Specifies the code for closing the opportunity.';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the description of the reason for closing the opportunity.';
        }
        field(3; "No. of Opportunities"; Integer)
        {
            CalcFormula = count ("Opportunity Entry" where("Close Opportunity Code" = field(Code)));
            Caption = 'No. of Opportunities';
            ToolTip = 'Specifies the number of opportunities closed using this close opportunity code. This field is not editable.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(4; Type; Option)
        {
            Caption = 'Type';
            ToolTip = 'Specifies whether the opportunity was a success or a failure.';
            OptionCaption = 'Won,Lost';
            OptionMembers = Won,Lost;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", Description, Type)
        {
        }
    }
}

