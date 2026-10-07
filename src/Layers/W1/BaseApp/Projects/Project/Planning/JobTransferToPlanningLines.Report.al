// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Planning;

using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Project.Ledger;

report 1091 "Job Transfer To Planning Lines"
{
    Caption = 'Project Transfer To Planning Lines';
    ProcessingOnly = true;

    dataset
    {
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(TransferTo; LineType)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Transfer To';
                        ToolTip = 'Specifies the type of planning lines that should be created.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        JobCalcBatches.TransferToPlanningLine(JobLedgEntry, LineType.AsInteger() + 1);
    end;

    var
        JobLedgEntry: Record "Job Ledger Entry";
        JobCalcBatches: Codeunit "Job Calculate Batches";
        LineType: Enum "Job Planning Line Line Type";

    procedure GetJobLedgEntry(var JobLedgEntry2: Record "Job Ledger Entry")
    begin
        JobLedgEntry.Copy(JobLedgEntry2);
    end;
}

