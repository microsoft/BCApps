// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.HumanResources.Employee;
using Microsoft.Projects.Project.Job;
using System.Security.AccessControl;

table 6912 "Expense Ledger Entry"
{
    Caption = 'Expense Ledger Entry';
    Access = Internal;
    ReplicateData = false;
    DrillDownPageID = "Expense Ledger Entries";
    LookupPageID = "Expense Ledger Entries";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Expense User No."; Code[20])
        {
            Caption = 'Expense User No.';
            TableRelation = "Expense User"."No.";
            Editable = false;
        }
        field(3; "Employee No."; Code[20])
        {
            Caption = 'Employee No.';
            TableRelation = Employee;
        }
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(5; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
        }
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(7; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(11; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(13; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
        }
        field(15; "Original Amt. (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Original Amt. (LCY)';
            Editable = false;
        }
        field(17; "Amount (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Amount (LCY)';
            Editable = false;
        }
        field(18; "Expense Category"; Code[20])
        {
            Caption = 'Expense Category';
            TableRelation = "Expense Category".Code;
        }
        field(19; "Expense Subcategory Code"; Code[20])
        {
            Caption = 'Expense Subcategory Code';
            TableRelation = "Expense SubCategory".Code where("Expense Category Code" = field("Expense Category"));
        }
        field(22; "Employee Posting Group"; Code[20])
        {
            Caption = 'Employee Posting Group';
            TableRelation = "Employee Posting Group";
        }
        field(23; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(24; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(27; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(28; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            TableRelation = "Source Code";
        }
        field(37; "Non-Refundable Amount"; Decimal)
        {
            Caption = 'Non-Refundable Amount';
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Editable = false;
        }
        field(38; "Non-Refundable Amount (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Non-Refundable Amount (LCY)';
            Editable = false;
        }
        field(39; "Reimbursable Amount"; Decimal)
        {
            Caption = 'Reimbursable Amount';
            AutoFormatExpression = GetReimbursementCurrencyCode();
            AutoFormatType = 1;
            Editable = false;
        }
        field(40; "Reimbursable Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Reimbursable Amount (LCY)';
            Editable = false;
        }
        field(41; "Refundable Amount"; Decimal)
        {
            Caption = 'Refundable Amount';
            AutoFormatExpression = GetReimbursementCurrencyCode();
            AutoFormatType = 1;
            Editable = false;
        }
        field(42; "Refundable Amount (LCY)"; Decimal)
        {
            Caption = 'Refundable Amount (LCY)';
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Editable = false;
        }
        field(48; "Journal Templ. Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            DataClassification = SystemMetadata;
        }
        field(49; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
        }
        field(50; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(53; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
        }
        field(64; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(75; "Original Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Original Amount';
            Editable = false;
        }
        field(80; "Document Line No."; Integer)
        {
            Caption = 'Document Line No.';
        }
        field(87; Reversed; Boolean)
        {
            Caption = 'Reversed';
        }
        field(88; "Reversed by Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Reversed by Entry No.';
            TableRelation = "Expense Ledger Entry";
        }
        field(89; "Reversed Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Reversed Entry No.';
            TableRelation = "Expense Ledger Entry";
        }
        field(90; "Job No."; Code[20])
        {
            Caption = 'Project No.';
            TableRelation = Job."No.";
        }
        field(91; "Job Task No."; Code[20])
        {
            Caption = 'Project Task No.';
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));
        }
        field(172; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
            TableRelation = "Expense Payment Method";
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                Rec.ShowDimensions();
            end;
        }
        field(481; "Shortcut Dimension 3 Code"; Code[20])
        {
            CaptionClass = '1,2,3';
            Caption = 'Shortcut Dimension 3 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(3)));
        }
        field(482; "Shortcut Dimension 4 Code"; Code[20])
        {
            CaptionClass = '1,2,4';
            Caption = 'Shortcut Dimension 4 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(4)));
        }
        field(483; "Shortcut Dimension 5 Code"; Code[20])
        {
            CaptionClass = '1,2,5';
            Caption = 'Shortcut Dimension 5 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(5)));
        }
        field(484; "Shortcut Dimension 6 Code"; Code[20])
        {
            CaptionClass = '1,2,6';
            Caption = 'Shortcut Dimension 6 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(6)));
        }
        field(485; "Shortcut Dimension 7 Code"; Code[20])
        {
            CaptionClass = '1,2,7';
            Caption = 'Shortcut Dimension 7 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(7)));
        }
        field(486; "Shortcut Dimension 8 Code"; Code[20])
        {
            CaptionClass = '1,2,8';
            Caption = 'Shortcut Dimension 8 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(8)));
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        PostedExpenseReportHeader: Record "Posted Expense Report Header";

    procedure CopyFromGenJnlLine(GenJnlLine: Record "Gen. Journal Line")
    begin
        "Posting Date" := GenJnlLine."Posting Date";
        "Document Type" := GenJnlLine."Document Type";
        "Document No." := GenJnlLine."Document No.";
        Description := GenJnlLine.Description;
        "Employee Posting Group" := GenJnlLine."Posting Group";
        "Global Dimension 1 Code" := GenJnlLine."Shortcut Dimension 1 Code";
        "Global Dimension 2 Code" := GenJnlLine."Shortcut Dimension 2 Code";
        "Dimension Set ID" := GenJnlLine."Dimension Set ID";
        "Source Code" := GenJnlLine."Source Code";
        "Reason Code" := GenJnlLine."Reason Code";
        "Journal Templ. Name" := GenJnlLine."Journal Template Name";
        "Journal Batch Name" := GenJnlLine."Journal Batch Name";
        "User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
        "No. Series" := GenJnlLine."Posting No. Series";
        Amount := GenJnlLine.Amount;
        "Amount (LCY)" := GenJnlLine."Amount (LCY)";
        "Expense User No." := GenJnlLine."Expense User No.";
        "Expense Category" := GenJnlLine."Expense Category";
        "Expense Subcategory Code" := GenJnlLine."Expense Subcategory Code";
    end;

    procedure CopyFromPostedExpenseReportLine(PostedExpenseReportLine: Record "Posted Expense Report Line")
    begin
        "Document No." := PostedExpenseReportLine."Document No.";
        Description := PostedExpenseReportLine.Description;
        "Currency Code" := PostedExpenseReportLine."Expense Currency Code";
        "Global Dimension 1 Code" := PostedExpenseReportLine."Shortcut Dimension 1 Code";
        "Global Dimension 2 Code" := PostedExpenseReportLine."Shortcut Dimension 2 Code";
        "Dimension Set ID" := PostedExpenseReportLine."Dimension Set ID";
        "User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
        Amount := PostedExpenseReportLine.Amount;
        "Original Amount" := PostedExpenseReportLine.Amount;
        "Amount (LCY)" := PostedExpenseReportLine."Amount (LCY)";
        "Original Amt. (LCY)" := PostedExpenseReportLine."Amount (LCY)";
        "Non-Refundable Amount" := PostedExpenseReportLine."Non-Refundable Amount";
        "Non-Refundable Amount (LCY)" := PostedExpenseReportLine."Non-Refundable Amount (LCY)";
        "Reimbursable Amount" := PostedExpenseReportLine."Reimbursable Amount";
        "Reimbursable Amount (LCY)" := PostedExpenseReportLine."Reimbursable Amount (LCY)";
        "Expense User No." := PostedExpenseReportLine."Expense User No.";
        "Expense Category" := PostedExpenseReportLine."Expense Category";
        "Expense Subcategory Code" := PostedExpenseReportLine."Expense Subcategory Code";
        "Document Line No." := PostedExpenseReportLine."Line No.";
        "Payment Method Code" := PostedExpenseReportLine."Payment Method Code";
        "Job No." := PostedExpenseReportLine."Job No.";
        "Job Task No." := PostedExpenseReportLine."Job Task No.";
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"Expense Ledger Entry", 'r')]
    procedure GetNextEntryNo(): Integer
    var
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
    begin
        exit(SequenceNoMgt.GetNextSeqNo(DATABASE::"Expense Ledger Entry"));
    end;

    local procedure GetReimbursementCurrencyCode(): Code[10]
    begin
        if PostedExpenseReportHeader.Get("Document No.") then
            exit(PostedExpenseReportHeader."Reimbursement Currency Code");
    end;

    procedure ShowDimensions()
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", CopyStr(StrSubstNo('%1 %2', TableCaption(), "Entry No."), 1, 250));
    end;
}