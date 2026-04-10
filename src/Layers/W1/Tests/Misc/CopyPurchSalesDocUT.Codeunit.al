codeunit 134338 "Copy Purch/Sales Doc UT"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Copy Document] [Event]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        BeforeSalesTxt: Label 'BeforeSales';
        BeforePurchaseTxt: Label 'BeforePurchase';
        AfterSalesTxt: Label 'AfterSales';
        AfterPurchaseTxt: Label 'AfterPurchase';
        SwitchedToLanguageIsNotEqualToTargetTxt: Label 'Switched to language is not equal to target. Target language - %1, actual language - %2.', Comment = '%1 : target language ID, %2 : actual language ID.';
        RestoredLanguageIsNotEqualToTargetTxt: Label 'Restored language is not equal to target. To restore language - %1, actual language - %2.', Comment = '%1 : to restore language ID, %2 : actual language ID.';
        IsInitialized: Boolean;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure FireEventsOnCopySalesDocument()
    var
        FromSalesHeader: Record "Sales Header";
        ToSalesHeader: Record "Sales Header";
        CopyPurchSalesDocUT: Codeunit "Copy Purch/Sales Doc UT";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 170312] "Copy Document Mgt.".CopySalesDoc - fires OnBeforeCopySalesDocument and OnAfterCopySalesDocument events
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Copy Purch/Sales Doc UT");

        // [GIVEN] Source Sales Invoice with "No." = "X"
        // [GIVEN] Destination Sales Header "Y"
        BindSubscription(CopyPurchSalesDocUT);

        LibrarySales.CreateSalesInvoice(FromSalesHeader);
        CreateNewSalesHeader(FromSalesHeader."Sell-to Customer No.", ToSalesHeader);

        // [WHEN] When run "Copy Document Mgt.".CopySalesDoc
        RunCopySalesDoc(FromSalesHeader."No.", ToSalesHeader, "Sales Document Type From"::Invoice, false, false);

        // [THEN] Event OnBeforeCopySalesDocument fired with parameters FromDocType = "Invoice", FromDocNo = "X" and ToSalesHeader = "Y"
        VerifyEventArgs("Sales Document Type From"::Invoice.AsInteger(), FromSalesHeader."No.", ToSalesHeader.RecordId, BeforeSalesTxt);
        // [THEN] Event OnAfterCopySalesDocument fired with parameters FromDocType = "Invoice", FromDocNo = "X" and ToSalesHeader = "Y"
        VerifyEventArgs("Sales Document Type From"::Invoice.AsInteger(), FromSalesHeader."No.", ToSalesHeader.RecordId, AfterSalesTxt);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure FireEventsOnCopyPurchaseDocument()
    var
        FromPurchaseHeader: Record "Purchase Header";
        ToPurchaseHeader: Record "Purchase Header";
        CopyPurchSalesDocUT: Codeunit "Copy Purch/Sales Doc UT";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 170312] "Copy Document Mgt.".CopyPurchDoc - fires OnBeforeCopyPurchaseDocument and OnAfterCopyPurchaseDocument events
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Copy Purch/Sales Doc UT");

        // [GIVEN] Source Purchase Invoice with "No." = "X"
        // [GIVEN] Destination Purchase Header "Y"
        BindSubscription(CopyPurchSalesDocUT);

        LibraryPurchase.CreatePurchaseInvoice(FromPurchaseHeader);
        CreateNewPurchaseHeader(FromPurchaseHeader."Buy-from Vendor No.", ToPurchaseHeader);

        // [WHEN] When run "Copy Document Mgt.".CopyPurchDoc
        RunCopyPurchaseDoc(FromPurchaseHeader."No.", ToPurchaseHeader, "Purchase Document Type From"::Invoice, false, false);

        // [THEN] Event OnBeforeCopyPurchaseDocument fired with parameters FromDocType = "Invoice", FromDocNo = "X" and ToPurchaseHeader = "Y"
        VerifyEventArgs("Purchase Document Type From"::Invoice.AsInteger(), FromPurchaseHeader."No.", ToPurchaseHeader.RecordId, BeforePurchaseTxt);
        // [THEN] Event OnAfterCopyPurchaseDocument fired with parameters FromDocType = "Invoice", FromDocNo = "X" and ToPurchaseHeader = "Y"
        VerifyEventArgs("Purchase Document Type From"::Invoice.AsInteger(), FromPurchaseHeader."No.", ToPurchaseHeader.RecordId, AfterPurchaseTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SwitchGlobalLanguageUT()
    var
        Language: Record Language;
        TranslationHelper: Codeunit "Translation Helper";
        DEU_ID: Integer;
        DAN_ID: Integer;
        SAVED_ID: Integer;
    begin
        // [FEATURE] [Language]
        // [SCENARIO 381564] Switch to target language by its code through Language Management, check current language ID to target ID, restore through Language Management and check again to saved language ID.
        Initialize();

        // Save for tear Down.
        SAVED_ID := GlobalLanguage;

        // [GIVEN] Windows Language IDs of DEU and DAN from Language table.
        Language.Get('DEU');
        DEU_ID := Language."Windows Language ID";
        Language.Get('DAN');
        DAN_ID := Language."Windows Language ID";

        // [GIVEN] Set language to DEU by standard GLOBALLANGUAGE function.
        GlobalLanguage(DEU_ID);

        // [WHEN] Switch to DAN language through TranslationHelper.SetGlobalLanguageByCode('DAN') (code param) function
        TranslationHelper.SetGlobalLanguageByCode('DAN');

        // [THEN] Standard GLOBALLANGUAGE() returns ID of DAN.
        Assert.AreEqual(DAN_ID, GlobalLanguage, StrSubstNo(SwitchedToLanguageIsNotEqualToTargetTxt, DAN_ID, GlobalLanguage));

        // [WHEN] Switch back to DEU language through TranslationHelper.RestoreGlobalLanguage (no params) function
        TranslationHelper.RestoreGlobalLanguage();

        // [THEN] Standard GLOBALLANGUAGE() returns ID of DEU.
        Assert.AreEqual(DEU_ID, GlobalLanguage, StrSubstNo(RestoredLanguageIsNotEqualToTargetTxt, DAN_ID, GlobalLanguage));

        // Tear Down.
        GlobalLanguage(SAVED_ID);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopySalesDocCopiesPaymentTermCodeToSalesCreditMemo()
    var
        FromSalesHeader: Record "Sales Header";
        ToSalesHeader: Record "Sales Header";
        PaymentTerms: Record "Payment Terms";
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 342193] CopyDocumentMgt.CopySalesDoc copies Payment Terms to Sales Credit Memo.
        Initialize();

        // [GIVEN] Sales Invoice with Payment Term Code and Sales Credit memo.
        LibrarySales.CreateSalesHeader(FromSalesHeader, FromSalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        FromSalesHeader.Validate("Payment Terms Code", PaymentTerms.Code);
        FromSalesHeader.Modify(true);
        LibrarySales.CreateSalesHeader(
          ToSalesHeader, ToSalesHeader."Document Type"::"Credit Memo", FromSalesHeader."Sell-to Customer No.");

        // [WHEN] CopySalesDoc is used to copy Sales Invoice to Sales Credit memo.
        CopyDocumentMgt.SetProperties(true, false, false, false, true, false, false);
        CopyDocumentMgt.CopySalesDoc("Sales Document Type From"::Invoice, FromSalesHeader."No.", ToSalesHeader);

        // [THEN] Sales Credit Memo has the same Payment Term Code as Sales Invoice.
        Assert.AreEqual(PaymentTerms.Code, ToSalesHeader."Payment Terms Code", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopySalesDocCopiesPaymentTermCodeToPurchaseCreditMemo()
    var
        FromPurchHeader: Record "Purchase Header";
        ToPurchHeader: Record "Purchase Header";
        PaymentTerms: Record "Payment Terms";
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 342193] CopyDocumentMgt.CopyPurchDoc copies Payment Terms to Purchase Credit Memo.
        Initialize();

        // [GIVEN] Purchase Invoice with Payment Term Code and Purchase Credit memo.
        LibraryPurchase.CreatePurchHeader(FromPurchHeader, FromPurchHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        FromPurchHeader.Validate("Payment Terms Code", PaymentTerms.Code);
        FromPurchHeader.Modify(true);
        LibraryPurchase.CreatePurchHeader(
          ToPurchHeader, ToPurchHeader."Document Type"::"Credit Memo", FromPurchHeader."Sell-to Customer No.");

        // [WHEN] CopyPurchDoc is used to copy Purchase Invoice to Purchase Credit memo.
        CopyDocumentMgt.SetProperties(true, false, false, false, true, false, false);
        CopyDocumentMgt.CopyPurchDoc("Purchase Document Type From"::Invoice, FromPurchHeader."No.", ToPurchHeader);

        // [THEN] Purchase Credit Memo has the same Payment Term Code as Purchase Invoice.
        Assert.AreEqual(PaymentTerms.Code, ToPurchHeader."Payment Terms Code", '');
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Copy Purch/Sales Doc UT");

        if IsInitialized then
            exit;

        IsInitialized := true;
        Commit();
    end;

    local procedure CreateNewSalesHeader(CustomerNo: Code[20]; var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.Init();
        SalesHeader.Insert(true);
        SalesHeader.Validate("Sell-to Customer No.", CustomerNo);
        SalesHeader.Modify(true);
    end;

    local procedure CreateNewPurchaseHeader(VendorNo: Code[20]; var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.Init();
        PurchaseHeader.Insert(true);
        PurchaseHeader.Validate("Buy-from Vendor No.", VendorNo);
        PurchaseHeader.Modify(true);
    end;

    local procedure InsertBufferEntry(FromDocumentType: Option; FromDocumentNo: Code[20]; ToRecordID: RecordID; EventName: Text[250])
    var
        NameValueBuffer: Record "Name/Value Buffer";
    begin
        NameValueBuffer.Init();
        NameValueBuffer.Name := EventName;
        NameValueBuffer.Value := GetValueText(FromDocumentType, FromDocumentNo, ToRecordID);
        NameValueBuffer.Insert();
    end;

    local procedure GetValueText(FromDocumentType: Option; FromDocumentNo: Code[20]; ToRecordID: RecordID) Result: Text[250]
    begin
        Result :=
          CopyStr(
            StrSubstNo('%1 - %2 - %3', Format(FromDocumentType), FromDocumentNo, Format(ToRecordID)),
            1,
            MaxStrLen(Result));
        exit(Result);
    end;

    local procedure RunCopyPurchaseDoc(DocumentNo: Code[20]; NewPurchHeader: Record "Purchase Header"; FromDocType: Enum "Purchase Document Type From"; IncludeHeader: Boolean; RecalculateLines: Boolean)
    var
        CopyPurchDoc: Report "Copy Purchase Document";
    begin
        Clear(CopyPurchDoc);
        CopyPurchDoc.SetParameters(FromDocType, DocumentNo, IncludeHeader, RecalculateLines);
        CopyPurchDoc.SetPurchHeader(NewPurchHeader);
        CopyPurchDoc.UseRequestPage(false);
        CopyPurchDoc.RunModal();
    end;

    local procedure RunCopySalesDoc(DocumentNo: Code[20]; NewSalesHeader: Record "Sales Header"; FromDocType: Enum "Sales Document Type From"; IncludeHeader: Boolean; RecalculateLines: Boolean)
    var
        CopySalesDoc: Report "Copy Sales Document";
    begin
        Clear(CopySalesDoc);
        CopySalesDoc.SetParameters(FromDocType, DocumentNo, IncludeHeader, RecalculateLines);
        CopySalesDoc.SetSalesHeader(NewSalesHeader);
        CopySalesDoc.UseRequestPage(false);
        CopySalesDoc.RunModal();
    end;

    local procedure VerifyEventArgs(FromDocumentType: Option; FromDocumentNo: Code[20]; ToRecordID: RecordID; ExpectedEventName: Text)
    var
        NameValueBuffer: Record "Name/Value Buffer";
    begin
        NameValueBuffer.SetRange(Name, ExpectedEventName);
        NameValueBuffer.FindFirst();
        Assert.AreEqual(
          GetValueText(FromDocumentType, FromDocumentNo, ToRecordID),
          NameValueBuffer.Value,
          'Wrong data passed in event');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Document Mgt.", 'OnBeforeCopySalesDocument', '', false, false)]
    local procedure DecreaseCounterOnBeforeCopySalesDocument(FromDocumentType: Option; FromDocumentNo: Code[20]; var ToSalesHeader: Record "Sales Header")
    begin
        InsertBufferEntry(FromDocumentType, FromDocumentNo, ToSalesHeader.RecordId, BeforeSalesTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Document Mgt.", 'OnBeforeCopyPurchaseDocument', '', false, false)]
    local procedure DecreaseCounterOnBeforeCopyPurchaseDocument(FromDocumentType: Option; FromDocumentNo: Code[20]; var ToPurchaseHeader: Record "Purchase Header")
    begin
        InsertBufferEntry(FromDocumentType, FromDocumentNo, ToPurchaseHeader.RecordId, BeforePurchaseTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Document Mgt.", 'OnAfterCopySalesDocument', '', false, false)]
    local procedure DecreaseCounterOnAfterCopySalesDocument(FromDocumentType: Option; FromDocumentNo: Code[20]; var ToSalesHeader: Record "Sales Header")
    begin
        InsertBufferEntry(FromDocumentType, FromDocumentNo, ToSalesHeader.RecordId, AfterSalesTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Document Mgt.", 'OnAfterCopyPurchaseDocument', '', false, false)]
    local procedure DecreaseCounterOnAfterCopyPurchaseDocument(FromDocumentType: Option; FromDocumentNo: Code[20]; var ToPurchaseHeader: Record "Purchase Header")
    begin
        InsertBufferEntry(FromDocumentType, FromDocumentNo, ToPurchaseHeader.RecordId, AfterPurchaseTxt);
    end;
}

