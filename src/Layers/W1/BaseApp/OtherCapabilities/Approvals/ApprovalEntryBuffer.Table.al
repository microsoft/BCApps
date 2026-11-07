// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Automation;

using Microsoft.CRM.Team;
using Microsoft.Finance.Currency;
using Microsoft.Utilities;
using System.Reflection;
using System.Security.AccessControl;

table 1572 "Approval Entry Buffer"
{
    Caption = 'Approval Entry Buffer';
    ReplicateData = false;
    TableType = Temporary;
    DataClassification = CustomerContent;
    InherentEntitlements = RIMDX;
    InherentPermissions = RIMDX;

    fields
    {
        field(1; "Table ID"; Integer)
        {
            Caption = 'Table ID';
        }
        field(2; "Document Type"; Enum "Approval Document Type")
        {
            Caption = 'Document Type';
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(4; "Sequence No."; Integer)
        {
            Caption = 'Sequence No.';
        }
        field(5; "Approval Code"; Code[20])
        {
            Caption = 'Approval Code';
        }
        field(6; "Sender ID"; Code[50])
        {
            Caption = 'Sender ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(7; "Salespers./Purch. Code"; Code[20])
        {
            Caption = 'Salespers./Purch. Code';
        }
        field(8; "Approver ID"; Code[50])
        {
            Caption = 'Approver ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(9; Status; Enum "Approval Status")
        {
            Caption = 'Status';
        }
        field(10; "Date-Time Sent for Approval"; DateTime)
        {
            Caption = 'Date-Time Sent for Approval';
        }
        field(11; "Last Date-Time Modified"; DateTime)
        {
            Caption = 'Last Date-Time Modified';
        }
        field(12; "Last Modified By ID"; Code[50])
        {
            Caption = 'Last Modified By ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(13; Comment; Boolean)
        {
            Caption = 'Comment';
            Editable = false;
        }
        field(14; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        field(15; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
        }
        field(16; "Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Amount (LCY)';
        }
        field(17; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(18; "Approval Type"; Enum "Workflow Approval Type")
        {
            Caption = 'Approval Type';
        }
        field(19; "Limit Type"; Enum "Workflow Approval Limit Type")
        {
            Caption = 'Limit Type';
        }
        field(20; "Available Credit Limit (LCY)"; Decimal)
        {
            Caption = 'Available Credit Limit (LCY)';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(21; "Pending Approvals"; Integer)
        {
            CalcFormula = count("Approval Entry" where("Record ID to Approve" = field("Record ID"),
                                                        Status = filter(Created | Open),
                                                        "Workflow Step Instance ID" = field("Workflow Step Instance ID")));
            Caption = 'Pending Approvals';
            FieldClass = FlowField;
        }
        field(22; "Record ID"; RecordID)
        {
            Caption = 'Record ID';
            DataClassification = CustomerContent;
        }
        field(23; "Delegation Date Formula"; DateFormula)
        {
            Caption = 'Delegation Date Formula';
        }
        field(26; "Number of Approved Requests"; Integer)
        {
            CalcFormula = count("Approval Entry" where("Record ID to Approve" = field("Record ID"),
                                                        Status = filter(Approved),
                                                        "Workflow Step Instance ID" = field("Workflow Step Instance ID")));
            Caption = 'Number of Approved Requests';
            FieldClass = FlowField;
        }
        field(27; "Number of Rejected Requests"; Integer)
        {
            CalcFormula = count("Approval Entry" where("Record ID to Approve" = field("Record ID"),
                                                        Status = filter(Rejected),
                                                        "Workflow Step Instance ID" = field("Workflow Step Instance ID")));
            Caption = 'Number of Rejected Requests';
            FieldClass = FlowField;
        }
        field(28; "Iteration No."; Integer)
        {
            Caption = 'Iteration No.';
        }
        field(29; "Entry No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'Entry No.';
        }
        field(30; "Workflow Step Instance ID"; Guid)
        {
            Caption = 'Workflow Step Instance ID';
        }
        field(31; "Related to Change"; Boolean)
        {
            CalcFormula = exist("Workflow - Record Change" where("Workflow Step Instance ID" = field("Workflow Step Instance ID"),
                                                                  "Record ID" = field("Record ID")));
            Caption = 'Related to Change';
            FieldClass = FlowField;
        }
        field(32; "Approver Full Name"; Text[80])
        {
            Caption = 'Approver Full Name';
            CalcFormula = lookup(User."Full Name" where("User Name" = field("Approver ID")));
            FieldClass = FlowField;
            Editable = false;
        }
        field(33; "Sender Full Name"; Text[80])
        {
            Caption = 'Sender Full Name';
            CalcFormula = lookup(User."Full Name" where("User Name" = field("Sender ID")));
            FieldClass = FlowField;
            Editable = false;
        }
        field(34; "Salespers./Purch. Name"; Text[80])
        {
            Caption = 'Salespers./Purch. Full Name';
            CalcFormula = lookup("Salesperson/Purchaser".Name where("Code" = field("Salespers./Purch. Code")));
            FieldClass = FlowField;
            Editable = false;
        }
        field(35; Posted; Boolean)
        {
            Caption = 'Posted';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Entry No.", Posted)
        {
            Clustered = true;
        }
        key(Key2; "Last Date-Time Modified")
        {
        }
    }

    fieldgroups
    {
    }

    procedure ShowRecord()
    var
        PageManagement: Codeunit "Page Management";
        RecRef: RecordRef;
    begin
        if not RecRef.Get("Record ID") then
            exit;
        RecRef.SetRecFilter();
        PageManagement.PageRun(RecRef);
    end;

    procedure ShowComments()
    var
        PostedApprovalCommentLine: Record "Posted Approval Comment Line";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        RecRef: RecordRef;
    begin
        if Rec.Posted then begin
            PostedApprovalCommentLine.FilterGroup(2);
            PostedApprovalCommentLine.SetRange("Posted Record ID", Rec."Record ID");
            PostedApprovalCommentLine.FilterGroup(0);
            Page.Run(Page::"Posted Approval Comments", PostedApprovalCommentLine);
        end else begin
            RecRef.Get(Rec."Record ID");
            ApprovalsMgmt.GetApprovalCommentForWorkflowStepInstanceID(RecRef, Rec."Workflow Step Instance ID");
        end;
    end;

    procedure CopyFiltersAndFillBuffer()
    var
        ApprovalEntry: Record "Approval Entry";
        PostedApprovalEntry: Record "Posted Approval Entry";
        BufferFields: Record Field;
        ApprovalEntryBufferRecRef: RecordRef;
        ApprovalEntryRecRef: RecordRef;
        PostedApprovalEntryRecRef: RecordRef;
        ApprovalEntryBufferFieldRef: FieldRef;
        ApprovalEntryFieldRef: FieldRef;
        PostedApprovalEntryFieldRef: FieldRef;
        PostedFilterText: Text;
    begin
        //Improve API performance by copying filters from Approval Entry Buffer to Approval Entry and Posted Approval Entry
        ApprovalEntryBufferRecRef.GetTable(Rec);
        ApprovalEntryRecRef.GetTable(ApprovalEntry);
        PostedApprovalEntryRecRef.GetTable(PostedApprovalEntry);

        BufferFields.SetRange(TableNo, Database::"Approval Entry Buffer");
        if BufferFields.FindSet() then
            repeat
                ApprovalEntryBufferFieldRef := ApprovalEntryBufferRecRef.Field(BufferFields."No.");
                if ApprovalEntryRecRef.FieldExist(BufferFields."No.") then begin
                    ApprovalEntryFieldRef := ApprovalEntryRecRef.Field(BufferFields."No.");
                    ApprovalEntryFieldRef.SetFilter(ApprovalEntryBufferFieldRef.GetFilter());
                end;
                if PostedApprovalEntryRecRef.FieldExist(BufferFields."No.") then begin
                    PostedApprovalEntryFieldRef := PostedApprovalEntryRecRef.Field(BufferFields."No.");
                    PostedApprovalEntryFieldRef.SetFilter(ApprovalEntryBufferFieldRef.GetFilter());
                end;
            until BufferFields.Next() = 0;

        ApprovalEntryRecRef.SetTable(ApprovalEntry);
        PostedApprovalEntryRecRef.SetTable(PostedApprovalEntry);

        FillBuffer(ApprovalEntry);

        PostedFilterText := ApprovalEntryBufferRecRef.Field(Rec.FieldNo(Posted)).GetFilter();
        if (PostedFilterText = '') or (PostedFilterText = 'Yes') then
            FillBuffer(PostedApprovalEntry);
    end;

    procedure FillBuffer(var ApprovalEntry: Record "Approval Entry")
    begin
        ApprovalEntry.SetAutoCalcFields(Comment);
        if ApprovalEntry.FindSet() then
            repeat
                Rec.Init();
                Rec.TransferFields(ApprovalEntry);
                Rec.Comment := ApprovalEntry.Comment;
                Rec.Posted := false;
                Rec.Insert();
            until ApprovalEntry.Next() = 0;
    end;

    procedure FillBuffer(var PostedApprovalEntry: Record "Posted Approval Entry")
    begin
        PostedApprovalEntry.SetAutoCalcFields(Comment);
        if PostedApprovalEntry.FindSet() then
            repeat
                Rec.Init();
                Rec.TransferFields(PostedApprovalEntry);
                Rec."Document Type" := Rec."Document Type"::" ";
                Rec.Comment := PostedApprovalEntry.Comment;
                Rec.Posted := true;
                Rec.Insert();
            until PostedApprovalEntry.Next() = 0;
    end;
}