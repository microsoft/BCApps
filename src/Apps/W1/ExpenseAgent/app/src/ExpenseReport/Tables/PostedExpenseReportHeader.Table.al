// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.SpendRequest;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.HumanResources.Employee;
using Microsoft.Inventory.Location;
using System.Globalization;
using System.Security.AccessControl;

table 6915 "Posted Expense Report Header"
{
    Access = Internal;
    Caption = 'Posted Expense Report Header';
    DataCaptionFields = "No.", Description;
    DataClassification = CustomerContent;
    LookupPageId = "Posted Expense Reports";
    ReplicateData = false;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(2; "Expense User No."; Code[20])
        {
            Caption = 'Expense User No.';
            TableRelation = "Expense User"."No.";
        }
        field(3; "Expense User Name"; Text[100])
        {
            Caption = 'Expense User Name';
        }
        field(4; "Expense Report Date"; Date)
        {
            Caption = 'Expense Report Date';
        }
        field(5; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(6; "Description"; Text[100])
        {
            Caption = 'Description';
        }
#pragma warning disable AA0232
        field(10; "Amount (LCY)"; Decimal)
#pragma warning restore AA0232
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Amount (LCY)';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = sum("Posted Expense Report Line"."Amount (LCY)" where("Document No." = field("No.")));
        }
        field(12; "Non-Refundable Amount (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Non-Refundable Amount (LCY)';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = sum("Posted Expense Report Line"."Non-Refundable Amount (LCY)" where("Document No." = field("No.")));
        }
        field(13; "Reimbursable Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Reimbursement Currency Code";
            AutoFormatType = 1;
            Caption = 'Reimbursable Amount';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = sum("Posted Expense Report Line"."Reimbursable Amount" where("Document No." = field("No.")));
        }
        field(14; "Reimbursable Amount (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Reimbursable Amount (LCY)';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = sum("Posted Expense Report Line"."Reimbursable Amount (LCY)" where("Document No." = field("No.")));
        }
        field(15; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1),
                                                          Blocked = const(false));
        }
        field(16; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2),
                                                          Blocked = const(false));
        }
        field(17; "Employee Posting Group"; Code[20])
        {
            Caption = 'Employee Posting Group';
            TableRelation = "Employee Posting Group".Code;
        }
        field(18; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language.Code;
            DataClassification = SystemMetadata;
        }
        field(19; Comment; Boolean)
        {
            Caption = 'Comment';
        }
        field(20; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code".Code;
        }
        field(21; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            DataClassification = SystemMetadata;
        }
        field(22; "Posting No. Series"; Code[20])
        {
            Caption = 'Posting No. Series';
            DataClassification = SystemMetadata;
        }
        field(23; Status; Enum "Expense Report Status")
        {
            Caption = 'Status';
            Editable = false;
            DataClassification = SystemMetadata;
        }
        field(24; "Anti-Corruption Attestation"; Boolean)
        {
            Caption = 'Anti-Corruption Attestation';
        }
        field(25; "Anti-Corruption Description"; Text[100])
        {
            Caption = 'Anti-Corruption Description';
        }
        field(26; Corrected; Boolean)
        {
            Caption = 'Corrected';
        }
        field(27; "Responsibility Center"; Code[20])
        {
            Caption = 'Responsibility Center';
            TableRelation = "Responsibility Center".Code;
        }
        field(28; "Reimbursement Currency Code"; Code[10])
        {
            Caption = 'Reimbursement Currency Code';
            TableRelation = Currency.Code;
        }
        field(29; "Corrected Document No."; Code[20])
        {
            Caption = 'Corrected Document No.';
            Editable = false;
        }
        field(30; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";
        }
        field(31; "VAT Amount (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'VAT Amount (LCY)';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = sum("Posted Expense Report Line"."VAT Amount (LCY)" where("Document No." = field("No.")));
        }
        field(32; "Amount without VAT (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Amount without VAT (LCY)';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = sum("Posted Expense Report Line"."Amount without VAT (LCY)" where("Document No." = field("No.")));
        }
        field(33; "Refundable Amount (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Refundable Amount (LCY)';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = sum("Posted Expense Report Line"."Refundable Amount (LCY)" where("Document No." = field("No.")));
        }
        field(34; "Refundable Amount"; Decimal)
        {
            AutoFormatExpression = "Reimbursement Currency Code";
            AutoFormatType = 1;
            Caption = 'Refundable Amount';
            ToolTip = 'Specifies the value of the Refundable Amount field.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = sum("Posted Expense Report Line"."Refundable Amount" where("Document No." = field("No.")));
        }
        field(40; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
        }
        field(42; "Submission DateTime"; DateTime)
        {
            Caption = 'Submission Date and Time';
        }
        field(43; "Approved/Rejected DateTime"; DateTime)
        {
            Caption = 'Approved/Rejected Date and Time';
        }
        field(44; "Approved/Rejected By"; Code[50])
        {
            Caption = 'Approved/Rejected By';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            Editable = false;
        }
        field(45; "Approver Expense User No."; Code[20])
        {
            Caption = 'Approver Expense User No.';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = "Expense User"."No.";
        }
        field(46; "Approver Expense User ID"; Code[50])
        {
            Caption = 'Approver Expense User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
        }
        field(47; "Created By"; Code[50])
        {
            Caption = 'Created By';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(50; "Reimbursement Currency Factor"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Reimbursement Currency Factor';
            DecimalPlaces = 0 : 15;
            Editable = false;
            MinValue = 0;
        }
        field(58; "Created By Exp. User Id"; Guid)
        {
            Caption = 'Created By Expense User Id';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(59; "Modified By Exp. User Id"; Guid)
        {
            Caption = 'Modified By Expense User Id';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(92; Canceled; Boolean)
        {
            Caption = 'Canceled';
            ToolTip = 'Specifies whether this posted expense report has been canceled. When canceled, the related ledger entries have been reversed.';
            Editable = false;
        }
        field(93; "Approved Reclaim VAT (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Approved Reclaim VAT (LCY)';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = sum("Posted Exp. Rep. Line VAT Spec"."Reclaim VAT Amount (LCY)" where("Expense Report No." = field("No."), "Reclaim Status" = const(Approved)));
            ToolTip = 'Specifies the total VAT amount approved for reclaim across all VAT specification lines of this posted expense report, in local currency.';
        }
        field(100; "Spend Request No."; Code[20])
        {
            Caption = 'Travel Request No.';
            ToolTip = 'Specifies the travel request to which the posted expense report is linked.';
            TableRelation = "Spend Request";
        }
        field(101; "Spend Request Close"; Boolean)
        {
            Caption = 'Travel Request Close';
            ToolTip = 'Specifies that the travel request will be closed when the expense report is posted.';
        }
    }

    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
        key(ExpenseUser; "Expense User No.", "No.")
        {
        }
    }

    trigger OnInsert()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        NoSeriesMgmt: Codeunit "No. Series - Batch";
    begin
        if "No." = '' then begin
            ExpenseAgentSetup.Get();
            ExpenseAgentSetup.TestField("Posted Expense Reports Nos.");

            if Rec."No." = '' then
                Rec."No." := NoSeriesMgmt.GetNextNo(ExpenseAgentSetup."Posted Expense Reports Nos.", WorkDate(), true);
        end;
    end;

    trigger OnDelete()
    var
        PostedExpenseReportLines: Record "Posted Expense Report Line";
        ExpenseActivityLogMgt: Codeunit "Expense Activity Log Mgt.";
    begin
        ExpenseActivityLogMgt.DeleteEntriesForSource(Database::"Posted Expense Report Header", Rec.SystemId);
        PostedExpenseReportLines.SetRange("Document No.", Rec."No.");
        PostedExpenseReportLines.DeleteAll();
    end;

    var
        EntryRecIDLbl: Label '%1 %2', Locked = true;

    procedure ShowDimensions()
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimMgt.ShowDimensionSet(Rec."Dimension Set ID", StrSubstNo(EntryRecIDLbl, Rec.TableCaption(), Rec."No."));
    end;

    procedure ShowEmployeeCard()
    var
        Employee: Record Employee;
        ExpenseUser: Record "Expense User";
    begin
        ExpenseUser.Get(Rec."Expense User No.");
        Employee.Get(ExpenseUser."Employee No.");

        Page.Run(Page::"Employee Card", Employee);
    end;
}