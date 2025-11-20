// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Analysis;

table 7116 "Analysis Column Template"
{
    Caption = 'Analysis Column Template';
    DataCaptionFields = Name, Description;
    LookupPageID = "Analysis Column Templates";
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
        ItemColumnLayout: Record "Analysis Column";
    begin
        ItemColumnLayout.SetRange("Analysis Area", "Analysis Area");
        ItemColumnLayout.SetRange("Analysis Column Template", Name);
        ItemColumnLayout.DeleteAll(true);
    end;
}

