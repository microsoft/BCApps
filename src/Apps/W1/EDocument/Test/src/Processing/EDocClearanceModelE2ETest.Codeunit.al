// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using Microsoft.Foundation.NoSeries;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Setup;
using System.Text;
using System.Utilities;

codeunit 139890 "E-Doc Clearance Model E2E Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    EventSubscriberInstance = Manual;
    Permissions = TableData "Sales Header" = rimd,
                  TableData "Sales Invoice Header" = rimd,
                  TableData "Sales Cr.Memo Header" = rimd;

    var
        LibraryAssert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        TestQRBase64: Text;

    [Test]
    [HandlerFunctions('QRCodeViewerPageHandler')]
    procedure TestQRCodeViewerWithSalesInvoiceWithQRCode()
    var
        Customer: Record Customer;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        InvoiceNoTxt: Code[20];
    begin
        // [SCENARIO] Verify that the QR Code Viewer page can be opened for a Sales Invoice that contains QR code data.
        // [GIVEN] A Sales Invoice is created and posted, and QR code data is generated and linked to the posted invoice.
        LibrarySales.CreateCustomer(Customer);

        CheckManualPostedSalesInvoiceSeries('001');
        InvoiceNoTxt := 'TEST-EDOC-QR-001';
        InsertFakePostedSalesInvoice(SalesInvoiceHeader, Customer."No.", InvoiceNoTxt);
        CreateTestQRBufferForSalesInvoice(SalesInvoiceHeader."No.", GetTestBase64QRCode());

        // [WHEN] The user opens the Posted Sales Invoice page and selects the record with the QR code.
        PostedSalesInvoice.OpenView();
        PostedSalesInvoice.GotoRecord(SalesInvoiceHeader);

        // [THEN] The "View QR Code" action should be visible, and the user should be able to invoke it to open the viewer.
        LibraryAssert.IsTrue(PostedSalesInvoice.ViewQRCode.Visible(), 'View QR Code action should be visible.');
        PostedSalesInvoice.ViewQRCode.Invoke();
        // [THEN] The QR Code Viewer page should display the QR code correctly and the base64 content should not be empty.
    end;

    [Test]
    procedure TestQRCodeViewerWithSalesInvoiceWithoutQRCode()
    var
        Cust: Record Customer;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        InvoiceNoTxt: Code[20];
    begin
        // [SCENARIO] Verify that the QR Code Viewer action is not visible for a Sales Invoice without QR code data.
        // [GIVEN] A Sales Invoice without QR code data is created and posted.
        LibrarySales.CreateCustomer(Cust);

        CheckManualPostedSalesInvoiceSeries('002');
        InvoiceNoTxt := 'TEST-EDOC-QR-002';
        InsertFakePostedSalesInvoice(SalesInvoiceHeader, Cust."No.", InvoiceNoTxt);

        // [WHEN] The user opens the Posted Sales Invoice page and selects the record with the QR code.
        PostedSalesInvoice.OpenView();
        PostedSalesInvoice.GotoRecord(SalesInvoiceHeader);

        // [THEN] The "View QR Code" action should not be visible, and the user should be able to invoke it to open the viewer.
        LibraryAssert.IsFalse(PostedSalesInvoice.ViewQRCode.Visible(), 'View QR Code action should not be visible.');
    end;

    [Test]
    [HandlerFunctions('QRCodeViewerPageHandler')]
    procedure TestQRCodeViewerWithSalesCreditMemoWithQRCode()
    var
        Customer: Record Customer;
        SalesCreditMemo: Record "Sales Cr.Memo Header";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
        CreditMemoNo: Code[20];
    begin
        // [SCENARIO] Verify that the QR Code Viewer page can be opened for a Sales Credit Memo that contains QR code data.
        // [GIVEN] A Sales Credit Memo is created and posted, and QR code data is generated and linked to the posted memo.
        LibrarySales.CreateCustomer(Customer);

        CheckManualPostedCrMemoSeries('003');
        CreditMemoNo := 'TEST-EDOC-QR-003';
        InsertFakePostedCrMemo(SalesCreditMemo, Customer."No.", CreditMemoNo);
        CreateTestQRBufferForSalesMemo(SalesCreditMemo."No.", GetTestBase64QRCode());

        // [WHEN] The user opens the Posted Sales Credit Memo page and selects the record with the QR code.
        PostedSalesCreditMemo.OpenView();
        PostedSalesCreditMemo.GotoRecord(SalesCreditMemo);

        // [THEN] The "View QR Code" action should be visible, and the user should be able to invoke it to open the viewer.
        LibraryAssert.IsTrue(PostedSalesCreditMemo.ViewQRCode.Visible(), 'View QR Code action should be visible.');
        PostedSalesCreditMemo.ViewQRCode.Invoke();

        // [THEN] The QR Code Viewer page should display the QR code correctly and the base64 content should not be empty.
    end;

    [Test]
    procedure TestQRCodeViewerWithSalesCreditMemoWithoutQRCode()
    var
        Customer: Record Customer;
        SalesCreditMemo: Record "Sales Cr.Memo Header";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
        CreditMemoNo: Code[20];
    begin
        // [SCENARIO] Verify that the QR Code Viewer action is not visible for a Sales Credit Memo without QR code data.
        // [GIVEN] A Sales Credit Memo without QR code data is created and posted.
        LibrarySales.CreateCustomer(Customer);

        CheckManualPostedCrMemoSeries('004');
        CreditMemoNo := 'TEST-EDOC-QR-004';
        InsertFakePostedCrMemo(SalesCreditMemo, Customer."No.", CreditMemoNo);

        // [WHEN] The user opens the Posted Sales Credit Memo page and selects the record with the QR code.
        PostedSalesCreditMemo.OpenView();
        PostedSalesCreditMemo.GotoRecord(SalesCreditMemo);

        // [THEN] The "View QR Code" action should not be visible, and the user should be able to invoke it to open the viewer.
        LibraryAssert.IsFalse(PostedSalesCreditMemo.ViewQRCode.Visible(), 'View QR Code action should not be visible.');
    end;

    local procedure CreateTestQRBufferForSalesInvoice(SourceNo: Code[20]; QRBase64: Text)
    var
        Inv: Record "Sales Invoice Header";
        Base64Convert: Codeunit "Base64 Convert";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        OutStream: OutStream;
    begin
        if not Inv.Get(SourceNo) then
            Error('Invoice %1 not found.', SourceNo);

        if QRBase64 = '' then
            exit;
        Inv."QR Code Base64".CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(QRBase64);

        TempBlob.CreateOutStream(OutStream);
        Base64Convert.FromBase64(QRBase64, OutStream);

        TempBlob.CreateInStream(InStream);
        Inv."QR Code Image".ImportStream(InStream, 'image/png');

        Inv.Modify();
    end;

    local procedure CreateTestQRBufferForSalesMemo(SourceNo: Code[20]; QRBase64: Text)
    var
        Memo: Record "Sales Cr.Memo Header";
        Base64Convert: Codeunit "Base64 Convert";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        OutStream: OutStream;
    begin
        if not Memo.Get(SourceNo) then
            Error('Memo %1 not found.', SourceNo);

        if QRBase64 = '' then
            exit;
        Memo."QR Code Base64".CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(QRBase64);

        TempBlob.CreateOutStream(OutStream);
        Base64Convert.FromBase64(QRBase64, OutStream);

        TempBlob.CreateInStream(InStream);
        Memo."QR Code Image".ImportStream(InStream, 'image/png');

        Memo.Modify();
    end;

    local procedure GetTestBase64QRCode(): Text
    begin
        TestQRBase64 := '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';
        exit(TestQRBase64);
    end;

    local procedure CheckManualPostedCrMemoSeries(SrNo: Code[3])
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        NoSeries: Record "No. Series";
    begin
        if not SalesReceivablesSetup.Get() then
            SalesReceivablesSetup.Init();

        if SalesReceivablesSetup."Posted Credit Memo Nos." = '' then begin
            NoSeries.Init();
            NoSeries.Code := 'TEST-EDOC-QR' + SrNo;
            NoSeries."Manual Nos." := true;
            NoSeries.Insert(true);

            SalesReceivablesSetup.Validate("Posted Credit Memo Nos.", NoSeries.Code);
            SalesReceivablesSetup.Modify(true);
        end else begin
            NoSeries.Get(SalesReceivablesSetup."Posted Credit Memo Nos.");
            if not NoSeries."Manual Nos." then begin
                NoSeries.Validate("Manual Nos.", true);
                NoSeries.Modify(true);
            end;
        end;
    end;

    local procedure InsertFakePostedCrMemo(var CrMemoHeader: Record "Sales Cr.Memo Header"; CustNo: Code[20]; NoToUse: Code[20])
    begin
        CrMemoHeader.Init();
        CrMemoHeader.Validate("No.", NoToUse);
        CrMemoHeader.Validate("Sell-to Customer No.", CustNo);
        CrMemoHeader.Validate("Bill-to Customer No.", CustNo);
        CrMemoHeader.Validate("Posting Date", WorkDate());
        CrMemoHeader.Validate("VAT Reporting Date", WorkDate());
        CrMemoHeader.Insert(true);
    end;

    local procedure CheckManualPostedSalesInvoiceSeries(SrNo: Code[3])
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        NoSeries: Record "No. Series";
    begin
        if not SalesReceivablesSetup.Get() then
            SalesReceivablesSetup.Init();

        if SalesReceivablesSetup."Posted Invoice Nos." = '' then begin
            NoSeries.Init();
            NoSeries.Code := 'TEST-EDOC-QR' + SrNo;
            NoSeries."Manual Nos." := true;
            NoSeries.Insert(true);

            SalesReceivablesSetup.Validate("Posted Invoice Nos.", NoSeries.Code);
            SalesReceivablesSetup.Modify(true);
        end else begin
            NoSeries.Get(SalesReceivablesSetup."Posted Invoice Nos.");
            if not NoSeries."Manual Nos." then begin
                NoSeries.Validate("Manual Nos.", true);
                NoSeries.Modify(true);
            end;
        end;
    end;

    local procedure InsertFakePostedSalesInvoice(var InvoiceHeader: Record "Sales Invoice Header"; CustNo: Code[20]; NoToUse: Code[20])
    begin
        InvoiceHeader.Init();
        InvoiceHeader.Validate("No.", NoToUse);
        InvoiceHeader.Validate("Sell-to Customer No.", CustNo);
        InvoiceHeader.Validate("Bill-to Customer No.", CustNo);
        InvoiceHeader.Validate("Posting Date", WorkDate());
        InvoiceHeader.Validate("VAT Reporting Date", WorkDate());
        InvoiceHeader.Insert(true);
    end;

    [ModalPageHandler]
    procedure QRCodeViewerPageHandler(var QRCodeViewer: TestPage "E-Document QR Viewer")
    begin
        LibraryAssert.AreNotEqual('', QRCodeViewer.QRCodeBase64Preview.Value(), 'QR Code Base64 preview should not be empty.');
        LibraryAssert.IsTrue(QRCodeViewer.ExportQRCode.Visible(), 'Export QR Code action should be visible.');
        QRCodeViewer.ExportQRCode.Invoke();
    end;
}
