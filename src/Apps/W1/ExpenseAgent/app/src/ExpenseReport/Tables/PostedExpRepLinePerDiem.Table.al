// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

table 6920 "Posted Exp. Rep. Line Per Diem"
{
    Access = Internal;
    Caption = 'Posted Expense Report Line Per Diem';
    DataClassification = CustomerContent;
    LookupPageId = "Posted Exp. Rep. Line Per Diem";
    ReplicateData = false;

    fields
    {
        field(1; "Expense Report No."; Code[20])
        {
            Caption = 'Expense Report No.';
            TableRelation = "Posted Expense Report Header"."No.";
        }
        field(2; "Expense Report Line No."; Integer)
        {
            Caption = 'Expense Report Line No.';
            TableRelation = "Posted Expense Report Line"."Line No." where("Document No." = field("Expense Report No."));
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(5; "Expense No."; Code[20])
        {
            Caption = 'Expense No.';
            TableRelation = Expense."No.";
        }
        field(6; "Expense Category Code"; Code[20])
        {
            Caption = 'Expense Category Code';
        }
        field(7; "Expense Subcategory Code"; Code[20])
        {
            Caption = 'Expense Subcategory Code';
        }
        field(8; "Expense Location"; Code[30])
        {
            Caption = 'Expense Location';
        }
        field(9; "Description"; Text[100])
        {
            Caption = 'Description';
        }
        field(10; "Date"; Date)
        {
            Caption = 'Date';
        }
        field(11; "Breakfast"; Boolean)
        {
            Caption = 'Breakfast';
        }
        field(12; "Lunch"; Boolean)
        {
            Caption = 'Lunch';
        }
        field(13; "Dinner"; Boolean)
        {
            Caption = 'Dinner';
        }
        field(14; "Per Diem Amount"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Per Diem Amount';
        }
        field(15; "Original Per Diem Amount"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Original Per Diem Amount';
            Editable = false;
        }
        field(16; "Breakfast Reduction Percent"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Breakfast Reduction Percent';
            Editable = false;
        }
        field(17; "Lunch Reduction Percent"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Lunch Reduction Percent';
            Editable = false;
        }
        field(18; "Dinner Reduction Percent"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Dinner Reduction Percent';
            Editable = false;
        }
    }
    keys
    {
        key(PK; "Expense Report No.", "Expense Report Line No.", "Line No.")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
        TestField("Expense Report No.");
        TestField("Expense Report Line No.");
        TestField("Line No.");
    end;
}