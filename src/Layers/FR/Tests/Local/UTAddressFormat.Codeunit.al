codeunit 144004 "UT Address Format"
{
    // 1-2. Purpose of the test is to verify Post Code and City and Country Region Code with and without blank line on Customer Address of Report ID - 206 Sales - Invoice.
    // 3-4. Purpose of the test is to verify Post Code and City and Local Address Format on General Ledger Setup with and without blank line on Customer Address of Report ID - 206 Sales - Invoice.
    // 5-7. Purpose of this test to verify Country Region Code on Customer Card,Vendor Card and Contact Card.
    // 8. Purpose of this test to verify Country Region Code is deleted on Country/Region table.
    //
    // Covers Test Cases for WI - 344970
    // ----------------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                                   TFS ID
    // ----------------------------------------------------------------------------------------------------------------------------
    // OnAfterGetRecAddrFormatPostCodeCity                                                                                  151133
    // OnAfterGetRecAddrFormatPostCodeCityGLSetup                                                                           151135
    // OnAfterGetRecAddrFormatBlankLinePostCodeCity                                                                         151132
    // OnAfterGetRecAddrFormatBlankLinePostCodeCityGLSetup                                                                  151134
    // OnAfterGetRecordCountryRegionCustomerCard,OnAfterGetRecordCountryRegionVendorCard
    // OnAfterGetRecordCountryRegionContactCard,OnDeleteCountryRegion

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        CountryRegionCodeErr: Label 'Country Region should not exist';

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCountryRegionCustomerCard()
    var
        CountryRegion: Record "Country/Region";
        Customer: Record Customer;
        CustomerCard: TestPage "Customer Card";
    begin
        // Purpose of this test to verify Country Region Code on Page - 21 Customer Card.

        // Setup: Create Customer with Country Region.
        Initialize();
        CreateCustomerWithCountryRegion(Customer, CreateCountryRegionCode(CountryRegion."Address Format"::"Post Code+City"));
        CustomerCard.OpenEdit();

        // Exercise.
        CustomerCard.FILTER.SetFilter("No.", Customer."No.");

        // Verify: Verify Country Region Code on Customer Card Page.
        CustomerCard."Country/Region Code".AssertEquals(Customer."Country/Region Code");
        CustomerCard.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCountryRegionVendorCard()
    var
        CountryRegion: Record "Country/Region";
        Vendor: Record Vendor;
        VendorCard: TestPage "Vendor Card";
    begin
        // Purpose of this test to verify Country Region Code on Page - 26 Vendor Card.

        // Setup: Create Vendor with Country Region.
        Initialize();
        CreateVendorWithCountryRegion(Vendor, CreateCountryRegionCode(CountryRegion."Address Format"::"Post Code+City"));
        VendorCard.OpenEdit();

        // Exercise.
        VendorCard.FILTER.SetFilter("No.", Vendor."No.");

        // Verify: Verify Country Region Code on Vendor Card Page.
        VendorCard."Country/Region Code".AssertEquals(Vendor."Country/Region Code");
        VendorCard.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCountryRegionContactCard()
    var
        Contact: Record Contact;
        CountryRegion: Record "Country/Region";
        ContactCard: TestPage "Contact Card";
    begin
        // Purpose of this test to verify Country Region Code on Page - 5050 Contact Card.

        // Setup: Create Contact with Country Region.
        Initialize();
        CreateContactWithCountryRegion(Contact, CreateCountryRegionCode(CountryRegion."Address Format"::"Post Code+City"));
        ContactCard.OpenEdit();

        // Exercise.
        ContactCard.FILTER.SetFilter("No.", Contact."No.");

        // Verify: Verify Country Region Code on Contact Card Page.
        ContactCard."Country/Region Code".AssertEquals(Contact."Country/Region Code");
        ContactCard.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnDeleteCountryRegion()
    var
        CountryRegion: Record "Country/Region";
        VATRegistrationNoFormat: Record "VAT Registration No. Format";
    begin
        // Purpose of this test to verify Country Region Code is deleted on Table - 9 Country/Region.

        // Setup: Create Country Region.
        Initialize();
        CountryRegion.Code := LibraryUTUtility.GetNewCode10();
        CountryRegion.Insert();

        // Exercise: Delete Country Region.
        CountryRegion.Delete(true);

        // Verify: Verify Country Region deleted.
        Assert.IsFalse(CountryRegion.Get(CountryRegion.Code), CountryRegionCodeErr);
        Assert.IsFalse(VATRegistrationNoFormat.Get(CountryRegion.Code), CountryRegionCodeErr);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateContactWithCountryRegion(var Contact: Record Contact; CountryRegionCode: Code[10])
    begin
        Contact."No." := LibraryUTUtility.GetNewCode();
        Contact.Address := LibraryUTUtility.GetNewCode();
        Contact."Address 2" := LibraryUTUtility.GetNewCode();
        Contact."Country/Region Code" := CountryRegionCode;
        Contact.County := LibraryUTUtility.GetNewCode();
        Contact."Post Code" := LibraryUTUtility.GetNewCode();
        Contact.City := LibraryUTUtility.GetNewCode();
        Contact.Insert();
    end;

    local procedure CreateCustomerWithCountryRegion(var Customer: Record Customer; CountryRegionCode: Code[10])
    begin
        Customer."No." := LibraryUTUtility.GetNewCode();
        Customer.Address := LibraryUTUtility.GetNewCode();
        Customer."Address 2" := LibraryUTUtility.GetNewCode();
        Customer."Country/Region Code" := CountryRegionCode;
        Customer.County := LibraryUTUtility.GetNewCode();
        Customer."Post Code" := LibraryUTUtility.GetNewCode();
        Customer.City := LibraryUTUtility.GetNewCode();
        Customer.Insert(true);
    end;

    local procedure CreateVendorWithCountryRegion(var Vendor: Record Vendor; CountryRegionCode: Code[10])
    begin
        Vendor."No." := LibraryUTUtility.GetNewCode();
        Vendor.Address := LibraryUTUtility.GetNewCode();
        Vendor."Address 2" := LibraryUTUtility.GetNewCode();
        Vendor."Country/Region Code" := CountryRegionCode;
        Vendor.County := LibraryUTUtility.GetNewCode();
        Vendor."Post Code" := LibraryUTUtility.GetNewCode();
        Vendor.City := LibraryUTUtility.GetNewCode();
        Vendor.Insert(true);
    end;

    local procedure CreateCountryRegionCode(AddressFormat: Enum "Country/Region Address Format"): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        CountryRegion.Code := LibraryUTUtility.GetNewCode10();
        CountryRegion."Address Format" := AddressFormat;
        CountryRegion.Insert();
        exit(CountryRegion.Code);
    end;
}
