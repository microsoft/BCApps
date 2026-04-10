// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Analysis;

table 7160 "ABC Analysis Setup"
{
    Caption = 'ABC Analysis Setup';
    DrillDownPageID = "ABC Analysis Setup";
    LookupPageID = "ABC Analysis Setup";
    DataClassification = CustomerContent;
    ReplicateData = false;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Category A"; Decimal)
        {
            Caption = 'Category A %';
            AutoFormatType = 0;
            InitValue = 0;
            MinValue = 0;
            MaxValue = 100;
            DecimalPlaces = 0 : 5;
        }
        field(3; "Category B"; Decimal)
        {
            Caption = 'Category B %';
            AutoFormatType = 0;
            InitValue = 0;
            MinValue = 0;
            MaxValue = 100;
            DecimalPlaces = 0 : 5;
        }
        field(4; "Category C"; Decimal)
        {
            Caption = 'Category C %';
            AutoFormatType = 0;
            InitValue = 0;
            MinValue = 0;
            MaxValue = 100;
            DecimalPlaces = 0 : 5;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    var
        CategoriesSumErr: Label 'The total of Category A, B, and C percentages must equal 100. Please adjust the values accordingly.';

    internal procedure ValidateCategoryFields()
    begin
        if (Rec."Category A" + Rec."Category B" + Rec."Category C" <> 100) then
            Error(CategoriesSumErr);
    end;

    internal procedure InitializeValues()
    begin
        Rec."Category A" := 50;
        Rec."Category B" := 30;
        Rec."Category C" := 20;
    end;
}