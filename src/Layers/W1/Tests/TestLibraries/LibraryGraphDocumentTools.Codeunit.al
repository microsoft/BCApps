codeunit 130619 "Library - Graph Document Tools"
{

    trigger OnRun()
    begin
    end;

    var
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        LibraryResource: Codeunit "Library - Resource";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryPurchase: Codeunit "Library - Purchase";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        LineDetailsFieldNameTxt: Label 'lineDetails';
        LineTypeFieldNameTxt: Label 'lineType';
        DiscountAmountFieldTxt: Label 'discountAmount';

    [Scope('OnPrem')]
    procedure InitializeUIPage()
    var
        UserPreference: Record "User Preference";
    begin
        if IsInitialized then
            exit;

        LibraryApplicationArea.EnableFoundationSetup();
        LibrarySales.SetStockoutWarning(false);

        // Disable warning on closing Order
        UserPreference."User ID" := CopyStr(UserId(), 1, MaxStrLen(UserPreference."User ID"));
        UserPreference."Instruction Code" := 'QUERYPOSTONCLOSE';
        if not UserPreference.Insert() then
            UserPreference.Modify();

        IsInitialized := true;
        Commit();
    end;

    [Scope('OnPrem')]
    procedure GetCustomerAddressComplexType(var ComplexTypeJSON: Text; var Customer: Record Customer; ShouldBeEmpty: Boolean; ShouldBePartiallyEmpty: Boolean)
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        City: Text;
        State: Text;
        CountryCode: Text;
        PostalCode: Text;
        Address: Text;
        Address2: Text;
    begin
        if ShouldBeEmpty then begin
            Address := '';
            Address2 := '';
            City := '';
            State := '';
            CountryCode := '';
            PostalCode := '';
        end else
            if ShouldBePartiallyEmpty then begin
                Address := Customer.Address;
                Address2 := Customer."Address 2";
                City := '';
                State := '';
                CountryCode := Customer."Country/Region Code";
                PostalCode := '';
            end else begin
                Address := Customer.Address;
                Address2 := Customer."Address 2";
                City := Customer.City;
                State := Customer.County;
                CountryCode := Customer."Country/Region Code";
                PostalCode := Customer."Post Code";
            end;

        ComplexTypeJSON :=
          LibraryGraphMgt.AddPropertytoJSON('{}', 'street', GraphCollectionMgtContact.ConcatenateStreet(Address, Address2));
        ComplexTypeJSON := LibraryGraphMgt.AddPropertytoJSON(ComplexTypeJSON, 'city', City);
        ComplexTypeJSON := LibraryGraphMgt.AddPropertytoJSON(ComplexTypeJSON, 'state', State);
        ComplexTypeJSON := LibraryGraphMgt.AddPropertytoJSON(ComplexTypeJSON, 'countryLetterCode', CountryCode);
        ComplexTypeJSON := LibraryGraphMgt.AddPropertytoJSON(ComplexTypeJSON, 'postalCode', PostalCode);
    end;

    [Scope('OnPrem')]
    procedure GetCustomerAddressJSON(var DocumentJSON: Text; var Customer: Record Customer; AddressType: Text; ShouldBeEmpty: Boolean; ShouldBePartiallyEmpty: Boolean)
    var
        City: Text;
        State: Text;
        CountryCode: Text;
        PostalCode: Text;
        Address: Text;
        Address2: Text;
    begin
        if ShouldBeEmpty then begin
            Address := '';
            Address2 := '';
            City := '';
            State := '';
            CountryCode := '';
            PostalCode := '';
        end else
            if ShouldBePartiallyEmpty then begin
                Address := Customer.Address;
                Address2 := Customer."Address 2";
                City := '';
                State := '';
                CountryCode := Customer."Country/Region Code";
                PostalCode := '';
            end else begin
                Address := Customer.Address;
                Address2 := Customer."Address 2";
                City := Customer.City;
                State := Customer.County;
                CountryCode := Customer."Country/Region Code";
                PostalCode := Customer."Post Code";
            end;

        DocumentJSON := LibraryGraphMgt.AddPropertytoJSON(DocumentJSON, AddressType + 'AddressLine1', Address);
        DocumentJSON := LibraryGraphMgt.AddPropertytoJSON(DocumentJSON, AddressType + 'AddressLine2', Address2);
        DocumentJSON := LibraryGraphMgt.AddPropertytoJSON(DocumentJSON, AddressType + 'City', City);
        DocumentJSON := LibraryGraphMgt.AddPropertytoJSON(DocumentJSON, AddressType + 'State', State);
        DocumentJSON := LibraryGraphMgt.AddPropertytoJSON(DocumentJSON, AddressType + 'Country', CountryCode);
        DocumentJSON := LibraryGraphMgt.AddPropertytoJSON(DocumentJSON, AddressType + 'PostCode', PostalCode);
    end;

    [Scope('OnPrem')]
    procedure GetVendorAddressComplexType(var ComplexTypeJSON: Text; var Vendor: Record Vendor; ShouldBeEmpty: Boolean; ShouldBePartiallyEmpty: Boolean)
    var
        CountryRegion: Record "Country/Region";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        City: Text;
        State: Text;
        CountryCode: Text;
        PostalCode: Text;
        Address: Text;
        Address2: Text;
    begin
        if ShouldBeEmpty then begin
            Address := '';
            Address2 := '';
            City := '';
            State := '';
            CountryCode := '';
            PostalCode := '';
        end else
            if ShouldBePartiallyEmpty then begin
                Address := Vendor.Address;
                Address2 := Vendor."Address 2";
                City := '';
                State := '';
                CountryCode := Vendor."Country/Region Code";
                PostalCode := '';
            end else begin
                Address := Vendor.Address;
                Address2 := Vendor."Address 2";
                City := Vendor.City;
                State := Vendor.County;
                LibraryERM.CreateCountryRegion(CountryRegion);
                CountryCode := Vendor."Country/Region Code";
                PostalCode := Vendor."Post Code";
            end;

        ComplexTypeJSON :=
          LibraryGraphMgt.AddPropertytoJSON('{}', 'street', GraphCollectionMgtContact.ConcatenateStreet(Address, Address2));
        ComplexTypeJSON := LibraryGraphMgt.AddPropertytoJSON(ComplexTypeJSON, 'city', City);
        ComplexTypeJSON := LibraryGraphMgt.AddPropertytoJSON(ComplexTypeJSON, 'state', State);
        ComplexTypeJSON := LibraryGraphMgt.AddPropertytoJSON(ComplexTypeJSON, 'countryLetterCode', CountryCode);
        ComplexTypeJSON := LibraryGraphMgt.AddPropertytoJSON(ComplexTypeJSON, 'postalCode', PostalCode);
    end;

    [Scope('OnPrem')]
    procedure GetVendorAddressJSON(var DocumentJSON: Text; var Vendor: Record Vendor; AddressType: Text; ShouldBeEmpty: Boolean; ShouldBePartiallyEmpty: Boolean)
    var
        CountryRegion: Record "Country/Region";
        City: Text;
        State: Text;
        CountryCode: Text;
        PostalCode: Text;
        Address: Text;
        Address2: Text;
    begin
        if ShouldBeEmpty then begin
            Address := '';
            Address2 := '';
            City := '';
            State := '';
            CountryCode := '';
            PostalCode := '';
        end else
            if ShouldBePartiallyEmpty then begin
                Address := Vendor.Address;
                Address2 := Vendor."Address 2";
                City := '';
                State := '';
                CountryCode := Vendor."Country/Region Code";
                PostalCode := '';
            end else begin
                Address := Vendor.Address;
                Address2 := Vendor."Address 2";
                City := Vendor.City;
                State := Vendor.County;
                LibraryERM.CreateCountryRegion(CountryRegion);
                CountryCode := Vendor."Country/Region Code";
                PostalCode := Vendor."Post Code";
            end;

        DocumentJSON := LibraryGraphMgt.AddPropertytoJSON(DocumentJSON, AddressType + 'AddressLine1', Address);
        DocumentJSON := LibraryGraphMgt.AddPropertytoJSON(DocumentJSON, AddressType + 'AddressLine2', Address2);
        DocumentJSON := LibraryGraphMgt.AddPropertytoJSON(DocumentJSON, AddressType + 'City', City);
        DocumentJSON := LibraryGraphMgt.AddPropertytoJSON(DocumentJSON, AddressType + 'State', State);
        DocumentJSON := LibraryGraphMgt.AddPropertytoJSON(DocumentJSON, AddressType + 'Country', CountryCode);
        DocumentJSON := LibraryGraphMgt.AddPropertytoJSON(DocumentJSON, AddressType + 'PostCode', PostalCode);
    end;

    [Scope('OnPrem')]
    procedure AssertSalesDocumentBillToAddress(var SalesHeader: Record "Sales Header"; ExpectedAddress: Text; ExpectedAddress2: Text; ExpectedCity: Text; ExpectedState: Text; ExpectedCountryCode: Text; ExpectedPostalCode: Text)
    begin
        SalesHeader.TestField("Bill-to Address", ExpectedAddress);
        SalesHeader.TestField("Bill-to Address 2", ExpectedAddress2);
        SalesHeader.TestField("Bill-to City", ExpectedCity);
        SalesHeader.TestField("Bill-to County", ExpectedState);
        SalesHeader.TestField("Bill-to Post Code", ExpectedPostalCode);
        SalesHeader.TestField("Bill-to Country/Region Code", ExpectedCountryCode);
    end;

    [Scope('OnPrem')]
    procedure AssertSalesDocumentSellToAddress(var SalesHeader: Record "Sales Header"; ExpectedAddress: Text; ExpectedAddress2: Text; ExpectedCity: Text; ExpectedState: Text; ExpectedCountryCode: Text; ExpectedPostalCode: Text)
    begin
        SalesHeader.TestField("Sell-to Address", ExpectedAddress);
        SalesHeader.TestField("Sell-to Address 2", ExpectedAddress2);
        SalesHeader.TestField("Sell-to City", ExpectedCity);
        SalesHeader.TestField("Sell-to County", ExpectedState);
        SalesHeader.TestField("Sell-to Post Code", ExpectedPostalCode);
        SalesHeader.TestField("Sell-to Country/Region Code", ExpectedCountryCode);
    end;

    [Scope('OnPrem')]
    procedure AssertSalesDocumentShipToAddress(var SalesHeader: Record "Sales Header"; ExpectedAddress: Text; ExpectedAddress2: Text; ExpectedCity: Text; ExpectedState: Text; ExpectedCountryCode: Text; ExpectedPostalCode: Text)
    begin
        SalesHeader.TestField("Ship-to Address", ExpectedAddress);
        SalesHeader.TestField("Ship-to Address 2", ExpectedAddress2);
        SalesHeader.TestField("Ship-to City", ExpectedCity);
        SalesHeader.TestField("Ship-to County", ExpectedState);
        SalesHeader.TestField("Ship-to Post Code", ExpectedPostalCode);
        SalesHeader.TestField("Ship-to Country/Region Code", ExpectedCountryCode);
    end;

    [Scope('OnPrem')]
    procedure AssertPurchaseDocumentBuyFromAddress(var PurchaseHeader: Record "Purchase Header"; ExpectedAddress: Text; ExpectedAddress2: Text; ExpectedCity: Text; ExpectedState: Text; ExpectedCountryCode: Text; ExpectedPostalCode: Text)
    begin
        PurchaseHeader.TestField("Buy-from Address", ExpectedAddress);
        PurchaseHeader.TestField("Buy-from Address 2", ExpectedAddress2);
        PurchaseHeader.TestField("Buy-from City", ExpectedCity);
        PurchaseHeader.TestField("Buy-from County", ExpectedState);
        PurchaseHeader.TestField("Buy-from Post Code", ExpectedPostalCode);
        PurchaseHeader.TestField("Buy-from Country/Region Code", ExpectedCountryCode);
    end;

    [Scope('OnPrem')]
    procedure AssertPurchaseDocumentPayToAddress(var PurchaseHeader: Record "Purchase Header"; ExpectedAddress: Text; ExpectedAddress2: Text; ExpectedCity: Text; ExpectedState: Text; ExpectedCountryCode: Text; ExpectedPostalCode: Text)
    begin
        PurchaseHeader.TestField("Pay-to Address", ExpectedAddress);
        PurchaseHeader.TestField("Pay-to Address 2", ExpectedAddress2);
        PurchaseHeader.TestField("Pay-to City", ExpectedCity);
        PurchaseHeader.TestField("Pay-to County", ExpectedState);
        PurchaseHeader.TestField("Pay-to Post Code", ExpectedPostalCode);
        PurchaseHeader.TestField("Pay-to Country/Region Code", ExpectedCountryCode);
    end;

    [Scope('OnPrem')]
    procedure AssertPurchaseDocumentShipToAddress(var PurchaseHeader: Record "Purchase Header"; ExpectedAddress: Text; ExpectedAddress2: Text; ExpectedCity: Text; ExpectedState: Text; ExpectedCountryCode: Text; ExpectedPostalCode: Text)
    begin
        PurchaseHeader.TestField("Ship-to Address", ExpectedAddress);
        PurchaseHeader.TestField("Ship-to Address 2", ExpectedAddress2);
        PurchaseHeader.TestField("Ship-to City", ExpectedCity);
        PurchaseHeader.TestField("Ship-to County", ExpectedState);
        PurchaseHeader.TestField("Ship-to Post Code", ExpectedPostalCode);
        PurchaseHeader.TestField("Ship-to Country/Region Code", ExpectedCountryCode);
    end;

    [Scope('OnPrem')]
    procedure CreateDocumentWithDiscountPctPending(var SalesHeader: Record "Sales Header"; var DiscountPct: Decimal; DocumentType: Enum "Sales Document Type")
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
        Customer: Record Customer;
    begin
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(
          Item, LibraryRandom.RandDecInDecimalRange(1, 100, 2), LibraryRandom.RandDecInDecimalRange(1, 100, 2));
        LibrarySales.CreateCustomer(Customer);
        DiscountPct := LibraryRandom.RandDecInRange(1, 99, 2);
        LibrarySmallBusiness.SetInvoiceDiscountToCustomer(Customer, DiscountPct, 0, '');

        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandIntInRange(1, 10));
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandIntInRange(1, 10));
    end;

    [Scope('OnPrem')]
    procedure VerifySalesTotals(SalesHeader: Record "Sales Header"; JSONResponse: Text; OrderDiscountValue: Decimal; ExpectedOrderDiscountType: Option)
    var
        discountAmount: Decimal;
        totalAmountExcludingTax: Decimal;
        totalTaxAmount: Decimal;
        totalAmountIncludingTax: Decimal;
        discountAmountTxt: Text;
        totalAmountExcludingTaxTxt: Text;
        totalTaxAmountTxt: Text;
        totalAmountIncludingTaxTxt: Text;
    begin
        SalesHeader.Find();
        SalesHeader.CalcFields(Amount, "Amount Including VAT", "Invoice Discount Amount");

        // Parse JSON
        LibraryGraphMgt.GetObjectIDFromJSON(JSONResponse, 'discountAmount', discountAmountTxt);
        LibraryGraphMgt.GetObjectIDFromJSON(JSONResponse, 'totalAmountExcludingTax', totalAmountExcludingTaxTxt);
        LibraryGraphMgt.GetObjectIDFromJSON(JSONResponse, 'totalTaxAmount', totalTaxAmountTxt);
        LibraryGraphMgt.GetObjectIDFromJSON(JSONResponse, 'totalAmountIncludingTax', totalAmountIncludingTaxTxt);

        Evaluate(discountAmount, discountAmountTxt);
        Evaluate(totalAmountExcludingTax, totalAmountExcludingTaxTxt);
        Evaluate(totalTaxAmount, totalTaxAmountTxt);
        Evaluate(totalAmountIncludingTax, totalAmountIncludingTaxTxt);

        Assert.AreEqual(
          ExpectedOrderDiscountType, SalesHeader."Invoice Discount Calculation", 'Wrong Invoice Discount type on the header');
        Assert.AreEqual(OrderDiscountValue, SalesHeader."Invoice Discount Value", 'Invoice Discount value was not set on the header');
        Assert.AreNotEqual(0, SalesHeader."Invoice Discount Amount", 'Invoice Discount amount was not set on the header');

        Assert.AreEqual(SalesHeader.Amount, totalAmountExcludingTax, 'Total Amount Excl. Tax was not correct.');
        Assert.AreEqual(SalesHeader."Amount Including VAT", totalAmountIncludingTax, 'Total Amount Incl. Tax is not correct.');
        Assert.AreEqual(SalesHeader."Amount Including VAT" - SalesHeader.Amount, totalTaxAmount, 'Total Tax Amount is not correct.');
        Assert.AreEqual(SalesHeader."Invoice Discount Amount", discountAmount, 'Discount amount is not correct');
    end;

    [Scope('OnPrem')]
    procedure VerifyPurchaseTotals(PurchaseHeader: Record "Purchase Header"; JSONResponse: Text; OrderDiscountValue: Decimal; ExpectedOrderDiscountType: Option)
    var
        discountAmount: Decimal;
        totalAmountExcludingTax: Decimal;
        totalTaxAmount: Decimal;
        totalAmountIncludingTax: Decimal;
        discountAmountTxt: Text;
        totalAmountExcludingTaxTxt: Text;
        totalTaxAmountTxt: Text;
        totalAmountIncludingTaxTxt: Text;
    begin
        PurchaseHeader.Find();
        PurchaseHeader.CalcFields(Amount, "Amount Including VAT", "Invoice Discount Amount");
        PurchaseHeader.CalcFields("Invoice Discount Amount");

        // Parse JSON
        LibraryGraphMgt.GetObjectIDFromJSON(JSONResponse, 'discountAmount', discountAmountTxt);
        LibraryGraphMgt.GetObjectIDFromJSON(JSONResponse, 'totalAmountExcludingTax', totalAmountExcludingTaxTxt);
        LibraryGraphMgt.GetObjectIDFromJSON(JSONResponse, 'totalTaxAmount', totalTaxAmountTxt);
        LibraryGraphMgt.GetObjectIDFromJSON(JSONResponse, 'totalAmountIncludingTax', totalAmountIncludingTaxTxt);

        Evaluate(discountAmount, discountAmountTxt);
        Evaluate(totalAmountExcludingTax, totalAmountExcludingTaxTxt);
        Evaluate(totalTaxAmount, totalTaxAmountTxt);
        Evaluate(totalAmountIncludingTax, totalAmountIncludingTaxTxt);

        Assert.AreEqual(
          ExpectedOrderDiscountType, PurchaseHeader."Invoice Discount Calculation", 'Wrong Invoice Discount type on the header');
        Assert.AreEqual(OrderDiscountValue, PurchaseHeader."Invoice Discount Value", 'Invoice Discount value was not set on the header');
        Assert.AreNotEqual(0, PurchaseHeader."Invoice Discount Amount", 'Invoice Discount amount was not set on the header');

        Assert.AreEqual(PurchaseHeader.Amount, totalAmountExcludingTax, 'Total Amount Excl. Tax was not correct.');
        Assert.AreEqual(PurchaseHeader."Amount Including VAT", totalAmountIncludingTax, 'Total Amount Incl. Tax is not correct.');
        Assert.AreEqual(PurchaseHeader."Amount Including VAT" - PurchaseHeader.Amount, totalTaxAmount, 'Total Tax Amount is not correct.');
        Assert.AreEqual(PurchaseHeader."Invoice Discount Amount", discountAmount, 'Discount amount is not correct');
    end;

    [Scope('OnPrem')]
    procedure VerifyCustomerBillingAddress(Customer: Record Customer; SalesHeader: Record "Sales Header"; ResponseText: Text; EmptyData: Boolean; PartiallyEmptyData: Boolean)
    var
        JSONManagement: Codeunit "JSON Management";
        JObject: DotNet JObject;
        JSONAddressValue: Text;
    begin
        JSONManagement.InitializeObject(ResponseText);
        JSONManagement.GetJSONObject(JObject);
        Assert.IsTrue(JSONManagement.GetStringPropertyValueFromJObjectByName(JObject, 'billingPostalAddress', JSONAddressValue),
          'Could not find the billingPostalAddress property in' + ResponseText);
        Assert.AreNotEqual('', JSONAddressValue, 'billingPostalAddress should not be blank in ' + ResponseText);

        if EmptyData then begin
            AssertSalesDocumentSellToAddress(SalesHeader, '', '', '', '', '', '');
            exit;
        end;

        if PartiallyEmptyData then
            AssertSalesDocumentSellToAddress(SalesHeader, Customer.Address, Customer."Address 2", '', '', Customer."Country/Region Code", '')
        else
            AssertSalesDocumentSellToAddress(SalesHeader, Customer.Address, Customer."Address 2", Customer.City, Customer.County, Customer."Country/Region Code", Customer."Post Code");
    end;

    [Scope('OnPrem')]
    procedure VerifySalesDocumentSellToAddress(Customer: Record Customer; SalesHeader: Record "Sales Header"; ResponseText: Text; EmptyData: Boolean; PartiallyEmptyData: Boolean)
    var
        JSONManagement: Codeunit "JSON Management";
        JObject: DotNet JObject;
        JSONAddressValue: Text;
    begin
        JSONManagement.InitializeObject(ResponseText);
        JSONManagement.GetJSONObject(JObject);
        Assert.IsTrue(JSONManagement.GetStringPropertyValueFromJObjectByName(JObject, 'sellingPostalAddress', JSONAddressValue),
          'Could not find the sellingPostalAddress property in' + ResponseText);
        Assert.AreNotEqual('', JSONAddressValue, 'sellingPostalAddress should not be blank in ' + ResponseText);

        CheckSalesDocumentSellToAddress(Customer, SalesHeader, EmptyData, PartiallyEmptyData);
    end;

    [Scope('OnPrem')]
    procedure CheckSalesDocumentSellToAddress(Customer: Record Customer; SalesHeader: Record "Sales Header"; EmptyData: Boolean; PartiallyEmptyData: Boolean)
    begin
        if EmptyData then
            AssertSalesDocumentSellToAddress(SalesHeader, '', '', '', '', '', '')
        else
            if PartiallyEmptyData then
                AssertSalesDocumentSellToAddress(SalesHeader, Customer.Address, Customer."Address 2", '', '', Customer."Country/Region Code", '')
            else
                AssertSalesDocumentSellToAddress(SalesHeader, Customer.Address, Customer."Address 2", Customer.City, Customer.County, Customer."Country/Region Code", Customer."Post Code");
    end;

    [Scope('OnPrem')]
    procedure VerifySalesDocumentBillToAddress(Customer: Record Customer; SalesHeader: Record "Sales Header"; ResponseText: Text; EmptyData: Boolean; PartiallyEmptyData: Boolean)
    var
        JSONManagement: Codeunit "JSON Management";
        JObject: DotNet JObject;
        JSONAddressValue: Text;
    begin
        JSONManagement.InitializeObject(ResponseText);
        JSONManagement.GetJSONObject(JObject);
        Assert.IsTrue(JSONManagement.GetStringPropertyValueFromJObjectByName(JObject, 'billingPostalAddress', JSONAddressValue),
          'Could not find the billingPostalAddress property in' + ResponseText);
        Assert.AreNotEqual('', JSONAddressValue, 'billingPostalAddress should not be blank in ' + ResponseText);

        CheckSalesDocumentBillToAddress(Customer, SalesHeader, EmptyData, PartiallyEmptyData);
    end;

    [Scope('OnPrem')]
    procedure CheckSalesDocumentBillToAddress(Customer: Record Customer; SalesHeader: Record "Sales Header"; EmptyData: Boolean; PartiallyEmptyData: Boolean)
    begin
        if EmptyData then
            AssertSalesDocumentBillToAddress(SalesHeader, '', '', '', '', '', '')
        else
            if PartiallyEmptyData then
                AssertSalesDocumentBillToAddress(SalesHeader, Customer.Address, Customer."Address 2", '', '', Customer."Country/Region Code", '')
            else
                AssertSalesDocumentBillToAddress(SalesHeader, Customer.Address, Customer."Address 2", Customer.City, Customer.County, Customer."Country/Region Code", Customer."Post Code");
    end;

    [Scope('OnPrem')]
    procedure VerifySalesDocumentShipToAddress(Customer: Record Customer; SalesHeader: Record "Sales Header"; ResponseText: Text; EmptyData: Boolean; PartiallyEmptyData: Boolean)
    var
        JSONManagement: Codeunit "JSON Management";
        JObject: DotNet JObject;
        JSONAddressValue: Text;
    begin
        JSONManagement.InitializeObject(ResponseText);
        JSONManagement.GetJSONObject(JObject);
        Assert.IsTrue(JSONManagement.GetStringPropertyValueFromJObjectByName(JObject, 'shippingPostalAddress', JSONAddressValue),
          'Could not find the shippingPostalAddress property in' + ResponseText);
        Assert.AreNotEqual('', JSONAddressValue, 'shippingPostalAddress should not be blank in ' + ResponseText);

        CheckSalesDocumentShipToAddress(Customer, SalesHeader, EmptyData, PartiallyEmptyData);
    end;

    [Scope('OnPrem')]
    procedure CheckSalesDocumentShipToAddress(Customer: Record Customer; SalesHeader: Record "Sales Header"; EmptyData: Boolean; PartiallyEmptyData: Boolean)
    begin
        if EmptyData then
            AssertSalesDocumentShipToAddress(SalesHeader, '', '', '', '', '', '')
        else
            if PartiallyEmptyData then
                AssertSalesDocumentShipToAddress(SalesHeader, Customer.Address, Customer."Address 2", '', '', Customer."Country/Region Code", '')
            else
                AssertSalesDocumentShipToAddress(SalesHeader, Customer.Address, Customer."Address 2", Customer.City, Customer.County, Customer."Country/Region Code", Customer."Post Code");
    end;

    [Scope('OnPrem')]
    procedure VerifyPurchaseDocumentBuyFromAddress(Vendor: Record Vendor; PurchaseHeader: Record "Purchase Header"; ResponseText: Text; EmptyData: Boolean; PartiallyEmptyData: Boolean)
    var
        JSONManagement: Codeunit "JSON Management";
        JObject: DotNet JObject;
        JSONAddressValue: Text;
    begin
        JSONManagement.InitializeObject(ResponseText);
        JSONManagement.GetJSONObject(JObject);
        Assert.IsTrue(JSONManagement.GetStringPropertyValueFromJObjectByName(JObject, 'buyFromAddress', JSONAddressValue),
          'Could not find the buyFromAddress property in' + ResponseText);
        Assert.AreNotEqual('', JSONAddressValue, 'buyFromAddress should not be blank in ' + ResponseText);

        CheckPurchaseDocumentBuyFromAddress(Vendor, PurchaseHeader, EmptyData, PartiallyEmptyData)
    end;

    [Scope('OnPrem')]
    procedure CheckPurchaseDocumentBuyFromAddress(Vendor: Record Vendor; PurchaseHeader: Record "Purchase Header"; EmptyData: Boolean; PartiallyEmptyData: Boolean)
    begin
        if EmptyData then
            AssertPurchaseDocumentBuyFromAddress(PurchaseHeader, '', '', '', '', '', '')
        else
            if PartiallyEmptyData then
                AssertPurchaseDocumentBuyFromAddress(PurchaseHeader, Vendor.Address, Vendor."Address 2", '', '', Vendor."Country/Region Code", '')
            else
                AssertPurchaseDocumentBuyFromAddress(PurchaseHeader, Vendor.Address, Vendor."Address 2", Vendor.City, Vendor.County, Vendor."Country/Region Code", Vendor."Post Code");
    end;

    [Scope('OnPrem')]
    procedure VerifyPurchaseDocumentPayToAddress(Vendor: Record Vendor; PurchaseHeader: Record "Purchase Header"; ResponseText: Text; EmptyData: Boolean; PartiallyEmptyData: Boolean)
    var
        JSONManagement: Codeunit "JSON Management";
        JObject: DotNet JObject;
        JSONAddressValue: Text;
    begin
        JSONManagement.InitializeObject(ResponseText);
        JSONManagement.GetJSONObject(JObject);
        Assert.IsTrue(JSONManagement.GetStringPropertyValueFromJObjectByName(JObject, 'payToAddress', JSONAddressValue),
          'Could not find the payToAddress property in' + ResponseText);
        Assert.AreNotEqual('', JSONAddressValue, 'payToAddress should not be blank in ' + ResponseText);

        CheckPurchaseDocumentPayToAddress(Vendor, PurchaseHeader, EmptyData, PartiallyEmptyData)
    end;

    [Scope('OnPrem')]
    procedure CheckPurchaseDocumentPayToAddress(Vendor: Record Vendor; PurchaseHeader: Record "Purchase Header"; EmptyData: Boolean; PartiallyEmptyData: Boolean)
    begin
        if EmptyData then
            AssertPurchaseDocumentPayToAddress(PurchaseHeader, '', '', '', '', '', '')
        else
            if PartiallyEmptyData then
                AssertPurchaseDocumentPayToAddress(PurchaseHeader, Vendor.Address, Vendor."Address 2", '', '', Vendor."Country/Region Code", '')
            else
                AssertPurchaseDocumentPayToAddress(PurchaseHeader, Vendor.Address, Vendor."Address 2", Vendor.City, Vendor.County, Vendor."Country/Region Code", Vendor."Post Code");
    end;

    [Scope('OnPrem')]
    procedure VerifyPurchaseDocumentShipToAddress(Vendor: Record Vendor; PurchaseHeader: Record "Purchase Header"; ResponseText: Text; EmptyData: Boolean; PartiallyEmptyData: Boolean)
    var
        JSONManagement: Codeunit "JSON Management";
        JObject: DotNet JObject;
        JSONAddressValue: Text;
    begin
        JSONManagement.InitializeObject(ResponseText);
        JSONManagement.GetJSONObject(JObject);
        Assert.IsTrue(JSONManagement.GetStringPropertyValueFromJObjectByName(JObject, 'shipToAddress', JSONAddressValue),
          'Could not find the shipToAddress property in' + ResponseText);
        Assert.AreNotEqual('', JSONAddressValue, 'shipToAddress should not be blank in ' + ResponseText);

        CheckPurchaseDocumentShipToAddress(Vendor, PurchaseHeader, EmptyData, PartiallyEmptyData)
    end;

    [Scope('OnPrem')]
    procedure CheckPurchaseDocumentShipToAddress(Vendor: Record Vendor; PurchaseHeader: Record "Purchase Header"; EmptyData: Boolean; PartiallyEmptyData: Boolean)
    begin
        if EmptyData then
            AssertPurchaseDocumentShipToAddress(PurchaseHeader, '', '', '', '', '', '')
        else
            if PartiallyEmptyData then
                AssertPurchaseDocumentShipToAddress(PurchaseHeader, Vendor.Address, Vendor."Address 2", '', '', Vendor."Country/Region Code", '')
            else
                AssertPurchaseDocumentShipToAddress(PurchaseHeader, Vendor.Address, Vendor."Address 2", Vendor.City, Vendor.County, Vendor."Country/Region Code", Vendor."Post Code");
    end;

    [Scope('OnPrem')]
    procedure CreateSalesLinesWithAllPossibleTypes(var SalesHeader: Record "Sales Header")
    var
        SalesLineFixedAsset: Record "Sales Line";
        SalesLineCharge: Record "Sales Line";
        SalesLineResource: Record "Sales Line";
        SalesLineComment: Record "Sales Line";
        SalesLineGLAccount: Record "Sales Line";
        ItemCharge: Record "Item Charge";
        Resource: Record Resource;
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        FixedAsset: Record "Fixed Asset";
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryInventory.CreateItemCharge(ItemCharge);
        LibrarySales.CreateSalesLine(SalesLineCharge, SalesHeader, SalesLineCharge.Type::"Charge (Item)", ItemCharge."No.", 1);

        LibraryERM.FindVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryResource.CreateResource(Resource, VATBusinessPostingGroup.Code);
        VATPostingSetup.SetRange("VAT Bus. Posting Group", SalesHeader."VAT Bus. Posting Group");
        VATPostingSetup.SetRange("VAT Prod. Posting Group", Resource."VAT Prod. Posting Group");
        if not VATPostingSetup.FINDFIRST() then
            LibraryERM.CreateVATPostingSetup(VATPostingSetup, SalesHeader."VAT Bus. Posting Group", Resource."VAT Prod. Posting Group");
        LibrarySales.CreateSalesLine(SalesLineResource, SalesHeader, SalesLineResource.Type::Resource, Resource."No.", 1);

        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        LibrarySales.CreateSalesLine(SalesLineFixedAsset, SalesHeader, SalesLineFixedAsset.Type::"Fixed Asset", FixedAsset."No.", 1);

        LibrarySales.CreateSalesLineSimple(SalesLineComment, SalesHeader);
        SalesLineComment.Type := SalesLineComment.Type::" ";
        SalesLineComment.Description := 'Thank you for your business!';
        SalesLineComment.Modify();

        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        LibrarySales.CreateSalesLine(SalesLineGLAccount, SalesHeader, SalesLineGLAccount.Type::"G/L Account", GLAccount."No.", 1);
    end;

    [Scope('OnPrem')]
    procedure CreatePurchaseLinesWithAllPossibleTypes(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLineFixedAsset: Record "Purchase Line";
        PurchaseLineCharge: Record "Purchase Line";
        PurchaseLineComment: Record "Purchase Line";
        PurchaseLineGLAccount: Record "Purchase Line";
        ItemCharge: Record "Item Charge";
        FixedAsset: Record "Fixed Asset";
        GLAccount: Record "G/L Account";
    begin
        LibraryInventory.CreateItemCharge(ItemCharge);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLineCharge, PurchaseHeader, PurchaseLineCharge.Type::"Charge (Item)", ItemCharge."No.", 1);

        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLineFixedAsset, PurchaseHeader, PurchaseLineFixedAsset.Type::"Fixed Asset", FixedAsset."No.", 1);

        LibraryPurchase.CreatePurchaseLineSimple(PurchaseLineComment, PurchaseHeader);
        PurchaseLineComment.Type := PurchaseLineComment.Type::" ";
        PurchaseLineComment.Description := 'Thank you for your business!';
        PurchaseLineComment.Modify();

