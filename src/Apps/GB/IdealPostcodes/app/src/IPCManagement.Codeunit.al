namespace Microsoft.Foundation.Address.IdealPostcodes;

using System.Reflection;
using System.Telemetry;

codeunit 9400 "IPC Management"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        ConfigNotSetupErr: Label 'The IdealPostcodes Provider is not configured. Set up the API key in the IdealPostcodes Provider Setup page.';
        ConnectionSuccessMsg: Label 'Connection test was successful.';
        ConnectionFailedErr: Label 'Connection test failed.';
        NoResultsMsg: Label 'No addresses found for the given postcode.';
        ApiKeyConfigErr: Label 'API Key is not configured.';
        ResponseDetailsTxt: Label 'Received response %1 %2.', Comment = '%1 - Status code, %2 - Reason phrase.';
        UnsuccessfulAddressSearchTxt: Label 'Unsuccessful address search. Response %1 %2.', Comment = '%1 - Status code, %2 - Reason phrase.', Locked = true;
        SecurityAuditAuthFailedTxt: Label 'IdealPostcodes API rejected the request with status %1 %2.', Locked = true, Comment = '%1 - Status code, %2 - Reason phrase.';

    procedure SearchAddress(SearchText: Text; var TempIPCAddressLookup: Record "IPC Address Lookup" temporary; var StatusCode: Integer; var ReasonPhrase: Text): Boolean
    var
        Config: Record "IPC Config";
        TypeHelper: Codeunit "Type Helper";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ResponseText: Text;
    begin
        if not GetConfiguration(Config) then
            Error(ConfigNotSetupErr);

        if not Config.Enabled then
            exit(false);

        FeatureTelemetry.LogUptake('0000RFE', 'IdealPostcodes', Enum::"Feature Uptake Status"::Used);
        if not SendGetRequest(Config, '/postcodes/' + TypeHelper.UriEscapeDataString(SearchText), ResponseText, StatusCode, ReasonPhrase) then
            exit(false);

        ParseAddressResponse(ResponseText, TempIPCAddressLookup);
        exit(not TempIPCAddressLookup.IsEmpty());
    end;

    /// <summary>
    /// Retrieves one address by the ID returned in a search result. The API bills this as a lookup,
    /// so use it only when the address is not already at hand from a search.
    /// </summary>
    procedure ResolveAddress(AddressId: Text; var TempIPCAddressLookup: Record "IPC Address Lookup" temporary; var StatusCode: Integer; var ReasonPhrase: Text): Boolean
    var
        Config: Record "IPC Config";
        TypeHelper: Codeunit "Type Helper";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ResponseText: Text;
    begin
        if not GetConfiguration(Config) then
            Error(ConfigNotSetupErr);

        if not Config.Enabled then
            exit(false);

        FeatureTelemetry.LogUptake('0000RFF', 'IdealPostcodes', Enum::"Feature Uptake Status"::Used);
        if not SendGetRequest(Config, '/autocomplete/addresses/' + TypeHelper.UriEscapeDataString(AddressId) + '/gbr', ResponseText, StatusCode, ReasonPhrase) then
            exit(false);

        ParseResolveResponse(ResponseText, TempIPCAddressLookup);
        exit(TempIPCAddressLookup.FindFirst());
    end;

    [NonDebuggable]
    local procedure SendGetRequest(var Config: Record "IPC Config"; RelativePath: Text; var ResponseText: Text; var StatusCode: Integer; var ReasonPhrase: Text): Boolean
    var
        AuditLog: Codeunit "Audit Log";
        HttpClient: HttpClient;
        HttpResponse: HttpResponseMessage;
    begin
        HttpClient.DefaultRequestHeaders().Add('Authorization', SecretStrSubstNo('IDEALPOSTCODES api_key="%1"', Config.GetAPIPasswordAsSecret(Config."API Key")));
        HttpClient.DefaultRequestHeaders().Add('Accept-Encoding', 'utf-8');
        HttpClient.DefaultRequestHeaders().Add('Accept', 'application/json');

        if not HttpClient.Get(Config.APIEndpoint() + RelativePath, HttpResponse) then
            exit(false);

        StatusCode := HttpResponse.HttpStatusCode();
        ReasonPhrase := HttpResponse.ReasonPhrase();
        if HttpResponse.IsSuccessStatusCode() then begin
            HttpResponse.Content.ReadAs(ResponseText);
            exit(true);
        end;

        if StatusCode in [401, 403] then
            AuditLog.LogAuditMessage(StrSubstNo(SecurityAuditAuthFailedTxt, StatusCode, ReasonPhrase), SecurityOperationResult::Failure, AuditCategory::Authentication, 4, 0);
        exit(false);
    end;

    procedure LookupAddress(var Address: Text[100]; var Address2: Text[50]; var City: Text[30]; var PostCode: Code[20]; var County: Text[30]; var CountryCode: Code[10])
    var
        TempIPCAddressLookup: Record "IPC Address Lookup" temporary;
        TempSelectedIPCAddressLookup: Record "IPC Address Lookup" temporary;
        AddressLookupPage: Page "IPC Address Lookup";
        SearchText, ReasonPhrase : Text;
        StatusCode: Integer;
    begin
        SearchText := PostCode;
        if SearchText = '' then
            SearchText := City;

        if SearchText = '' then
            exit;

        if not SearchAddress(SearchText, TempIPCAddressLookup, StatusCode, ReasonPhrase) then begin
            case StatusCode of
                404, 200:
                    Message(NoResultsMsg);
                else
                    Message(ResponseDetailsTxt, StatusCode, ReasonPhrase);
            end;
            Session.LogMessage('0000RFS', StrSubstNo(UnsuccessfulAddressSearchTxt, StatusCode, ReasonPhrase), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'IdealPostcodes');
        end;

        AddressLookupPage.SetRecords(TempIPCAddressLookup);
        AddressLookupPage.LookupMode(true);

        if AddressLookupPage.RunModal() = Action::LookupOK then begin
            AddressLookupPage.GetSelectedAddress(TempSelectedIPCAddressLookup);
            Address := TempSelectedIPCAddressLookup.Address;
            Address2 := TempSelectedIPCAddressLookup."Address 2";
            City := TempSelectedIPCAddressLookup.City;
            PostCode := TempSelectedIPCAddressLookup."Post Code";
            County := TempSelectedIPCAddressLookup.County;
            CountryCode := TempSelectedIPCAddressLookup."Country/Region Code";
        end;
    end;

    local procedure GetConfiguration(var Config: Record "IPC Config"): Boolean
    begin
        if Config.Get() then
            exit(true);
        exit(false);
    end;

    local procedure ParseAddressResponse(ResponseText: Text; var TempIPCAddressLookup: Record "IPC Address Lookup" temporary)
    var
        IPCConfig: Record "IPC Config";
        JsonObject: JsonObject;
        JsonArray: JsonArray;
        JsonToken: JsonToken;
        RemoveOrganisationName: Boolean;
        i: Integer;
    begin
        TempIPCAddressLookup.DeleteAll();
        RemoveOrganisationName := GetConfiguration(IPCConfig) and IPCConfig."Remove Organisation Name";

        if JsonObject.ReadFrom(ResponseText) then
            if JsonObject.Get('result', JsonToken) then begin
                JsonArray := JsonToken.AsArray();

                for i := 0 to JsonArray.Count - 1 do begin
                    JsonArray.Get(i, JsonToken);
                    AddAddressToBuffer(JsonToken.AsObject(), TempIPCAddressLookup, i + 1, RemoveOrganisationName);
                end;
            end;
    end;

    local procedure ParseResolveResponse(ResponseText: Text; var TempIPCAddressLookup: Record "IPC Address Lookup" temporary)
    var
        IPCConfig: Record "IPC Config";
        JsonObject: JsonObject;
        JsonToken: JsonToken;
        RemoveOrganisationName: Boolean;
    begin
        TempIPCAddressLookup.DeleteAll();
        RemoveOrganisationName := GetConfiguration(IPCConfig) and IPCConfig."Remove Organisation Name";

        if JsonObject.ReadFrom(ResponseText) then
            if JsonObject.Get('result', JsonToken) then
                if JsonToken.IsObject() then
                    AddAddressToBuffer(JsonToken.AsObject(), TempIPCAddressLookup, 1, RemoveOrganisationName);
    end;

    local procedure AddAddressToBuffer(AddressJson: JsonObject; var TempIPCAddressLookup: Record "IPC Address Lookup" temporary; EntryNo: Integer; RemoveOrganisationName: Boolean)
    var
        Line1, Line2, Line3 : Text;
        DisplayText: Text;
    begin
        Line1 := GetJsonValue(AddressJson, 'line_1');
        Line2 := GetJsonValue(AddressJson, 'line_2');
        Line3 := GetJsonValue(AddressJson, 'line_3');

        if RemoveOrganisationName then
            if (Line1 <> '') and (Line1 = GetJsonValue(AddressJson, 'organisation_name')) then
                if Line2 <> '' then begin
                    Line1 := Line2;
                    Line2 := Line3;
                end else begin
                    Line1 := Line3;
                    Line2 := '';
                end;

        TempIPCAddressLookup.Init();
        TempIPCAddressLookup."Entry No." := EntryNo;
        TempIPCAddressLookup."Address ID" := CopyStr(GetJsonValue(AddressJson, 'id'), 1, MaxStrLen(TempIPCAddressLookup."Address ID"));
        TempIPCAddressLookup.Address := CopyStr(Line1, 1, MaxStrLen(TempIPCAddressLookup.Address));
        TempIPCAddressLookup."Address 2" := CopyStr(Line2, 1, MaxStrLen(TempIPCAddressLookup."Address 2"));
        TempIPCAddressLookup.City := CopyStr(GetJsonValue(AddressJson, 'post_town'), 1, MaxStrLen(TempIPCAddressLookup.City));
        TempIPCAddressLookup."Post Code" := CopyStr(GetJsonValue(AddressJson, 'postcode'), 1, MaxStrLen(TempIPCAddressLookup."Post Code"));
        TempIPCAddressLookup.County := CopyStr(GetJsonValue(AddressJson, 'county'), 1, MaxStrLen(TempIPCAddressLookup.County));
        TempIPCAddressLookup."Country/Region Code" := CopyStr(GetJsonValue(AddressJson, 'country_iso_2'), 1, MaxStrLen(TempIPCAddressLookup."Country/Region Code"));

        // Create display text from address lines 1-3
        DisplayText := Line1;
        if Line2 <> '' then
            DisplayText += ', ' + Line2;
        if Line3 <> '' then
            DisplayText += ', ' + Line3;
        TempIPCAddressLookup."Display Text" := CopyStr(DisplayText, 1, MaxStrLen(TempIPCAddressLookup."Display Text"));

        TempIPCAddressLookup.Insert();
    end;

    local procedure GetJsonValue(JsonObject: JsonObject; KeyName: Text): Text
    var
        JsonToken: JsonToken;
    begin
        if JsonObject.Get(KeyName, JsonToken) then
            if not JsonToken.AsValue().IsNull then
                exit(JsonToken.AsValue().AsText());
        exit('');
    end;

    procedure TestConnection()
    var
        Config: Record "IPC Config";
        TempIPCAddressLookup: Record "IPC Address Lookup" temporary;
        StatusCode: Integer;
        ReasonPhrase: Text;
    begin
        if not GetConfiguration(Config) then
            Error(ConfigNotSetupErr);

        if IsNullGuid(Config."API Key") then
            Error(ApiKeyConfigErr);

        if Config.GetAPIPasswordAsSecret(Config."API Key").IsEmpty() then
            Error(ApiKeyConfigErr);

        SearchAddress('SW1A 2AE', TempIPCAddressLookup, StatusCode, ReasonPhrase);
        if StatusCode <> 200 then
            Message(ConnectionFailedErr + ' ' + StrSubstNo(ResponseDetailsTxt, StatusCode, ReasonPhrase))
        else
            Message(ConnectionSuccessMsg);
        exit;
    end;

    procedure IsConfigured(): Boolean
    var
        Config: Record "IPC Config";
    begin
        if not GetConfiguration(Config) then
            exit(false);

        exit(Config.Enabled and not IsNullGuid(Config."API Key"));
    end;
}