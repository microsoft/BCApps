// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.PowerBIReports;

table 36956 "PowerBI ABC Analysis Setup"
{
    Access = Internal;
    Caption = 'Power BI ABC Analysis Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Category A"; Decimal)
        {
            Caption = 'Category A';
            AutoFormatType = 0;
            InitValue = 0;
            MinValue = 0;
            MaxValue = 100;
            DecimalPlaces = 0 : 5;
        }
        field(3; "Category B"; Decimal)
        {
            Caption = 'Category B';
            AutoFormatType = 0;
            InitValue = 0;
            MinValue = 0;
            MaxValue = 100;
            DecimalPlaces = 0 : 5;
        }
        field(4; "Category C"; Decimal)
        {
            Caption = 'Category C';
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

    internal procedure ValidateCategoryFields()
    var
        CategoriesSumErr: Label 'The total of Category A, B, and C percentages must equal 100. Please adjust the values accordingly.';
    begin
        if (Rec."Category A" + Rec."Category B" + Rec."Category C" <> 100) then
            Error(CategoriesSumErr);
    end;
}