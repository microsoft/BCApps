// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Analysis;

table 7112 "Analysis Line Template"
{
    Caption = 'Analysis Line Template';
    DataCaptionFields = Name, Description;
    LookupPageID = "Analysis Line Templates";
    ReplicateData = true;
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
        field(3; Description; Text[80])
        {
            Caption = 'Description';
        }
        field(4; "Default Column Template Name"; Code[10])
        {
            Caption = 'Default Column Template Name';
            TableRelation = "Analysis Column Template".Name where("Analysis Area" = field("Analysis Area"));
        }
        field(5; "Item Analysis View Code"; Code[10])
        {
            Caption = 'Item Analysis View Code';
            TableRelation = "Item Analysis View".Code where("Analysis Area" = field("Analysis Area"));
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

    trigger OnDelete()
    var
        ItemSchedLine: Record "Analysis Line";
    begin
        ItemSchedLine.SetRange("Analysis Area", "Analysis Area");
        ItemSchedLine.SetRange("Analysis Line Template Name", Name);
        ItemSchedLine.DeleteAll(true);
    end;
}

