// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Job;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Projects.Project.Ledger;

table 208 "Job Posting Group"
{
    Caption = 'Project Posting Group';
    DrillDownPageID = "Job Posting Groups";
    LookupPageID = "Job Posting Groups";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            ToolTip = 'Specifies a code for the posting group that defines to which G/L account you post project transactions when the project card contains the project posting group.';
            NotBlank = true;
        }
        field(2; "WIP Costs Account"; Code[20])
        {
            Caption = 'WIP Costs Account';
            ToolTip = 'Specifies the work in process (WIP) account for the calculated cost of the project WIP for project tasks with this posting group. The account is normally a balance sheet asset account.';
            TableRelation = "G/L Account";
        }
        field(3; "WIP Accrued Costs Account"; Code[20])
        {
            Caption = 'WIP Accrued Costs Account';
            ToolTip = 'Specifies an account that accumulates postings when the costs recognized, based on the invoiced value of the project, are greater than the current usage total posted If the WIP method for the project is Cost Value or Cost of Sales. The account is normally a balance sheet accrued expense liability account.';
            TableRelation = "G/L Account";
        }
        field(4; "Job Costs Applied Account"; Code[20])
        {
            Caption = 'Project Costs Applied Account';
            ToolTip = 'Specifies the balancing account for WIP Cost account for projects. The account is normally an expense (credit) account.';
            TableRelation = "G/L Account";
        }
        field(5; "Job Costs Adjustment Account"; Code[20])
        {
            Caption = 'Project Costs Adjustment Account';
            ToolTip = 'Specifies the balancing account to WIP Accrued Costs account if the work in process (WIP) method for the project is Cost Value or Cost of Sales. The account is normally an expense account.';
            TableRelation = "G/L Account";
        }
        field(6; "G/L Expense Acc. (Contract)"; Code[20])
        {
            Caption = 'G/L Expense Acc. (Contract)';
            TableRelation = "G/L Account";
        }
        field(7; "Job Sales Adjustment Account"; Code[20])
        {
            Caption = 'Project Sales Adjustment Account';
            ToolTip = 'Specifies the balancing account to the WIP Accrued Sales account if the work in process (WIP) Method for the project is the Sales Value. The account is normally an income account.';
            TableRelation = "G/L Account";
        }
        field(8; "WIP Accrued Sales Account"; Code[20])
        {
            Caption = 'WIP Accrued Sales Account';
            ToolTip = 'Specifies an account that will be posted to when the revenue that can be recognized for the project is greater than the current invoiced value for the project if the work in process (WIP) method for the project is Sales Value.';
            TableRelation = "G/L Account";
        }
        field(9; "WIP Invoiced Sales Account"; Code[20])
        {
            Caption = 'WIP Invoiced Sales Account';
            ToolTip = 'Specifies the account for the invoiced value, for the project for project tasks, with this posting group. The account is normally a Balance sheet liability account.';
            TableRelation = "G/L Account";
        }
        field(10; "Job Sales Applied Account"; Code[20])
        {
            Caption = 'Project Sales Applied Account';
            ToolTip = 'Specifies the balancing account to WIP Invoiced Sales Account. The account is normally a contra (or debit) income account.';
            TableRelation = "G/L Account";
        }
        field(11; "Recognized Costs Account"; Code[20])
        {
            Caption = 'Recognized Costs Account';
            ToolTip = 'Specifies the account for recognized costs for the project. The account is normally an expense account.';
            TableRelation = "G/L Account";
        }
        field(12; "Recognized Sales Account"; Code[20])
        {
            Caption = 'Recognized Sales Account';
            ToolTip = 'Specifies the account for recognized sales (or revenue) for the project. The account is normally an income account.';
            TableRelation = "G/L Account";
        }
        field(13; "Item Costs Applied Account"; Code[20])
        {
            Caption = 'Item Costs Applied Account';
            ToolTip = 'Specifies the balancing account for the WIP Costs account for items used in projects. The account is normally an expense (credit) account.';
            TableRelation = "G/L Account";
        }
        field(14; "Resource Costs Applied Account"; Code[20])
        {
            Caption = 'Resource Costs Applied Account';
            ToolTip = 'Specifies the balancing account for the WIP Costs account for resources used in projects. The account is normally an expense (credit) account.';
            TableRelation = "G/L Account";
        }
        field(15; "G/L Costs Applied Account"; Code[20])
        {
            Caption = 'G/L Costs Applied Account';
            ToolTip = 'Specifies the balancing account for the WIP Costs account.';
            TableRelation = "G/L Account";
        }
        field(20; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of project posting groups.';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(Brick; "Code")
        {
        }
    }

    trigger OnDelete()
    begin
        CheckGroupUsage();
    end;

    var
        PostingSetupMgt: Codeunit PostingSetupManagement;
        YouCannotDeleteErr: Label 'You cannot delete %1.', Comment = '%1 = Code';

    local procedure CheckGroupUsage()
    var
        Job: Record Job;
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        Job.SetRange("Job Posting Group", Code);
        if not Job.IsEmpty() then
            Error(YouCannotDeleteErr, Code);

        JobLedgerEntry.SetRange("Job Posting Group", Code);
        if not JobLedgerEntry.IsEmpty() then
            Error(YouCannotDeleteErr, Code);
    end;

    procedure GetWIPCostsAccount(): Code[20]
    begin
        if "WIP Costs Account" = '' then
            PostingSetupMgt.LogJobPostingGroupFieldError(Rec, FieldNo("WIP Costs Account"));

        exit("WIP Costs Account");
    end;

    procedure GetWIPAccruedCostsAccount(): Code[20]
    begin
        if "WIP Accrued Costs Account" = '' then
            PostingSetupMgt.LogJobPostingGroupFieldError(Rec, FieldNo("WIP Accrued Costs Account"));

        exit("WIP Accrued Costs Account");
    end;

    procedure GetWIPAccruedSalesAccount(): Code[20]
    begin
        if "WIP Accrued Sales Account" = '' then
            PostingSetupMgt.LogJobPostingGroupFieldError(Rec, FieldNo("WIP Accrued Sales Account"));

        exit("WIP Accrued Sales Account");
    end;

    procedure GetWIPInvoicedSalesAccount(): Code[20]
    begin
        if "WIP Invoiced Sales Account" = '' then
            PostingSetupMgt.LogJobPostingGroupFieldError(Rec, FieldNo("WIP Invoiced Sales Account"));

        exit("WIP Invoiced Sales Account");
    end;

    procedure GetJobCostsAppliedAccount(): Code[20]
    begin
        if "Job Costs Applied Account" = '' then
            PostingSetupMgt.LogJobPostingGroupFieldError(Rec, FieldNo("Job Costs Applied Account"));

        exit("Job Costs Applied Account");
    end;

    procedure GetJobCostsAdjustmentAccount(): Code[20]
    begin
        if "Job Costs Adjustment Account" = '' then
            PostingSetupMgt.LogJobPostingGroupFieldError(Rec, FieldNo("Job Costs Adjustment Account"));

        exit("Job Costs Adjustment Account");
    end;

    procedure GetGLExpenseAccountContract(): Code[20]
    begin
        if "G/L Expense Acc. (Contract)" = '' then
            PostingSetupMgt.LogJobPostingGroupFieldError(Rec, FieldNo("G/L Expense Acc. (Contract)"));

        exit("G/L Expense Acc. (Contract)");
    end;

    procedure GetJobSalesAdjustmentAccount(): Code[20]
    begin
        if "Job Sales Adjustment Account" = '' then
            PostingSetupMgt.LogJobPostingGroupFieldError(Rec, FieldNo("Job Sales Adjustment Account"));

        exit("Job Sales Adjustment Account");
    end;

    procedure GetJobSalesAppliedAccount(): Code[20]
    begin
        if "Job Sales Applied Account" = '' then
            PostingSetupMgt.LogJobPostingGroupFieldError(Rec, FieldNo("Job Sales Applied Account"));

        exit("Job Sales Applied Account");
    end;

    procedure GetRecognizedCostsAccount(): Code[20]
    begin
        if "Recognized Costs Account" = '' then
            PostingSetupMgt.LogJobPostingGroupFieldError(Rec, FieldNo("Recognized Costs Account"));

        exit("Recognized Costs Account");
    end;

    procedure GetRecognizedSalesAccount(): Code[20]
    begin
        if "Recognized Sales Account" = '' then
            PostingSetupMgt.LogJobPostingGroupFieldError(Rec, FieldNo("Recognized Sales Account"));

        exit("Recognized Sales Account");
    end;

    procedure GetItemCostsAppliedAccount(): Code[20]
    begin
        if "Item Costs Applied Account" = '' then
            PostingSetupMgt.LogJobPostingGroupFieldError(Rec, FieldNo("Item Costs Applied Account"));

        exit("Item Costs Applied Account");
    end;

    procedure GetResourceCostsAppliedAccount(): Code[20]
    begin
        if "Resource Costs Applied Account" = '' then
            PostingSetupMgt.LogJobPostingGroupFieldError(Rec, FieldNo("Resource Costs Applied Account"));

        exit("Resource Costs Applied Account");
    end;

    procedure GetGLCostsAppliedAccount(): Code[20]
    begin
        if "G/L Costs Applied Account" = '' then
            PostingSetupMgt.LogJobPostingGroupFieldError(Rec, FieldNo("G/L Costs Applied Account"));

        exit("G/L Costs Applied Account");
    end;
}

