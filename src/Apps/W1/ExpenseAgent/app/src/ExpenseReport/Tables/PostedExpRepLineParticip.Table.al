// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.HumanResources.Employee;

table 6917 "Posted Exp. Rep. Line Particip"
{
    Access = Internal;
    Caption = 'Posted Expense Report Line Participants';
    DataClassification = CustomerContent;
    LookupPageId = "Posted Exp. Rep. Line Particip";
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
        field(8; "Participant Type"; Enum "Expense Participant Type")
        {
            Caption = 'Participant Type';

            trigger OnValidate()
            begin
                if Rec."Participant Type" <> xRec."Participant Type" then
                    Rec.Validate("Participant Employee No.", '');
            end;
        }
        field(9; "Participant Employee No."; Code[20])
        {
            Caption = 'Participant Employee No.';
            TableRelation = if ("Participant Type" = const(Employee)) Employee."No.";
        }
        field(10; "Participant Name"; Text[100])
        {
            Caption = 'Participant Name';
        }
        field(11; "Participant Organization"; Text[100])
        {
            Caption = 'Participant Organization';
        }
        field(12; "Participant Country/Region"; Code[10])
        {
            Caption = 'Participant Country/Region';
        }
        field(13; "Participant Title"; Text[30])
        {
            Caption = 'Participant Title';
        }
        field(14; "Participant Email"; Text[80])
        {
            Caption = 'Participant Email';
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