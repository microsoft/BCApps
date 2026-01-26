codeunit 144019 "UT TAB Post Code"
{
    // // [FEATURE] [Post Code] [UT]
    // Test for feature Post Code.

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateAddressServiceQuoteHeader()
    var
        PostCodeRange: Record "Post Code Range";
        ServiceHeader: Record "Service Header";
        ServiceQuote: TestPage "Service Quote";
    begin
        // Purpose of the test is to validate Address - OnValidate Trigger of Table ID - 5900 Service Header.

        // Setup: Create Post Code Range and Service Quote Header.
        CreatePostCodeRange(PostCodeRange);
        OpenServiceQuote(ServiceQuote, CreateServiceHeader(ServiceHeader."Document Type"));

        // Exercise: Set value on Address field of Page - Service Quote.
        ServiceQuote.Address.SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Address, Post Code and City on page - Service Quote.
        ServiceQuote.Address.AssertEquals(PostCodeRange."Street Name");
        ServiceQuote."Post Code".AssertEquals(PostCodeRange."Post Code");
        ServiceQuote.City.AssertEquals(PostCodeRange.City);
        ServiceQuote.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateAddressServiceOrderHeader()
    var
        PostCodeRange: Record "Post Code Range";
        ServiceHeader: Record "Service Header";
        ServiceOrder: TestPage "Service Order";
    begin
        // Purpose of the test is to validate Address - OnValidate Trigger of Table ID - 5900 Service Header.

        // Setup: Create Post Code Range and Service Order Header, open Service Order Page.
        CreatePostCodeRange(PostCodeRange);
        OpenServiceOrder(ServiceOrder, CreateServiceHeader(ServiceHeader."Document Type"::Order));

        // Exercise: Set value on Address field of Page - Service Order.
        ServiceOrder.Address.SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Address, Post Code and City on page - Service Order.
        ServiceOrder.Address.AssertEquals(PostCodeRange."Street Name");
        ServiceOrder."Post Code".AssertEquals(PostCodeRange."Post Code");
        ServiceOrder.City.AssertEquals(PostCodeRange.City);
        ServiceOrder.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateAddressServiceInvoiceHeader()
    var
        PostCodeRange: Record "Post Code Range";
        ServiceHeader: Record "Service Header";
        ServiceInvoice: TestPage "Service Invoice";
    begin
        // Purpose of the test is to validate Address - OnValidate Trigger of Table ID - 5900 Service Header.

        // Setup: Create Post Code Range and Service Invoice Header.
        CreatePostCodeRange(PostCodeRange);
        OpenServiceInvoice(ServiceInvoice, CreateServiceHeader(ServiceHeader."Document Type"::Invoice));

        // Exercise: Set value on Address field of Page - Service Invoice.
        ServiceInvoice.Address.SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Address, Post Code and City on page - Service Invoice.
        ServiceInvoice.Address.AssertEquals(PostCodeRange."Street Name");
        ServiceInvoice."Post Code".AssertEquals(PostCodeRange."Post Code");
        ServiceInvoice.City.AssertEquals(PostCodeRange.City);
        ServiceInvoice.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateAddressServiceCreditMemoHeader()
    var
        PostCodeRange: Record "Post Code Range";
        ServiceHeader: Record "Service Header";
        ServiceCreditMemo: TestPage "Service Credit Memo";
    begin
        // Purpose of the test is to validate Address - OnValidate Trigger of Table ID - 5900 Service Header.

        // Setup: Create Post Code Range and Service Credit Memo Header, open Service Credit Memo Page.
        CreatePostCodeRange(PostCodeRange);
        OpenServiceCreditMemo(ServiceCreditMemo, CreateServiceHeader(ServiceHeader."Document Type"::"Credit Memo"));

        // Exercise: Set value on Address field of Page - Service Credit Memo.
        ServiceCreditMemo.Address.SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Address, Post Code and City on page - Service Credit Memo.
        ServiceCreditMemo.Address.AssertEquals(PostCodeRange."Street Name");
        ServiceCreditMemo."Post Code".AssertEquals(PostCodeRange."Post Code");
        ServiceCreditMemo.City.AssertEquals(PostCodeRange.City);
        ServiceCreditMemo.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateBillToAddressServiceQuoteHeader()
    var
        PostCodeRange: Record "Post Code Range";
        ServiceHeader: Record "Service Header";
        ServiceQuote: TestPage "Service Quote";
    begin
        // Purpose of the test is to validate Bill-to Address - OnValidate Trigger of Table ID - 5900 Service Header.

        // Setup: Create Post Code Range and Service Quote Header, open Service Quote Page.
        CreatePostCodeRange(PostCodeRange);
        OpenServiceQuote(ServiceQuote, CreateServiceHeader(ServiceHeader."Document Type"));

        // Exercise: Set value on Bill-to Address field of Page - Service Quote.
        ServiceQuote."Bill-to Address".SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Bill-to Address, Bill-to Post Code and Bill-to City on page - Service Quote.
        ServiceQuote."Bill-to Address".AssertEquals(PostCodeRange."Street Name");
        ServiceQuote."Bill-to Post Code".AssertEquals(PostCodeRange."Post Code");
        ServiceQuote."Bill-to City".AssertEquals(PostCodeRange.City);
        ServiceQuote.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateBillToAddressServiceOrderHeader()
    var
        PostCodeRange: Record "Post Code Range";
        ServiceHeader: Record "Service Header";
        ServiceOrder: TestPage "Service Order";
    begin
        // Purpose of the test is to validate Bill-to Address - OnValidate Trigger of Table ID - 5900 Service Header.

        // Setup: Create Post Code Range and Service Order Header, open Service Order Page.
        CreatePostCodeRange(PostCodeRange);
        OpenServiceOrder(ServiceOrder, CreateServiceHeader(ServiceHeader."Document Type"::Order));

        // Exercise: Set value on Bill-to Address field of Page - Service Order.
        ServiceOrder."Bill-to Address".SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Bill-to Address, Bill-to Post Code and Bill-to City on page - Service Order.
        ServiceOrder."Bill-to Address".AssertEquals(PostCodeRange."Street Name");
        ServiceOrder."Bill-to Post Code".AssertEquals(PostCodeRange."Post Code");
        ServiceOrder."Bill-to City".AssertEquals(PostCodeRange.City);
        ServiceOrder.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateBillToAddressServiceInvoiceHeader()
    var
        PostCodeRange: Record "Post Code Range";
        ServiceHeader: Record "Service Header";
        ServiceInvoice: TestPage "Service Invoice";
    begin
        // Purpose of the test is to validate Bill-to Address - OnValidate Trigger of Table ID - 5900 Service Header.

        // Setup: Create Post Code Range and Service Invoice Header, open Service Invoice Page.
        CreatePostCodeRange(PostCodeRange);
        OpenServiceInvoice(ServiceInvoice, CreateServiceHeader(ServiceHeader."Document Type"::Invoice));

        // Exercise: Set value on Bill-to Address field of Page - Service Invoice.
        ServiceInvoice."Bill-to Address".SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Bill-to Address, Bill-to Post Code and Bill-to City on page - Service Invoice.
        ServiceInvoice."Bill-to Address".AssertEquals(PostCodeRange."Street Name");
        ServiceInvoice."Bill-to Post Code".AssertEquals(PostCodeRange."Post Code");
        ServiceInvoice."Bill-to City".AssertEquals(PostCodeRange.City);
        ServiceInvoice.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateBillToAddressServiceCreditMemoHeader()
    var
        PostCodeRange: Record "Post Code Range";
        ServiceHeader: Record "Service Header";
        ServiceCreditMemo: TestPage "Service Credit Memo";
    begin
        // Purpose of the test is to validate Bill-to Address - OnValidate Trigger of Table ID - 5900 Service Header.

        // Setup: Create Post Code Range and Service Credit Memo Header, open Service Credit Memo Page.
        CreatePostCodeRange(PostCodeRange);
        OpenServiceCreditMemo(ServiceCreditMemo, CreateServiceHeader(ServiceHeader."Document Type"::"Credit Memo"));

        // Exercise: Set value on Bill-to Address field of Page - Service Credit Memo.
        ServiceCreditMemo."Bill-to Address".SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Bill-to Address, Bill-to Post Code and Bill-to City on page - Service Credit Memo.
        ServiceCreditMemo."Bill-to Address".AssertEquals(PostCodeRange."Street Name");
        ServiceCreditMemo."Bill-to Post Code".AssertEquals(PostCodeRange."Post Code");
        ServiceCreditMemo."Bill-to City".AssertEquals(PostCodeRange.City);
        ServiceCreditMemo.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateShipToAddressServiceQuoteHeader()
    var
        PostCodeRange: Record "Post Code Range";
        ServiceHeader: Record "Service Header";
        ServiceQuote: TestPage "Service Quote";
    begin
        // Purpose of the test is to validate Ship-to Address - OnValidate Trigger of Table ID - 5900 Service Header.

        // Setup: Create Post Code Range and Service Quote Header, open Service Quote Memo Page.
        CreatePostCodeRange(PostCodeRange);
        OpenServiceQuote(ServiceQuote, CreateServiceHeader(ServiceHeader."Document Type"));

        // Exercise: Set value on Ship-to Address field of Page - Service Quote.
        ServiceQuote."Ship-to Address".SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Ship-to Address, Ship-to Post Code and Ship-to City on page - Service Quote.
        ServiceQuote."Ship-to Address".AssertEquals(PostCodeRange."Street Name");
        ServiceQuote."Ship-to Post Code".AssertEquals(PostCodeRange."Post Code");
        ServiceQuote."Ship-to City".AssertEquals(PostCodeRange.City);
        ServiceQuote.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateShipToAddressServiceOrderHeader()
    var
        PostCodeRange: Record "Post Code Range";
        ServiceHeader: Record "Service Header";
        ServiceOrder: TestPage "Service Order";
    begin
        // Purpose of the test is to validate Ship-to Address - OnValidate Trigger of Table ID - 5900 Service Header.

        // Setup: Create Post Code Range and Service Order Header, open Service Order Page.
        CreatePostCodeRange(PostCodeRange);
        OpenServiceOrder(ServiceOrder, CreateServiceHeader(ServiceHeader."Document Type"::Order));

        // Exercise: Set value on Ship-to Address field of Page - Service Order.
        ServiceOrder."Ship-to Address".SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Ship-to Address, Ship-to Post Code and Ship-to City on page - Service Order.
        ServiceOrder."Ship-to Address".AssertEquals(PostCodeRange."Street Name");
        ServiceOrder."Ship-to Post Code".AssertEquals(PostCodeRange."Post Code");
        ServiceOrder."Ship-to City".AssertEquals(PostCodeRange.City);
        ServiceOrder.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateShipToAddressServiceInvoiceHeader()
    var
        PostCodeRange: Record "Post Code Range";
        ServiceHeader: Record "Service Header";
        ServiceInvoice: TestPage "Service Invoice";
    begin
        // Purpose of the test is to validate Ship-to Address - OnValidate Trigger of Table ID - 5900 Service Header.

        // Setup: Create Post Code Range and Service Invoice Header, open Service Invoice Page.
        CreatePostCodeRange(PostCodeRange);
        OpenServiceInvoice(ServiceInvoice, CreateServiceHeader(ServiceHeader."Document Type"::Invoice));

        // Exercise: Set value on Ship-to Address field of Page - Service Invoice.
        ServiceInvoice."Ship-to Address".SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Ship-to Address, Ship-to Post Code and Ship-to City on page - Service Invoice.
        ServiceInvoice."Ship-to Address".AssertEquals(PostCodeRange."Street Name");
        ServiceInvoice."Ship-to Post Code".AssertEquals(PostCodeRange."Post Code");
        ServiceInvoice."Ship-to City".AssertEquals(PostCodeRange.City);
        ServiceInvoice.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateShipToAddressServiceCreditMemoHeader()
    var
        PostCodeRange: Record "Post Code Range";
        ServiceHeader: Record "Service Header";
        ServiceCreditMemo: TestPage "Service Credit Memo";
    begin
        // Purpose of the test is to validate Ship-to Address - OnValidate Trigger of Table ID - 5900 Service Header.

        // Setup: Create Post Code Range and Service Credit Memo Header, open Service Credit Memo Page.
        CreatePostCodeRange(PostCodeRange);
        OpenServiceCreditMemo(ServiceCreditMemo, CreateServiceHeader(ServiceHeader."Document Type"::"Credit Memo"));

        // Exercise: Set value on Ship-to Address field of Page - Service Credit Memo.
        ServiceCreditMemo."Ship-to Address".SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Ship-to Address, Ship-to Post Code and Ship-to City on page - Service Credit Memo.
        ServiceCreditMemo."Ship-to Address".AssertEquals(PostCodeRange."Street Name");
        ServiceCreditMemo."Ship-to Post Code".AssertEquals(PostCodeRange."Post Code");
        ServiceCreditMemo."Ship-to City".AssertEquals(PostCodeRange.City);
        ServiceCreditMemo.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateBuyFromAddressPurchaseQuoteHeader()
    var
        PostCodeRange: Record "Post Code Range";
        PurchaseHeader: Record "Purchase Header";
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        // Purpose of the test is to validate Buy-from Address - OnValidate Trigger of Table ID - 38 Purchase Header.

        // Setup: Create Post Code Range and Purchase Quote Header, open Purchase Quote Page.
        CreatePostCodeRange(PostCodeRange);
        OpenPurchaseQuote(PurchaseQuote, CreatePurchaseHeader(PurchaseHeader."Document Type"::Quote));

        // Exercise: Set value on Buy-from Address field of Page - Purchase Quote.
        PurchaseQuote."Buy-from Address".SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Buy-from Address, Post Code and City on page - Purchase Quote.
        PurchaseQuote."Buy-from Address".AssertEquals(PostCodeRange."Street Name");
        PurchaseQuote."Buy-from Post Code".AssertEquals(PostCodeRange."Post Code");
        PurchaseQuote."Buy-from City".AssertEquals(PostCodeRange.City);
        PurchaseQuote.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateBuyFromAddressPurchaseOrderHeader()
    var
        PostCodeRange: Record "Post Code Range";
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // Purpose of the test is to validate Buy-from Address - OnValidate Trigger of Table ID - 38 Purchase Header.

        // Setup: Create Post Code Range and Purchase Order Header, open Purchase Order Page.
        CreatePostCodeRange(PostCodeRange);
        OpenPurchaseOrder(PurchaseOrder, CreatePurchaseHeader(PurchaseHeader."Document Type"::Order));

        // Exercise: Set value on Buy-from Address field of Page - Purchase Order.
        PurchaseOrder."Buy-from Address".SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Buy-from Address, Buy-from Post Code and Buy-from City on page - Purchase Order.
        PurchaseOrder."Buy-from Address".AssertEquals(PostCodeRange."Street Name");
        PurchaseOrder."Buy-from Post Code".AssertEquals(PostCodeRange."Post Code");
        PurchaseOrder."Buy-from City".AssertEquals(PostCodeRange.City);
        PurchaseOrder.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateBuyFromAddressPurchaseInvoiceHeader()
    var
        PostCodeRange: Record "Post Code Range";
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // Purpose of the test is to validate Buy-from Address - OnValidate Trigger of Table ID - 38 Purchase Header.

        // Setup: Create Post Code Range and Purchase Invoice Header, open Purchase Invoice Page.
        CreatePostCodeRange(PostCodeRange);
        OpenPurchaseInvoice(PurchaseInvoice, CreatePurchaseHeader(PurchaseHeader."Document Type"::Invoice));

        // Exercise: Set value on Buy-from Address field of Page - Purchase Invoice.
        PurchaseInvoice."Buy-from Address".SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Buy-from Address, Buy-from Post Code and Buy-from City on page - Purchase Invoice.
        PurchaseInvoice."Buy-from Address".AssertEquals(PostCodeRange."Street Name");
        PurchaseInvoice."Buy-from Post Code".AssertEquals(PostCodeRange."Post Code");
        PurchaseInvoice."Buy-from City".AssertEquals(PostCodeRange.City);
        PurchaseInvoice.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateBuyFromAddressPurchaseCreditMemoHeader()
    var
        PostCodeRange: Record "Post Code Range";
        PurchaseHeader: Record "Purchase Header";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // Purpose of the test is to validate Buy-from Address - OnValidate Trigger of Table ID - 38 Purchase Header.

        // Setup: Create Post Code Range and Purchase Credit Memo Header, open Purchase Credit Memo Page.
        CreatePostCodeRange(PostCodeRange);
        OpenPurchaseCreditMemo(PurchaseCreditMemo, CreatePurchaseHeader(PurchaseHeader."Document Type"::"Credit Memo"));

        // Exercise: Set value on Buy-from Address field of Page - Purchase Credit Memo.
        PurchaseCreditMemo."Buy-from Address".SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Buy-from Address, Buy-from Post Code and Buy-from City on page - Purchase Credit Memo.
        PurchaseCreditMemo."Buy-from Address".AssertEquals(PostCodeRange."Street Name");
        PurchaseCreditMemo."Buy-from Post Code".AssertEquals(PostCodeRange."Post Code");
        PurchaseCreditMemo."Buy-from City".AssertEquals(PostCodeRange.City);
        PurchaseCreditMemo.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateBuyFromAddressBlanketPurchaseOrderHeader()
    var
        PostCodeRange: Record "Post Code Range";
        PurchaseHeader: Record "Purchase Header";
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
    begin
        // Purpose of the test is to validate Buy-from Address - OnValidate Trigger of Table ID - 38 Purchase Header.

        // Setup: Create Post Code Range and Blanket Purchase Order Header, open Blanket Purchase Order Page.
        CreatePostCodeRange(PostCodeRange);
        OpenBlanketPurchaseOrder(BlanketPurchaseOrder, CreatePurchaseHeader(PurchaseHeader."Document Type"::"Blanket Order"));

        // Exercise: Set value on Buy-from Address field of Page - Blanket Purchase Order.
        BlanketPurchaseOrder."Buy-from Address".SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Buy-from Address, Buy-from Post Code and Buy-from City on page - Blanket Purchase Order.
        BlanketPurchaseOrder."Buy-from Address".AssertEquals(PostCodeRange."Street Name");
        BlanketPurchaseOrder."Buy-from Post Code".AssertEquals(PostCodeRange."Post Code");
        BlanketPurchaseOrder."Buy-from City".AssertEquals(PostCodeRange.City);
        BlanketPurchaseOrder.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateBuyFromAddressPurchaseReturnOrderHeader()
    var
        PostCodeRange: Record "Post Code Range";
        PurchaseHeader: Record "Purchase Header";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        // Purpose of the test is to validate Buy-from Address - OnValidate Trigger of Table ID - 38 Purchase Header.

        // Setup: Create Post Code Range and Purchase Return Order Header, open Purchase Return Order Page.
        CreatePostCodeRange(PostCodeRange);
        OpenPurchaseReturnOrder(PurchaseReturnOrder, CreatePurchaseHeader(PurchaseHeader."Document Type"::"Return Order"));

        // Exercise: Set value on Buy-from Address field of Page - Purchase Return Order.
        PurchaseReturnOrder."Buy-from Address".SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Buy-from Address, Buy-from Post Code and Buy-from City on page - Purchase Return Order.
        PurchaseReturnOrder."Buy-from Address".AssertEquals(PostCodeRange."Street Name");
        PurchaseReturnOrder."Buy-from Post Code".AssertEquals(PostCodeRange."Post Code");
        PurchaseReturnOrder."Buy-from City".AssertEquals(PostCodeRange.City);
        PurchaseReturnOrder.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidatePayToAddressPurchaseQuoteHeader()
    var
        PostCodeRange: Record "Post Code Range";
        PurchaseHeader: Record "Purchase Header";
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        // Purpose of the test is to validate Pay-to Address - OnValidate Trigger of Table ID - 38 Purchase Header.

        // Setup: Create Post Code Range and Purchase Quote Header, open Purchase Quote Page.
        CreatePostCodeRange(PostCodeRange);
        OpenPurchaseQuote(PurchaseQuote, CreatePurchaseHeader(PurchaseHeader."Document Type"::Quote));

        // Exercise: Set value on Pay-to Address field of Page - Purchase Quote.
        PurchaseQuote."Pay-to Address".SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Pay-to Address, Pay-to Post Code and Pay-to City on page - Purchase Quote.
        PurchaseQuote."Pay-to Address".AssertEquals(PostCodeRange."Street Name");
        PurchaseQuote."Pay-to Post Code".AssertEquals(PostCodeRange."Post Code");
        PurchaseQuote."Pay-to City".AssertEquals(PostCodeRange.City);
        PurchaseQuote.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidatePayToAddressPurchaseOrderHeader()
    var
        PostCodeRange: Record "Post Code Range";
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // Purpose of the test is to validate Pay-to Address - OnValidate Trigger of Table ID - 38 Purchase Header.

        // Setup: Create Post Code Range and Purchase Order Header, open Purchase Order Page.
        CreatePostCodeRange(PostCodeRange);
        OpenPurchaseOrder(PurchaseOrder, CreatePurchaseHeader(PurchaseHeader."Document Type"::Order));

        // Exercise: Set value on Pay-to Address field of Page - Purchase Order.
        PurchaseOrder."Pay-to Address".SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Pay-to Address, Pay-to Post Code and Pay-to City on page - Purchase Order.
        PurchaseOrder."Pay-to Address".AssertEquals(PostCodeRange."Street Name");
        PurchaseOrder."Pay-to Post Code".AssertEquals(PostCodeRange."Post Code");
        PurchaseOrder."Pay-to City".AssertEquals(PostCodeRange.City);
        PurchaseOrder.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidatePayToAddressPurchaseInvoiceHeader()
    var
        PostCodeRange: Record "Post Code Range";
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // Purpose of the test is to validate Pay-to Address - OnValidate Trigger of Table ID - 38 Purchase Header.

        // Setup: Create Post Code Range and Purchase Invoice Header, open Purchase Invoice Page.
        CreatePostCodeRange(PostCodeRange);
        OpenPurchaseInvoice(PurchaseInvoice, CreatePurchaseHeader(PurchaseHeader."Document Type"::Invoice));

        // Exercise: Set value on Pay-to Address field of Page - Purchase Invoice.
        PurchaseInvoice."Pay-to Address".SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Pay-to Address, Pay-to Post Code and Pay-to City on page - Purchase Invoice.
        PurchaseInvoice."Pay-to Address".AssertEquals(PostCodeRange."Street Name");
        PurchaseInvoice."Pay-to Post Code".AssertEquals(PostCodeRange."Post Code");
        PurchaseInvoice."Pay-to City".AssertEquals(PostCodeRange.City);
        PurchaseInvoice.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidatePayToAddressPurchaseCreditMemoHeader()
    var
        PostCodeRange: Record "Post Code Range";
        PurchaseHeader: Record "Purchase Header";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // Purpose of the test is to validate Pay-to Address - OnValidate Trigger of Table ID - 38 Purchase Header.

        // Setup: Create Post Code Range and Purchase Credit Memo Header, open Purchase Credit Memo Page.
        CreatePostCodeRange(PostCodeRange);
        OpenPurchaseCreditMemo(PurchaseCreditMemo, CreatePurchaseHeader(PurchaseHeader."Document Type"::"Credit Memo"));

        // Exercise: Set value on Pay-to Address field of Page - Purchase Credit Memo.
        PurchaseCreditMemo."Pay-to Address".SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Pay-to Address, Pay-to Post Code and Pay-to City on page - Purchase Credit Memo.
        PurchaseCreditMemo."Pay-to Address".AssertEquals(PostCodeRange."Street Name");
        PurchaseCreditMemo."Pay-to Post Code".AssertEquals(PostCodeRange."Post Code");
        PurchaseCreditMemo."Pay-to City".AssertEquals(PostCodeRange.City);
        PurchaseCreditMemo.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidatePayToAddressBlanketPurchaseOrderHeader()
    var
        PostCodeRange: Record "Post Code Range";
        PurchaseHeader: Record "Purchase Header";
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
    begin
        // Purpose of the test is to validate Pay-to Address - OnValidate Trigger of Table ID - 38 Purchase Header.

        // Setup: Create Post Code Range and Blanket Purchase Order Header, open Blanket Purchase Order Page.
        CreatePostCodeRange(PostCodeRange);
        OpenBlanketPurchaseOrder(BlanketPurchaseOrder, CreatePurchaseHeader(PurchaseHeader."Document Type"::"Blanket Order"));

        // Exercise: Set value on Pay-to Address field of Page - Blanket Purchase Order.
        BlanketPurchaseOrder."Pay-to Address".SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Pay-to Address, Pay-to Post Code and Pay-to City on page - Blanket Purchase Order.
        BlanketPurchaseOrder."Pay-to Address".AssertEquals(PostCodeRange."Street Name");
        BlanketPurchaseOrder."Pay-to Post Code".AssertEquals(PostCodeRange."Post Code");
        BlanketPurchaseOrder."Pay-to City".AssertEquals(PostCodeRange.City);
        BlanketPurchaseOrder.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidatePayToAddressPurchaseReturnOrderHeader()
    var
        PostCodeRange: Record "Post Code Range";
        PurchaseHeader: Record "Purchase Header";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        // Purpose of the test is to validate Pay-to Address - OnValidate Trigger of Table ID - 38 Purchase Header.

        // Setup: Create Post Code Range and Purchase Return Order Header, open Purchase Return Order Page.
        CreatePostCodeRange(PostCodeRange);
        OpenPurchaseReturnOrder(PurchaseReturnOrder, CreatePurchaseHeader(PurchaseHeader."Document Type"::"Return Order"));

        // Exercise: Set value on Pay-to Address field of Page - Purchase Return Order.
        PurchaseReturnOrder."Pay-to Address".SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Pay-to Address, Pay-to Post Code and Pay-to City on page - Purchase Return Order.
        PurchaseReturnOrder."Pay-to Address".AssertEquals(PostCodeRange."Street Name");
        PurchaseReturnOrder."Pay-to Post Code".AssertEquals(PostCodeRange."Post Code");
        PurchaseReturnOrder."Pay-to City".AssertEquals(PostCodeRange.City);
        PurchaseReturnOrder.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateShipToAddressPurchaseCreditMemoHeader()
    var
        PostCodeRange: Record "Post Code Range";
        PurchaseHeader: Record "Purchase Header";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // Purpose of the test is to validate Ship-to Address - OnValidate Trigger of Table ID - 38 Purchase Header.

        // Setup: Create Post Code Range and Purchase Credit Memo Header, open Purchase Credit Memo Page.
        CreatePostCodeRange(PostCodeRange);
        OpenPurchaseCreditMemo(PurchaseCreditMemo, CreatePurchaseHeader(PurchaseHeader."Document Type"::"Credit Memo"));

        // Exercise: Set value on Ship-to Address field of Page - Purchase Credit Memo.
        PurchaseCreditMemo."Ship-to Address".SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Ship-to Address, Ship-to Post Code and Ship-to City on page - Purchase Credit Memo.
        PurchaseCreditMemo."Ship-to Address".AssertEquals(PostCodeRange."Street Name");
        PurchaseCreditMemo."Ship-to Post Code".AssertEquals(PostCodeRange."Post Code");
        PurchaseCreditMemo."Ship-to City".AssertEquals(PostCodeRange.City);
        PurchaseCreditMemo.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateShipToAddressBlanketPurchaseOrderHeader()
    var
        PostCodeRange: Record "Post Code Range";
        PurchaseHeader: Record "Purchase Header";
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
    begin
        // Purpose of the test is to validate Ship-to Address - OnValidate Trigger of Table ID - 38 Purchase Header.

        // Setup: Create Post Code Range and Blanket Purchase Order Header, open Blanket Purchase Order Page.
        CreatePostCodeRange(PostCodeRange);
        OpenBlanketPurchaseOrder(BlanketPurchaseOrder, CreatePurchaseHeader(PurchaseHeader."Document Type"::"Blanket Order"));

        // Exercise: Set value on Ship-to Address field of Page - Blanket Purchase Order.
        BlanketPurchaseOrder."Ship-to Address".SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Ship-to Address, Ship-to Post Code and Ship-to City on page - Blanket Purchase Order.
        BlanketPurchaseOrder."Ship-to Address".AssertEquals(PostCodeRange."Street Name");
        BlanketPurchaseOrder."Ship-to Post Code".AssertEquals(PostCodeRange."Post Code");
        BlanketPurchaseOrder."Ship-to City".AssertEquals(PostCodeRange.City);
        BlanketPurchaseOrder.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateAddressVendor()
    var
        PostCodeRange: Record "Post Code Range";
        VendorCard: TestPage "Vendor Card";
    begin
        // Purpose of the test is to validate Address - OnValidate Trigger of Table ID - 23 Vendor.

        // Setup: Create Post Code Range and Vendor, open Vendor Page.
        CreatePostCodeRange(PostCodeRange);
        VendorCard.OpenEdit();
        VendorCard.FILTER.SetFilter("No.", CreateVendor());

        // Exercise: Set value on Address field of Page - Vendor Card.
        VendorCard.Address.SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Address, Post Code and City on page - Vendor Card.
        VendorCard.Address.AssertEquals(PostCodeRange."Street Name");
        VendorCard."Post Code".AssertEquals(PostCodeRange."Post Code");
        VendorCard.City.AssertEquals(PostCodeRange.City);
        VendorCard.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateAddressVendorBankAccount()
    var
        PostCodeRange: Record "Post Code Range";
        VendorBankAccountCard: TestPage "Vendor Bank Account Card";
    begin
        // Purpose of the test is to validate Address - OnValidate Trigger of Table ID - 288 Vendor Bank Account.

        // Setup: Create Post Code Range and Vendor Bank Account, open Vendor Bank Account Page.
        CreatePostCodeRange(PostCodeRange);
        OpenVendorBankAccountCard(VendorBankAccountCard);

        // Exercise: Set value on Address field of Page - Vendor Bank Account Card.
        VendorBankAccountCard.Address.SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Address, Post Code and City on page - Vendor Bank Account Card.
        VendorBankAccountCard.Address.AssertEquals(PostCodeRange."Street Name");
        VendorBankAccountCard."Post Code".AssertEquals(PostCodeRange."Post Code");
        VendorBankAccountCard.City.AssertEquals(PostCodeRange.City);
        VendorBankAccountCard.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateAccountHolderAddressVendorBankAccount()
    var
        PostCodeRange: Record "Post Code Range";
        VendorBankAccountCard: TestPage "Vendor Bank Account Card";
    begin
        // Purpose of the test is to validate Account Holder Address - OnValidate Trigger of Table ID - 288 Vendor Bank Account.

        // Setup: Create Post Code Range and Vendor Bank Account, open Vendor Bank Account Page.
        CreatePostCodeRange(PostCodeRange);
        OpenVendorBankAccountCard(VendorBankAccountCard);

        // Exercise: Set value on Account Holder Address field of Page - Vendor Bank Account Card.
        VendorBankAccountCard."Account Holder Address".SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Account Holder Address, Post Code and City on page - Vendor Bank Account Card.
        VendorBankAccountCard."Account Holder Address".AssertEquals(PostCodeRange."Street Name");
        VendorBankAccountCard."Account Holder Post Code".AssertEquals(PostCodeRange."Post Code");
        VendorBankAccountCard."Account Holder City".AssertEquals(PostCodeRange.City);
        VendorBankAccountCard.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateAddressCompanyInformation()
    var
        PostCodeRange: Record "Post Code Range";
        CompanyInformation: TestPage "Company Information";
    begin
        // Purpose of the test is to validate Address - OnValidate Trigger of Table ID - 79 Company Information.

        // Setup: Create Post Code Range, open Company Information page.
        CreatePostCodeRange(PostCodeRange);
        CompanyInformation.OpenEdit();

        // Exercise: Set value on Address field of Page - Company Information.
        CompanyInformation.Address.SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Address, Post Code and City on page - Company Information.
        CompanyInformation.Address.AssertEquals(PostCodeRange."Street Name");
        CompanyInformation."Post Code".AssertEquals(PostCodeRange."Post Code");
        CompanyInformation.City.AssertEquals(PostCodeRange.City);
        CompanyInformation.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateShipToAddressCompanyInformation()
    var
        PostCodeRange: Record "Post Code Range";
        CompanyInformation: TestPage "Company Information";
    begin
        // Purpose of the test is to validate Ship-to Address - OnValidate Trigger of Table ID - 79 Company Information.

        // Setup: Create Post Code Range, open Company Information page.
        CreatePostCodeRange(PostCodeRange);
        CompanyInformation.OpenEdit();

        // Exercise: Set value on Ship-to Address field of Page - Company Information.
        CompanyInformation."Ship-to Address".SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Ship-to Address, Ship-to Post Code and Ship-to City on page - Company Information.
        CompanyInformation."Ship-to Address".AssertEquals(PostCodeRange."Street Name");
        CompanyInformation."Ship-to Post Code".AssertEquals(PostCodeRange."Post Code");
        CompanyInformation."Ship-to City".AssertEquals(PostCodeRange.City);
        CompanyInformation.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateAccountHolderAddressBankAccount()
    var
        PostCodeRange: Record "Post Code Range";
        BankAccountCard: TestPage "Bank Account Card";
    begin
        // Purpose of the test is to validate Bank Account Holder Address - OnValidate Trigger of Table ID - 270 Bank Account.

        // Setup: Create Post Code Range and Bank Account, open Bank Account card.
        CreatePostCodeRange(PostCodeRange);
        OpenBankAccountCard(BankAccountCard, CreateBankAccount());

        // Exercise: Set value on Account Holder Address field of Page - Bank Account Card.
        BankAccountCard."Account Holder Address".SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Account Holder Address, Account Holder Post Code and Account Holder City on page - Bank Account Card.
        BankAccountCard."Account Holder Address".AssertEquals(PostCodeRange."Street Name");
        BankAccountCard."Account Holder Post Code".AssertEquals(PostCodeRange."Post Code");
        BankAccountCard."Account Holder City".AssertEquals(PostCodeRange.City);
        BankAccountCard.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateAddressBankAccount()
    var
        PostCodeRange: Record "Post Code Range";
        BankAccountCard: TestPage "Bank Account Card";
    begin
        // Purpose of the test is to validate Address - OnValidate Trigger of Table ID - 270 Bank Account.

        // Setup: Create Post Code Range and Bank Account, open Bank Account card.
        CreatePostCodeRange(PostCodeRange);
        OpenBankAccountCard(BankAccountCard, CreateBankAccount());

        // Exercise: Set value on Address field of Page - Bank Account Card.
        BankAccountCard.Address.SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Address, Post Code and City on page - Bank Account Card.
        BankAccountCard.Address.AssertEquals(PostCodeRange."Street Name");
        BankAccountCard."Post Code".AssertEquals(PostCodeRange."Post Code");
        BankAccountCard.City.AssertEquals(PostCodeRange.City);
        BankAccountCard.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateAddressContact()
    var
        Contact: Record Contact;
        PostCodeRange: Record "Post Code Range";
        CompanyDetails: TestPage "Company Details";
    begin
        // Purpose of the test is to validate Address - OnValidate Trigger of Table ID - 5050 Contact.

        // Setup: Create Post Code Range, open Company Details page.
        CreatePostCodeRange(PostCodeRange);
        Contact.Init();
        Contact.Insert();
        CompanyDetails.OpenEdit();

        // Exercise: Set value on Address field of Page - Company Details.
        CompanyDetails.Address.SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Address, Post Code and City on page - Company Details.
        CompanyDetails.Address.AssertEquals(PostCodeRange."Street Name");
        CompanyDetails."Post Code".AssertEquals(PostCodeRange."Post Code");
        CompanyDetails.City.AssertEquals(PostCodeRange.City);
        CompanyDetails.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateAddressContactAlternativeAddress()
    var
        PostCodeRange: Record "Post Code Range";
        ContactAltAddressCard: TestPage "Contact Alt. Address Card";
    begin
        // Purpose of the test is to validate Address - OnValidate Trigger of Table ID - 5051 Contact Alt. Address.

        // Setup: Create Post Code Range and Contact Alternative Address, open Contact Alternative Address Card.
        CreatePostCodeRange(PostCodeRange);
        ContactAltAddressCard.OpenEdit();
        ContactAltAddressCard.FILTER.SetFilter(Code, CreateContactAlternativeAddress());

        // Exercise: Set value on Address field of Page - Contact Alt. Address Card.
        ContactAltAddressCard.Address.SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Address, Post Code and City on page - Contact Alt. Address Card.
        ContactAltAddressCard.Address.AssertEquals(PostCodeRange."Street Name");
        ContactAltAddressCard."Post Code".AssertEquals(PostCodeRange."Post Code");
        ContactAltAddressCard.City.AssertEquals(PostCodeRange.City);
        ContactAltAddressCard.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateAddressContactCardAlternativeAddress()
    var
        PostCodeRange: Record "Post Code Range";
        ContactCard: TestPage "Contact Card";
    begin
        // Purpose of the test is to validate Address - OnValidate Trigger of Table ID - 5051 Contact Alt. Address.

        // Setup: Create Post Code Range and Contact, open and Contact Card.
        CreatePostCodeRange(PostCodeRange);
        ContactCard.OpenEdit();
        ContactCard.FILTER.SetFilter("No.", CreateContact());

        // Exercise: Set value on Address field of Page - Contact Card.
        ContactCard.Address.SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Address, Post Code and City on page - Contact Card.
        ContactCard.Address.AssertEquals(PostCodeRange."Street Name");
        ContactCard."Post Code".AssertEquals(PostCodeRange."Post Code");
        ContactCard.City.AssertEquals(PostCodeRange.City);
        ContactCard.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateAddressFinanceChargeMemoHeader()
    var
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        PostCodeRange: Record "Post Code Range";
        FinanceChargeMemo: TestPage "Finance Charge Memo";
    begin
        // Purpose of the test is to validate Address - OnValidate Trigger of Table ID - 302 Finance Charge Memo Header.

        // Setup: Create Post Code Range and Finance Charge Memo Header, open Finance Charge Memo page.
        CreatePostCodeRange(PostCodeRange);
        FinanceChargeMemoHeader."No." := LibraryUTUtility.GetNewCode();
        FinanceChargeMemoHeader.Insert();
        FinanceChargeMemo.OpenEdit();
        FinanceChargeMemo.FILTER.SetFilter("No.", FinanceChargeMemoHeader."No.");

        // Exercise: Set value on Address field of Page - Finance Charge Memo.
        FinanceChargeMemo.Address.SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Address, Post Code and City on page - Finance Charge Memo.
        FinanceChargeMemo.Address.AssertEquals(PostCodeRange."Street Name");
        FinanceChargeMemo."Post Code".AssertEquals(PostCodeRange."Post Code");
        FinanceChargeMemo.City.AssertEquals(PostCodeRange.City);
        FinanceChargeMemo.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateAddressLocation()
    var
        PostCodeRange: Record "Post Code Range";
        LocationCard: TestPage "Location Card";
    begin
        // Purpose of the test is to validate Address - OnValidate Trigger of Table ID - 14 Location.

        // Setup: Create Post Code Range and Location, open Location Card.
        CreatePostCodeRange(PostCodeRange);
        LocationCard.OpenEdit();
        LocationCard.FILTER.SetFilter(Code, CreateLocation());

        // Exercise: Set value on Address field of Page - Location Card.
        LocationCard.Address.SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Address, Post Code and City on page - Location Card.
        LocationCard.Address.AssertEquals(PostCodeRange."Street Name");
        LocationCard."Post Code".AssertEquals(PostCodeRange."Post Code");
        LocationCard.City.AssertEquals(PostCodeRange.City);
        LocationCard.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateAddressOrderAddress()
    var
        PostCodeRange: Record "Post Code Range";
        OrderAddressPage: TestPage "Order Address";
    begin
        // Purpose of the test is to validate Address - OnValidate Trigger of Table ID - 224 Order Address.

        // Setup: Create Post Code Range and Order Address, open Order Address page.
        CreatePostCodeRange(PostCodeRange);
        OrderAddressPage.OpenEdit();
        OrderAddressPage.FILTER.SetFilter(Code, CreateOrderAddress());

        // Exercise: Set value on Address field of Page - Order Address.
        OrderAddressPage.Address.SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Address, Post Code and City on page - Order Address.
        OrderAddressPage.Address.AssertEquals(PostCodeRange."Street Name");
        OrderAddressPage."Post Code".AssertEquals(PostCodeRange."Post Code");
        OrderAddressPage.City.AssertEquals(PostCodeRange.City);
        OrderAddressPage.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateAddressReminderHeader()
    var
        PostCodeRange: Record "Post Code Range";
        ReminderHeader: Record "Reminder Header";
        Reminder: TestPage Reminder;
    begin
        // Purpose of the test is to validate Address - OnValidate Trigger of Table ID - 295 Reminder Header.

        // Setup: Create Post Code Range and Reminder Header, open Reminder page.
        CreatePostCodeRange(PostCodeRange);
        ReminderHeader."No." := LibraryUTUtility.GetNewCode();
        ReminderHeader.Insert();
        Reminder.OpenEdit();
        Reminder.FILTER.SetFilter("No.", ReminderHeader."No.");

        // Exercise: Set value on Address field of Page - Reminder.
        Reminder.Address.SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Address, Post Code and City on page - Reminder.
        Reminder.Address.AssertEquals(PostCodeRange."Street Name");
        Reminder."Post Code".AssertEquals(PostCodeRange."Post Code");
        Reminder.City.AssertEquals(PostCodeRange.City);
        Reminder.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateAddressResponsibilityCenter()
    var
        PostCodeRange: Record "Post Code Range";
        ResponsibilityCenterCard: TestPage "Responsibility Center Card";
    begin
        // Purpose of the test is to validate Address - OnValidate Trigger of Table ID - 5714 Responsibility Center.

        // Setup: Create Post Code Range, open Responsibility Center Card.
        CreatePostCodeRange(PostCodeRange);
        ResponsibilityCenterCard.OpenEdit();

        // Exercise: Set value on Address field of Page - Responsibility Center Card.
        ResponsibilityCenterCard.Address.SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Address, Post Code and City on page - Responsibility Center Card.
        ResponsibilityCenterCard.Address.AssertEquals(PostCodeRange."Street Name");
        ResponsibilityCenterCard."Post Code".AssertEquals(PostCodeRange."Post Code");
        ResponsibilityCenterCard.City.AssertEquals(PostCodeRange.City);
        ResponsibilityCenterCard.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateAddressResource()
    var
        PostCodeRange: Record "Post Code Range";
        ResourceCard: TestPage "Resource Card";
    begin
        // Purpose of the test is to validate Address - OnValidate Trigger of Table ID - 156 Resource.

        // Setup: Create Post Code Range and Resource, open Resource Card.
        CreatePostCodeRange(PostCodeRange);
        ResourceCard.OpenEdit();
        ResourceCard.FILTER.SetFilter("No.", CreateResource());

        // Exercise: Set value on Address field of Page - Resource Card.
        ResourceCard.Address.SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Address, Post Code and City on page - Resource Card.
        ResourceCard.Address.AssertEquals(PostCodeRange."Street Name");
        ResourceCard."Post Code".AssertEquals(PostCodeRange."Post Code");
        ResourceCard.City.AssertEquals(PostCodeRange.City);
        ResourceCard.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateTransferFromAddressTransferHeader()
    var
        PostCodeRange: Record "Post Code Range";
        TransferOrder: TestPage "Transfer Order";
    begin
        // Purpose of the test is to validate Transfer-from Address - OnValidate Trigger of Table ID - 5740 Transfer Header.

        // Setup: Create Post Code Range and Transfer Header, open Transfer Order page.
        CreatePostCodeRange(PostCodeRange);
        TransferOrder.OpenEdit();
        TransferOrder.FILTER.SetFilter("No.", CreateTransferHeader());

        // Exercise: Set value on Transfer-from Address field of Page -  Transfer Order.
        TransferOrder."Transfer-from Address".SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Transfer-from Address, Transfer-from Post Code and Transfer-from City on page - Transfer Order.
        TransferOrder."Transfer-from Address".AssertEquals(PostCodeRange."Street Name");
        TransferOrder."Transfer-from Post Code".AssertEquals(PostCodeRange."Post Code");
        TransferOrder."Transfer-from City".AssertEquals(PostCodeRange.City);
        TransferOrder.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateTransferToAddressTransferHeader()
    var
        PostCodeRange: Record "Post Code Range";
        TransferOrder: TestPage "Transfer Order";
    begin
        // Purpose of the test is to validate Transfer-to Address - OnValidate Trigger of Table ID - 5740 Transfer Header.

        // Setup: Create Post Code Range and Transfer Header, open Transfer Order page.
        CreatePostCodeRange(PostCodeRange);
        TransferOrder.OpenEdit();
        TransferOrder.FILTER.SetFilter("No.", CreateTransferHeader());

        // Exercise: Set value on Transfer-to Address field of Page -  Transfer Order.
        TransferOrder."Transfer-to Address".SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Transfer-to Address, Transfer-to Post Code and Transfer-to City on page - Transfer Order.
        TransferOrder."Transfer-to Address".AssertEquals(PostCodeRange."Street Name");
        TransferOrder."Transfer-to Post Code".AssertEquals(PostCodeRange."Post Code");
        TransferOrder."Transfer-to City".AssertEquals(PostCodeRange.City);
        TransferOrder.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateSellToAddressSalesQuote()
    var
        PostCodeRange: Record "Post Code Range";
        SalesHeader: Record "Sales Header";
        SalesQuote: TestPage "Sales Quote";
    begin
        // Purpose of the test is to validate Sell-to Address - OnValidate Trigger of Table ID - 36 Sales Header.

        // Setup: Create Post Code Range and Sales Quote Header, open Sales Quote Page.
        CreatePostCodeRange(PostCodeRange);
        OpenSalesQuote(SalesQuote, CreateSalesHeader(SalesHeader."Document Type"));

        // Exercise: Set value on Sell-to Address field of Page - Sales Quote.
        SalesQuote."Sell-to Address".SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Sell-to Address, Sell-to Post Code and Sell-to City on page - Sales Quote.
        SalesQuote."Sell-to Address".AssertEquals(PostCodeRange."Street Name");
        SalesQuote."Sell-to Post Code".AssertEquals(PostCodeRange."Post Code");
        SalesQuote."Sell-to City".AssertEquals(PostCodeRange.City);
        SalesQuote.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateSellToAddressSalesOrder()
    var
        PostCodeRange: Record "Post Code Range";
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
    begin
        // Purpose of the test is to validate Sell-to Address - OnValidate Trigger of Table ID - 36 Sales Header.

        // Setup: Create Post Code Range and Sales Order Header, open Sales Order Page.
        CreatePostCodeRange(PostCodeRange);
        OpenSalesOrder(SalesOrder, CreateSalesHeader(SalesHeader."Document Type"::Order));

        // Exercise: Set value on Sell-to Address field of Page - Sales Order.
        SalesOrder."Sell-to Address".SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Sell-to Address, Sell-to Post Code and Sell-to City on page - Sales Order.
        SalesOrder."Sell-to Address".AssertEquals(PostCodeRange."Street Name");
        SalesOrder."Sell-to Post Code".AssertEquals(PostCodeRange."Post Code");
        SalesOrder."Sell-to City".AssertEquals(PostCodeRange.City);
        SalesOrder.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateSellToAddressSalesInvoice()
    var
        PostCodeRange: Record "Post Code Range";
        SalesHeader: Record "Sales Header";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // Purpose of the test is to validate Sell-to Address - OnValidate Trigger of Table ID - 36 Sales Header.

        // Setup: Create Post Code Range and Sales Invoice Header, open Sales Invoice Page.
        CreatePostCodeRange(PostCodeRange);
        OpenSalesInvoice(SalesInvoice, CreateSalesHeader(SalesHeader."Document Type"::Invoice));

        // Exercise: Set value on Sell-to Address field of Page - Sales Invoice.
        SalesInvoice."Sell-to Address".SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Sell-to Address, Sell-to Post Code and Sell-to City on page - Sales Invoice.
        SalesInvoice."Sell-to Address".AssertEquals(PostCodeRange."Street Name");
        SalesInvoice."Sell-to Post Code".AssertEquals(PostCodeRange."Post Code");
        SalesInvoice."Sell-to City".AssertEquals(PostCodeRange.City);
        SalesInvoice.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateSellToAddressSalesCreditMemo()
    var
        PostCodeRange: Record "Post Code Range";
        SalesHeader: Record "Sales Header";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // Purpose of the test is to validate Sell-to Address - OnValidate Trigger of Table ID - 36 Sales Header.

        // Setup: Create Post Code Range and Sales Credit Memo, open Sales Credit Memo Page.
        CreatePostCodeRange(PostCodeRange);
        OpenSalesCreditMemo(SalesCreditMemo, CreateSalesHeader(SalesHeader."Document Type"::"Credit Memo"));

        // Exercise: Set value on Sell-to Address field of Page - Sales Credit Memo.
        SalesCreditMemo."Sell-to Address".SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Sell-to Address, Sell-to Post Code and Sell-to City on page - Sales Credit Memo.
        SalesCreditMemo."Sell-to Address".AssertEquals(PostCodeRange."Street Name");
        SalesCreditMemo."Sell-to Post Code".AssertEquals(PostCodeRange."Post Code");
        SalesCreditMemo."Sell-to City".AssertEquals(PostCodeRange.City);
        SalesCreditMemo.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateBillToAddressSalesQuote()
    var
        PostCodeRange: Record "Post Code Range";
        SalesHeader: Record "Sales Header";
        SalesQuote: TestPage "Sales Quote";
    begin
        // Purpose of the test is to validate Bill-to Address - OnValidate Trigger of Table ID - 36 Sales Header.

        // Setup: Create Post Code Range and Sales Quote, open Sales Quote Page.
        CreatePostCodeRange(PostCodeRange);
        OpenSalesQuote(SalesQuote, CreateSalesHeader(SalesHeader."Document Type"));

        // Exercise: Set value on Bill-to Address field of Page - Sales Quote.
        SalesQuote."Bill-to Address".SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Bill-to Address, Bill-to Post Code and Bill-to City on page - Sales Quote.
        SalesQuote."Bill-to Address".AssertEquals(PostCodeRange."Street Name");
        SalesQuote."Bill-to Post Code".AssertEquals(PostCodeRange."Post Code");
        SalesQuote."Bill-to City".AssertEquals(PostCodeRange.City);
        SalesQuote.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateBillToAddressSalesOrder()
    var
        PostCodeRange: Record "Post Code Range";
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
    begin
        // Purpose of the test is to validate Bill-to Address - OnValidate Trigger of Table ID - 36 Sales Header.

        // Setup: Create Post Code Range and Sales Order, open Sales Order Page.
        CreatePostCodeRange(PostCodeRange);
        OpenSalesOrder(SalesOrder, CreateSalesHeader(SalesHeader."Document Type"::Order));

        // Exercise: Set value on Bill-to Address field of Page - Sales Order.
        SalesOrder."Bill-to Address".SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Bill-to Address, Bill-to Post Code and Bill-to City on page - Sales Order.
        SalesOrder."Bill-to Address".AssertEquals(PostCodeRange."Street Name");
        SalesOrder."Bill-to Post Code".AssertEquals(PostCodeRange."Post Code");
        SalesOrder."Bill-to City".AssertEquals(PostCodeRange.City);
        SalesOrder.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateBillToAddressSalesInvoice()
    var
        PostCodeRange: Record "Post Code Range";
        SalesHeader: Record "Sales Header";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // Purpose of the test is to validate Bill-to Address - OnValidate Trigger of Table ID - 36 Sales Header.

        // Setup: Create Post Code Range and Sales Invoice, open Sales Invoice Page.
        CreatePostCodeRange(PostCodeRange);
        OpenSalesInvoice(SalesInvoice, CreateSalesHeader(SalesHeader."Document Type"::Invoice));

        // Exercise: Set value on Bill-to Address field of Page - Sales Invoice.
        SalesInvoice."Bill-to Address".SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Bill-to Address, Bill-to Post Code and Bill-to City on page - Sales Invoice.
        SalesInvoice."Bill-to Address".AssertEquals(PostCodeRange."Street Name");
        SalesInvoice."Bill-to Post Code".AssertEquals(PostCodeRange."Post Code");
        SalesInvoice."Bill-to City".AssertEquals(PostCodeRange.City);
        SalesInvoice.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateBillToAddressSalesCreditMemo()
    var
        PostCodeRange: Record "Post Code Range";
        SalesHeader: Record "Sales Header";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // Purpose of the test is to validate Bill-to Address - OnValidate Trigger of Table ID - 36 Sales Header.

        // Setup: Create Post Code Range and Sales Credit Memo, open Sales Credit Memo Page.
        CreatePostCodeRange(PostCodeRange);
        OpenSalesCreditMemo(SalesCreditMemo, CreateSalesHeader(SalesHeader."Document Type"::"Credit Memo"));

        // Exercise: Set value on Bill-to Address field of Page - Sales Credit Memo.
        SalesCreditMemo."Bill-to Address".SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Bill-to Address, Bill-to Post Code and Bill-to City on page - Sales Credit Memo.
        SalesCreditMemo."Bill-to Address".AssertEquals(PostCodeRange."Street Name");
        SalesCreditMemo."Bill-to Post Code".AssertEquals(PostCodeRange."Post Code");
        SalesCreditMemo."Bill-to City".AssertEquals(PostCodeRange.City);
        SalesCreditMemo.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateShipToAddressSalesQuote()
    var
        PostCodeRange: Record "Post Code Range";
        SalesHeader: Record "Sales Header";
        SalesQuote: TestPage "Sales Quote";
    begin
        // Purpose of the test is to validate Ship-to Address - OnValidate Trigger of Table ID - 36 Sales Header.

        // Setup: Create Post Code Range and Sales Quote, open Sales Quote Page.
        CreatePostCodeRange(PostCodeRange);
        OpenSalesQuote(SalesQuote, CreateSalesHeader(SalesHeader."Document Type"));

        // Exercise: Set value on Ship-to Address field of Page - Sales Quote.
        SalesQuote."Ship-to Address".SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Ship-to Address, Ship-to Post Code and Ship-to City on page - Sales Quote.
        SalesQuote."Ship-to Address".AssertEquals(PostCodeRange."Street Name");
        SalesQuote."Ship-to Post Code".AssertEquals(PostCodeRange."Post Code");
        SalesQuote."Ship-to City".AssertEquals(PostCodeRange.City);
        SalesQuote.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateShipToAddressSalesOrder()
    var
        PostCodeRange: Record "Post Code Range";
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
    begin
        // Purpose of the test is to validate Ship-to Address - OnValidate Trigger of Table ID - 36 Sales Header.

        // Setup: Create Post Code Range and Sales Order, open Sales Order Page.
        CreatePostCodeRange(PostCodeRange);
        OpenSalesOrder(SalesOrder, CreateSalesHeader(SalesHeader."Document Type"::Order));

        // Exercise: Set value on Ship-to Address field of page - Sales Order.
        SalesOrder."Ship-to Address".SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Ship-to Address, Ship-to Post Code and Ship-to City on page - Sales Order.
        SalesOrder."Ship-to Address".AssertEquals(PostCodeRange."Street Name");
        SalesOrder."Ship-to Post Code".AssertEquals(PostCodeRange."Post Code");
        SalesOrder."Ship-to City".AssertEquals(PostCodeRange.City);
        SalesOrder.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateShipToAddressSalesInvoice()
    var
        PostCodeRange: Record "Post Code Range";
        SalesHeader: Record "Sales Header";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // Purpose of the test is to validate Ship-to Address - OnValidate Trigger of Table ID - 36 Sales Header.

        // Setup: Create Post Code Range and Sales Invoice, open Sales Invoice Page.
        CreatePostCodeRange(PostCodeRange);
        OpenSalesInvoice(SalesInvoice, CreateSalesHeader(SalesHeader."Document Type"::Invoice));

        // Exercise: Set value on Ship-to Address field of Page - Sales Invoice.
        SalesInvoice."Ship-to Address".SetValue(DelChr(PostCodeRange."Post Code"));  // Removing blank value from Post Code.

        // Verify: Verify Ship-to Address, Ship-to Post Code and Ship-to City on page - Sales Invoice.
        SalesInvoice."Ship-to Address".AssertEquals(PostCodeRange."Street Name");
        SalesInvoice."Ship-to Post Code".AssertEquals(PostCodeRange."Post Code");
        SalesInvoice."Ship-to City".AssertEquals(PostCodeRange.City);
        SalesInvoice.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnDeletePostCodeRange()
    var
        PostCode: Record "Post Code";
        PostCodeRange: Record "Post Code Range";
    begin
        // [SCENARIO 376685] Delete "Post Code" must not delete "Post Code" when another "Post Code Range"(s) refers to the "Post Code"

        // [GIVEN] Post Code "X"
        // [GIVEN] Post Code Range "Y1" refered to "X"
        // [GIVEN] Post Code Range "Y2" refered to "X"
        CreatePostCodeAnd2PostRanges(PostCode, PostCodeRange);

        // [WHEN] Delete "Y1"
        PostCodeRange.FindFirst();
        PostCodeRange.Delete(true);

        // [THEN] Post Code "X" exists
        Assert.RecordIsNotEmpty(PostCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnDeletePostCodeRanges()
    var
        PostCode: Record "Post Code";
        PostCodeRange: Record "Post Code Range";
    begin
        // [SCENARIO 376685] When last "Post Code Range" refered to a certain "Post Code" deleted then the "Post Code" must be deleted too

        // [GIVEN] Post Code "X"
        // [GIVEN] Post Code Range "Y1" refered to "X"
        // [GIVEN] Post Code Range "Y2" refered to "X"
        CreatePostCodeAnd2PostRanges(PostCode, PostCodeRange);

        // [GIVEN] Post Code Range "Y1" deleted
        PostCodeRange.FindFirst();
        PostCodeRange.Delete(true);

        // [WHEN] Delete "Y2"
        PostCodeRange.FindFirst();
        PostCodeRange.Delete(true);

        // [THEN] Post Code "X" deleted
        Assert.RecordIsEmpty(PostCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnDeleteAllPostCodeRanges()
    var
        PostCode: Record "Post Code";
        PostCodeRange: Record "Post Code Range";
    begin
        // [SCENARIO 376685] When call DELETEALL(TRUE) "Post Code Range"(s) refered to a certain "Post Code" then the "Post Code" must be deleted too

        // [GIVEN] Post Code "X"
        // [GIVEN] Post Code Range "Y1" refered to "X"
        // [GIVEN] Post Code Range "Y2" refered to "X"
        CreatePostCodeAnd2PostRanges(PostCode, PostCodeRange);

        // [WHEN] DELETEALL(TRUE) on "Post Code Range"
        PostCodeRange.DeleteAll(true);

        // [THEN] Post Code "X" deleted
        Assert.RecordIsEmpty(PostCode);
    end;

    local procedure CreateContactAlternativeAddress(): Code[10]
    var
        ContactAltAddress: Record "Contact Alt. Address";
    begin
        ContactAltAddress."Contact No." := CreateContact();
        ContactAltAddress.Code := LibraryUTUtility.GetNewCode10();
        ContactAltAddress.Insert();
        exit(ContactAltAddress.Code);
    end;

    local procedure CreateBankAccount(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount."No." := LibraryUTUtility.GetNewCode();
        BankAccount.Insert();
        exit(BankAccount."No.");
    end;

    local procedure CreateContact(): Code[20]
    var
        Contact: Record Contact;
    begin
        Contact."No." := LibraryUTUtility.GetNewCode();
        Contact.Insert();
        exit(Contact."No.");
    end;

    local procedure CreateLocation(): Code[10]
    var
        Location: Record Location;
    begin
        Location.Code := LibraryUTUtility.GetNewCode10();
        Location.Insert();
        exit(Location.Code);
    end;

    local procedure CreateOrderAddress(): Code[10]
    var
        OrderAddress: Record "Order Address";
    begin
        OrderAddress."Vendor No." := CreateVendor();
        OrderAddress.Code := LibraryUTUtility.GetNewCode10();
        OrderAddress.Insert();
        exit(OrderAddress.Code);
    end;

    local procedure CreatePostCode(var PostCode: Record "Post Code")
    begin
        PostCode.Code := Format(LibraryRandom.RandIntInRange(1000, 9999)) + ' ZZ';  // Code should contain 4 digit following space and two upper case alphabet.
        PostCode.City := LibraryUtility.GenerateGUID();
        PostCode.Insert(true);
    end;

    local procedure CreatePostCodeRange(var PostCodeRange: Record "Post Code Range")
    var
        PostCode: Record "Post Code";
    begin
        CreatePostCode(PostCode);
        CreatePostCodeRangeWithPostCode(PostCodeRange, PostCode, PostCodeRange.Type::" ");
    end;

    local procedure CreatePostCodeRangeWithPostCode(var PostCodeRange: Record "Post Code Range"; PostCode: Record "Post Code"; PostCodeRangeType: Option)
    begin
        PostCodeRange."Post Code" := PostCode.Code;
        PostCodeRange.City := PostCode.City;
        PostCodeRange.Type := PostCodeRangeType;
        PostCodeRange."Street Name" := LibraryUTUtility.GetNewCode();
        PostCodeRange.Insert();
    end;

    local procedure CreatePurchaseHeader(DocumentType: Enum "Purchase Document Type"): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader."No." := LibraryUTUtility.GetNewCode();
        PurchaseHeader."Document Type" := DocumentType;
        PurchaseHeader."Buy-from Vendor No." := LibraryUTUtility.GetNewCode();
        PurchaseHeader.Insert();
        exit(PurchaseHeader."No.");
    end;

    local procedure CreateResource(): Code[20]
    var
        Resource: Record Resource;
    begin
        Resource."No." := LibraryUTUtility.GetNewCode();
        Resource.Insert();
        exit(Resource."No.");
    end;

    local procedure CreateServiceHeader(DocumentType: Enum "Service Document Type"): Code[20]
    var
        ServiceHeader: Record "Service Header";
    begin
        ServiceHeader."Document Type" := DocumentType;
        ServiceHeader."No." := LibraryUTUtility.GetNewCode();
        ServiceHeader.Insert();
        exit(ServiceHeader."No.");
    end;

    local procedure CreateTransferHeader(): Code[20]
    var
        TransferHeader: Record "Transfer Header";
    begin
        TransferHeader."No." := LibraryUTUtility.GetNewCode();
        TransferHeader."Transfer-from Code" := CreateLocation();
        TransferHeader."Transfer-to Code" := CreateLocation();
        TransferHeader.Insert();
        exit(TransferHeader."No.");
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor."No." := LibraryUTUtility.GetNewCode();
        Vendor.Insert(true);
        exit(Vendor."No.");
    end;

    local procedure CreateVendorBankAccount(): Code[10]
    var
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        VendorBankAccount.Code := LibraryUTUtility.GetNewCode10();
        VendorBankAccount.Insert();
        exit(VendorBankAccount.Code);
    end;

    local procedure CreateSalesHeader(Type: Enum "Sales Document Type"): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader."Document Type" := Type;
        SalesHeader."No." := LibraryUTUtility.GetNewCode();
        SalesHeader.Insert();
        exit(SalesHeader."No.");
    end;

    local procedure CreatePostCodeAnd2PostRanges(var PostCode: Record "Post Code"; var PostCodeRange: Record "Post Code Range")
    begin
        CreatePostCode(PostCode);
        CreatePostCodeRangeWithPostCode(PostCodeRange, PostCode, PostCodeRange.Type::" ");
        CreatePostCodeRangeWithPostCode(PostCodeRange, PostCode, PostCodeRange.Type::Odd);

        PostCodeRange.SetRange("Post Code", PostCode.Code);
        PostCodeRange.SetRange(City, PostCode.City);
        PostCode.SetRange(Code, PostCode.Code);
        PostCode.SetRange(City, PostCode.City);
        PostCode.FindFirst();
    end;

    local procedure OpenBankAccountCard(var BankAccountCard: TestPage "Bank Account Card"; No: Code[20])
    begin
        BankAccountCard.OpenEdit();
        BankAccountCard.FILTER.SetFilter("No.", No);
    end;

    local procedure OpenBlanketPurchaseOrder(var BlanketPurchaseOrder: TestPage "Blanket Purchase Order"; No: Code[20])
    begin
        BlanketPurchaseOrder.OpenEdit();
        BlanketPurchaseOrder.FILTER.SetFilter("No.", No);
    end;

    local procedure OpenPurchaseQuote(var PurchaseQuote: TestPage "Purchase Quote"; No: Code[20])
    begin
        PurchaseQuote.OpenEdit();
        PurchaseQuote.FILTER.SetFilter("No.", No);
    end;

    local procedure OpenPurchaseOrder(var PurchaseOrder: TestPage "Purchase Order"; No: Code[20])
    begin
        PurchaseOrder.OpenEdit();
        PurchaseOrder.FILTER.SetFilter("No.", No);
    end;

    local procedure OpenPurchaseInvoice(var PurchaseInvoice: TestPage "Purchase Invoice"; No: Code[20])
    begin
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.FILTER.SetFilter("No.", No);
    end;

    local procedure OpenPurchaseCreditMemo(var PurchaseCreditMemo: TestPage "Purchase Credit Memo"; No: Code[20])
    begin
        PurchaseCreditMemo.OpenEdit();
        PurchaseCreditMemo.FILTER.SetFilter("No.", No);
    end;

    local procedure OpenPurchaseReturnOrder(var PurchaseReturnOrder: TestPage "Purchase Return Order"; No: Code[20])
    begin
        PurchaseReturnOrder.OpenEdit();
        PurchaseReturnOrder.FILTER.SetFilter("No.", No);
    end;

    local procedure OpenSalesQuote(var SalesQuote: TestPage "Sales Quote"; No: Code[20])
    begin
        SalesQuote.OpenEdit();
        SalesQuote.FILTER.SetFilter("No.", No);
    end;

    local procedure OpenSalesOrder(var SalesOrder: TestPage "Sales Order"; No: Code[20])
    begin
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", No);
    end;

    local procedure OpenSalesInvoice(var SalesInvoice: TestPage "Sales Invoice"; No: Code[20])
    begin
        SalesInvoice.OpenEdit();
        SalesInvoice.FILTER.SetFilter("No.", No);
    end;

    local procedure OpenSalesCreditMemo(var SalesCreditMemo: TestPage "Sales Credit Memo"; No: Code[20])
    begin
        SalesCreditMemo.OpenEdit();
        SalesCreditMemo.FILTER.SetFilter("No.", No);
    end;

    local procedure OpenServiceQuote(var ServiceQuote: TestPage "Service Quote"; No: Code[20])
    begin
        ServiceQuote.OpenEdit();
        ServiceQuote.FILTER.SetFilter("No.", No);
    end;

    local procedure OpenServiceOrder(var ServiceOrder: TestPage "Service Order"; No: Code[20])
    begin
        ServiceOrder.OpenEdit();
        ServiceOrder.FILTER.SetFilter("No.", No);
    end;

    local procedure OpenServiceInvoice(var ServiceInvoice: TestPage "Service Invoice"; No: Code[20])
    begin
        ServiceInvoice.OpenEdit();
        ServiceInvoice.FILTER.SetFilter("No.", No);
    end;

    local procedure OpenServiceCreditMemo(var ServiceCreditMemo: TestPage "Service Credit Memo"; No: Code[20])
    begin
        ServiceCreditMemo.OpenEdit();
        ServiceCreditMemo.FILTER.SetFilter("No.", No);
    end;

    local procedure OpenVendorBankAccountCard(var VendorBankAccountCard: TestPage "Vendor Bank Account Card")
    begin
        VendorBankAccountCard.OpenEdit();
        VendorBankAccountCard.FILTER.SetFilter(Code, CreateVendorBankAccount());
    end;
}

