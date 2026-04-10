codeunit 137040 "SCM Delete Return Orders"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Delete Documents] [Return Order] [Purchase]
        IsInitialized := false;
    end;

    var
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        MsgCorrectedInvoiceNo: Label 'have a Corrected Invoice No. Do you want to continue?';

    [Test]
    [HandlerFunctions('CorrectedInvoiceNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure DeleteInvdPurchReturnOrders()
    var
        PurchHeader: Record "Purchase Header";
        PurchHeader2: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReturnShipmentLine: Record "Return Shipment Line";
        PurchGetReturnShipments: Codeunit "Purch.-Get Return Shipments";
        ReturnPONumber: Code[20];
    begin
        // 1. Setup
        Initialize();

        // Create a new return purchase order.
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchHeader, PurchaseLine, PurchHeader."Document Type"::"Return Order", '', '', LibraryRandom.RandInt(100), '', 0D);

        // Ship the purchase return order.
        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, false);

        // Create a manual purchase credit memo with the items we shipped and post it.
        LibraryPurchase.CreatePurchHeader(PurchHeader2, PurchHeader2."Document Type"::"Credit Memo", PurchHeader."Buy-from Vendor No.");

        // Add the items we just shipped to the purchase credit memo using GetReturnShipments.
        ReturnShipmentLine.SetRange("Buy-from Vendor No.", PurchHeader."Buy-from Vendor No.");

        // Find the last line we posted and filter by it (otherwise we will invoice all possible lines for the vendor).
        ReturnShipmentLine.FindLast();
        ReturnShipmentLine.SetRecFilter();

        PurchGetReturnShipments.SetPurchHeader(PurchHeader2);
        PurchGetReturnShipments.CreateInvLines(ReturnShipmentLine);
        PurchHeader2.Validate("Vendor Cr. Memo No.",
          LibraryUtility.GenerateRandomCode(PurchHeader.FieldNo("Vendor Cr. Memo No."), DATABASE::"Purchase Header"));
        PurchHeader2.Modify(true);

        LibraryPurchase.PostPurchaseDocument(PurchHeader2, true, true);

        // Retrieve the Id so we can ensure it has been deleted.
        ReturnPONumber := PurchHeader."No.";

        // 2. Exercise
        // Since the all items in the purchase order have been shipped (from the PO) and invoiced (from the Purchase Credit Memo)
        // the report should delete the purchase return order we created.
        REPORT.Run(REPORT::"Delete Invd Purch. Ret. Orders", false);

        // 3. Verification
        Assert.IsFalse(PurchHeader.Get(PurchHeader."Document Type"::"Return Order", ReturnPONumber),
          'Invoiced Purchase Return Order shouldn''t exist.');
    end;

    [Test]
    [HandlerFunctions('CorrectedInvoiceNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure DeleteInvdReleasedPurchRetOrd()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ReturnPONumber: Code[20];
    begin
        // Checks deletion of invoiced released purchase return orders if the PRO has been
        // created with 2 lines, one fully shipped and invoiced and the other one is not shipped neither invoiced.
        // Then PRO is reopened, the second line deleted and the PRO is closed. Then report is run and PRO should be deleted
        // because all its existing lines have been shipped and invoiced.

        // 1. Setup
        Initialize();

        // Create a new return purchase order with 2 lines
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchHeader, PurchLine, PurchHeader."Document Type"::"Return Order", '', '', LibraryRandom.RandInt(100), '', 0D);
        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::Item, '', LibraryRandom.RandInt(100));

        // Don't ship the second line.
        PurchLine."Return Qty. to Ship" := 0;
        PurchLine.Modify(true);

        // Ship and Invoice the purchase return order (that will ship only the first line).
        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // reopen the doc and delete the second line, which has not been shipped neither invoiced:
        LibraryPurchase.ReopenPurchaseDocument(PurchHeader);
        PurchLine.Get(PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.");
        PurchLine.Delete();

        // Now the RPO can be released because it only contains one line that has been shipped and invoiced.
        LibraryPurchase.ReleasePurchaseDocument(PurchHeader);
        ReturnPONumber := PurchHeader."No.";

        // 2. Exercise
        // Since the all items in the RPO have been shipped and invoiced (from the RPO)
        // the report should delete the purchase return order we created.
        REPORT.Run(REPORT::"Delete Invd Purch. Ret. Orders", false);

        // 3. Verification
        Assert.IsFalse(PurchHeader.Get(PurchHeader."Document Type"::"Return Order", ReturnPONumber),
          'Invoiced Purchase Return Order shouldn''t exist.');
    end;

    [Normal]
    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Delete Return Orders");
        ExecuteConfirmHandler();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Delete Return Orders");
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateVATData();
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Delete Return Orders");
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure CorrectedInvoiceNoConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(Question, MsgCorrectedInvoiceNo) > 0, Question);
        Reply := true;
    end;

    local procedure ExecuteConfirmHandler()
    begin
        if Confirm(MsgCorrectedInvoiceNo) then;
    end;
}

