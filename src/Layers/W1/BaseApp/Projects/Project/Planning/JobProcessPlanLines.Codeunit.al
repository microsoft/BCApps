// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Planning;

using Microsoft.Projects.Project.Setup;
using Microsoft.Sales.Document;

codeunit 1033 "Job-Process Plan. Lines"
{
    TableNo = "Sales Line";

    trigger OnRun()
    begin
        SalesHeader.Get(Rec."Document Type", Rec."Document No.");
        SalesHeader.TestField("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.TestField(Status, SalesHeader.Status::Open);

        FindMatchingPlanningLines();
        OnRunOnAfterSetFiltersOnJobPlanningLine(SalesHeader, Rec, TempJobPlanningLine);

        GetPlanningLines.SetRecords(TempJobPlanningLine);
        GetPlanningLines.SetTableView(TempJobPlanningLine);
        GetPlanningLines.SetSalesHeader(SalesHeader);
        GetPlanningLines.LookupMode := true;
        if GetPlanningLines.RunModal() <> ACTION::Cancel then;
    end;

    var
        SalesHeader: Record "Sales Header";
        TempJobPlanningLine: Record "Job Planning Line" temporary;
        JobCreateInvoice: Codeunit "Job Create-Invoice";
        GetPlanningLines: Page "Get Job Planning Lines";

    local procedure FindMatchingPlanningLines()
    var
        GetJobPlanningLines: Query "GetJobPlanningLines";
        TaskBillingMethod: Enum "Task Billing Method";
    begin
        SetFiltersOnGetJobPlanningLine(GetJobPlanningLines, TaskBillingMethod::"One customer");
        UpdateTempJobPlanningLineBasedOnGetJobPlanningLine(GetJobPlanningLines);

        SetFiltersOnGetJobPlanningLine(GetJobPlanningLines, TaskBillingMethod::"Multiple customers");
        UpdateTempJobPlanningLineBasedOnGetJobPlanningLine(GetJobPlanningLines);
    end;

    local procedure SetFiltersOnGetJobPlanningLine(var GetJobPlanningLines: Query "GetJobPlanningLines"; TaskBillingMethod: Enum "Task Billing Method")
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        Clear(GetJobPlanningLines);

        GetJobPlanningLines.SetRange(Task_Billing_Method_Filter, TaskBillingMethod);

        if TaskBillingMethod = TaskBillingMethod::"One customer" then begin
            GetJobPlanningLines.SetRange(Job_Bill_to_Customer_No_Filter, SalesHeader."Bill-to Customer No.");
            GetJobPlanningLines.SetRange(Job_Sell_to_Customer_No_Filter, SalesHeader."Sell-to Customer No.");
            GetJobPlanningLines.SetRange(Job_Invoice_Currency_Code_Filter, SalesHeader."Currency Code");
        end
        else begin
            GetJobPlanningLines.SetRange(Task_Bill_to_Customer_No_Filter, SalesHeader."Bill-to Customer No.");
            GetJobPlanningLines.SetRange(Task_Sell_to_Customer_No_Filter, SalesHeader."Sell-to Customer No.");
            GetJobPlanningLines.SetRange(Task_Invoice_Currency_Code_Filter, SalesHeader."Currency Code");
        end;
        GetJobPlanningLines.SetFilter(Line_Type_Filter, '%1|%2', JobPlanningLine."Line Type"::Billable, JobPlanningLine."Line Type"::"Both Budget and Billable");
        GetJobPlanningLines.SetFilter(Qty_to_Transfer_to_Invoice_Filter, '<>%1', 0);
    end;

    local procedure UpdateTempJobPlanningLineBasedOnGetJobPlanningLine(var GetJobPlanningLines: Query "GetJobPlanningLines")
    var
        JobPlanningLine2: Record "Job Planning Line";
    begin
        GetJobPlanningLines.Open();
        JobPlanningLine2.ReadIsolation(IsolationLevel::ReadUncommitted);

        while GetJobPlanningLines.Read() do
            if JobPlanningLine2.Get(GetJobPlanningLines.Job_No, GetJobPlanningLines.Job_Task_No, GetJobPlanningLines.Line_No) then begin
                TempJobPlanningLine := JobPlanningLine2;
                TempJobPlanningLine.Insert();
            end;
    end;

    procedure SetSalesHeader(var SalesHeader2: Record "Sales Header")
    begin
        SalesHeader.Get(SalesHeader2."Document Type", SalesHeader2."No.");
        SalesHeader.TestField("Document Type", SalesHeader."Document Type"::Invoice);
    end;

    procedure CreateInvLines(var JobPlanningLine2: Record "Job Planning Line")
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine2.SetFilter("Qty. to Transfer to Invoice", '<>%1', 0);
        JobPlanningLine.Copy(JobPlanningLine2);
        JobPlanningLine.SetSkipCheckForMultipleJobsOnSalesLine(true);
        JobCreateInvoice.CreateSalesInvoiceLines(JobPlanningLine."Job No.", JobPlanningLine, SalesHeader."No.", false, SalesHeader."Posting Date", SalesHeader."Document Date", false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterSetFiltersOnJobPlanningLine(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var FilteredJobPlanningLine: Record "Job Planning Line")
    begin
    end;
}