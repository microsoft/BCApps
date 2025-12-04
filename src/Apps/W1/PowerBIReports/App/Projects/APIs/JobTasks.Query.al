// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.PowerBIReports;

using Microsoft.Projects.Project.Job;

query 36994 "Job Tasks"
{
    Access = Internal;
    QueryType = API;
    AboutText = 'Provides access to project task data including task hierarchy, task types, totaling definitions, and scheduled dates. Enables Power BI reports to analyze project work breakdown structures and support task-level reporting and filtering.';
    Caption = 'Power BI Project Tasks';
    APIPublisher = 'microsoft';
    APIGroup = 'analytics';
    ApiVersion = 'v0.5', 'v1.0';
    EntityName = 'jobTask';
    EntitySetName = 'jobTasks';
    DataAccessIntent = ReadOnly;

    elements
    {
        dataitem(jobTask; "Job Task")
        {
            column(jobNo; "Job No.")
            {
            }
            column(jobTaskNo; "Job Task No.")
            {
            }
            column(description; Description)
            {
            }
            column(totaling; Totaling)
            {
            }
            column(jobTaskType; "Job Task Type")
            {
            }
            column(indentation; Indentation)
            {
            }
            column(startingDate; "Start Date")
            {
            }
            column(endingDate; "End Date")
            {
            }
        }
    }
}
