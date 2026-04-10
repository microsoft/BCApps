// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Setup;

using Microsoft.FixedAssets.FixedAsset;

table 5608 "FA Subclass"
{
    Caption = 'FA Subclass';
    LookupPageID = "FA Subclasses";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            ToolTip = 'Specifies a code for the subclass that the fixed asset belongs to.';
            NotBlank = true;
        }
        field(2; Name; Text[50])
        {
            Caption = 'Name';
            ToolTip = 'Specifies the name of the fixed asset subclass.';
        }
        field(3; "FA Class Code"; Code[10])
        {
            Caption = 'FA Class Code';
            ToolTip = 'Specifies the class that the subclass belongs to.';
            TableRelation = "FA Class";
        }
        field(4; "Default FA Posting Group"; Code[20])
        {
            Caption = 'Default FA Posting Group';
            ToolTip = 'Specifies the posting group that is used when posting fixed assets that belong to this subclass.';
            TableRelation = "FA Posting Group";
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

