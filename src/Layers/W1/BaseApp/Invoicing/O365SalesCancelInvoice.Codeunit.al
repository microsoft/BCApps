// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#pragma warning disable AA0247
codeunit 2103 "O365 Sales Cancel Invoice"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    begin
        SendInvoiceCancelationEmailFromJobQueue(Rec);
    end;

    var
        EmailSubjectTxt: Label 'Your invoice has been canceled.';
        GreetingTxt: Label 'Hello %1,', Comment = '%1 - customer name';
        CanceletionEmailBodyTxt: Label 'Thank you for your business. Your invoice has been canceled.';
        CancelationEmailSubjectTxt: Label 'Invoice %1 of amount %2%3, that was due on %4 has been canceled. ', Comment = '%1 = Invoice No,%2 = Currency code, %3 = Total amount including tax , %4 = Due date';

    [Scope('OnPrem')]
    procedure SendInvoiceCancelationEmail(SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        ReportSelections: Record "Report Selections";
        Customer: Record "Customer";
        DocumentMailing: Codeunit "Document-Mailing";
        TempBlob: Codeunit "Temp Blob";
        EmailBodyTempBlob: Codeunit "Temp Blob";
        SourceReference: RecordRef;
        RecordVariant: Variant;
        CustomerAddress: Text[250];
        EmailBodyTxt: Text;
        AttachmentStream: InStream;
        SourceTableIDs, SourceRelationTypes : List of [Integer];
        SourceIDs: List of [Guid];
    begin
        if not IsInvoiceCanceled(SalesInvoiceHeader) then
            exit;

        RecordVariant := SalesInvoiceHeader;
        CustomerAddress := GetEmailAddress(SalesInvoiceHeader);
        EmailBodyTxt := GetEmailBody(SalesInvoiceHeader);
        ReportSelections.GetEmailBodyTextForCust(
          EmailBodyTempBlob, "Report Selection Usage"::"S.Invoice", RecordVariant, SalesInvoiceHeader."Bill-to Customer No.",
          CustomerAddress, EmailBodyTxt);

        TempBlob.CreateInStream(AttachmentStream);
        SourceReference := RecordVariant;

        SourceTableIDs.Add(SourceReference.Number());
        SourceIDs.Add(SourceReference.Field(SourceReference.SystemIdNo).Value());
        SourceRelationTypes.Add(Enum::"Email Relation Type"::"Primary Source".AsInteger());

        if Customer.Get(SalesInvoiceHeader."Sell-to Customer No.") then begin
            SourceTableIDs.Add(Database::Customer);
            SourceIDs.Add(Customer.SystemId);
            SourceRelationTypes.Add(Enum::"Email Relation Type"::"Related Entity".AsInteger());
        end;

        DocumentMailing.EmailFile(AttachmentStream, '', EmailBodyTempBlob, EmailSubjectTxt, SalesInvoiceHeader."No.", CustomerAddress, SalesInvoiceHeader.GetDocTypeTxt(), true, Enum::"Report Selection Usage"::"S.Invoice".AsInteger(), SourceTableIDs, SourceIDs, SourceRelationTypes);
    end;

    local procedure SendInvoiceCancelationEmailFromJobQueue(JobQueueEntry: Record "Job Queue Entry")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        if not SalesInvoiceHeader.Get(JobQueueEntry."Record ID to Process") then
            exit;

        SendInvoiceCancelationEmail(SalesInvoiceHeader);
    end;

    local procedure GetCustomerEmailAddress(SalesInvoiceHeader: Record "Sales Invoice Header"): Text[80]
    var
        Customer: Record Customer;
    begin
        if Customer.Get(SalesInvoiceHeader."Sell-to Customer No.") then
            exit(Customer."E-Mail");
    end;

    local procedure GetDocumentEmailAddress(var SalesInvoiceHeader: Record "Sales Invoice Header"): Text[250]
    var
        EmailParameter: Record "Email Parameter";
    begin
        if EmailParameter.Get(
             SalesInvoiceHeader."No.", EmailParameter."Document Type"::Invoice, EmailParameter."Parameter Type"::Address)
        then
            exit(EmailParameter."Parameter Value");
        exit('');
    end;

    procedure GetEmailAddress(var SalesInvoiceHeader: Record "Sales Invoice Header"): Text[250]
    var
        EmailAddress: Text[250];
    begin
        EmailAddress := GetDocumentEmailAddress(SalesInvoiceHeader);
        if EmailAddress <> '' then
            exit(EmailAddress);

        EmailAddress := GetCustomerEmailAddress(SalesInvoiceHeader);
        exit(EmailAddress);
    end;

    procedure GetEmailSubject(var SalesInvoiceHeader: Record "Sales Invoice Header"): Text[250]
    var
        EmailSubject: Text[250];
    begin
        SalesInvoiceHeader.CalcFields("Amount Including VAT");
        EmailSubject := StrSubstNo(
            CancelationEmailSubjectTxt, SalesInvoiceHeader."No.", ResolveCurrency(SalesInvoiceHeader."Currency Code"),
            SalesInvoiceHeader."Amount Including VAT", SalesInvoiceHeader."Due Date");
        exit(EmailSubject);
    end;

    procedure IsInvoiceCanceled(SalesInvoiceHeader: Record "Sales Invoice Header"): Boolean
    var
        CancelledDocument: Record "Cancelled Document";
    begin
        exit(CancelledDocument.FindSalesCancelledInvoice(SalesInvoiceHeader."No."));
    end;

    local procedure ResolveCurrency(CurrencyCode: Code[10]): Text
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        if CurrencyCode = '' then begin
            GeneralLedgerSetup.Get();
            exit(GeneralLedgerSetup."LCY Code" + ' ');
        end;
        exit(CurrencyCode + ' ');
    end;

    local procedure GetEmailBody(SalesInvoiceHeader: Record "Sales Invoice Header"): Text
    var
        CR: Text[1];
        EmailBodyTxt: Text;
    begin
        CR[1] := 10;

        // Create cancel invoice body message
        EmailBodyTxt := StrSubstNo(GreetingTxt, SalesInvoiceHeader."Sell-to Customer Name") + CR + CR + CanceletionEmailBodyTxt;

        exit(EmailBodyTxt)
    end;
}
