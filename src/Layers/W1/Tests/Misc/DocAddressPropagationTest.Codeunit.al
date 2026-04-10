codeunit 134772 "Doc. Address Propagation Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Ship/Pay-To Address]
        IsInitialized := false;
    end;

    var
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryService: Codeunit "Library - Service";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        Assert: Codeunit Assert;
        ServiceDocPropagateFalse_AddressMsg: Label 'Address should not match Ship-to Address';
        ServiceDocPropagateFalse_Address2Msg: Label 'Address 2 should not match Ship-to Address 2';
        ServiceDocPropagateFalse_CityMsg: Label 'City should not match Ship-to City';
        ServiceDocPropagateFalse_PostCodeMsg: Label 'Post Code should not match Ship-to Post Code';
        ServiceDocPropagateFalse_CountyMsg: Label 'County should not match Ship-to County';
        ServiceDocPropagateFalse_CountryRegionMsg: Label 'Country/Region Code should not match Ship-to Country/Region Code';
        IsInitialized: Boolean;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PurchaseDocAddressChangesPropagateWhenValuesEqual()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Changes to Purchase Header Buy-from Address fields should propagate to Pay-to Address fields when the field values are equal
        // [GIVEN] Purchase Header with matching Buy-from address fields and Pay-to address fields
        Initialize();
        PurchaseHeader.DontNotifyCurrentUserAgain(PurchaseHeader.GetModifyVendorAddressNotificationId());
        PurchaseHeader.DontNotifyCurrentUserAgain(PurchaseHeader.GetModifyPayToVendorAddressNotificationId());
        CreateTempVendor(Vendor);
        CreatePurchaseHeaderForVendor(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");

        // [WHEN] Buy-from address fields are changed
        ChangePurchaseHeaderBuyFromAddressFields(PurchaseHeader);

        // [THEN] Changes to Buy-from address fields should propagate to Pay-to address fields
        VerifyBuyFromAddressEqualsPayToAddress(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseDocAddressChangesDoNotPropogateWhenValuesDiffer()
    var
        PurchaseHeader: Record "Purchase Header";
        CountryRegion: Record "Country/Region";
        DeltaCountryRegionCode: Code[10];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Changes to Purchase Header Buy-from Address fields should not propagate to Pay-to Address fields when the field values are not equal
        // [GIVEN] Purchase Header with non-matching Buy-from address fields and Pay-to address fields
        Initialize();
        PurchaseHeader."Pay-to Address" := 'New Pay-to Address';
        PurchaseHeader."Pay-to Address 2" := 'New Pay-to Address2';
        CountryRegion.Next(LibraryRandom.RandInt(CountryRegion.Count));
        PurchaseHeader.Validate("Pay-to Country/Region Code", CountryRegion.Code);
        DeltaCountryRegionCode := CountryRegion.Code;
        PurchaseHeader."Pay-to City" := 'New Pay-to City';
        PurchaseHeader."Pay-to Post Code" := 'New Pay-to Post Code';
        PurchaseHeader."Pay-to County" := 'New Pay-to County';

        // [WHEN] Buy-from address fields are changed
        PurchaseHeader.Validate("Buy-from Address", 'New Address');
        PurchaseHeader.Validate("Buy-from Address 2", 'New Address2');
        CountryRegion.Next(LibraryRandom.RandInt(CountryRegion.Count));
        PurchaseHeader.Validate("Buy-from Country/Region Code", CountryRegion.Code);
        PurchaseHeader.Validate("Buy-from City", 'New City');
        PurchaseHeader.Validate("Buy-from Post Code", 'New Post Code');
        PurchaseHeader.Validate("Buy-from County", 'New County');

        // [THEN] Changes to Buy-from address fields should not propagate to Pay-to address fields
        VerifyPayToAddress(PurchaseHeader, 'New Pay-to Address', 'New Pay-to Address2', 'New Pay-to City',
          UpperCase('New Pay-to Post Code'), 'New Pay-to County', DeltaCountryRegionCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseDocAddressChangesDoNotPropogateWhenAddressDiffer()
    var
        PurchaseHeader: Record "Purchase Header";
        DeltaCountryRegionCode: Code[10];
        DeltaPayToAddress2: Text[50];
        DeltaPayToCity: Text[30];
        DeltaPayToPostCode: Text[20];
        DeltaPayToCounty: Text[30];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Changes to Purchase Header Buy-from Address fields should not propagate to Pay-to Address fields when the field values are not equal
        // [GIVEN] Purchase Header with non-matching Buy-from address fields and Pay-to address fields
        Initialize();
        PurchaseHeader."Pay-to Address" := 'New Pay-to Address';

        DeltaPayToAddress2 := PurchaseHeader."Pay-to Address 2";
        DeltaPayToCity := PurchaseHeader."Pay-to City";
        DeltaPayToPostCode := PurchaseHeader."Pay-to Post Code";
        DeltaPayToCounty := PurchaseHeader."Pay-to County";
        DeltaCountryRegionCode := PurchaseHeader."Pay-to Country/Region Code";

        // [WHEN] Buy-from address fields are changed
        ChangePurchaseHeaderBuyFromAddressFields(PurchaseHeader);

        // [THEN] Changes to Buy-from address fields should not propagate to Pay-to address fields
        VerifyPayToAddress(PurchaseHeader,
          'New Pay-to Address', DeltaPayToAddress2, DeltaPayToCity, DeltaPayToPostCode, DeltaPayToCounty, DeltaCountryRegionCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseDocAddressChangesDoNotPropogateWhenAddress2Differ()
    var
        PurchaseHeader: Record "Purchase Header";
        DeltaCountryRegionCode: Code[10];
        DeltaPayToAddress: Text[100];
        DeltaPayToCity: Text[30];
        DeltaPayToPostCode: Text[20];
        DeltaPayToCounty: Text[30];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Changes to Purchase Header Buy-from Address fields should not propagate to Pay-to Address fields when the field values are not equal
        // [GIVEN] Purchase Header with non-matching Buy-from address fields and Pay-to address fields
        Initialize();
        PurchaseHeader."Pay-to Address 2" := 'New Pay-to Address2';

        DeltaPayToAddress := PurchaseHeader."Pay-to Address";
        DeltaPayToCity := PurchaseHeader."Pay-to City";
        DeltaPayToPostCode := PurchaseHeader."Pay-to Post Code";
        DeltaPayToCounty := PurchaseHeader."Pay-to County";
        DeltaCountryRegionCode := PurchaseHeader."Pay-to Country/Region Code";

        // [WHEN] Buy-from address fields are changed
        ChangePurchaseHeaderBuyFromAddressFields(PurchaseHeader);

        // [THEN] Changes to Buy-from address fields should not propagate to Pay-to address fields
        VerifyPayToAddress(PurchaseHeader,
          DeltaPayToAddress, 'New Pay-to Address2', DeltaPayToCity, DeltaPayToPostCode, DeltaPayToCounty, DeltaCountryRegionCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseDocAddressChangesDoNotPropogateWhenCityDiffer()
    var
        PurchaseHeader: Record "Purchase Header";
        DeltaCountryRegionCode: Code[10];
        DeltaPayToAddress2: Text[50];
        DeltaPayToAddress: Text[100];
        DeltaPayToPostCode: Text[20];
        DeltaPayToCounty: Text[30];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Changes to Purchase Header Buy-from Address fields should not propagate to Pay-to Address fields when the field values are not equal
        // [GIVEN] Purchase Header with non-matching Buy-from address fields and Pay-to address fields
        Initialize();
        PurchaseHeader."Pay-to City" := 'New Pay-to City';

        DeltaPayToAddress := PurchaseHeader."Pay-to Address";
        DeltaPayToAddress2 := PurchaseHeader."Pay-to Address 2";
        DeltaPayToPostCode := PurchaseHeader."Pay-to Post Code";
        DeltaPayToCounty := PurchaseHeader."Pay-to County";
        DeltaCountryRegionCode := PurchaseHeader."Pay-to Country/Region Code";

        // [WHEN] Buy-from address fields are changed
        ChangePurchaseHeaderBuyFromAddressFields(PurchaseHeader);

        // [THEN] Changes to Buy-from address fields should not propagate to Pay-to address fields
        VerifyPayToAddress(PurchaseHeader,
          DeltaPayToAddress, DeltaPayToAddress2, 'New Pay-to City', DeltaPayToPostCode, DeltaPayToCounty, DeltaCountryRegionCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseDocAddressChangesDoNotPropogateWhenPostCodeDiffer()
    var
        PurchaseHeader: Record "Purchase Header";
        DeltaCountryRegionCode: Code[10];
        DeltaPayToAddress2: Text[50];
        DeltaPayToCity: Text[30];
        DeltaPayToAddress: Text[100];
        DeltaPayToCounty: Text[30];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Changes to Purchase Header Buy-from Address fields should not propagate to Pay-to Address fields when the field values are not equal
        // [GIVEN] Purchase Header with non-matching Buy-from address fields and Pay-to address fields
        Initialize();
        PurchaseHeader."Pay-to Post Code" := 'New Pay-to Post Code';

        DeltaPayToAddress := PurchaseHeader."Pay-to Address";
        DeltaPayToAddress2 := PurchaseHeader."Pay-to Address 2";
        DeltaPayToCity := PurchaseHeader."Pay-to City";
        DeltaPayToCounty := PurchaseHeader."Pay-to County";
        DeltaCountryRegionCode := PurchaseHeader."Pay-to Country/Region Code";

        // [WHEN] Buy-from address fields are changed
        ChangePurchaseHeaderBuyFromAddressFields(PurchaseHeader);

        // [THEN] Changes to Buy-from address fields should not propagate to Pay-to address fields
        VerifyPayToAddress(PurchaseHeader,
          DeltaPayToAddress, DeltaPayToAddress2, DeltaPayToCity,
          UpperCase('New Pay-to Post Code'), DeltaPayToCounty, DeltaCountryRegionCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseDocAddressChangesDoNotPropogateWhenCountyDiffer()
    var
        PurchaseHeader: Record "Purchase Header";
        DeltaCountryRegionCode: Code[10];
        DeltaPayToAddress2: Text[50];
        DeltaPayToCity: Text[30];
        DeltaPayToPostCode: Text[20];
        DeltaPayToAddress: Text[100];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Changes to Purchase Header Buy-from Address fields should not propagate to Pay-to Address fields when the field values are not equal
        // [GIVEN] Purchase Header with non-matching Buy-from address fields and Pay-to address fields
        Initialize();
        PurchaseHeader."Pay-to County" := 'New Pay-to County';

        DeltaPayToAddress := PurchaseHeader."Pay-to Address";
        DeltaPayToAddress2 := PurchaseHeader."Pay-to Address 2";
        DeltaPayToCity := PurchaseHeader."Pay-to City";
        DeltaPayToPostCode := PurchaseHeader."Pay-to Post Code";
        DeltaCountryRegionCode := PurchaseHeader."Pay-to Country/Region Code";

        // [WHEN] Buy-from address fields are changed
        ChangePurchaseHeaderBuyFromAddressFields(PurchaseHeader);

        // [THEN] Changes to Buy-from address fields should not propagate to Pay-to address fields
        VerifyPayToAddress(PurchaseHeader,
          DeltaPayToAddress, DeltaPayToAddress2, DeltaPayToCity, DeltaPayToPostCode, 'New Pay-to County', DeltaCountryRegionCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseDocAddressChangesDoNotPropogateWhenCountryRegionDiffer()
    var
        PurchaseHeader: Record "Purchase Header";
        CountryRegion: Record "Country/Region";
        DeltaCountryRegionCode: Code[10];
        DeltaPayToAddress2: Text[50];
        DeltaPayToCity: Text[30];
        DeltaPayToPostCode: Text[20];
        DeltaPayToCounty: Text[30];
        DeltaPayToAddress: Text[100];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Changes to Purchase Header Buy-from Address fields should not propagate to Pay-to Address fields when the field values are not equal
        // [GIVEN] Purchase Header with non-matching Buy-from address fields and Pay-to address fields
        Initialize();
        CountryRegion.Next(LibraryRandom.RandInt(CountryRegion.Count));
        PurchaseHeader.Validate("Pay-to Country/Region Code", CountryRegion.Code);
        DeltaCountryRegionCode := CountryRegion.Code;

        DeltaPayToAddress := PurchaseHeader."Pay-to Address";
        DeltaPayToAddress2 := PurchaseHeader."Pay-to Address 2";
        DeltaPayToCity := PurchaseHeader."Pay-to City";
        DeltaPayToPostCode := PurchaseHeader."Pay-to Post Code";
        DeltaPayToCounty := PurchaseHeader."Pay-to County";

        // [WHEN] Buy-from address fields are changed
        ChangePurchaseHeaderBuyFromAddressFields(PurchaseHeader);

        // [THEN] Changes to Buy-from address fields should not propagate to Pay-to address fields
        VerifyPayToAddress(PurchaseHeader,
          DeltaPayToAddress, DeltaPayToAddress2, DeltaPayToCity, DeltaPayToPostCode, DeltaPayToCounty, DeltaCountryRegionCode);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SalesDocAddressChangesPropagateWhenValuesEqual()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Changes to Sales Header Sell-to Address fields should propagate to Ship-to Address fields when the field values are equal
        // [GIVEN] Sales Header with matching Sell-to address fields and Ship-to address fields
        Initialize();
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyCustomerAddressNotificationId());
        CreateTempCustomer(Customer);
        CreateSalesHeaderForCustomer(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");

        // [WHEN] Sell-to address fields are changed
        ChangeSalesHeaderSellToAddressFields(SalesHeader);

        // [THEN] Changes to Sell-to address fields should propagate to Ship-to address fields
        VerifySellToAddressEqualsShipToAddress(SalesHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesDocAddressChangesDoNotPropagateWhenValuesDiffer()
    var
        SalesHeader: Record "Sales Header";
        CountryRegion: Record "Country/Region";
        DeltaCountryRegionCode: Code[10];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Changes to Sales Header Sell-to Address fields should not propagate to Ship-to Address fields when the field values are not equal
        // [GIVEN] Sales Header with non-matching Sell-to address fields and Ship-to address fields
        Initialize();
        SalesHeader."Ship-to Address" := 'New Sell-to Address';
        SalesHeader."Ship-to Address 2" := 'New Sell-to Address2';
        SalesHeader."Ship-to City" := 'New Sell-to City';
        SalesHeader."Ship-to Post Code" := 'New Ship-to PostCode';
        SalesHeader."Ship-to County" := 'New Pay-to County';
        CountryRegion.Next(LibraryRandom.RandInt(CountryRegion.Count));
        SalesHeader.Validate("Ship-to Country/Region Code", CountryRegion.Code);
        DeltaCountryRegionCode := CountryRegion.Code;

        // [WHEN] Sell-to address fields are changed
        ChangeSalesHeaderSellToAddressFields(SalesHeader);

        // [THEN] Changes to Sell-to address fields should not propagate to Ship-to address fields
        VerifySalesDocumentShipToAddress(SalesHeader,
          'New Sell-to Address', 'New Sell-to Address2', 'New Sell-to City',
          UpperCase('New Ship-to PostCode'), 'New Pay-to County', DeltaCountryRegionCode);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SalesDocAddressChangesDoNotPropagateWhenShipToCodeIsSet()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        ShipToAddress: Record "Ship-to Address";
        DeltaCountryRegionCode: Code[10];
        DeltaShipToAddress: Text[100];
        DeltaShipToAddress2: Text[50];
        DeltaShipToCity: Text[30];
        DeltaShipToPostCode: Text[20];
        DeltaShipToCounty: Text[30];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Changes to Sales Header Sell-to Address fields should not propagate to Ship-to Address fields when "Ship-to Code" is set
        // [GIVEN] Sales Header with "Ship-to Code" set
        Initialize();
        CreateTempCustomer(Customer);
        CreateSalesHeaderForCustomer(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateShipToAddress(ShipToAddress, Customer."No.");
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyCustomerAddressNotificationId());
        ShipToAddress.Address := SalesHeader."Sell-to Address";
        DeltaShipToAddress := ShipToAddress.Address;
        ShipToAddress."Address 2" := SalesHeader."Sell-to Address 2";
        DeltaShipToAddress2 := ShipToAddress."Address 2";
        ShipToAddress.City := SalesHeader."Sell-to City";
        DeltaShipToCity := ShipToAddress.City;
        ShipToAddress."Post Code" := SalesHeader."Sell-to Post Code";
        DeltaShipToPostCode := ShipToAddress."Post Code";
        ShipToAddress.County := SalesHeader."Sell-to County";
        DeltaShipToCounty := ShipToAddress.County;
        ShipToAddress."Country/Region Code" := SalesHeader."Ship-to Country/Region Code";
        DeltaCountryRegionCode := ShipToAddress."Country/Region Code";
        ShipToAddress.Modify(true);
        SalesHeader."Ship-to Code" := ShipToAddress.Code;
        SalesHeader.Modify(true);

        // [WHEN] Sell-to address fields are changed
        ChangeSalesHeaderSellToAddressFields(SalesHeader);

        // [THEN] Changes to Sell-to address fields should not propagate to Ship-to address fields
        VerifySalesDocumentShipToAddress(SalesHeader,
          DeltaShipToAddress, DeltaShipToAddress2, DeltaShipToCity, DeltaShipToPostCode, DeltaShipToCounty, DeltaCountryRegionCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesDocAddressChangesDoNotPropagateWhenAddressDiffer()
    var
        SalesHeader: Record "Sales Header";
        DeltaCountryRegionCode: Code[10];
        DeltaShipToAddress2: Text[50];
        DeltaShipToCity: Text[30];
        DeltaShipToPostCode: Text[20];
        DeltaShipToCounty: Text[30];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Changes to Sales Header Sell-to Address fields should not propagate to Ship-to Address fields when the field values are not equal
        // [GIVEN] Sales Header with non-matching Sell-to address fields and Ship-to address fields
        Initialize();
        SalesHeader."Ship-to Address" := 'New Ship-to Address';

        DeltaShipToAddress2 := SalesHeader."Ship-to Address 2";
        DeltaShipToCity := SalesHeader."Ship-to City";
        DeltaShipToPostCode := SalesHeader."Ship-to Post Code";
        DeltaShipToCounty := SalesHeader."Ship-to County";
        DeltaCountryRegionCode := SalesHeader."Ship-to Country/Region Code";

        // [WHEN] Sell-to address fields are changed
        ChangeSalesHeaderSellToAddressFields(SalesHeader);

        // [THEN] Changes to Sell-to address fields should not propagate to Ship-to address fields
        VerifySalesDocumentShipToAddress(SalesHeader,
          'New Ship-to Address', DeltaShipToAddress2, DeltaShipToCity, DeltaShipToPostCode, DeltaShipToCounty, DeltaCountryRegionCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesDocAddressChangesDoNotPropagateWhenAddress2Differ()
    var
        SalesHeader: Record "Sales Header";
        DeltaCountryRegionCode: Code[10];
        DeltaShipToAddress: Text[100];
        DeltaShipToCity: Text[30];
        DeltaShipToPostCode: Text[20];
        DeltaShipToCounty: Text[30];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Changes to Sales Header Sell-to Address fields should not propagate to Ship-to Address fields when the field values are not equal
        // [GIVEN] Sales Header with non-matching Sell-to address fields and Ship-to address fields
        Initialize();
        SalesHeader."Ship-to Address 2" := 'New Ship-to Address2';

        DeltaShipToAddress := SalesHeader."Ship-to Address";
        DeltaShipToCity := SalesHeader."Ship-to City";
        DeltaShipToPostCode := SalesHeader."Ship-to Post Code";
        DeltaShipToCounty := SalesHeader."Ship-to County";
        DeltaCountryRegionCode := SalesHeader."Ship-to Country/Region Code";

        // [WHEN] Sell-to address fields are changed
        ChangeSalesHeaderSellToAddressFields(SalesHeader);

        // [THEN] Changes to Sell-to address fields should not propagate to Ship-to address fields
        VerifySalesDocumentShipToAddress(SalesHeader,
          DeltaShipToAddress, 'New Ship-to Address2', DeltaShipToCity, DeltaShipToPostCode, DeltaShipToCounty, DeltaCountryRegionCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesDocAddressChangesDoNotPropagateWhenCityDiffer()
    var
        SalesHeader: Record "Sales Header";
        DeltaCountryRegionCode: Code[10];
        DeltaShipToAddress: Text[100];
        DeltaShipToAddress2: Text[50];
        DeltaShipToPostCode: Text[20];
        DeltaShipToCounty: Text[30];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Changes to Sales Header Sell-to Address fields should not propagate to Ship-to Address fields when the field values are not equal
        // [GIVEN] Sales Header with non-matching Sell-to address fields and Ship-to address fields
        Initialize();
        SalesHeader."Ship-to City" := 'New Ship-to City';

        DeltaShipToAddress := SalesHeader."Ship-to Address";
        DeltaShipToAddress2 := SalesHeader."Ship-to Address 2";
        DeltaShipToPostCode := SalesHeader."Ship-to Post Code";
        DeltaShipToCounty := SalesHeader."Ship-to County";
        DeltaCountryRegionCode := SalesHeader."Ship-to Country/Region Code";

        // [WHEN] Sell-to address fields are changed
        ChangeSalesHeaderSellToAddressFields(SalesHeader);

        // [THEN] Changes to Sell-to address fields should not propagate to Ship-to address fields
        VerifySalesDocumentShipToAddress(SalesHeader,
          DeltaShipToAddress, DeltaShipToAddress2, 'New Ship-to City', DeltaShipToPostCode, DeltaShipToCounty, DeltaCountryRegionCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesDocAddressChangesDoNotPropagateWhenPostCodeDiffer()
    var
        SalesHeader: Record "Sales Header";
        DeltaCountryRegionCode: Code[10];
        DeltaShipToAddress: Text[100];
        DeltaShipToAddress2: Text[50];
        DeltaShipToCity: Text[30];
        DeltaShipToCounty: Text[30];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Changes to Sales Header Sell-to Address fields should not propagate to Ship-to Address fields when the field values are not equal
        // [GIVEN] Sales Header with non-matching Sell-to address fields and Ship-to address fields
        Initialize();
        SalesHeader."Ship-to Post Code" := 'New Ship-to PostCode';

        DeltaShipToAddress := SalesHeader."Ship-to Address";
        DeltaShipToAddress2 := SalesHeader."Ship-to Address 2";
        DeltaShipToCity := SalesHeader."Ship-to City";
        DeltaShipToCounty := SalesHeader."Ship-to County";
        DeltaCountryRegionCode := SalesHeader."Ship-to Country/Region Code";

        // [WHEN] Sell-to address fields are changed
        ChangeSalesHeaderSellToAddressFields(SalesHeader);

        // [THEN] Changes to Sell-to address fields should not propagate to Ship-to address fields
        VerifySalesDocumentShipToAddress(SalesHeader,
          DeltaShipToAddress, DeltaShipToAddress2, DeltaShipToCity,
          UpperCase('New Ship-to PostCode'), DeltaShipToCounty, DeltaCountryRegionCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesDocAddressChangesDoNotPropagateWhenCountyDiffer()
    var
        SalesHeader: Record "Sales Header";
        DeltaCountryRegionCode: Code[10];
        DeltaShipToAddress: Text[100];
        DeltaShipToAddress2: Text[50];
        DeltaShipToCity: Text[30];
        DeltaShipToPostCode: Text[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Changes to Sales Header Sell-to Address fields should not propagate to Ship-to Address fields when the field values are not equal
        // [GIVEN] Sales Header with non-matching Sell-to address fields and Ship-to address fields
        Initialize();
        SalesHeader."Ship-to County" := 'New Ship-to County';

        DeltaShipToAddress := SalesHeader."Ship-to Address";
        DeltaShipToAddress2 := SalesHeader."Ship-to Address 2";
        DeltaShipToCity := SalesHeader."Ship-to City";
        DeltaShipToPostCode := SalesHeader."Ship-to Post Code";
        DeltaCountryRegionCode := SalesHeader."Ship-to Country/Region Code";

        // [WHEN] Sell-to address fields are changed
        ChangeSalesHeaderSellToAddressFields(SalesHeader);

        // [THEN] Changes to Sell-to address fields should not propagate to Ship-to address fields
        VerifySalesDocumentShipToAddress(SalesHeader,
          DeltaShipToAddress, DeltaShipToAddress2, DeltaShipToCity, DeltaShipToPostCode, 'New Ship-to County', DeltaCountryRegionCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesDocAddressChangesDoNotPropagateWhenCountryRegionDiffer()
    var
        SalesHeader: Record "Sales Header";
        CountryRegion: Record "Country/Region";
        DeltaCountryRegionCode: Code[10];
        DeltaShipToAddress: Text[100];
        DeltaShipToAddress2: Text[50];
        DeltaShipToCity: Text[30];
        DeltaShipToPostCode: Text[20];
        DeltaShipToCounty: Text[30];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Changes to Sales Header Sell-to Address fields should not propagate to Ship-to Address fields when the field values are not equal
        // [GIVEN] Sales Header with non-matching Sell-to address fields and Ship-to address fields
        Initialize();
        CountryRegion.Next(LibraryRandom.RandInt(CountryRegion.Count));
        SalesHeader.Validate("Ship-to Country/Region Code", CountryRegion.Code);
        DeltaCountryRegionCode := CountryRegion.Code;

        DeltaShipToAddress := SalesHeader."Ship-to Address";
        DeltaShipToAddress2 := SalesHeader."Ship-to Address 2";
        DeltaShipToCity := SalesHeader."Ship-to City";
        DeltaShipToPostCode := SalesHeader."Ship-to Post Code";
        DeltaShipToCounty := SalesHeader."Ship-to County";
        DeltaCountryRegionCode := SalesHeader."Ship-to Country/Region Code";

        // [WHEN] Sell-to address fields are changed
        ChangeSalesHeaderSellToAddressFields(SalesHeader);

        // [THEN] Changes to Sell-to address fields should not propagate to Ship-to address fields
        VerifySalesDocumentShipToAddress(SalesHeader,
          DeltaShipToAddress, DeltaShipToAddress2, DeltaShipToCity, DeltaShipToPostCode, DeltaShipToCounty, DeltaCountryRegionCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceDocAddressChangesPropagateWhenValuesEqual()
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
    begin
        // [FEATURE] [Service]
        // [SCENARIO] Changes to Service Header Address fields should propagate to Ship-to Address fields when the field values are equal
        // [GIVEN] Service Header with matching address fields and Ship-to address fields
        Initialize();
        CreateTempCustomer(Customer);
        CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");

        // [WHEN] address fields are changed
        ChangeServiceHeaderAddressFields(ServiceHeader);

        // [THEN] Changes to address fields should propagate to Ship-to address fields
        VerifyAddressEqualsShipToAddress(ServiceHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceDocAddressChangesDoNotPropagateWhenValuesDiffer()
    var
        ServiceHeader: Record "Service Header";
        CountryRegion: Record "Country/Region";
    begin
        // [FEATURE] [Service]
        // [SCENARIO] Changes to Service Order General Address fields should not propagate to Ship-to Address fields when the field values are not equal
        // [GIVEN] Service Order with non-matching general address fields and Ship-to address fields
        Initialize();
        ServiceHeader."Ship-to Address" := 'New Ship-to Address';
        ServiceHeader."Ship-to Address 2" := 'New Ship-to Address2';
        ServiceHeader."Ship-to City" := 'New Ship-to City';
        ServiceHeader."Ship-to Post Code" := 'New Ship-to PostCode';
        ServiceHeader."Ship-to County" := 'New Pay-to County';
        CountryRegion.Next(LibraryRandom.RandInt(CountryRegion.Count));
        ServiceHeader.Validate("Ship-to Country/Region Code", CountryRegion.Code);

        // [WHEN] general address fields are changed
        ChangeServiceHeaderAddressFields(ServiceHeader);

        // [THEN] Changes to general address fields should not propagate to Ship-to address fields
        Assert.AreNotEqual(ServiceHeader.Address, ServiceHeader."Ship-to Address", ServiceDocPropagateFalse_AddressMsg);
        Assert.AreNotEqual(ServiceHeader."Address 2", ServiceHeader."Ship-to Address 2", ServiceDocPropagateFalse_Address2Msg);
        Assert.AreNotEqual(ServiceHeader.City, ServiceHeader."Ship-to City", ServiceDocPropagateFalse_CityMsg);
        Assert.AreNotEqual(ServiceHeader."Post Code", ServiceHeader."Ship-to Post Code", ServiceDocPropagateFalse_PostCodeMsg);
        Assert.AreNotEqual(ServiceHeader.County, ServiceHeader."Ship-to County", ServiceDocPropagateFalse_CountyMsg);
        Assert.AreNotEqual(ServiceHeader."Country/Region Code", ServiceHeader."Ship-to Country/Region Code",
          ServiceDocPropagateFalse_CountryRegionMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceDocAddressChangesDoNotPropagateWhenShipToCodeIsSet()
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        ShipToAddress: Record "Ship-to Address";
        DeltaCountryRegionCode: Code[10];
        DeltaShipToAddress: Text[100];
        DeltaShipToAddress2: Text[50];
        DeltaShipToCity: Text[30];
        DeltaShipToPostCode: Text[20];
        DeltaShipToCounty: Text[30];
    begin
        // [FEATURE] [Service]
        // [SCENARIO] Changes to Service Header General Address fields should not propagate to Ship-to Address fields when "Ship-to Code" is set
        // [GIVEN] Service Header with "Ship-to Code" set
        Initialize();
        CreateTempCustomer(Customer);
        CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateShipToAddress(ShipToAddress, Customer."No.");
        ShipToAddress.Address := ServiceHeader.Address;
        DeltaShipToAddress := ShipToAddress.Address;
        ShipToAddress."Address 2" := ServiceHeader."Address 2";
        DeltaShipToAddress2 := ShipToAddress."Address 2";
        ShipToAddress.City := ServiceHeader.City;
        DeltaShipToCity := ShipToAddress.City;
        ShipToAddress."Post Code" := ServiceHeader."Post Code";
        DeltaShipToPostCode := ShipToAddress."Post Code";
        ShipToAddress.County := ServiceHeader.County;
        DeltaShipToCounty := ShipToAddress.County;
        ShipToAddress."Country/Region Code" := ServiceHeader."Country/Region Code";
        DeltaCountryRegionCode := ShipToAddress."Country/Region Code";
        ShipToAddress.Modify(true);
        ServiceHeader."Ship-to Code" := ShipToAddress.Code;
        ServiceHeader.Modify(true);

        // [WHEN] general address fields are changed
        ChangeServiceHeaderAddressFields(ServiceHeader);

        // [THEN] Changes to general address fields should not propagate to Ship-to address fields
        VerifyServiceDocumentShipToAddress(ServiceHeader,
          DeltaShipToAddress, DeltaShipToAddress2, DeltaShipToCity, DeltaShipToPostCode, DeltaShipToCounty, DeltaCountryRegionCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceDocAddressChangesDoNotPropagateWhenAddressDiffer()
    var
        ServiceHeader: Record "Service Header";
        DeltaCountryRegionCode: Code[10];
        DeltaShipToAddress2: Text[50];
        DeltaShipToCity: Text[30];
        DeltaShipToPostCode: Text[20];
        DeltaShipToCounty: Text[30];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Changes to Sales Header Sell-to Address fields should not propagate to Ship-to Address fields when the field values are not equal
        // [GIVEN] Sales Header with non-matching Sell-to address fields and Ship-to address fields
        Initialize();
        ServiceHeader."Ship-to Address" := 'New Ship-to Address';

        DeltaShipToAddress2 := ServiceHeader."Ship-to Address 2";
        DeltaShipToCity := ServiceHeader."Ship-to City";
        DeltaShipToPostCode := ServiceHeader."Ship-to Post Code";
        DeltaShipToCounty := ServiceHeader."Ship-to County";
        DeltaCountryRegionCode := ServiceHeader."Ship-to Country/Region Code";

        // [WHEN] Sell-to address fields are changed
        ChangeServiceHeaderAddressFields(ServiceHeader);

        // [THEN] Changes to Sell-to address fields should not propagate to Ship-to address fields
        VerifyServiceDocumentShipToAddress(ServiceHeader,
          'New Ship-to Address', DeltaShipToAddress2, DeltaShipToCity, DeltaShipToPostCode, DeltaShipToCounty, DeltaCountryRegionCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceDocAddressChangesDoNotPropagateWhenAddress2Differ()
    var
        ServiceHeader: Record "Service Header";
        DeltaCountryRegionCode: Code[10];
        DeltaShipToAddress: Text[100];
        DeltaShipToCity: Text[30];
        DeltaShipToPostCode: Text[20];
        DeltaShipToCounty: Text[30];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Changes to Sales Header Sell-to Address fields should not propagate to Ship-to Address fields when the field values are not equal
        // [GIVEN] Sales Header with non-matching Sell-to address fields and Ship-to address fields
        Initialize();
        ServiceHeader."Ship-to Address 2" := 'New Ship-to Address2';

        DeltaShipToAddress := ServiceHeader."Ship-to Address";
        DeltaShipToCity := ServiceHeader."Ship-to City";
        DeltaShipToPostCode := ServiceHeader."Ship-to Post Code";
        DeltaShipToCounty := ServiceHeader."Ship-to County";
        DeltaCountryRegionCode := ServiceHeader."Ship-to Country/Region Code";

        // [WHEN] Sell-to address fields are changed
        ChangeServiceHeaderAddressFields(ServiceHeader);

        // [THEN] Changes to Sell-to address fields should not propagate to Ship-to address fields
        VerifyServiceDocumentShipToAddress(ServiceHeader,
          DeltaShipToAddress, 'New Ship-to Address2', DeltaShipToCity, DeltaShipToPostCode, DeltaShipToCounty, DeltaCountryRegionCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceDocAddressChangesDoNotPropagateWhenCityDiffer()
    var
        ServiceHeader: Record "Service Header";
        DeltaCountryRegionCode: Code[10];
        DeltaShipToAddress: Text[100];
        DeltaShipToAddress2: Text[50];
        DeltaShipToPostCode: Text[20];
        DeltaShipToCounty: Text[30];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Changes to Sales Header Sell-to Address fields should not propagate to Ship-to Address fields when the field values are not equal
        // [GIVEN] Sales Header with non-matching Sell-to address fields and Ship-to address fields
        Initialize();
        ServiceHeader."Ship-to City" := 'New Ship-to City';

        DeltaShipToAddress := ServiceHeader."Ship-to Address";
        DeltaShipToAddress2 := ServiceHeader."Ship-to Address 2";
        DeltaShipToPostCode := ServiceHeader."Ship-to Post Code";
        DeltaShipToCounty := ServiceHeader."Ship-to County";
        DeltaCountryRegionCode := ServiceHeader."Ship-to Country/Region Code";

        // [WHEN] Sell-to address fields are changed
        ChangeServiceHeaderAddressFields(ServiceHeader);

        // [THEN] Changes to Sell-to address fields should not propagate to Ship-to address fields
        VerifyServiceDocumentShipToAddress(ServiceHeader,
          DeltaShipToAddress, DeltaShipToAddress2, 'New Ship-to City', DeltaShipToPostCode, DeltaShipToCounty, DeltaCountryRegionCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceDocAddressChangesDoNotPropagateWhenPostCodeDiffer()
    var
        ServiceHeader: Record "Service Header";
        DeltaCountryRegionCode: Code[10];
        DeltaShipToAddress: Text[100];
        DeltaShipToAddress2: Text[50];
        DeltaShipToCity: Text[30];
        DeltaShipToCounty: Text[30];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Changes to Sales Header Sell-to Address fields should not propagate to Ship-to Address fields when the field values are not equal
        // [GIVEN] Sales Header with non-matching Sell-to address fields and Ship-to address fields
        Initialize();
        ServiceHeader."Ship-to Post Code" := 'New Ship-to PostCode';

        DeltaShipToAddress := ServiceHeader."Ship-to Address";
        DeltaShipToAddress2 := ServiceHeader."Ship-to Address 2";
        DeltaShipToCity := ServiceHeader."Ship-to City";
        DeltaShipToCounty := ServiceHeader."Ship-to County";
        DeltaCountryRegionCode := ServiceHeader."Ship-to Country/Region Code";

        // [WHEN] Sell-to address fields are changed
        ChangeServiceHeaderAddressFields(ServiceHeader);

        // [THEN] Changes to Sell-to address fields should not propagate to Ship-to address fields
        VerifyServiceDocumentShipToAddress(ServiceHeader,
          DeltaShipToAddress, DeltaShipToAddress2, DeltaShipToCity,
          UpperCase('New Ship-to PostCode'), DeltaShipToCounty, DeltaCountryRegionCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceDocAddressChangesDoNotPropagateWhenCountyDiffer()
    var
        ServiceHeader: Record "Service Header";
        DeltaCountryRegionCode: Code[10];
        DeltaShipToAddress: Text[100];
        DeltaShipToAddress2: Text[50];
        DeltaShipToCity: Text[30];
        DeltaShipToPostCode: Text[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Changes to Sales Header Sell-to Address fields should not propagate to Ship-to Address fields when the field values are not equal
        // [GIVEN] Sales Header with non-matching Sell-to address fields and Ship-to address fields
        Initialize();
        ServiceHeader."Ship-to County" := 'New Ship-to County';

        DeltaShipToAddress := ServiceHeader."Ship-to Address";
        DeltaShipToAddress2 := ServiceHeader."Ship-to Address 2";
        DeltaShipToCity := ServiceHeader."Ship-to City";
        DeltaShipToPostCode := ServiceHeader."Ship-to Post Code";
        DeltaCountryRegionCode := ServiceHeader."Ship-to Country/Region Code";

        // [WHEN] Sell-to address fields are changed
        ChangeServiceHeaderAddressFields(ServiceHeader);

        // [THEN] Changes to Sell-to address fields should not propagate to Ship-to address fields
        VerifyServiceDocumentShipToAddress(ServiceHeader,
          DeltaShipToAddress, DeltaShipToAddress2, DeltaShipToCity, DeltaShipToPostCode, 'New Ship-to County', DeltaCountryRegionCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceDocAddressChangesDoNotPropagateWhenCountryRegionDiffer()
    var
        ServiceHeader: Record "Service Header";
        CountryRegion: Record "Country/Region";
        DeltaCountryRegionCode: Code[10];
        DeltaShipToAddress: Text[100];
        DeltaShipToAddress2: Text[50];
        DeltaShipToCity: Text[30];
        DeltaShipToPostCode: Text[20];
        DeltaShipToCounty: Text[30];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Changes to Sales Header Sell-to Address fields should not propagate to Ship-to Address fields when the field values are not equal
        // [GIVEN] Sales Header with non-matching Sell-to address fields and Ship-to address fields
        Initialize();
        CountryRegion.Next(LibraryRandom.RandInt(CountryRegion.Count));
        ServiceHeader.Validate("Ship-to Country/Region Code", CountryRegion.Code);
        DeltaCountryRegionCode := CountryRegion.Code;

        DeltaShipToAddress := ServiceHeader."Ship-to Address";
        DeltaShipToAddress2 := ServiceHeader."Ship-to Address 2";
        DeltaShipToCity := ServiceHeader."Ship-to City";
        DeltaShipToPostCode := ServiceHeader."Ship-to Post Code";
        DeltaShipToCounty := ServiceHeader."Ship-to County";
        DeltaCountryRegionCode := ServiceHeader."Ship-to Country/Region Code";

        // [WHEN] Sell-to address fields are changed
        ChangeServiceHeaderAddressFields(ServiceHeader);

        // [THEN] Changes to Sell-to address fields should not propagate to Ship-to address fields
        VerifyServiceDocumentShipToAddress(ServiceHeader,
          DeltaShipToAddress, DeltaShipToAddress2, DeltaShipToCity, DeltaShipToPostCode, DeltaShipToCounty, DeltaCountryRegionCode);
    end;

    [Test]
    [HandlerFunctions('ModifyCustomerAddressNotificationHandler,ConfirmAddressHandler,ModifyBillToCustomerAddressRecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure SalesDocAddressChangesPropagateToCustomerAddressOnNotification()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        DocumentNotifications: Codeunit "Document Notifications";
        Notification: Notification;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Changes to Sales Header Sell-to Address fields should propagate to Customer Address fields when the Notification action is pressed
        Initialize();
        CreateTempCustomer(Customer);
        CreateSalesHeaderForCustomer(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");

        ChangeSalesHeaderSellToAddressFields(SalesHeader);
        SalesHeader.Modify(true);

        Notification.SetData(SalesHeader.FieldName("Sell-to Customer No."), SalesHeader."Sell-to Customer No.");
        Notification.SetData(SalesHeader.FieldName("Document Type"), Format(SalesHeader."Document Type"));
        Notification.SetData(SalesHeader.FieldName("No."), SalesHeader."No.");
        DocumentNotifications.CopySellToCustomerAddressFieldsFromSalesDocument(Notification);

        VerifySellToAddressEqualsCustomerAddress(SalesHeader, Customer."No.");

        LibraryNotificationMgt.RecallNotificationsForRecord(SalesHeader);
    end;

    [Test]
    [HandlerFunctions('HandleConfirm,ModifyBillToCustomerAddressRecallNotificationHandler,ModifyBillToCustomerAddressNotificationHandler,ConfirmAddressHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SalesDocBillToAddressChangesPropagateToCustomerAddressOnNotification()
    var
        Customer: Record Customer;
        BillToCustomer: Record Customer;
        SalesHeader: Record "Sales Header";
        DocumentNotifications: Codeunit "Document Notifications";
        Notification: Notification;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Changes to Sales Header Bill-to Address fields should propagate to Customer Address fields when the Notification action is pressed
        Initialize();
        CreateTempCustomer(Customer);
        CreateSalesHeaderForCustomer(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");

        CreateTempCustomer(BillToCustomer);
        SalesHeader.Validate("Bill-to Customer No.", BillToCustomer."No.");
        ChangeSalesHeaderBillToAddressFields(SalesHeader);
        SalesHeader.Modify(true);

        Notification.SetData(SalesHeader.FieldName("Bill-to Customer No."), SalesHeader."Bill-to Customer No.");
        Notification.SetData(SalesHeader.FieldName("Document Type"), Format(SalesHeader."Document Type"));
        Notification.SetData(SalesHeader.FieldName("No."), SalesHeader."No.");
        DocumentNotifications.CopyBillToCustomerAddressFieldsFromSalesDocument(Notification);

        VerifyBillToAddressEqualsCustomerAddress(SalesHeader, BillToCustomer."No.");

        LibraryNotificationMgt.RecallNotificationsForRecord(SalesHeader);
    end;

    [Test]
    [HandlerFunctions('ModifyVendorAddressNotificationHandler,ConfirmAddressHandler,ModifyPayToVendorAddressRecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure PurchDocBuyFromAddressChangesPropagateToVendorAddressOnNotification()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        DocumentNotifications: Codeunit "Document Notifications";
        Notification: Notification;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 263931] Changes to Purchase Header Buy-from Address fields should propagate to Vendor Address fields when the Notification action is pressed.

        // [GIVEN] Vendor, Purchase Document "PH1" for him.
        CreateTempVendor(Vendor);
        CreatePurchaseHeaderForVendor(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");

        // [WHEN] Buy-from Address fields are changed.
        ChangePurchaseHeaderBuyFromAddressFields(PurchaseHeader);
        PurchaseHeader.Modify(true);

        Notification.SetData(PurchaseHeader.FieldName("Buy-from Vendor No."), PurchaseHeader."Buy-from Vendor No.");
        Notification.SetData(PurchaseHeader.FieldName("Document Type"), Format(PurchaseHeader."Document Type"));
        Notification.SetData(PurchaseHeader.FieldName("No."), PurchaseHeader."No.");
        DocumentNotifications.CopyBuyFromVendorAddressFieldsFromSalesDocument(Notification);

        // [THEN] Address fields for Vendor are equal to Address fields of "PH1".
        VerifyBuyFromAddressEqualsVendorAddress(PurchaseHeader, Vendor."No.");
        LibraryNotificationMgt.RecallNotificationsForRecord(PurchaseHeader);
    end;

    [Test]
    [HandlerFunctions('HandleConfirm,ModifyPayToVendorAddressRecallNotificationHandler,ModifyPayToVendorAddressNotificationHandler,ConfirmAddressHandler')]
    [Scope('OnPrem')]
    procedure PurchDocPayToAddressChangesPropagateToVendorAddressOnNotification()
    var
        Vendor: Record Vendor;
        PayToVendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        DocumentNotifications: Codeunit "Document Notifications";
        Notification: Notification;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 263931] Changes to Purchase Header Pay-to Address fields should propagate to Vendor Address fields when the Notification action is pressed.

        // [GIVEN] Vendors "V1" and "V2", Purchase Document "PH1" for "V1" with "Pay-to Vendor" = "V2".
        CreateTempVendor(Vendor);
        CreatePurchaseHeaderForVendor(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        CreateTempVendor(PayToVendor);
        PurchaseHeader.Validate("Pay-to Vendor No.", PayToVendor."No.");

        // [WHEN] Pay-to Address fields are changed.
        ChangePurchaseHeaderPayToAddressFields(PurchaseHeader);
        PurchaseHeader.Modify(true);

        Notification.SetData(PurchaseHeader.FieldName("Pay-to Vendor No."), PurchaseHeader."Pay-to Vendor No.");
        Notification.SetData(PurchaseHeader.FieldName("Document Type"), Format(PurchaseHeader."Document Type"));
        Notification.SetData(PurchaseHeader.FieldName("No."), PurchaseHeader."No.");
        DocumentNotifications.CopyPayToVendorAddressFieldsFromSalesDocument(Notification);

        // [THEN] Address fields for "V2" are equal to Address fields of "PH1".
        VerifyPayToAddressEqualsVendorAddress(PurchaseHeader, PayToVendor."No.");
        LibraryNotificationMgt.RecallNotificationsForRecord(PurchaseHeader);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure EnableModifyCustomerAddressNotificationsOnInitializingnWithDefaultState()
    var
        SalesHeader: Record "Sales Header";
        MyNotifications: Record "My Notifications";
        User: Record User;
        LibraryPermissions: Codeunit "Library - Permissions";
        MyNotificationsPage: TestPage "My Notifications";
    begin
        // [GIVEN] A user
        Initialize();
        LibraryPermissions.CreateWindowsUser(User, UserId);

        // [WHEN] My Notifications Page is opened
        MyNotificationsPage.OpenView();

        // [THEN] A notification entry is added to MyNotification for the current user
        MyNotifications.Get(User."User Name", SalesHeader.GetModifyBillToCustomerAddressNotificationId());
        MyNotifications.Get(User."User Name", SalesHeader.GetModifyCustomerAddressNotificationId());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerAddressNotChangedOnSalesDocAddressChangeWhenDoNotUpdCustAddr()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        Customer2: Record Customer;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 263931] Customer Address is not changed after Sales Header Sell-to/Bill-to Address change, when "Ignore Updated Addresses" flag is set.
        Initialize();

        // [GIVEN] "Ignore Updated Addresses" flag is set.
        LibrarySales.EnableSalesSetupIgnoreUpdatedAddresses();

        // [GIVEN] Customer with Address, Sales Document for him.
        LibrarySales.CreateCustomerWithAddress(Customer);
        Customer2.Copy(Customer);
        CreateSalesHeaderForCustomer(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");

        // [WHEN] Sell-to Address and Bill-to Address fields are changed.
        ChangeSalesHeaderSellToAddressFields(SalesHeader);
        ChangeSalesHeaderBillToAddressFields(SalesHeader);
        SalesHeader.Modify(true);

        // [THEN] Address fields for Customer are not changed.
        Customer.Find();
        VerifyCustomerAddressHasNotChanged(Customer, Customer2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorAddressNotChangedOnPurchDocAddressChangeWhenDoNotUpdVendAddr()
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        Vendor2: Record Vendor;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 263931] Vendor Address is not changed after Purchase Header Buy-from/Pay-to Address change, when "Ignore Updated Addresses" flag is set.
        Initialize();

        // [GIVEN] "Ignore Updated Addresses" flag is set.
        LibraryPurchase.EnablePurchSetupIgnoreUpdatedAddresses();

        // [GIVEN] Vendor with Address, Purchase Document for him.
        LibraryPurchase.CreateVendorWithAddress(Vendor);
        Vendor2.Copy(Vendor);
        CreatePurchaseHeaderForVendor(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");

        // [WHEN] Buy-from Address and Pay-to Address fields are changed.
        ChangePurchaseHeaderBuyFromAddressFields(PurchaseHeader);
        ChangePurchaseHeaderPayToAddressFields(PurchaseHeader);
        PurchaseHeader.Modify(true);

        // [THEN] Address fields for Vendor are not changed.
        Vendor.Find();
        VerifyVendorAddressHasNotChanged(Vendor, Vendor2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetIgnoreUpdatedAddressOnSalesSetupPage()
    var
        SalesSetup: Record "Sales & Receivables Setup";
        SalesSetupPage: TestPage "Sales & Receivables Setup";
    begin
        // [FEATURE] [UI] [Sales Receivables Setup]
        // [SCENARIO 263931] "Ignore Updated Addresses" field is visible and editable on Sales Setup page in Basic Application Area setup.
        Initialize();
        LibraryApplicationArea.EnableBasicSetup();

        // [GIVEN] "Ignore Updated Addresses" initial state is FALSE.
        LibrarySales.DisableSalesSetupIgnoreUpdatedAddresses();

        // [WHEN] Open Sales Setup page, set "Ignore Updated Addresses" flag, close page.
        SalesSetupPage.OpenEdit();
        Assert.IsTrue(SalesSetupPage."Ignore Updated Addresses".Visible(), '');
        Assert.IsTrue(SalesSetupPage."Ignore Updated Addresses".Editable(), '');
        SalesSetupPage."Ignore Updated Addresses".SetValue(true);
        SalesSetupPage.Close();

        // [THEN] "Ignore Updated Addresses" table field is set to TRUE.
        SalesSetup.Get();
        SalesSetup.TestField("Ignore Updated Addresses", true);

        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetIgnoreUpdatedAddressOnPurchasesSetupPage()
    var
        PurchasesSetup: Record "Purchases & Payables Setup";
        PurchasesSetupPage: TestPage "Purchases & Payables Setup";
    begin
        // [FEATURE] [UI] [Purchases Payables Setup]
        // [SCENARIO 263931] "Ignore Updated Addresses" field is visible and editable on Purchases Setup page in Basic Application Area setup.
        Initialize();
        LibraryApplicationArea.EnableBasicSetup();

        // [GIVEN] "Ignore Updated Addresses" initial state is FALSE.
        LibraryPurchase.DisablePurchSetupIgnoreUpdatedAddresses();

        // [WHEN] Open Purchases Setup page, set "Ignore Updated Addresses" flag, close page.
        PurchasesSetupPage.OpenEdit();
        Assert.IsTrue(PurchasesSetupPage."Ignore Updated Addresses".Visible(), '');
        Assert.IsTrue(PurchasesSetupPage."Ignore Updated Addresses".Editable(), '');
        PurchasesSetupPage."Ignore Updated Addresses".SetValue(true);
        PurchasesSetupPage.Close();

        // [THEN] "Ignore Updated Addresses" table field is set to TRUE.
        PurchasesSetup.Get();
        PurchasesSetup.TestField("Ignore Updated Addresses", true);

        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SalesSalesShipToAddressPropagateWhenShipToCodeIsSetForCustomer()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        ShipToAddress: Record "Ship-to Address";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Ship-to Code from Customer should propagate to Ship-to Address fields
        // [GIVEN] Sales Header created for Customer with "Ship-to Code" set
        Initialize();
        CreateTempCustomer(Customer);
        LibrarySales.CreateShipToAddress(ShipToAddress, Customer."No.");
        Customer."Ship-to Code" := ShipToAddress.Code;
        Customer.Modify();

        // [WHEN] Create sales order for customer
        CreateSalesHeaderForCustomer(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");

        // [THEN] Ship-to should propagate to Ship-to address fields in sales order
        VerifySalesDocumentShipToAddress(SalesHeader,
          ShipToAddress.Address, ShipToAddress."Address 2", ShipToAddress.City, ShipToAddress."Post Code",
          ShipToAddress.County, ShipToAddress."Country/Region Code");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SalesSalesShipToAddressPropagateFromShipToNotBillTo()
    var
        SellToCustomer: Record Customer;
        BillToCustomer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 324316] Ship-to Code should propagate from "Sell-to Customer"
        Initialize();

        // [GIVEN] Customer "C1" with 'Ship-to Code' "X"
        CreateCustomerWithShipToCode(SellToCustomer);
        // [GIVEN] Customer "C2" with 'Ship-to Code' "Y"
        CreateCustomerWithShipToCode(BillToCustomer);
        // [GIVEN] Set "C1" 'Bill-to Customer' = "C2"
        SellToCustomer.Validate("Bill-to Customer No.", BillToCustomer."No.");
        SellToCustomer.Modify(true);

        // [WHEN] Create sales order for customer "C1"
        CreateSalesHeaderForCustomer(SalesHeader, SalesHeader."Document Type"::Order, SellToCustomer."No.");

        // [THEN] Ship-to Code is "X"
        SalesHeader.TestField("Ship-to Code", SellToCustomer."Ship-to Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceShipToCodePropagateFromCustomer()
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
    begin
        // [FEATURE] [Service]
        // [SCENARIO 331966] Ship-to Code should propagate from Customer
        Initialize();

        // [GIVEN] Created customer C1 with "Ship-to Code"=X
        CreateCustomerWithShipToCode(Customer);

        // [WHEN] Create Service Order for customer C1
        CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");

        // [THEN] "Ship-to Code" is "X"
        ServiceHeader.TestField("Ship-to Code", Customer."Ship-to Code");
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Doc. Address Propagation Test");
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Doc. Address Propagation Test");

        IsInitialized := true;

        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Doc. Address Propagation Test");
    end;

    [SendNotificationHandler]
    [HandlerFunctions('ConfirmAddressHandler')]
    [Scope('OnPrem')]
    procedure ModifyCustomerAddressNotificationHandler(var Notification: Notification): Boolean
    var
        DocumentNotifications: Codeunit "Document Notifications";
    begin
        DocumentNotifications.CopySellToCustomerAddressFieldsFromSalesDocument(Notification);
    end;

    [SendNotificationHandler]
    [HandlerFunctions('ConfirmAddressHandler')]
    [Scope('OnPrem')]
    procedure ModifyBillToCustomerAddressNotificationHandler(var Notification: Notification): Boolean
    var
        DocumentNotifications: Codeunit "Document Notifications";
    begin
        DocumentNotifications.CopyBillToCustomerAddressFieldsFromSalesDocument(Notification);
    end;

    [RecallNotificationHandler]
    [Scope('OnPrem')]
    procedure ModifyBillToCustomerAddressRecallNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    [SendNotificationHandler]
    [HandlerFunctions('ConfirmAddressHandler')]
    [Scope('OnPrem')]
    procedure ModifyVendorAddressNotificationHandler(var Notification: Notification): Boolean
    var
        DocumentNotifications: Codeunit "Document Notifications";
    begin
        DocumentNotifications.CopyBuyFromVendorAddressFieldsFromSalesDocument(Notification);
    end;

    [SendNotificationHandler]
    [HandlerFunctions('ConfirmAddressHandler')]
    [Scope('OnPrem')]
    procedure ModifyPayToVendorAddressNotificationHandler(var Notification: Notification): Boolean
    var
        DocumentNotifications: Codeunit "Document Notifications";
    begin
        DocumentNotifications.CopyPayToVendorAddressFieldsFromSalesDocument(Notification);
    end;

    [RecallNotificationHandler]
    [Scope('OnPrem')]
    procedure ModifyPayToVendorAddressRecallNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ConfirmAddressHandler(var UpdateAddress: Page "Update Address"; var Response: Action)
    begin
        Response := ACTION::OK;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure HandleConfirm(Message: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    local procedure CreateTempVendor(var Vendor: Record Vendor)
    var
        PostCode: Record "Post Code";
    begin
        LibraryERM.CreatePostCode(PostCode);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate(Name, LibraryUtility.GenerateRandomText(MaxStrLen(Vendor.Name)));
        Vendor.Validate(Address, LibraryUtility.GenerateRandomText(MaxStrLen(Vendor.Address)));
        Vendor.Validate("Post Code", PostCode.Code);
        Vendor.Contact := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Vendor.Contact)), 1, MaxStrLen(Vendor.Contact));
        Vendor.Modify(true);
    end;

    local procedure CreateTempCustomer(var Customer: Record Customer)
    var
        PostCode: Record "Post Code";
    begin
        LibraryERM.CreatePostCode(PostCode);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate(Name, LibraryUtility.GenerateRandomText(MaxStrLen(Customer.Name)));
        Customer.Validate(Address, LibraryUtility.GenerateRandomText(MaxStrLen(Customer.Address)));
        Customer.Validate("Post Code", PostCode.Code);
        Customer.Contact := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Customer.Contact)), 1, MaxStrLen(Customer.Contact));
        Customer.Modify(true);
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type")
    begin
        SalesHeader.Init();
        SalesHeader.Validate("Document Type", DocumentType);
        SalesHeader.Insert(true);
    end;

    local procedure CreatePurchaseHeaderForVendor(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; BuyFromVendorNo: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, BuyFromVendorNo);
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
    end;

    local procedure CreateSalesHeaderForCustomer(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; CustomerCode: Code[20])
    begin
        CreateSalesHeader(SalesHeader, DocumentType);

        // If Copy Sales Document is ran with IncludeHeader=False is mandatory to have the same vendor in original and destination doc.
        SalesHeader.Validate("Sell-to Customer No.", CustomerCode);
        SalesHeader.Modify(true);
    end;

    local procedure CreateServiceHeader(var ServiceHeader: Record "Service Header"; DocType: Enum "Service Document Type"; CustomerCode: Code[20])
    begin
        // Create Service header, return document No
        LibraryService.CreateServiceHeader(ServiceHeader, DocType, CustomerCode);
        ServiceHeader.Validate("Posting Date", WorkDate());
        ServiceHeader.Modify(true);
    end;

    local procedure CreateCustomerWithShipToCode(var Customer: Record Customer)
    var
        ShipToAddress: Record "Ship-to Address";
    begin
        CreateTempCustomer(Customer);
        LibrarySales.CreateShipToAddress(ShipToAddress, Customer."No.");
        Customer."Ship-to Code" := ShipToAddress.Code;
        Customer.Modify();
    end;

    local procedure ChangePurchaseHeaderBuyFromAddressFields(var PurchaseHeader: Record "Purchase Header")
    var
        CountryRegion: Record "Country/Region";
    begin
        PurchaseHeader.Validate("Buy-from Address", 'New Address');
        PurchaseHeader.Validate("Buy-from Address 2", 'New Address2');
        CountryRegion.Next(LibraryRandom.RandInt(CountryRegion.Count));
        PurchaseHeader.Validate("Buy-from Country/Region Code", CountryRegion.Code);
        PurchaseHeader.Validate("Buy-from City", 'New City');
        PurchaseHeader.Validate("Buy-from Post Code", 'New Post Code');
        PurchaseHeader.Validate("Buy-from County", 'New County');
    end;

    local procedure ChangePurchaseHeaderPayToAddressFields(var PurchaseHeader: Record "Purchase Header")
    var
        CountryRegion: Record "Country/Region";
    begin
        PurchaseHeader.Validate("Pay-to Address", 'New Address');
        PurchaseHeader.Validate("Pay-to Address 2", 'New Address 2');
        CountryRegion.Next(LibraryRandom.RandInt(CountryRegion.Count));
        PurchaseHeader.Validate("Pay-to Country/Region Code", CountryRegion.Code);
        PurchaseHeader.Validate("Pay-to City", 'New City');
        PurchaseHeader.Validate("Pay-to Post Code", 'New Post Code');
        PurchaseHeader.Validate("Pay-to County", 'New County');
    end;

    local procedure ChangeSalesHeaderSellToAddressFields(var SalesHeader: Record "Sales Header")
    var
        CountryRegion: Record "Country/Region";
    begin
        SalesHeader.Validate("Sell-to Address", 'New Address');
        SalesHeader.Validate("Sell-to Address 2", 'New Address2');
        CountryRegion.Next(LibraryRandom.RandInt(CountryRegion.Count));
        SalesHeader.Validate("Sell-to Country/Region Code", CountryRegion.Code);
        SalesHeader.Validate("Sell-to City", 'New City');
        SalesHeader.Validate("Sell-to Post Code", 'New Post Code');
        SalesHeader.Validate("Sell-to County", 'New County');
    end;

    local procedure ChangeSalesHeaderBillToAddressFields(var SalesHeader: Record "Sales Header")
    var
        CountryRegion: Record "Country/Region";
    begin
        SalesHeader.Validate("Bill-to Address", 'New Address');
        SalesHeader.Validate("Bill-to Address 2", 'New Address2');
        CountryRegion.Next(LibraryRandom.RandInt(CountryRegion.Count));
        SalesHeader.Validate("Bill-to Country/Region Code", CountryRegion.Code);
        SalesHeader.Validate("Bill-to City", 'New City');
        SalesHeader.Validate("Bill-to Post Code", 'New Post Code');
        SalesHeader.Validate("Bill-to County", 'New County');
    end;

    local procedure ChangeServiceHeaderAddressFields(var ServiceHeader: Record "Service Header")
    var
        CountryRegion: Record "Country/Region";
    begin
        ServiceHeader.Validate(Address, 'New Address');
        ServiceHeader.Validate("Address 2", 'New Address2');
        CountryRegion.Next(LibraryRandom.RandInt(CountryRegion.Count));
        ServiceHeader.Validate("Country/Region Code", CountryRegion.Code);
        ServiceHeader.Validate(City, 'New City');
        ServiceHeader.Validate("Post Code", 'New Post Code');
        ServiceHeader.Validate(County, 'New County');
    end;

    local procedure VerifyBuyFromAddressEqualsPayToAddress(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.TestField("Buy-from Address", PurchaseHeader."Pay-to Address");
        PurchaseHeader.TestField("Buy-from Address 2", PurchaseHeader."Pay-to Address 2");
        PurchaseHeader.TestField("Buy-from City", PurchaseHeader."Pay-to City");
        PurchaseHeader.TestField("Buy-from Post Code", PurchaseHeader."Pay-to Post Code");
        PurchaseHeader.TestField("Buy-from County", PurchaseHeader."Pay-to County");
        PurchaseHeader.TestField("Buy-from Country/Region Code", PurchaseHeader."Pay-to Country/Region Code");
    end;

    local procedure VerifyPayToAddress(var PurchaseHeader: Record "Purchase Header"; PayToAddress: Text[100]; PayToAddress2: Text[50]; PayToCity: Text[30]; PayToPostCode: Code[20]; PayToCounty: Text[30]; PayToCountryRegionCode: Code[10])
    begin
        PurchaseHeader.TestField("Pay-to Address", PayToAddress);
        PurchaseHeader.TestField("Pay-to Address 2", PayToAddress2);
        PurchaseHeader.TestField("Pay-to City", PayToCity);
        PurchaseHeader.TestField("Pay-to Post Code", PayToPostCode);
        PurchaseHeader.TestField("Pay-to County", PayToCounty);
        PurchaseHeader.TestField("Pay-to Country/Region Code", PayToCountryRegionCode);
    end;

    local procedure VerifySellToAddressEqualsShipToAddress(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.TestField("Sell-to Address", SalesHeader."Ship-to Address");
        SalesHeader.TestField("Sell-to Address 2", SalesHeader."Ship-to Address 2");
        SalesHeader.TestField("Sell-to City", SalesHeader."Ship-to City");
        SalesHeader.TestField("Sell-to Post Code", SalesHeader."Ship-to Post Code");
        SalesHeader.TestField("Sell-to County", SalesHeader."Ship-to County");
        SalesHeader.TestField("Sell-to Country/Region Code", SalesHeader."Ship-to Country/Region Code");
    end;

    local procedure VerifySalesDocumentShipToAddress(var SalesHeader: Record "Sales Header"; ShipToAddress: Text[100]; ShipToAddress2: Text[50]; ShipToCity: Text[30]; ShipToPostCode: Code[20]; ShipToCounty: Text[30]; ShipToCountryRegionCode: Code[10])
    begin
        SalesHeader.TestField("Ship-to Address", ShipToAddress);
        SalesHeader.TestField("Ship-to Address 2", ShipToAddress2);
        SalesHeader.TestField("Ship-to City", ShipToCity);
        SalesHeader.TestField("Ship-to Post Code", ShipToPostCode);
        SalesHeader.TestField("Ship-to County", ShipToCounty);
        SalesHeader.TestField("Ship-to Country/Region Code", ShipToCountryRegionCode);
    end;

    local procedure VerifyAddressEqualsShipToAddress(var ServiceHeader: Record "Service Header")
    begin
        ServiceHeader.TestField(Address, ServiceHeader."Ship-to Address");
        ServiceHeader.TestField("Address 2", ServiceHeader."Ship-to Address 2");
        ServiceHeader.TestField(City, ServiceHeader."Ship-to City");
        ServiceHeader.TestField("Post Code", ServiceHeader."Ship-to Post Code");
        ServiceHeader.TestField(County, ServiceHeader."Ship-to County");
        ServiceHeader.TestField("Country/Region Code", ServiceHeader."Ship-to Country/Region Code");
    end;

    local procedure VerifyServiceDocumentShipToAddress(var ServiceHeader: Record "Service Header"; ShipToAddress: Text[100]; ShipToAddress2: Text[50]; ShipToCity: Text[30]; ShipToPostCode: Code[20]; ShipToCounty: Text[30]; ShipToCountryRegionCode: Code[10])
    begin
        ServiceHeader.TestField("Ship-to Address", ShipToAddress);
        ServiceHeader.TestField("Ship-to Address 2", ShipToAddress2);
        ServiceHeader.TestField("Ship-to City", ShipToCity);
        ServiceHeader.TestField("Ship-to Post Code", ShipToPostCode);
        ServiceHeader.TestField("Ship-to County", ShipToCounty);
        ServiceHeader.TestField("Ship-to Country/Region Code", ShipToCountryRegionCode);
    end;

    local procedure VerifySellToAddressEqualsCustomerAddress(SalesHeader: Record "Sales Header"; CustomerNo: Code[20])
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        Customer.TestField(Address, SalesHeader."Sell-to Address");
        Customer.TestField("Address 2", SalesHeader."Sell-to Address 2");
        Customer.TestField(City, SalesHeader."Sell-to City");
        Customer.TestField("Post Code", SalesHeader."Sell-to Post Code");
        Customer.TestField(County, SalesHeader."Sell-to County");
        Customer.TestField("Country/Region Code", SalesHeader."Sell-to Country/Region Code");
    end;

    local procedure VerifyBillToAddressEqualsCustomerAddress(SalesHeader: Record "Sales Header"; CustomerNo: Code[20])
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        Customer.TestField(Address, SalesHeader."Bill-to Address");
        Customer.TestField("Address 2", SalesHeader."Bill-to Address 2");
        Customer.TestField(City, SalesHeader."Bill-to City");
        Customer.TestField("Post Code", SalesHeader."Bill-to Post Code");
        Customer.TestField(County, SalesHeader."Bill-to County");
        Customer.TestField("Country/Region Code", SalesHeader."Bill-to Country/Region Code");
    end;

    local procedure VerifyBuyFromAddressEqualsVendorAddress(PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20])
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendorNo);
        Vendor.TestField(Address, PurchaseHeader."Buy-from Address");
        Vendor.TestField("Address 2", PurchaseHeader."Buy-from Address 2");
        Vendor.TestField(City, PurchaseHeader."Buy-from City");
        Vendor.TestField("Post Code", PurchaseHeader."Buy-from Post Code");
        Vendor.TestField(County, PurchaseHeader."Buy-from County");
        Vendor.TestField("Country/Region Code", PurchaseHeader."Buy-from Country/Region Code");
    end;

    local procedure VerifyPayToAddressEqualsVendorAddress(PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20])
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendorNo);
        Vendor.TestField(Address, PurchaseHeader."Pay-to Address");
        Vendor.TestField("Address 2", PurchaseHeader."Pay-to Address 2");
        Vendor.TestField(City, PurchaseHeader."Pay-to City");
        Vendor.TestField("Post Code", PurchaseHeader."Pay-to Post Code");
        Vendor.TestField(County, PurchaseHeader."Pay-to County");
        Vendor.TestField("Country/Region Code", PurchaseHeader."Pay-to Country/Region Code");
    end;

    local procedure VerifyCustomerAddressHasNotChanged(CustomerActual: Record Customer; CustomerExpected: Record Customer)
    begin
        CustomerActual.TestField(Address, CustomerExpected.Address);
        CustomerActual.TestField("Address 2", CustomerExpected."Address 2");
        CustomerActual.TestField(City, CustomerExpected.City);
        CustomerActual.TestField("Post Code", CustomerExpected."Post Code");
        CustomerActual.TestField(County, CustomerExpected.County);
        CustomerActual.TestField("Country/Region Code", CustomerExpected."Country/Region Code");
    end;

    local procedure VerifyVendorAddressHasNotChanged(VendorActual: Record Vendor; VendorExpected: Record Vendor)
    begin
        VendorActual.TestField(Address, VendorExpected.Address);
        VendorActual.TestField("Address 2", VendorExpected."Address 2");
        VendorActual.TestField(City, VendorExpected.City);
        VendorActual.TestField("Post Code", VendorExpected."Post Code");
        VendorActual.TestField(County, VendorExpected.County);
        VendorActual.TestField("Country/Region Code", VendorExpected."Country/Region Code");
    end;
}

