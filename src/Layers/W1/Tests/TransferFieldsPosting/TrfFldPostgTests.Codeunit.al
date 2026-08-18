codeunit 141954 "TrfFld Postg Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;

    [Test]
    procedure SalesPostingSkipsTransferFieldsTypeMismatch()
    var
        SalesHeader: Record "Sales Header";
        PostedSalesInvoiceHeader: Record "Sales Invoice Header";
        PostedSalesInvoiceNo: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 614967] Sales posting skips mismatched extension fields during TransferFields.
        Initialize();

        // [GIVEN] Sales Invoice "SI" with a mismatched extension field value
        LibrarySales.CreateSalesInvoice(SalesHeader);
        SalesHeader.Validate("Transfer Mismatch Value", 'TYPE-MISMATCH');
        SalesHeader.Modify(true);

        // [WHEN] Sales Invoice "SI" is posted
        PostedSalesInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // [THEN] Posted Sales Invoice "PSI" is created and the mismatched field is skipped
        PostedSalesInvoiceHeader.Get(PostedSalesInvoiceNo);
        Assert.AreEqual(0, PostedSalesInvoiceHeader."Transfer Mismatch Value", 'Mismatched sales field should be skipped during posting.');
    end;

    [Test]
    procedure PurchasePostingSkipsTransferFieldsTypeMismatch()
    var
        PurchaseHeader: Record "Purchase Header";
        PostedPurchaseInvoiceHeader: Record "Purch. Inv. Header";
        PostedPurchaseInvoiceNo: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 614967] Purchase posting skips mismatched extension fields during TransferFields.
        Initialize();

        // [GIVEN] Purchase Invoice "PI" with a mismatched extension field value
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        PurchaseHeader.Validate("Transfer Mismatch Value", 'TYPE-MISMATCH');
        PurchaseHeader.Modify(true);

        // [WHEN] Purchase Invoice "PI" is posted
        PostedPurchaseInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [THEN] Posted Purchase Invoice "PPI" is created and the mismatched field is skipped
        PostedPurchaseInvoiceHeader.Get(PostedPurchaseInvoiceNo);
        Assert.AreEqual(0, PostedPurchaseInvoiceHeader."Transfer Mismatch Value", 'Mismatched purchase field should be skipped during posting.');
    end;

    [Test]
    procedure ServicePostingSkipsTransferFieldsTypeMismatch()
    var
        ServiceHeader: Record "Service Header";
        ServiceShipmentHeader: Record "Service Shipment Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 614967] Service posting skips mismatched extension fields during TransferFields.
        Initialize();

        // [GIVEN] Service Order "SO" with a mismatched extension field value
        LibraryService.CreateServiceDocumentWithItemServiceLine(ServiceHeader, ServiceHeader."Document Type"::Order);
        ServiceHeader.Validate("Transfer Mismatch Value", 'TYPE-MISMATCH');
        ServiceHeader.Modify(true);

        // [WHEN] Service Order "SO" is posted with shipment and invoice
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] Posted Service Shipment "PSS" and Service Invoice "PSI" are created and the mismatched field is skipped
        ServiceShipmentHeader.SetRange("Order No.", ServiceHeader."No.");
        Assert.IsTrue(ServiceShipmentHeader.FindFirst(), 'Posted service shipment was not created.');
        Assert.AreEqual(0, ServiceShipmentHeader."Transfer Mismatch Value", 'Mismatched service shipment field should be skipped during posting.');

        ServiceInvoiceHeader.SetRange("Order No.", ServiceHeader."No.");
        Assert.IsTrue(ServiceInvoiceHeader.FindFirst(), 'Posted service invoice was not created.');
        Assert.AreEqual(0, ServiceInvoiceHeader."Transfer Mismatch Value", 'Mismatched service invoice field should be skipped during posting.');
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"TrfFld Postg Tests");
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"TrfFld Postg Tests");
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"TrfFld Postg Tests");
    end;
}
