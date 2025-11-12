// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.StandardCost;

table 5840 "Standard Cost Worksheet Name"
{
    Caption = 'Standard Cost Worksheet Name';
    LookupPageID = "Standard Cost Worksheet Names";
    DataClassification = CustomerContent;

    fields
    {
        field(2; Name; Code[10])
        {
            Caption = 'Name';
            NotBlank = true;
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; Name)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        StdCostWksh.SetRange("Standard Cost Worksheet Name", Name);
        StdCostWksh.DeleteAll(true);
    end;

    var
        StdCostWksh: Record "Standard Cost Worksheet";
}

