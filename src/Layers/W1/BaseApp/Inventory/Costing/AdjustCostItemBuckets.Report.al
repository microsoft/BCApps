// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using Microsoft.Inventory.Ledger;

report 5804 "Adjust Cost - Item Buckets"
{
    ApplicationArea = Basic, Suite;
    ProcessingOnly = true;
    UseRequestPage = false;
    Permissions = TableData "Item Ledger Entry" = rimd,
                  TableData "Item Application Entry" = r,
                  TableData "Value Entry" = rimd,
                  TableData "Avg. Cost Adjmt. Entry Point" = rimd;
    Caption = 'Adjust Cost - Item Buckets';

    dataset
    {
        dataitem("CA Item Bucket"; "Cost Adj. Item Bucket")
        {
            DataItemTableView = sorting("Line No.");

            trigger OnPreDataItem()
            begin
                if IsEmpty() then
                    CurrReport.Quit();

                SetRange(Status, Status::Running);
                if not IsEmpty() then
                    Error(TaskIsRunningErr);

                SetRange(Status, Status::"Not started");
            end;

            trigger OnAfterGetRecord()
            begin
                Clear("Starting Date-Time");
                Clear("Ending Date-Time");
                Clear("Last Error");
                Clear("Last Error Call Stack");
                Clear("Failed Item No.");
                Modify();
            end;

            trigger OnPostDataItem()
            var
                CostAdjSessionScheduler: Codeunit "Cost Adj. Session Scheduler";
            begin
                Commit();
                if TaskScheduler.CanCreateTask() and not RunForeground then
                    TaskScheduler.CreateTask(Codeunit::"Cost Adj. Session Scheduler", 0, true, CompanyName(), CurrentDateTime())
                else begin
                    CostAdjSessionScheduler.SetRunForeground(RunForeground);
                    CostAdjSessionScheduler.Run();
                end;
            end;
        }
    }

    var
        RunForeground: Boolean;
        TaskIsRunningErr: Label 'The cost adjustment is now running. Please wait until it is finished.';

    procedure SetRunForeground(NeedRunForeground: Boolean)
    begin
        RunForeground := NeedRunForeground;
    end;
}
