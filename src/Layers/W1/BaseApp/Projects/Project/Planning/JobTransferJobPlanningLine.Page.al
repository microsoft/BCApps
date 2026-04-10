// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Planning;

using Microsoft.Projects.Project.Journal;

page 1014 "Job Transfer Job Planning Line"
{
    Caption = 'Project Transfer Project Planning Line';
    PageType = StandardDialog;
    SaveValues = true;
    SourceTable = "Job Journal Template";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(PostingDate; PostingDate)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Posting Date';
                    ToolTip = 'Specifies the posting date for the document.';
                }
                field(JobJournalTemplateName; JobJournalTemplateName)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Project Journal Template';
                    Lookup = true;
                    TableRelation = "Job Journal Template".Name where("Page ID" = const(201),
                                                                       Recurring = const(false));
                    ToolTip = 'Specifies the journal template that is used for the project journal.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        SelectJobJournalTemplate();
                    end;
                }
                field(JobJournalBatchName; JobJournalBatchName)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Project Journal Batch';
                    Lookup = true;
                    TableRelation = "Job Journal Batch".Name where("Journal Template Name" = field(Name));
                    ToolTip = 'Specifies the journal batch that is used for the project journal.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        SelectJobJournalBatch();
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        InitializeValues();
    end;

    var
        JobJournalTemplateName: Code[10];
        JobJournalBatchName: Code[10];
        PostingDate: Date;

    procedure InitializeValues()
    var
        JobJnlTemplate: Record "Job Journal Template";
        JobJnlBatch: Record "Job Journal Batch";
    begin
        PostingDate := WorkDate();

        JobJnlTemplate.SetRange("Page ID", PAGE::"Job Journal");
        JobJnlTemplate.SetRange(Recurring, false);

        if JobJnlTemplate.Count = 1 then begin
            JobJnlTemplate.FindFirst();
            JobJournalTemplateName := JobJnlTemplate.Name;

            JobJnlBatch.SetRange("Journal Template Name", JobJournalTemplateName);

            if JobJnlBatch.Count = 1 then begin
                JobJnlBatch.FindFirst();
                JobJournalBatchName := JobJnlBatch.Name;
            end;
        end;
    end;

    local procedure SelectJobJournalTemplate()
    var
        JobJnlTemplate: Record "Job Journal Template";
        JobJnlBatch: Record "Job Journal Batch";
    begin
        JobJnlTemplate.SetRange("Page ID", PAGE::"Job Journal");
        JobJnlTemplate.SetRange(Recurring, false);

        if PAGE.RunModal(0, JobJnlTemplate) = ACTION::LookupOK then begin
            JobJournalTemplateName := JobJnlTemplate.Name;

            JobJnlBatch.SetRange("Journal Template Name", JobJournalTemplateName);

            if JobJnlBatch.Count = 1 then begin
                JobJnlBatch.FindFirst();
                JobJournalBatchName := JobJnlBatch.Name;
            end else
                JobJournalBatchName := '';
        end;
    end;

    local procedure SelectJobJournalBatch()
    var
        JobJnlBatch: Record "Job Journal Batch";
    begin
        JobJnlBatch.SetRange("Journal Template Name", JobJournalTemplateName);

        if PAGE.RunModal(0, JobJnlBatch) = ACTION::LookupOK then
            JobJournalBatchName := JobJnlBatch.Name;
    end;

    procedure GetPostingDate(): Date
    begin
        exit(PostingDate);
    end;

    procedure GetJobJournalTemplateName(): Code[10]
    begin
        exit(JobJournalTemplateName);
    end;

    procedure GetJobJournalBatchName(): Code[10]
    begin
        exit(JobJournalBatchName);
    end;
}

