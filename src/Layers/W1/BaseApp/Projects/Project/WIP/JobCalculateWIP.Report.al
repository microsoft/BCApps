// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.WIP;

using Microsoft.Foundation.NoSeries;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Project.Setup;

report 1086 "Job Calculate WIP"
{
    AdditionalSearchTerms = 'calculate work in process,calculate work in progress, Job Calculate WIP';
    ApplicationArea = Jobs;
    Caption = 'Project Calculate WIP';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem(Job; Job)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Planning Date Filter", "Posting Date Filter";

            trigger OnAfterGetRecord()
            var
                JobCalculateWIP: Codeunit "Job Calculate WIP";
            begin
                JobCalculateWIP.JobCalcWIP(Job, PostingDate, DocNo);
                CalcFields("WIP Warnings");
                WIPPostedWithWarnings := WIPPostedWithWarnings or "WIP Warnings";
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(PostingDate; PostingDate)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the posting date for the document.';
                    }
                    field(DocumentNo; DocNo)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Document No.';
                        ToolTip = 'Specifies the number of a document that the calculation will apply to.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        var
            NoSeries: Codeunit "No. Series";
            NewNoSeriesCode: Code[20];
        begin
            if PostingDate = 0D then
                PostingDate := WorkDate();

            JobsSetup.Get();

            JobsSetup.TestField("Job WIP Nos.");
                NewNoSeriesCode := JobsSetup."Job WIP Nos.";
                DocNo := NoSeries.GetNextNo(NewNoSeriesCode);
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    var
        WIPPosted: Boolean;
        WIPQst: Text;
        InfoMsg: Text;
    begin
        JobWIPEntry.SetCurrentKey("Job No.");
        JobWIPEntry.SetFilter("Job No.", Job.GetFilter("No."));
        WIPPosted := JobWIPEntry.FindFirst();
        Commit();

        if WIPPosted then begin
            if WIPPostedWithWarnings then
                InfoMsg := Text002
            else
                InfoMsg := Text000;
            if DIALOG.Confirm(InfoMsg + PreviewQst) then begin
                JobWIPEntry.SetRange("Job No.", Job."No.");
                PAGE.RunModal(PAGE::"Job WIP Entries", JobWIPEntry);

                WIPQst := StrSubstNo(RunWIPFunctionsQst, 'Project Post WIP to G/L');
                if DIALOG.Confirm(WIPQst) then
                    REPORT.RunModal(REPORT::"Job Post WIP to G/L", true, false, Job);
            end;
        end else
            Message(Text001);
    end;

    trigger OnPreReport()
    var
        NoSeries: Codeunit "No. Series";
        NewNoSeriesCode: Code[20];
    begin
        JobsSetup.Get();

        if DocNo = '' then begin
            JobsSetup.TestField("Job WIP Nos.");
                NewNoSeriesCode := JobsSetup."Job WIP Nos.";
                DocNo := NoSeries.GetNextNo(NewNoSeriesCode);
        end;

        if PostingDate = 0D then
            PostingDate := WorkDate();

        JobCalculateBatches.BatchError(PostingDate, DocNo);
    end;

    var
#pragma warning disable AA0074
        Text000: Label 'WIP was successfully calculated.\';
        Text001: Label 'There were no new WIP entries created.';
        Text002: Label 'WIP was calculated with warnings.\';
#pragma warning restore AA0074
        PreviewQst: Label 'Do you want to preview the posting accounts?';
        RunWIPFunctionsQst: Label 'You must run the %1 function to post the completion entries for this project. \Do you want to run this function now?', Comment = '%1 = The name of the Project Post WIP to G/L report';

    protected var
        JobWIPEntry: Record "Job WIP Entry";
        JobsSetup: Record "Jobs Setup";
        JobCalculateBatches: Codeunit "Job Calculate Batches";
        PostingDate: Date;
        DocNo: Code[20];
        WIPPostedWithWarnings: Boolean;

    procedure InitializeRequest()
    begin
        PostingDate := WorkDate();
    end;
}
