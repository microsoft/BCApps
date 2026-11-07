// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Automation;

using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using System.Security.AccessControl;

table 1573 "Workflow Approvers Buffer"
{
    Caption = 'Workflow Approvers Buffer';
    DataClassification = CustomerContent;
    TableType = Temporary;
    InherentEntitlements = RIMDX;
    InherentPermissions = RIMDX;

    fields
    {
        field(1; WorkflowCode; Code[20])
        {
            Caption = 'Workflow Code';
            AllowInCustomizations = AsReadOnly;
        }
        field(2; WorkflowStepId; Integer)
        {
            Caption = 'Workflow Step Id';
            AllowInCustomizations = AsReadOnly;
        }
        field(3; WorkflowType; Enum "Approval Workflow Type")
        {
            Caption = 'Workflow Type';
            AllowInCustomizations = AsReadOnly;
        }
        field(4; ArgumentId; Guid)
        {
            Caption = 'Argument Id';
            AllowInCustomizations = AsReadOnly;
        }
        field(5; UserName; Code[50])
        {
            Caption = 'User Name';
            AllowInCustomizations = AsReadOnly;
        }
        field(6; Sequence; Integer)
        {
            Caption = 'Sequence';
            AllowInCustomizations = AsReadOnly;
        }
        field(7; ApproverType; enum "Workflow Approver Type")
        {
            Caption = 'Approver Type';
            AllowInCustomizations = AsReadOnly;
        }
        field(8; ApproverLimitType; enum "Workflow Approver Limit Type")
        {
            Caption = 'Approver Limit Type';
            AllowInCustomizations = AsReadOnly;
        }
        field(9; WorkflowDescription; Text[100])
        {
            Caption = 'Workflow Description';
            AllowInCustomizations = AsReadOnly;
        }
        field(10; Category; Code[20])
        {
            Caption = 'Category';
            AllowInCustomizations = AsReadOnly;
        }
        field(11; Enabled; Boolean)
        {
            Caption = 'Enabled';
            AllowInCustomizations = AsReadOnly;
        }
        field(12; UserGroupCode; Code[20])
        {
            Caption = 'User Group Code';
            AllowInCustomizations = AsReadOnly;
        }
        field(13; UserGroupDescription; Text[100])
        {
            Caption = 'User Group Description';
            CalcFormula = lookup("Workflow User Group".Description where(Code = field(UserGroupCode)));
            FieldClass = FlowField;
        }
        field(14; UserId; Guid)
        {
            Caption = 'User Id';
        }
        field(15; UserFullName; Text[100])
        {
            Caption = 'User Full Name';
            CalcFormula = lookup(User."Full Name" where("User Security ID" = field(UserId)));
            FieldClass = FlowField;
        }

    }

    keys
    {
        key(Key1; WorkflowCode, WorkflowStepId, ArgumentId, UserName, Sequence)
        {
            Clustered = true;
        }
    }

    procedure FillBuffer()
    var
        Workflow: Record Workflow;
        WorkflowStepArgument: Record "Workflow Step Argument";
        WorkflowStep: Record "Workflow Step";
        WorkflowUserGroupMember: Record "Workflow User Group Member";
    begin
        WorkflowStepArgument.SetRange(Type, WorkflowStepArgument.Type::Response);
        WorkflowStepArgument.SetRange("Response Option Group", 'GROUP 5');
        if WorkflowStepArgument.FindSet() then
            repeat
                WorkflowStep.SetLoadFields(ID, "Workflow Code");
                WorkflowStep.SetRange(Argument, WorkflowStepArgument.ID);
                if WorkflowStep.FindFirst() then
                    if Workflow.Get(WorkflowStep."Workflow Code") and (not Workflow.Template) then begin
                        Rec.Init();
                        Rec.WorkflowCode := Workflow.Code;
                        Rec.WorkflowDescription := Workflow.Description;
                        Rec.WorkflowStepId := WorkflowStep.ID;
                        Rec.ArgumentId := WorkflowStepArgument.ID;
                        Rec.ApproverType := WorkflowStepArgument."Approver Type";
                        Rec.ApproverLimitType := WorkflowStepArgument."Approver Limit Type";
                        Rec.Category := Workflow.Category;
                        Rec.Enabled := Workflow.Enabled;
                        Rec.WorkflowType := GetWorkflowType(Workflow.Code);

                        if WorkflowStepArgument."Approver Type" = WorkflowStepArgument."Approver Type"::"Workflow User Group" then begin
                            WorkflowUserGroupMember.SetRange("Workflow User Group Code", WorkflowStepArgument."Workflow User Group Code");
                            if WorkflowUserGroupMember.FindSet() then
                                repeat
                                    Rec.UserName := WorkflowUserGroupMember."User Name";
                                    Rec.Sequence := WorkflowUserGroupMember."Sequence No.";
                                    Rec.UserGroupCode := WorkflowUserGroupMember."Workflow User Group Code";
                                    Rec.UserId := GetUserId(Rec.UserName);
                                    Rec.Insert();

                                until WorkflowUserGroupMember.Next() = 0;
                        end else begin
                            if WorkflowStepArgument."Approver Limit Type" = WorkflowStepArgument."Approver Limit Type"::"Specific Approver" then begin
                                Rec.UserName := WorkflowStepArgument."Approver User ID";
                                Rec.UserId := GetUserId(Rec.UserName);
                            end;

                            Rec.Insert();
                        end;

                        Clear(Rec);
                    end;
            until WorkflowStepArgument.Next() = 0;
    end;

    local procedure GetWorkflowType(Code: Code[20]): Enum "Approval Workflow Type"
    var
        WorkflowStep: Record "Workflow Step";
        WorkflowEvent: Record "Workflow Event";
    begin
        WorkflowStep.SetLoadFields("Function Name");
        WorkflowStep.SetRange("Workflow Code", Code);
        WorkflowStep.SetRange("Entry Point", true);
        if WorkflowStep.FindFirst() then begin
            WorkflowEvent.SetLoadFields("Table ID");
            if WorkflowEvent.Get(WorkflowStep."Function Name") then
                case WorkflowEvent."Table ID" of
                    Database::"Sales Header":
                        exit(WorkflowType::Sales);
                    Database::"Purchase Header":
                        exit(WorkflowType::Purchase);
                    else
                        exit(WorkflowType::Request);
                end;
        end
    end;

    local procedure GetUserId(ApproverUserName: Code[50]): Guid
    var
        User: Record User;
    begin
        User.SetLoadFields("User Security ID");
        User.SetRange("User Name", ApproverUserName);
        if User.FindFirst() then
            exit(User."User Security ID");
    end;
}