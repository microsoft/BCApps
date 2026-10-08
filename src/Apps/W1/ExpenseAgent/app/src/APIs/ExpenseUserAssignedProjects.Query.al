// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#if not CLEAN29
namespace Microsoft.ExpenseAgent;

using Microsoft.HumanResources.Employee;
using Microsoft.Projects.Project.Job;

query 7081 "Expense User Assigned Projects"
{
    QueryType = API;
    Access = Internal;
    APIPublisher = 'microsoft';
    APIGroup = 'expense';
    APIVersion = 'beta';
    EntityName = 'expenseUserAssignedProjectEntry';
    EntitySetName = 'expenseUserAssignedProjects';
    Caption = 'Expense User Assigned Projects';
    DataAccessIntent = ReadOnly;
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced by the consolidated expenseProjects API.';
    ObsoleteTag = '29.0';
    AboutTitle = 'Expense User Assigned Projects';
    AboutText = 'Returns non-completed projects (with their posting-type tasks) for which the given Expense User is the Person Responsible.';

    elements
    {
        dataitem(expenseUser; "Expense User")
        {
            column(forExpenseUserSystemId; SystemId) { }

            dataitem(employee; Employee)
            {
                DataItemLink = "No." = expenseUser."Employee No.";
                // Skip employees with no Resource No. so that empty values
                DataItemTableFilter = "Resource No." = filter(<> '');
                SqlJoinType = InnerJoin;

                dataitem(project; Job)
                {
                    DataItemLink = "Person Responsible" = employee."Resource No.";
                    DataItemTableFilter = Status = filter(< Completed);
                    SqlJoinType = InnerJoin;

                    column(systemId; SystemId) { }
                    column(projectNo; "No.") { }
                    column(projectDescription; Description) { }
                    column(projectStatus; Status) { }
                    column(projectStartingDate; "Starting Date") { }
                    column(projectEndingDate; "Ending Date") { }

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
        }
    }

    trigger OnBeforeOpen()
    var
        ExpenseAgentAPIValidation: Codeunit "Expense Agent API Validation";
        ExpenseCapabilitiesProvider: Codeunit "Expense Capabilities Provider";
    begin
        ExpenseAgentAPIValidation.VerifyAgentAccess();
        if not ExpenseCapabilitiesProvider.IsEnabled(Enum::"Expense Capability"::Projects) then
            Error(ProjectFieldsNotEnabledErr);
        if GetFilter(forExpenseUserSystemId) = '' then
            Error(ScopeRequiredErr);
    end;

    var
        ProjectFieldsNotEnabledErr: Label 'Project fields are not enabled in the Expense Agent Setup.';
        ScopeRequiredErr: Label 'A filter on forExpenseUserSystemId is required.';
}
#endif
