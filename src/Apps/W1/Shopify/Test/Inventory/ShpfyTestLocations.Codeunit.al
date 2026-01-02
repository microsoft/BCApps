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
    EventSubscriberInstance = Manual;

    var
        Any: Codeunit Any;
        LibraryAssert: Codeunit "Library Assert";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        JData: JsonObject;
        KnownIds: List of [Integer];

    [Test]
    procedure UnitTestImportLocation()
    var
        ShopLocation: Record "Shpfy Shop Location";
        TempShopLocation: Record "Shpfy Shop Location" temporary;
        SyncShopLocations: Codeunit "Shpfy Sync Shop Locations";
        JLocation: JsonObject;
    begin
        Codeunit.Run(Codeunit::"Shpfy Initialize Test");
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
    procedure TestGetShopifyLocationsFullCycle()
    var
        ShopLocation: Record "Shpfy Shop Location";
        NumberOfLocations: Integer;
    begin
        ShopLocation.DeleteAll();
        Codeunit.Run(Codeunit::"Shpfy Initialize Test");
        // [SCENARIO] Invoke a REST API to get the locations from Shopify.
        // For the moking we will choose a random number between 1 and 5 to generate the number of locations that will be in the result set.
        // [GIVEN] The number of locations we want to have in the moking data.
        NumberOfLocations := Any.IntegerInRange(1, 5);
        CreateShopifyLocationsJson(NumberOfLocations);
        // [WHEN] Invoke the request.

        // [THEN] The function return true if it was succesfull.
        LibraryAssert.IsTrue(GetShopifyLocations(), GetLastErrorText());
        // [THEN] ShpfyShopLocation.Count = NumberOfLocations WHERE (Shop.Code = Field("Shop Code"))
        ShopLocation.SetRange("Shop Code", CommunicationMgt.GetShopRecord().Code);
        LibraryAssert.RecordCount(ShopLocation, NumberOfLocations);
    end;

    [Test]
    procedure TestUpdateFulfillmentServiceCallbackUrl()
    var
        ShopLocation: Record "Shpfy Shop Location";
        LocationSubcriber: Codeunit "Shpfy Location Subcriber";
        SyncShopLocations: Codeunit "Shpfy Sync Shop Locations";
    begin
        ShopLocation.DeleteAll();
        Codeunit.Run(Codeunit::"Shpfy Initialize Test");
        // [SCENARIO] Update the Callback URL of an existing fulfillment service location.
        // [GIVEN] A Shop and fulfillment service location with empty Callback URL.
        SyncShopLocations.SetShop(CommunicationMgt.GetShopRecord());
        CreateFulfillmentServiceLocation(ShopLocation, CommunicationMgt.GetShopRecord());
        LocationSubcriber.InitShopifyLocations(JData, CreateShopifyLocationJson());
        BindSubscription(LocationSubcriber);

        // [WHEN] Update the Callback URL by invoking UpdateFulfillmentServiceCallbackUrl.
        SyncShopLocations.UpdateFulfillmentServiceCallbackUrl();
        UnbindSubscription(LocationSubcriber);

        // [THEN] The Callback URL is updated.
        ShopLocation.Get(ShopLocation."Shop Code", ShopLocation.Id);
        LibraryAssert.AreNotEqual(ShopLocation."Fulfillment Service Id", 0, 'Fulfillment Service Id should not be 0');
        LibraryAssert.AreEqual(ShopLocation."Fulfillment Srv. Callback URL", SyncShopLocations.GetFulfillmentServiceCallbackUrl(), 'Fulfillment Service Callback URL was not updated');
    end;

    local procedure GetShopifyLocations() Result: Boolean
    var
        Shop: Record "Shpfy Shop";
        LocationSubcriber: Codeunit "Shpfy Location Subcriber";
    begin
        Commit();
        LocationSubcriber.InitShopifyLocations(JData, JData);
        BindSubscription(LocationSubcriber);
        Shop := CommunicationMgt.GetShopRecord();
        Result := Codeunit.Run(Codeunit::"Shpfy Sync Shop Locations", Shop);
        UnbindSubscription(LocationSubcriber);
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

    local procedure CreateFulfillmentServiceLocation(var ShopLocation: Record "Shpfy Shop Location"; Shop: Record "Shpfy Shop")
    var
        SyncShopLocations: Codeunit "Shpfy Sync Shop Locations";
    begin
        ShopLocation."Shop Code" := Shop.Code;
        ShopLocation.Id := Any.IntegerInRange(12354658, 99999999);
        ShopLocation.Name := CopyStr(SyncShopLocations.GetFulfillmentServiceName(), 1, MaxStrLen(ShopLocation.Name));
        ShopLocation."Is Fulfillment Service" := true;
        ShopLocation.Insert();
    end;
}
