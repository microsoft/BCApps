// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Foundation.NoSeries;

table 6910 "Expense Report Rule Violation"
{
    DataClassification = CustomerContent;
    ReplicateData = false;
    Access = Internal;

    fields
    {
        field(1; "Expense Report No."; Code[20])
        {
            Caption = 'Expense Report No.';
            TableRelation = "Expense Report Header"."No.";
        }
        field(2; "Report Line No."; Integer)
        {
            Caption = 'Report Line No.';
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; "Description"; Text[500])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "Expense Report No.", "Report Line No.", "Line No.")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
        if "Line No." = 0 then
            Rec."Line No." := GetNextLineNo();
    end;

    procedure ClearRuleViolations(ExpenseReportNo: Code[20]; ReportLineNo: Integer)
    begin
        Rec.SetRange("Expense Report No.", ExpenseReportNo);
        Rec.SetRange("Report Line No.", ReportLineNo);
        if not Rec.IsEmpty() then
            Rec.DeleteAll(true);
    end;

    procedure AddRuleViolation(ExpenseReportNo: Code[20]; ReportLineNo: Integer; Violation: Text[500])
    begin
        Rec."Expense Report No." := ExpenseReportNo;
        Rec."Report Line No." := ReportLineNo;
        Rec."Line No." := GetNextLineNo();
        Rec.Description := Violation;
        Rec.Insert();
    end;

    local procedure GetNextLineNo(): Integer
    var
        SequenceNoMgt: codeunit "Sequence No. Mgt.";
    begin
        exit(SequenceNoMgt.GetNextSeqNo(Database::"Expense Report Rule Violation"))
    end;
}