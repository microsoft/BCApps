// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#if not CLEAN29
namespace Microsoft.ExpenseAgent;

using Microsoft.HumanResources.Employee;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Planning;

query 7080 "Expense User Assigned Plan Ln"
{
    QueryType = API;
    Access = Internal;
    APIPublisher = 'microsoft';
    APIGroup = 'expense';
    APIVersion = 'beta';
    EntityName = 'expenseUserAssignedPlanningLine';
    EntitySetName = 'expenseUserAssignedPlanningLines';
    Caption = 'Expense User Assigned Planning Lines';
    DataAccessIntent = ReadOnly;
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced by the consolidated expenseProjects API.';
    ObsoleteTag = '29.0';
    AboutTitle = 'Expense User Assigned Planning Lines';
    AboutText = 'Returns one (project, project task) row per posting-type task that the given Expense User is planned on. The caller must filter by forExpenseUserSystemId';

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

                dataitem(projectPlanningLine; "Job Planning Line")
                {
                    DataItemLink = "No." = employee."Resource No.";
                    DataItemTableFilter = Type = const(Resource);
                    SqlJoinType = InnerJoin;

                    column(projectNo; "Job No.") { }
                    column(projectTaskNo; "Job Task No.") { }
                    // Method = Count triggers a SQL GROUP BY across the query,
                    // collapsing multiple planning lines per (projectNo, projectTaskNo)
                    // into one row.
                    column(planningLineCount) { Method = Count; }

                    dataitem(project; Job)
                    {
                        DataItemLink = "No." = projectPlanningLine."Job No.";
                        DataItemTableFilter = Status = filter(< Completed);
                        SqlJoinType = InnerJoin;

                        column(systemId; SystemId) { }
                        column(projectDescription; Description) { }
                        column(projectStatus; Status) { }
                        column(projectStartingDate; "Starting Date") { }
                        column(projectEndingDate; "Ending Date") { }

                        dataitem(projectTask; "Job Task")
                        {
                            DataItemLink = "Job No." = project."No.", "Job Task No." = projectPlanningLine."Job Task No.";
                            DataItemTableFilter = "Job Task Type" = const(Posting);
                            SqlJoinType = InnerJoin;

                            column(taskSystemId; SystemId) { }
                            column(taskDescription; Description) { }
                            column(taskType; "Job Task Type") { }
                            column(taskStartDate; "Start Date") { }
                            column(taskEndDate; "End Date") { }
                        }
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

