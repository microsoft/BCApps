codeunit 144008 "UT COD Address"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Address]
    end;

    var
        LibraryUTUtility: Codeunit "Library UT Utility";
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CityCountyPostCodeFormatAddress()
    var
        Customer: Record Customer;
        CountryRegion: Record "Country/Region";
        FormatAddress: Codeunit "Format Address";
        AddressArray: array[8] of Text[90];
        CityCountyPostCode: Text[90];
    begin
        // Purpose of the test is to validate FormatAddr Function of Codeunit 365 - Format Address.

        // Setup: Create Country Region Address Format Type - City+County+Post Code. Create Customer.
        Initialize();
        CreateCustomer(Customer, CreateCountryRegion(CountryRegion."Address Format"::"City+County+Post Code"));
        CityCountyPostCode := Customer.City + ', ' + Customer.County + ' ' + Customer."Post Code";  // Calculation is based on Address Format Type - City+County+Post Code.

        // Exercise.
        FormatAddress.FormatAddr(
          AddressArray, Customer.Name, '', '', Customer.Address, '', Customer.City, Customer."Post Code", Customer.County,
          Customer."Country/Region Code");  // Blank values for - Second Name, Contact, and Second Address.

        // Verify: Verify Name, Address field of Customer and combined Postal Address(City + County + Post Code) with Address Array.
        VerifyCustomerPostalAddress(Customer, AddressArray, CityCountyPostCode);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CityCountyNewLinePostCodeFormatAddress()
    var
        Customer: Record Customer;
        CountryRegion: Record "Country/Region";
        FormatAddress: Codeunit "Format Address";
        AddressArray: array[8] of Text[90];
        CityCounty: Text[90];
    begin
        // Purpose of the test is to validate FormatAddr Function of Codeunit 365 - Format Address.

        // Setup: Create Country Region Address Format Type - City+County+New Line+Post Code. Create Customer.
        Initialize();
        CreateCustomer(Customer, CreateCountryRegion(CountryRegion."Address Format"::"City+County+New Line+Post Code"));
        CityCounty := Customer.City + ', ' + Customer.County;  // Calculation is based on Address Format Type - City+County+New Line+Post Code.

        // Exercise.
        FormatAddress.FormatAddr(
          AddressArray, Customer.Name, '', '', Customer.Address, '', Customer.City, Customer."Post Code", Customer.County,
          Customer."Country/Region Code");  // Blank values for - Second Name, Contact, and Second Address.

        // Verify: Verify Name, Address, Post Code field of Customer and combined Postal Address(City + County) Address Array.
        VerifyCustomerPostalAddress(Customer, AddressArray, CityCounty);
        Customer.TestField("Post Code", AddressArray[4]);  // Post Code of Customer placed on position AddressArray[4] for format Type - City+County+New Line+Post Code.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PostCodeCityCountyFormatAddress()
    var
        Customer: Record Customer;
        CountryRegion: Record "Country/Region";
        FormatAddress: Codeunit "Format Address";
        AddressArray: array[8] of Text[90];
        PostCodeCityCounty: Text[90];
    begin
        // Purpose of the test is to validate FormatAddr Function of Codeunit 365 - Format Address.

        // Setup: Create Country Region Address Format Type - Post Code+City+County. Create Customer.
        Initialize();
        CreateCustomer(Customer, CreateCountryRegion(CountryRegion."Address Format"::"Post Code+City+County"));
        PostCodeCityCounty := Customer."Post Code" + ' ' + Customer.City + ', ' + Customer.County;  // Calculation is based on Address Format Type - Post Code+City+County.

        // Exercise.
        FormatAddress.FormatAddr(
          AddressArray, Customer.Name, '', '', Customer.Address, '', Customer.City, Customer."Post Code", Customer.County,
          Customer."Country/Region Code");  // Blank values for - Second Name, Contact, and Second Address.

        // Verify: Verify Name, Address field of Customer and combined Postal Address(Post Code + City + County) with Address Array.
        VerifyCustomerPostalAddress(Customer, AddressArray, PostCodeCityCounty);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TransferShptTransferFromFormatAddress()
    var
        TransferShipmentHeader: Record "Transfer Shipment Header";
        FormatAddress: Codeunit "Format Address";
        AddressArray: array[8] of Text[90];
    begin
        // Purpose of the test is to validate TransferShptTransferFrom Function of Codeunit 365 - Format Address.

        // Setup: Create Transfer Shipment Header.
        Initialize();
        CreateTransferShipmentHeader(TransferShipmentHeader);

        // Exercise.
        FormatAddress.TransferShptTransferFrom(AddressArray, TransferShipmentHeader);

        // Verify: Verify Transfer From Name and Transfer From Address field of Transfer Shipment Header Table with Address Array.
        TransferShipmentHeader.TestField("Transfer-from Name", AddressArray[1]);
        TransferShipmentHeader.TestField("Transfer-from Address", AddressArray[2]);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TransferShptTransferToFormatAddress()
    var
        TransferShipmentHeader: Record "Transfer Shipment Header";
        FormatAddress: Codeunit "Format Address";
        AddressArray: array[8] of Text[90];
    begin
        // Purpose of the test is to validate TransferShptTransferTo Function of Codeunit 365 - Format Address.

        // Setup: Create Transfer Shipment Header.
        Initialize();
        CreateTransferShipmentHeader(TransferShipmentHeader);

        // Exercise.
        FormatAddress.TransferShptTransferTo(AddressArray, TransferShipmentHeader);

        // Verify: Verify Transfer To Name and Transfer To Address field of Transfer Shipment Header Table with Address Array.
        TransferShipmentHeader.TestField("Transfer-to Name", AddressArray[1]);
        TransferShipmentHeader.TestField("Transfer-to Address", AddressArray[2]);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TransferRcptTransferFromFormatAddress()
    var
        TransferReceiptHeader: Record "Transfer Receipt Header";
        FormatAddress: Codeunit "Format Address";
        AddressArray: array[8] of Text[90];
    begin
        // Purpose of the test is to validate TransferRcptTransferFrom Function of Codeunit 365 - Format Address.

        // Setup: Create Transfer Receipt Header.
        Initialize();
        CreateTransferReceiptHeader(TransferReceiptHeader);

        // Exercise.
        FormatAddress.TransferRcptTransferFrom(AddressArray, TransferReceiptHeader);

        // Verify: Verify Transfer From Name and Transfer From Address field of Transfer Receipt Header Table with Address Array.
        TransferReceiptHeader.TestField("Transfer-from Name", AddressArray[1]);
        TransferReceiptHeader.TestField("Transfer-from Address", AddressArray[2]);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TransferRcptTransferToFormatAddress()
    var
        TransferReceiptHeader: Record "Transfer Receipt Header";
        FormatAddress: Codeunit "Format Address";
        AddressArray: array[8] of Text[90];
    begin
        // Purpose of the test is to validate TransferRcptTransferTo Function of Codeunit 365 - Format Address.

        // Setup: Create Transfer Receipt Header.
        Initialize();
        CreateTransferReceiptHeader(TransferReceiptHeader);

        // Exercise.
        FormatAddress.TransferRcptTransferTo(AddressArray, TransferReceiptHeader);

        // Verify: Verify Transfer To Name and Transfer To Address field of Transfer Receipt Header Table with Address Array.
        TransferReceiptHeader.TestField("Transfer-to Name", AddressArray[1]);
        TransferReceiptHeader.TestField("Transfer-to Address", AddressArray[2]);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TransferHeaderTransferFromFormatAddress()
    var
        TransferHeader: Record "Transfer Header";
        FormatAddress: Codeunit "Format Address";
        AddressArray: array[8] of Text[90];
    begin
        // Purpose of the test is to validate TransferHeaderTransferFrom Function of Codeunit 365 - Format Address.

        // Setup: Create Transfer Header.
        Initialize();
        CreateTransferHeader(TransferHeader);

        // Exercise.
        FormatAddress.TransferHeaderTransferFrom(AddressArray, TransferHeader);

        // Verify: Verify Transfer From Name and Transfer From Address field of Transfer Header Table with Address Array.
        TransferHeader.TestField("Transfer-from Name", AddressArray[1]);
        TransferHeader.TestField("Transfer-from Address", AddressArray[2]);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TransferHeaderTransferToFormatAddress()
    var
        TransferHeader: Record "Transfer Header";
        FormatAddress: Codeunit "Format Address";
        AddressArray: array[8] of Text[90];
    begin
        // Purpose of the test is to validate TransferHeaderTransferTo Function of Codeunit 365 - Format Address.

        // Setup: Create Transfer Header.
        Initialize();
        CreateTransferHeader(TransferHeader);

        // Exercise.
        FormatAddress.TransferHeaderTransferTo(AddressArray, TransferHeader);

        // Verify: Verify Transfer To Name and Transfer To Address field of Transfer Header Table with Address Array.
        TransferHeader.TestField("Transfer-to Name", AddressArray[1]);
        TransferHeader.TestField("Transfer-to Address", AddressArray[2]);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateCustomer(var Customer: Record Customer; CountryRegionCode: Code[10])
    begin
        Customer."No." := LibraryUTUtility.GetNewCode();
        Customer.Name := LibraryUTUtility.GetNewCode();
        Customer.Address := LibraryUTUtility.GetNewCode();
        Customer.City := LibraryUTUtility.GetNewCode();
        Customer."Post Code" := LibraryUTUtility.GetNewCode();
        Customer.County := LibraryUTUtility.GetNewCode10();
        Customer."Country/Region Code" := CountryRegionCode;
        Customer.Insert();
    end;

    local procedure CreateCountryRegion(AddressFormat: Enum "Country/Region Address Format"): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        CountryRegion.Code := LibraryUTUtility.GetNewCode10();
        CountryRegion."Address Format" := AddressFormat;
        CountryRegion.Insert();
        exit(CountryRegion.Code);
    end;

    local procedure CreateTransferShipmentHeader(var TransferShipmentHeader: Record "Transfer Shipment Header")
    begin
        TransferShipmentHeader."No." := LibraryUTUtility.GetNewCode();
        TransferShipmentHeader."Transfer-from Name" := LibraryUTUtility.GetNewCode();
        TransferShipmentHeader."Transfer-from Address" := LibraryUTUtility.GetNewCode();
        TransferShipmentHeader."Transfer-to Name" := LibraryUTUtility.GetNewCode();
        TransferShipmentHeader."Transfer-to Address" := LibraryUTUtility.GetNewCode();
        TransferShipmentHeader.Insert();
    end;

    local procedure CreateTransferReceiptHeader(var TransferReceiptHeader: Record "Transfer Receipt Header")
    begin
        TransferReceiptHeader."No." := LibraryUTUtility.GetNewCode();
        TransferReceiptHeader."Transfer-from Name" := LibraryUTUtility.GetNewCode();
        TransferReceiptHeader."Transfer-from Address" := LibraryUTUtility.GetNewCode();
        TransferReceiptHeader."Transfer-to Name" := LibraryUTUtility.GetNewCode();
        TransferReceiptHeader."Transfer-to Address" := LibraryUTUtility.GetNewCode();
        TransferReceiptHeader.Insert();
    end;

    local procedure CreateTransferHeader(var TransferHeader: Record "Transfer Header")
    begin
        TransferHeader."No." := LibraryUTUtility.GetNewCode();
        TransferHeader."Transfer-from Name" := LibraryUTUtility.GetNewCode();
        TransferHeader."Transfer-from Address" := LibraryUTUtility.GetNewCode();
        TransferHeader."Transfer-to Name" := LibraryUTUtility.GetNewCode();
        TransferHeader."Transfer-to Address" := LibraryUTUtility.GetNewCode();
        TransferHeader.Insert();
    end;

    local procedure VerifyCustomerPostalAddress(Customer: Record Customer; AddressArray: array[8] of Text[90]; PostalAddress: Text[90])
    begin
        Customer.TestField(Name, AddressArray[1]);
        Customer.TestField(Address, AddressArray[2]);
        Assert.AreEqual(PostalAddress, AddressArray[3], 'Value must be Equal.');
    end;
}
