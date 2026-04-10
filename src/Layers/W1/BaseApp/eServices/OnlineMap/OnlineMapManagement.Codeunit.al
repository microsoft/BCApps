// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.OnlineMap;

using Microsoft.Bank.BankAccount;
using Microsoft.CRM.Contact;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.HumanResources.Employee;
using Microsoft.Inventory.Location;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Utilities;
using System;

codeunit 802 "Online Map Management"
{

    trigger OnRun()
    begin
    end;

    var
        OnlineMapSetup: Record "Online Map Setup";
        OnlineMapParameterSetup: Record "Online Map Parameter Setup";
        ThisAddressTxt: Label '&This address';
        DirectionsFromLocationTxt: Label '&Directions from my location';
        OtherDirectionsTxt: Label '&Other';
        OtherMenuQst: Label '&Directions from my company,Directions to my &company,Directions from &another address,Directions to an&other address';
#pragma warning disable AA0074
        Text002: Label 'There is no default Map setup.';
#pragma warning restore AA0074
        ShowMapQst: Label 'Show map with:';
        GoToOnlineMapQst: Label 'To get a map with route directions, you must set up the map service on the Online Map Setup page. Do you want to go there now?';
        ContiueOpeningMapQst: Label 'Do you want to open the map with route directions?';
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text007: Label 'Table %1 has not been set up to use Online Map.';
#pragma warning restore AA0470
        Text008: Label 'The specified record could not be found.';
        Text015: Label 'Bing Maps';
#pragma warning restore AA0074

    procedure MakeSelectionIfMapEnabled(TableID: Integer; Position: Text[1000])
    var
        OnlineMapSetupLocal: Record "Online Map Setup";
        MapSetupPage: Page "Online Map Setup";
        OpenOnlineMap: Boolean;
    begin
        OnlineMapSetupLocal.SetRange(Enabled, true);
        OpenOnlineMap := not OnlineMapSetupLocal.IsEmpty();
        if not OpenOnlineMap then
            if Confirm(GoToOnlineMapQst, true) then begin
                MapSetupPage.RunModal();
                if not OnlineMapSetupLocal.IsEmpty() then
                    OpenOnlineMap := Confirm(ContiueOpeningMapQst, true);
            end;
        if OpenOnlineMap then
            MakeSelection(TableID, Position);
    end;

    procedure MakeSelection(TableID: Integer; Position: Text[1000])
    var
        [RunOnClient]
        LocationProvider: DotNet LocationProvider;
        MainMenu: Text;
        Selection: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeMakeSelection(MainMenu, TableID, Position, Selection, IsHandled);
        if IsHandled then
            exit;

        if LocationProvider.IsAvailable() then
            MainMenu := StrSubstNo('%1,%2,%3', ThisAddressTxt, DirectionsFromLocationTxt, OtherDirectionsTxt)
        else
            MainMenu := StrSubstNo('%1,%2', ThisAddressTxt, OtherDirectionsTxt);

        Selection := StrMenu(MainMenu, 1, ShowMapQst);
        OnMakeSelectionAfterStrMenu(Selection, OnlineMapParameterSetup);
        case Selection of
            1:
                ProcessMap(TableID, Position);
            2:
                if LocationProvider.IsAvailable() then
                    SelectAddress(TableID, Position, 4)
                else
                    ShowOtherMenu(TableID, Position);
            3:
                ShowOtherMenu(TableID, Position);
        end;

        OnAfterMakeSelection(TableID, Position, Selection);
    end;

    local procedure ShowOtherMenu(TableID: Integer; Position: Text[1000])
    var
        Selection: Integer;
    begin
        Selection := StrMenu(OtherMenuQst, 1, ShowMapQst);
        case Selection of
            0:
                MakeSelection(TableID, Position);
            1:
                SelectAddress(TableID, Position, 3);
            2:
                SelectAddress(TableID, Position, 2);
            3:
                SelectAddress(TableID, Position, 1);
            4:
                SelectAddress(TableID, Position, 0);
        end;
    end;

    local procedure ProcessWebMap(TableNo: Integer; ToRecPosition: Text[1000])
    var
        Parameters: array[12] of Text[100];
        url: Text[1024];
        IsHandled: Boolean;
    begin
        GetSetup();
        BuildParameters(TableNo, ToRecPosition, Parameters, OnlineMapSetup."Distance In", OnlineMapSetup.Route);

        url := OnlineMapParameterSetup."Map Service";
        SubstituteParameters(url, Parameters);

        IsHandled := false;
        OnAfterProcessWebMap(url, IsHandled);
        if not IsHandled then
            HyperLink(url);
    end;

    local procedure ProcessWebDirections(FromNo: Integer; FromRecPosition: Text[1000]; ToNo: Integer; ToRecPosition: Text[1000]; Distance: Option Miles,Kilometers; Route: Option Quickest,Shortest)
    var
        Parameters: array[2, 12] of Text[100];
        url: Text[1024];
        IsHandled: Boolean;
    begin
        GetSetup();
        BuildParameters(FromNo, FromRecPosition, Parameters[1], Distance, Route);
        BuildParameters(ToNo, ToRecPosition, Parameters[2], Distance, Route);

        if FromNo = Database::Geolocation then begin
            url := OnlineMapParameterSetup."Directions from Location Serv.";
            SubstituteGPSParameters(url, Parameters[1]);
            SubstituteParameters(url, Parameters[2]);
        end else begin
            url := OnlineMapParameterSetup."Directions Service";
            SubstituteParameters(url, Parameters[1]);
            SubstituteParameters(url, Parameters[2]);
        end;

        IsHandled := false;
        OnAfterProcessWebDirections(url, IsHandled);
        if not IsHandled then
            HyperLink(url);
    end;

    procedure ProcessMap(TableNo: Integer; ToRecPosition: Text[1000])
    begin
        TestSetupExists();
        ProcessWebMap(TableNo, ToRecPosition);
    end;

    procedure ProcessDirections(FromNo: Integer; FromRecPosition: Text[1000]; ToNo: Integer; ToRecPosition: Text[1000]; Distance: Option; Route: Option)
    begin
        TestSetupExists();
        ProcessWebDirections(FromNo, FromRecPosition, ToNo, ToRecPosition, Distance, Route);
    end;

    procedure BuildParameters(TableNo: Integer; RecPosition: Text[1000]; var Parameters: array[12] of Text[100]; Distance: Option Miles,Kilometers; Route: Option Quickest,Shortest)
    var
        CompanyInfo: Record "Company Information";
        CountryRegion: Record "Country/Region";
        OnlineMapSetup: Record "Online Map Setup";
        OnlineMapParameterSetup: Record "Online Map Parameter Setup";
        i: Integer;
        IsHandled: Boolean;
    begin
        Clear(Parameters);
        if ValidAddresses(TableNo) then
            GetAddress(TableNo, RecPosition, Parameters)
        else
            Error(Text007, Format(TableNo));
        if TableNo = Database::Geolocation then
            exit;

        IsHandled := false;
        OnBuildParametersOnBeforeGetOnlineMapSetup(TableNo, IsHandled);
        if IsHandled then
            exit;

        OnlineMapSetup.Get();
        OnlineMapSetup.TestField("Map Parameter Setup Code");
        OnlineMapParameterSetup.Get(OnlineMapSetup."Map Parameter Setup Code");
        CompanyInfo.Get();

        if Parameters[5] = '' then
            Parameters[5] := CompanyInfo."Country/Region Code";
        if CountryRegion.Get(CopyStr(Parameters[5], 1, MaxStrLen(CountryRegion.Code))) then
            Parameters[6] := CountryRegion.Name;

        if OnlineMapParameterSetup."URL Encode Non-ASCII Chars" then
            for i := 1 to 6 do
                Parameters[i] := CopyStr(URLEncode(Parameters[i]), 1, MaxStrLen(Parameters[i]));

        Parameters[7] := GetCultureInfo();
        if OnlineMapParameterSetup."Miles/Kilometers Option List" <> '' then
            Parameters[8] := SelectStr(Distance + 1, OnlineMapParameterSetup."Miles/Kilometers Option List");
        if OnlineMapParameterSetup."Quickest/Shortest Option List" <> '' then
            Parameters[9] := SelectStr(Route + 1, OnlineMapParameterSetup."Quickest/Shortest Option List");
    end;

    local procedure GetAddress(TableID: Integer; RecPosition: Text[1000]; var Parameters: array[12] of Text[100])
    var
        Geolocation: Record Geolocation;
        Location: Record Location;
        RecordRef: RecordRef;
        IsHandled: Boolean;
    begin
        OnBeforeGetAddress(TableID, RecPosition, Parameters, IsHandled);
        if IsHandled then
            exit;

        RecordRef.Open(TableID);
        RecordRef.SetPosition(RecPosition);
        if not RecordRef.Find('=') then
            Error(Text008);

        case TableID of
            Database::Location:
                begin
                    RecordRef.SetTable(Location);
                    Parameters[1] := Format(Location.Address);
                    Parameters[2] := Format(Location.City);
                    Parameters[3] := Format(Location.County);
                    Parameters[4] := Format(Location."Post Code");
                    Parameters[5] := Format(Location."Country/Region Code");
                end;
            Database::Customer:
                SetParameters(RecordRef, Parameters, 5, 7, 92, 91, 35);
            Database::Vendor:
                SetParameters(RecordRef, Parameters, 5, 7, 92, 91, 35);
            Database::"Company Information":
                SetParameters(RecordRef, Parameters, 4, 6, 31, 30, 36);
            Database::Resource:
                SetParameters(RecordRef, Parameters, 6, 8, 54, 53, 59);
            Database::Job:
                SetParameters(RecordRef, Parameters, 59, 61, 63, 64, 67);
            Database::"Ship-to Address":
                SetParameters(RecordRef, Parameters, 5, 7, 92, 91, 35);
            Database::"Order Address":
                SetParameters(RecordRef, Parameters, 5, 7, 92, 91, 35);
            Database::"Bank Account":
                SetParameters(RecordRef, Parameters, 5, 7, 92, 91, 35);
            Database::Contact:
                SetParameters(RecordRef, Parameters, 5, 7, 92, 91, 35);
            Database::Employee:
                SetParameters(RecordRef, Parameters, 8, 10, 12, 11, 25);
            Database::Geolocation:
                begin
                    RecordRef.SetTable(Geolocation);
                    Parameters[10] := Format(Geolocation.Latitude, 0, 2);
                    Parameters[11] := Format(Geolocation.Longitude, 0, 2);
                end;
        end;

        OnAfterGetAddress(TableID, RecPosition, Parameters, RecordRef);
    end;

    local procedure ValidAddresses(TableID: Integer): Boolean
    var
        IsValid: Boolean;
    begin
        OnBeforeValidAddress(TableID, IsValid);
        if IsValid then
            exit(true);

        IsValid :=
          TableID in [Database::"Bank Account",
                      Database::"Company Information",
                      Database::Contact,
                      Database::Customer,
                      Database::Employee,
                      Database::Job,
                      Database::Location,
                      Database::Resource,
                      Database::"Ship-to Address",
                      Database::"Order Address",
                      Database::Vendor,
                      Database::Geolocation];

        OnAfterValidAddress(TableID, IsValid);
        exit(IsValid);
    end;

    local procedure URLEncode(InText: Text[250]) OutText: Text[250]
    var
        SystemWebHttpUtility: DotNet HttpUtility;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeURLEncode(InText, OutText, IsHandled);
        if IsHandled then
            exit;

        SystemWebHttpUtility := SystemWebHttpUtility.HttpUtility();
        exit(CopyStr(SystemWebHttpUtility.UrlEncode(InText), 1, MaxStrLen(InText)));
    end;

    local procedure GetCultureInfo(): Text[30]
    var
        CultureInfo: DotNet CultureInfo;
    begin
        CultureInfo := CultureInfo.CultureInfo(WindowsLanguage);
        exit(CopyStr(CultureInfo.ToString(), 1, 30));
    end;

    local procedure TestSetupExists(): Boolean
    var
        OnlineMapSetup: Record "Online Map Setup";
    begin
        if not OnlineMapSetup.Get() then
            Error(Text002);
        exit(true);
    end;

    procedure TestSetup(): Boolean
    var
        OnlineMapSetup: Record "Online Map Setup";
    begin
        exit(not OnlineMapSetup.IsEmpty);
    end;

    local procedure SelectAddress(TableNo: Integer; RecPosition: Text[1000]; Direction: Option "To Other","From Other","To Company","From Company","From my location")
    var
        CompanyInfo: Record "Company Information";
        OnlineMapSetup: Record "Online Map Setup";
        OnlineMapAddressSelector: Page "Online Map Address Selector";
        OnlineMapLocation: Page "Online Map Location";
        Distance: Option Miles,Kilometers;
        Route: Option Quickest,Shortest;
    begin
        if Direction in [Direction::"To Other", Direction::"From Other"] then begin
            if not (OnlineMapAddressSelector.RunModal() = ACTION::OK) then
                exit;
            if OnlineMapAddressSelector.GetRecPosition() = '' then
                exit;
            OnlineMapAddressSelector.Getdefaults(Distance, Route)
        end else begin
            OnlineMapSetup.Get();
            CompanyInfo.Get();
        end;

        case Direction of
            Direction::"To Other":
                ProcessDirections(
                  TableNo, RecPosition,
                  OnlineMapAddressSelector.GetTableNo(), OnlineMapAddressSelector.GetRecPosition(),
                  Distance, Route);
            Direction::"From Other":
                ProcessDirections(
                  OnlineMapAddressSelector.GetTableNo(), OnlineMapAddressSelector.GetRecPosition(),
                  TableNo, RecPosition,
                  Distance, Route);
            Direction::"To Company":
                ProcessDirections(
                  TableNo, RecPosition,
                  Database::"Company Information", CompanyInfo.GetPosition(),
                  OnlineMapSetup."Distance In", OnlineMapSetup.Route);
            Direction::"From Company":
                ProcessDirections(
                  Database::"Company Information", CompanyInfo.GetPosition(),
                  TableNo, RecPosition,
                  OnlineMapSetup."Distance In", OnlineMapSetup.Route);
            Direction::"From my location":
                begin
                    OnlineMapLocation.SetRecordTo(TableNo, RecPosition);
                    OnlineMapLocation.Run();
                end;
        end;
    end;

    procedure SubstituteParameters(var url: Text[1024]; Parameters: array[12] of Text[100])
    var
        ParameterName: Text;
        parameterNumber: Integer;
        ParmPos: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSubstituteParameters(url, Parameters, IsHandled);
        if IsHandled then
            exit;

        for parameterNumber := 1 to ArrayLen(Parameters) do begin
            ParameterName := StrSubstNo('{%1}', parameterNumber);
            ParmPos := StrPos(url, ParameterName);

            if ParmPos > 1 then
                url :=
                  CopyStr(
                    CopyStr(url, 1, ParmPos - 1) + Parameters[parameterNumber] + CopyStr(url, ParmPos + StrLen(ParameterName)),
                    1, MaxStrLen(url));
        end;
    end;

    local procedure SubstituteGPSParameters(var url: Text[1024]; Parameters: array[12] of Text[100])
    var
        ParameterName: Text;
        parameterNumber: Integer;
        ParmPos: Integer;
    begin
        for parameterNumber := 10 to ArrayLen(Parameters) do begin
            ParameterName := StrSubstNo('{%1}', parameterNumber);
            ParmPos := StrPos(url, ParameterName);

            if ParmPos > 1 then
                url :=
                  CopyStr(
                    CopyStr(url, 1, ParmPos - 1) + Parameters[parameterNumber] + CopyStr(url, ParmPos + StrLen(ParameterName)),
                    1, MaxStrLen(url));
        end;
    end;

    procedure SetupDefault()
    var
        OnlineMapSetup: Record "Online Map Setup";
        OnlineMapParameterSetup: Record "Online Map Parameter Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetupDefault(OnlineMapSetup, OnlineMapParameterSetup, IsHandled);
        if IsHandled then
            exit;

        OnlineMapSetup.DeleteAll();
        OnlineMapParameterSetup.DeleteAll();
        InsertParam(
          'BING',
          Text015,
          'https://bing.com/maps/default.aspx?where1={1}+{2}+{6}&v=2&mkt={7}',
          'https://bing.com/maps/default.aspx?rtp=adr.{1}+{2}+{6}~adr.{1}+{2}+{6}&v=2&mkt={7}&rtop={9}~0~0',
          'https://bing.com/maps/default.aspx?rtp=pos.{10}_{11}~adr.{1}+{2}+{6}&v=2&mkt={7}&rtop={9}~0~0',
          false, '', '0,1',
          'http://go.microsoft.com/fwlink/?LinkId=519372');
        OnlineMapSetup."Map Parameter Setup Code" := 'BING';
        OnlineMapSetup.Insert();
    end;

    local procedure InsertParam("Code": Code[10]; Name: Text[30]; MapURL: Text[250]; DirectionsURL: Text[250]; DirectionsFromGpsURL: Text[250]; URLEncode: Boolean; MilesKilometres: Text[250]; QuickesShortest: Text[250]; Comment: Text[250])
    var
        OnlineMapParameterSetup: Record "Online Map Parameter Setup";
    begin
        OnlineMapParameterSetup.Init();
        OnlineMapParameterSetup.Code := Code;
        OnlineMapParameterSetup.Name := Name;
        OnlineMapParameterSetup."Map Service" := MapURL;
        OnlineMapParameterSetup."Directions Service" := DirectionsURL;
        OnlineMapParameterSetup."Directions from Location Serv." := DirectionsFromGpsURL;
        OnlineMapParameterSetup."URL Encode Non-ASCII Chars" := URLEncode;
        OnlineMapParameterSetup."Miles/Kilometers Option List" := MilesKilometres;
        OnlineMapParameterSetup."Quickest/Shortest Option List" := QuickesShortest;
        OnlineMapParameterSetup.Comment := Comment;
        OnlineMapParameterSetup.Insert(true);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Connection", 'OnRegisterServiceConnection', '', false, false)]
    procedure HandleMAPRegisterServiceConnection(var ServiceConnection: Record "Service Connection")
    var
        OnlineMapSetupLocal: Record "Online Map Setup";
        [SecurityFiltering(SecurityFilter::Ignored)]
        OnlineMapSetup2: Record "Online Map Setup";
        RecRef: RecordRef;
    begin
        if not OnlineMapSetupLocal.Get() then begin
            if not OnlineMapSetup2.WritePermission() then
                exit;
            OnlineMapSetupLocal.Init();
            OnlineMapSetupLocal.Insert();
        end;
        RecRef.GetTable(OnlineMapSetupLocal);

        ServiceConnection.Status := ServiceConnection.Status::Enabled;
        ServiceConnection.Status := ServiceConnection.Status::Disabled;
        if OnlineMapSetupLocal.Enabled then
            ServiceConnection.Status := ServiceConnection.Status::Enabled;
        ServiceConnection.InsertServiceConnection(
          ServiceConnection, RecRef.RecordId, OnlineMapSetupLocal.TableCaption(), '', PAGE::"Online Map Setup");
    end;

    local procedure GetSetup()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetSetup(OnlineMapSetup, OnlineMapParameterSetup, IsHandled);
        if IsHandled then
            exit;

        OnlineMapSetup.Get();
        OnlineMapSetup.TestField("Map Parameter Setup Code");
        OnlineMapParameterSetup.Get(OnlineMapSetup."Map Parameter Setup Code");
    end;

    procedure SetParameters(var RecordRef: RecordRef; var Parameters: array[12] of Text[100]; AddressFieldNo: Integer; CityFieldNo: Integer; CountyFieldNo: Integer; PostCodeFieldNo: Integer; CountryCodeFieldNo: Integer)
    var
        FieldRef: FieldRef;
    begin
        FieldRef := RecordRef.Field(AddressFieldNo);
        Parameters[1] := Format(FieldRef);
        FieldRef := RecordRef.Field(CityFieldNo);
        Parameters[2] := Format(FieldRef);
        FieldRef := RecordRef.Field(CountyFieldNo);
        Parameters[3] := Format(FieldRef);
        FieldRef := RecordRef.Field(PostCodeFieldNo);
        Parameters[4] := Format(FieldRef);
        FieldRef := RecordRef.Field(CountryCodeFieldNo);
        Parameters[5] := Format(FieldRef);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetAddress(TableID: Integer; RecPosition: Text; var Parameters: array[12] of Text[100]; var RecordRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMakeSelection(TableID: Integer; Position: Text[1000]; Selection: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterProcessWebMap(url: Text[1024]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterProcessWebDirections(url: Text[1024]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidAddress(TableID: Integer; var IsValid: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMakeSelection(var MainMenu: Text; TableID: Integer; Position: Text[1000]; var Selection: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetAddress(TableID: Integer; RecPosition: Text; var Parameters: array[12] of Text[100]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSetup(var OnlineMapSetup: Record "Online Map Setup"; var OnlineMapParameterSetup: Record "Online Map Parameter Setup"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetupDefault(var OnlineMapSetup: Record "Online Map Setup"; var OnlineMapParameterSetup: Record "Online Map Parameter Setup"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSubstituteParameters(var url: Text[1024]; Parameters: array[12] of Text[100]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidAddress(TableID: Integer; var IsValid: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeURLEncode(InText: Text[250]; var OutText: Text[250]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMakeSelectionAfterStrMenu(var Selection: Integer; var OnlineMapParameterSetup: Record "Online Map Parameter Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBuildParametersOnBeforeGetOnlineMapSetup(TableNo: Integer; var IsHandled: Boolean)
    begin
    end;
}

