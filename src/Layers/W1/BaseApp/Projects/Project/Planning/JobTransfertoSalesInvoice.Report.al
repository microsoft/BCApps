// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Planning;

using Microsoft.Projects.Project.Job;
using Microsoft.Sales.Document;
using Microsoft.Sales.Setup;

report 1094 "Job Transfer to Sales Invoice"
{
    Caption = 'Project Transfer to Sales Invoice';
    ProcessingOnly = true;

    dataset
    {
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
                    field(CreateNewInvoice; NewInvoice)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Create New Invoice';
                        ToolTip = 'Specifies if the batch job creates a new sales invoice.';

                        trigger OnValidate()
                        begin
                            if NewInvoice then begin
                                InvoiceNo := '';
                                if PostingDate = 0D then
                                    PostingDate := WorkDate();
                                if DocumentDate = 0D then
                                    DocumentDate := WorkDate();
                                InvoicePostingDate := 0D;
                            end;
                        end;
                    }
                    field(PostingDate; PostingDate)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the posting date for the document.';

                        trigger OnValidate()
                        var
                            SalesReceivablesSetup: Record "Sales & Receivables Setup";
                        begin
                            if PostingDate = 0D then
                                NewInvoice := false;
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

                        trigger OnValidate()
                        begin
                            if DocumentDate = 0D then
                                NewInvoice := false;
                        end;
                    }
                    field(AppendToSalesInvoiceNo; InvoiceNo)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Append to Sales Invoice No.';
                        ToolTip = 'Specifies the number of the sales invoice that you want to append the lines to if you did not select the Create New Sales Invoice field.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            Clear(SalesHeader);
                            SalesHeader.FilterGroup := 2;
                            SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
                            SalesHeader.SetRange("Bill-to Customer No.", BillToCustomerNo);
                            if Job."Task Billing Method" = Job."Task Billing Method"::"Multiple customers" then begin
                                SalesHeader.SetRange("Sell-to Customer No.", SellToCustomerNo);
                                SalesHeader.SetRange("Currency Code", CurrencyCode);
                            end;
                            SalesHeader.FilterGroup := 0;
                            if PAGE.RunModal(0, SalesHeader) = ACTION::LookupOK then
                                InvoiceNo := SalesHeader."No.";
                            if InvoiceNo <> '' then begin
                                SalesHeader.Get(SalesHeader."Document Type"::Invoice, InvoiceNo);
                                InvoicePostingDate := SalesHeader."Posting Date";
                                NewInvoice := false;
                                PostingDate := 0D;
                                DocumentDate := 0D;
                            end;
                            if InvoiceNo = '' then
                                InitReport();
                        end;

                        trigger OnValidate()
                        begin
                            if InvoiceNo <> '' then begin
                                SalesHeader.Get(SalesHeader."Document Type"::Invoice, InvoiceNo);
                                InvoicePostingDate := SalesHeader."Posting Date";
                                NewInvoice := false;
                                PostingDate := 0D;
                                DocumentDate := 0D;
                            end;
                            if InvoiceNo = '' then
                                InitReport();
                        end;
                    }
                    field(InvoicePostingDate; InvoicePostingDate)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Invoice Posting Date';
                        Editable = false;
                        ToolTip = 'Specifies, if you filled in the Append to Sales Invoice No. field, the posting date of the invoice.';

                        trigger OnValidate()
                        begin
                            if PostingDate = 0D then
                                NewInvoice := false;
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
            InitReport();
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        Done := false;
    end;

    trigger OnPostReport()
    begin
        Done := true;
    end;

    var
        SalesHeader: Record "Sales Header";
        BillToCustomerNo, SellToCustomerNo, CurrencyCode : Code[20];
        PostingDate: Date;
        DocumentDate: Date;
        InvoicePostingDate: Date;
        Done: Boolean;

    protected var
        Job: Record Job;
        InvoiceNo: Code[20];
        NewInvoice: Boolean;

    procedure GetInvoiceNo(var Done2: Boolean; var NewInvoice2: Boolean; var PostingDate2: Date; var DocumentDate2: Date; var InvoiceNo2: Code[20])
    begin
        Done2 := Done;
        NewInvoice2 := NewInvoice;
        PostingDate2 := PostingDate;
        InvoiceNo2 := InvoiceNo;
        DocumentDate2 := DocumentDate;
    end;

    procedure InitReport()
    begin
        PostingDate := WorkDate();
        DocumentDate := WorkDate();
        NewInvoice := true;
        InvoiceNo := '';
        InvoicePostingDate := 0D;
    end;

    procedure SetCustomer(JobNo: Code[20])
    begin
        Job.Get(JobNo);
    end;

    procedure SetCustomer(JobPlanningLine: Record "Job Planning Line")
    var
        JobTask: Record "Job Task";
        IsHandled: Boolean;
    begin
        Job.Get(JobPlanningLine."Job No.");
        IsHandled := false;
        OnBeforeSetCustomer(JobPlanningLine, BillToCustomerNo, SellToCustomerNo, CurrencyCode, IsHandled);
        if IsHandled then
            exit;

        BillToCustomerNo := Job."Bill-to Customer No.";

        if Job."Task Billing Method" = Job."Task Billing Method"::"One customer" then
            exit;

        JobTask.SetLoadFields("Bill-to Customer No.", "Sell-to Customer No.", "Invoice Currency Code");
        if JobTask.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.") then begin
            BillToCustomerNo := JobTask."Bill-to Customer No.";
            SellToCustomerNo := JobTask."Sell-to Customer No.";
            CurrencyCode := JobTask."Invoice Currency Code";
        end;
    end;

    procedure SetPostingDate(PostingDate2: Date)
    begin
        PostingDate := PostingDate2;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetCustomer(JobPlanningLine: Record "Job Planning Line"; var BillToCustomerNo: Code[20]; var SellToCustomerNo: Code[20]; var CurrencyCode: Code[20]; var IsHandled: Boolean)
    begin
    end;
}

