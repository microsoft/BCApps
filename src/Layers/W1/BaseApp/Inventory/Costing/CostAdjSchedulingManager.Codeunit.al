// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using Microsoft.Sales.Posting;
using System.Threading;

codeunit 2849 "Cost Adj. Scheduling Manager"
{
    var
        SalesPostViaJobQueue: Codeunit "Sales Post via Job Queue";

    procedure AdjCostJobQueueExists(): Boolean
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Report);
        JobQueueEntry.SetRange("Object ID to Run", Report::"Adjust Cost - Item Entries");
        exit(not JobQueueEntry.IsEmpty());
    end;

    procedure PostInvCostToGLJobQueueExists(): Boolean
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // Check for both regular report reference and our codeunit wrapper.
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Report);
        JobQueueEntry.SetRange("Object ID to Run", Report::"Post Inventory Cost to G/L");
        if not JobQueueEntry.IsEmpty() then
            exit(true);

        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Post Inventory Cost to G/L");
        exit(not JobQueueEntry.IsEmpty());
    end;

    procedure CreateAdjCostJobQueue()
    var
        JobQueueEntry: Record "Job Queue Entry";
        BlankRecordId: RecordId;
        NextRunDateFormula: DateFormula;
    begin
        if AdjCostJobQueueExists() then
            exit;

        Evaluate(NextRunDateFormula, '<1D>');

        JobQueueEntry.ScheduleRecurrentJobQueueEntryWithRunDateFormula(
            JobQueueEntry."Object Type to Run"::Report,
            Report::"Adjust Cost - Item Entries",
            BlankRecordId,
            SalesPostViaJobQueue.GetJobQueueCategoryCode(),
            0,
            NextRunDateFormula,
            010000T // 1 AM.
        );
        JobQueueEntry."Report Output Type" := JobQueueEntry."Report Output Type"::"None (Processing only)";
        JobQueueEntry.Modify();
    end;

    procedure CreatePostInvCostToGLJobQueue()
    var
        JobQueueEntry: Record "Job Queue Entry";
        BlankRecordId: RecordId;
        NextRunDateFormula: DateFormula;
    begin
        if PostInvCostToGLJobQueueExists() then
            exit;

        Evaluate(NextRunDateFormula, '<1D>');

        JobQueueEntry.ScheduleRecurrentJobQueueEntryWithRunDateFormula(
            JobQueueEntry."Object Type to Run"::Codeunit,
            Codeunit::"Post Inventory Cost to G/L",
            BlankRecordId,
            SalesPostViaJobQueue.GetJobQueueCategoryCode(),
            0,
            NextRunDateFormula,
            020000T // 2 AM.
        );
    end;

    procedure SetupDisplayJobQueueEntriesFilter(var JobQueueEntry: Record "Job Queue Entry")
    begin
        JobQueueEntry.SetFilter("Object ID to Run", '%1|%2',
            Codeunit::"Post Inventory Cost to G/L", Report::"Adjust Cost - Item Entries");
        JobQueueEntry.SetRange("Job Queue Category Code", SalesPostViaJobQueue.GetJobQueueCategoryCode());
    end;
}
