// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Setup;

table 5607 "FA Class"
{
    Caption = 'FA Class';
    LookupPageID = "FA Classes";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            ToolTip = 'Specifies a code for the class that the fixed asset belongs to.';
            NotBlank = true;
        }
        field(2; Name; Text[50])
        {
            Caption = 'Name';
            ToolTip = 'Specifies the name of the fixed asset class.';
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
    }
}

