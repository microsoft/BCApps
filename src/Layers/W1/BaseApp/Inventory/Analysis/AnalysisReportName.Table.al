// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Analysis;

table 7111 "Analysis Report Name"
{
    Caption = 'Analysis Report Name';
    DataCaptionFields = Name, Description;
    LookupPageID = "Analysis Report Names";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Analysis Area"; Enum "Analysis Area Type")
        {
            Caption = 'Analysis Area';
        }
        field(2; Name; Code[10])
        {
            Caption = 'Name';
            NotBlank = true;
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(4; "Analysis Line Template Name"; Code[10])
        {
            Caption = 'Analysis Line Template Name';
            TableRelation = "Analysis Line Template".Name where("Analysis Area" = field("Analysis Area"));
        }
        field(5; "Analysis Column Template Name"; Code[10])
        {
            Caption = 'Analysis Column Template Name';
            TableRelation = "Analysis Column Template".Name where("Analysis Area" = field("Analysis Area"));
        }
    }

    keys
    {
        key(Key1; "Analysis Area", Name)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