#pragma warning disable AA0210
        GLAccount.SetRange("Account Type", GLAccount."Account Type"::Posting);
        GLAccount.SetRange("Direct Posting", true);
#pragma warning restore AA0210
        GLAccount.FindFirst();
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLineGLAccount, PurchaseHeader, PurchaseLineGLAccount.Type::"G/L Account", GLAccount."No.", 1);
    end;

    [Scope('OnPrem')]
    procedure VerifySalesObjectTxtDescription(SalesLine: Record "Sales Line"; JObjectTxt: Text)
    var
        JSONManagement: Codeunit "JSON Management";
        JsonObject: DotNet JObject;
    begin
        JSONManagement.InitializeObject(JObjectTxt);
        JSONManagement.GetJSONObject(JsonObject);
        VerifySalesObjectDescription(SalesLine, JsonObject);
    end;

    [Scope('OnPrem')]
    procedure VerifySalesObjectTxtDescriptionWithoutComplexTypes(SalesLine: Record "Sales Line"; JObjectTxt: Text)
    var
        JSONManagement: Codeunit "JSON Management";
        JsonObject: DotNet JObject;
    begin
        JSONManagement.InitializeObject(JObjectTxt);
        JSONManagement.GetJSONObject(JsonObject);
        VerifySalesObjectTypeAndSequence(SalesLine, JsonObject);
    end;

    [Scope('OnPrem')]
    procedure VerifySalesObjectDescription(var SalesLine: Record "Sales Line"; var JObject: DotNet JObject)
    var
        JSONManagement: Codeunit "JSON Management";
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
        objectDetailsTxt: Text;
        No: Code[20];
        Description: Text[50];
        Name: Text[100];
    begin
        JSONManagement.InitializeObjectFromJObject(JObject);

        VerifySalesObjectTypeAndSequence(SalesLine, JObject);

        Assert.IsTrue(
          JSONManagement.GetStringPropertyValueFromJObjectByName(JObject, LineDetailsFieldNameTxt, objectDetailsTxt),
          'Could not find ' + LineDetailsFieldNameTxt);

        case SalesLine.Type of
            SalesLine.Type::" ":
                Assert.AreEqual('', objectDetailsTxt, 'Object details text should be blank for comments');
            else begin
                GraphMgtComplexTypes.ParseDocumentLineObjectDetailsFromJSON(objectDetailsTxt, No, Name, Description);
                Assert.AreEqual(SalesLine."No.", No, 'Wrong no. value');
                Assert.AreEqual(SalesLine.Description, Name, 'Wrong name value');
            end;
        end;
    end;

    local procedure VerifySalesObjectTypeAndSequence(SalesLine: Record "Sales Line"; JObject: Dotnet JObject)
    var
        SalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate";
        JSONManagement: Codeunit "JSON Management";
        sequenceTxt: Text;
        objectTypeTxt: Text;
        xmlConvert: DotNet XmlConvert;
    begin
        Assert.IsTrue(JSONManagement.GetStringPropertyValueFromJObjectByName(JObject, 'sequence', sequenceTxt), 'Could not find sequence');
        Assert.IsTrue(
          JSONManagement.GetStringPropertyValueFromJObjectByName(JObject, LineTypeFieldNameTxt, objectTypeTxt),
          'Could not find ' + LineTypeFieldNameTxt);

        SalesInvoiceLineAggregate."API Type" := SalesLine.Type;
        Assert.AreEqual(xmlConvert.DecodeName(objectTypeTxt), Format(SalesInvoiceLineAggregate."API Type"), 'Wrong value for the API Type');
        Assert.AreEqual(sequenceTxt, Format(SalesLine."Line No."), 'Wrong value for Line No.');
    end;

    [Scope('OnPrem')]
    procedure VerifyPurchaseObjectTxtDescription(PurchaseLine: Record "Purchase Line"; JObjectTxt: Text)
    var
        JSONManagement: Codeunit "JSON Management";
        JsonObject: DotNet JObject;
    begin
        JSONManagement.InitializeObject(JObjectTxt);
        JSONManagement.GetJSONObject(JsonObject);
        VerifyPurchaseObjectDescription(PurchaseLine, JsonObject);
    end;

    [Scope('OnPrem')]
    procedure VerifyPurchaseObjectTxtDescriptionWithoutComplexType(PurchaseLine: Record "Purchase Line"; JObjectTxt: Text)
    var
        JSONManagement: Codeunit "JSON Management";
        JsonObject: DotNet JObject;
    begin
        JSONManagement.InitializeObject(JObjectTxt);
        JSONManagement.GetJSONObject(JsonObject);
        VerifyPurchaseObjectTypeAndSequence(PurchaseLine, JsonObject);
    end;

    [Scope('OnPrem')]
    procedure VerifyPurchaseObjectDescription(var PurchaseLine: Record "Purchase Line"; var JObject: DotNet JObject)
    var
        JSONManagement: Codeunit "JSON Management";
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
        objectDetailsTxt: Text;
        No: Code[20];
        Description: Text[50];
        Name: Text[100];
    begin
        JSONManagement.InitializeObjectFromJObject(JObject);

        VerifyPurchaseObjectTypeAndSequence(PurchaseLine, JObject);

        Assert.IsTrue(
          JSONManagement.GetStringPropertyValueFromJObjectByName(JObject, LineDetailsFieldNameTxt, objectDetailsTxt),
          'Could not find ' + LineDetailsFieldNameTxt);

        case PurchaseLine.Type of
            PurchaseLine.Type::" ":
                Assert.AreEqual('', objectDetailsTxt, 'Object details text should be blank for comments');
            else begin
                GraphMgtComplexTypes.ParseDocumentLineObjectDetailsFromJSON(objectDetailsTxt, No, Name, Description);
                Assert.AreEqual(PurchaseLine."No.", No, 'Wrong no. value');
                Assert.AreEqual(PurchaseLine.Description, Name, 'Wrong name value');
            end;
        end;
    end;

    local procedure VerifyPurchaseObjectTypeAndSequence(PurchaseLine: Record "Purchase Line"; JObject: Dotnet JObject)
    var
        PurchInvLineAggregate: Record "Purch. Inv. Line Aggregate";
        JSONManagement: Codeunit "JSON Management";
        sequenceTxt: Text;
        objectTypeTxt: Text;
        xmlConvert: DotNet XmlConvert;
    begin
        Assert.IsTrue(JSONManagement.GetStringPropertyValueFromJObjectByName(JObject, 'sequence', sequenceTxt), 'Could not find sequence');
        Assert.IsTrue(
          JSONManagement.GetStringPropertyValueFromJObjectByName(JObject, LineTypeFieldNameTxt, objectTypeTxt),
          'Could not find ' + LineTypeFieldNameTxt);
        PurchInvLineAggregate."API Type" := PurchaseLine.Type;
        Assert.AreEqual(xmlConvert.DecodeName(objectTypeTxt), Format(PurchInvLineAggregate."API Type"), 'Wrong value for the API Type');
        Assert.AreEqual(sequenceTxt, Format(PurchaseLine."Line No."), 'Wrong value for Line No.');
    end;

    [Scope('OnPrem')]
    procedure VerifySalesIdsSetFromTxt(SalesLine: Record "Sales Line"; JObjectTxt: Text)
    var
        JSONManagement: Codeunit "JSON Management";
        JsonObject: DotNet JObject;
    begin
        JSONManagement.InitializeObject(JObjectTxt);
        JSONManagement.GetJSONObject(JsonObject);
        VerifySalesIdsSet(SalesLine, JsonObject);
    end;

    [Scope('OnPrem')]
    procedure VerifyPurchaseIdsSetFromTxt(PurchaseLine: Record "Purchase Line"; JObjectTxt: Text)
    var
        JSONManagement: Codeunit "JSON Management";
        JsonObject: DotNet JObject;
    begin
        JSONManagement.InitializeObject(JObjectTxt);
        JSONManagement.GetJSONObject(JsonObject);
        VerifyPurchaseIdsSet(PurchaseLine, JsonObject);
    end;

    [Scope('OnPrem')]
    procedure VerifySalesIdsSet(var SalesLine: Record "Sales Line"; var JObject: DotNet JObject)
    var
        Item: Record Item;
        GLAccount: Record "G/L Account";
        itemId: Text;
        accountId: Text;
        ExpectedItemId: Text;
        ExpectedAccountId: Text;
        BlankGuid: Guid;
    begin
        ExpectedItemId := GraphMgtGeneralTools.GetIdWithoutBrackets(BlankGuid);
        ExpectedAccountId := ExpectedItemId;

        VerifyIdsSet(JObject, itemId, accountId);

        case SalesLine.Type of
            SalesLine.Type::Item:
                begin
                    Item.Get(SalesLine."No.");
                    ExpectedItemId := GraphMgtGeneralTools.GetIdWithoutBrackets(Item.SystemId);
                    Assert.AreNotEqual(ExpectedAccountId, ExpectedItemId, 'Account and Item Id cannot be same');
                end;
            SalesLine.Type::"G/L Account":
                begin
                    GLAccount.Get(SalesLine."No.");
                    ExpectedAccountId := GraphMgtGeneralTools.GetIdWithoutBrackets(GLAccount.SystemId);
                    Assert.AreNotEqual(ExpectedAccountId, ExpectedItemId, 'Account and Item Id cannot be same');
                end;
        end;

        Assert.AreEqual(UpperCase(ExpectedAccountId), UpperCase(accountId), 'Wrong account id');
        Assert.AreEqual(UpperCase(ExpectedItemId), UpperCase(itemId), 'Wrong item id');
    end;

    [Scope('OnPrem')]
    procedure VerifyPurchaseIdsSet(var PurchaseLine: Record "Purchase Line"; var JObject: DotNet JObject)
    var
        Item: Record Item;
        GLAccount: Record "G/L Account";
        itemId: Text;
        accountId: Text;
        ExpectedItemId: Text;
        ExpectedAccountId: Text;
        BlankGuid: Guid;
    begin
        ExpectedItemId := GraphMgtGeneralTools.GetIdWithoutBrackets(BlankGuid);
        ExpectedAccountId := ExpectedItemId;

        VerifyIdsSet(JObject, itemId, accountId);

        case PurchaseLine.Type of
            PurchaseLine.Type::Item:
                begin
                    Item.Get(PurchaseLine."No.");
                    ExpectedItemId := GraphMgtGeneralTools.GetIdWithoutBrackets(Item.SystemId);
                    Assert.AreNotEqual(ExpectedAccountId, ExpectedItemId, 'Account and Item Id cannot be same');
                end;
            PurchaseLine.Type::"G/L Account":
                begin
                    GLAccount.Get(PurchaseLine."No.");
                    ExpectedAccountId := GraphMgtGeneralTools.GetIdWithoutBrackets(GLAccount.SystemId);
                    Assert.AreNotEqual(ExpectedAccountId, ExpectedItemId, 'Account and Item Id cannot be same');
                end;
        end;

        Assert.AreEqual(UpperCase(ExpectedAccountId), UpperCase(accountId), 'Wrong account id');
        Assert.AreEqual(UpperCase(ExpectedItemId), UpperCase(itemId), 'Wrong item id');
    end;

    [Scope('OnPrem')]
    procedure VerifyIdsSet(var JObject: DotNet JObject; var ItemId: Text; var AccountId: Text)
    var
        JSONManagement: Codeunit "JSON Management";
    begin
        JSONManagement.InitializeObjectFromJObject(JObject);

        Assert.IsTrue(JSONManagement.GetStringPropertyValueFromJObjectByName(JObject, 'itemId', ItemId), 'Could not find itemId');
        Assert.IsTrue(JSONManagement.GetStringPropertyValueFromJObjectByName(JObject, 'accountId', AccountId), 'Could not find accountId');
    end;

    [Scope('OnPrem')]
    procedure VerifyValidDiscountAmount(ResponseText: Text; ExpectedDiscountAmount: Decimal)
    var
        JSONManagement: Codeunit "JSON Management";
        JsonObject: DotNet JObject;
        ActualInvoiceDiscountAmount: Decimal;
    begin
        JSONManagement.InitializeObject(ResponseText);
        JSONManagement.GetJSONObject(JsonObject);
        Assert.IsTrue(
          JSONManagement.GetDecimalPropertyValueFromJObjectByName(JsonObject, DiscountAmountFieldTxt, ActualInvoiceDiscountAmount),
          'Could not find the invoice discount amount in the response');
        Assert.AreEqual(ExpectedDiscountAmount, ActualInvoiceDiscountAmount, 'Invoice discount amount was not set');
    end;
}

