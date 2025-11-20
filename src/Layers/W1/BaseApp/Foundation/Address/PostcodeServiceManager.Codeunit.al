// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Address;

using Microsoft.Utilities;

codeunit 9090 "Postcode Service Manager"
{

    trigger OnRun()
    begin
    end;

    var
        TechnicalErr: Label 'A general technical error occurred while contacting remote service.';
        ServiceNotConfiguredErr: Label 'Postcode service is not configured.';
        DisabledTok: Label 'Disabled';

    procedure DiscoverPostcodeServices(var TempServiceListNameValueBuffer: Record "Name/Value Buffer" temporary)
    begin
        OnDiscoverPostcodeServices(TempServiceListNameValueBuffer);
    end;

    procedure ShowConfigurationPage(ServiceKey: Text; var IsSuccessful: Boolean)
    begin
        OnShowConfigurationPage(ServiceKey, IsSuccessful);
    end;

    procedure IsServiceConfigured(ServiceKey: Text; var IsConfigured: Boolean)
    begin
        OnCheckIsServiceConfigured(ServiceKey, IsConfigured);
    end;

    procedure GetAddressList(TempEnteredAutocompleteAddress: Record "Autocomplete Address" temporary; var TempAddressListNameValueBuffer: Record "Name/Value Buffer" temporary): Boolean
    var
        IsSuccessful: Boolean;
        ErrorMsg: Text;
    begin
        IsSuccessful := true;
        if not TryGetAddressList(GetActiveService(), TempEnteredAutocompleteAddress, TempAddressListNameValueBuffer, IsSuccessful, ErrorMsg) then begin
            IsSuccessful := false;
            if ErrorMsg = '' then
                ErrorMsg := TechnicalErr;
        end;

        HandleErrorsIfNeccessary(IsSuccessful, ErrorMsg);
        exit(IsSuccessful);
    end;

    procedure GetAddress(TempSelectedAddressNameValueBuffer: Record "Name/Value Buffer" temporary; var TempEnteredAutocompleteAddress: Record "Autocomplete Address" temporary; var TempAutocompleteAddress: Record "Autocomplete Address" temporary): Boolean
    var
        IsSuccessful: Boolean;
        ErrorMsg: Text;
    begin
        IsSuccessful := true;
        if not TryGetAddress(GetActiveService(), TempEnteredAutocompleteAddress,
             TempSelectedAddressNameValueBuffer, TempAutocompleteAddress, IsSuccessful, ErrorMsg)
        then begin
            IsSuccessful := false;
            ErrorMsg := TechnicalErr;
        end;

        HandleErrorsIfNeccessary(IsSuccessful, ErrorMsg);
        exit(IsSuccessful);
    end;

    procedure SetSelectedService(ServiceKey: Text)
    var
        PostcodeServiceConfig: Record "Postcode Service Config";
    begin
        if not PostcodeServiceConfig.FindFirst() then begin
            PostcodeServiceConfig.Init();
            PostcodeServiceConfig.Insert();
        end;

        PostcodeServiceConfig.SaveServiceKey(CopyStr(ServiceKey, 250));
        Commit();
    end;

    procedure RegisterService(var TempServiceListNameValueBuffer: Record "Name/Value Buffer" temporary; ServiceIdentifier: Text[250]; ServiceName: Text[250])
    begin
        InsertNameValueBuffer(TempServiceListNameValueBuffer, ServiceIdentifier, ServiceName);
    end;

    procedure AddSelectionAddress(var TempAddressListNameValueBuffer: Record "Name/Value Buffer" temporary; Identifier: Text[250]; DisplayString: Text[250])
    begin
        InsertNameValueBuffer(TempAddressListNameValueBuffer, Identifier, DisplayString);
    end;

    procedure IsConfigured(): Boolean
    var
        PostcodeServiceConfig: Record "Postcode Service Config";
        IsSerConf: Boolean;
        PostCodeServiceKey: Text;
    begin
        if not PostcodeServiceConfig.FindFirst() then
            exit(false);

        PostCodeServiceKey := PostcodeServiceConfig.GetServiceKey();
        if PostCodeServiceKey = DisabledTok then
            exit(false);

        IsServiceConfigured(PostCodeServiceKey, IsSerConf);
        exit(IsSerConf);
    end;

    [TryFunction]
    local procedure TryGetAddressList(ServiceKey: Text; TempEnteredAutocompleteAddress: Record "Autocomplete Address" temporary; var TempAddressListNameValueBuffer: Record "Name/Value Buffer" temporary; var IsSuccessful: Boolean; var ErrorMSg: Text)
    begin
        OnRetrieveAddressList(ServiceKey, TempEnteredAutocompleteAddress, TempAddressListNameValueBuffer, IsSuccessful, ErrorMSg);
    end;

    [TryFunction]
    local procedure TryGetAddress(ServiceKey: Text; TempEnteredAutocompleteAddress: Record "Autocomplete Address" temporary; TempSelectedAddressNameValueBuffer: Record "Name/Value Buffer" temporary; var TempAutocompleteAddress: Record "Autocomplete Address" temporary; var IsSuccessful: Boolean; var ErrorMsg: Text)
    begin
        OnRetrieveAddress(ServiceKey, TempEnteredAutocompleteAddress, TempSelectedAddressNameValueBuffer,
          TempAutocompleteAddress, IsSuccessful, ErrorMsg);
    end;

    local procedure HandleErrorsIfNeccessary(IsSuccessful: Boolean; ErrorMsg: Text)
    begin
        if not IsSuccessful then
            Message(ErrorMsg);
    end;

    local procedure InsertNameValueBuffer(var TempNameValueBuffer: Record "Name/Value Buffer" temporary; Name: Text[250]; Value: Text[250])
    var
        LastId: Integer;
    begin
        LastId := 0;
        if TempNameValueBuffer.FindLast() then
            LastId := TempNameValueBuffer.ID;

        TempNameValueBuffer.Init();
        TempNameValueBuffer.ID := LastId + 1;
        TempNameValueBuffer.Name := Name;
        TempNameValueBuffer.Value := Value;
        TempNameValueBuffer.Insert();
    end;

    procedure GetActiveService(): Text
    var
        PostcodeServiceConfig: Record "Postcode Service Config";
    begin
        if not PostcodeServiceConfig.FindFirst() then
            Error(ServiceNotConfiguredErr);

        exit(PostcodeServiceConfig.GetServiceKey());
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure OnDiscoverPostcodeServices(var TempServiceListNameValueBuffer: Record "Name/Value Buffer" temporary)
    begin
        // Emit broadcast message to find all postcode service
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure OnRetrieveAddressList(ServiceKey: Text; TempEnteredAutocompleteAddress: Record "Autocomplete Address" temporary; var TempAddressListNameValueBuffer: Record "Name/Value Buffer" temporary; var IsSuccessful: Boolean; var ErrorMsg: Text)
    begin
        // Retrieve the list of possible UK addresses or autocompletetion based on parameters
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure OnRetrieveAddress(ServiceKey: Text; TempEnteredAutocompleteAddress: Record "Autocomplete Address" temporary; TempSelectedAddressNameValueBuffer: Record "Name/Value Buffer" temporary; var TempAutocompleteAddress: Record "Autocomplete Address" temporary; var IsSuccessful: Boolean; var ErrorMsg: Text)
    begin
        // Retrieve specific address
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure OnShowConfigurationPage(ServiceKey: Text; var Successful: Boolean)
    begin
        // Notify services to create their configuration records if necessary
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure OnCheckIsServiceConfigured(ServiceKey: Text; var IsConfigured: Boolean)
    begin
        // Retrieve information from service if it is configured
    end;
}

