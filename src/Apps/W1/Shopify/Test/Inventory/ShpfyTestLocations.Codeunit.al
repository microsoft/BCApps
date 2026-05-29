// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.Integration.Shopify;
using System.TestLibraries.Utilities;

/// <summary>
/// Codeunit Shpfy Test Locations (ID 139577).
/// </summary>
codeunit 139577 "Shpfy Test Locations"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;
    TestHttpRequestPolicy = BlockOutboundRequests;

    var
        Shop: Record "Shpfy Shop";
        Any: Codeunit Any;
        LibraryAssert: Codeunit "Library Assert";
        LibraryRandom: Codeunit "Library - Random";
        OutboundHttpRequests: Codeunit "Library - Variable Storage";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        InitializeTest: Codeunit "Shpfy Initialize Test";
        JData: JsonObject;
        JLocationData: JsonObject;
        KnownIds: List of [Integer];
        IsInitialized: Boolean;

    local procedure Initialize()
    var
        AccessToken: SecretText;
    begin
        if IsInitialized then
            exit;

        Codeunit.Run(Codeunit::"Shpfy Initialize Test");
        Shop := CommunicationMgt.GetShopRecord();

        AccessToken := LibraryRandom.RandText(20);
        InitializeTest.RegisterAccessTokenForShop(Shop.GetStoreName(), AccessToken);

        IsInitialized := true;
    end;

    [HttpClientHandler]
    internal procedure LocationsHttpHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    var
        RequestType: Text;
        Body: Text;
    begin
        if not InitializeTest.VerifyRequestUrl(Request.Path, Shop."Shopify URL") then
            exit(true);

        if OutboundHttpRequests.Length() = 0 then
            exit(false);

        RequestType := OutboundHttpRequests.DequeueText();
        case RequestType of
            'Locations':
                Response.Content.WriteFrom(Format(JData));
            'Location':
                Response.Content.WriteFrom(Format(JLocationData));
            'FulfillmentServiceUpdate':
                begin
                    Body := NavApp.GetResourceAsText('Locations/FulfillmentServiceUpdateResponse.txt', TextEncoding::UTF8);
                    Response.Content.WriteFrom(GetFulfillmentServiceUpdateResponse(Body));
                end;
        end;
        exit(false);
    end;

    local procedure GetFulfillmentServiceUpdateResponse(Body: Text): Text
    var
        SyncShopLocations: Codeunit "Shpfy Sync Shop Locations";
    begin
        exit(StrSubstNo(Body, SyncShopLocations.GetFulfillmentServiceCallbackUrl()));
    end;

    [Test]
    procedure UnitTestImportLocation()
    var
        ShopLocation: Record "Shpfy Shop Location";
        TempShopLocation: Record "Shpfy Shop Location" temporary;
        SyncShopLocations: Codeunit "Shpfy Sync Shop Locations";
        JLocation: JsonObject;
    begin
        Initialize();
        // [SCENARIO] Import/Update Shopify locations from a Json location object into a "Shpfy Shop Location" with
        // [GIVEN] A Shop
        SyncShopLocations.SetShop(CommunicationMgt.GetShopRecord());
        // [GIVEN] A Shopify Location as an Jsonobject.
        JLocation := CreateShopifyLocation(false, false);
        // [GIVEN] TempShopLocation
        // [WHEN] Invode ImportLocation
        SyncShopLocations.ImportLocation(JLocation, TempShopLocation);
        // [THEN] TempShopLocation.Count() = 1 WHERE TempShopLocation."Shop Code) = Shop.Code
        ShopLocation.SetRange("Shop Code", CommunicationMgt.GetShopRecord().Code);
        LibraryAssert.RecordCount(ShopLocation, 1);
    end;

    [Test]
    [HandlerFunctions('LocationsHttpHandler')]
    procedure TestGetShopifyLocationsFullCycle()
    var
        ShopLocation: Record "Shpfy Shop Location";
        NumberOfLocations: Integer;
    begin
        ShopLocation.DeleteAll();
        Initialize();
        // [SCENARIO] Invoke a REST API to get the locations from Shopify.
        // For the moking we will choose a random number between 1 and 5 to generate the number of locations that will be in the result set.
        // [GIVEN] The number of locations we want to have in the moking data.
        NumberOfLocations := Any.IntegerInRange(1, 5);
        CreateShopifyLocationsJson(NumberOfLocations);

        // [GIVEN] Register Expected Outbound API Requests.
        OutboundHttpRequests.Clear();
        OutboundHttpRequests.Enqueue('Locations');

        // [WHEN] Invoke the request.

        // [THEN] The function return true if it was succesfull.
        LibraryAssert.IsTrue(GetShopifyLocations(), GetLastErrorText());
        // [THEN] ShpfyShopLocation.Count = NumberOfLocations WHERE (Shop.Code = Field("Shop Code"))
        ShopLocation.SetRange("Shop Code", CommunicationMgt.GetShopRecord().Code);
        LibraryAssert.RecordCount(ShopLocation, NumberOfLocations);
    end;

    [Test]
    [HandlerFunctions('LocationsHttpHandler')]
    procedure TestUpdateFulfillmentServiceCallbackUrl()
    var
        ShopLocation: Record "Shpfy Shop Location";
        SyncShopLocations: Codeunit "Shpfy Sync Shop Locations";
    begin
        ShopLocation.DeleteAll();
        Initialize();
        // [SCENARIO] Update the Callback URL of an existing fulfillment service location.
        // [GIVEN] A Shop and fulfillment service location with empty Callback URL.
        SyncShopLocations.SetShop(CommunicationMgt.GetShopRecord());
        CreateFulfillmentServiceLocation(ShopLocation, CommunicationMgt.GetShopRecord());
        JLocationData := CreateShopifyLocationJson();

        // [GIVEN] Register Expected Outbound API Requests.
        OutboundHttpRequests.Clear();
        OutboundHttpRequests.Enqueue('Location');
        OutboundHttpRequests.Enqueue('FulfillmentServiceUpdate');

        // [WHEN] Update the Callback URL by invoking UpdateFulfillmentServiceCallbackUrl.
        SyncShopLocations.UpdateFulfillmentServiceCallbackUrl();

        // [THEN] The Callback URL is updated.
        ShopLocation.Get(ShopLocation."Shop Code", ShopLocation.Id);
        LibraryAssert.AreNotEqual(ShopLocation."Fulfillment Service Id", 0, 'Fulfillment Service Id should not be 0');
        LibraryAssert.AreEqual(ShopLocation."Fulfillment Srv. Callback URL", SyncShopLocations.GetFulfillmentServiceCallbackUrl(), 'Fulfillment Service Callback URL was not updated');
    end;

    local procedure GetShopifyLocations() Result: Boolean
    var
        ShopRecord: Record "Shpfy Shop";
    begin
        Commit();
        JLocationData := JData;
        ShopRecord := CommunicationMgt.GetShopRecord();
        Result := Codeunit.Run(Codeunit::"Shpfy Sync Shop Locations", ShopRecord);
    end;

    local procedure CreateShopifyLocationsJson(NumberOfLocations: Integer)
    var
        JLocations: JsonObject;
        JNodes: JsonArray;
        JPageInfo: JsonObject;
        JExtensions: JsonObject;
        JCost: JsonObject;
        JThrottleStatus: JsonObject;
        Index: Integer;
    begin
        Clear(JData);
        Clear(KnownIds);
        for Index := 1 to NumberOfLocations do
            JNodes.Add(CreateShopifyLocation(Index = 1, false));
        JLocations.Add('nodes', JNodes);
        JPageInfo.Add('hasNextPage', false);
        JLocations.Add('pageInfo', JPageInfo);
        JData.Add('locations', JLocations);
        JThrottleStatus.Add('maximumAvailable', 1000.0);
        JThrottleStatus.Add('currentlyAvailable', 996);
        JThrottleStatus.Add('restoreRate', 50.0);
        JCost.Add('requestedQueryCost', 12);
        JCost.Add('actualQueryCost', 4);
        JCost.Add('throttleStatus', JThrottleStatus);
        JData.Add('extensions', JExtensions);
    end;

    local procedure CreateShopifyLocationJson(): JsonObject
    var
        JResult: JsonObject;
        JLocation: JsonObject;
    begin
        JLocation.Add('location', CreateShopifyLocation(false, true));
        JResult.Add('data', JLocation);
        exit(JResult);
    end;

    local procedure CreateShopifyLocation(AsPrimary: Boolean; FulfillmentService: Boolean): JsonObject
    var
        Id: Integer;
        JLocation: JsonObject;
        JFulfillmentService: JsonObject;
        LocationIdTxt: Label 'gid:\/\/shopify\/Location\/%1', Comment = '%1 = LocationId', Locked = true;
    begin
        repeat
            Id := Any.IntegerInRange(12354658, 99999999);
        until not KnownIds.Contains(Id);
        KnownIds.Add(Id);
        JLocation.Add('id', StrSubstNo(LocationIdTxt, id));
        JLocation.Add('isActive', true);
        JLocation.Add('isPrimary', AsPrimary);
        JLocation.Add('name', Any.AlphabeticText(30));
        JLocation.Add('legacyResourceId', Format(Id, 0, 9));
        if FulfillmentService then begin
            JFulfillmentService.Add('id', 12345678);
            JFulfillmentService.Add('callbackUrl', 'https://myshopify.callback.url/fulfillment');
            JLocation.Add('fulfillmentService', JFulfillmentService);
        end;
        exit(JLocation);
    end;

    local procedure CreateFulfillmentServiceLocation(var ShopLocation: Record "Shpfy Shop Location"; ShopRecord: Record "Shpfy Shop")
    var
        SyncShopLocations: Codeunit "Shpfy Sync Shop Locations";
    begin
        ShopLocation."Shop Code" := ShopRecord.Code;
        ShopLocation.Id := Any.IntegerInRange(12354658, 99999999);
        ShopLocation.Name := CopyStr(SyncShopLocations.GetFulfillmentServiceName(), 1, MaxStrLen(ShopLocation.Name));
        ShopLocation."Is Fulfillment Service" := true;
        ShopLocation.Insert();
    end;
}
