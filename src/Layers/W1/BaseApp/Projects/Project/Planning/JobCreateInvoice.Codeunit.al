// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Planning;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.ExtendedText;
using Microsoft.Inventory.Ledger;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Resources.Ledger;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Setup;
using System.Reflection;
using System.Text;

codeunit 1002 "Job Create-Invoice"
{

    trigger OnRun()
    begin
    end;

    var
        Currency: Record Currency;
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempJobPlanningLine: Record "Job Planning Line" temporary;
        TempJobPlanningLine2: Record "Job Planning Line" temporary;
        TransferExtendedText: Codeunit "Transfer Extended Text";
        JobInvCurrency: Boolean;
        UpdateExchangeRates: Boolean;
        NoOfSalesLinesCreated: Integer;

#pragma warning disable AA0074
        Text000: Label 'The lines were successfully transferred to an invoice.';
        Text001: Label 'The lines were not transferred to an invoice.';
#pragma warning disable AA0470
        Text002: Label 'There was no %1 with a %2 larger than 0. No lines were transferred.';
        Text003: Label '%1 may not be lower than %2 and may not exceed %3.';
#pragma warning restore AA0470
        Text004: Label 'You must specify Invoice No. or New Invoice.';
        Text005: Label 'You must specify Credit Memo No. or New Invoice.';
#pragma warning disable AA0470
        Text007: Label 'You must specify %1.';
#pragma warning restore AA0470
        Text008: Label 'The lines were successfully transferred to a credit memo.';
#pragma warning disable AA0470
        Text009: Label 'The selected planning lines must have the same %1.';
#pragma warning restore AA0470
        Text010: Label 'The currency dates on all planning lines will be updated based on the invoice posting date because there is a difference in currency exchange rates. Recalculations will be based on the Exch. Calculation setup for the Cost and Price values for the project. Do you want to continue?';
        Text011: Label 'The currency exchange rate on all planning lines will be updated based on the exchange rate on the sales invoice. Do you want to continue?';
#pragma warning disable AA0470
        Text012: Label 'The %1 %2 does not exist anymore. A printed copy of the document was created before the document was deleted.', Comment = 'The Sales Invoice Header 103001 does not exist in the system anymore. A printed copy of the document was created before deletion.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure CreateSalesInvoice(var JobPlanningLine: Record "Job Planning Line"; CrMemo: Boolean)
    var
        Job: Record Job;
        JobPlanningLine2: Record "Job Planning Line";
        TempJobTask: Record "Job Task" temporary;
        GetSalesInvoiceNo: Report "Job Transfer to Sales Invoice";
        GetSalesCrMemoNo: Report "Job Transfer to Credit Memo";
        Done: Boolean;
        NewInvoice: Boolean;
        PostingDate: Date;
        DocumentDate: Date;
        InvoiceNo: Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnCreateSalesInvoiceOnBeforeRunReport(JobPlanningLine, Done, NewInvoice, PostingDate, InvoiceNo, IsHandled, CrMemo);
        if not IsHandled then
            if not CrMemo then begin
                GetSalesInvoiceNo.SetCustomer(JobPlanningLine);
                GetSalesInvoiceNo.RunModal();
                IsHandled := false;
                OnBeforeGetInvoiceNo(JobPlanningLine, Done, NewInvoice, PostingDate, InvoiceNo, IsHandled);
                if not IsHandled then
                    GetSalesInvoiceNo.GetInvoiceNo(Done, NewInvoice, PostingDate, DocumentDate, InvoiceNo);
            end else begin
                GetSalesCrMemoNo.SetCustomer(JobPlanningLine);
                GetSalesCrMemoNo.RunModal();
                IsHandled := false;
                OnBeforeGetCrMemoNo(JobPlanningLine, Done, NewInvoice, PostingDate, InvoiceNo, IsHandled);
                if not IsHandled then
                    GetSalesCrMemoNo.GetCreditMemoNo(Done, NewInvoice, PostingDate, DocumentDate, InvoiceNo);
            end;

        if Done then begin
            if (PostingDate = 0D) and NewInvoice then
                Error(Text007, SalesHeader.FieldCaption("Posting Date"));
            if (InvoiceNo = '') and not NewInvoice then begin
                if CrMemo then
                    Error(Text005);
                Error(Text004);
            end;

            Job.Get(JobPlanningLine."Job No.");
            if Job."Task Billing Method" = Job."Task Billing Method"::"One customer" then
                CreateSalesInvoiceLines(
                    JobPlanningLine."Job No.", JobPlanningLine, InvoiceNo, NewInvoice, PostingDate, DocumentDate, CrMemo)
            else begin
                TempJobTask.DeleteAll();
                JobPlanningLine2.Copy(JobPlanningLine);
                JobPlanningLine2.SetCurrentKey("Job No.", "Job Task No.");
                OnCreateSalesInvoiceOnBeforeFindJobPlanningLines(JobPlanningLine2);
                if JobPlanningLine2.FindSet() then
                    repeat
                        if not TempJobTask.Get(JobPlanningLine2."Job No.", JobPlanningLine2."Job Task No.") then begin
                            TempJobTask.Init();
                            TempJobTask."Job No." := JobPlanningLine2."Job No.";
                            TempJobTask."Job Task No." := JobPlanningLine2."Job Task No.";
                            TempJobTask.Insert();
                        end;
                    until JobPlanningLine2.Next() = 0;

                if TempJobTask.FindSet() then
                    repeat
                        JobPlanningLine.SetRange("Job No.", TempJobTask."Job No.");
                        JobPlanningLine.SetRange("Job Task No.", TempJobTask."Job Task No.");
                        JobPlanningLine.FindFirst();
                        CreateSalesInvoiceLines(JobPlanningLine."Job No.", JobPlanningLine, InvoiceNo, NewInvoice, PostingDate, DocumentDate, CrMemo);
                    until TempJobTask.Next() = 0;
            end;

            Commit();

            ShowMessageLinesTransferred(JobPlanningLine, CrMemo);
        end;
    end;

    local procedure ShowMessageLinesTransferred(JobPlanningLine: Record "Job Planning Line"; CrMemo: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowMessageLinesTransferred(JobPlanningLine, CrMemo, IsHandled);
        if IsHandled then
            exit;

        if CrMemo then
            Message(Text008)
        else
            Message(Text000);
    end;

    procedure CreateSalesInvoiceLines(JobNo: Code[20]; var JobPlanningLineSource: Record "Job Planning Line"; InvoiceNo: Code[20]; NewInvoice: Boolean; PostingDate: Date; DocumentDate: Date; CreditMemo: Boolean)
    var
        Job: Record Job;
        JobPlanningLine: Record "Job Planning Line";
        JobPlanningLineInvoice: Record "Job Planning Line Invoice";
        LineCounter: Integer;
        LastError: Text;
        SkipError: Boolean;
        SkipClear: Boolean;
        SkipCreateSalesLine: Boolean;
    begin
        SkipClear := false;
        OnBeforeCreateSalesInvoiceLines(JobPlanningLineSource, InvoiceNo, NewInvoice, PostingDate, CreditMemo, NoOfSalesLinesCreated, SkipClear);

        if not SkipClear then
            ClearAll();
        Job.Get(JobNo);
        OnCreateSalesInvoiceLinesOnBeforeTestJob(Job);
        if Job.Blocked = Job.Blocked::All then
            Job.TestBlocked();
        if Job."Currency Code" = '' then
            JobInvCurrency := IsJobInvCurrencyDependingOnBillingMethod(Job, JobPlanningLineSource);

        OnCreateSalesInvoiceLinesOnAfterSetJobInvCurrency(Job, JobInvCurrency);
        CheckJobBillToCustomer(JobPlanningLineSource, Job);

        if CreditMemo then
            SalesHeader2."Document Type" := SalesHeader2."Document Type"::"Credit Memo"
        else
            SalesHeader2."Document Type" := SalesHeader2."Document Type"::Invoice;

        OnCreateSalesInvoiceLinesOnAfterSetSalesDocumentType(SalesHeader2);

        if not NewInvoice then
            SalesHeader.Get(SalesHeader2."Document Type", InvoiceNo);

        OnCreateSalesInvoiceLinesOnBeforeJobPlanningLineCopy(Job, JobPlanningLineSource, PostingDate);
        JobPlanningLine.Copy(JobPlanningLineSource);
        JobPlanningLine.SetCurrentKey("Job No.", "Job Task No.", "Line No.");

        OnCreateSalesInvoiceLinesOnBeforeJobPlanningLineFindSet(JobPlanningLine, InvoiceNo, NewInvoice, PostingDate, CreditMemo);
        if JobPlanningLine.FindSet() then
            repeat
                if TransferLine(JobPlanningLine) then begin
                    LineCounter := LineCounter + 1;
                    if (JobPlanningLine."Job No." <> JobNo) and (not JobPlanningLineSource.GetSkipCheckForMultipleJobsOnSalesLine()) then
                        LastError := StrSubstNo(Text009, JobPlanningLine.FieldCaption("Job No."));
                    OnCreateSalesInvoiceLinesOnAfterValidateJobPlanningLine(JobPlanningLine, LastError);
                    if LastError <> '' then
                        Error(LastError);
                    if NewInvoice then
                        TestExchangeRate(JobPlanningLine, PostingDate)
                    else
                        TestExchangeRate(JobPlanningLine, SalesHeader."Posting Date");
                end;
            until JobPlanningLine.Next() = 0;

        if LineCounter = 0 then
            Error(Text002,
              JobPlanningLine.TableCaption(),
              JobPlanningLine.FieldCaption("Qty. to Transfer to Invoice"));

        if NewInvoice then
            CreateSalesHeader(Job, JobPlanningLine, PostingDate, DocumentDate)
        else
            TestSalesHeader(SalesHeader, Job, JobPlanningLine);
        if JobPlanningLine.Find('-') then
            repeat
                if TransferLine(JobPlanningLine) then begin
                    if JobPlanningLine.Type in [JobPlanningLine.Type::Resource,
                                                JobPlanningLine.Type::Item,
                                                JobPlanningLine.Type::"G/L Account"]
                    then
                        JobPlanningLine.TestField("No.");

                    SkipCreateSalesLine := false;
                    OnCreateSalesInvoiceLinesOnBeforeCreateSalesLine(
                      JobPlanningLine, SalesHeader, SalesHeader2, NewInvoice, NoOfSalesLinesCreated, SkipCreateSalesLine);

                    if not SkipCreateSalesLine then
                        CreateSalesLine(JobPlanningLine);

                    JobPlanningLineInvoice.InitFromJobPlanningLine(JobPlanningLine);
                    if NewInvoice then
                        JobPlanningLineInvoice.InitFromSales(SalesHeader, PostingDate, SalesLine."Line No.")
                    else
                        JobPlanningLineInvoice.InitFromSales(SalesHeader, SalesHeader."Posting Date", SalesLine."Line No.");

                    OnCreateSalesInvoiceLinesOnBeforeJobPlanningLineInvoiceInsert(JobPlanningLineInvoice);
                    JobPlanningLineInvoice.Insert();

                    JobPlanningLine.UpdateQtyToTransfer();
                    OnCreateSalesInvoiceLinesOnBeforeJobPlanningLineModify(JobPlanningLine);
                    JobPlanningLine.Modify();
                end;
            until JobPlanningLine.Next() = 0;

        JobPlanningLineSource.Get(
          JobPlanningLineSource."Job No.", JobPlanningLineSource."Job Task No.", JobPlanningLineSource."Line No.");
        JobPlanningLineSource.CalcFields("Qty. Transferred to Invoice");

        SkipError := false;
        OnCreateSalesInvoiceLinesOnBeforeNoSalesLineCreatedError(SkipError);
        if not SkipError then
            if NoOfSalesLinesCreated = 0 then
                Error(Text002, JobPlanningLine.TableCaption(), JobPlanningLine.FieldCaption("Qty. to Transfer to Invoice"));

        OnAfterCreateSalesInvoiceLines(SalesHeader, NewInvoice);
    end;

    local procedure CheckJobBillToCustomer(var JobPlanningLineSource: Record "Job Planning Line"; Job: Record Job)
    var
        JobTask: Record "Job Task";
        Cust: Record Customer;
        BillToCustomerNo: Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckJobBillToCustomer(JobPlanningLineSource, Job, IsHandled);
        if IsHandled then
            exit;
        if Job."Task Billing Method" = Job."Task Billing Method"::"One customer" then begin
            Job.TestField("Bill-to Customer No.");
            BillToCustomerNo := Job."Bill-to Customer No.";
        end else begin
            JobTask.Get(JobPlanningLineSource."Job No.", JobPlanningLineSource."Job Task No.");
            JobTask.TestField("Bill-to Customer No.");
            BillToCustomerNo := JobTask."Bill-to Customer No.";
        end;
        Cust.Get(BillToCustomerNo);
    end;

    procedure DeleteSalesInvoiceBuffer()
    begin
        ClearAll();
        TempJobPlanningLine.DeleteAll();
    end;

    procedure CreateSalesInvoiceJobTask(var JobTask2: Record "Job Task"; PostingDate: Date; DocumentDate: Date; InvoicePerTask: Boolean; var NoOfInvoices: Integer; var OldJobNo: Code[20]; var OldJobTaskNo: Code[20]; LastJobTask: Boolean)
    var
        Cust: Record Customer;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobPlanningLineInvoice: Record "Job Planning Line Invoice";
        IsHandled: Boolean;
        GroupMultipleCustomer: Boolean;
        InvoicePerProjectTask: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateSalesInvoiceJobTask(
          JobTask2, PostingDate, InvoicePerTask, NoOfInvoices, OldJobNo, OldJobTaskNo, LastJobTask, IsHandled);
        if IsHandled then
            exit;

        ClearAll();
        if not LastJobTask then begin
            JobTask := JobTask2;
            if JobTask."Job No." = '' then
                exit;
            if JobTask."Job Task No." = '' then
                exit;
            JobTask.Find();
            if JobTask."Job Task Type" <> JobTask."Job Task Type"::Posting then
                exit;
            Job.Get(JobTask."Job No.");
        end;
        if LastJobTask then begin
            if not TempJobPlanningLine.Find('-') then
                exit;
            Job.Get(TempJobPlanningLine."Job No.");
            JobTask.Get(TempJobPlanningLine."Job No.", TempJobPlanningLine."Job Task No.");
        end;

        OnCreateSalesInvoiceJobTaskTestJob(Job, JobPlanningLine, PostingDate);
        TestIfBillToCustomerExistOnJobOrJobTask(Job, JobTask2);
        if Job.Blocked = Job.Blocked::All then
            Job.TestBlocked();
        if Job."Currency Code" = '' then
            JobInvCurrency := IsJobInvCurrencyDependingOnBillingMethod(Job, JobTask2);
        Cust.Get(ReturnBillToCustomerNoDependingOnTaskBillingMethod(Job, JobTask2));

        if InvoicePerTask or (Job."Task Billing Method" = Job."Task Billing Method"::"Multiple customers") then
            InvoicePerProjectTask := true;

        if CreateNewInvoice(JobTask, InvoicePerProjectTask, OldJobNo, OldJobTaskNo, LastJobTask) then begin
            Job.Get(TempJobPlanningLine."Job No.");

            if (Job."Task Billing Method" = Job."Task Billing Method"::"Multiple customers") and InvoicePerTask then
                GroupMultipleCustomer := true;

            Cust.Get(ReturnBillToCustomerNoDependingOnTaskBillingMethod(Job, JobTask2));
            SalesHeader2."Document Type" := SalesHeader2."Document Type"::Invoice;
            if not SalesInvoiceExistForMultipleCustomerBillingMethod(Job, GroupMultipleCustomer) then begin
                CreateSalesHeader(Job, TempJobPlanningLine, PostingDate, DocumentDate);
                NoOfInvoices := NoOfInvoices + 1;
            end;
            OnCreateSalesInvoiceJobTaskOnBeforeTempJobPlanningLineFind(JobTask, SalesHeader, InvoicePerTask, TempJobPlanningLine);
            if TempJobPlanningLine.Find('-') then
                repeat
                    Job.Get(TempJobPlanningLine."Job No.");
                    JobInvCurrency := (Job."Currency Code" = '') and IsJobInvCurrencyDependingOnBillingMethod(Job, TempJobPlanningLine);
                    JobPlanningLine := TempJobPlanningLine;
                    JobPlanningLine.Find();
                    if JobPlanningLine.Type in [JobPlanningLine.Type::Resource,
                                                JobPlanningLine.Type::Item,
                                                JobPlanningLine.Type::"G/L Account"]
                    then
                        JobPlanningLine.TestField("No.");
                    TestExchangeRate(JobPlanningLine, PostingDate);

                    OnCreateSalesInvoiceJobTaskOnBeforeCreateSalesLine(JobPlanningLine, SalesHeader, SalesHeader2, NoOfSalesLinesCreated);
                    CreateSalesLine(JobPlanningLine);

                    JobPlanningLineInvoice."Job No." := JobPlanningLine."Job No.";
                    JobPlanningLineInvoice."Job Task No." := JobPlanningLine."Job Task No.";
                    JobPlanningLineInvoice."Job Planning Line No." := JobPlanningLine."Line No.";
                    if SalesHeader."Document Type" = SalesHeader."Document Type"::Invoice then
                        JobPlanningLineInvoice."Document Type" := JobPlanningLineInvoice."Document Type"::Invoice;
                    if SalesHeader."Document Type" = SalesHeader."Document Type"::"Credit Memo" then
                        JobPlanningLineInvoice."Document Type" := JobPlanningLineInvoice."Document Type"::"Credit Memo";
                    JobPlanningLineInvoice."Document No." := SalesHeader."No.";
                    JobPlanningLineInvoice."Line No." := SalesLine."Line No.";
                    JobPlanningLineInvoice."Quantity Transferred" := JobPlanningLine."Qty. to Transfer to Invoice";
                    JobPlanningLineInvoice."Transferred Date" := PostingDate;
                    OnCreateSalesInvoiceJobTaskOnBeforeJobPlanningLineInvoiceInsert(JobPlanningLineInvoice);
                    JobPlanningLineInvoice.Insert();

                    JobPlanningLine.UpdateQtyToTransfer();
                    JobPlanningLine.Modify();
                until TempJobPlanningLine.Next() = 0;
            TempJobPlanningLine.DeleteAll();
        end;

        OnCreateSalesInvoiceJobTaskOnAfterLinesCreated(SalesHeader, Job, InvoicePerTask, LastJobTask);

        if LastJobTask then begin
            if NoOfSalesLinesCreated = 0 then
                Error(Text002, JobPlanningLine.TableCaption(), JobPlanningLine.FieldCaption("Qty. to Transfer to Invoice"));
            exit;
        end;

        JobPlanningLine.Reset();
        JobPlanningLine.SetCurrentKey("Job No.", "Job Task No.");
        JobPlanningLine.SetRange("Job No.", JobTask2."Job No.");
        JobPlanningLine.SetRange("Job Task No.", JobTask2."Job Task No.");
        JobPlanningLine.SetFilter("Planning Date", JobTask2.GetFilter("Planning Date Filter"));
        OnCreateSalesInvoiceJobTaskOnAfterJobPlanningLineSetFilters(JobPlanningLine, JobTask2);
        if JobPlanningLine.Find('-') then
            repeat
                if TransferLine(JobPlanningLine) then begin
                    TempJobPlanningLine := JobPlanningLine;
                    TempJobPlanningLine.Insert();

                    if Job."Task Billing Method" = Job."Task Billing Method"::"Multiple customers" then begin
                        TempJobPlanningLine2 := JobPlanningLine;
                        TempJobPlanningLine2.Insert();
                    end;
                end;
            until JobPlanningLine.Next() = 0;
    end;

    procedure CreateNewInvoice(var JobTask: Record "Job Task"; InvoicePerTask: Boolean; var OldJobNo: Code[20]; var OldJobTaskNo: Code[20]; LastJobTask: Boolean): Boolean
    var
        NewInvoice: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateNewInvoice(JobTask, InvoicePerTask, OldJobNo, OldJobTaskNo, LastJobTask, NewInvoice, IsHandled, TempJobPlanningLine);
        if IsHandled then
            exit(NewInvoice);

        if LastJobTask then
            NewInvoice := true
        else begin
            if OldJobNo <> '' then begin
                if InvoicePerTask then
                    if (OldJobNo <> JobTask."Job No.") or (OldJobTaskNo <> JobTask."Job Task No.") then
                        NewInvoice := true;
                if not InvoicePerTask then
                    if OldJobNo <> JobTask."Job No." then
                        NewInvoice := true;
            end;
            OldJobNo := JobTask."Job No.";
            OldJobTaskNo := JobTask."Job Task No.";
        end;
        if not TempJobPlanningLine.Find('-') then
            NewInvoice := false;
        exit(NewInvoice);
    end;

    procedure CreateSalesHeader(Job: Record Job; JobPlanningLine: Record "Job Planning Line"; PostingDate: Date; DocumentDate: Date)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        JobTask: Record "Job Task";
        IsHandled: Boolean;
    begin
        OnBeforeCreateSalesHeader(Job, PostingDate, SalesHeader2, JobPlanningLine);

        SalesReceivablesSetup.SetLoadFields("Invoice Nos.", "Credit Memo Nos.");
        SalesReceivablesSetup.Get();
        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader2."Document Type";
        if SalesHeader."Document Type" = SalesHeader."Document Type"::Invoice then
            SalesReceivablesSetup.TestField("Invoice Nos.");
        if SalesHeader."Document Type" = SalesHeader."Document Type"::"Credit Memo" then
            SalesReceivablesSetup.TestField("Credit Memo Nos.");
        SalesHeader."Posting Date" := PostingDate;
        SalesHeader."Document Date" := DocumentDate;
        OnBeforeInsertSalesHeader(SalesHeader, Job, JobPlanningLine);
        SalesHeader.Insert(true);

        IsHandled := false;
        OnCreateSalesHeaderOnBeforeCheckBillToCustomerNo(SalesHeader, Job, JobPlanningLine, IsHandled);

        if not IsHandled then begin
            SalesHeader.SetHideValidationDialog(true);
            SalesHeader.Validate("Sell-to Customer No.", GetCustomerNo(Job, JobPlanningLine, true));
            SalesHeader.Validate("Bill-to Customer No.", GetCustomerNo(Job, JobPlanningLine, false));
        end;

        if Job."Task Billing Method" = Job."Task Billing Method"::"One customer" then begin
            if Job."Payment Method Code" <> '' then
                SalesHeader.Validate("Payment Method Code", Job."Payment Method Code");
            if Job."Payment Terms Code" <> '' then
                SalesHeader.Validate("Payment Terms Code", Job."Payment Terms Code");
            if Job."External Document No." <> '' then
                SalesHeader.Validate("External Document No.", Job."External Document No.");
        end else begin
            JobTask.SetLoadFields("Payment Method Code", "Payment Terms Code", "External Document No.");
            JobTask.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.");
            if JobTask."Payment Method Code" <> '' then
                SalesHeader.Validate("Payment Method Code", JobTask."Payment Method Code");
            if JobTask."Payment Terms Code" <> '' then
                SalesHeader.Validate("Payment Terms Code", JobTask."Payment Terms Code");
            if JobTask."External Document No." <> '' then
                SalesHeader.Validate("External Document No.", JobTask."External Document No.");
        end;

        if Job."Currency Code" <> '' then
            SalesHeader.Validate("Currency Code", Job."Currency Code")
        else
            SalesHeader.Validate("Currency Code", ReturnJobDataDependingOnTaskBillingMethod(Job, JobPlanningLine, 'Invoice Currency Code'));

        if PostingDate <> 0D then
            SalesHeader.Validate("Posting Date", PostingDate);
        if DocumentDate <> 0D then
            SalesHeader.Validate("Document Date", DocumentDate);

        SalesHeader."Your Reference" := ReturnJobDataDependingOnTaskBillingMethod(Job, JobPlanningLine, 'Your Reference');

        if SalesHeader."Document Type" = SalesHeader."Document Type"::Invoice then
            SalesHeader.SetDefaultPaymentServices();

        IsHandled := false;
        OnCreateSalesHeaderOnBeforeUpdateSalesHeader(SalesHeader, Job, IsHandled, JobPlanningLine);
        if not IsHandled then
            if Job."Task Billing Method" = Job."Task Billing Method"::"One customer" then
                UpdateSalesHeader(SalesHeader, Job)
            else
                UpdateSalesHeader(SalesHeader, JobPlanningLine);
        OnBeforeModifySalesHeader(SalesHeader, Job, JobPlanningLine);
        SalesHeader.Modify(true);
    end;

    local procedure SalesInvoiceExistForMultipleCustomerBillingMethod(Job: Record Job; InvoicePerTask: Boolean): Boolean
    var
        JobTask: Record "Job Task";
        JobTask2: Record "Job Task";
        JobPlanningLineInvoice: Record "Job Planning Line Invoice";
        TempJobPlanningLine3: Record "Job Planning Line" temporary;
        SelectionFilterMgt: Codeunit SelectionFilterManagement;
        RecRef: RecordRef;
        JobTaskFilter: Text;
        ExitValue: Boolean;
        IsHandled: Boolean;
    begin
        if (Job."Task Billing Method" = Job."Task Billing Method"::"One customer") or
            InvoicePerTask then
            exit;

        TempJobPlanningLine3.Copy(TempJobPlanningLine2, true);
        TempJobPlanningLine3.Reset();
        TempJobPlanningLine3.SetFilter("Job Contract Entry No.", '<>%1', TempJobPlanningLine."Job Contract Entry No.");
        RecRef.GetTable(TempJobPlanningLine3);
        JobTaskFilter := SelectionFilterMgt.GetSelectionFilter(RecRef, TempJobPlanningLine3.FieldNo("Job Task No."));
        if JobTaskFilter = '' then
            exit;

        if JobTask.Get(TempJobPlanningLine."Job No.", TempJobPlanningLine."Job Task No.") then begin
            JobTask2.SetRange("Job No.", Job."No.");
            JobTask2.SetFilter("Job Task No.", JobTaskFilter);
            JobTask2.SetRange("Sell-to Customer No.", JobTask."Sell-to Customer No.");
            JobTask2.SetRange("Bill-to Customer No.", JobTask."Bill-to Customer No.");
            JobTask2.SetRange("Invoice Currency Code", JobTask."Invoice Currency Code");
            if JobTask2.FindFirst() then begin
                JobPlanningLineInvoice.SetRange("Job No.", Job."No.");
                JobPlanningLineInvoice.SetRange("Job Task No.", JobTask2."Job Task No.");
                JobPlanningLineInvoice.SetRange("Document Type", JobPlanningLineInvoice."Document Type"::Invoice);
                OnBeforeFindJobPlanningLineInvoice(JobTask, JobPlanningLineInvoice, SalesHeader, ExitValue, Ishandled);
                if IsHandled then
                    exit(ExitValue);
                if JobPlanningLineInvoice.FindFirst() then begin
                    SalesHeader.Get(SalesHeader."Document Type"::Invoice, JobPlanningLineInvoice."Document No.");
                    exit(true);
                end;
            end;
        end;
    end;

    local procedure GetCustomerNo(Job: Record Job; JobPlanningLine: Record "Job Planning Line"; SellToCustomerNo: Boolean) CustomerNo: Code[20]
    var
        JobTask: Record "Job Task";
    begin
        OnBeforeGetCustomerNo(Job, JobPlanningLine, SellToCustomerNo, CustomerNo);
        if CustomerNo <> '' then
            exit(CustomerNo);

        if Job."Task Billing Method" = Job."Task Billing Method"::"One customer" then
            if SellToCustomerNo then
                exit(Job."Sell-to Customer No.")
            else
                exit(Job."Bill-to Customer No.");

        JobTask.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.");
        if SellToCustomerNo then
            exit(JobTask."Sell-to Customer No.")
        else
            exit(JobTask."Bill-to Customer No.");
    end;

    procedure CreateSalesLine(var JobPlanningLine: Record "Job Planning Line")
    var
        Job: Record Job;
        Factor: Integer;
        IsHandled: Boolean;
        ShouldUpdateCurrencyFactor: Boolean;
    begin
        OnBeforeCreateSalesLine(JobPlanningLine, SalesHeader, SalesHeader2, JobInvCurrency);

        Factor := 1;
        if SalesHeader2."Document Type" = SalesHeader2."Document Type"::"Credit Memo" then
            Factor := -1;
        TestTransferred(JobPlanningLine);
        JobPlanningLine.TestField("Planning Date");
        Job.Get(JobPlanningLine."Job No.");
        Clear(SalesLine);
        SalesLine."Document Type" := SalesHeader2."Document Type";
        SalesLine."Document No." := SalesHeader."No.";

        ShouldUpdateCurrencyFactor := (not JobInvCurrency) and (JobPlanningLine.Type <> JobPlanningLine.Type::Text);
        OnCreateSalesLineOnAfterCalcShouldUpdateCurrencyFactor(JobPlanningLine, Job, SalesHeader, SalesHeader2, JobInvCurrency, ShouldUpdateCurrencyFactor);
        if ShouldUpdateCurrencyFactor then begin
            SalesHeader.TestField("Currency Code", JobPlanningLine."Currency Code");
            if (Job."Currency Code" <> '') and (JobPlanningLine."Currency Factor" <> SalesHeader."Currency Factor") then
                if Confirm(Text011) then begin
                    JobPlanningLine.Validate("Currency Factor", SalesHeader."Currency Factor");
                    JobPlanningLine.Modify();
                end else
                    Error(Text001);
            SalesHeader.TestField("Currency Code", Job."Currency Code");
        end;
        if JobPlanningLine.Type = JobPlanningLine.Type::Text then
            SalesLine.Validate(Type, SalesLine.Type::" ");
        if JobPlanningLine.Type = JobPlanningLine.Type::"G/L Account" then
            SalesLine.Validate(Type, SalesLine.Type::"G/L Account");
        if JobPlanningLine.Type = JobPlanningLine.Type::Item then
            SalesLine.Validate(Type, SalesLine.Type::Item);
        if JobPlanningLine.Type = JobPlanningLine.Type::Resource then
            SalesLine.Validate(Type, SalesLine.Type::Resource);


        IsHandled := false;
        OnCreateSalesLineOnBeforeValidateSalesLineNo(JobPlanningLine, SalesLine, IsHandled);
        if not IsHandled then
            SalesLine.Validate("No.", JobPlanningLine."No.");
        SalesLine.Validate("Gen. Prod. Posting Group", JobPlanningLine."Gen. Prod. Posting Group");
        SalesLine.Validate("Location Code", JobPlanningLine."Location Code");
        SalesLine.Validate("Work Type Code", JobPlanningLine."Work Type Code");
        SalesLine.Validate("Variant Code", JobPlanningLine."Variant Code");

        if SalesLine.Type <> SalesLine.Type::" " then begin
            SalesLine.Validate("Unit of Measure Code", JobPlanningLine."Unit of Measure Code");
            SalesLine.Validate(Quantity, Factor * JobPlanningLine."Qty. to Transfer to Invoice");
            if JobPlanningLine."Bin Code" <> '' then
                SalesLine."Bin Code" := JobPlanningLine."Bin Code";
            if JobInvCurrency then begin
                OnCreateSalesLineOnBeforeValidateCurrencyCode(IsHandled, SalesLine, JobPlanningLine);
                if not IsHandled then begin
                    Currency.Get(SalesLine."Currency Code");
                    SalesLine.Validate("Unit Price",
                    Round(JobPlanningLine."Unit Price" * SalesHeader."Currency Factor",
                        Currency."Unit-Amount Rounding Precision"));
                end;
            end else
                SalesLine.Validate("Unit Price", JobPlanningLine."Unit Price");
            SalesLine.Validate("Unit Cost (LCY)", JobPlanningLine."Unit Cost (LCY)");
            SalesLine.Validate("Line Discount %", JobPlanningLine."Line Discount %");
            SalesLine."Inv. Discount Amount" := 0;
            SalesLine."Inv. Disc. Amount to Invoice" := 0;
            SalesLine.UpdateAmounts();
        end;

        IsHandled := false;
        OnCreateSalesLineOnBeforeCheckPricesIncludingVATAndSetJobInformation(SalesLine, JobPlanningLine, IsHandled);
        if not IsHandled then begin
            if not SalesHeader."Prices Including VAT" then
                SalesLine.Validate("Job Contract Entry No.", JobPlanningLine."Job Contract Entry No.");
            SalesLine."Job No." := JobPlanningLine."Job No.";
            SalesLine."Job Task No." := JobPlanningLine."Job Task No.";
        end;
        SalesLine.Description := JobPlanningLine.Description;
        SalesLine."Description 2" := JobPlanningLine."Description 2";
        SalesLine."Line No." := GetNextLineNo(SalesLine);
        OnBeforeInsertSalesLine(SalesLine, SalesHeader, Job, JobPlanningLine, JobInvCurrency);
        SalesLine.Insert(true);

        if SalesLine.Type <> SalesLine.Type::" " then begin
            NoOfSalesLinesCreated += 1;
            CalculateInvoiceDiscount(SalesLine, SalesHeader);
        end;

        if SalesHeader."Prices Including VAT" and (SalesLine.Type <> SalesLine.Type::" ") then begin
            Currency.Initialize(SalesLine."Currency Code");
            SalesLine."Unit Price" :=
              Round(
                SalesLine."Unit Price" * (1 + (SalesLine."VAT %" / 100)),
                Currency."Unit-Amount Rounding Precision");
            if SalesLine.Quantity <> 0 then begin
                SalesLine."Line Discount Amount" :=
                  Round(
                    SalesLine.Quantity * SalesLine."Unit Price" * SalesLine."Line Discount %" / 100,
                    Currency."Amount Rounding Precision");
                SalesLine.Validate("Inv. Discount Amount",
                  Round(
                    SalesLine."Inv. Discount Amount" * (1 + (SalesLine."VAT %" / 100)),
                    Currency."Amount Rounding Precision"));
            end;
            SalesLine.Validate("Job Contract Entry No.", JobPlanningLine."Job Contract Entry No.");
            OnBeforeModifySalesLine(SalesLine, SalesHeader, Job, JobPlanningLine);
            SalesLine.Modify();
            OnCreateSalesLineOnAfterSalesLineModify(SalesLine, SalesHeader, Job, JobPlanningLine);
            JobPlanningLine."VAT Unit Price" := SalesLine."Unit Price";
            JobPlanningLine."VAT Line Discount Amount" := SalesLine."Line Discount Amount";
            JobPlanningLine."VAT Line Amount" := SalesLine."Line Amount";
            JobPlanningLine."VAT %" := SalesLine."VAT %";
        end;
        if SalesLine."Job Task No." <> '' then
            UpdateSalesLineDimension(SalesLine, JobPlanningLine);

        IsHandled := false;
        OnCreateSalesLineOnBeforeSalesCheckIfAnyExtText(JobPlanningLine, SalesLine, IsHandled);
        if not IsHandled then
            if TransferExtendedText.SalesCheckIfAnyExtText(SalesLine, false) then
                TransferExtendedText.InsertSalesExtText(SalesLine);

        OnAfterCreateSalesLine(SalesLine, SalesHeader, Job, JobPlanningLine);
    end;

    local procedure CalculateInvoiceDiscount(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    var
        TotalSalesHeader: Record "Sales Header";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        TotalSalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        TotalSalesHeader.CalcFields("Recalculate Invoice Disc.");

        SalesReceivablesSetup.Get();
        if SalesReceivablesSetup."Calc. Inv. Discount" and
           (SalesLine."Document No." <> '') and
           (TotalSalesHeader."Customer Posting Group" <> '') and
           TotalSalesHeader."Recalculate Invoice Disc."
        then
            Codeunit.Run(Codeunit::"Sales-Calc. Discount", SalesLine);
    end;

    procedure TransferLine(var JobPlanningLine: Record "Job Planning Line"): Boolean
    var
        IsHandled, Result : Boolean;
    begin
        IsHandled := false;
        OnBeforeTransferLine(JobPlanningLine, IsHandled, Result);
        if IsHandled then
            exit(Result);

        if not JobPlanningLine."Contract Line" then
            exit(false);
        if JobPlanningLine.Type = JobPlanningLine.Type::Text then
            exit(true);
        exit(JobPlanningLine."Qty. to Transfer to Invoice" <> 0);
    end;

    local procedure GetNextLineNo(SalesLine: Record "Sales Line"): Integer
    var
        NextLineNo: Integer;
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type");
        SalesLine.SetRange("Document No.", SalesLine."Document No.");
        NextLineNo := 10000;
        if SalesLine.FindLast() then
            NextLineNo := SalesLine."Line No." + 10000;
        exit(NextLineNo);
    end;

    local procedure TestTransferred(JobPlanningLine: Record "Job Planning Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestTransferred(JobPlanningLine, SalesHeader2, IsHandled);
        if IsHandled then
            exit;

        JobPlanningLine.CalcFields("Qty. Transferred to Invoice");
        if JobPlanningLine.Quantity > 0 then begin
            if (JobPlanningLine."Qty. to Transfer to Invoice" > 0) and (JobPlanningLine."Qty. to Transfer to Invoice" > (JobPlanningLine.Quantity - JobPlanningLine."Qty. Transferred to Invoice")) or
                (JobPlanningLine."Qty. to Transfer to Invoice" < 0)
            then
                Error(Text003, JobPlanningLine.FieldCaption("Qty. to Transfer to Invoice"), 0, JobPlanningLine.Quantity - JobPlanningLine."Qty. Transferred to Invoice");
        end else
            if (JobPlanningLine."Qty. to Transfer to Invoice" > 0) or
                (JobPlanningLine."Qty. to Transfer to Invoice" < 0) and (JobPlanningLine."Qty. to Transfer to Invoice" < (JobPlanningLine.Quantity - JobPlanningLine."Qty. Transferred to Invoice"))
            then
                Error(Text003, JobPlanningLine.FieldCaption("Qty. to Transfer to Invoice"), JobPlanningLine.Quantity - JobPlanningLine."Qty. Transferred to Invoice", 0);
    end;

    procedure DeleteSalesLine(SalesLine: Record "Sales Line")
    var
        JobPlanningLineInvoice: Record "Job Planning Line Invoice";
        JobPlanningLine: Record "Job Planning Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeleteSalesLine(SalesLine, IsHandled);
        if IsHandled then
            exit;

        case SalesLine."Document Type" of
            SalesLine."Document Type"::Invoice:
                JobPlanningLineInvoice.SetRange("Document Type", JobPlanningLineInvoice."Document Type"::Invoice);
            SalesLine."Document Type"::"Credit Memo":
                JobPlanningLineInvoice.SetRange("Document Type", JobPlanningLineInvoice."Document Type"::"Credit Memo");
        end;
        JobPlanningLineInvoice.SetRange("Document No.", SalesLine."Document No.");
        JobPlanningLineInvoice.SetRange("Line No.", SalesLine."Line No.");
        if JobPlanningLineInvoice.FindSet() then
            repeat
                OnDeleteSalesLineOnBeforeGetJobPlanningLine(JobPlanningLineInvoice);
                JobPlanningLine.Get(JobPlanningLineInvoice."Job No.", JobPlanningLineInvoice."Job Task No.", JobPlanningLineInvoice."Job Planning Line No.");
                JobPlanningLineInvoice.Delete();
                JobPlanningLine.UpdateQtyToTransfer();
                OnDeleteSalesLineOnBeforeJobPlanningLineModify(JobPlanningLine);
                JobPlanningLine.Modify();
            until JobPlanningLineInvoice.Next() = 0;
    end;

    procedure FindInvoices(var TempJobPlanningLineInvoice: Record "Job Planning Line Invoice" temporary; JobNo: Code[20]; JobTaskNo: Code[20]; JobPlanningLineNo: Integer; DetailLevel: Option All,"Per Job","Per Job Task","Per Job Planning Line")
    var
        JobPlanningLineInvoice: Record "Job Planning Line Invoice";
        RecordFound: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeFindInvoices(TempJobPlanningLineInvoice, JobNo, JobTaskNo, JobPlanningLineNo, DetailLevel, IsHandled);
        if IsHandled then
            exit;

        case DetailLevel of
            DetailLevel::All:
                begin
                    if JobPlanningLineInvoice.FindSet() then
                        TempJobPlanningLineInvoice := JobPlanningLineInvoice;
                    exit;
                end;
            DetailLevel::"Per Job":
                JobPlanningLineInvoice.SetRange("Job No.", JobNo);
            DetailLevel::"Per Job Task":
                begin
                    JobPlanningLineInvoice.SetRange("Job No.", JobNo);
                    JobPlanningLineInvoice.SetRange("Job Task No.", JobTaskNo);
                end;
            DetailLevel::"Per Job Planning Line":
                begin
                    JobPlanningLineInvoice.SetRange("Job No.", JobNo);
                    JobPlanningLineInvoice.SetRange("Job Task No.", JobTaskNo);
                    JobPlanningLineInvoice.SetRange("Job Planning Line No.", JobPlanningLineNo);
                end;
        end;

        TempJobPlanningLineInvoice.DeleteAll();
        if JobPlanningLineInvoice.FindSet() then
            repeat
                RecordFound := false;
                case DetailLevel of
                    DetailLevel::"Per Job":
                        if TempJobPlanningLineInvoice.Get(
                             JobNo, '', 0, JobPlanningLineInvoice."Document Type", JobPlanningLineInvoice."Document No.", 0)
                        then
                            RecordFound := true;
                    DetailLevel::"Per Job Task":
                        if TempJobPlanningLineInvoice.Get(
                             JobNo, JobTaskNo, 0, JobPlanningLineInvoice."Document Type", JobPlanningLineInvoice."Document No.", 0)
                        then
                            RecordFound := true;
                    DetailLevel::"Per Job Planning Line":
                        if TempJobPlanningLineInvoice.Get(
                             JobNo, JobTaskNo, JobPlanningLineNo, JobPlanningLineInvoice."Document Type", JobPlanningLineInvoice."Document No.", 0)
                        then
                            RecordFound := true;
                end;

                if RecordFound then begin
                    TempJobPlanningLineInvoice."Quantity Transferred" += JobPlanningLineInvoice."Quantity Transferred";
                    TempJobPlanningLineInvoice."Invoiced Amount (LCY)" += JobPlanningLineInvoice."Invoiced Amount (LCY)";
                    TempJobPlanningLineInvoice."Invoiced Cost Amount (LCY)" += JobPlanningLineInvoice."Invoiced Cost Amount (LCY)";
                    OnFindInvoicesOnBeforeTempJobPlanningLineInvoiceModify(TempJobPlanningLineInvoice, JobPlanningLineInvoice);
                    TempJobPlanningLineInvoice.Modify();
                end else begin
                    case DetailLevel of
                        DetailLevel::"Per Job":
                            TempJobPlanningLineInvoice."Job No." := JobNo;
                        DetailLevel::"Per Job Task":
                            begin
                                TempJobPlanningLineInvoice."Job No." := JobNo;
                                TempJobPlanningLineInvoice."Job Task No." := JobTaskNo;
                            end;
                        DetailLevel::"Per Job Planning Line":
                            begin
                                TempJobPlanningLineInvoice."Job No." := JobNo;
                                TempJobPlanningLineInvoice."Job Task No." := JobTaskNo;
                                TempJobPlanningLineInvoice."Job Planning Line No." := JobPlanningLineNo;
                            end;
                    end;
                    TempJobPlanningLineInvoice."Document Type" := JobPlanningLineInvoice."Document Type";
                    TempJobPlanningLineInvoice."Document No." := JobPlanningLineInvoice."Document No.";
                    TempJobPlanningLineInvoice."Quantity Transferred" := JobPlanningLineInvoice."Quantity Transferred";
                    TempJobPlanningLineInvoice."Invoiced Amount (LCY)" := JobPlanningLineInvoice."Invoiced Amount (LCY)";
                    TempJobPlanningLineInvoice."Invoiced Cost Amount (LCY)" := JobPlanningLineInvoice."Invoiced Cost Amount (LCY)";
                    TempJobPlanningLineInvoice."Invoiced Date" := JobPlanningLineInvoice."Invoiced Date";
                    TempJobPlanningLineInvoice."Transferred Date" := JobPlanningLineInvoice."Transferred Date";
                    OnFindInvoicesOnBeforeTempJobPlanningLineInvoiceInsert(TempJobPlanningLineInvoice, JobPlanningLineInvoice);
                    TempJobPlanningLineInvoice.Insert();
                end;
            until JobPlanningLineInvoice.Next() = 0;
    end;

    procedure GetJobPlanningLineInvoices(JobPlanningLine: Record "Job Planning Line")
    var
        JobPlanningLineInvoice: Record "Job Planning Line Invoice";
    begin
        OnBeforeGetJobPlanningLineInvoices(JobPlanningLine);

        ClearAll();
        if JobPlanningLine."Line No." = 0 then
            exit;

        JobPlanningLine.TestField("Job No.");
        JobPlanningLine.TestField("Job Task No.");

        JobPlanningLineInvoice.SetRange("Job No.", JobPlanningLine."Job No.");
        JobPlanningLineInvoice.SetRange("Job Task No.", JobPlanningLine."Job Task No.");
        JobPlanningLineInvoice.SetRange("Job Planning Line No.", JobPlanningLine."Line No.");
        if JobPlanningLineInvoice.Count = 1 then begin
            JobPlanningLineInvoice.FindFirst();
            OpenSalesInvoice(JobPlanningLineInvoice);
        end else
            Page.RunModal(Page::"Job Invoices", JobPlanningLineInvoice);
    end;

    procedure OpenSalesInvoice(JobPlanningLineInvoice: Record "Job Planning Line Invoice")
    var
        SalesHeader: Record "Sales Header";
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOpenSalesInvoice(JobPlanningLineInvoice, IsHandled);
        if IsHandled then
            exit;

        case JobPlanningLineInvoice."Document Type" of
            JobPlanningLineInvoice."Document Type"::Invoice:
                begin
                    SalesHeader.Get(SalesHeader."Document Type"::Invoice, JobPlanningLineInvoice."Document No.");
                    PAGE.RunModal(PAGE::"Sales Invoice", SalesHeader);
                end;
            JobPlanningLineInvoice."Document Type"::"Credit Memo":
                begin
                    SalesHeader.Get(SalesHeader."Document Type"::"Credit Memo", JobPlanningLineInvoice."Document No.");
                    PAGE.RunModal(PAGE::"Sales Credit Memo", SalesHeader);
                end;
            JobPlanningLineInvoice."Document Type"::"Posted Invoice":
                begin
                    if not SalesInvHeader.Get(JobPlanningLineInvoice."Document No.") then
                        Error(Text012, SalesInvHeader.TableCaption(), JobPlanningLineInvoice."Document No.");
                    PAGE.RunModal(PAGE::"Posted Sales Invoice", SalesInvHeader);
                end;
            JobPlanningLineInvoice."Document Type"::"Posted Credit Memo":
                begin
                    if not SalesCrMemoHeader.Get(JobPlanningLineInvoice."Document No.") then
                        Error(Text012, SalesCrMemoHeader.TableCaption(), JobPlanningLineInvoice."Document No.");
                    PAGE.RunModal(PAGE::"Posted Sales Credit Memo", SalesCrMemoHeader);
                end;
        end;

        OnAfterOpenSalesInvoice(JobPlanningLineInvoice);
    end;

    local procedure UpdateSalesHeader(var SalesHeader: Record "Sales Header"; Job: Record Job)
    var
        FormatAddress: Codeunit "Format Address";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateSalesHeader(SalesHeader, Job, IsHandled);
        if not IsHandled then begin
            SalesHeader."Bill-to Contact No." := Job."Bill-to Contact No.";
            SalesHeader."Bill-to Contact" := Job."Bill-to Contact";
            SalesHeader."Bill-to Name" := Job."Bill-to Name";
            SalesHeader."Bill-to Name 2" := Job."Bill-to Name 2";
            SalesHeader."Bill-to Address" := Job."Bill-to Address";
            SalesHeader."Bill-to Address 2" := Job."Bill-to Address 2";
            SalesHeader."Bill-to City" := Job."Bill-to City";
            SalesHeader."Bill-to Post Code" := Job."Bill-to Post Code";
            SalesHeader."Bill-to Country/Region Code" := Job."Bill-to Country/Region Code";

            SalesHeader."Sell-to Contact No." := Job."Sell-to Contact No.";
            SalesHeader."Sell-to Contact" := Job."Sell-to Contact";
            SalesHeader."Sell-to Customer Name" := Job."Sell-to Customer Name";
            SalesHeader."Sell-to Customer Name 2" := Job."Sell-to Customer Name 2";
            SalesHeader."Sell-to Address" := Job."Sell-to Address";
            SalesHeader."Sell-to Address 2" := Job."Sell-to Address 2";
            SalesHeader."Sell-to City" := Job."Sell-to City";
            SalesHeader."Sell-to Post Code" := Job."Sell-to Post Code";
            SalesHeader."Sell-to Country/Region Code" := Job."Sell-to Country/Region Code";

            if Job."Ship-to Code" <> '' then
                SalesHeader.Validate("Ship-to Code", Job."Ship-to Code")
            else
                if SalesHeader."Ship-to Code" = '' then begin
                    SalesHeader."Ship-to Contact" := Job."Ship-to Contact";
                    SalesHeader."Ship-to Name" := Job."Ship-to Name";
                    SalesHeader."Ship-to Name 2" := Job."Ship-to Name 2";
                    SalesHeader."Ship-to Address" := Job."Ship-to Address";
                    SalesHeader."Ship-to Address 2" := Job."Ship-to Address 2";
                    SalesHeader."Ship-to City" := Job."Ship-to City";
                    SalesHeader."Ship-to Post Code" := Job."Ship-to Post Code";
                    SalesHeader."Ship-to Country/Region Code" := Job."Ship-to Country/Region Code";
                    SalesHeader."Ship-to Phone No." := Job."Ship-to Phone No.";
                    if FormatAddress.UseCounty(SalesHeader."Ship-to Country/Region Code") then
                        SalesHeader."Ship-to County" := Job."Ship-to County";
                end;

            if FormatAddress.UseCounty(SalesHeader."Bill-to Country/Region Code") then
                SalesHeader."Bill-to County" := Job."Bill-to County";
            if FormatAddress.UseCounty(SalesHeader."Sell-to Country/Region Code") then
                SalesHeader."Sell-to County" := Job."Sell-to County";
        end;
        OnAfterUpdateSalesHeader(SalesHeader, Job);
    end;

    local procedure UpdateSalesHeader(var SalesHeader: Record "Sales Header"; JobPlanningLine: Record "Job Planning Line")
    var
        JobTask: Record "Job Task";
        FormatAddress: Codeunit "Format Address";
    begin
        JobTask.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.");
        SalesHeader."Bill-to Contact No." := JobTask."Bill-to Contact No.";
        SalesHeader."Bill-to Contact" := JobTask."Bill-to Contact";
        SalesHeader."Bill-to Name" := JobTask."Bill-to Name";
        SalesHeader."Bill-to Name 2" := JobTask."Bill-to Name 2";
        SalesHeader."Bill-to Address" := JobTask."Bill-to Address";
        SalesHeader."Bill-to Address 2" := JobTask."Bill-to Address 2";
        SalesHeader."Bill-to City" := JobTask."Bill-to City";
        SalesHeader."Bill-to Post Code" := JobTask."Bill-to Post Code";
        SalesHeader."Bill-to Country/Region Code" := JobTask."Bill-to Country/Region Code";

        SalesHeader."Sell-to Contact No." := JobTask."Sell-to Contact No.";
        SalesHeader."Sell-to Contact" := JobTask."Sell-to Contact";
        SalesHeader."Sell-to Customer Name" := JobTask."Sell-to Customer Name";
        SalesHeader."Sell-to Customer Name 2" := JobTask."Sell-to Customer Name 2";
        SalesHeader."Sell-to Address" := JobTask."Sell-to Address";
        SalesHeader."Sell-to Address 2" := JobTask."Sell-to Address 2";
        SalesHeader."Sell-to City" := JobTask."Sell-to City";
        SalesHeader."Sell-to Post Code" := JobTask."Sell-to Post Code";
        SalesHeader."Sell-to Country/Region Code" := JobTask."Sell-to Country/Region Code";

        if JobTask."Ship-to Code" <> '' then
            SalesHeader.Validate("Ship-to Code", JobTask."Ship-to Code")
        else
            if SalesHeader."Ship-to Code" = '' then begin
                SalesHeader."Ship-to Contact" := JobTask."Ship-to Contact";
                SalesHeader."Ship-to Name" := JobTask."Ship-to Name";
                SalesHeader."Ship-to Name 2" := JobTask."Ship-to Name 2";
                SalesHeader."Ship-to Address" := JobTask."Ship-to Address";
                SalesHeader."Ship-to Address 2" := JobTask."Ship-to Address 2";
                SalesHeader."Ship-to City" := JobTask."Ship-to City";
                SalesHeader."Ship-to Post Code" := JobTask."Ship-to Post Code";
                SalesHeader."Ship-to Country/Region Code" := JobTask."Ship-to Country/Region Code";
                if FormatAddress.UseCounty(SalesHeader."Ship-to Country/Region Code") then
                    SalesHeader."Ship-to County" := JobTask."Ship-to County";
            end;

        if FormatAddress.UseCounty(SalesHeader."Bill-to Country/Region Code") then
            SalesHeader."Bill-to County" := JobTask."Bill-to County";
        if FormatAddress.UseCounty(SalesHeader."Sell-to Country/Region Code") then
            SalesHeader."Sell-to County" := JobTask."Sell-to County";
    end;

    local procedure TestSalesHeader(var SalesHeader: Record "Sales Header"; var Job: Record Job; JobPlanningLine: Record "Job Planning Line")
    var
        JobTask: Record "Job Task";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestSalesHeader(SalesHeader, Job, IsHandled, JobPlanningLine);
        if IsHandled then
            exit;

        Job.Get(JobPlanningLine."Job No.");
        if Job."Task Billing Method" = Job."Task Billing Method"::"One customer" then begin
            SalesHeader.TestField("Bill-to Customer No.", Job."Bill-to Customer No.");
            SalesHeader.TestField("Sell-to Customer No.", Job."Sell-to Customer No.");
        end else begin
            JobTask.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.");
            SalesHeader.TestField("Bill-to Customer No.", JobTask."Bill-to Customer No.");
            SalesHeader.TestField("Sell-to Customer No.", JobTask."Sell-to Customer No.");
        end;

        if Job."Currency Code" <> '' then
            SalesHeader.TestField("Currency Code", Job."Currency Code")
        else
            if Job."Task Billing Method" = Job."Task Billing Method"::"One customer" then
                SalesHeader.TestField("Currency Code", Job."Invoice Currency Code")
            else
                SalesHeader.TestField("Currency Code", JobTask."Invoice Currency Code");
        OnAfterTestSalesHeader(SalesHeader, Job, JobPlanningLine);
    end;

    procedure TestExchangeRate(var JobPlanningLine: Record "Job Planning Line"; PostingDate: Date)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        ShouldValidateCurrencyCode: Boolean;
    begin
        OnBeforeTestExchangeRate(JobPlanningLine, PostingDate, UpdateExchangeRates, CurrencyExchangeRate);

        if JobPlanningLine."Currency Code" <> '' then
            if (CurrencyExchangeRate.ExchangeRate(PostingDate, JobPlanningLine."Currency Code") <> JobPlanningLine."Currency Factor")
            then begin
                if not UpdateExchangeRates then
                    UpdateExchangeRates := Confirm(Text010, true);

                if UpdateExchangeRates then begin
                    JobPlanningLine."Currency Date" := PostingDate;
                    JobPlanningLine."Document Date" := PostingDate;

                    ShouldValidateCurrencyCode := true;
                    OnTestExchangeRateOnBeforeValidateCurrencyDate(JobPlanningLine, PostingDate, CurrencyExchangeRate, ShouldValidateCurrencyCode);
                    if ShouldValidateCurrencyCode then
                        JobPlanningLine.Validate("Currency Date");
                    JobPlanningLine."Last Date Modified" := Today;
                    JobPlanningLine."User ID" := CopyStr(UserId(), 1, MaxStrLen(JobPlanningLine."User ID"));
                    JobPlanningLine.Modify(true);
                end else
                    Error('');
            end;
    end;

    local procedure GetLedgEntryDimSetID(JobPlanningLine: Record "Job Planning Line"): Integer
    var
        ResLedgEntry: Record "Res. Ledger Entry";
        ItemLedgEntry: Record "Item Ledger Entry";
        GLEntry: Record "G/L Entry";
    begin
        if JobPlanningLine."Ledger Entry No." = 0 then
            exit(0);

        case JobPlanningLine."Ledger Entry Type" of
            JobPlanningLine."Ledger Entry Type"::Resource:
                begin
                    ResLedgEntry.Get(JobPlanningLine."Ledger Entry No.");
                    exit(ResLedgEntry."Dimension Set ID");
                end;
            JobPlanningLine."Ledger Entry Type"::Item:
                begin
                    ItemLedgEntry.Get(JobPlanningLine."Ledger Entry No.");
                    exit(ItemLedgEntry."Dimension Set ID");
                end;
            JobPlanningLine."Ledger Entry Type"::"G/L Account":
                begin
                    GLEntry.Get(JobPlanningLine."Ledger Entry No.");
                    exit(GLEntry."Dimension Set ID");
                end;
            else
                exit(0);
        end;
    end;

    local procedure GetJobLedgEntryDimSetID(JobPlanningLine: Record "Job Planning Line"): Integer
    var
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        if JobPlanningLine."Job Ledger Entry No." = 0 then
            exit(0);

        if JobLedgerEntry.Get(JobPlanningLine."Job Ledger Entry No.") then
            exit(JobLedgerEntry."Dimension Set ID");

        exit(0);
    end;

    local procedure UpdateSalesLineDimension(var SalesLine: Record "Sales Line"; JobPlanningLine: Record "Job Planning Line")
    var
        SourceCodeSetup: Record "Source Code Setup";
        DimMgt: Codeunit DimensionManagement;
        DimSetIDArr: array[10] of Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateSalesLineDimension(SalesLine, JobPlanningLine, IsHandled);
        if not IsHandled then begin
            SourceCodeSetup.Get();
            DimSetIDArr[1] := SalesLine."Dimension Set ID";
            DimSetIDArr[2] :=
                DimMgt.CreateDimSetFromJobTaskDim(
                SalesLine."Job No.", SalesLine."Job Task No.", SalesLine."Shortcut Dimension 1 Code", SalesLine."Shortcut Dimension 2 Code");
            DimSetIDArr[3] := GetLedgEntryDimSetID(JobPlanningLine);
            DimSetIDArr[4] := GetJobLedgEntryDimSetID(JobPlanningLine);
            DimMgt.CreateDimForSalesLineWithHigherPriorities(
                SalesLine, 0, DimSetIDArr[5],
                SalesLine."Shortcut Dimension 1 Code", SalesLine."Shortcut Dimension 2 Code",
                SourceCodeSetup.Sales, DATABASE::Job);
            SalesLine."Dimension Set ID" :=
                DimMgt.GetCombinedDimensionSetID(
                DimSetIDArr, SalesLine."Shortcut Dimension 1 Code", SalesLine."Shortcut Dimension 2 Code");
            Salesline.Modify();
        end;
    end;

    local procedure IsJobInvCurrencyDependingOnBillingMethod(Job: Record Job; var JobPlanningLineSource: Record "Job Planning Line"): Boolean
    var
        JobTask: Record "Job Task";
    begin
        if Job."Task Billing Method" = Job."Task Billing Method"::"One customer" then
            exit(Job."Invoice Currency Code" <> '')
        else begin
            JobTask.Get(JobPlanningLineSource."Job No.", JobPlanningLineSource."Job Task No.");
            exit(JobTask."Invoice Currency Code" <> '');
        end;
    end;

    local procedure IsJobInvCurrencyDependingOnBillingMethod(Job: Record Job; JobTask: Record "Job Task"): Boolean
    begin
        if Job."Task Billing Method" = Job."Task Billing Method"::"One customer" then
            exit(Job."Invoice Currency Code" <> '')
        else
            exit(JobTask."Invoice Currency Code" <> '');
    end;

    local procedure TestIfBillToCustomerExistOnJobOrJobTask(Job: Record Job; JobTask: Record "Job Task")
    begin
        if Job."Task Billing Method" = Job."Task Billing Method"::"One customer" then
            Job.TestField("Bill-to Customer No.")
        else
            JobTask.TestField("Bill-to Customer No.");
    end;

    local procedure ReturnBillToCustomerNoDependingOnTaskBillingMethod(Job: Record Job; JobTask2: Record "Job Task"): Code[20]
    var
        JobTask: Record "Job Task";
    begin
        if Job."Task Billing Method" = Job."Task Billing Method"::"One customer" then
            exit(Job."Bill-to Customer No.")
        else
            if JobTask.Get(TempJobPlanningLine."Job No.", TempJobPlanningLine."Job Task No.") then
                exit(JobTask."Bill-to Customer No.")
            else
                exit(JobTask2."Bill-to Customer No.");
    end;

    local procedure ReturnJobDataDependingOnTaskBillingMethod(Job: Record Job; JobPlanningLine: Record "Job Planning Line"; FieldName: Text): Text[35]
    var
        JobTask: Record "Job Task";
        DataTypeMgt: Codeunit "Data Type Management";
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        if Job."Task Billing Method" = Job."Task Billing Method"::"One customer" then begin
            RecRef.GetTable(Job);
            if DataTypeMgt.FindFieldByName(RecRef, FldRef, FieldName) then
                exit(FldRef.Value());
        end else begin
            JobTask.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.");
            RecRef.GetTable(JobTask);
            if DataTypeMgt.FindFieldByName(RecRef, FldRef, FieldName) then
                exit(FldRef.Value());
        end;
    end;


    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateSalesInvoiceLines(var SalesHeader: Record "Sales Header"; NewInvoice: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateSalesHeader(Job: Record Job; PostingDate: Date; var SalesHeader2: Record "Sales Header"; var JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateSalesLine(var JobPlanningLine: Record "Job Planning Line"; var SalesHeader: Record "Sales Header"; var SalesHeader2: Record "Sales Header"; var JobInvCurrency: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; Job: Record Job; var JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateSalesHeader(var SalesHeader: Record "Sales Header"; Job: Record Job)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateNewInvoice(var JobTask: Record "Job Task"; InvoicePerTask: Boolean; var OldJobNo: Code[20]; var OldJobTaskNo: Code[20]; LastJobTask: Boolean; var NewInvoice: Boolean; var IsHandled: Boolean; var TempJobPlanningLine: Record "Job Planning Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateSalesInvoiceLines(var JobPlanningLine: Record "Job Planning Line"; InvoiceNo: Code[20]; NewInvoice: Boolean; PostingDate: Date; CreditMemo: Boolean; var NoOfSalesLinesCreated: Integer; var SkipClear: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateSalesInvoiceJobTask(var JobTask2: Record "Job Task"; PostingDate: Date; InvoicePerTask: Boolean; var NoOfInvoices: Integer; var OldJobNo: Code[20]; var OldJobTaskNo: Code[20]; LastJobTask: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteSalesLine(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetInvoiceNo(var JobPlanningLine: Record "Job Planning Line"; Done: Boolean; NewInvoice: Boolean; PostingDate: Date; var InvoiceNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetCrMemoNo(var JobPlanningLine: Record "Job Planning Line"; Done: Boolean; NewInvoice: Boolean; PostingDate: Date; var InvoiceNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertSalesHeader(var SalesHeader: Record "Sales Header"; Job: Record Job; JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifySalesHeader(var SalesHeader: Record "Sales Header"; Job: Record Job; JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertSalesLine(var SalesLine: Record "Sales Line"; var SalesHeader: Record "Sales Header"; Job: Record Job; JobPlanningLine: Record "Job Planning Line"; JobInvCurrency: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifySalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; Job: Record Job; JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenSalesInvoice(var JobPlanningLineInvoice: Record "Job Planning Line Invoice"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestSalesHeader(var SalesHeader: Record "Sales Header"; Job: Record Job; var IsHandled: Boolean; var JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferLine(var JobPlanningLine: Record "Job Planning Line"; var IsHandled: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateSalesHeader(var SalesHeader: Record "Sales Header"; Job: Record Job; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOpenSalesInvoice(var JobPlanningLineInvoice: Record "Job Planning Line Invoice")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTestSalesHeader(var SalesHeader: Record "Sales Header"; Job: Record Job; JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckJobBillToCustomer(JobPlanningLineSource: Record "Job Planning Line"; Job: Record Job; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindInvoices(var TempJobPlanningLineInvoice: Record "Job Planning Line Invoice" temporary; JobNo: Code[20]; JobTaskNo: Code[20]; JobPlanningLineNo: Integer; DetailLevel: Option; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowMessageLinesTransferred(var JobPlanningLine: Record "Job Planning Line"; CrMemo: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestExchangeRate(var JobPlanningLine: Record "Job Planning Line"; PostingDate: Date; var UpdateExchangeRates: Boolean; var CurrencyExchangeRate: Record "Currency Exchange Rate")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestTransferred(var JobPlanningLine: Record "Job Planning Line"; SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesLineOnAfterCalcShouldUpdateCurrencyFactor(var JobPlanningLine: Record "Job Planning Line"; var Job: Record Job; var SalesHeader: Record "Sales Header"; var SalesHeader2: Record "Sales Header"; var JobInvCurrency: Boolean; var ShouldUpdateCurrencyFactor: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesHeaderOnBeforeUpdateSalesHeader(var SalesHeader: Record "Sales Header"; var Job: Record Job; var IsHandled: Boolean; JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesLineOnBeforeSalesCheckIfAnyExtText(var JobPlanningLine: Record "Job Planning Line"; var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesLineOnBeforeValidateSalesLineNo(var JobPlanningLine: Record "Job Planning Line"; var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesLineOnAfterSalesLineModify(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; Job: Record Job; JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesInvoiceLinesOnAfterValidateJobPlanningLine(var JobPlanningLine: Record "Job Planning Line"; var LastError: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesInvoiceLinesOnBeforeJobPlanningLineFindSet(var JobPlanningLine: Record "Job Planning Line"; InvoiceNo: Code[20]; NewInvoice: Boolean; PostingDate: Date; CreditMemo: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesInvoiceLinesOnBeforeJobPlanningLineModify(var JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesInvoiceLinesOnBeforeCreateSalesLine(var JobPlanningLine: Record "Job Planning Line"; SalesHeader: Record "Sales Header"; SalesHeader2: Record "Sales Header"; NewInvoice: Boolean; var NoOfSalesLinesCreated: Integer; var SkipCreateSalesLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesInvoiceLinesOnBeforeTestJob(var Job: Record Job)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesInvoiceJobTaskOnAfterLinesCreated(var SalesHeader: Record "Sales Header"; var Job: Record Job; InvoicePerTask: Boolean; LastJobTask: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesInvoiceJobTaskOnBeforeTempJobPlanningLineFind(var JobTask: Record "Job Task"; var SalesHeader: Record "Sales Header"; InvoicePerTask: Boolean; var TempJobPlanningLine: Record "Job Planning Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesInvoiceJobTaskOnBeforeCreateSalesLine(var JobPlanningLine: Record "Job Planning Line"; SalesHeader: Record "Sales Header"; SalesHeader2: Record "Sales Header"; var NoOfSalesLinesCreated: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesInvoiceJobTaskTestJob(var Job: Record Job; var JobPlanningLine: Record "Job Planning Line"; PostingDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteSalesLineOnBeforeJobPlanningLineModify(var JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesInvoiceJobTaskOnBeforeJobPlanningLineInvoiceInsert(var JobPlanningLineInvoice: Record "Job Planning Line Invoice")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesInvoiceOnBeforeRunReport(var JobPlanningLine: Record "Job Planning Line"; var Done: Boolean; var NewInvoice: Boolean; var PostingDate: Date; var InvoiceNo: Code[20]; var IsHandled: Boolean; CrMemo: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindInvoicesOnBeforeTempJobPlanningLineInvoiceInsert(var TempJobPlanningLineInvoice: Record "Job Planning Line Invoice"; JobPlanningLineInvoice: Record "Job Planning Line Invoice")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindInvoicesOnBeforeTempJobPlanningLineInvoiceModify(var TempJobPlanningLineInvoice: Record "Job Planning Line Invoice"; JobPlanningLineInvoice: Record "Job Planning Line Invoice")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesHeaderOnBeforeCheckBillToCustomerNo(var SalesHeader: Record "Sales Header"; Job: Record Job; JobPlanningLine: Record "Job Planning Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesInvoiceLinesOnBeforeJobPlanningLineCopy(Job: Record Job; var JobPlanningLineSource: Record "Job Planning Line"; PostingDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateSalesLineDimension(var SalesLine: Record "Sales Line"; JobPlanningLine: Record "Job Planning Line"; var IsHandled: Boolean)
    begin
    end;


    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesInvoiceLinesOnAfterSetJobInvCurrency(Job: Record Job; var JobInvCurrency: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesLineOnBeforeValidateCurrencyCode(var IsHandled: Boolean; SalesLine: Record "Sales Line"; JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesInvoiceLinesOnAfterSetSalesDocumentType(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeGetJobPlanningLineInvoices(JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesInvoiceJobTaskOnAfterJobPlanningLineSetFilters(var JobPlanningLine: Record "Job Planning Line"; var JobTask2: Record "Job Task")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesLineOnBeforeCheckPricesIncludingVATAndSetJobInformation(var SalesLine: Record "Sales Line"; JobPlanningLine: Record "Job Planning Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteSalesLineOnBeforeGetJobPlanningLine(JobPlanningLineInvoice: Record "Job Planning Line Invoice")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetCustomerNo(var Job: Record Job; var JobPlanningLine: Record "Job Planning Line"; SellToCustomerNo: Boolean; var CustomerNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindJobPlanningLineInvoice(JobTask: Record "Job Task"; var JobPlanningLineInvoice: Record "Job Planning Line Invoice"; var SalesHeader: Record "Sales Header"; var ExitValue: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTestExchangeRateOnBeforeValidateCurrencyDate(var JobPlanningLine: Record "Job Planning Line"; PostingDate: Date; var CurrencyExchangeRate: Record "Currency Exchange Rate"; var ShouldValidateCurrencyCode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesInvoiceLinesOnBeforeNoSalesLineCreatedError(var SkipError: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesInvoiceLinesOnBeforeJobPlanningLineInvoiceInsert(var JobPlanningLineInvoice: Record "Job Planning Line Invoice")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesInvoiceOnBeforeFindJobPlanningLines(var JobPlanningLine: Record "Job Planning Line")
    begin
    end;
}
