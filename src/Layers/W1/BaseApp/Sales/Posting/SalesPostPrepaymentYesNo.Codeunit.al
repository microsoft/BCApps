// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Posting;

using Microsoft.Finance.GeneralLedger.Preview;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using System.Utilities;

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

    procedure Preview(var SalesHeader: Record "Sales Header"; DocumentType: Option)
    var
        SalesPostPrepaymentYesNo: Codeunit "Sales-Post Prepayment (Yes/No)";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
    begin
        BindSubscription(SalesPostPrepaymentYesNo);
        SalesPostPrepaymentYesNo.SetDocumentType(DocumentType);
        GenJnlPostPreview.Preview(SalesPostPrepaymentYesNo, SalesHeader);
    end;

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

    [Scope('OnPrem')]
    procedure SetDocumentType(NewPrepmtDocumentType: Option)
    begin
        PrepmtDocumentType := NewPrepmtDocumentType;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostPrepmtInvoiceYN(var SalesHeader: Record "Sales Header")
    begin
    end;

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

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetReport(var SalesHeader: Record "Sales Header"; DocumentType: Option Invoice,"Credit Memo"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmForDocument(var SalesHeader: Record "Sales Header"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostPrepmtDocument(var SalesHeader: Record "Sales Header"; PrepmtDocumentType: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostPrepmtInvoiceYNOnBeforeConfirm(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostPrepmtDocumentOnBeforeRunSalesPostPrepayments(var SalesHeader: Record "Sales Header"; var SuppressCommit: Boolean);
    begin
    end;
}

