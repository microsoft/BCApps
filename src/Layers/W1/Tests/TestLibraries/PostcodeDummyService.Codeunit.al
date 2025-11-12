codeunit 139091 "Postcode Dummy Service"
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    var
        PostcodeServiceManager: Codeunit "Postcode Service Manager";
        SimulatedErrorErr: Label 'Error', Locked = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Postcode Service Manager", 'OnDiscoverPostcodeServices', '', false, false)]
    [Scope('OnPrem')]
    procedure RegisterServiceOnDiscoverPostcodeServices(var TempServiceListNameValueBuffer: Record "Name/Value Buffer" temporary)
    begin
        PostcodeServiceManager.RegisterService(TempServiceListNameValueBuffer, 'Dummy Service', 'Dummy Service');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Postcode Service Manager", 'OnRetrieveAddressList', '', false, false)]
    [Scope('OnPrem')]
    procedure GetAddressListOnRetrieveAddressList(ServiceKey: Text; TempEnteredAutocompleteAddress: Record "Autocomplete Address" temporary; var TempAddressListNameValueBuffer: Record "Name/Value Buffer" temporary; var IsSuccessful: Boolean; var ErrorMsg: Text)
    var
        Text: Text[250];
        i: Integer;
        "count": Integer;
    begin
        if ServiceKey <> 'Dummy Service' then
            exit;

        IsSuccessful := true;
        if TempEnteredAutocompleteAddress.Postcode = 'ERROR' then
            Error(SimulatedErrorErr);

        if TempEnteredAutocompleteAddress.Postcode = 'ERROR HANDLED' then begin
            IsSuccessful := false;
            ErrorMsg := 'Error from postcode service.';
            exit;
        end;

        count := 5;
        if TempEnteredAutocompleteAddress.Postcode = 'ONE' then
            count := 1;

        for i := 1 to count do begin
            Text := StrSubstNo('Address %1', i);
            PostcodeServiceManager.AddSelectionAddress(TempAddressListNameValueBuffer, Text, Text);
        end
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Postcode Service Manager", 'OnRetrieveAddress', '', false, false)]
    [Scope('OnPrem')]
    procedure GetAddressOnGetRetrieveAddress(ServiceKey: Text; TempEnteredAutocompleteAddress: Record "Autocomplete Address" temporary; TempSelectedAddressNameValueBuffer: Record "Name/Value Buffer" temporary; var TempAutocompleteAddress: Record "Autocomplete Address" temporary; var IsSuccessful: Boolean; var ErrorMsg: Text)
    begin
        if ServiceKey <> 'Dummy Service' then
            exit;

        IsSuccessful := true;

        // In some tests we can't select what we want. Fill empty values
        if TempAutocompleteAddress.Address = '' then
            TempAutocompleteAddress.Address := 'ADDRESS';

        if TempAutocompleteAddress."Address 2" = '' then
            TempAutocompleteAddress."Address 2" := 'ADDRESS 2';

        if TempAutocompleteAddress.Postcode = '' then
            TempAutocompleteAddress.Postcode := 'POSTCODE';

        if TempAutocompleteAddress.City = '' then
            TempAutocompleteAddress.City := 'CITY';

        if TempAutocompleteAddress."Country / Region" = '' then
            TempAutocompleteAddress."Country / Region" := 'COUNTRY';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Postcode Service Manager", 'OnShowConfigurationPage', '', false, false)]
    [Scope('OnPrem')]
    procedure ConfigureOnShowConfigurationPage(ServiceKey: Text; var Successful: Boolean)
    begin
        Successful := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Postcode Service Manager", 'OnCheckIsServiceConfigured', '', false, false)]
    [Scope('OnPrem')]
    procedure RespondOnCheckIsServiceConfigured(ServiceKey: Text; var IsConfigured: Boolean)
    begin
        if ServiceKey = 'Dummy Service' then
            IsConfigured := true;
    end;
}

