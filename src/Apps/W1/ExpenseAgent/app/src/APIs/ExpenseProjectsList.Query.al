// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#if not CLEAN29
namespace Microsoft.ExpenseAgent;

using Microsoft.Projects.Project.Job;

query 7079 "Expense Projects List"
{
    QueryType = API;
    Access = Internal;
    APIPublisher = 'microsoft';
    APIGroup = 'expense';
    APIVersion = 'beta';
    EntityName = 'expenseProjectsListEntry';
    EntitySetName = 'expenseProjectsList';
    Caption = 'Expense Projects List';
    DataAccessIntent = ReadOnly;
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced by the consolidated expenseProjects API.';
    ObsoleteTag = '29.0';
    AboutTitle = 'Expense Projects List';
    AboutText = 'Returns all active projects with their posting-type tasks as a flat list. Non-posting tasks (Heading, Total, Begin-Total, End-Total) are excluded as they are not valid for expense posting. Callers are expected to scope the request with an OData $filter (typically projectStatus eq ''Open'' and a date window) to keep the response small in tenants with many projects.';

    elements
    {
        dataitem(project; Job)
        {
            DataItemTableFilter = Status = filter(< Completed);

            column(systemId; SystemId) { }
            column(projectNo; "No.") { }
            column(projectDescription; Description) { }
            column(projectStatus; Status) { }
            column(projectStartingDate; "Starting Date") { }
            column(projectEndingDate; "Ending Date") { }
            column(personResponsible; "Person Responsible") { }

            dataitem(projectTask; "Job Task")
            {
                DataItemLink = "Job No." = project."No.";
                DataItemTableFilter = "Job Task Type" = const(Posting);
                SqlJoinType = InnerJoin;

                column(taskSystemId; SystemId) { }
                column(projectTaskNo; "Job Task No.") { }
                column(taskDescription; Description) { }
                column(taskType; "Job Task Type") { }
                column(taskStartDate; "Start Date") { }
                column(taskEndDate; "End Date") { }
            }
        }
    }

    trigger OnBeforeOpen()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        ExpenseAgentAPIValidation: Codeunit "Expense Agent API Validation";
        ExpenseCapabilitiesProvider: Codeunit "Expense Capabilities Provider";
    begin
        ExpenseAgentAPIValidation.VerifyAgentAccess();
        if not ExpenseCapabilitiesProvider.IsEnabled(Enum::"Expense Capability"::Projects) then
            Error(ProjectFieldsNotEnabledErr);
        if not ExpenseAgentSetup.Get() then
            Error(ExpenseAgentSetupMissingErr);
        if ExpenseAgentSetup."Project Visibility" <> ExpenseAgentSetup."Project Visibility"::"All projects" then
            Error(AllProjectsNotAllowedErr);
    end;

    var
        ExpenseAgentSetupMissingErr: Label 'Expense Agent Setup record is missing.';
        ProjectFieldsNotEnabledErr: Label 'Project fields are not enabled in the Expense Agent Setup.';
        AllProjectsNotAllowedErr: Label 'Listing all projects is not allowed by the current Project Visibility setting.';
}
#endif
