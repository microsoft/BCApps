// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Maintenance;

table 5917 "Fault Reason Code"
{
    Caption = 'Fault Reason Code';
    DataCaptionFields = "Code", Description;
    DrillDownPageID = "Fault Reason Codes";
    LookupPageID = "Fault Reason Codes";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            ToolTip = 'Specifies a code for the fault reason.';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the fault reason code.';
        }
        field(3; "Exclude Warranty Discount"; Boolean)
        {
            Caption = 'Exclude Warranty Discount';
            ToolTip = 'Specifies that you want to exclude a warranty discount for the service item assigned this fault reason code.';
        }
        field(4; "Exclude Contract Discount"; Boolean)
        {
            Caption = 'Exclude Contract Discount';
            ToolTip = 'Specifies that you want to exclude a contract/service discount for the service item assigned this fault reason code.';
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
        fieldgroup(DropDown; "Code", Description, "Exclude Warranty Discount", "Exclude Contract Discount")
        {
        }
    }
}

