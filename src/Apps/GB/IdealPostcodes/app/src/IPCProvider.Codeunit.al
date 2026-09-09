namespace Microsoft.Foundation.Address.IdealPostcodes;

using Microsoft.Foundation.Address;
using Microsoft.Utilities;

codeunit 9403 "IPC Provider"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        MyServiceKeyTok: Label 'IDEAL_POSTCODE_POSTCODE_SERVICE', Locked = true;
        MyServiceNameLbl: Label 'IdealPostcodes', Locked = true; // product name; also accepted as service key - see IsMyServiceKey
        ServiceConnectionNameLbl: Label 'Postcode Service';
        RetrieveAddressDetailsErr: Label 'Failed to retrieve address details.';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Postcode Service Manager", 'OnDiscoverPostcodeServices', '', false, false)]
    local procedure OnDiscoverPostcodeServices(var TempServiceListNameValueBuffer: Record "Name/Value Buffer" temporary)
    begin
        TempServiceListNameValueBuffer.Init();
        TempServiceListNameValueBuffer.ID := TempServiceListNameValueBuffer.Count + 1;
        TempServiceListNameValueBuffer.Name := MyServiceNameLbl;
        TempServiceListNameValueBuffer.Value := MyServiceKeyTok;
        TempServiceListNameValueBuffer.Insert();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Postcode Service Manager", 'OnCheckIsServiceConfigured', '', false, false)]
    local procedure OnCheckIsServiceConfigured(ServiceKey: Text; var IsConfigured: Boolean)
    var
        IdealPostcodesConfig: Record "IPC Config";
    begin
        if IsConfigured then
            exit;

        if not IsMyServiceKey(ServiceKey) then
            exit;

        if not IdealPostcodesConfig.Get() then begin
            IsConfigured := false;
            exit;
        end;

        if not IdealPostcodesConfig.Enabled then begin
            IsConfigured := false;
            exit;
        end;

        if IsNullGuid(IdealPostcodesConfig."API Key") then begin
            IsConfigured := false;
            exit;
        end;

        if IdealPostcodesConfig.GetAPIPasswordAsSecret(IdealPostcodesConfig."API Key").IsEmpty() then begin
            IsConfigured := false;
            exit;
        end;

        IsConfigured := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Postcode Service Manager", 'OnShowConfigurationPage', '', false, false)]
    local procedure OnShowConfigurationPage(ServiceKey: Text; var Successful: Boolean)
    var
        IPCConfig: Record "IPC Config";
        IPCConfigPage: Page "IPC Config";
    begin
        if not IsMyServiceKey(ServiceKey) then
            exit;

        Successful := IPCConfigPage.RunModal() = ACTION::OK;
        Successful := IPCConfig.FindFirst();
        Successful := Successful and not IsNullGuid(IPCConfig."API Key") and IPCConfig.Enabled;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Postcode Service Manager", 'OnRetrieveAddressList', '', false, false)]
    local procedure OnRetrieveAddressList(ServiceKey: Text; TempEnteredAutocompleteAddress: Record "Autocomplete Address" temporary; var TempAddressListNameValueBuffer: Record "Name/Value Buffer" temporary; var IsSuccessful: Boolean; var ErrorMsg: Text)
    var
        TempIPCAddressLookup: Record "IPC Address Lookup" temporary;
        IPCManagement: Codeunit "IPC Management";
        SearchText, ReasonPhrase : Text;
        LastId, StatusCode : Integer;
    begin
        if not IsMyServiceKey(ServiceKey) then
            exit;

        LastId := 0;
        if TempAddressListNameValueBuffer.FindLast() then
            LastId := TempAddressListNameValueBuffer.ID;

        if TempEnteredAutocompleteAddress.Postcode <> '' then
            SearchText := TempEnteredAutocompleteAddress.PostCode
        else
            SearchText := TempEnteredAutocompleteAddress.City;

        if SearchText = '' then
            exit;

        if not IPCManagement.SearchAddress(SearchText, TempIPCAddressLookup, StatusCode, ReasonPhrase) then
            exit;

        TempIPCAddressLookup.Reset();
        if TempIPCAddressLookup.FindSet() then
            repeat
                LastId += 1;
                TempAddressListNameValueBuffer.Init();
                TempAddressListNameValueBuffer.ID := LastId;
                TempAddressListNameValueBuffer.Name := TempIPCAddressLookup."Address ID";
                TempAddressListNameValueBuffer.Value := TempIPCAddressLookup."Display Text";
                TempAddressListNameValueBuffer.Insert();
            until TempIPCAddressLookup.Next() = 0;

        IsSuccessful := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Postcode Service Manager", 'OnRetrieveAddress', '', false, false)]
    local procedure OnRetrieveAddress(ServiceKey: Text; TempEnteredAutocompleteAddress: Record "Autocomplete Address" temporary; TempSelectedAddressNameValueBuffer: Record "Name/Value Buffer" temporary; var TempAutocompleteAddress: Record "Autocomplete Address" temporary; var IsSuccessful: Boolean; var ErrorMsg: Text)
    var
        TempIPCAddressLookup: Record "IPC Address Lookup" temporary;
        IPCManagement: Codeunit "IPC Management";
        SearchText, ReasonPhrase : Text;
        StatusCode: Integer;
    begin
        if not IsMyServiceKey(ServiceKey) then
            exit;

        // The API has no address-by-id endpoint. Search again for what the user entered and take the
        // entry that was selected; this also delivers the address with the "Remove Organisation Name"
        // setting applied, exactly as it was shown in the selection list.
        if TempEnteredAutocompleteAddress.Postcode <> '' then
            SearchText := TempEnteredAutocompleteAddress.Postcode
        else
            SearchText := TempEnteredAutocompleteAddress.City;

        IsSuccessful := (SearchText <> '') and IPCManagement.SearchAddress(SearchText, TempIPCAddressLookup, StatusCode, ReasonPhrase);
        if IsSuccessful then begin
            if TempSelectedAddressNameValueBuffer.Name <> '' then
                TempIPCAddressLookup.SetRange("Address ID", CopyStr(TempSelectedAddressNameValueBuffer.Name, 1, MaxStrLen(TempIPCAddressLookup."Address ID")))
            else
                TempIPCAddressLookup.SetRange("Display Text", TempSelectedAddressNameValueBuffer.Value);
            IsSuccessful := TempIPCAddressLookup.FindFirst();
        end;

        if not IsSuccessful then begin
            ErrorMsg := RetrieveAddressDetailsErr;
            exit;
        end;

        TempAutocompleteAddress.Address := TempIPCAddressLookup.Address;
        TempAutocompleteAddress."Address 2" := TempIPCAddressLookup."Address 2";
        TempAutocompleteAddress.City := TempIPCAddressLookup.City;
        TempAutocompleteAddress."Postcode" := TempIPCAddressLookup."Post Code";
        TempAutocompleteAddress.County := TempIPCAddressLookup.County;
        TempAutocompleteAddress."Country / Region" := TempIPCAddressLookup."Country/Region Code";
        IsSuccessful := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Connection", 'OnRegisterServiceConnection', '', false, false)]
    local procedure RegisterServiceOnRegisterServiceConnection(var ServiceConnection: Record "Service Connection")
    var
        PostcodeServiceConfig: Record "Postcode Service Config";
        PostcodeServiceManager: Codeunit "Postcode Service Manager";
        Configured: Boolean;
    begin
        PostcodeServiceManager.IsServiceConfigured(GetServiceKey(), Configured);
        if Configured then
            ServiceConnection.Status := ServiceConnection.Status::Enabled
        else
            if ServiceConnection.Status = ServiceConnection.Status::" " then
                ServiceConnection.Status := ServiceConnection.Status::Disabled;

        if not PostcodeServiceConfig.FindFirst() then begin
            PostcodeServiceConfig.Init();
            PostcodeServiceConfig.Insert();
            PostcodeServiceConfig.SaveServiceKey('Disabled');
        end;

        ServiceConnection.InsertServiceConnection(ServiceConnection, PostcodeServiceConfig.RecordId,
          ServiceConnectionNameLbl, '', PAGE::"Postcode Configuration Page W1");
    end;

    procedure GetServiceKey(): Text
    begin
        exit(MyServiceKeyTok);
    end;

    local procedure IsMyServiceKey(ServiceKey: Text): Boolean
    begin
        // The Postcode Configuration Page W1 stores the selected row's Name - our display name - as
        // the service key, while internal callers pass the token from GetServiceKey(). Accept both.
        exit(ServiceKey in [MyServiceKeyTok, MyServiceNameLbl]);
    end;
}
