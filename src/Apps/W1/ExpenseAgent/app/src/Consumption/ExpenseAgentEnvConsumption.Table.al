// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;
using System.Environment.Consumption;

table 6969 "Expense Agent Env. Consumption"
{
    Access = Internal;
    Caption = 'Expense Agent Environment Consumption';
    DataClassification = CustomerContent;
    InherentEntitlements = RIX;
    InherentPermissions = RIX;
    ReplicateData = false;
    DataPerCompany = false;

    fields
    {
        field(1; "Consumption Unique ID"; Text[1024])
        {
            Caption = 'User AI Consumption Data Unique ID';
            TableRelation = "User AI Consumption Data"."Unique Id";
            ValidateTableRelation = false;
            NotBlank = true;
            DataClassification = CustomerContent;
        }
        field(3; "Expense User No."; Code[20])
        {
            Caption = 'Expense User No.';
            TableRelation = "Expense User"."No.";
            DataClassification = EndUserPseudonymousIdentifiers;
        }
        field(4; "Consumption Source Type"; Enum "Expense Agent Cons. Source")
        {
            Caption = 'Consumption Source Type';
            DataClassification = SystemMetadata;
        }
        field(5; "Consumption Source System ID"; Guid)
        {
            Caption = 'Consumption Source System ID';
            DataClassification = SystemMetadata;
            TableRelation =
            if ("Consumption Source Type" = const(Expense)) "Expense".SystemID else
            if ("Consumption Source Type" = const("Expense Report")) "Expense Report Header".SystemID;
            ValidateTableRelation = false; // Source could belong to a different company than the current one
        }
        field(6; "Consumption Source Operation"; Code[50])
        {
            Caption = 'Consumption Source Operation';
            DataClassification = SystemMetadata;
        }
        field(101; "Consumption DateTime"; DateTime)
        {
            FieldClass = FlowField;
            CalcFormula = lookup("User AI Consumption Data"."Consumption DateTime" where("Unique Id" = field("Consumption Unique ID")));
            Caption = 'Consumption DateTime';
        }
        field(102; "User Id"; Guid)
        {
            FieldClass = FlowField;
            CalcFormula = lookup("User AI Consumption Data"."User Id" where("Unique Id" = field("Consumption Unique ID")));
            Caption = 'User Id';
        }
        field(106; "App Version"; Text[50])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("User AI Consumption Data"."App Version" where("Unique Id" = field("Consumption Unique ID")));
            Caption = 'App Version';
        }
        field(108; "Feature Name"; Text[256])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("User AI Consumption Data"."Feature Name" where("Unique Id" = field("Consumption Unique ID")));
            Caption = 'Feature Name';
        }
        field(109; "Actions"; Text[1024])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("User AI Consumption Data"."Actions" where("Unique Id" = field("Consumption Unique ID")));
            Caption = 'Actions';
        }
        field(110; "Copilot Studio Feature"; Text[1024])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("User AI Consumption Data"."Copilot Studio Feature" where("Unique Id" = field("Consumption Unique ID")));
            Caption = 'Copilot Studio Feature';
        }
        field(111; "Copilot Credits"; Decimal)
        {
            FieldClass = FlowField;
            AutoFormatType = 0;
            CalcFormula = lookup("User AI Consumption Data"."Copilot Credits" where("Unique Id" = field("Consumption Unique ID")));
            Caption = 'Copilot Credits';
        }
        field(113; "Company Name"; Text[30])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("User AI Consumption Data"."Company Name" where("Unique Id" = field("Consumption Unique ID")));
            Caption = 'Company Name';
        }
        field(115; "Processed For Billing"; Boolean)
        {
            FieldClass = FlowField;
            CalcFormula = lookup("User AI Consumption Data"."Processed For Billing" where("Unique Id" = field("Consumption Unique ID")));
            Caption = 'Processed For Billing';
        }
        field(116; "CS Feature Quantity"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = lookup("User AI Consumption Data"."Copilot Studio Feature Quantity" where("Unique Id" = field("Consumption Unique ID")));
            Caption = 'Copilot Studio Feature Quantity';
        }
        field(117; "CS Feature Display Name"; Text[1024])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("User AI Consumption Data"."Copilot Studio Feature Display Name" where("Unique Id" = field("Consumption Unique ID")));
            Caption = 'Copilot Studio Feature Display Name';
        }

    }
    keys
    {
        key(PK; "Consumption Unique ID")
        {
            Clustered = true;
        }
        key(ExpenseUser; "Expense User No.")
        {
        }
        key(Source; "Consumption Source Type", "Consumption Source System ID")
        {
        }
    }

    var
        DifferentCompanyRecordTxt: Label 'Record belongs to company %1', Comment = '%1: a company name, such as "CRONUS W1"';
        DeletedRecordTxt: Label 'Deleted %1', Comment = '%1: a record caption, such as "Expense Report"';
        RecordIdStringPatternTxt: Label '%1 %2', Comment = '%1: a record caption, such as "Expense Report"; %2: a record number, such as "ER123"';

    procedure GetTaskDisplayName(var TaskShortName: Text[30]; var TaskLongName: Text)
    var
        DestinationCompany: Text[30];
    begin
        Rec.CalcFields("Company Name");
        if Rec."Company Name" <> CompanyName() then
            DestinationCompany := Rec."Company Name";

        case Rec."Consumption Source Type" of
            Rec."Consumption Source Type"::Expense:
                TaskLongName := GetTaskDisplayNameForExpense(DestinationCompany, Rec."Consumption Source System ID");
            Rec."Consumption Source Type"::"Expense Report":
                TaskLongName := GetTaskDisplayNameForExpenseReport(DestinationCompany, Rec."Consumption Source System ID");
        end;

        TaskShortName := CopyStr(TaskLongName, 1, 30);
    end;

    local procedure GetTaskDisplayNameForExpense(DestinationCompany: Text[30]; SourceSystemId: Guid): Text
    var
        Expense: Record Expense;
    begin
        if DestinationCompany <> '' then
            if not Expense.ChangeCompany(DestinationCompany) or not Expense.ReadPermission() then
                exit(StrSubstNo(DifferentCompanyRecordTxt, DestinationCompany));

        Expense.SetLoadFields("No.");
        if Expense.GetBySystemId(SourceSystemId) then
            exit(StrSubstNo(RecordIdStringPatternTxt, Expense.TableCaption(), Expense."No."));
        exit(StrSubstNo(DeletedRecordTxt, Expense.TableCaption()));
    end;

    local procedure GetTaskDisplayNameForExpenseReport(DestinationCompany: Text[30]; SourceSystemId: Guid): Text
    var
        ExpenseReport: Record "Expense Report Header";
    begin
        if DestinationCompany <> '' then
            if not ExpenseReport.ChangeCompany(DestinationCompany) or not ExpenseReport.ReadPermission() then
                exit(StrSubstNo(DifferentCompanyRecordTxt, DestinationCompany));

        ExpenseReport.SetLoadFields("No.");
        if ExpenseReport.GetBySystemId(SourceSystemId) then
            exit(StrSubstNo(RecordIdStringPatternTxt, ExpenseReport.TableCaption(), ExpenseReport."No."));
        exit(StrSubstNo(DeletedRecordTxt, ExpenseReport.TableCaption()));
    end;

}
