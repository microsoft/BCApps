// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Posting;

using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Setup;

/// <summary>
/// Posts a sales document and prints or emails the posted document based on user selection.
/// </summary>
codeunit 82 "Sales-Post + Print"
{
    TableNo = "Sales Header";

    trigger OnRun()
    var
        SalesHeader: Record "Sales Header";
    begin
        OnBeforeOnRun(Rec);

        SalesHeader.Copy(Rec);
        Code(SalesHeader);
        Rec := SalesHeader;
    end;

    var
        SendReportAsEmail: Boolean;

    /// <summary>
    /// Posts the sales document and sends the posted document to the customer via email.
    /// </summary>
    /// <param name="ParmSalesHeader">Specifies the sales header of the document to post and email.</param>
    procedure PostAndEmail(var ParmSalesHeader: Record "Sales Header")
    var
        SalesHeader: Record "Sales Header";
    begin
        SendReportAsEmail := true;
        SalesHeader.Copy(ParmSalesHeader);
        Code(SalesHeader);
        ParmSalesHeader := SalesHeader;
    end;

    local procedure "Code"(var SalesHeader: Record "Sales Header")
    var
        SalesSetup: Record "Sales & Receivables Setup";
        SalesPostViaJobQueue: Codeunit "Sales Post via Job Queue";
        HideDialog: Boolean;
        IsHandled: Boolean;
        DefaultOption: Integer;
    begin
        HideDialog := false;
        IsHandled := false;
        DefaultOption := 3;
        OnBeforeConfirmPost(SalesHeader, HideDialog, IsHandled, SendReportAsEmail, DefaultOption);
        if IsHandled then
            exit;

        if not HideDialog then
            if not ConfirmPost(SalesHeader, DefaultOption) then
                exit;

        IsHandled := false;
        OnAfterConfirmPost(SalesHeader, IsHandled);
        if IsHandled then
            exit;

        SalesSetup.Get();
        if SalesSetup."Post & Print with Job Queue" and not SendReportAsEmail then
            SalesPostViaJobQueue.EnqueueSalesDoc(SalesHeader)
        else begin
            RunSalesPost(SalesHeader);
            GetReport(SalesHeader);
        end;

        OnAfterPost(SalesHeader);
        Commit();
    end;

    local procedure RunSalesPost(var SalesHeader: Record "Sales Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunSalesPost(SalesHeader, IsHandled);
        if IsHandled then
            exit;

        Codeunit.Run(Codeunit::"Sales-Post", SalesHeader);
    end;

    /// <summary>
    /// Prints or emails the posted sales document based on the document type and settings.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header of the document for which to print or email the report.</param>
    procedure GetReport(var SalesHeader: Record "Sales Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetReport(SalesHeader, IsHandled, SendReportAsEmail);
        if not IsHandled then
            case SalesHeader."Document Type" of
                SalesHeader."Document Type"::Order:
                    begin
                        if SalesHeader.Ship then
                            PrintShip(SalesHeader);
                        if SalesHeader.Invoice then
                            PrintInvoice(SalesHeader);
                    end;
                SalesHeader."Document Type"::Invoice:
                    PrintInvoice(SalesHeader);
                SalesHeader."Document Type"::"Return Order":
                    begin
                        if SalesHeader.Receive then
                            PrintReceive(SalesHeader);
                        if SalesHeader.Invoice then
                            PrintCrMemo(SalesHeader);
                    end;
                SalesHeader."Document Type"::"Credit Memo":
                    PrintCrMemo(SalesHeader);
            end;

        OnAfterGetReport(SalesHeader, SendReportAsEmail);
    end;

    local procedure ConfirmPost(var SalesHeader: Record "Sales Header"; DefaultOption: Integer) Result: Boolean
    var
        PostingSelectionManagement: Codeunit "Posting Selection Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeConfirmPostProcedure(SalesHeader, DefaultOption, Result, IsHandled);
        if IsHandled then
            exit(Result);

        Result := PostingSelectionManagement.ConfirmPostSalesDocument(SalesHeader, DefaultOption, not SendReportAsEmail, SendReportAsEmail);
        if not Result then
            exit(false);

        SalesHeader."Print Posted Documents" := true;
        exit(true);
    end;

    /// <summary>
    /// Prints or emails the posted return receipt document.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header of the return order from which the return receipt was posted.</param>
    procedure PrintReceive(var SalesHeader: Record "Sales Header")
    var
        ReturnRcptHeader: Record "Return Receipt Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrintReceive(SalesHeader, SendReportAsEmail, IsHandled);
        if IsHandled then
            exit;

        ReturnRcptHeader."No." := SalesHeader."Last Return Receipt No.";
        if ReturnRcptHeader.Find() then;
        ReturnRcptHeader.SetRecFilter();

        if SendReportAsEmail then
            ReturnRcptHeader.EmailRecords(true)
        else
            ReturnRcptHeader.PrintRecords(false);
    end;

    /// <summary>
    /// Prints or emails the posted sales invoice document.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header of the document from which the invoice was posted.</param>
    procedure PrintInvoice(var SalesHeader: Record "Sales Header")
    var
        SalesInvHeader: Record "Sales Invoice Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrintInvoice(SalesHeader, SendReportAsEmail, IsHandled);
        if IsHandled then
            exit;

        if SalesHeader."Last Posting No." = '' then
            SalesInvHeader."No." := SalesHeader."No."
        else
            SalesInvHeader."No." := SalesHeader."Last Posting No.";
        SalesInvHeader.Find();
        SalesInvHeader.SetRecFilter();

        OnPrintInvoiceOnAfterSetSalesInvHeaderFilter(SalesHeader, SalesInvHeader, SendReportAsEmail);

        if SendReportAsEmail then
            SalesInvHeader.EmailRecords(true)
        else
            SalesInvHeader.PrintRecords(false);
    end;

    /// <summary>
    /// Prints or emails the posted sales shipment document.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header of the sales order from which the shipment was posted.</param>
    procedure PrintShip(var SalesHeader: Record "Sales Header")
    var
        SalesShptHeader: Record "Sales Shipment Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrintShip(SalesHeader, SendReportAsEmail, IsHandled);
        if IsHandled then
            exit;

        SalesShptHeader."No." := SalesHeader."Last Shipping No.";
        if SalesShptHeader.Find() then;
        SalesShptHeader.SetRecFilter();

        if SendReportAsEmail then
            SalesShptHeader.EmailRecords(true)
        else
            SalesShptHeader.PrintRecords(false);
    end;

    /// <summary>
    /// Prints or emails the posted sales credit memo document.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header of the document from which the credit memo was posted.</param>
    procedure PrintCrMemo(var SalesHeader: Record "Sales Header")
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrintCrMemo(SalesHeader, SendReportAsEmail, IsHandled);
        if IsHandled then
            exit;

        if SalesHeader."Last Posting No." = '' then
            SalesCrMemoHeader."No." := SalesHeader."No."
        else
            SalesCrMemoHeader."No." := SalesHeader."Last Posting No.";
        SalesCrMemoHeader.Find();
        SalesCrMemoHeader.SetRecFilter();

        if SendReportAsEmail then
            SalesCrMemoHeader.EmailRecords(true)
        else
            SalesCrMemoHeader.PrintRecords(false);
    end;

    /// <summary>
    /// Raised after the sales document has been posted.
    /// </summary>
    /// <param name="SalesHeader">The sales header that was posted.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterPost(var SalesHeader: Record "Sales Header")
    begin
    end;

    /// <summary>
    /// Raised after the user confirms posting the sales document.
    /// </summary>
    /// <param name="SalesHeader">The sales header being posted.</param>
    /// <param name="IsHandled">Set to true to skip the default posting logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterConfirmPost(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before confirming the post and print operation.
    /// </summary>
    /// <param name="SalesHeader">The sales header to be posted and printed.</param>
    /// <param name="HideDialog">Set to true to hide the confirmation dialog.</param>
    /// <param name="IsHandled">Set to true to skip the default confirmation logic.</param>
    /// <param name="SendReportAsEmail">Indicates whether to send the report via email instead of printing.</param>
    /// <param name="DefaultOption">The default posting option to select in the dialog.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmPost(var SalesHeader: Record "Sales Header"; var HideDialog: Boolean; var IsHandled: Boolean; var SendReportAsEmail: Boolean; var DefaultOption: Integer)
    begin
    end;

    /// <summary>
    /// Raised before the confirmation dialog procedure.
    /// </summary>
    /// <param name="SalesHeader">The sales header being posted.</param>
    /// <param name="DefaultOption">The default posting option to select in the dialog.</param>
    /// <param name="Result">Returns the result of the confirmation dialog.</param>
    /// <param name="IsHandled">Set to true to skip the default confirmation dialog.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmPostProcedure(var SalesHeader: Record "Sales Header"; var DefaultOption: Integer; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before getting the report to print or email.
    /// </summary>
    /// <param name="SalesHeader">The sales header for which to get the report.</param>
    /// <param name="IsHandled">Set to true to skip the default report logic.</param>
    /// <param name="SendReportAsEmail">Indicates whether to send the report via email instead of printing.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetReport(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean; SendReportAsEmail: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before the OnRun trigger executes.
    /// </summary>
    /// <param name="SalesHeader">The sales header to be posted.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var SalesHeader: Record "Sales Header")
    begin
    end;

    /// <summary>
    /// Raised before printing or emailing the posted sales invoice.
    /// </summary>
    /// <param name="SalesHeader">The sales header from which the invoice was posted.</param>
    /// <param name="SendReportAsEmail">Indicates whether to send the report via email instead of printing.</param>
    /// <param name="IsHandled">Set to true to skip the default print logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintInvoice(var SalesHeader: Record "Sales Header"; SendReportAsEmail: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before printing or emailing the posted sales credit memo.
    /// </summary>
    /// <param name="SalesHeader">The sales header from which the credit memo was posted.</param>
    /// <param name="SendReportAsEmail">Indicates whether to send the report via email instead of printing.</param>
    /// <param name="IsHandled">Set to true to skip the default print logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintCrMemo(var SalesHeader: Record "Sales Header"; SendReportAsEmail: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before printing or emailing the posted return receipt.
    /// </summary>
    /// <param name="SalesHeader">The sales header from which the return receipt was posted.</param>
    /// <param name="SendReportAsEmail">Indicates whether to send the report via email instead of printing.</param>
    /// <param name="IsHandled">Set to true to skip the default print logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintReceive(var SalesHeader: Record "Sales Header"; SendReportAsEmail: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before printing or emailing the posted sales shipment.
    /// </summary>
    /// <param name="SalesHeader">The sales header from which the shipment was posted.</param>
    /// <param name="SendReportAsEmail">Indicates whether to send the report via email instead of printing.</param>
    /// <param name="IsHandled">Set to true to skip the default print logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintShip(var SalesHeader: Record "Sales Header"; SendReportAsEmail: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before running the Sales-Post codeunit.
    /// </summary>
    /// <param name="SalesHeader">The sales header to be posted.</param>
    /// <param name="IsHandled">Set to true to skip the default posting logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunSalesPost(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after setting the filter on the sales invoice header for printing.
    /// </summary>
    /// <param name="SalesHeader">The sales header from which the invoice was posted.</param>
    /// <param name="SalesInvoiceHeader">The posted sales invoice header to be printed.</param>
    /// <param name="SendReportAsEmail">Indicates whether to send the report via email instead of printing.</param>
    [IntegrationEvent(false, false)]
    local procedure OnPrintInvoiceOnAfterSetSalesInvHeaderFilter(var SalesHeader: Record "Sales Header"; var SalesInvoiceHeader: Record "Sales Invoice Header"; SendReportAsEmail: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after getting and printing or emailing the report.
    /// </summary>
    /// <param name="SalesHeader">The sales header for which the report was processed.</param>
    /// <param name="SendReportAsEmail">Indicates whether the report was sent via email.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetReport(var SalesHeader: Record "Sales Header"; SendReportAsEmail: Boolean)
    begin
    end;
}

