// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Address.IdealPostcodes.Test;

using Microsoft.Foundation.Address;
using Microsoft.Foundation.Address.IdealPostcodes;
using Microsoft.Utilities;

codeunit 148120 "Test IPC Provider Lookup"
{
    // [FEATURE] [IdealPostcodes] [Postcode Service Manager]

    Subtype = Test;
    TestType = IntegrationTest;

    var
        Assert: Codeunit "Assert";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        PostcodeServiceManager: Codeunit "Postcode Service Manager";
        SearchRequestCount: Integer;
        ResolveRequestCount: Integer;
        OtherRequestCount: Integer;
        MyServiceKeyTok: Label 'IDEAL_POSTCODE_POSTCODE_SERVICE', Locked = true;
        RetrieveAddressDetailsErr: Label 'Failed to retrieve address details.';
        RetrievedInvalidValueTok: Label 'Retrieved field value is incorrect.', Locked = true;

    [Test]
    [HandlerFunctions('IPCHttpClientHandler')]
    procedure TestSelectedAddressFromSearchMakesNoSecondRequest()
    var
        TempEnteredAutocompleteAddress: Record "Autocomplete Address" temporary;
        TempAutocompleteAddress: Record "Autocomplete Address" temporary;
        TempAddressListNameValueBuffer: Record "Name/Value Buffer" temporary;
    begin
        // [SCENARIO] The postcode search already returns, and bills, full addresses. Retrieving the address
        // the user selects from that search must not make another (billed) API request.
        LibraryLowerPermissions.SetO365BusFull();
        Initialize();

        // [GIVEN] The framework lists the addresses for a postcode
        TempEnteredAutocompleteAddress.Postcode := 'TESTPOSTCODE';
        Assert.IsTrue(PostcodeServiceManager.GetAddressList(TempEnteredAutocompleteAddress, TempAddressListNameValueBuffer), 'The address list should be retrieved.');
        Assert.AreEqual(2, TempAddressListNameValueBuffer.Count(), 'Both addresses of the postcode should be listed.');

        // [WHEN] The user selects the second address
        TempAddressListNameValueBuffer.SetRange(Name, '2');
        TempAddressListNameValueBuffer.FindFirst();
        Assert.IsTrue(PostcodeServiceManager.GetAddress(TempAddressListNameValueBuffer, TempEnteredAutocompleteAddress, TempAutocompleteAddress), 'The selected address should be retrieved.');

        // [THEN] The selected address is returned from the search result
        Assert.AreEqual('ADDRESS', TempAutocompleteAddress.Address, RetrievedInvalidValueTok);
        Assert.AreEqual('ADDRESS 2', TempAutocompleteAddress."Address 2", RetrievedInvalidValueTok);
        Assert.AreEqual('CITY', TempAutocompleteAddress.City, RetrievedInvalidValueTok);
        Assert.AreEqual('TESTPOSTCODE', TempAutocompleteAddress.Postcode, RetrievedInvalidValueTok);
        Assert.AreEqual('COUNTY', TempAutocompleteAddress.County, RetrievedInvalidValueTok);
        Assert.AreEqual('GB', TempAutocompleteAddress."Country / Region", RetrievedInvalidValueTok);

        // [THEN] Only the search called the API
        Assert.AreEqual(1, SearchRequestCount, 'The postcode search should call the API once.');
        Assert.AreEqual(0, ResolveRequestCount, 'The selected address must not be requested again.');
        Assert.AreEqual(0, OtherRequestCount, 'No other API request is expected.');
    end;

    [Test]
    [HandlerFunctions('IPCHttpClientHandler')]
    procedure TestSelectedAddressNotFromSearchIsResolvedById()
    var
        TempEnteredAutocompleteAddress: Record "Autocomplete Address" temporary;
        TempAutocompleteAddress: Record "Autocomplete Address" temporary;
        TempSelectedAddressNameValueBuffer: Record "Name/Value Buffer" temporary;
    begin
        // [SCENARIO] An address ID that no search in this session returned is retrieved by ID.
        LibraryLowerPermissions.SetO365BusFull();
        Initialize();

        // [GIVEN] A selected address that did not come from a search
        TempSelectedAddressNameValueBuffer.ID := 1;
        TempSelectedAddressNameValueBuffer.Name := 'paf_RESOLVEID';
        TempSelectedAddressNameValueBuffer.Value := 'RESOLVED ADDRESS, RESOLVED ADDRESS 2';
        TempSelectedAddressNameValueBuffer.Insert();

        // [WHEN] The framework retrieves it
        Assert.IsTrue(PostcodeServiceManager.GetAddress(TempSelectedAddressNameValueBuffer, TempEnteredAutocompleteAddress, TempAutocompleteAddress), 'The selected address should be retrieved.');

        // [THEN] The address is resolved with one request by ID
        Assert.AreEqual('RESOLVED ADDRESS', TempAutocompleteAddress.Address, RetrievedInvalidValueTok);
        Assert.AreEqual('RESOLVED ADDRESS 2', TempAutocompleteAddress."Address 2", RetrievedInvalidValueTok);
        Assert.AreEqual('RESOLVED CITY', TempAutocompleteAddress.City, RetrievedInvalidValueTok);
        Assert.AreEqual('RESOLVEPOSTCODE', TempAutocompleteAddress.Postcode, RetrievedInvalidValueTok);
        Assert.AreEqual('RESOLVED COUNTY', TempAutocompleteAddress.County, RetrievedInvalidValueTok);
        Assert.AreEqual('GB', TempAutocompleteAddress."Country / Region", RetrievedInvalidValueTok);
        Assert.AreEqual(0, SearchRequestCount, 'No postcode search is expected.');
        Assert.AreEqual(1, ResolveRequestCount, 'The address should be requested once by ID.');
        Assert.AreEqual(0, OtherRequestCount, 'No other API request is expected.');
    end;

    [Test]
    [HandlerFunctions('IPCHttpClientHandler,MessageHandler')]
    procedure TestUnknownAddressIdFails()
    var
        TempEnteredAutocompleteAddress: Record "Autocomplete Address" temporary;
        TempAutocompleteAddress: Record "Autocomplete Address" temporary;
        TempSelectedAddressNameValueBuffer: Record "Name/Value Buffer" temporary;
    begin
        // [SCENARIO] An address ID the API does not know is reported as a failed retrieval.
        LibraryLowerPermissions.SetO365BusFull();
        Initialize();

        // [GIVEN] A selected address with an unknown ID
        TempSelectedAddressNameValueBuffer.ID := 1;
        TempSelectedAddressNameValueBuffer.Name := 'paf_UNKNOWN';
        TempSelectedAddressNameValueBuffer.Insert();

        // [WHEN] The framework retrieves it
        // [THEN] Retrieval fails and the provider's error is shown (MessageHandler)
        Assert.IsFalse(PostcodeServiceManager.GetAddress(TempSelectedAddressNameValueBuffer, TempEnteredAutocompleteAddress, TempAutocompleteAddress), 'Retrieving an unknown address should fail.');
        Assert.AreEqual(1, ResolveRequestCount, 'The address should be requested once by ID.');
    end;

    local procedure Initialize()
    var
        IPCConfig: Record "IPC Config";
        PostcodeServiceConfig: Record "Postcode Service Config";
        TempServiceListNameValueBuffer: Record "Name/Value Buffer" temporary;
        IPCAddressCache: Codeunit "IPC Address Cache";
        ApiKeyGuid: Guid;
    begin
        Clear(PostcodeServiceManager);
        IPCAddressCache.ClearCache();
        SearchRequestCount := 0;
        ResolveRequestCount := 0;
        OtherRequestCount := 0;

        // IdealPostcodes is the selected provider, stored the way page 9143 stores it: the discovered row's Name
        PostcodeServiceManager.DiscoverPostcodeServices(TempServiceListNameValueBuffer);
        TempServiceListNameValueBuffer.SetRange(Value, MyServiceKeyTok);
        TempServiceListNameValueBuffer.FindFirst();
        PostcodeServiceConfig.DeleteAll();
        PostcodeServiceConfig.Init();
        PostcodeServiceConfig.Insert();
        PostcodeServiceConfig.SaveServiceKey(TempServiceListNameValueBuffer.Name);

        // Enabled and with an API key
        IPCConfig.DeleteAll();
        IPCConfig.Init();
        IPCConfig.Insert();
        IPCConfig.Enabled := true;
        ApiKeyGuid := CreateGuid();
        IPCConfig.SaveAPIKeyAsSecret(ApiKeyGuid, SecretStrSubstNo('apikey'));
        IPCConfig."API Key" := ApiKeyGuid;
        IPCConfig.Modify();
        Commit();
    end;

    [HttpClientHandler]
    procedure IPCHttpClientHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    var
        IPCConfig: Record "IPC Config";
        InStream: InStream;
        URLTxt: Text;
    begin
        URLTxt := IPCConfig.APIEndpoint();
        case Request.Path of
            URLTxt + '/postcodes/TESTPOSTCODE':
                begin
                    SearchRequestCount += 1;
                    NavApp.GetResource('SearchAddress_TESTPOSTCODE.json', InStream);
                end;
            URLTxt + '/autocomplete/addresses/paf_RESOLVEID/gbr':
                begin
                    ResolveRequestCount += 1;
                    NavApp.GetResource('ResolveAddress_RESOLVEID.json', InStream);
                end;
            URLTxt + '/autocomplete/addresses/paf_UNKNOWN/gbr':
                begin
                    ResolveRequestCount += 1;
                    Response.HttpStatusCode := 404;
                    exit(false);
                end;
            else begin
                OtherRequestCount += 1;
                Response.HttpStatusCode := 404;
                exit(false);
            end;
        end;

        Response.Content.WriteFrom(InStream);
        Response.HttpStatusCode := 200;
        exit(false);
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
        Assert.AreEqual(RetrieveAddressDetailsErr, Message, 'Incorrect error was shown.');
    end;
}
