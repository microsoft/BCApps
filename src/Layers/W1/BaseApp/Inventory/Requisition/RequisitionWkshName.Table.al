// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Requisition;

using Microsoft.Inventory.Planning;
using System.Automation;

table 245 "Requisition Wksh. Name"
{
    Caption = 'Requisition Wksh. Name';
    DataCaptionFields = Name, Description;
    LookupPageID = "Req. Wksh. Names";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Worksheet Template Name"; Code[10])
        {
            Caption = 'Worksheet Template Name';
            NotBlank = true;
            TableRelation = "Req. Wksh. Template";
        }
        field(2; Name; Code[10])
        {
            Caption = 'Name';
            ToolTip = 'Specifies the name of the requisition worksheet you are creating.';
            NotBlank = true;
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a brief description of the requisition worksheet name you are creating.';
        }
        field(21; "Template Type"; Enum "Req. Worksheet Template Type")
        {
            CalcFormula = lookup("Req. Wksh. Template".Type where(Name = field("Worksheet Template Name")));
            Caption = 'Template Type';
            Editable = false;
            FieldClass = FlowField;
        }
        field(22; Recurring; Boolean)
        {
            CalcFormula = lookup("Req. Wksh. Template".Recurring where(Name = field("Worksheet Template Name")));
            Caption = 'Recurring';
            Editable = false;
            FieldClass = FlowField;
        }
        field(40; "No. of Lines"; Integer)
        {
            CalcFormula = count("Requisition Line" where("Worksheet Template Name" = field("Worksheet Template Name"), "Journal Batch Name" = field(Name)));
            Caption = 'No. of Lines';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the number of lines in this worksheet.';
        }
    }

    keys
    {
        key(Key1; "Worksheet Template Name", Name)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        ApprovalsMgmt.PreventDeletingRecordWithOpenApprovalEntry(Rec);

        ReqLine.SetRange("Worksheet Template Name", "Worksheet Template Name");
        ReqLine.SetRange("Journal Batch Name", Name);
        ReqLine.DeleteAll(true);

        PlanningErrorLog.SetRange("Worksheet Template Name", "Worksheet Template Name");
        PlanningErrorLog.SetRange("Journal Batch Name", Name);
        PlanningErrorLog.DeleteAll();
    end;

    trigger OnInsert()
    begin
        LockTable();
        ReqWkshTmpl.Get("Worksheet Template Name");
    end;

    trigger OnModify()
    begin
        ApprovalsMgmt.PreventModifyRecIfOpenApprovalEntryExistForCurrentUser(Rec);
    end;

    trigger OnRename()
    begin
        ApprovalsMgmt.OnRenameRecordInApprovalRequest(xRec.RecordId, RecordId);

        ReqLine.SetRange("Worksheet Template Name", xRec."Worksheet Template Name");
        ReqLine.SetRange("Journal Batch Name", xRec.Name);
        while ReqLine.FindFirst() do
            ReqLine.Rename("Worksheet Template Name", Name, ReqLine."Line No.");

        PlanningErrorLog.SetRange("Worksheet Template Name", xRec."Worksheet Template Name");
        PlanningErrorLog.SetRange("Journal Batch Name", xRec.Name);
        while PlanningErrorLog.FindFirst() do
            PlanningErrorLog.Rename("Worksheet Template Name", Name, PlanningErrorLog."Entry No.");
    end;

    var
        ReqWkshTmpl: Record "Req. Wksh. Template";
        ReqLine: Record "Requisition Line";
        PlanningErrorLog: Record "Planning Error Log";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";

    internal procedure SetApprovalStateForWkshBatch(RequisitionWkshName: Record "Requisition Wksh. Name"; RequisitionLine: Record "Requisition Line"; var OpenApprovalEntriesExistForCurrentUser: Boolean; var OpenApprovalEntriesOnWorksheetBatchExist: Boolean; var CanCancelApprovalForWorksheetBatch: Boolean; var LocalCanRequestFlowApprovalForWkshBatch: Boolean; var LocalCanCancelFlowApprovalForWkshBatch: Boolean; var LocalApprovalEntriesExistSentByCurrentUser: Boolean; var EnabledWorksheetBatchWorkflowsExist: Boolean)
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowManagement: Codeunit "Workflow Management";
    begin
        OpenApprovalEntriesExistForCurrentUser := OpenApprovalEntriesExistForCurrentUser or ApprovalsMgmt.HasOpenApprovalEntriesForCurrentUser(RequisitionWkshName.RecordId());
        OpenApprovalEntriesOnWorksheetBatchExist := ApprovalsMgmt.HasOpenApprovalEntries(RequisitionWkshName.RecordId());
        CanCancelApprovalForWorksheetBatch := ApprovalsMgmt.CanCancelApprovalForRecord(RequisitionWkshName.RecordId());
        WorkflowWebhookManagement.GetCanRequestAndCanCancel(RequisitionWkshName.RecordId(), LocalCanRequestFlowApprovalForWkshBatch, LocalCanCancelFlowApprovalForWkshBatch);
        LocalApprovalEntriesExistSentByCurrentUser := ApprovalsMgmt.HasApprovalEntriesSentByCurrentUser(RequisitionWkshName.RecordId());
        EnabledWorksheetBatchWorkflowsExist := WorkflowManagement.EnabledWorkflowExist(Database::"Requisition Wksh. Name", WorkflowEventHandling.RunWorkflowOnSendRequisitionWkshBatchForApprovalCode());
    end;
}

