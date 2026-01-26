codeunit 144070 "UT TAB VAT Exemption"
{
    // // [FEATURE] [VAT Exemption] [UT]
    // 
    // Test for feature VATEXEMP - VAT Exemption.

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryUTUtility: Codeunit "Library UT Utility";
        ValueMustEqualMsg: Label 'Value must equal.';
        CustomerVATExemptionTxt: Label 'The customer has an active VAT exemption and VAT Bus. Posting Group hasn''t "Check VAT Exemption". Do you want to continue?';
        DialogErr: Label 'Dialog';
        LibraryRandom: Codeunit "Library - Random";
        VATExemptNumeringErr: Label 'The VAT Exemption Intl. Register No. must be different';
        VATExemptNumeringNoSeriesErr: Label 'The VAT Exemption Intl. Register No. must be set from No. Series Lines setup';
        LibraryERM: Codeunit "Library - ERM";
        TestFieldErr: Label 'TestField';
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('CheckVATExemptionConfirmHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateBillToCustomerNoOrderServiceHeader()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Purpose of the test is to validate Bill-to Customer No. - OnValidate Trigger of Table ID - 5900 Service Header.
        OnValidateBillToCustomerNoDocumentTypeServiceHeader(ServiceHeader."Document Type"::Order);
    end;

    [Test]
    [HandlerFunctions('CheckVATExemptionConfirmHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateBillToCustomerNoInvoiceServiceHeader()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Purpose of the test is to validate Bill-to Customer No. - OnValidate Trigger of Table ID - 5900 Service Header.
        OnValidateBillToCustomerNoDocumentTypeServiceHeader(ServiceHeader."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('CheckVATExemptionConfirmHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateBillToCustomerNoCreditMemoServiceHeader()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Purpose of the test is to validate Bill-to Customer No. - OnValidate Trigger of Table ID - 5900 Service Header.
        OnValidateBillToCustomerNoDocumentTypeServiceHeader(ServiceHeader."Document Type"::"Credit Memo");
    end;

    local procedure OnValidateBillToCustomerNoDocumentTypeServiceHeader(DocumentType: Enum "Service Document Type")
    var
        ServiceHeader: Record "Service Header";
        VATExemption: Record "VAT Exemption";
    begin
        // Setup.
        CreateServiceHeader(ServiceHeader, DocumentType);
        CreateVATExemption(VATExemption);

        // Exercise & Verify: Verify confirmation message - The customer has an active VAT exemption and VAT Business Posting Group hasn't "Check VAT Exemption". Do you want to continue? in CheckVATExemptionConfirmHandler.
        ServiceHeader.Validate("Bill-to Customer No.", VATExemption."No.");
    end;

    [Test]
    [HandlerFunctions('CheckVATExemptionConfirmHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateBillToCustomerNoOrderSalesHeader()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Purpose of the test is to validate Bill-to Customer No. - OnValidate Trigger of Table ID - 36 Sales Header.
        OnValidateBillToCustomerNoDocumentTypeSalesHeader(SalesHeader."Document Type"::Order);
    end;

    [Test]
    [HandlerFunctions('CheckVATExemptionConfirmHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateBillToCustomerNoInvoiceSalesHeader()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Purpose of the test is to validate Bill-to Customer No. - OnValidate Trigger of Table ID - 36 Sales Header.
        OnValidateBillToCustomerNoDocumentTypeSalesHeader(SalesHeader."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('CheckVATExemptionConfirmHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateBillToCustomerNoReturnOrderSalesHeader()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Purpose of the test is to validate Bill-to Customer No. - OnValidate Trigger of Table ID - 36 Sales Header.
        OnValidateBillToCustomerNoDocumentTypeSalesHeader(SalesHeader."Document Type"::"Return Order");
    end;

    [Test]
    [HandlerFunctions('CheckVATExemptionConfirmHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateBillToCustomerNoCreditMemoSalesHeader()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Purpose of the test is to validate Bill-to Customer No. - OnValidate Trigger of Table ID - 36 Sales Header.
        OnValidateBillToCustomerNoDocumentTypeSalesHeader(SalesHeader."Document Type"::"Credit Memo");
    end;

    local procedure OnValidateBillToCustomerNoDocumentTypeSalesHeader(DocumentType: Enum "Sales Document Type")
    var
        SalesHeader: Record "Sales Header";
        VATExemption: Record "VAT Exemption";
    begin
        // Setup.
        CreateSalesHeader(SalesHeader, DocumentType);
        CreateVATExemption(VATExemption);

        // Exercise & Verify: Verify confirmation message - The customer has an active VAT exemption and VAT Business Posting Group hasn't "Check VAT Exemption". Do you want to continue? in CheckVATExemptionConfirmHandler.
        SalesHeader.Validate("Bill-to Customer No.", VATExemption."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnValidateCustomerNoOrderServiceHeaderError()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Purpose of the test is to validate Customer No. - OnValidate Trigger of Table ID - 5900 Service Header.
        OnValidateCustomerNoDocumentTypeServiceHeader(ServiceHeader."Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnValidateCustomerNoInvoiceServiceHeaderError()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Purpose of the test is to validate Customer No. - OnValidate Trigger of Table ID - 5900 Service Header.
        OnValidateCustomerNoDocumentTypeServiceHeader(ServiceHeader."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnValidateCustomerNoCreditMemoServiceHeaderError()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Purpose of the test is to validate Customer No. - OnValidate Trigger of Table ID - 5900 Service Header.
        OnValidateCustomerNoDocumentTypeServiceHeader(ServiceHeader."Document Type"::"Credit Memo");
    end;

    local procedure OnValidateCustomerNoDocumentTypeServiceHeader(DocumentType: Enum "Service Document Type")
    var
        ServiceHeader: Record "Service Header";
    begin
        // Setup: Transaction Model Type Auto Commit is required as Commit is explicitly using on OnValidate - Customer No. Trigger of Table ID - 5900 Service Header.
        CreateServiceHeader(ServiceHeader, DocumentType);

        // Exercise.
        asserterror ServiceHeader.Validate("Customer No.", CreateCustomer(true));  // Check VAT Exemption as True.

        // Verify: Verify expected error code, actual error: It is not possible to insert a customer with VAT exemption if an active VAT exemption doesn't exist.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateSellToCustomerNoOrderSalesHeaderError()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Purpose of the test is to validate Sell-to Customer No. - OnValidate Trigger of Table ID - 36 Sales Header.
        OnValidateSellToCustomerNoDocumentTypeSalesHeader(SalesHeader."Document Type"::Order);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateSellToCustomerNoInvoiceSalesHeaderError()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Purpose of the test is to validate Sell-to Customer No. - OnValidate Trigger of Table ID - 36 Sales Header.
        OnValidateSellToCustomerNoDocumentTypeSalesHeader(SalesHeader."Document Type"::Invoice);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateSellToCustomerNoReturnOrderSalesHeaderError()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Purpose of the test is to validate Sell-to Customer No. - OnValidate Trigger of Table ID - 36 Sales Header.
        OnValidateSellToCustomerNoDocumentTypeSalesHeader(SalesHeader."Document Type"::"Return Order");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateSellToCustomerNoCreditMemoSalesHeaderError()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Purpose of the test is to validate Sell-to Customer No. - OnValidate Trigger of Table ID - 36 Sales Header.
        OnValidateSellToCustomerNoDocumentTypeSalesHeader(SalesHeader."Document Type"::"Credit Memo");
    end;

    local procedure OnValidateSellToCustomerNoDocumentTypeSalesHeader(DocumentType: Enum "Sales Document Type")
    var
        SalesHeader: Record "Sales Header";
    begin
        // Setup.
        CreateSalesHeader(SalesHeader, DocumentType);

        // Exercise.
        asserterror SalesHeader.Validate("Sell-to Customer No.", CreateCustomer(true));  // Check VAT Exemption as True.

        // Verify: Verify expected error code, actual error: It is not possible to insert a customer with VAT exemption if an active VAT exemption doesn't exist.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateBuyFromVendorNoOrderPurchaseHeaderError()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Purpose of the test is to validate Buy-from Vendor No. - OnValidate Trigger of Table ID - 38 Purchase Header.
        OnValidateBuyFromVendorNoDocumentTypePurchaseHeader(PurchaseHeader."Document Type"::Order);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateBuyFromVendorNoInvoicePurchaseHeaderError()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Purpose of the test is to validate Buy-from Vendor No. - OnValidate Trigger of Table ID - 38 Purchase Header.
        OnValidateBuyFromVendorNoDocumentTypePurchaseHeader(PurchaseHeader."Document Type"::Invoice);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateBuyFromVendorNoReturnOrderPurchaseHeaderError()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Purpose of the test is to validate Buy-from Vendor No. - OnValidate Trigger of Table ID - 38 Purchase Header.
        OnValidateBuyFromVendorNoDocumentTypePurchaseHeader(PurchaseHeader."Document Type"::"Return Order");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateBuyFromVendorNoCreditMemoPurchaseHeaderError()
    begin
        // Purpose of the test is to validate Buy-from Vendor No. - OnValidate Trigger of Table ID - 38 Purchase Header.
        OnValidateBuyFromVendorNoDocumentTypePurchaseHeader("Purchase Document Type"::"Credit Memo");
    end;

    local procedure OnValidateBuyFromVendorNoDocumentTypePurchaseHeader(DocumentType: Enum "Purchase Document Type")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Setup.
        CreatePurchaseHeader(PurchaseHeader, DocumentType);

        // Exercise.
        asserterror PurchaseHeader.Validate("Buy-from Vendor No.", CreateVendor());

        // Verify: Verify expected error code, actual error: It is not possible to insert a vendor with VAT exemption if an active VAT exemption doesn't exist.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateVATExemptionStartingDateError()
    var
        VATExemption: Record "VAT Exemption";
    begin
        // Purpose of the test is to validate VAT Exempt. Starting Date - OnValidate Trigger of Table ID - 12186 VAT Exemption.
        // Setup.
        Initialize();
        CreateVATExemption(VATExemption);
        UpdatePurchasesPayablesSetupVATExemptionNos(CreateNoSeries());

        // Exercise: Validate VAT Exemption -  VAT Exemption Starting Date with Date after Workdate.
        asserterror
          VATExemption.Validate("VAT Exempt. Starting Date", CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate()));

        // Verify: Verify expected error code, actual error: VAT Exempt. Ending Date must not be prior to VAT Exempt. Starting Date.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateVATExemptionStartingDateActiveExistError()
    var
        VATExemption: Record "VAT Exemption";
        VATExemption2: Record "VAT Exemption";
    begin
        // Purpose of the test is to validate VAT Exempt. Starting Date - OnValidate Trigger of Table ID - 12186 VAT Exemption.

        // Setup: Create VAT Exemption, assign VAT Exemption - Number to second VAT Exemption.
        Initialize();
        CreateVATExemption(VATExemption);
        VATExemption2."No." := VATExemption."No.";
        UpdatePurchasesPayablesSetupVATExemptionNos(CreateNoSeries());

        // Exercise: Validate VAT Exemption - VAT Exemption Starting Date with created VAT Exemption - VAT Exemption Ending Date.
        asserterror VATExemption2.Validate("VAT Exempt. Starting Date", VATExemption."VAT Exempt. Ending Date");

        // Verify: Verify expected error code, actual error: It is not possible to insert a new VAT exemption if an active exemption exists.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateVATExemptionEndingDateError()
    var
        VATExemption: Record "VAT Exemption";
    begin
        // Purpose of the test is to validate VAT Exempt. Ending Date - OnValidate Trigger of Table ID - 12186 VAT Exemption.
        // Setup.
        CreateVATExemption(VATExemption);

        // Exercise: Validate VAT Exemption - VAT Exemption Ending Date with Date after Workdate.
        asserterror
          VATExemption.Validate("VAT Exempt. Ending Date", CalcDate('<' + Format(-LibraryRandom.RandInt(10)) + 'D>', WorkDate()));

        // Verify: Verify expected error code, actual error: VAT Exempt. Ending Date must not be prior to VAT Exempt. Starting Date.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateVATExemptionEndingDateOnSamePeriodError()
    var
        VATExemption: Record "VAT Exemption";
        VATExemption2: Record "VAT Exemption";
    begin
        // Purpose of the test is to validate VAT Exempt. Ending Date - OnValidate Trigger of Table ID - 12186 VAT Exemption.

        // Setup: Create VAT Exemption, assign VAT Exemption - Number to second VAT Exemption.
        CreateVATExemption(VATExemption);
        VATExemption2."No." := VATExemption."No.";

        // Exercise: Validate VAT Exemption - VAT Exemption Ending Date with created VAT Exemption - VAT Exemption starting Date.
        asserterror VATExemption2.Validate("VAT Exempt. Ending Date", VATExemption."VAT Exempt. Starting Date");

        // Verify: Verify expected error code, actual error: It is not possible to have two VAT Exemptions in the same period.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnInsertVATExemptIntRegistryNoVATExemption()
    var
        VATExemption: Record "VAT Exemption";
        VATExemption2: Record "VAT Exemption";
    begin
        // [SCENARIO] "VAT Exempt. Int. Registry No." should be different for two VAT Exemptions having the same "No." and "Starting Date" within the same year

        // [GIVEN] Created 1st VAT Exemption
        CreateVATExemption(VATExemption);

        // [GIVEN] Assigned "No." and "Starting Date" to the second VAT Exemption.
        VATExemption2."No." := VATExemption."No.";
        VATExemption2."VAT Exempt. Starting Date" := VATExemption."VAT Exempt. Starting Date";

        // [WHEN] Insert the 2nd VAT Exemption
        VATExemption2.Insert(true);

        // [THEN] "VAT Exempt. Int. Registry No." of VAT Exemption are different
        Assert.AreNotEqual(
          VATExemption."VAT Exempt. Int. Registry No.",
          VATExemption2."VAT Exempt. Int. Registry No.",
          VATExemption.FieldCaption("VAT Exempt. Int. Registry No."));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnInsertVATExemptionTypeCustomerVATExemptionError()
    var
        VATExemption: Record "VAT Exemption";
        OldVATExemptionNos: Code[20];
    begin
        // Purpose of the test is to validate OnInsert Trigger of Table ID - 12186 VAT Exemption.

        // Setup: Update Sales & Receivables Setup.
        OldVATExemptionNos := UpdateSalesReceivablesSetupVATExemptionNos(CreateNoSeries());
        VATExemption.Type := VATExemption.Type::Customer;

        // Exercise.
        asserterror VATExemption.Insert(true);

        // Verify: Verify expected error code, actual error:It is not possible to assign numbers automatically. If you want the program to assign numbers automatically, please activate Default Nos. in No. Series.
        Assert.ExpectedErrorCode(DialogErr);

        // TearDown.
        UpdateSalesReceivablesSetupVATExemptionNos(OldVATExemptionNos);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnInsertVATExemptionTypeVendorVATExemptionError()
    var
        VATExemption: Record "VAT Exemption";
        OldVATExemptionNos: Code[20];
    begin
        // Purpose of the test is to validate OnInsert Trigger of Table ID - 12186 VAT Exemption.

        // Setup: Update Purchases & Payables Setup.
        OldVATExemptionNos := UpdatePurchasesPayablesSetupVATExemptionNos(CreateNoSeries());
        VATExemption.Type := VATExemption.Type::Vendor;

        // Exercise.
        asserterror VATExemption.Insert(true);

        // Verify: Verify expected error code, actual error:It is not possible to assign numbers automatically. If you want the program to assign numbers automatically, please activate Default Nos. in No. Series.
        Assert.ExpectedErrorCode(DialogErr);

        // TearDown.
        UpdatePurchasesPayablesSetupVATExemptionNos(OldVATExemptionNos);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnValidateVATExemptIntlRegNo()
    var
        VATExemption: Record "VAT Exemption";
        StartingNo: Code[20];
        StartDate: Date;
    begin
        // Setup No. Series and save the Starting No.
        StartingNo := SetNoSeries();
        StartDate := CalcDate('<-CM>', WorkDate());

        // Create the VAT Exemption for a new Customer
        CreateVATExemptionWithValidation(
          VATExemption, CreateCustomer(true), StartDate, GetNextRandDate(StartDate), true);

        // Verify that the "VAT Exemption Intl. Register No." value is set from No. Series Setup
        Assert.AreEqual(
          StartingNo, VATExemption."VAT Exempt. Int. Registry No.", VATExemptNumeringNoSeriesErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnValidateVATExIntRegNoOneYear()
    var
        VATExemption: array[2] of Record "VAT Exemption";
        CustomerNo: Code[20];
        StartDate: Date;
    begin
        // [SCENARIO] Different "VAT Exemption Int. Register No." should be assigned for two VAT Exemptions for one customer for one year

        SetNoSeries();

        CustomerNo := CreateCustomer(true);

        // [GIVEN] Created the 1st VAT Exemption for current year
        StartDate := CalcDate('<-CM>', WorkDate());
        CreateVATExemptionWithValidation(
          VATExemption[1], CustomerNo, StartDate, GetNextRandDate(StartDate), true);

        // [WHEN] Create the 2nd VAT Exemption for current year
        StartDate := CalcDate('<-CM+14D>', WorkDate());
        // Create the 2nd VAT Exemption for current year
        CreateVATExemptionWithValidation(
          VATExemption[2], CustomerNo, StartDate, GetNextRandDate(StartDate), true);

        // [THEN] "VAT Exemption Intl. Register No." values are different
        Assert.AreNotEqual(
          VATExemption[1]."VAT Exempt. Int. Registry No.",
          VATExemption[2]."VAT Exempt. Int. Registry No.",
          VATExemption[1].FieldCaption("VAT Exempt. Int. Registry No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnValidateVATExIntRegNoDiffCustomers()
    var
        VATExemption: array[2] of Record "VAT Exemption";
        StartDate: Date;
    begin
        // Check that for different customers the system assigns different values of "VAT Exemption Int. Register No."
        // for a one year
        SetNoSeries();
        StartDate := CalcDate('<-CM>', WorkDate());

        // Create a new Customer and the 1st VAT Exemption for current year
        CreateVATExemptionWithValidation(
          VATExemption[1], CreateCustomer(true), StartDate, GetNextRandDate(StartDate), true);

        // Create a new Customer the 2nd VAT Exemption for current year
        CreateVATExemptionWithValidation(
          VATExemption[2], CreateCustomer(true), StartDate, GetNextRandDate(StartDate), true);

        // Verify that the "VAT Exemption Intl. Register No." values are different
        Assert.AreNotEqual(
          VATExemption[1]."VAT Exempt. Int. Registry No.", VATExemption[2]."VAT Exempt. Int. Registry No.", VATExemptNumeringErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnValidateVATExemptStartDateForVendor()
    var
        VATExemption: Record "VAT Exemption";
    begin
        // [SCENARIO 337552] Create "VAT Exempt." without Pre-setup in Purchases & Payables Setup
        // [GIVEN] Removed data from PurchasesPayablesSetup."VAT Exemption Nos."
        Initialize();

        UpdatePurchasesPayablesSetupVATExemptionNos('');

        // [WHEN] Create new line "VAT Exempt." for type Vendor in VAT Exempt.
        VATExemption.Validate("VAT Exempt. Starting Date", WorkDate());
        VATExemption.Validate(Type, VATExemption.Type::Vendor);
        asserterror VATExemption.Insert(true);

        // [THEN] The error was shown.
        Assert.ExpectedErrorCode(TestFieldErr);
        VATExemption.SetRange("VAT Exempt. Starting Date", WorkDate());
        VATExemption.SetRange(Type, VATExemption.Type::Vendor);
        Assert.RecordIsEmpty(VATExemption);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnValidateVATExemptStartDateForCustomer()
    var
        VATExemption: Record "VAT Exemption";
        VATExemptionNo: Code[20];
    begin
        // [SCENARIO 337552] Create "VAT Exempt." without Pre-setup in Sales & Receivables Setup
        // [GIVEN] Removed data from SalesReceivablesSetup."VAT Exemption Nos."
        Initialize();

        UpdateSalesReceivablesSetupVATExemptionNos('');

        // [GIVEN] VATExemption No "N"
        VATExemptionNo := CopyStr(LibraryRandom.RandText(MaxStrLen(VATExemptionNo)), 1, MaxStrLen(VATExemptionNo));

        // [WHEN] Create new line "VAT Exempt." for type Customer in VAT Exempt.
        VATExemption.Validate("VAT Exempt. Starting Date", WorkDate());
        VATExemption.Validate(Type, VATExemption.Type::Customer);
        VATExemption.Validate("VAT Exempt. Ending Date", WorkDate());
        VATExemption.Validate("VAT Exempt. No.", VATExemptionNo);
        VATExemption.Insert(true);

        // [THEN] The line with VATExemption No. "N" was created
        VATExemption.SetRange("VAT Exempt. No.", VATExemptionNo);
        VATExemption.SetRange(Type, VATExemption.Type::Customer);
        Assert.RecordIsNotEmpty(VATExemption);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnValidateVATExemptIntRegistryNoForVendor()
    var
        PurchaseSetup: Record "Purchases & Payables Setup";
        VATExemptions: TestPage "VAT Exemptions";
        VendorCard: TestPage "Vendor Card";
    begin
        // [SCENARIO 385036] Change "VAT Exempt. Int. Registry No." in page "VAT Exemptions" using assistedit with empty "VAT Exemption Nos." in Purchase Setup
        Initialize();

        // [GIVEN] Removed data from PurchasesPayablesSetup."VAT Exemption Nos."
        UpdatePurchasesPayablesSetupVATExemptionNos('');

        // [GIVEN] Open page 12100 "VAT Exemptions" from Vendor Card
        VendorCard.OpenEdit();
        VendorCard.FILTER.SetFilter("No.", LibraryPurchase.CreateVendorNo());
        VATExemptions.Trap();
        VendorCard."VAT E&xemption".Invoke();

        // [WHEN] VATExemption No "N"
        asserterror VATExemptions."VAT Exempt. Int. Registry No.".AssistEdit();

        // [THEN] Testfield error was shown
        Assert.ExpectedTestFieldError(PurchaseSetup.FieldCaption("VAT Exemption Nos."), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnValidateVATExemptIntRegistryNoForCustomer()
    var
        VATExemptions: TestPage "VAT Exemptions";
        SalesSetup: Record "Sales & Receivables Setup";
        CustomerCard: TestPage "Customer Card";
    begin
        // [SCENARIO 385036] Change "VAT Exempt. Int. Registry No." in page "VAT Exemptions" unsing assistedit with empty "VAT Exemption Nos." in Sales Setup
        Initialize();

        // [GIVEN] Removed data from SalesReceivablesSetup."VAT Exemption Nos."
        UpdateSalesReceivablesSetupVATExemptionNos('');

        // [GIVEN] Open page 12100 "VAT Exemptions" from Customer Card
        CustomerCard.OpenEdit();
        CustomerCard.FILTER.SetFilter("No.", LibrarySales.CreateCustomerNo());
        VATExemptions.Trap();
        CustomerCard."VAT E&xemption".Invoke();

        // [WHEN] VATExemption No "N"
        asserterror VATExemptions."VAT Exempt. Int. Registry No.".AssistEdit();

        // [THEN] Testfield error was shown
        Assert.ExpectedTestFieldError(SalesSetup.FieldCaption("VAT Exemption Nos."), '');
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;

        LibrarySetupStorage.SavePurchasesSetup();
        LibrarySetupStorage.SaveSalesSetup();
        IsInitialized := true;
    end;

    local procedure CreateCustomer(CheckVATExemption: Boolean): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer."No." := LibraryUTUtility.GetNewCode();
        Customer."Customer Posting Group" := LibraryUTUtility.GetNewCode10();
        Customer."Gen. Bus. Posting Group" := LibraryUTUtility.GetNewCode10();
        Customer."VAT Bus. Posting Group" := CreateVATBusinessPostingGroup(CheckVATExemption);
        Customer.Insert();
        exit(Customer."No.");
    end;

    local procedure CreateNoSeries(): Code[20]
    var
        NoSeries: Record "No. Series";
    begin
        NoSeries.Code := LibraryUTUtility.GetNewCode10();
        NoSeries.Insert();
        exit(NoSeries.Code);
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type")
    begin
        PurchaseHeader."Document Type" := DocumentType;
        PurchaseHeader."No." := LibraryUTUtility.GetNewCode();
        PurchaseHeader.Insert();
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type")
    begin
        SalesHeader."Document Type" := DocumentType;
        SalesHeader."No." := LibraryUTUtility.GetNewCode();
        SalesHeader."Document Date" := WorkDate();
        SalesHeader.Insert();
    end;

    local procedure CreateServiceHeader(var ServiceHeader: Record "Service Header"; DocumentType: Enum "Service Document Type")
    begin
        ServiceHeader."Document Type" := DocumentType;
        ServiceHeader."No." := LibraryUTUtility.GetNewCode();
        ServiceHeader."Document Date" := WorkDate();
        ServiceHeader.Insert();
    end;

    local procedure CreateVATBusinessPostingGroup(CheckVATExemption: Boolean): Code[10]
    var
        VATBusPostingGroup: Record "VAT Business Posting Group";
    begin
        VATBusPostingGroup.Code := LibraryUTUtility.GetNewCode10();
        VATBusPostingGroup."Check VAT Exemption" := CheckVATExemption;
        VATBusPostingGroup.Insert();
        exit(VATBusPostingGroup.Code);
    end;

    local procedure CreateVATExemption(var VATExemption: Record "VAT Exemption")
    begin
        VATExemption.Type := VATExemption.Type::Customer;
        VATExemption."No." := CreateCustomer(false);  // Check VAT Exemption as False.
        VATExemption."VAT Exempt. Ending Date" := WorkDate();
        VATExemption."VAT Exempt. Starting Date" := WorkDate();
        VATExemption."VAT Exempt. Int. Registry No." := LibraryUTUtility.GetNewCode();
        VATExemption."VAT Exempt. No." := LibraryUTUtility.GetNewCode();
        VATExemption.Insert();
    end;

    local procedure CreateVATExemptionWithValidation(var VATExemption: Record "VAT Exemption"; No: Code[20]; StartingDate: Date; EndingDate: Date; RunTrigger: Boolean)
    begin
        VATExemption.Type := VATExemption.Type;
        VATExemption."No." := No;
        VATExemption."VAT Exempt. Ending Date" := StartingDate;
        VATExemption."VAT Exempt. Starting Date" := EndingDate;
        VATExemption."VAT Exempt. No." := LibraryUTUtility.GetNewCode();
        VATExemption.Insert(RunTrigger);
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor."No." := LibraryUTUtility.GetNewCode();
        Vendor."Vendor Posting Group" := LibraryUTUtility.GetNewCode10();
        Vendor."Gen. Bus. Posting Group" := LibraryUTUtility.GetNewCode10();
        Vendor."VAT Bus. Posting Group" := CreateVATBusinessPostingGroup(true);  // Check VAT Exemption as TRUE.
        Vendor.Insert();
        exit(Vendor."No.");
    end;

    local procedure UpdatePurchasesPayablesSetupVATExemptionNos(VATExemptionNos: Code[20]) OldVATExemptionNos: Code[20]
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        OldVATExemptionNos := PurchasesPayablesSetup."VAT Exemption Nos.";
        PurchasesPayablesSetup."VAT Exemption Nos." := VATExemptionNos;
        PurchasesPayablesSetup.Modify();
    end;

    local procedure UpdateSalesReceivablesSetupVATExemptionNos(VATExemptionNos: Code[20]) OldVATExemptionNos: Code[20]
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        OldVATExemptionNos := SalesReceivablesSetup."VAT Exemption Nos.";
        SalesReceivablesSetup."VAT Exemption Nos." := VATExemptionNos;
        SalesReceivablesSetup.Modify();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure CheckVATExemptionConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.AreEqual(Format(CustomerVATExemptionTxt), Question, ValueMustEqualMsg);
        Reply := true;
    end;

    local procedure SetNoSeries(): Code[20]
    var
        NoSeriesLine: Record "No. Series Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."VAT Exemption Nos." := LibraryERM.CreateNoSeriesCode();
        SalesReceivablesSetup.Modify();

        NoSeriesLine.Reset();
        NoSeriesLine.SetRange("Series Code", SalesReceivablesSetup."VAT Exemption Nos.");
        NoSeriesLine.FindFirst();
        exit(NoSeriesLine."Starting No.");
    end;

    local procedure GetNextRandDate(StartDate: Date): Date
    begin
        exit(CalcDate('<+' + Format(LibraryRandom.RandInt(10)) + 'D>', StartDate));
    end;
}

