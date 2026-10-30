codeunit 134631 "Graph Collect Mgt Customer"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Graph] [Customer]
    end;

    var
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";

    [Test]
    [Scope('OnPrem')]
    procedure TestSetPostalAddress()
    var
        Customer: Record Customer;
        GraphMgtCustomer: Codeunit "Graph Mgt - Customer";
        PostalAddressJSON: Text;
        CustomerNo: Code[20];
    begin
        // Setup
        FindCustomerWithAddress(Customer);
        CustomerNo := Customer."No.";
        PostalAddressJSON := GraphMgtCustomer.PostalAddressToJSON(Customer);

        // Execute
        Customer.Get(CustomerNo);
        GraphMgtCustomer.UpdatePostalAddress(PostalAddressJSON, Customer);
        Customer.Modify(true);

        // Verify
        VerifyMatchingPostalAddress(PostalAddressJSON, Customer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetBlankPostalAddress()
    var
        Customer: Record Customer;
        GraphMgtCustomer: Codeunit "Graph Mgt - Customer";
    begin
        // Setup
        FindCustomerWithAddress(Customer);
        Customer.Modify(true);

        // Execute
        GraphMgtCustomer.UpdatePostalAddress('null', Customer);
        Customer.Modify(true);

        // Verify
        Customer.TestField(Address, '');
        Customer.TestField("Address 2", '');
        Customer.TestField(City, '');
        Customer.TestField(County, '');
        Customer.TestField("Country/Region Code", '');
        Customer.TestField("Post Code", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetInvalidPostalAddress()
    var
        Customer: Record Customer;
        GraphMgtCustomer: Codeunit "Graph Mgt - Customer";
        CustomerNo: Code[20];
        InvalidCountryCode: Code[10];
        PostalAddressJSON: Text;
        ActualError: Text;
    begin
        // Setup
        FindCustomerWithAddress(Customer);
        InvalidCountryCode := 'zq-v1'; // Invalid country/region code
        Customer."Country/Region Code" := InvalidCountryCode;
        CustomerNo := Customer."No.";
        PostalAddressJSON := GraphMgtCustomer.PostalAddressToJSON(Customer);

        // Execute
        Customer.Get(CustomerNo);
        asserterror GraphMgtCustomer.UpdatePostalAddress(PostalAddressJSON, Customer);
        ActualError := GetLastErrorText;

        // Verify
        asserterror Customer.Validate("Country/Region Code", InvalidCountryCode);
        Assert.ExpectedError(ActualError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetSamePostalAddress()
    var
        Customer: Record Customer;
        GraphMgtCustomer: Codeunit "Graph Mgt - Customer";
        PostalAddressJSON: Text;
    begin
        // Setup
        FindCustomerWithAddress(Customer);
        Customer.Modify(true);
        PostalAddressJSON := GraphMgtCustomer.PostalAddressToJSON(Customer);

        // Execute
        GraphMgtCustomer.UpdatePostalAddress(PostalAddressJSON, Customer);

        // Verify
        VerifyMatchingPostalAddress(PostalAddressJSON, Customer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestEmptyDimensionsJSON()
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
        NewDimensionSetId: Integer;
    begin
        NewDimensionSetId := 42;
        GraphMgtComplexTypes.GetDimensionSetFromJSON('', 0, NewDimensionSetId);

        Assert.AreEqual(0, NewDimensionSetId, 'Blank dimensions JSON must produce an empty dimension set.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateWebsiteAddsNewWebsiteWithAddress()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        WebsitesJson: JsonArray;
        WebsiteToken: JsonToken;
        AddressToken: JsonToken;
        WebsitesText: Text;
        WebsiteAddress: Text[80];
    begin
        // [SCENARIO] Updating a website that does not exist yet adds a website entry that carries the address
        WebsiteAddress := 'https://contoso.example/' + LibraryUtility.GenerateGUID();

        WebsitesText := GraphCollectionMgtContact.UpdateWorkWebsite('', WebsiteAddress);

        Assert.IsTrue(WebsitesJson.ReadFrom(WebsitesText), 'The websites collection must be a JSON array.');
        Assert.AreEqual(1, WebsitesJson.Count(), 'A single website must be added.');
        WebsitesJson.Get(0, WebsiteToken);
        Assert.IsTrue(WebsiteToken.AsObject().Get('Address', AddressToken), 'The added website must contain the address.');
        Assert.AreEqual(WebsiteAddress, AddressToken.AsValue().AsText(), 'The added website address is incorrect.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateWebsiteWithBlankAddressDoesNotAddWebsite()
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
    begin
        // [SCENARIO] Updating a missing website with a blank address leaves the collection empty
        Assert.AreEqual('[]', GraphCollectionMgtContact.UpdateHomeWebsite('', ''), 'No website must be added for a blank address.');
    end;

    local procedure FindCustomerWithAddress(var Customer: Record Customer)
    var
        CountryRegion: Record "Country/Region";
    begin
        Customer.FindFirst();
        CountryRegion.FindLast();
        Customer.Address := RandomCode10();
        Customer."Address 2" := RandomCode10();
        Customer.City := RandomCode10();
        Customer.County := RandomCode10();
        Customer."Country/Region Code" := CountryRegion.Code;
        Customer."Post Code" := RandomCode10();
    end;

    local procedure RandomCode10(): Code[10]
    begin
        exit(LibraryUtility.GenerateGUID());
    end;

    local procedure VerifyMatchingPostalAddress(ActualJSON: Text; Customer: Record Customer)
    var
        TempCustomer: Record Customer temporary;
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
        RecRef: RecordRef;
    begin
        // Apply complex type JSON to TempCustomer
        RecRef.GetTable(TempCustomer);
        GraphMgtComplexTypes.ApplyPostalAddressFromJSON(ActualJSON, RecRef,
              TempCustomer.FieldNo(Address), TempCustomer.FieldNo("Address 2"), TempCustomer.FieldNo(City), TempCustomer.FieldNo(County), TempCustomer.FieldNo("Country/Region Code"), TempCustomer.FieldNo("Post Code"));
        RecRef.SetTable(TempCustomer);
        // Verify Customer fields match TempCustomer fields (which were from the JSON)
        Customer.TestField(Address, TempCustomer.Address);
        Customer.TestField("Address 2", TempCustomer."Address 2");
        Customer.TestField(City, TempCustomer.City);
        Customer.TestField(County, TempCustomer.County);
        Customer.TestField("Country/Region Code", TempCustomer."Country/Region Code");
        Customer.TestField("Post Code", TempCustomer."Post Code");
    end;
}
