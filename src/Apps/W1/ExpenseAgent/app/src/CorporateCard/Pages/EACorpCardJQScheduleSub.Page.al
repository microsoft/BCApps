// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using System.Threading;

page 7235 "EA Corp Card JQ Schedule Sub"
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

    trigger OnAfterGetRecord()
    var
        EmptyRecordId: RecordId;
    begin
        if Rec."Record ID to Process" = EmptyRecordId then
            CurrPage.Close();

        if Rec."Record ID to Process".TableNo() = 0 then
            CurrPage.Close();
    end;

    procedure SetProviderFilter(ProviderCode: Code[20])
    var
        CorpCardProvider: Record "EA Corp Card Provider";
    begin
        CorpCardProvider.Get(ProviderCode);
        Rec.SetRange("Record ID to Process", CorpCardProvider.RecordId);
    end;
}
