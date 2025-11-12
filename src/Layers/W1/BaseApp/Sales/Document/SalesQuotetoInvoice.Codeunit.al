// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Sales.Comment;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Setup;
using Microsoft.Utilities;
using System.Utilities;
using System.Email;

codeunit 1305 "Sales-Quote to Invoice"
{
    TableNo = "Sales Header";

    trigger OnRun()
    var
        Cust: Record Customer;
        SalesQuoteLine: Record "Sales Line";
        SalesCommentLine: Record "Sales Comment Line";
        SalesInvoiceLine: Record "Sales Line";
        CustCheckCrLimit: Codeunit "Cust-Check Cr. Limit";
        IsHandled: Boolean;
    begin
        OnBeforeOnRun(Rec);

        Rec.TestField("Document Type", Rec."Document Type"::Quote);

        if Rec."Sell-to Customer No." = '' then
            Error(SpecifyCustomerErr);

        if Rec."Bill-to Customer No." = '' then
            Error(SpecifyBillToCustomerNoErr, Rec.FieldCaption("Bill-to Customer No."));

        Rec.OnCheckSalesPostRestrictions();

        Cust.Get(Rec."Sell-to Customer No.");
        Cust.CheckBlockedCustOnDocs(Cust, Rec."Document Type"::Quote, true, false);
        Rec.CalcFields("Amount Including VAT", "Invoice Discount Amount", "Work Description");

        Rec.ValidateSalesPersonOnSalesHeader(Rec, true, false);

        OnRunOnBeforeRunLineChecks(Rec);

        Rec.CheckForBlockedLines();
        CheckForAssembleToOrderLines(Rec);

        SalesInvoiceHeader := Rec;

        SalesInvoiceLine.LockTable();

        CreateSalesInvoiceHeader(SalesInvoiceHeader, Rec);
        CreateSalesInvoiceLines(SalesInvoiceHeader, Rec, SalesQuoteLine);
        OnAfterInsertAllSalesInvLines(SalesInvoiceLine, Rec);

        SalesSetup.Get();
        ArchiveSalesQuote(Rec);

        if SalesSetup."Default Posting Date" = SalesSetup."Default Posting Date"::"No Date" then begin
            SalesInvoiceHeader."Posting Date" := 0D;
            SalesInvoiceHeader.Modify();
        end;
        UpdateEmailParameters(SalesInvoiceHeader);

        IsHandled := false;
        OnBeforeDeletionOfQuote(Rec, SalesInvoiceHeader, IsHandled, SalesQuoteLine);
        if not IsHandled then begin
            SalesCommentLine.DeleteComments(Rec."Document Type".AsInteger(), Rec."No.");
            Rec.DeleteLinks();
            Rec.Delete();
            SalesQuoteLine.DeleteAll();
        end;

        Commit();
        Clear(CustCheckCrLimit);

        OnAfterOnRun(Rec, SalesInvoiceHeader);
    end;

    var
        SalesSetup: Record "Sales & Receivables Setup";
        SalesInvoiceHeader: Record "Sales Header";
        SpecifyCustomerErr: Label 'You must select a customer before you can convert a quote to an invoice.';
        SpecifyBillToCustomerNoErr: Label 'You must specify the %1 before you can convert a quote to an invoice.', Comment = '%1 is Bill-To Customer No.';
        CannotConvertAssembleToOrderItemErr: Label 'You can not convert sales quote to sales invoice because one or more lines is linked to assembly quote. Change the %1 to zero or convert the quote to order instead.', Comment = '%1 = field name';

    local procedure ArchiveSalesQuote(var SalesHeader: Record "Sales Header")
    var
        ArchiveManagement: Codeunit ArchiveManagement;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeArchiveSalesQuote(SalesHeader, SalesInvoiceHeader, IsHandled);
        if IsHandled then
            exit;

        case SalesSetup."Archive Quotes" of
            SalesSetup."Archive Quotes"::Always:
                ArchiveManagement.ArchSalesDocumentNoConfirm(SalesHeader);
            SalesSetup."Archive Quotes"::Question:
                ArchiveManagement.ArchiveSalesDocument(SalesHeader);
        end;
    end;

    procedure GetSalesInvoiceHeader(var SalesHeader2: Record "Sales Header")
    begin
        SalesHeader2 := SalesInvoiceHeader;
    end;

    local procedure CreateSalesInvoiceHeader(var SalesInvoiceHeader: Record "Sales Header"; SalesQuoteHeader: Record "Sales Header")
    var
        GLSetup: Record "General Ledger Setup";
    begin
        SalesInvoiceHeader."Document Type" := SalesInvoiceHeader."Document Type"::Invoice;

        SalesInvoiceHeader."No. Printed" := 0;
        SalesInvoiceHeader.Status := SalesInvoiceHeader.Status::Open;
        SalesInvoiceHeader."No." := '';

        SalesInvoiceHeader."Quote No." := SalesQuoteHeader."No.";
        OnCreateSalesInvoiceHeaderOnBeforeSalesInvoiceHeaderInsert(SalesInvoiceHeader, SalesQuoteHeader);
        SalesInvoiceHeader.Insert(true);

        if SalesQuoteHeader."Posting Date" <> 0D then
            SalesInvoiceHeader."Posting Date" := SalesQuoteHeader."Posting Date"
        else
            SalesInvoiceHeader."Posting Date" := WorkDate();
        SalesInvoiceHeader.InitFromSalesHeader(SalesQuoteHeader);
        SalesInvoiceHeader."VAT Reporting Date" := GLSetup.GetVATDate(SalesInvoiceHeader."Posting Date", SalesInvoiceHeader."Document Date");
        SalesInvoiceHeader.Validate("Posting Date");

        OnBeforeInsertSalesInvoiceHeader(SalesInvoiceHeader, SalesQuoteHeader);
        SalesInvoiceHeader.Modify();
    end;

    local procedure CreateSalesInvoiceLines(SalesInvoiceHeader: Record "Sales Header"; SalesQuoteHeader: Record "Sales Header"; var SalesQuoteLine: Record "Sales Line")
    var
        SalesInvoiceLine: Record "Sales Line";
        SalesLineReserve: Codeunit "Sales Line-Reserve";
        IsHandled: Boolean;
    begin
        SalesQuoteLine.Reset();
        SalesQuoteLine.SetRange("Document Type", SalesQuoteHeader."Document Type");
        SalesQuoteLine.SetRange("Document No.", SalesQuoteHeader."No.");
        OnAfterSalesQuoteLineSetFilters(SalesQuoteLine);
        if SalesQuoteLine.FindSet() then
            repeat
                IsHandled := false;
                OnBeforeCreateSalesInvoiceLineLoop(SalesQuoteLine, SalesQuoteHeader, SalesInvoiceHeader, IsHandled);
                if not IsHandled then begin
                    SalesInvoiceLine := SalesQuoteLine;
                    SalesInvoiceLine."Document Type" := SalesInvoiceHeader."Document Type";
                    SalesInvoiceLine."Document No." := SalesInvoiceHeader."No.";
                    if SalesInvoiceLine."No." <> '' then
                        SalesInvoiceLine.DefaultDeferralCode();
                    SalesInvoiceLine.InitQtyToShip();
                    OnBeforeInsertSalesInvoiceLine(SalesQuoteLine, SalesQuoteHeader, SalesInvoiceLine, SalesInvoiceHeader);
                    SalesInvoiceLine.Insert();

                    SalesLineReserve.TransferSaleLineToSalesLine(SalesQuoteLine, SalesInvoiceLine, SalesQuoteLine."Outstanding Qty. (Base)");
                    SalesLineReserve.VerifyQuantity(SalesInvoiceLine, SalesQuoteLine);
                    OnAfterInsertSalesInvoiceLine(SalesQuoteLine, SalesQuoteHeader, SalesInvoiceLine, SalesInvoiceHeader);
                end;
            until SalesQuoteLine.Next() = 0;

        MoveLineCommentsToSalesInvoice(SalesInvoiceHeader, SalesQuoteHeader);

        OnCreateSalesInvoiceLinesOnBeforeSalesQuoteLineDeleteAll(SalesQuoteHeader, SalesInvoiceHeader, SalesQuoteLine);
    end;

    local procedure MoveLineCommentsToSalesInvoice(SalesInvoiceHeader: Record "Sales Header"; SalesQuoteHeader: Record "Sales Header")
    var
        SalesCommentLine: Record "Sales Comment Line";
        RecordLinkManagement: Codeunit "Record Link Management";
    begin
        SalesCommentLine.CopyComments(
          SalesQuoteHeader."Document Type".AsInteger(), SalesInvoiceHeader."Document Type".AsInteger(), SalesQuoteHeader."No.", SalesInvoiceHeader."No.");
        RecordLinkManagement.CopyLinks(SalesQuoteHeader, SalesInvoiceHeader);
    end;

    local procedure UpdateEmailParameters(SalesHeader: Record "Sales Header")
    var
        EmailParameter: Record "Email Parameter";
    begin
        EmailParameter.SetRange("Document No", SalesHeader."Quote No.");
        EmailParameter.SetRange("Document Type", SalesHeader."Document Type"::Quote);
        EmailParameter.DeleteAll();
    end;

    local procedure CheckForAssembleToOrderLines(QuoteSalesHeader: Record "Sales Header")
    var
        CurrentSalesLine: Record "Sales Line";
    begin
        CurrentSalesLine.SetRange("Document Type", QuoteSalesHeader."Document Type");
        CurrentSalesLine.SetRange("Document No.", QuoteSalesHeader."No.");
        CurrentSalesLine.SetRange(Type, CurrentSalesLine.Type::Item);
        CurrentSalesLine.SetFilter("Qty. to Assemble to Order", '<> 0');

        if not CurrentSalesLine.IsEmpty() then
            Error(CannotConvertAssembleToOrderItemErr, CurrentSalesLine.FieldCaption("Qty. to Assemble to Order"));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertSalesInvoiceHeader(var SalesInvoiceHeader: Record "Sales Header"; QuoteSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertSalesInvoiceLine(SalesQuoteLine: Record "Sales Line"; SalesQuoteHeader: Record "Sales Header"; var SalesInvoiceLine: Record "Sales Line"; SalesInvoiceHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertAllSalesInvLines(var SalesInvoiceLine: Record "Sales Line"; SalesQuoteHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnRun(var SalesHeader: Record "Sales Header"; var SalesInvoiceHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesQuoteLineSetFilters(var SalesQuoteLine: Record "Sales Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeArchiveSalesQuote(var SalesHeader: Record "Sales Header"; var SalesInvoiceHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertSalesInvoiceLine(SalesQuoteLine: Record "Sales Line"; SalesQuoteHeader: Record "Sales Header"; var SalesInvoiceLine: Record "Sales Line"; SalesInvoiceHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateSalesInvoiceLineLoop(var SalesQuoteLine: Record "Sales Line"; var SalesQuoteHeader: Record "Sales Header"; var SalesInvoiceHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeletionOfQuote(var SalesHeader: Record "Sales Header"; var SalesInvoiceHeader: Record "Sales Header"; var IsHandled: Boolean; var SalesQuoteLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesInvoiceHeaderOnBeforeSalesInvoiceHeaderInsert(var SalesInvoiceHeader: Record "Sales Header"; SalesQuoteHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesInvoiceLinesOnBeforeSalesQuoteLineDeleteAll(QuoteSalesHeader: Record "Sales Header"; InvoiceSalesHeader: Record "Sales Header"; var QuoteSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeRunLineChecks(var SalesHeader: Record "Sales Header")
    begin
    end;
}

