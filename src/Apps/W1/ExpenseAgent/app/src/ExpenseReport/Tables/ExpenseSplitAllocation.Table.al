// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

table 7140 "Expense Split Allocation"
{
    Access = Internal;
    TableType = Temporary;
    Caption = 'Expense Split Allocation';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(2; "Expense User No."; Code[20])
        {
            Caption = 'Expense User No.';
            TableRelation = "Expense User"."No.";

            trigger OnValidate()
            var
                ExpenseUser: Record "Expense User";
            begin
                "Expense User Name" := '';
                if "Expense User No." = '' then
                    exit;

                ExpenseUser.Get("Expense User No.");
                ExpenseUser.TestField("Employee No.");
                "Expense User Name" := ExpenseUser.Name;
            end;
        }
        field(3; "Expense User Name"; Text[100])
        {
            Caption = 'Expense User Name';
            Editable = false;
        }
        field(4; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Amount';
            MinValue = 0;
        }
        field(5; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            Editable = false;
        }
        field(6; "Expense Category"; Code[20])
        {
            Caption = 'Expense Category';
            TableRelation = "Expense Category".Code where(Inactive = const(false));

            trigger OnValidate()
            begin
                if "Expense Category" <> xRec."Expense Category" then
                    "Expense Subcategory Code" := '';
            end;
        }
        field(7; "Expense Subcategory Code"; Code[20])
        {
            Caption = 'Expense Subcategory';
            TableRelation = "Expense Subcategory".Code where("Expense Category Code" = field("Expense Category"), Inactive = const(false));
        }
        field(8; Description; Text[100])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(PK; "Line No.")
        {
            Clustered = true;
        }
    }
}
