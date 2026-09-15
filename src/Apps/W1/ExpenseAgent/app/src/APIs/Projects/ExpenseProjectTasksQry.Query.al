// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Projects.Project.Job;

query 7089 "Expense Project Tasks Qry"
{
    QueryType = Normal;
    Access = Internal;
    DataAccessIntent = ReadOnly;
    Caption = 'Expense Project Tasks Query';

    elements
    {
        dataitem(project; Job)
        {
            DataItemTableFilter = Status = filter(< Completed);

            column(projectSystemId; SystemId) { }
            column(projectNo; "No.") { }
            column(projectDescription; Description) { }
            column(projectStatus; Status) { }
            column(projectStartingDate; "Starting Date") { }
            column(projectEndingDate; "Ending Date") { }
            column(personResponsible; "Person Responsible") { }
            column(projectManager; "Project Manager") { }

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
