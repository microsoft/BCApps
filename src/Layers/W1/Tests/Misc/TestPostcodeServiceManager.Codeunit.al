codeunit 139090 "Test Postcode Service Manager"
{
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Postcode Service] [UT]
    end;

    var
        TempEnteredAutocompleteAddressNameValueBuffer: Record "Autocomplete Address" temporary;
        TempAddressListNameValueBuffer: Record "Name/Value Buffer" temporary;
        Assert: Codeunit Assert;
        PostcodeServiceManager: Codeunit "Postcode Service Manager";
        PostcodeDummyService: Codeunit "Postcode Dummy Service";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";

    [Test]
    [Scope('OnPrem')]
    procedure TestDiscoverPostcodeServices()
    var
        TempServiceListNameValueBuffer: Record "Name/Value Buffer" temporary;
    begin
        // [SCENARIO] When DiscoverPostcodeServices event is raised, at least one (Dummy) service should respond

        // [GIVEN]
        Initialize();
        LibraryLowerPermissions.SetO365Basic();

        // [WHEN]
        PostcodeServiceManager.DiscoverPostcodeServices(TempServiceListNameValueBuffer);

        // [THEN] There should be at least one service registered
        Assert.RecordIsNotEmpty(TempServiceListNameValueBuffer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetAddressList()
    begin
        // [SCENARIO] A list of addresses should be retrieved from Dummy service when requested

        // [GIVEN]
        Initialize();
        LibraryLowerPermissions.SetO365Basic();

        // [WHEN]
        TempEnteredAutocompleteAddressNameValueBuffer.Postcode := '';
        PostcodeServiceManager.GetAddressList(TempEnteredAutocompleteAddressNameValueBuffer, TempAddressListNameValueBuffer);

        // [THEN]
        Assert.AreEqual(5, TempAddressListNameValueBuffer.Count, 'Address list was retrieved incorrectly.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetAddressDetails()
    var
        TempSelectedAddressNameValueBuffer: Record "Name/Value Buffer" temporary;
        TempAutocompleteAddress: Record "Autocomplete Address" temporary;
    begin
        // [SCENARIO] Test retrieval of address details when event GetAddress (specific) is raised

        // [GIVEN]
        // Set values that you want to get
        Initialize();
        LibraryLowerPermissions.SetO365Basic();
        TempAutocompleteAddress.Address := 'ADDRESS';
        TempAutocompleteAddress.Postcode := 'POSTCODE';

        // [WHEN]
        PostcodeServiceManager.GetAddress(
          TempSelectedAddressNameValueBuffer, TempEnteredAutocompleteAddressNameValueBuffer, TempAutocompleteAddress);

        // [THEN] There should be at least one service registered
        Assert.AreEqual('ADDRESS', TempAutocompleteAddress.Address, 'Retrieved address details are incorrect.');
        Assert.AreEqual('POSTCODE', TempAutocompleteAddress.Postcode, 'Retrieved address details are incorrect.');
    end;

    [Test]
    [HandlerFunctions('MessageDialogHandler')]
    [Scope('OnPrem')]
    procedure TestUnhandledErrorInPostcodeProvider()
    begin
        // [SCENARIO] In external service unhandled error occurs. Check that Postcode Service Manager catches is it and shows general error

        // [GIVEN]
        Initialize();
        LibraryLowerPermissions.SetO365Basic();
        LibraryVariableStorage.Enqueue('A general technical error occurred while contacting remote service.'); // Expected error message

        // [WHEN]
        TempEnteredAutocompleteAddressNameValueBuffer.Postcode := 'ERROR';
        PostcodeServiceManager.GetAddressList(TempEnteredAutocompleteAddressNameValueBuffer, TempAddressListNameValueBuffer);

        // [THEN] There should be at least one service registered
        // Assertion is done in the handler
    end;

    [Test]
    [HandlerFunctions('MessageDialogHandler')]
    [Scope('OnPrem')]
    procedure TestHandledErrorInPostcodeProvider()
    begin
        // [SCENARIO] Error occurs in a postcode but services handles it. Custom error should surface through Postcode Service Manager.

        // [GIVEN]
        Initialize();
        LibraryLowerPermissions.SetO365Basic();
        LibraryVariableStorage.Enqueue('Error from postcode service.'); // Expe

        // [WHEN]
        TempEnteredAutocompleteAddressNameValueBuffer.Postcode := 'ERROR HANDLED';
        PostcodeServiceManager.GetAddressList(TempEnteredAutocompleteAddressNameValueBuffer, TempAddressListNameValueBuffer);

        // [THEN] There should be at least one service registered
        // Assertion is done in the handler
    end;

    [Scope('OnPrem')]
    procedure Initialize()
    var
        PostcodeServiceConfig: Record "Postcode Service Config";
    begin
        Clear(PostcodeServiceManager);
        Clear(LibraryVariableStorage);
        Clear(TempEnteredAutocompleteAddressNameValueBuffer);
        // On first initialization
        if PostcodeServiceConfig.IsEmpty() then begin
            BindSubscription(PostcodeDummyService);

            PostcodeServiceConfig.Init();
            PostcodeServiceConfig.Insert();
            PostcodeServiceConfig.SaveServiceKey('Dummy Service');
        end;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageDialogHandler(Message: Text[1024])
    begin
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), Message, 'Invalid message was shown');
    end;
}

