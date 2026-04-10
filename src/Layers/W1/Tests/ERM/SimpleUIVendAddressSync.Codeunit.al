codeunit 138045 "Simple UI: Vend. Address Sync"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Purchase] [Vendor] [Address]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        HasAddressErr: Label 'HasAddress of the %1 record should return true.', Comment = 'HasAddress of the Vendor record should return true.';
        DoesNotHaveAddressErr: Label 'HasAddress of the %1 record should return false.', Comment = 'HasAddress of the Vendor record should return false.';
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        isInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure TestSyncBuyFromAddressToExistingVendorAddress()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        Address2: Text[50];
    begin
        // [GIVEN]A Purchase Invoice document, and a Buy-From Vendor record with an address.
        // [WHEN]User finished editing the header (Buy-From Address fields) and either leaves the page,
        // invokes an action or starts working on the lines
        // [THEN]The address fields on the Buy-From Vendor do not get sync-ed with the data from the Purchase Header.
        Initialize();

        // Setup.
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        Address2 := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Vendor."Address 2")), 1, 50);
        Vendor."Address 2" := Address2;
        Vendor.Modify(true);
        UpdateBuyFromAddressOnPurchaseHeader(PurchaseHeader);

        // Pre-verify.
        Vendor.Find();
        Assert.IsTrue(Vendor.HasAddress(), StrSubstNo(HasAddressErr, Vendor.TableCaption()));

        // Exercise.
        PurchaseHeader.Modify(true);

        // Verify.
        Vendor.Find();
        Assert.IsTrue(Vendor.HasAddress(), StrSubstNo(HasAddressErr, Vendor.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSyncShipToAddressToExistingVendorAddress()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        Address2: Text[50];
    begin
        // [GIVEN]A Purchase Invoice document, and a Buy-from Vendor record with an address.
        // [WHEN]User finished editing the header (Ship-to Address fields) and either leaves the page,
        // invokes an action or starts working on the lines
        // [THEN]The address fields on the Buy-from Vendor do not get sync-ed with the data from the Purchase Header.
        Initialize();

        // Setup.
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        Address2 := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Vendor."Address 2")), 1, 50);
        Vendor."Address 2" := Address2;
        Vendor.Modify(true);
        UpdateShipToAddressOnPurchaseHeader(PurchaseHeader);

        // Pre-verify.
        Vendor.Find();
        Assert.IsTrue(Vendor.HasAddress(), StrSubstNo(HasAddressErr, Vendor.TableCaption()));

        // Exercise.
        PurchaseHeader.Modify(true);

        // Verify.
        Vendor.Find();
        Assert.IsTrue(Vendor.HasAddress(), StrSubstNo(HasAddressErr, Vendor.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerWithMessageValidation')]
    [Scope('OnPrem')]
    procedure TestReplaceExistingBuyFromVendorByVendorWithoutAddress()
    var
        OriginalVendor: Record Vendor;
        ReplacementVendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
    begin
        // [GIVEN] New Purchase Invoice document is created with Buy-from Address details
        // [GIVEN] Vendor without address details is assigned to the Purchase Invoice
        // [WHEN] Buy-from Vendor is replaced with another Vendor without address details
        // [WHEN] Confirm to replace the Buy-from Vendor and not to replace the Pay-to Vendor
        // [THEN] Buy-from Address details are cleared from the Purchase Invoice
        // [THEN] Pay-to Address details are not cleared from the Purchase Invoice
        Initialize();

        // Setup
        LibraryPurchase.CreateVendor(OriginalVendor);
        LibraryPurchase.CreateVendor(ReplacementVendor);

        CreatePurchaseInvoiceWithBuyFromAndPayToAddresses(OriginalVendor.Name);

        // Exercise
        // LibraryVariableStorage.Enqueue('Buy-from Vendor');
        LibraryVariableStorage.Enqueue(true);
        // LibraryVariableStorage.Enqueue('Pay-to Vendor');
        LibraryVariableStorage.Enqueue(false);

        ReplacePurchaseInvoiceBuyFromVendor(OriginalVendor."No.", ReplacementVendor.Name);

        // Verify
        FindBuyFromVendorPurchaseInvoice(PurchaseHeader, ReplacementVendor."No.");
        Assert.IsFalse(PurchaseHeader.HasBuyFromAddress(), StrSubstNo(DoesNotHaveAddressErr, PurchaseHeader.TableCaption()));
        Assert.IsTrue(PurchaseHeader.HasShipToAddress(), StrSubstNo(HasAddressErr, PurchaseHeader.TableCaption()));
        Assert.IsTrue(PurchaseHeader.HasPayToAddress(), StrSubstNo(HasAddressErr, PurchaseHeader.TableCaption()));

        // Teardown
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerWithMessageValidation')]
    [Scope('OnPrem')]
    procedure TestReplaceExistingPayToVendorByVendorWithoutAddress()
    var
        OriginalVendor: Record Vendor;
        ReplacementVendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
    begin
        // [GIVEN] New Purchase Invoice document is created with Buy-from Address details
        // [GIVEN] Vendor without address details is assigned to the Purchase Invoice
        // [WHEN] Pay-to Vendor is replaced with another Vendor without address details
        // [WHEN] Confirm not to replace the Buy-from Vendor and to replace the Pay-to Vendor
        // [THEN] Buy-from Address details are not cleared from the Purchase Invoice
        // [THEN] Pay-to Address details are cleared from the Purchase Invoice
        Initialize();

        // Setup
        LibraryPurchase.CreateVendor(OriginalVendor);
        LibraryPurchase.CreateVendor(ReplacementVendor);

        CreatePurchaseInvoiceWithBuyFromAndPayToAddresses(OriginalVendor.Name);

        // Exercise
        // LibraryVariableStorage.Enqueue('Pay-to Vendor');
        LibraryVariableStorage.Enqueue(true);

        ReplacePurchaseInvoicePayToVendor(OriginalVendor."No.", ReplacementVendor.Name);

        // Verify
        FindPayToVendorPurchaseInvoice(PurchaseHeader, ReplacementVendor."No.");
        Assert.IsTrue(PurchaseHeader.HasBuyFromAddress(), StrSubstNo(HasAddressErr, PurchaseHeader.TableCaption()));
        Assert.IsTrue(PurchaseHeader.HasShipToAddress(), StrSubstNo(HasAddressErr, PurchaseHeader.TableCaption()));
        Assert.IsFalse(PurchaseHeader.HasPayToAddress(), StrSubstNo(DoesNotHaveAddressErr, PurchaseHeader.TableCaption()));

        // Teardown
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerWithMessageValidation')]
    [Scope('OnPrem')]
    procedure TestReplaceExistingBuyFromAndPayToVendorsByVendorWithoutAddress()
    var
        OriginalVendor: Record Vendor;
        ReplacementVendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
    begin
        // [GIVEN] New Purchase Invoice document is created with Buy-from Address details
        // [GIVEN] Vendor without address details is assigned to the Purchase Invoice
        // [WHEN] Buy-from Vendor is replaced with another Vendor without address details
        // [WHEN] Confirm to replace both Buy-from Vendor and Pay-to Vendor
        // [THEN] Buy-from Address details are cleared from the Purchase Invoice
        // [THEN] Pay-to Address details are cleared from the Purchase Invoice
        Initialize();

        // Setup
        LibraryPurchase.CreateVendor(OriginalVendor);
        LibraryPurchase.CreateVendor(ReplacementVendor);

        CreatePurchaseInvoiceWithBuyFromAndPayToAddresses(OriginalVendor.Name);

        // Exercise
        // LibraryVariableStorage.Enqueue('Buy-from Vendor');
        LibraryVariableStorage.Enqueue(true);
        // LibraryVariableStorage.Enqueue('Pay-to Vendor');
        LibraryVariableStorage.Enqueue(true);

        ReplacePurchaseInvoiceBuyFromVendor(OriginalVendor."No.", ReplacementVendor.Name);

        // Verify
        FindBuyFromVendorPurchaseInvoice(PurchaseHeader, ReplacementVendor."No.");
        Assert.IsFalse(PurchaseHeader.HasBuyFromAddress(), StrSubstNo(DoesNotHaveAddressErr, PurchaseHeader.TableCaption()));
        Assert.IsTrue(PurchaseHeader.HasShipToAddress(), StrSubstNo(HasAddressErr, PurchaseHeader.TableCaption()));
        Assert.IsFalse(PurchaseHeader.HasPayToAddress(), StrSubstNo(DoesNotHaveAddressErr, PurchaseHeader.TableCaption()));

        // Teardown
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerWithMessageValidation')]
    [Scope('OnPrem')]
    procedure TestReplaceExistingBuyFromAndPayToVendorsByVendorWithAddress()
    var
        OriginalVendor: Record Vendor;
        ReplacementVendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [GIVEN] New Purchase Invoice document is created with Buy-from Address details
        // [GIVEN] Vendor with address details is assigned to the Purchase Invoice
        // [WHEN] Buy-from Vendor is replaced with another Vendor with address details
        // [WHEN] Confirm to replace both Buy-from Vendor and Pay-to Vendor
        // [THEN] Buy-from Address details are overriden on the Purchase Invoice
        // [THEN] Ship-to Address details are overriden on the Purchase Invoice
        // [THEN] Pay-to Address details are overriden on the Purchase Invoice
        Initialize();

        // Setup
        LibraryPurchase.CreateVendor(OriginalVendor);
        CreateVendorWithAddress(ReplacementVendor);

        LibraryPurchase.CreatePurchaseDocumentWithItem(PurchaseHeader, PurchaseLine,
          PurchaseHeader."Document Type"::Invoice, OriginalVendor."No.", '', LibraryRandom.RandInt(10), '', 0D);

        // Exercise
        LibraryVariableStorage.Enqueue(true); // Replace Buy-from Vendor
        LibraryVariableStorage.Enqueue(true); // Replace Pay-to Vendor
        LibraryVariableStorage.Enqueue(true); // Recreate Purchase Lines

        ReplacePurchaseInvoiceBuyFromVendor(OriginalVendor."No.", ReplacementVendor.Name);

        // Verify
        FindBuyFromVendorPurchaseInvoice(PurchaseHeader, ReplacementVendor."No.");
        VerifyBuyFromAddressSyncedFromVendor(PurchaseHeader, ReplacementVendor);
        VerifyShipToAddressSyncedFromCompany(PurchaseHeader);
        VerifyPayToAddressSyncedFromVendor(PurchaseHeader, ReplacementVendor);

        // Teardown
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVendorHasAddressForAddressField()
    var
        Vendor: Record Vendor;
    begin
        Initialize();

        // Setup.
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Address := CopyStr(LibraryUtility.GenerateRandomText(
              MaxStrLen(Vendor.Address)), 1, MaxStrLen(Vendor.Address));
        Vendor.Modify(true);

        // Verify.
        Assert.IsTrue(Vendor.HasAddress(), StrSubstNo(HasAddressErr, Vendor.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVendorHasAddressForAddress2Field()
    var
        Vendor: Record Vendor;
    begin
        Initialize();

        // Setup.
        LibraryPurchase.CreateVendor(Vendor);
        Vendor."Address 2" := CopyStr(LibraryUtility.GenerateRandomText(
              MaxStrLen(Vendor."Address 2")), 1, MaxStrLen(Vendor."Address 2"));
        Vendor.Modify(true);

        // Verify.
        Assert.IsTrue(Vendor.HasAddress(), StrSubstNo(HasAddressErr, Vendor.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVendorHasAddressForCityField()
    var
        Vendor: Record Vendor;
    begin
        Initialize();

        // Setup.
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.City := CopyStr(LibraryUtility.GenerateRandomText(
              MaxStrLen(Vendor.City)), 1, MaxStrLen(Vendor.City));
        Vendor.Modify(true);

        // Verify.
        Assert.IsTrue(Vendor.HasAddress(), StrSubstNo(HasAddressErr, Vendor.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVendorHasAddressForCountryField()
    var
        Vendor: Record Vendor;
    begin
        Initialize();

        // Setup.
        LibraryPurchase.CreateVendor(Vendor);
        Vendor."Country/Region Code" := CopyStr(LibraryUtility.GenerateRandomText(
              MaxStrLen(Vendor."Country/Region Code")), 1, MaxStrLen(Vendor."Country/Region Code"));
        Vendor.Modify(true);

        // Verify.
        Assert.IsTrue(Vendor.HasAddress(), StrSubstNo(HasAddressErr, Vendor.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVendorHasAddressForCountyField()
    var
        Vendor: Record Vendor;
    begin
        Initialize();

        // Setup.
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.County := CopyStr(LibraryUtility.GenerateRandomText(
              MaxStrLen(Vendor.County)), 1, MaxStrLen(Vendor.County));
        Vendor.Modify(true);

        // Verify.
        Assert.IsTrue(Vendor.HasAddress(), StrSubstNo(HasAddressErr, Vendor.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVendorHasAddressForPostCodeField()
    var
        Vendor: Record Vendor;
    begin
        Initialize();

        // Setup.
        LibraryPurchase.CreateVendor(Vendor);
        Vendor."Post Code" := CopyStr(LibraryUtility.GenerateRandomText(
              MaxStrLen(Vendor."Post Code")), 1, MaxStrLen(Vendor."Post Code"));
        Vendor.Modify(true);

        // Verify.
        Assert.IsTrue(Vendor.HasAddress(), StrSubstNo(HasAddressErr, Vendor.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVendorHasAddressForContactField()
    var
        Vendor: Record Vendor;
    begin
        Initialize();

        // Setup.
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Contact := CopyStr(LibraryUtility.GenerateRandomText(
              MaxStrLen(Vendor.Contact)), 1, MaxStrLen(Vendor.Contact));
        Vendor.Modify(true);

        // Verify.
        Assert.IsTrue(Vendor.HasAddress(), StrSubstNo(HasAddressErr, Vendor.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseHeaderHasBuyFromAddressForAddressField()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        Initialize();

        // Setup.
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo(), '', 1, '', 0D);
        PurchaseHeader."Buy-from Address" :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(PurchaseHeader."Buy-from Address")),
            1, MaxStrLen(PurchaseHeader."Buy-from Address"));
        PurchaseHeader.Modify(true);

        // Verify.
        Assert.IsTrue(PurchaseHeader.HasBuyFromAddress(), StrSubstNo(HasAddressErr, PurchaseHeader.TableCaption()));
        Assert.IsTrue(PurchaseHeader.HasShipToAddress(), StrSubstNo(HasAddressErr, PurchaseHeader.TableCaption()));
        Assert.IsFalse(PurchaseHeader.HasPayToAddress(), StrSubstNo(DoesNotHaveAddressErr, PurchaseHeader.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseHeaderHasBuyFromAddressForAddress2Field()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        Initialize();

        // Setup.
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo(), '', 1, '', 0D);
        PurchaseHeader."Buy-from Address 2" :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(PurchaseHeader."Buy-from Address 2")),
            1, MaxStrLen(PurchaseHeader."Buy-from Address 2"));
        PurchaseHeader.Modify(true);

        // Verify.
        Assert.IsTrue(PurchaseHeader.HasBuyFromAddress(), StrSubstNo(HasAddressErr, PurchaseHeader.TableCaption()));
        Assert.IsTrue(PurchaseHeader.HasShipToAddress(), StrSubstNo(HasAddressErr, PurchaseHeader.TableCaption()));
        Assert.IsFalse(PurchaseHeader.HasPayToAddress(), StrSubstNo(DoesNotHaveAddressErr, PurchaseHeader.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseHeaderHasBuyFromAddressForCityField()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        Initialize();

        // Setup.
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo(), '', 1, '', 0D);
        PurchaseHeader."Buy-from City" :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(PurchaseHeader."Buy-from City")),
            1, MaxStrLen(PurchaseHeader."Buy-from City"));
        PurchaseHeader.Modify(true);

        // Verify.
        Assert.IsTrue(PurchaseHeader.HasBuyFromAddress(), StrSubstNo(HasAddressErr, PurchaseHeader.TableCaption()));
        Assert.IsTrue(PurchaseHeader.HasShipToAddress(), StrSubstNo(HasAddressErr, PurchaseHeader.TableCaption()));
        Assert.IsFalse(PurchaseHeader.HasPayToAddress(), StrSubstNo(DoesNotHaveAddressErr, PurchaseHeader.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseHeaderHasBuyFromAddressForCountryField()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        Initialize();

        // Setup.
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo(), '', 1, '', 0D);
        PurchaseHeader."Buy-from Country/Region Code" :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(PurchaseHeader."Buy-from Country/Region Code")),
            1, MaxStrLen(PurchaseHeader."Buy-from Country/Region Code"));
        PurchaseHeader.Modify(true);

        // Verify.
        Assert.IsTrue(PurchaseHeader.HasBuyFromAddress(), StrSubstNo(HasAddressErr, PurchaseHeader.TableCaption()));
        Assert.IsTrue(PurchaseHeader.HasShipToAddress(), StrSubstNo(HasAddressErr, PurchaseHeader.TableCaption()));
        Assert.IsFalse(PurchaseHeader.HasPayToAddress(), StrSubstNo(DoesNotHaveAddressErr, PurchaseHeader.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseHeaderHasBuyFromAddressForCountyField()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        Initialize();

        // Setup.
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo(), '', 1, '', 0D);
        PurchaseHeader."Buy-from County" :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(PurchaseHeader."Buy-from County")),
            1, MaxStrLen(PurchaseHeader."Buy-from County"));
        PurchaseHeader.Modify(true);

        // Verify.
        Assert.IsTrue(PurchaseHeader.HasBuyFromAddress(), StrSubstNo(HasAddressErr, PurchaseHeader.TableCaption()));
        Assert.IsTrue(PurchaseHeader.HasShipToAddress(), StrSubstNo(HasAddressErr, PurchaseHeader.TableCaption()));
        Assert.IsFalse(PurchaseHeader.HasPayToAddress(), StrSubstNo(DoesNotHaveAddressErr, PurchaseHeader.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseHeaderHasBuyFromAddressForPostCodeField()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        Initialize();

        // Setup.
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo(), '', 1, '', 0D);
        PurchaseHeader."Buy-from Post Code" :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(PurchaseHeader."Buy-from Post Code")),
            1, MaxStrLen(PurchaseHeader."Buy-from Post Code"));
        PurchaseHeader.Modify(true);

        // Verify.
        Assert.IsTrue(PurchaseHeader.HasBuyFromAddress(), StrSubstNo(HasAddressErr, PurchaseHeader.TableCaption()));
        Assert.IsTrue(PurchaseHeader.HasShipToAddress(), StrSubstNo(HasAddressErr, PurchaseHeader.TableCaption()));
        Assert.IsFalse(PurchaseHeader.HasPayToAddress(), StrSubstNo(DoesNotHaveAddressErr, PurchaseHeader.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseHeaderHasBuyFromAddressForContactField()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        Initialize();

        // Setup.
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo(), '', 1, '', 0D);
        PurchaseHeader."Buy-from Contact" :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(PurchaseHeader."Buy-from Contact")),
            1, MaxStrLen(PurchaseHeader."Buy-from Contact"));
        PurchaseHeader.Modify(true);

        // Verify.
        Assert.IsTrue(PurchaseHeader.HasBuyFromAddress(), StrSubstNo(HasAddressErr, PurchaseHeader.TableCaption()));
        Assert.IsTrue(PurchaseHeader.HasShipToAddress(), StrSubstNo(HasAddressErr, PurchaseHeader.TableCaption()));
        Assert.IsFalse(PurchaseHeader.HasPayToAddress(), StrSubstNo(DoesNotHaveAddressErr, PurchaseHeader.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseHeaderHasShipToAddressForAddressField()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        Initialize();

        // Setup.
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo(), '', 1, '', 0D);
        PurchaseHeader."Ship-to Address" :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(PurchaseHeader."Ship-to Address")),
            1, MaxStrLen(PurchaseHeader."Ship-to Address"));
        PurchaseHeader.Modify(true);

        // Verify.
        Assert.IsFalse(PurchaseHeader.HasBuyFromAddress(), StrSubstNo(DoesNotHaveAddressErr, PurchaseHeader.TableCaption()));
        Assert.IsTrue(PurchaseHeader.HasShipToAddress(), StrSubstNo(HasAddressErr, PurchaseHeader.TableCaption()));
        Assert.IsFalse(PurchaseHeader.HasPayToAddress(), StrSubstNo(DoesNotHaveAddressErr, PurchaseHeader.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseHeaderHasShipToAddressForAddress2Field()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        Initialize();

        // Setup.
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo(), '', 1, '', 0D);
        PurchaseHeader."Ship-to Address 2" :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(PurchaseHeader."Ship-to Address 2")),
            1, MaxStrLen(PurchaseHeader."Ship-to Address 2"));
        PurchaseHeader.Modify(true);

        // Verify.
        Assert.IsFalse(PurchaseHeader.HasBuyFromAddress(), StrSubstNo(DoesNotHaveAddressErr, PurchaseHeader.TableCaption()));
        Assert.IsTrue(PurchaseHeader.HasShipToAddress(), StrSubstNo(HasAddressErr, PurchaseHeader.TableCaption()));
        Assert.IsFalse(PurchaseHeader.HasPayToAddress(), StrSubstNo(DoesNotHaveAddressErr, PurchaseHeader.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseHeaderHasShipToAddressForCityField()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        Initialize();

        // Setup.
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo(), '', 1, '', 0D);
        PurchaseHeader."Ship-to City" :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(PurchaseHeader."Ship-to City")),
            1, MaxStrLen(PurchaseHeader."Ship-to City"));
        PurchaseHeader.Modify(true);

        // Verify.
        Assert.IsFalse(PurchaseHeader.HasBuyFromAddress(), StrSubstNo(DoesNotHaveAddressErr, PurchaseHeader.TableCaption()));
        Assert.IsTrue(PurchaseHeader.HasShipToAddress(), StrSubstNo(HasAddressErr, PurchaseHeader.TableCaption()));
        Assert.IsFalse(PurchaseHeader.HasPayToAddress(), StrSubstNo(DoesNotHaveAddressErr, PurchaseHeader.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseHeaderHasShipToAddressForCountryField()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        Initialize();

        // Setup.
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo(), '', 1, '', 0D);
        PurchaseHeader."Ship-to Country/Region Code" :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(PurchaseHeader."Ship-to Country/Region Code")),
            1, MaxStrLen(PurchaseHeader."Ship-to Country/Region Code"));
        PurchaseHeader.Modify(true);

        // Verify.
        Assert.IsFalse(PurchaseHeader.HasBuyFromAddress(), StrSubstNo(DoesNotHaveAddressErr, PurchaseHeader.TableCaption()));
        Assert.IsTrue(PurchaseHeader.HasShipToAddress(), StrSubstNo(HasAddressErr, PurchaseHeader.TableCaption()));
        Assert.IsFalse(PurchaseHeader.HasPayToAddress(), StrSubstNo(DoesNotHaveAddressErr, PurchaseHeader.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseHeaderHasShipToAddressForCountyField()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        Initialize();

        // Setup.
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo(), '', 1, '', 0D);
        PurchaseHeader."Ship-to County" :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(PurchaseHeader."Ship-to County")),
            1, MaxStrLen(PurchaseHeader."Ship-to County"));
        PurchaseHeader.Modify(true);

        // Verify.
        Assert.IsFalse(PurchaseHeader.HasBuyFromAddress(), StrSubstNo(DoesNotHaveAddressErr, PurchaseHeader.TableCaption()));
        Assert.IsTrue(PurchaseHeader.HasShipToAddress(), StrSubstNo(HasAddressErr, PurchaseHeader.TableCaption()));
        Assert.IsFalse(PurchaseHeader.HasPayToAddress(), StrSubstNo(DoesNotHaveAddressErr, PurchaseHeader.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseHeaderHasShipToAddressForPostCodeField()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        Initialize();

        // Setup.
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo(), '', 1, '', 0D);
        PurchaseHeader."Ship-to Post Code" :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(PurchaseHeader."Ship-to Post Code")),
            1, MaxStrLen(PurchaseHeader."Ship-to Post Code"));
        PurchaseHeader.Modify(true);

        // Verify.
        Assert.IsFalse(PurchaseHeader.HasBuyFromAddress(), StrSubstNo(DoesNotHaveAddressErr, PurchaseHeader.TableCaption()));
        Assert.IsTrue(PurchaseHeader.HasShipToAddress(), StrSubstNo(HasAddressErr, PurchaseHeader.TableCaption()));
        Assert.IsFalse(PurchaseHeader.HasPayToAddress(), StrSubstNo(DoesNotHaveAddressErr, PurchaseHeader.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseHeaderHasShipToAddressForContactField()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        Initialize();

        // Setup.
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo(), '', 1, '', 0D);
        PurchaseHeader."Ship-to Contact" :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(PurchaseHeader."Ship-to Contact")),
            1, MaxStrLen(PurchaseHeader."Ship-to Contact"));
        PurchaseHeader.Modify(true);

        // Verify.
        Assert.IsFalse(PurchaseHeader.HasBuyFromAddress(), StrSubstNo(DoesNotHaveAddressErr, PurchaseHeader.TableCaption()));
        Assert.IsTrue(PurchaseHeader.HasShipToAddress(), StrSubstNo(HasAddressErr, PurchaseHeader.TableCaption()));
        Assert.IsFalse(PurchaseHeader.HasPayToAddress(), StrSubstNo(DoesNotHaveAddressErr, PurchaseHeader.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseHeaderHasPayToAddressForAddressField()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        Initialize();

        // Setup.
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo(), '', 1, '', 0D);
        PurchaseHeader."Pay-to Address" :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(PurchaseHeader."Pay-to Address")),
            1, MaxStrLen(PurchaseHeader."Pay-to Address"));
        PurchaseHeader.Modify(true);

        // Verify.
        Assert.IsFalse(PurchaseHeader.HasBuyFromAddress(), StrSubstNo(DoesNotHaveAddressErr, PurchaseHeader.TableCaption()));
        Assert.IsTrue(PurchaseHeader.HasShipToAddress(), StrSubstNo(HasAddressErr, PurchaseHeader.TableCaption()));
        Assert.IsTrue(PurchaseHeader.HasPayToAddress(), StrSubstNo(HasAddressErr, PurchaseHeader.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseHeaderHasPayToAddressForAddress2Field()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        Initialize();

        // Setup.
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo(), '', 1, '', 0D);
        PurchaseHeader."Pay-to Address 2" :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(PurchaseHeader."Pay-to Address 2")),
            1, MaxStrLen(PurchaseHeader."Pay-to Address 2"));
        PurchaseHeader.Modify(true);

        // Verify.
        Assert.IsFalse(PurchaseHeader.HasBuyFromAddress(), StrSubstNo(DoesNotHaveAddressErr, PurchaseHeader.TableCaption()));
        Assert.IsTrue(PurchaseHeader.HasShipToAddress(), StrSubstNo(HasAddressErr, PurchaseHeader.TableCaption()));
        Assert.IsTrue(PurchaseHeader.HasPayToAddress(), StrSubstNo(HasAddressErr, PurchaseHeader.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseHeaderHasPayToAddressForCityField()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        Initialize();

        // Setup.
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo(), '', 1, '', 0D);
        PurchaseHeader."Pay-to City" :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(PurchaseHeader."Pay-to City")),
            1, MaxStrLen(PurchaseHeader."Pay-to City"));
        PurchaseHeader.Modify(true);

        // Verify.
        Assert.IsFalse(PurchaseHeader.HasBuyFromAddress(), StrSubstNo(DoesNotHaveAddressErr, PurchaseHeader.TableCaption()));
        Assert.IsTrue(PurchaseHeader.HasShipToAddress(), StrSubstNo(HasAddressErr, PurchaseHeader.TableCaption()));
        Assert.IsTrue(PurchaseHeader.HasPayToAddress(), StrSubstNo(HasAddressErr, PurchaseHeader.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseHeaderHasPayToAddressForCountryField()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        Initialize();

        // Setup.
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo(), '', 1, '', 0D);
        PurchaseHeader."Pay-to Country/Region Code" :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(PurchaseHeader."Pay-to Country/Region Code")),
            1, MaxStrLen(PurchaseHeader."Pay-to Country/Region Code"));
        PurchaseHeader.Modify(true);

        // Verify.
        Assert.IsFalse(PurchaseHeader.HasBuyFromAddress(), StrSubstNo(DoesNotHaveAddressErr, PurchaseHeader.TableCaption()));
        Assert.IsTrue(PurchaseHeader.HasShipToAddress(), StrSubstNo(HasAddressErr, PurchaseHeader.TableCaption()));
        Assert.IsTrue(PurchaseHeader.HasPayToAddress(), StrSubstNo(HasAddressErr, PurchaseHeader.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseHeaderHasPayToAddressForCountyField()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        Initialize();

        // Setup.
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo(), '', 1, '', 0D);
        PurchaseHeader."Pay-to County" :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(PurchaseHeader."Pay-to County")),
            1, MaxStrLen(PurchaseHeader."Pay-to County"));
        PurchaseHeader.Modify(true);

        // Verify.
        Assert.IsFalse(PurchaseHeader.HasBuyFromAddress(), StrSubstNo(DoesNotHaveAddressErr, PurchaseHeader.TableCaption()));
        Assert.IsTrue(PurchaseHeader.HasShipToAddress(), StrSubstNo(HasAddressErr, PurchaseHeader.TableCaption()));
        Assert.IsTrue(PurchaseHeader.HasPayToAddress(), StrSubstNo(HasAddressErr, PurchaseHeader.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseHeaderHasPayToAddressForPostCodeField()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        Initialize();

        // Setup.
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo(), '', 1, '', 0D);
        PurchaseHeader."Pay-to Post Code" :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(PurchaseHeader."Pay-to Post Code")),
            1, MaxStrLen(PurchaseHeader."Pay-to Post Code"));
        PurchaseHeader.Modify(true);

        // Verify.
        Assert.IsFalse(PurchaseHeader.HasBuyFromAddress(), StrSubstNo(DoesNotHaveAddressErr, PurchaseHeader.TableCaption()));
        Assert.IsTrue(PurchaseHeader.HasShipToAddress(), StrSubstNo(HasAddressErr, PurchaseHeader.TableCaption()));
        Assert.IsTrue(PurchaseHeader.HasPayToAddress(), StrSubstNo(HasAddressErr, PurchaseHeader.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseHeaderHasPayToAddressForContactField()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        Initialize();

        // Setup.
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo(), '', 1, '', 0D);
        PurchaseHeader."Pay-to Contact" :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(PurchaseHeader."Pay-to Contact")),
            1, MaxStrLen(PurchaseHeader."Pay-to Contact"));
        PurchaseHeader.Modify(true);

        // Verify.
        Assert.IsFalse(PurchaseHeader.HasBuyFromAddress(), StrSubstNo(DoesNotHaveAddressErr, PurchaseHeader.TableCaption()));
        Assert.IsTrue(PurchaseHeader.HasShipToAddress(), StrSubstNo(HasAddressErr, PurchaseHeader.TableCaption()));
        Assert.IsTrue(PurchaseHeader.HasPayToAddress(), StrSubstNo(HasAddressErr, PurchaseHeader.TableCaption()));
    end;

    local procedure Initialize()
    var
        PurchaseHeader: Record "Purchase Header";
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Simple UI: Vend. Address Sync");
        LibraryVariableStorage.Clear();
        LibraryApplicationArea.EnableFoundationSetup();
        PurchaseHeader.DontNotifyCurrentUserAgain(PurchaseHeader.GetModifyPayToVendorAddressNotificationId());
        PurchaseHeader.DontNotifyCurrentUserAgain(PurchaseHeader.GetModifyVendorAddressNotificationId());

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Simple UI: Vend. Address Sync");

        if not LibraryFiscalYear.AccountingPeriodsExists() then
            LibraryFiscalYear.CreateFiscalYear();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Simple UI: Vend. Address Sync");
    end;

    local procedure UpdateBuyFromAddressOnPurchaseHeader(var PurchaseHeader: Record "Purchase Header")
    var
        CountryRegion: Record "Country/Region";
    begin
        PurchaseHeader."Buy-from Address" := CopyStr(LibraryUtility.GenerateRandomText(
              MaxStrLen(PurchaseHeader."Buy-from Address")), 1, MaxStrLen(PurchaseHeader."Buy-from Address"));
        PurchaseHeader."Buy-from Address 2" := CopyStr(LibraryUtility.GenerateRandomText(
              MaxStrLen(PurchaseHeader."Buy-from Address 2")), 1, MaxStrLen(PurchaseHeader."Buy-from Address 2"));
        PurchaseHeader."Buy-from City" := CopyStr(LibraryUtility.GenerateRandomText(
              MaxStrLen(PurchaseHeader."Buy-from City")), 1, MaxStrLen(PurchaseHeader."Buy-from City"));
        PurchaseHeader."Buy-from Contact" := CopyStr(LibraryUtility.GenerateRandomText(20), 1, 20);
        PurchaseHeader."Buy-from County" := CopyStr(LibraryUtility.GenerateRandomText(
              MaxStrLen(PurchaseHeader."Buy-from County")), 1, MaxStrLen(PurchaseHeader."Buy-from County"));
        PurchaseHeader."Buy-from Post Code" := CopyStr(LibraryUtility.GenerateRandomText(
              MaxStrLen(PurchaseHeader."Buy-from Post Code")), 1, MaxStrLen(PurchaseHeader."Buy-from Post Code"));

        LibraryERM.CreateCountryRegion(CountryRegion);
        PurchaseHeader."Buy-from Country/Region Code" := CountryRegion.Code;
    end;

    local procedure UpdateShipToAddressOnPurchaseHeader(var PurchaseHeader: Record "Purchase Header")
    var
        CountryRegion: Record "Country/Region";
    begin
        PurchaseHeader."Ship-to Address" := CopyStr(LibraryUtility.GenerateRandomText(
              MaxStrLen(PurchaseHeader."Ship-to Address")), 1, MaxStrLen(PurchaseHeader."Ship-to Address"));
        PurchaseHeader."Ship-to Address 2" := CopyStr(LibraryUtility.GenerateRandomText(
              MaxStrLen(PurchaseHeader."Ship-to Address 2")), 1, MaxStrLen(PurchaseHeader."Ship-to Address 2"));
        PurchaseHeader."Ship-to City" := CopyStr(LibraryUtility.GenerateRandomText(
              MaxStrLen(PurchaseHeader."Ship-to City")), 1, MaxStrLen(PurchaseHeader."Ship-to City"));
        PurchaseHeader."Ship-to Contact" := CopyStr(LibraryUtility.GenerateRandomText(20), 1, 20);
        PurchaseHeader."Ship-to County" := CopyStr(LibraryUtility.GenerateRandomText(
              MaxStrLen(PurchaseHeader."Ship-to County")), 1, MaxStrLen(PurchaseHeader."Ship-to County"));
        PurchaseHeader."Ship-to Post Code" := CopyStr(LibraryUtility.GenerateRandomText(
              MaxStrLen(PurchaseHeader."Ship-to Post Code")), 1, MaxStrLen(PurchaseHeader."Ship-to Post Code"));
        PurchaseHeader."Ship-to Phone No." := LibraryUtility.GenerateRandomPhoneNo();

        LibraryERM.CreateCountryRegion(CountryRegion);
        PurchaseHeader."Ship-to Country/Region Code" := CountryRegion.Code;
    end;

    local procedure CreatePurchaseInvoiceWithBuyFromAndPayToAddresses(BuyFromVendorName: Text[100])
    var
        BuyFromPostCode: Record "Post Code";
        PayToPostCode: Record "Post Code";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        LibraryERM.CreatePostCode(BuyFromPostCode);
        LibraryERM.CreatePostCode(PayToPostCode);

        PurchaseInvoice.OpenNew();
        PurchaseInvoice."Posting Date".SetValue(WorkDate());
        PurchaseInvoice."Buy-from Post Code".SetValue(BuyFromPostCode.Code);
        PurchaseInvoice."Buy-from Address".SetValue(GenerateBuyFromAddress());
        PurchaseInvoice."Pay-to Post Code".SetValue(PayToPostCode.Code);
        PurchaseInvoice."Pay-to Address".SetValue(GeneratePayToAddress());
        PurchaseInvoice."Buy-from Vendor Name".SetValue(BuyFromVendorName);
        PurchaseInvoice.OK().Invoke();
    end;

    local procedure CreateVendorWithAddress(var Vendor: Record Vendor)
    var
        PostCode: Record "Post Code";
    begin
        LibraryERM.CreatePostCode(PostCode);

        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate(Address, GenerateBuyFromAddress());
        Vendor.Validate("Address 2", CopyStr(GenerateBuyFromAddress(), 1, MaxStrLen(Vendor."Address 2")));
        Vendor.Validate("Post Code", PostCode.Code);
        Vendor.Modify(true);
    end;

    local procedure GenerateBuyFromAddress(): Text[100]
    var
        DummyPurchaseHeader: Record "Purchase Header";
        Address: Text;
        Status: Option Capitalized,Literal;
    begin
        Address := LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(DummyPurchaseHeader."Buy-from Address"), Status::Capitalized);
        exit(CopyStr(Address, 1, MaxStrLen(DummyPurchaseHeader."Buy-from Address")));
    end;

    local procedure GeneratePayToAddress(): Text[100]
    var
        DummyPurchaseHeader: Record "Purchase Header";
        Address: Text;
        Status: Option Capitalized,Literal;
    begin
        Address := LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(DummyPurchaseHeader."Pay-to Address"), Status::Capitalized);
        exit(CopyStr(Address, 1, MaxStrLen(DummyPurchaseHeader."Pay-to Address")));
    end;

    local procedure ReplacePurchaseInvoiceBuyFromVendor(OriginalVendorNo: Code[20]; ReplacementVendorName: Text[100])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        FindBuyFromVendorPurchaseInvoice(PurchaseHeader, OriginalVendorNo);

        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchaseHeader);
        PurchaseInvoice."Buy-from Vendor Name".SetValue(ReplacementVendorName);
        PurchaseInvoice.OK().Invoke();
    end;

    local procedure ReplacePurchaseInvoicePayToVendor(OriginalVendorNo: Code[20]; ReplacementVendorName: Text[100])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        FindPayToVendorPurchaseInvoice(PurchaseHeader, OriginalVendorNo);

        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchaseHeader);
        PurchaseInvoice."Pay-to Name".SetValue(ReplacementVendorName);
        PurchaseInvoice.OK().Invoke();
    end;

    local procedure VerifyBuyFromAddressSyncedFromVendor(var PurchaseHeader: Record "Purchase Header"; Vendor: Record Vendor)
    begin
        PurchaseHeader.TestField("Buy-from Address", Vendor.Address);
        PurchaseHeader.TestField("Buy-from Address 2", Vendor."Address 2");
        PurchaseHeader.TestField("Buy-from City", Vendor.City);
        PurchaseHeader.TestField("Buy-from County", Vendor.County);
        PurchaseHeader.TestField("Buy-from Country/Region Code", Vendor."Country/Region Code");
        PurchaseHeader.TestField("Buy-from Contact", Vendor.Contact);
    end;

    local procedure VerifyShipToAddressSyncedFromCompany(var PurchaseHeader: Record "Purchase Header")
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();

        PurchaseHeader.TestField("Ship-to Address", CompanyInformation."Ship-to Address");
        PurchaseHeader.TestField("Ship-to Address 2", CompanyInformation."Ship-to Address 2");
        PurchaseHeader.TestField("Ship-to City", CompanyInformation."Ship-to City");
        PurchaseHeader.TestField("Ship-to County", CompanyInformation."Ship-to County");
        PurchaseHeader.TestField("Ship-to Country/Region Code", CompanyInformation."Ship-to Country/Region Code");
        PurchaseHeader.TestField("Ship-to Phone No.", CompanyInformation."Ship-to Phone No.");
    end;

    local procedure VerifyPayToAddressSyncedFromVendor(var PurchaseHeader: Record "Purchase Header"; Vendor: Record Vendor)
    begin
        PurchaseHeader.TestField("Pay-to Address", Vendor.Address);
        PurchaseHeader.TestField("Pay-to Address 2", Vendor."Address 2");
        PurchaseHeader.TestField("Pay-to City", Vendor.City);
        PurchaseHeader.TestField("Pay-to County", Vendor.County);
        PurchaseHeader.TestField("Pay-to Country/Region Code", Vendor."Country/Region Code");
        PurchaseHeader.TestField("Pay-to Contact", Vendor.Contact);
    end;

    local procedure FindBuyFromVendorPurchaseInvoice(var PurchaseHeader: Record "Purchase Header"; BuyFromVendorNo: Code[20])
    begin
        PurchaseHeader.SetCurrentKey("Document Type", "Buy-from Vendor No.");
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Invoice);
        PurchaseHeader.SetRange("Buy-from Vendor No.", BuyFromVendorNo);
        PurchaseHeader.FindLast();
    end;

    local procedure FindPayToVendorPurchaseInvoice(var PurchaseHeader: Record "Purchase Header"; PayToVendorNo: Code[20])
    begin
        PurchaseHeader.SetCurrentKey("Document Type", "Pay-to Vendor No.");
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Invoice);
        PurchaseHeader.SetRange("Pay-to Vendor No.", PayToVendorNo);
        PurchaseHeader.FindLast();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerWithMessageValidation(Question: Text[1024]; var Reply: Boolean)
    begin
        // Due to a platform bug in ALConfirm, the placehoders in a CONFIRM question do not get replaced.
        // Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(),Question);
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;
}

