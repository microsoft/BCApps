// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 50163 "Filename Proof Name Routes"
{
    // Names one posted invoice on the three interactive routes, in isolation.
    //
    // It exists because of what the caller does around it: the language proofs alter a posted
    // document, name it, and put it back. The email route renders the report for real, which
    // both writes to the document and can fail for reasons that have nothing to do with naming
    // - and a straight-line call would then skip the restore and leave a customer's posted
    // invoice permanently carrying a language somebody's test gave it.
    //
    // Run through Codeunit.Run, a failure here rolls back what it did and hands control back,
    // so the restore always runs.

    SingleInstance = true;

    trigger OnRun()
    begin
        Clear(PreviewName);
        Clear(DownloadName);
        Clear(EmailName);

        PreviewName := NameAsPreview();
        DownloadName := NameAsDownload();
        EmailName := NameAsEmail();
    end;

    /// <summary>
    /// The document to name. Set before running.
    /// </summary>
    /// <param name="NewSalesInvoiceHeader">The invoice.</param>
    internal procedure SetInvoice(var NewSalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        SalesInvoiceHeader := NewSalesInvoiceHeader;
    end;

    /// <summary>
    /// The three names, after a successful run.
    /// </summary>
    internal procedure GetNames(var NewPreviewName: Text; var NewDownloadName: Text; var NewEmailName: Text)
    begin
        NewPreviewName := PreviewName;
        NewDownloadName := DownloadName;
        NewEmailName := EmailName;
    end;

    local procedure NameAsPreview() Name: Text
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        EmptyRecRef: RecordRef;
        Channel: Enum "Report Filename Output Route";
    begin
        if not ReportFilenameMgt.TryResolve(Report::"Standard Sales - Invoice", Channel::Preview,
             EmptyRecRef, ProofSupport.InvoiceFilterViews(SalesInvoiceHeader), Name)
        then
            exit(DidNotResolveMsg);
    end;

    local procedure NameAsDownload() Name: Text
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        SourceRecRef: RecordRef;
        Channel: Enum "Report Filename Output Route";
    begin
        SalesInvoiceHeader.SetRecFilter();
        SourceRecRef.GetTable(SalesInvoiceHeader);

        if not ReportFilenameMgt.TryResolve(Report::"Standard Sales - Invoice", Channel::Download,
             SourceRecRef, ProofSupport.InvoiceFilterViews(SalesInvoiceHeader), Name)
        then
            exit(DidNotResolveMsg);
    end;

    local procedure NameAsEmail(): Text
    var
        DocumentMailing: Codeunit "Document-Mailing";
        TempBlob: Codeunit "Temp Blob";
        RecRef: RecordRef;
        OutStr: OutStream;
        AttachmentName: Text[250];
    begin
        SalesInvoiceHeader.SetRecFilter();
        RecRef.GetTable(SalesInvoiceHeader);

        TempBlob.CreateOutStream(OutStr);
        Report.SaveAs(Report::"Standard Sales - Invoice", '', ReportFormat::Pdf, OutStr, RecRef);

        DocumentMailing.GetAttachmentFileName(AttachmentName, SalesInvoiceHeader."No.",
            InvoiceDocTypeTok, "Report Selection Usage"::"S.Invoice".AsInteger());

        if AttachmentName = '' then
            exit(DidNotResolveMsg);

        exit(AttachmentName.Replace(PdfExtensionTok, ''));
    end;


    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ProofSupport: Codeunit "Filename Proof Support";
        PreviewName: Text;
        DownloadName: Text;
        EmailName: Text;
        InvoiceDocTypeTok: Label 'Invoice', Locked = true;
        PdfExtensionTok: Label '.pdf', Locked = true;
        DidNotResolveMsg: Label '(did not resolve)';
}
