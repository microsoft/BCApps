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
            NotBlank = true;
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
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
}

