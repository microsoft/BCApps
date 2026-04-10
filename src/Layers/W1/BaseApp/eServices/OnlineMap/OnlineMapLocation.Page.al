// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.OnlineMap;

using System;

page 806 "Online Map Location"
{
    Caption = 'Online Map Location';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = Card;
    ShowFilter = false;

    layout
    {
        area(content)
        {
            label(GeoLocationInstructionsLbl)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Allow Business Central to access data about the geographical location of the device.';
            }

            field(GeolocationLbl; GeolocationLbl)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Status';
                Importance = Promoted;
                ToolTip = 'Specifies the status of the map.';
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        if not LocationProvider.IsAvailable() then begin
            Message(LocationNotAvailableMsg);
            CurrPage.Close();
            exit;
        end;
        LocationProvider := LocationProvider.Create();
        LocationProvider.RequestLocationAsync();
    end;

    var
        [RunOnClient]
        [WithEvents]
        LocationProvider: DotNet LocationProvider;
        ToTableNo: Integer;
        ToRecordPosition: Text[1000];
        GeolocationLbl: Label 'Searching for your location.';
        LocationNotAvailableMsg: Label 'Your location cannot be determined.';

    procedure SetRecordTo(NewToTableNo: Integer; NewToRecordPosition: Text[1000])
    begin
        ToTableNo := NewToTableNo;
        ToRecordPosition := NewToRecordPosition;
    end;

    trigger LocationProvider::LocationChanged(location: DotNet Location)
    var
        OnlineMapSetup: Record "Online Map Setup";
        Geolocation: Record Geolocation;
        OnlineMapManagement: Codeunit "Online Map Management";
    begin
        if location.Status <> 0 then begin
            Message(LocationNotAvailableMsg);
            CurrPage.Close();
            exit;
        end;

        Geolocation.Init();
        Geolocation.ID := CreateGuid();
        Geolocation.Latitude := location.Coordinate.Latitude;
        Geolocation.Longitude := location.Coordinate.Longitude;
        Geolocation.Insert();

        if not OnlineMapSetup.Get() then begin
            OnlineMapManagement.SetupDefault();
            OnlineMapSetup.Get();
        end;

        OnlineMapManagement.ProcessDirections(
          DATABASE::Geolocation, Geolocation.GetPosition(),
          ToTableNo, ToRecordPosition,
          OnlineMapSetup."Distance In", OnlineMapSetup.Route);

        Geolocation.Delete();
        CurrPage.Close();
    end;
}

