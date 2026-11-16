// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;
using Microsoft.Foundation.NoSeries;

table 6903 "Expense Rule Violation"
{
    DataClassification = CustomerContent;
    ReplicateData = false;
    Access = Internal;

    fields
    {
        field(1; "Expense No."; Code[20])
        {
            Caption = 'Expense No.';
            TableRelation = Expense."No.";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Description"; Text[500])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "Expense No.", "Line No.")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
        if "Line No." = 0 then
            Rec."Line No." := GetNextLineNo();
    end;

    procedure ClearRuleViolations(ExpenseNo: Code[20])
    begin
        Rec.SetRange("Expense No.", ExpenseNo);
        if not Rec.IsEmpty() then
            Rec.DeleteAll(true);
    end;

    procedure AddRuleViolation(ExpenseNo: Code[20]; Violation: Text[500])
    begin
        Rec."Expense No." := ExpenseNo;
        Rec."Line No." := GetNextLineNo();
        Rec.Description := Violation;
        Rec.Insert();
    end;

    local procedure GetNextLineNo(): Integer
    var
        SequenceNoMgt: codeunit "Sequence No. Mgt.";
    begin
        exit(SequenceNoMgt.GetNextSeqNo(Database::"Expense Rule Violation"))
    end;
}