codeunit 143304 "Library - 347 Declaration"
{

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        FileManagement: Codeunit "File Management";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryTextFileValidation: Codeunit "Library - Text File Validation";
        LibraryRandom: Codeunit "Library - Random";
        ContactNameTxt: Label 'Contact Name';
        DeclarationNumberTxt: Label '1234';
        CountyRegionCodeESTxt: Label 'ES';
        CountyRegionCodePTTxt: Label 'PT';
        TelephoneNumberTxt: Label '123456789';

    [Scope('OnPrem')]
    procedure CreateAndPostCashReceiptJournal(var GenJournalLine: Record "Gen. Journal Line"; GLAccount: Record "G/L Account"; CustNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        // Creates a cash receipt journal and posts it. Doesn't apply the payment to an invoice.

        // Find a Cash Receipts journal template
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::"Cash Receipts");
        GenJournalTemplate.SetRange(Recurring, false);
        GenJournalTemplate.FindFirst();

        // Create new journal batch
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"G/L Account");
        GenJournalBatch.Validate("Bal. Account No.", GLAccount."No.");
        GenJournalBatch.Modify(true);

        // Create journal line for the customer and with the right amount
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name",
          GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, CustNo, 0);
        GenJournalLine.Validate("Credit Amount", Amount);
        GenJournalLine.Modify(true);
        Commit();

        // Post the journal line
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    [Scope('OnPrem')]
    procedure CreateAndPostGeneralJournalLine(DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; DebitAmount: Decimal; CreditAmount: Decimal)
    var
        GLAccount: Record "G/L Account";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Create G/L Account
        LibraryERM.CreateGLAccount(GLAccount);

        // Setup: Find a Cash Receipts journal template
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::"Cash Receipts");
        GenJournalTemplate.SetRange(Recurring, false);
        GenJournalTemplate.FindFirst();

        // Setup: Create new journal batch
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"G/L Account");
        GenJournalBatch.Validate("Bal. Account No.", GLAccount."No.");
        GenJournalBatch.Modify(true);

        // Setup: Create Invoice journal line for the customer and with the right Debit amount
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          DocumentType, AccountType, AccountNo, 0);
        if DebitAmount > 0 then
            GenJournalLine.Validate("Debit Amount", DebitAmount)
        else
            GenJournalLine.Validate("Credit Amount", CreditAmount);
        GenJournalLine.Modify(true);
        Commit();

        // Setup: Post the journal line
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    [Scope('OnPrem')]
    procedure CreateAndPostPurchaseOrderForGLAccount(VendorNo: Code[20]; GLAccount: Code[20]; Amount: Decimal): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Post a Sales Invoice with the exact amount
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccount, 1);
        PurchaseLine.Validate("Direct Unit Cost", Amount);
        PurchaseLine.Modify(true);

        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    [Scope('OnPrem')]
    procedure CreateAndPostSalesInvoiceWithoutVAT(CustNo: Code[20]; Amount: Decimal): Code[20]
    var
        Item: Record Item;
    begin
        CreateItemWithZeroVAT(Item, CustNo);
        exit(CreateAndPostSalesInvoiceForItem(CustNo, Item, Amount, WorkDate()));
    end;

    [Scope('OnPrem')]
    procedure CreateAndPostSalesInvoiceWithNoTaxableVAT(CustNo: Code[20]; Amount: Decimal): Code[20]
    var
        Item: Record Item;
    begin
        // Create an Item with No Taxable VAT (which is different from 0 VAT in that no VAT entries will be created)
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", FindVATPostingSetupNoTaxableVAT());
        Item.Modify(true);

        exit(CreateAndPostSalesInvoiceForItem(CustNo, Item, Amount, WorkDate()));
    end;

    [Scope('OnPrem')]
    procedure CreateAndPostSalesInvoice(CustomerNo: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        exit(CreateAndPostSalesInvoiceForItem(CustomerNo, Item, 5000, WorkDate()));
    end;

    [Scope('OnPrem')]
    procedure CreateAndPostSalesInvoiceForItem(CustNo: Code[20]; Item: Record Item; Amount: Decimal; Date: Date): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustNo);
        SalesHeader.Validate("Posting Date", Date);
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        SalesLine.Validate("Unit Price", Amount);
        SalesLine.Modify(true);

        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    [Scope('OnPrem')]
    procedure CreateAndPostSalesInvoiceWithShipToAddress(CustNo: Code[20]; Amount: Decimal; ShipToAddressCode: Code[10]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        CreateItemWithZeroVAT(Item, CustNo);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustNo);
        SalesHeader.Validate("Posting Date", WorkDate());
        SalesHeader.Validate("Ship-to Code", ShipToAddressCode);
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        SalesLine.Validate("Unit Price", Amount);
        SalesLine.Modify(true);

        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    [Scope('OnPrem')]
    procedure CreateAndPostPurchaseOrderWithNoVAT(VendorNo: Code[20]; Amount: Decimal)
    var
        Item: Record Item;
    begin
        CreateItemWithZeroVAT(Item, VendorNo);
        CreateAndPostPurchaseOrderForItem(VendorNo, Item, Amount, WorkDate());
    end;

    [Scope('OnPrem')]
    procedure CreateAndPostPurchaseOrderWithNoTaxableVAT(VendorNo: Code[20]; Amount: Decimal)
    var
        Item: Record Item;
    begin
        // Create an Item with No Taxable VAT (which is different from 0 VAT in that no VAT entries will be created)
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", FindVATPostingSetupNoTaxableVAT());
        Item.Modify(true);

        CreateAndPostPurchaseOrderForItem(VendorNo, Item, Amount, WorkDate());
    end;

    [Scope('OnPrem')]
    procedure CreateAndPostPurchaseOrderForItem(VendNo: Code[20]; Item: Record Item; Amount: Decimal; Date: Date): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendNo);
        PurchaseHeader.Validate("Posting Date", Date);
        PurchaseHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);
        PurchaseLine.Validate("Direct Unit Cost", Amount);
        PurchaseLine.Modify(true);

        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    [Scope('OnPrem')]
    procedure CreateAndPostPurchaseInvoiceWithOrderAddress(VendNo: Code[20]; Amount: Decimal; OrderAddressCode: Code[10]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
    begin
        CreateItemWithZeroVAT(Item, VendNo);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendNo);
        PurchaseHeader.Validate("Posting Date", WorkDate());
        PurchaseHeader.Validate("Order Address Code", OrderAddressCode);
        PurchaseHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);
        PurchaseLine.Validate("Direct Unit Cost", Amount);
        PurchaseLine.Modify(true);

        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    [Scope('OnPrem')]
    procedure CreateAndPostSalesInvoiceForGLAccount(CustNo: Code[20]; GLAccount: Code[20]; Amount: Decimal): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Post a Sales Invoice with the exact amount
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccount, 1);
        SalesLine.Validate("Unit Price", Amount);
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    [Scope('OnPrem')]
    procedure CreateAndPostSalesInvoiceToEnsureAReportGetsGenerated()
    var
        CustNo: Code[20];
    begin
        // Creates and posts a sales invoice with a big amount, which will ensure that if we generate
        // a report, then we WILL get a report generated as opposed to getting the error "no records found...".
        // This simplifies some of the negative tests, i.e., they don't have to test for EITHER no new records generated
        // OR no report generated at all.
        CustNo := CreateCustomerWithPostCode(GetUniqueVATRegNo(CountyRegionCodeESTxt));
        CreateAndPostSalesInvoiceWithoutVAT(CustNo, 1000000);
    end;

    [Scope('OnPrem')]
    procedure CreateCustomerWithPostCode(VATRegistrationNo: Text[20]): Code[20]
    var
        Customer: Record Customer;
        CustNo: Code[20];
    begin
        CustNo := CreateCustomer(VATRegistrationNo);

        Customer.Get(CustNo);
        Customer.Validate("Post Code", '11011');
        Customer.Modify(true);

        exit(CustNo);
    end;

    [Scope('OnPrem')]
    procedure CreateCustomerInPortugalWithPostCode(VATRegistrationNo: Text[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Country/Region Code", CountyRegionCodePTTxt);
        Customer.Validate("Post Code", 'PT 4000-322');
        Customer.Validate("VAT Registration No.", VATRegistrationNo);
        Customer.Modify(true);
        AssignPaymentTermsToCustomer(Customer."No.");
        exit(Customer."No.");
    end;

    [Scope('OnPrem')]
    procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryERM.FindGenProductPostingGroup(GenProductPostingGroup);
        GLAccount.Validate("Gen. Prod. Posting Group", GenProductPostingGroup.Code);
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    [Scope('OnPrem')]
    procedure CreateItemWithZeroVAT(var Item: Record Item; CustOrVendNo: Code[20])
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        VATProdPostingGroupCode: Code[20];
        VATBusPostingGroupCode: Code[20];
    begin
        // Creates an Item, which when used with the given customer/vendor, will lead to 0% VAT. This
        // allows us to easily control the exact amount that gets posted.

        // The VAT Posting Setup will be found during posting based on two things: 1) the customer/vendor's
        // VAT Bus. Posting Group and 2) the item's VAT Prod. Posting Group. We know the customer/vendor, and
        // so we only need to find the VAT Prod. Posting Group to assign to the new item in order to
        // identify a good VAT Posting Setup with 0% VAT.

        // Get the VAT Bus. Posting Group
        if Customer.Get(CustOrVendNo) then
            VATBusPostingGroupCode := Customer."VAT Bus. Posting Group"
        else begin
            Vendor.Get(CustOrVendNo);
            VATBusPostingGroupCode := Vendor."VAT Bus. Posting Group";
        end;

        // Find a good VAT Prod. Posting Group
        VATProdPostingGroupCode := FindZeroVATPostingGroup(VATBusPostingGroupCode);

        // Create the item
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroupCode);
        Item.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateOrderAddress(VendorNo: Code[20]; CountryCode: Code[10]): Code[10]
    var
        OrderAddress: Record "Order Address";
    begin
        LibraryPurchase.CreateOrderAddress(OrderAddress, VendorNo);
        OrderAddress.Validate("Country/Region Code", CountryCode);
        OrderAddress.Modify(true);
        exit(OrderAddress.Code);
    end;

    [Scope('OnPrem')]
    procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; CountryCode: Text[2]): Code[20]
    var
        PurchaseLine: Record "Purchase Line";
        VATRegistrationNo: Text[20];
    begin
        VATRegistrationNo := GetUniqueVATRegNo(CountryCode);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, CreateVendor(VATRegistrationNo, CountyRegionCodeESTxt));
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", CreateGLAccount(), LibraryRandom.RandDec(100, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(1000, 2));
        PurchaseLine.Modify(true);
        exit(PurchaseLine."No.");
    end;

    [Scope('OnPrem')]
    procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; CountryCode: Text[2])
    var
        SalesLine: Record "Sales Line";
        VATRegistrationNo: Text[20];
    begin
        VATRegistrationNo := GetUniqueVATRegNo(CountryCode);
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CreateCustomer(VATRegistrationNo));
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", CreateGLAccount(), LibraryRandom.RandInt(10));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(1000, 2));
        SalesLine.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateServiceDocument(var ServiceHeader: Record "Service Header"; DocumentType: Enum "Service Document Type"; CountryCode: Text[2])
    var
        ServiceLine: Record "Service Line";
        VATRegistrationNo: Text[20];
    begin
        VATRegistrationNo := GetUniqueVATRegNo(CountryCode);
        LibraryService.CreateServiceHeader(ServiceHeader, DocumentType, CreateCustomer(VATRegistrationNo));
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::"G/L Account", CreateGLAccount());
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(1000, 2));
        ServiceLine.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateShipToAddress(CustomerNo: Code[20]; CountryCode: Code[10]): Code[10]
    var
        ShipToAddress: Record "Ship-to Address";
    begin
        LibrarySales.CreateShipToAddress(ShipToAddress, CustomerNo);
        ShipToAddress.Validate("Country/Region Code", CountryCode);
        ShipToAddress.Modify(true);
        exit(ShipToAddress.Code);
    end;

    [Scope('OnPrem')]
    procedure CreateShortVATRegNo(CountryRegionCode: Code[10]): Text[20]
    var
        TempVATEntry: Record "VAT Entry" temporary;
        VATRegistrationNoFormat: Record "VAT Registration No. Format";
        VATRegistrationNo: Text[20];
    begin
        LibraryERM.CreateVATRegistrationNoFormat(VATRegistrationNoFormat, CountryRegionCode);
        VATRegistrationNoFormat.Validate(Format, '#####T');
        VATRegistrationNoFormat.Modify(true);

        FillVATRegistrationNoBuffer(TempVATEntry);
        repeat
            VATRegistrationNo :=
              LibraryERM.GenerateVATRegistrationForFormat(CountryRegionCode, VATRegistrationNoFormat."Line No.");
            TempVATEntry.SetRange("VAT Registration No.", VATRegistrationNo);
        until TempVATEntry.IsEmpty();
        exit(VATRegistrationNo);
    end;

    [Scope('OnPrem')]
    procedure CreateVendorWithPostCode(VATRegistrationNo: Text[20]): Code[20]
    var
        Vendor: Record Vendor;
        VendNo: Code[20];
    begin
        VendNo := CreateVendor(VATRegistrationNo, CountyRegionCodeESTxt);

        Vendor.Get(VendNo);
        Vendor.Validate("Post Code", '11011');
        Vendor.Modify(true);

        exit(Vendor."No.");
    end;

    [Scope('OnPrem')]
    procedure CreateVendorWithCountryCode(CountryCode: Code[10]): Code[20]
    var
        Vendor: Record Vendor;
        PostCode: Record "Post Code";
        VendNo: Code[20];
    begin
        VendNo := CreateVendor(GetUniqueVATRegNo(CountryCode), CountryCode);
        LibraryERM.CreatePostCode(PostCode);
        PostCode.Validate("Country/Region Code", CountryCode);
        PostCode.Modify(true);

        Vendor.Get(VendNo);
        Vendor.Validate("Post Code", PostCode.Code);
        Vendor.Modify(true);

        exit(Vendor."No.");
    end;

    [Scope('OnPrem')]
    procedure CreateVendorInPortugalWithPostCode(VATRegistrationNo: Text[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Country/Region Code", CountyRegionCodePTTxt);
        Vendor.Validate("Post Code", 'PT 4000-322');
        Vendor.Validate("VAT Registration No.", VATRegistrationNo);
        Vendor.Modify(true);
        AssignPaymentTermsToVendor(Vendor."No.");
        exit(Vendor."No.");
    end;

    [Scope('OnPrem')]
    procedure FormatVATRegNo(VatRegNo: Text[20]): Text[20]
    begin
        VatRegNo := CopyStr(DelChr(VatRegNo, '=', '.-/'), 1, 9);
        while StrLen(VatRegNo) < 9 do
            VatRegNo := '0' + VatRegNo;
        exit(VatRegNo);
    end;

    [Scope('OnPrem')]
    procedure GetNewWorkDate(): Date
    var
        GLRegister: Record "G/L Register";
    begin
        GLRegister.SetCurrentKey("Posting Date");
        GLRegister.FindLast();
        exit(CalcDate('<1Y>', GLRegister."Posting Date"));
    end;

    [Scope('OnPrem')]
    procedure GetUniqueVATRegNo(CountryCode: Code[10]): Text[20]
    var
        TempVATEntry: Record "VAT Entry" temporary;
        VATRegistrationNo: Text[20];
    begin
        FillVATRegistrationNoBuffer(TempVATEntry);
        repeat
            VATRegistrationNo := LibraryERM.GenerateVATRegistrationNo(CountryCode);
            TempVATEntry.SetRange("VAT Registration No.", VATRegistrationNo);
        until TempVATEntry.IsEmpty();
        exit(VATRegistrationNo);
    end;

    local procedure FillVATRegistrationNoBuffer(var TempVATEntry: Record "VAT Entry" temporary)
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
    begin
        Customer.SetFilter("VAT Registration No.", '<>%1', '');
        if Customer.FindSet() then
            repeat
                TempVATEntry."Entry No." += 1;
                TempVATEntry."VAT Registration No." := Customer."VAT Registration No.";
                TempVATEntry.Insert();
            until Customer.Next() = 0;

        Vendor.SetFilter("VAT Registration No.", '<>%1', '');
        if Vendor.FindSet() then
            repeat
                TempVATEntry."Entry No." += 1;
                TempVATEntry."VAT Registration No." := Vendor."VAT Registration No.";
                TempVATEntry.Insert();
            until Vendor.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure Init347DeclarationParameters(var Test347DeclarationParameter: Record "Test 347 Declaration Parameter")
    begin
        Test347DeclarationParameter.Reset();
        Test347DeclarationParameter.Init();
        Test347DeclarationParameter.ContactName := ContactNameTxt;
        Test347DeclarationParameter.TelephoneNumber := TelephoneNumberTxt;
        Test347DeclarationParameter.DeclarationNumber := DeclarationNumberTxt;
        Test347DeclarationParameter.MinAmount := 1;
        Test347DeclarationParameter.MinAmountCash := 1;
        Test347DeclarationParameter.PostingDate := WorkDate();
    end;

    [Scope('OnPrem')]
    procedure ReadLineWithCustomerOrVendor(FileName: Text[1024]; CustOrVendNo: Code[20]): Text[500]
    var
        LineNo: Integer;
        TruncatedVATRegistrationNo: Code[20];
    begin
        // Search in the file for a line with the given VAT Registration No. The VAT Registration No starts in column 18 and forward.
        TruncatedVATRegistrationNo := FindVATRegistrationNo(CustOrVendNo, true); // this is to match the truncation that the report itself does

        LineNo := LibraryTextFileValidation.FindLineNoWithValue(FileName, 18, 9, TruncatedVATRegistrationNo, 1);
        if LineNo = 0 then
            exit('');

        exit(LibraryTextFileValidation.ReadLine(FileName, LineNo));
    end;

    [Scope('OnPrem')]
    procedure ReadLineWithCustomerOrVendorOutsideES(FileName: Text[1024]; CustOrVendNo: Code[20]): Text[500]
    var
        LineNo: Integer;
        AmountTxt: Text[16];
        Amount: Decimal;
    begin
        Amount := FindVATEntryAmount(CustOrVendNo);
        AmountTxt := FormatAmount(Amount);
        LineNo := LibraryTextFileValidation.FindLineNoWithValue(FileName, 83, 16, AmountTxt, 1);
        if LineNo = 0 then
            exit('');

        exit(LibraryTextFileValidation.ReadLine(FileName, LineNo));
    end;

    [Scope('OnPrem')]
    procedure ReadSecondLineForVendor(FileName: Text[1024]; CustOrVendNo: Code[20]): Text[500]
    var
        LineNo: Integer;
        TruncatedVATRegistrationNo: Code[20];
    begin
        // Search in the file for a line with the given VAT Registration No. The VAT Registration No starts in column 18 and forward.
        TruncatedVATRegistrationNo := FindVATRegistrationNo(CustOrVendNo, true); // this is to match the truncation that the report itself does

        if LibraryTextFileValidation.CountNoOfLinesWithValue(FileName, TruncatedVATRegistrationNo, 18, 9) < 2 then
            exit('');

        LineNo := LibraryTextFileValidation.FindLineNoWithValue(FileName, 18, 9, TruncatedVATRegistrationNo, 1);
        exit(LibraryTextFileValidation.ReadLine(FileName, LineNo + 1));
    end;

    [Scope('OnPrem')]
    procedure ReadLineWithYear(FileName: Text[1024]; Year: Code[4]): Text[500]
    var
        LineNo: Integer;
    begin
        // Search in the file for a line with the given VAT Registration No. The VAT Registration No starts in column 18 and forward.

        // Search in the file
        LineNo := LibraryTextFileValidation.FindLineNoWithValue(FileName, 18, 9, Year, 1);
        if LineNo = 0 then
            exit('');

        exit(LibraryTextFileValidation.ReadLine(FileName, LineNo));
    end;

    [Scope('OnPrem')]
    procedure RemoveVATRegistrationNumberFromCustomer(CustomerNo: Code[20])
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        Customer.Validate("VAT Registration No.", '');
        Customer.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure RemoveVATRegistrationNumberFromVendor(VendorNo: Code[20])
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendorNo);
        Vendor.Validate("VAT Registration No.", '');
        Vendor.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure RunMake347DeclarationReport(Test347DeclarationParameter: Record "Test 347 Declaration Parameter"; var LibraryVariableStorage: Codeunit "Library - Variable Storage"): Text[1024]
    var
        Make347Declaration: Report "Make 347 Declaration";
        FileName: Text[1024];
    begin
        FileName := CopyStr(FileManagement.ServerTempFileName('txt'), 1, 1024);

        LibraryVariableStorage.Enqueue(Date2DMY(Test347DeclarationParameter.PostingDate, 3));
        LibraryVariableStorage.Enqueue(Test347DeclarationParameter.MinAmount);
        LibraryVariableStorage.Enqueue(Test347DeclarationParameter.MinAmountCash);
        LibraryVariableStorage.Enqueue(Test347DeclarationParameter.GLAccForPaymentsInCash);
        LibraryVariableStorage.Enqueue(Test347DeclarationParameter.ContactName);
        LibraryVariableStorage.Enqueue(Test347DeclarationParameter.TelephoneNumber);
        LibraryVariableStorage.Enqueue(Test347DeclarationParameter.DeclarationNumber);
        Make347Declaration.SetSilentMode(FileName);
        Make347Declaration.RunModal();

        exit(FileName);
    end;

    [Scope('OnPrem')]
    procedure ValidateFileHasLineForCustomer(FileName: Text[1024]; CustOrVendNo: Code[20])
    var
        Line: Text[500];
    begin
        Line := ReadLineWithCustomerOrVendor(FileName, CustOrVendNo);
        if Line = '' then
            Assert.Fail('Should have found VAT no for customer/vendor ' + CustOrVendNo + ' in generated file');
    end;

    [Scope('OnPrem')]
    procedure ValidateFileHasNoLineForCustomer(FileName: Text[1024]; CustOrVendNo: Code[20])
    var
        Line: Text[500];
    begin
        Line := ReadLineWithCustomerOrVendor(FileName, CustOrVendNo);
        if Line <> '' then
            Assert.Fail('Should not have found VAT no for customer/vendor ' + CustOrVendNo + ' in generated file')
    end;

    [Scope('OnPrem')]
    procedure ValidateFileHasNoLineForCustomerOutsideES(FileName: Text[1024]; CustOrVendNo: Code[20])
    var
        Line: Text[500];
    begin
        Line := ReadLineWithCustomerOrVendorOutsideES(FileName, CustOrVendNo);
        if Line <> '' then
            Assert.Fail('Should not have found Amount for customer/vendor ' + CustOrVendNo + ' in generated file');
    end;

    local procedure AssignPaymentTermsToCustomer(CustNo: Code[20])
    var
        Customer: Record Customer;
        PaymentMethod: Record "Payment Method";
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        LibraryERM.CreatePaymentMethod(PaymentMethod);

        Customer.Get(CustNo);
        Customer.Validate("Payment Terms Code", PaymentTerms.Code);
        Customer.Validate("Payment Method Code", PaymentMethod.Code);
        Customer.Modify(true);
    end;

    local procedure AssignPaymentTermsToVendor(VendNo: Code[20])
    var
        Vendor: Record Vendor;
        PaymentMethod: Record "Payment Method";
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        LibraryERM.CreatePaymentMethod(PaymentMethod);

        Vendor.Get(VendNo);
        Vendor.Validate("Payment Terms Code", PaymentTerms.Code);
        Vendor.Validate("Payment Method Code", PaymentMethod.Code);
        Vendor.Modify(true);
    end;

    local procedure CreateCustomer(VATRegistrationNo: Text[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Country/Region Code", CountyRegionCodeESTxt);
        Customer.Validate("VAT Registration No.", VATRegistrationNo);
        Customer.Modify(true);
        AssignPaymentTermsToCustomer(Customer."No.");
        exit(Customer."No.");
    end;

    local procedure CreateVendor(VATRegistrationNo: Text[20]; CountryRegionCode: Code[10]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Country/Region Code", CountryRegionCode);
        Vendor.Validate("VAT Registration No.", VATRegistrationNo);
        Vendor.Modify(true);
        AssignPaymentTermsToVendor(Vendor."No.");
        exit(Vendor."No.");
    end;

    local procedure FindVATEntryAmount(CustOrVendNo: Code[20]) Amount: Decimal
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("VAT Registration No.", FindVATRegistrationNo(CustOrVendNo, false));
        VATEntry.FindSet();
        repeat
            Amount += VATEntry.Base + VATEntry.Amount;
        until VATEntry.Next() = 0;
    end;

    local procedure FindVATRegistrationNo(CustOrVendNo: Code[20]; TruncateVATRegNoVATRegistrationNo: Boolean): Code[20]
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        VATRegistrationNo: Code[20];
    begin
        // Find customer/vendor and get its VAT Registration No
        if Customer.Get(CustOrVendNo) then
            VATRegistrationNo := Customer."VAT Registration No."
        else
            if Vendor.Get(CustOrVendNo) then
                VATRegistrationNo := Vendor."VAT Registration No."
            else
                exit('');

        // Search in the file
        if TruncateVATRegNoVATRegistrationNo then
            exit(FormatVATRegNo(VATRegistrationNo)); // this is to match the truncation that the report itself does
        exit(VATRegistrationNo);
    end;

    local procedure FindVATPostingSetupNoTaxableVAT(): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.SetFilter("VAT Bus. Posting Group", '<>''''');
        VATPostingSetup.SetFilter("VAT Prod. Posting Group", '<>''''');
        VATPostingSetup.SetRange("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"No Taxable VAT");
        VATPostingSetup.FindFirst();
        exit(VATPostingSetup."VAT Prod. Posting Group");
    end;

    local procedure FindZeroVATPostingGroup(VATBusPostingGroupCode: Code[20]): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.SetRange("VAT Bus. Posting Group", VATBusPostingGroupCode);
        VATPostingSetup.SetFilter("VAT Prod. Posting Group", '<>''''');
        VATPostingSetup.SetRange("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.SetRange("VAT %", 0);
        VATPostingSetup.FindFirst();
        exit(VATPostingSetup."VAT Prod. Posting Group");
    end;

    local procedure FormatAmount(Amount: Decimal): Text[16]
    begin
        if Amount < 0 then
            exit('N' + FormatAmountEuro(-Amount));

        exit(' ' + FormatAmountEuro(Amount));
    end;

    local procedure FormatAmountEuro(Amount: Decimal): Text[15]
    var
        AmtText: Text[15];
    begin
        Amount := Amount * 100;
        AmtText := ConvertStr(Format(Amount), ' ', '0');
        AmtText := DelChr(AmtText, '=', '.,');

        while StrLen(AmtText) < 15 do
            AmtText := '0' + AmtText;
        exit(AmtText);
    end;
}

