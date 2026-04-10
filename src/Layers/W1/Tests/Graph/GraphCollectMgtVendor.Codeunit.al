codeunit 134632 "Graph Collect Mgt Vendor"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Graph] [Vendor]
    end;

    var
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";

    [Test]
    [Scope('OnPrem')]
    procedure TestSetPostalAddress()
    var
        Vendor: Record Vendor;
        GraphMgtVendor: Codeunit "Graph Mgt - Vendor";
        PostalAddressJSON: Text;
        VendorNo: Code[20];
    begin
        // Setup
        FindVendorWithAddress(Vendor);
        VendorNo := Vendor."No.";
        PostalAddressJSON := GraphMgtVendor.PostalAddressToJSON(Vendor);

        // Execute
        Vendor.Get(VendorNo);
        GraphMgtVendor.UpdatePostalAddress(PostalAddressJSON, Vendor);
        Vendor.Modify(true);

        // Verify
        VerifyMatchingPostalAddress(PostalAddressJSON, Vendor);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetBlankPostalAddress()
    var
        Vendor: Record Vendor;
        GraphMgtVendor: Codeunit "Graph Mgt - Vendor";
    begin
        // Setup
        FindVendorWithAddress(Vendor);
        Vendor.Modify(true);

        // Execute
        GraphMgtVendor.UpdatePostalAddress('null', Vendor);
        Vendor.Modify(true);

        // Verify
        Vendor.TestField(Address, '');
        Vendor.TestField("Address 2", '');
        Vendor.TestField(City, '');
        Vendor.TestField(County, '');
        Vendor.TestField("Country/Region Code", '');
        Vendor.TestField("Post Code", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetInvalidPostalAddress()
    var
        Vendor: Record Vendor;
        GraphMgtVendor: Codeunit "Graph Mgt - Vendor";
        VendorNo: Code[20];
        InvalidCountryCode: Code[10];
        PostalAddressJSON: Text;
        ActualError: Text;
    begin
        // Setup
        FindVendorWithAddress(Vendor);
        InvalidCountryCode := 'abcd'; // Invalid country/region code
        Vendor."Country/Region Code" := InvalidCountryCode;
        VendorNo := Vendor."No.";
        PostalAddressJSON := GraphMgtVendor.PostalAddressToJSON(Vendor);

        // Execute
        Vendor.Get(VendorNo);
        asserterror GraphMgtVendor.UpdatePostalAddress(PostalAddressJSON, Vendor);

        ActualError := GetLastErrorText;

        // Verify
        asserterror Vendor.Validate("Country/Region Code", InvalidCountryCode);
        Assert.ExpectedError(ActualError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetSamePostalAddress()
    var
        Vendor: Record Vendor;
        GraphMgtVendor: Codeunit "Graph Mgt - Vendor";
        PostalAddressJSON: Text;
    begin
        // Setup
        FindVendorWithAddress(Vendor);
        Vendor.Modify(true);
        PostalAddressJSON := GraphMgtVendor.PostalAddressToJSON(Vendor);

        // Execute
        GraphMgtVendor.UpdatePostalAddress(PostalAddressJSON, Vendor);

        // Verify
        VerifyMatchingPostalAddress(PostalAddressJSON, Vendor);
    end;

    local procedure FindVendorWithAddress(var Vendor: Record Vendor)
    var
        CountryRegion: Record "Country/Region";
    begin
        Vendor.FindFirst();
        CountryRegion.FindLast();
        Vendor.Address := RandomCode10();
        Vendor."Address 2" := RandomCode10();
        Vendor.City := RandomCode10();
        Vendor.County := RandomCode10();
        Vendor."Country/Region Code" := CountryRegion.Code;
        Vendor."Post Code" := RandomCode10();
    end;

    local procedure RandomCode10(): Code[10]
    begin
        exit(LibraryUtility.GenerateGUID());
    end;

    local procedure VerifyMatchingPostalAddress(ActualJSON: Text; Vendor: Record Vendor)
    var
        TempVendor: Record Vendor temporary;
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
        RecRef: RecordRef;
    begin
        // Apply complex type JSON to TempVendor
        RecRef.GetTable(TempVendor);
        GraphMgtComplexTypes.ApplyPostalAddressFromJSON(ActualJSON, RecRef,
              TempVendor.FieldNo(Address), TempVendor.FieldNo("Address 2"), TempVendor.FieldNo(City), TempVendor.FieldNo(County), TempVendor.FieldNo("Country/Region Code"), TempVendor.FieldNo("Post Code"));
        RecRef.SetTable(TempVendor);
        // Verify Vendor fields match TempVendor fields (which were from the JSON)
        Vendor.TestField(Address, TempVendor.Address);
        Vendor.TestField("Address 2", TempVendor."Address 2");
        Vendor.TestField(City, TempVendor.City);
        Vendor.TestField(County, TempVendor.County);
        Vendor.TestField("Country/Region Code", TempVendor."Country/Region Code");
        Vendor.TestField("Post Code", TempVendor."Post Code");
    end;
}

