// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

table 6919 "Posted Exp. Rep. Line Item"
{
    Access = Internal;
    Caption = 'Posted Expense Report Line Itemization';
    DataClassification = CustomerContent;
    LookupPageId = "Posted Exp. Rep. Line Items";
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
            TableRelation = "Expense Category".Code;
        }
        field(7; "Expense Subcategory Code"; Code[20])
        {
            Caption = 'Expense Subcategory Code';
            TableRelation = "Expense SubCategory".Code where("Expense Category Code" = field("Expense Category Code"));
        }
        field(8; "Description"; Text[100])
        {
            Caption = 'Description';
        }
        field(9; "Start Date"; Date)
        {
            Caption = 'Start Date';
        }
        field(10; Quantity; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity';
        }
        field(11; "Daily Rate"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Daily Rate';
        }
        field(12; "Amount"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Amount';
        }
        field(13; "Refundable"; Boolean)
        {
            Caption = 'Refundable';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Expense Report No.", "Expense Report Line No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Expense Report No.", "Expense Report Line No.")
        {
            SumIndexFields = Amount;
        }
    }
}