// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Planning;

using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Journal;
using Microsoft.Sales.Setup;

report 1093 "Job Create Sales Invoice"
{
    AdditionalSearchTerms = 'Job Create Sales Invoice';
    ApplicationArea = Jobs;
    Caption = 'Project Create Sales Invoice';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("Job Task"; "Job Task")
        {
            DataItemTableView = sorting("Job No.", "Job Task No.");
            RequestFilterFields = "Job No.", "Job Task No.", "Planning Date Filter";

            trigger OnAfterGetRecord()
            var
                IsHandled: Boolean;
            begin

                IsHandled := false;
                OnBeforeJobTaskOnAfterGetRecord("Job Task", IsHandled);
                if not IsHandled then
                    JobCreateInvoice.CreateSalesInvoiceJobTask(
                      "Job Task", PostingDate, DocumentDate, InvoicePerTask, NoOfInvoices, OldJobNo, OldJTNo, false);
            end;

            trigger OnPostDataItem()
            begin
                JobCreateInvoice.CreateSalesInvoiceJobTask(
                  "Job Task", PostingDate, DocumentDate, InvoicePerTask, NoOfInvoices, OldJobNo, OldJTNo, true);
            end;

            trigger OnPreDataItem()
            begin
                NoOfInvoices := 0;
                OldJobNo := '';
                OldJTNo := '';
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

                        trigger OnValidate()
                        var
                            SalesReceivablesSetup: Record "Sales & Receivables Setup";
                        begin
                            SalesReceivablesSetup.SetLoadFields("Link Doc. Date To Posting Date");
                            SalesReceivablesSetup.GetRecordOnce();
                            if SalesReceivablesSetup."Link Doc. Date To Posting Date" then
                                DocumentDate := PostingDate;
                        end;
                    }
                    field("Document Date"; DocumentDate)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Document Date';
                        ToolTip = 'Specifies the document date.';
                    }
                    field(JobChoice; JobChoice)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Create Invoice per';
                        OptionCaption = 'Project,Project Task';
                        ToolTip = 'Specifies, if you select the Project Task option, that you want to create one invoice per project task rather than the one invoice per project that is created by default.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            PostingDate := WorkDate();
            DocumentDate := WorkDate();
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        OnBeforeOnOnInitReport(JobChoice);
    end;

    trigger OnPostReport()
    begin
        OnBeforePostReport();

        JobCalcBatches.EndCreateInvoice(NoOfInvoices);

        OnAfterPostReport(NoOfInvoices);
    end;

    trigger OnPreReport()
    begin
        JobCalcBatches.BatchError(PostingDate, Text000);
        InvoicePerTask := JobChoice = JobChoice::"Job Task";
        JobCreateInvoice.DeleteSalesInvoiceBuffer();

        OnAfterPreReport();
    end;

    var
        JobCreateInvoice: Codeunit "Job Create-Invoice";
        JobCalcBatches: Codeunit "Job Calculate Batches";
        NoOfInvoices: Integer;
        InvoicePerTask: Boolean;
        OldJobNo: Code[20];
        OldJTNo: Code[20];
#pragma warning disable AA0074
        Text000: Label 'A', Comment = 'A';
#pragma warning restore AA0074

    protected var
        JobChoice: Option Job,"Job Task";
        PostingDate, DocumentDate : Date;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostReport(NoOfInvoices: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPreReport()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnOnInitReport(var JobChoice: Option Job,"Job Task")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeJobTaskOnAfterGetRecord(JobTask: Record "Job Task"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostReport()
    begin
    end;
}

