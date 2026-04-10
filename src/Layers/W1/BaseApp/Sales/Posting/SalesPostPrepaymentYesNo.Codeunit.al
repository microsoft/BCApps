// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Posting;

using Microsoft.Finance.GeneralLedger.Preview;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using System.Utilities;

/// <summary>
/// Prompts the user for confirmation before posting prepayment invoices or credit memos for sales orders.
/// </summary>
codeunit 443 "Sales-Post Prepayment (Yes/No)"
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PrepmtDocumentType: Option ,,Invoice,"Credit Memo";

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Do you want to post the prepayments for %1 %2?';
        Text001: Label 'Do you want to post a credit memo for the prepayments for %1 %2?';
#pragma warning restore AA0470
#pragma warning restore AA0074
        UnsupportedDocTypeErr: Label 'Unsupported prepayment document type.';

    /// <summary>
    /// Posts a prepayment invoice for the sales order after prompting the user for confirmation.
    /// </summary>
    /// <param name="SalesHeader2">Specifies the sales header of the order for which to post the prepayment invoice.</param>
    /// <param name="Print">Specifies whether to print the posted prepayment invoice.</param>
    procedure PostPrepmtInvoiceYN(var SalesHeader2: Record "Sales Header"; Print: Boolean)
    var
        SalesHeader: Record "Sales Header";
        IsHandled: Boolean;
    begin
        SalesHeader.Copy(SalesHeader2);
        IsHandled := false;
        OnPostPrepmtInvoiceYNOnBeforeConfirm(SalesHeader, IsHandled);
        if not IsHandled then
            if not ConfirmForDocument(SalesHeader, Text000) then
                exit;

        PostPrepmtDocument(SalesHeader, SalesHeader."Document Type"::Invoice);

        if Print then begin
            Commit();
            GetReport(SalesHeader, 0);
        end;

        OnAfterPostPrepmtInvoiceYN(SalesHeader);

        SalesHeader2 := SalesHeader;
    end;

    /// <summary>
    /// Posts a prepayment credit memo for the sales order after prompting the user for confirmation.
    /// </summary>
    /// <param name="SalesHeader2">Specifies the sales header of the order for which to post the prepayment credit memo.</param>
    /// <param name="Print">Specifies whether to print the posted prepayment credit memo.</param>
    procedure PostPrepmtCrMemoYN(var SalesHeader2: Record "Sales Header"; Print: Boolean)
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Copy(SalesHeader2);
        if not ConfirmForDocument(SalesHeader, Text001) then
            exit;

        PostPrepmtDocument(SalesHeader, SalesHeader."Document Type"::"Credit Memo");

        if Print then
            GetReport(SalesHeader, 1);

        Commit();
        OnAfterPostPrepmtCrMemoYN(SalesHeader);

        SalesHeader2 := SalesHeader;
    end;

    local procedure ConfirmForDocument(var SalesHeader: Record "Sales Header"; ConfirmationText: Text) Result: Boolean
    var
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeConfirmForDocument(SalesHeader, Result, IsHandled);
        if IsHandled then
            exit(Result);

        Result := ConfirmManagement.GetResponseOrDefault(StrSubstNo(ConfirmationText, SalesHeader."Document Type", SalesHeader."No."), true);
    end;

    local procedure PostPrepmtDocument(var SalesHeader: Record "Sales Header"; PrepmtDocumentType: Enum "Sales Document Type")
    var
        SalesPostPrepayments: Codeunit "Sales-Post Prepayments";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorContextElement: Codeunit "Error Context Element";
        SuppressCommit: Boolean;
    begin
        OnBeforePostPrepmtDocument(SalesHeader, PrepmtDocumentType.AsInteger());

        ErrorMessageMgt.Activate(ErrorMessageHandler);
        ErrorMessageMgt.PushContext(ErrorContextElement, SalesHeader.RecordId, 0, '');
        SalesPostPrepayments.SetDocumentType(PrepmtDocumentType.AsInteger());
        Commit();

        OnPostPrepmtDocumentOnBeforeRunSalesPostPrepayments(SalesHeader, SuppressCommit);
        SalesPostPrepayments.SetSuppressCommit(SuppressCommit);
        if not SalesPostPrepayments.Run(SalesHeader) then
            ErrorMessageHandler.ShowErrors();
    end;

    /// <summary>
    /// Previews the posting of a prepayment document without actually posting it.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header of the order for which to preview the prepayment posting.</param>
    /// <param name="DocumentType">Specifies the prepayment document type (Invoice or Credit Memo) to preview.</param>
    procedure Preview(var SalesHeader: Record "Sales Header"; DocumentType: Option)
    var
        SalesPostPrepaymentYesNo: Codeunit "Sales-Post Prepayment (Yes/No)";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
    begin
        BindSubscription(SalesPostPrepaymentYesNo);
        SalesPostPrepaymentYesNo.SetDocumentType(DocumentType);
        GenJnlPostPreview.Preview(SalesPostPrepaymentYesNo, SalesHeader);
    end;

    /// <summary>
    /// Prints the posted prepayment invoice or credit memo.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header of the order from which to print the prepayment document.</param>
    /// <param name="DocumentType">Specifies the prepayment document type (Invoice or Credit Memo) to print.</param>
    procedure GetReport(var SalesHeader: Record "Sales Header"; DocumentType: Option Invoice,"Credit Memo")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetReport(SalesHeader, DocumentType, IsHandled);
        if IsHandled then
            exit;

        case DocumentType of
            DocumentType::Invoice:
                begin
                    SalesInvHeader."No." := SalesHeader."Last Prepayment No.";
                    SalesInvHeader.SetRecFilter();
                    SalesInvHeader.PrintRecords(false);
                end;
            DocumentType::"Credit Memo":
                begin
                    SalesCrMemoHeader."No." := SalesHeader."Last Prepmt. Cr. Memo No.";
                    SalesCrMemoHeader.SetRecFilter();
                    SalesCrMemoHeader.PrintRecords(false);
                end;
        end;
    end;

    /// <summary>
    /// Sets the prepayment document type to be used for posting.
    /// </summary>
    /// <param name="NewPrepmtDocumentType">Specifies the prepayment document type (Invoice or Credit Memo) to set.</param>
    [Scope('OnPrem')]
    procedure SetDocumentType(NewPrepmtDocumentType: Option)
    begin
        PrepmtDocumentType := NewPrepmtDocumentType;
    end;

    /// <summary>
    /// Raised after posting the prepayment invoice for a sales order.
    /// </summary>
    /// <param name="SalesHeader">The sales header for which the prepayment invoice was posted.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterPostPrepmtInvoiceYN(var SalesHeader: Record "Sales Header")
    begin
    end;

    /// <summary>
    /// Raised after posting the prepayment credit memo for a sales order.
    /// </summary>
    /// <param name="SalesHeader">The sales header for which the prepayment credit memo was posted.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterPostPrepmtCrMemoYN(var SalesHeader: Record "Sales Header")
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Preview", 'OnRunPreview', '', false, false)]
    local procedure OnRunPreview(var Result: Boolean; Subscriber: Variant; RecVar: Variant)
    var
        SalesHeader: Record "Sales Header";
        SalesPostPrepayments: Codeunit "Sales-Post Prepayments";
    begin
        SalesHeader.Copy(RecVar);
        SalesHeader.Invoice := true;

        if PrepmtDocumentType in [PrepmtDocumentType::Invoice, PrepmtDocumentType::"Credit Memo"] then
            SalesPostPrepayments.SetDocumentType(PrepmtDocumentType)
        else
            Error(UnsupportedDocTypeErr);

        SalesPostPrepayments.SetPreviewMode(true);
        Result := SalesPostPrepayments.Run(SalesHeader);
    end;

    /// <summary>
    /// Raised before getting the report to print the prepayment document.
    /// </summary>
    /// <param name="SalesHeader">The sales header for which to print the prepayment document.</param>
    /// <param name="DocumentType">The prepayment document type (Invoice or Credit Memo).</param>
    /// <param name="IsHandled">Set to true to skip the default print logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetReport(var SalesHeader: Record "Sales Header"; DocumentType: Option Invoice,"Credit Memo"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before displaying the confirmation dialog for posting the prepayment document.
    /// </summary>
    /// <param name="SalesHeader">The sales header being processed.</param>
    /// <param name="Result">Returns the result of the confirmation dialog.</param>
    /// <param name="IsHandled">Set to true to skip the default confirmation dialog.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmForDocument(var SalesHeader: Record "Sales Header"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before posting the prepayment document.
    /// </summary>
    /// <param name="SalesHeader">The sales header for which to post the prepayment document.</param>
    /// <param name="PrepmtDocumentType">The prepayment document type (Invoice or Credit Memo).</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforePostPrepmtDocument(var SalesHeader: Record "Sales Header"; PrepmtDocumentType: Option)
    begin
    end;

    /// <summary>
    /// Raised before confirming the posting of the prepayment invoice.
    /// </summary>
    /// <param name="SalesHeader">The sales header being processed.</param>
    /// <param name="IsHandled">Set to true to skip the default confirmation dialog.</param>
    [IntegrationEvent(false, false)]
    local procedure OnPostPrepmtInvoiceYNOnBeforeConfirm(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean);
    begin
    end;

    /// <summary>
    /// Raised before running the Sales-Post Prepayments codeunit.
    /// </summary>
    /// <param name="SalesHeader">The sales header to be posted.</param>
    /// <param name="SuppressCommit">Set to true to suppress database commits during posting.</param>
    [IntegrationEvent(false, false)]
    local procedure OnPostPrepmtDocumentOnBeforeRunSalesPostPrepayments(var SalesHeader: Record "Sales Header"; var SuppressCommit: Boolean);
    begin
    end;
}

