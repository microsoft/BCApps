// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using System.Threading;

page 7445 "EA Corp Card JQ Schedule Sub"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Job Queue Schedule';
    PageType = ListPart;
    SourceTable = "Job Queue Entry";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(JobQueues)
            {
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the Job Queue entry.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the Job Queue entry.';
                }
                field("No. of Minutes between Runs"; Rec."No. of Minutes between Runs")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the frequency of the Job Queue entry (in minutes).';
                }
                field("Earliest Start Date/Time"; Rec."Earliest Start Date/Time")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the earliest start date and time for this job queue entry.';
                }
                field("No. of Attempts to Run"; Rec."No. of Attempts to Run")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of times this job queue entry has been executed.';
                }
                field("Maximum No. of Attempts to Run"; Rec."Maximum No. of Attempts to Run")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the maximum number of attempts for this job queue entry.';
                }
                field("Last Ready State"; Rec."Last Ready State")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last ready state of the Job Queue entry.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.FilterGroup(2);
        Rec.SetRange("Object Type to Run", Rec."Object Type to Run"::Codeunit);
        Rec.SetRange("Object ID to Run", Codeunit::"EA Corp Card JQ Runner");
        Rec.FilterGroup(0);
    end;
}
