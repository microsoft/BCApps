codeunit 6378 Activation
{
    var
        InvalidActivationIdWithValueMsg: Label 'Unable to parse activation ID from JSON. Value: %1', Comment = '%1 = Activation ID text';
        // Error messages
        InvalidJsonErr: Label 'The provided JSON is invalid or malformed.';
        JsonFieldCodeTok: Label 'code', Locked = true;
        JsonFieldCompanyTok: Label 'company', Locked = true;
        JsonFieldCountryCodeTok: Label 'countryCode', Locked = true;
        JsonFieldCountryMandateTok: Label 'countryMandate', Locked = true;
        JsonFieldDisplayNameTok: Label 'displayName', Locked = true;
        JsonFieldFullAuthorityNetworkValueTok: Label 'fullAuthorityNetworkValue', Locked = true;
        JsonFieldIdentifierTok: Label 'identifier', Locked = true;
        // JSON field name constants
        JsonFieldIdTok: Label 'id', Locked = true;
        JsonFieldJurisdictionTok: Label 'jurisdiction', Locked = true;
        JsonFieldLastModifiedTok: Label 'lastModified', Locked = true;
        JsonFieldLocationTok: Label 'location', Locked = true;
        JsonFieldMandatesTok: Label 'mandates', Locked = true;
        JsonFieldMandateTypeTok: Label 'mandateType', Locked = true;
        JsonFieldMessageTok: Label 'message', Locked = true;
        JsonFieldMetaTok: Label 'meta', Locked = true;
        JsonFieldRegistrationDataTok: Label 'registrationData', Locked = true;
        JsonFieldRegistrationTypeTok: Label 'registrationType', Locked = true;
        JsonFieldSchemeIdTok: Label 'schemeId', Locked = true;
        JsonFieldStatusTok: Label 'status', Locked = true;
        JsonFieldValueTok: Label 'value', Locked = true;
        MissingValueArrayErr: Label 'The JSON response is missing the required "value" array.';
        StatusCompletedTok: Label 'Completed', Locked = true;

    procedure PopulateFromJson(JsonText: Text)
    var
        ActivationHeader: Record "Activation Header";
        ActivationMandate: Record "Activation Mandate";
    begin
        if JsonText = '' then
            Error(InvalidJsonErr);

        ClearExistingData(ActivationHeader, ActivationMandate);
        ParseAndInsertActivations(JsonText);
    end;

    local procedure ClearExistingData(var ActivationHeader: Record "Activation Header"; var ActivationMandate: Record "Activation Mandate")
    begin
        if not ActivationHeader.IsEmpty() then
            ActivationHeader.DeleteAll(true);

        if not ActivationMandate.IsEmpty() then
            ActivationMandate.DeleteAll(true);
    end;

    local procedure ParseAndInsertActivations(JsonText: Text)
    var
        RootObject: JsonObject;
        ItemToken: JsonToken;
        ValueToken: JsonToken;
    begin
        if not RootObject.ReadFrom(JsonText) then
            Error(InvalidJsonErr);

        if not RootObject.Get(JsonFieldValueTok, ValueToken) then
            Error(MissingValueArrayErr);

        if not ValueToken.IsArray() then
            Error(MissingValueArrayErr);

        foreach ItemToken in ValueToken.AsArray() do
            ProcessActivationItem(ItemToken);
    end;

    local procedure ProcessActivationItem(ItemToken: JsonToken)
    var
        ActivationHeader: Record "Activation Header";
        ItemObject: JsonObject;
    begin
        if not ItemToken.IsObject() then
            exit;

        ItemObject := ItemToken.AsObject();

        if not PopulateActivationHeader(ActivationHeader, ItemObject) then
            exit;

        if not InsertActivationHeader(ActivationHeader) then
            exit;

        ProcessMandates(ItemObject, ActivationHeader);
    end;

    local procedure PopulateActivationHeader(var ActivationHeader: Record "Activation Header"; ItemObject: JsonObject): Boolean
    var
        ConnectionSetup: Record "Connection Setup";
        ActivationId: Guid;
        ActivationIdText: Text;
        CurrentCompanyId: Text;
    begin
        ActivationHeader.Init();

        // Parse and validate Activation ID
        ActivationIdText := GetJsonText(ItemObject, JsonFieldIdTok);
        if ActivationIdText = '' then
            exit(false);

        if not Evaluate(ActivationId, ActivationIdText) then begin
            Session.LogMessage('0000AVL001', StrSubstNo(InvalidActivationIdWithValueMsg, ActivationIdText), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'Avalara Activation');
            exit(false);
        end;

        ActivationHeader.ID := ActivationId;

        // Parse registration data
        ActivationHeader."Registration Type" := CopyStr(GetJsonText(ItemObject, JsonFieldRegistrationTypeTok), 1, MaxStrLen(ActivationHeader."Registration Type"));
        ActivationHeader.Jurisdiction := CopyStr(GetNestedJsonText(ItemObject, JsonFieldRegistrationDataTok, JsonFieldJurisdictionTok), 1, MaxStrLen(ActivationHeader.Jurisdiction));
        ActivationHeader."Scheme Id" := CopyStr(GetNestedJsonText(ItemObject, JsonFieldRegistrationDataTok, JsonFieldSchemeIdTok), 1, MaxStrLen(ActivationHeader."Scheme Id"));
        ActivationHeader.Identifier := CopyStr(GetNestedJsonText(ItemObject, JsonFieldRegistrationDataTok, JsonFieldIdentifierTok), 1, MaxStrLen(ActivationHeader.Identifier));
        ActivationHeader."Full Authority Value" := CopyStr(GetNestedJsonText(ItemObject, JsonFieldRegistrationDataTok, JsonFieldFullAuthorityNetworkValueTok), 1, MaxStrLen(ActivationHeader."Full Authority Value"));

        // Parse status data
        ActivationHeader."Status Code" := CopyStr(GetNestedJsonText(ItemObject, JsonFieldStatusTok, JsonFieldCodeTok), 1, MaxStrLen(ActivationHeader."Status Code"));
        ActivationHeader."Status Message" := CopyStr(GetNestedJsonText(ItemObject, JsonFieldStatusTok, JsonFieldMessageTok), 1, MaxStrLen(ActivationHeader."Status Message"));

        // Parse company data
        ActivationHeader."Company Name" := CopyStr(GetNestedJsonText(ItemObject, JsonFieldCompanyTok, JsonFieldDisplayNameTok), 1, MaxStrLen(ActivationHeader."Company Name"));
        ActivationHeader."Company Location" := CopyStr(GetNestedJsonText(ItemObject, JsonFieldCompanyTok, JsonFieldLocationTok), 1, MaxStrLen(ActivationHeader."Company Location"));
        ActivationHeader."Company Id" := CopyStr(GetNestedJsonText(ItemObject, JsonFieldCompanyTok, JsonFieldIdentifierTok), 1, MaxStrLen(ActivationHeader."Company Id"));

        // Determine if this is the active company
        CurrentCompanyId := '';
        if ConnectionSetup.Get() then
            CurrentCompanyId := ConnectionSetup."Company Id";

        ActivationHeader."Is Active ID" := ActivationHeader."Company Id" = CurrentCompanyId;

        // Parse metadata
        ActivationHeader."Last Modified" := GetNestedJsonDateTime(ItemObject, JsonFieldMetaTok, JsonFieldLastModifiedTok);
        ActivationHeader."Meta Location" := CopyStr(GetNestedJsonText(ItemObject, JsonFieldMetaTok, JsonFieldLocationTok), 1, MaxStrLen(ActivationHeader."Meta Location"));

        exit(true);
    end;

    local procedure InsertActivationHeader(var ActivationHeader: Record "Activation Header"): Boolean
    begin
        // Use Insert(true) to trigger table triggers and validation
        if not ActivationHeader.Insert(true) then begin
            Session.LogMessage('0000AVL002', 'Failed to insert Activation Header', Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'Avalara Activation');
            exit(false);
        end;

        exit(true);
    end;

    local procedure ProcessMandates(ItemObject: JsonObject; ActivationHeader: Record "Activation Header")
    var
        MandatesToken: JsonToken;
        MandateToken: JsonToken;
    begin
        if not ItemObject.Get(JsonFieldMandatesTok, MandatesToken) then
            exit;

        if not MandatesToken.IsArray() then
            exit;

        foreach MandateToken in MandatesToken.AsArray() do
            ProcessMandateItem(MandateToken, ActivationHeader);
    end;

    local procedure ProcessMandateItem(MandateToken: JsonToken; ActivationHeader: Record "Activation Header")
    var
        ActivationMandate: Record "Activation Mandate";
        MandateObject: JsonObject;
    begin
        if not MandateToken.IsObject() then
            exit;

        MandateObject := MandateToken.AsObject();

        ActivationMandate.Init();
        ActivationMandate."Activation ID" := ActivationHeader.ID;
        ActivationMandate."Country Mandate" := CopyStr(GetJsonText(MandateObject, JsonFieldCountryMandateTok), 1, MaxStrLen(ActivationMandate."Country Mandate"));
        ActivationMandate."Country Code" := CopyStr(GetJsonText(MandateObject, JsonFieldCountryCodeTok), 1, MaxStrLen(ActivationMandate."Country Code"));
        ActivationMandate."Mandate Type" := CopyStr(GetJsonText(MandateObject, JsonFieldMandateTypeTok), 1, MaxStrLen(ActivationMandate."Mandate Type"));
        ActivationMandate."Company Id" := ActivationHeader."Company Id";
        ActivationMandate.Activated := ActivationHeader."Status Code" = StatusCompletedTok;

        // Use Insert(true) to trigger table triggers and validation
        if not ActivationMandate.Insert(true) then
            Session.LogMessage('0000AVL003', 'Failed to insert Activation Mandate', Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'Avalara Activation');
    end;

    local procedure GetNestedJsonText(JsonObj: JsonObject; ParentFieldName: Text; ChildFieldName: Text): Text
    var
        ParentObject: JsonObject;
        ParentToken: JsonToken;
    begin
        if not JsonObj.Get(ParentFieldName, ParentToken) then
            exit('');

        if not ParentToken.IsObject() then
            exit('');

        ParentObject := ParentToken.AsObject();
        exit(GetJsonText(ParentObject, ChildFieldName));
    end;

    local procedure GetNestedJsonDateTime(JsonObj: JsonObject; ParentFieldName: Text; ChildFieldName: Text): DateTime
    var
        DateTimeValue: DateTime;
        ParentObject: JsonObject;
        ParentToken: JsonToken;
        DateTimeText: Text;
    begin
        if not JsonObj.Get(ParentFieldName, ParentToken) then
            exit(0DT);

        if not ParentToken.IsObject() then
            exit(0DT);

        ParentObject := ParentToken.AsObject();
        DateTimeText := GetJsonText(ParentObject, ChildFieldName);

        if DateTimeText = '' then
            exit(0DT);

        // Try to evaluate the full datetime string
        if Evaluate(DateTimeValue, DateTimeText) then
            exit(DateTimeValue);

        // Fallback: Try to parse first 19 characters (ISO 8601 format: YYYY-MM-DDTHH:MM:SS)
        if StrLen(DateTimeText) >= 19 then
            if Evaluate(DateTimeValue, CopyStr(DateTimeText, 1, 19)) then
                exit(DateTimeValue);

        exit(0DT);
    end;

    local procedure GetJsonText(JsonObj: JsonObject; FieldName: Text): Text
    var
        FieldToken: JsonToken;
        FieldValue: JsonValue;
    begin
        if not JsonObj.Get(FieldName, FieldToken) then
            exit('');

        if not FieldToken.IsValue() then
            exit('');

        FieldValue := FieldToken.AsValue();

        if FieldValue.IsNull() then
            exit('');

        exit(FieldValue.AsText());
    end;
}