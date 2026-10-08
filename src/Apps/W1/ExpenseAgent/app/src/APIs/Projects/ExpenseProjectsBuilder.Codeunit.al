// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Planning;

codeunit 7090 "Expense Projects Builder"
{
    Access = Internal;

    var
        ExpenseAgentSetupMissingErr: Label 'Expense Agent Setup record is missing.';

    procedure BuildProjects(var TempProjectBuf: Record "Expense Project Buf" temporary; UserSystemIdFilter: Text)
    var
        UserSystemId: Guid;
    begin
        TempProjectBuf.Reset();
        TempProjectBuf.DeleteAll();

        if not TryEvaluateUser(UserSystemIdFilter, UserSystemId) then
            exit;

        if IsAllProjectsVisibility() then
            BuildAllProjects(TempProjectBuf, UserSystemId)
        else
            BuildAssignedProjects(TempProjectBuf, UserSystemId);
    end;

    local procedure BuildAllProjects(var TempProjectBuf: Record "Expense Project Buf" temporary; UserSystemId: Guid)
    var
        ExpenseProjectTasksQry: Query "Expense Project Tasks Qry";
    begin
        ExpenseProjectTasksQry.Open();
        while ExpenseProjectTasksQry.Read() do
            InsertRow(TempProjectBuf, UserSystemId, ExpenseProjectTasksQry);
        ExpenseProjectTasksQry.Close();
    end;

    local procedure BuildAssignedProjects(var TempProjectBuf: Record "Expense Project Buf" temporary; UserSystemId: Guid)
    var
        TempTaskLevelPair: Record "Job Task" temporary;
        ExpenseProjectTasksQry: Query "Expense Project Tasks Qry";
        WholeProjectJobs: Dictionary of [Code[20], Boolean];
        ResourceNo: Code[20];
        UserId: Code[50];
    begin
        if not GetUserIdentity(UserSystemId, ResourceNo, UserId) then
            exit;

        CollectAssignedResources(ResourceNo, WholeProjectJobs, TempTaskLevelPair);
        CollectPlanningLines(ResourceNo, TempTaskLevelPair);

        ExpenseProjectTasksQry.Open();
        while ExpenseProjectTasksQry.Read() do
            if IsTaskAssigned(ExpenseProjectTasksQry, ResourceNo, UserId, WholeProjectJobs, TempTaskLevelPair) then
                InsertRow(TempProjectBuf, UserSystemId, ExpenseProjectTasksQry);
        ExpenseProjectTasksQry.Close();
    end;

    local procedure IsTaskAssigned(var ExpenseProjectTasksQry: Query "Expense Project Tasks Qry"; ResourceNo: Code[20]; UserId: Code[50]; var WholeProjectJobs: Dictionary of [Code[20], Boolean]; var TempTaskLevelPair: Record "Job Task" temporary): Boolean
    var
        WholeProject: Boolean;
    begin
        WholeProject :=
            ((ResourceNo <> '') and (ExpenseProjectTasksQry.personResponsible = ResourceNo)) or
            ((UserId <> '') and (ExpenseProjectTasksQry.projectManager = UserId)) or
            WholeProjectJobs.ContainsKey(ExpenseProjectTasksQry.projectNo);
        exit(
            WholeProject or
            PairExists(TempTaskLevelPair, ExpenseProjectTasksQry.projectNo, ExpenseProjectTasksQry.projectTaskNo));
    end;

    local procedure CollectAssignedResources(ResourceNo: Code[20]; var WholeProjectJobs: Dictionary of [Code[20], Boolean]; var TempTaskLevelPair: Record "Job Task" temporary)
    var
        JobAssignedResource: Record "Job Assigned Resource";
    begin
        if ResourceNo = '' then
            exit;
        JobAssignedResource.SetLoadFields("Job No.", "Job Task No.");
        JobAssignedResource.SetRange("Resource No.", ResourceNo);
        if JobAssignedResource.FindSet() then
            repeat
                if JobAssignedResource."Job Task No." = '' then begin
                    if not WholeProjectJobs.ContainsKey(JobAssignedResource."Job No.") then
                        WholeProjectJobs.Add(JobAssignedResource."Job No.", true);
                end else
                    AddPair(TempTaskLevelPair, JobAssignedResource."Job No.", JobAssignedResource."Job Task No.");
            until JobAssignedResource.Next() = 0;
    end;

    local procedure CollectPlanningLines(ResourceNo: Code[20]; var TempTaskLevelPair: Record "Job Task" temporary)
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        if ResourceNo = '' then
            exit;
        JobPlanningLine.SetLoadFields("Job No.", "Job Task No.");
        JobPlanningLine.SetRange(Type, JobPlanningLine.Type::Resource);
        JobPlanningLine.SetRange("No.", ResourceNo);
        if JobPlanningLine.FindSet() then
            repeat
                AddPair(TempTaskLevelPair, JobPlanningLine."Job No.", JobPlanningLine."Job Task No.");
            until JobPlanningLine.Next() = 0;
    end;

    local procedure AddPair(var TempTaskLevelPair: Record "Job Task" temporary; JobNo: Code[20]; JobTaskNo: Code[20])
    begin
        TempTaskLevelPair."Job No." := JobNo;
        TempTaskLevelPair."Job Task No." := JobTaskNo;
        if TempTaskLevelPair.Insert() then;
    end;

    local procedure PairExists(var TempTaskLevelPair: Record "Job Task" temporary; JobNo: Code[20]; JobTaskNo: Code[20]): Boolean
    begin
        exit(TempTaskLevelPair.Get(JobNo, JobTaskNo));
    end;

    local procedure InsertRow(var TempProjectBuf: Record "Expense Project Buf" temporary; UserSystemId: Guid; var ExpenseProjectTasksQry: Query "Expense Project Tasks Qry")
    begin
        TempProjectBuf.Init();
        TempProjectBuf."Expense User SystemId" := UserSystemId;
        TempProjectBuf."Project No." := ExpenseProjectTasksQry.projectNo;
        TempProjectBuf."Project Task No." := ExpenseProjectTasksQry.projectTaskNo;
        TempProjectBuf."Project SystemId" := ExpenseProjectTasksQry.projectSystemId;
        TempProjectBuf."Project Description" := ExpenseProjectTasksQry.projectDescription;
        TempProjectBuf."Project Status" := ExpenseProjectTasksQry.projectStatus;
        TempProjectBuf."Project Starting Date" := ExpenseProjectTasksQry.projectStartingDate;
        TempProjectBuf."Project Ending Date" := ExpenseProjectTasksQry.projectEndingDate;
        TempProjectBuf."Task SystemId" := ExpenseProjectTasksQry.taskSystemId;
        TempProjectBuf."Task Description" := ExpenseProjectTasksQry.taskDescription;
        TempProjectBuf."Task Type" := ExpenseProjectTasksQry.taskType;
        TempProjectBuf."Task Start Date" := ExpenseProjectTasksQry.taskStartDate;
        TempProjectBuf."Task End Date" := ExpenseProjectTasksQry.taskEndDate;
        if TempProjectBuf.Insert() then;
    end;

    local procedure GetUserIdentity(UserSystemId: Guid; var ResourceNo: Code[20]; var UserId: Code[50]): Boolean
    var
        ExpenseUser: Record "Expense User";
    begin
        if not ExpenseUser.GetBySystemId(UserSystemId) then
            exit(false);
        ExpenseUser.CalcFields("Resource No.");
        ResourceNo := ExpenseUser."Resource No.";
        UserId := ExpenseUser."User Id For Approvals";
        exit(true);
    end;

    local procedure IsAllProjectsVisibility(): Boolean
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        if not ExpenseAgentSetup.Get() then
            Error(ExpenseAgentSetupMissingErr);
        exit(ExpenseAgentSetup."Project Visibility" = ExpenseAgentSetup."Project Visibility"::"All projects");
    end;

    local procedure TryEvaluateUser(UserSystemIdFilter: Text; var UserSystemId: Guid): Boolean
    begin
        Clear(UserSystemId);
        if UserSystemIdFilter = '' then
            exit(false);
        if not Evaluate(UserSystemId, UserSystemIdFilter) then
            exit(false);
        exit(not IsNullGuid(UserSystemId));
    end;
}
