// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Planning;

using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Journal;

report 1088 "Job Split Planning Line"
{
    AdditionalSearchTerms = 'Job Split Planning Line';
    ApplicationArea = Jobs;
    Caption = 'Project Split Planning Line';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("Job Task"; "Job Task")
        {
            DataItemTableView = sorting("Job No.", "Job Task No.");
            RequestFilterFields = "Job No.", "Job Task No.", "Planning Date Filter";

            trigger OnAfterGetRecord()
            begin
                Clear(CalcBatches);
                NoOfLinesSplit += CalcBatches.SplitLines("Job Task");
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        if NoOfLinesSplit <> 0 then
            Message(Text000, NoOfLinesSplit)
        else
            Message(Text001);
    end;

    trigger OnPreReport()
    begin
        NoOfLinesSplit := 0;
    end;

    var
        CalcBatches: Codeunit "Job Calculate Batches";
        NoOfLinesSplit: Integer;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%1 planning line(s) successfully split.';
#pragma warning restore AA0470
        Text001: Label 'There were no planning lines to split.';
#pragma warning restore AA0074
}

