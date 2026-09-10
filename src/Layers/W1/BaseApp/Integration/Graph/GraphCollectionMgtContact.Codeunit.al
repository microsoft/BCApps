// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Graph;

using Microsoft.CRM.Comment;
using Microsoft.CRM.Contact;
using Microsoft.Foundation.Address;
using System;
using System.Reflection;
using System.Text;

codeunit 5458 "Graph Collection Mgt - Contact"
{

    trigger OnRun()
    begin
    end;

    var
        JsonArrayState: JsonArray;
        JsonObjectState: JsonObject;
        SelectedCollectionIndex: Integer;
        HasSelectedCollectionIndex: Boolean;
        WebsiteType: Option Other,Home,Work,Blog,"Profile";
        PhoneType: Option Home,Business,Mobile,Other,Assistant,HomeFax,BusinessFax,OtherFax,Pager,Radio;
        AddressType: Option Unknown,Home,Business,Other;
        BusinessType: Option Company,Individual;
        FlagStatusOption: Option NotFlagged,Complete,Flagged;
        PropertyIdErr: Label 'The PropertyId is not correct. Expected: %1, Actual %2.', Comment = '%1 and %2 are a string like: ''Integer {47ac1412-279b-41cb-891e-58904a94a48b} Name IsCustomer'' ';
        BusinessTypePropertyIdTxt: Label 'String {bdba944b-fc2b-47a1-8ba4-cafc4ae13ea2} Name BusinessType', Locked = true;
        IsCustomerPropertyIdTxt: Label 'Integer {47ac1412-279b-41cb-891e-58904a94a48b} Name IsCustomer', Locked = true;
        IsVendorPropertyIdTxt: Label 'Integer {ccf57c46-c10e-41bb-b8c5-362b185d2f98} Name IsVendor', Locked = true;
        IsBankPropertyIdTxt: Label 'Integer {a8ef117a-16d9-4cc6-965a-d2fbe0177e61} Name IsBank', Locked = true;
        IsNavCreatedPropertyIdTxt: Label 'Integer {6023a623-3b6c-492d-9ef5-811850c088ac} Name IsNavCreated', Locked = true;
        IsLeadPropertyIdTxt: Label 'Integer {37829b75-e5e4-4582-ae12-36f754e4bd7b} Name IsLead', Locked = true;
        IsContactPropertyIdTxt: Label 'Integer {f4be2302-782e-483d-8ba4-26fb6535f665} Name IsContact', Locked = true;
        IsPartnerPropertyIdTxt: Label 'Integer {65ebabde-6946-455f-b918-a88ee36182a9} Name IsPartner', Locked = true;
        NavIntegrationIdTxt: Label 'String {d048f561-4dd0-443c-a8d8-f397fb74f1df} Name NavIntegrationId', Locked = true;

    procedure GetEmailAddress(Index: Integer; var Name: Text; var Address: Text)
    var
        JObject: JsonObject;
    begin
        Clear(Name);
        Clear(Address);
        if Index >= GetCollectionCount() then
            exit;

        GetJObjectFromCollectionByIndex(JObject, Index);
        GetStringPropertyValueFromJObjectByName(JObject, 'Name', Name);
        GetStringPropertyValueFromJObjectByName(JObject, 'Address', Address);
    end;

    procedure AddEmailAddress(Name: Text; Address: Text)
    var
        JObject: JsonObject;
    begin
        if Address = '' then
            exit;

        JObject.Add('Name', Name);
        JObject.Add('Address', Address);
        AddJObjectToCollection(JObject);
    end;

    procedure UpdateEmailAddress(EmailAddressesString: Text; Index: Integer; Address: Text): Text
    var
        JObject: JsonObject;
    begin
        InitializeCollection(EmailAddressesString);
        if Index > GetCollectionCount() then // cannot add where index would leave empty slots.
            exit(EmailAddressesString);

        if GetJObjectFromCollectionByIndex(JObject, Index) then begin
            ReplaceOrAddJPropertyInJObject(JObject, 'Name', '');
            ReplaceOrAddJPropertyInJObject(JObject, 'Address', Address)
        end else
            AddEmailAddress('', Address);

        exit(WriteCollectionToString());
    end;

    procedure GetWebsiteByIndex(Index: Integer; var Type: Option; var Address: Text; var DisplayName: Text; var Name: Text)
    var
        JObject: JsonObject;
    begin
        if Index >= GetCollectionCount() then
            exit;

        GetJObjectFromCollectionByIndex(JObject, Index);
        GetEnumPropertyValueFromJObjectByName(JObject, 'Type', Type);
        GetStringPropertyValueFromJObjectByName(JObject, 'Address', Address);
        GetStringPropertyValueFromJObjectByName(JObject, 'DisplayName', DisplayName);
        GetStringPropertyValueFromJObjectByName(JObject, 'Name', Name);
    end;

    local procedure GetWebsiteByType(Type: Option; var Address: Text; var DisplayName: Text; var Name: Text)
    var
        JObject: JsonObject;
    begin
        WebsiteType := Type;
        if not GetJObjectFromCollectionByPropertyValue(JObject, 'Type', Format(WebsiteType, 0, 0)) then
            exit;
        GetStringPropertyValueFromJObjectByName(JObject, 'Address', Address);
        GetStringPropertyValueFromJObjectByName(JObject, 'DisplayName', DisplayName);
        GetStringPropertyValueFromJObjectByName(JObject, 'Name', Name);
    end;

    procedure AddWebsite(Type: Option; Address: Text; DisplayName: Text; Name: Text)
    var
        JObject: JsonObject;
    begin
        if Address = '' then
            exit;
        WebsiteType := Type;
        JObject.Add('Type', Format(WebsiteType, 0, 0));
        JObject.Add('Address', Address);
        JObject.Add('DisplayName', DisplayName);
        JObject.Add('Name', Name);
        AddJObjectToCollection(JObject);
    end;

    procedure UpdateWebsite(Type: Option; Address: Text)
    var
        JObject: JsonObject;
    begin
        WebsiteType := Type;
        if not GetJObjectFromCollectionByPropertyValue(JObject, 'Type', Format(WebsiteType, 0, 0)) then begin
            if Address = '' then
                exit;
            AddJObjectToCollection(JObject);
        end else
            JObject.Remove('Type');
        ReplaceOrAddJPropertyInJObject(JObject, 'Address', Address);
    end;

    procedure GetImAddress(Index: Integer; var ImAddress: Text)
    var
        JsonToken: JsonToken;
    begin
        if Index >= GetCollectionCount() then
            exit;

        GetTokenFromCollectionByIndex(JsonToken, Index);
        GetStringValueFromJsonToken(JsonToken, ImAddress);
    end;

    procedure AddImAddress(ImAddress: Text)
    begin
        if ImAddress = '' then
            exit;

        AddValueToCollection(ImAddress);
    end;

    procedure GetPhoneByIndex(Index: Integer; var Type: Option; var Number: Text)
    var
        JObject: JsonObject;
    begin
        if Index >= GetCollectionCount() then
            exit;

        GetJObjectFromCollectionByIndex(JObject, Index);
        GetEnumPropertyValueFromJObjectByName(JObject, 'Type', Type);
        GetStringPropertyValueFromJObjectByName(JObject, 'Number', Number);
    end;

    procedure GetPhoneByType(Type: Option; var Number: Text)
    var
        JObject: JsonObject;
    begin
        PhoneType := Type;
        if not GetJObjectFromCollectionByPropertyValue(JObject, 'Type', Format(PhoneType, 0, 0)) then
            exit;

        GetStringPropertyValueFromJObjectByName(JObject, 'Number', Number);
    end;

    procedure AddPhone(Type: Option; Number: Text)
    var
        JObject: JsonObject;
    begin
        PhoneType := Type;
        if Number = '' then
            exit;

        JObject.Add('Type', Format(PhoneType, 0, 0));
        JObject.Add('Number', Number);
        AddJObjectToCollection(JObject);
    end;

    procedure GetPostalAddressByIndex(Index: Integer; var Type: Option; var PostOfficeBox: Text; var Street: Text; var City: Text; var State: Text; var CountryOrRegion: Text; var PostalCode: Text)
    var
        JObject: JsonObject;
    begin
        if Index >= GetCollectionCount() then
            exit;

        GetJObjectFromCollectionByIndex(JObject, Index);
        GetEnumPropertyValueFromJObjectByName(JObject, 'Type', Type);
        GetStringPropertyValueFromJObjectByName(JObject, 'PostOfficeBox', PostOfficeBox);
        GetStringPropertyValueFromJObjectByName(JObject, 'Street', Street);
        GetStringPropertyValueFromJObjectByName(JObject, 'City', City);
        GetStringPropertyValueFromJObjectByName(JObject, 'State', State);
        GetStringPropertyValueFromJObjectByName(JObject, 'CountryOrRegion', CountryOrRegion);
        GetStringPropertyValueFromJObjectByName(JObject, 'PostalCode', PostalCode);
    end;

    local procedure GetPostalAddressByType(Type: Option; var Address: Text[100]; var Address2: Text[50]; var City: Text[30]; var County: Text[30]; var CountryRegionCode: Code[10]; var PostCode: Code[20])
    var
        JObject: JsonObject;
        value: Text;
    begin
        AddressType := Type;
        if not GetJObjectFromCollectionByPropertyValue(JObject, 'Type', Format(AddressType, 0, 0)) then
            exit;

        GetStringPropertyValueFromJObjectByName(JObject, 'Street', value);
        SplitStreet(value, Address, Address2);
        GetStringPropertyValueFromJObjectByName(JObject, 'City', value);
        City := CopyStr(value, 1, MaxStrLen(value));
        GetStringPropertyValueFromJObjectByName(JObject, 'State', value);
        County := CopyStr(value, 1, MaxStrLen(value));
        GetStringPropertyValueFromJObjectByName(JObject, 'CountryOrRegion', value);
        CountryRegionCode := FindCountryRegionCode(value);
        GetStringPropertyValueFromJObjectByName(JObject, 'PostalCode', value);
        PostCode := CopyStr(value, 1, MaxStrLen(PostCode));
    end;

    procedure AddPostalAddress(Type: Option; PostOfficeBox: Text; Street: Text; City: Text; State: Text; CountryOrRegion: Text; PostalCode: Text)
    var
        JObject: JsonObject;
    begin
        AddressType := Type;
        JObject.Add('Type', Format(AddressType, 0, 0));
        JObject.Add('PostOfficeBox', PostOfficeBox);
        JObject.Add('Street', Street);
        JObject.Add('City', City);
        JObject.Add('State', State);
        JObject.Add('CountryOrRegion', CountryOrRegion);
        JObject.Add('PostalCode', PostalCode);
        AddJObjectToCollection(JObject);
    end;

    procedure GetChildren(Index: Integer; var Child: Text)
    var
        JsonToken: JsonToken;
    begin
        if Index >= GetCollectionCount() then
            exit;

        GetTokenFromCollectionByIndex(JsonToken, Index);
        GetStringValueFromJsonToken(JsonToken, Child);
    end;

    procedure AddChildren(Child: Text)
    begin
        if Child = '' then
            exit;

        AddValueToCollection(Child);
    end;

    procedure GetFlag(var CompletedDateTime: Text; var CompletedTimeZone: Text; var DueDateTime: Text; var DueTimeZone: Text; var StartDateTime: Text; var StartTimeZone: Text; var FlagStatus: Option)
    var
        CurrentJsonObject: JsonObject;
        NestedJsonObject: JsonObject;
        JsonToken: JsonToken;
    begin
        GetJSONObject(CurrentJsonObject);
        if CurrentJsonObject.Get('CompletedDateTime', JsonToken) and JsonToken.IsObject() then begin
            NestedJsonObject := JsonToken.AsObject();
            GetStringPropertyValueFromJObjectByName(NestedJsonObject, 'CompletedDateTime', CompletedDateTime);
            GetStringPropertyValueFromJObjectByName(NestedJsonObject, 'CompletedTimeZone', CompletedTimeZone);
        end;
        if CurrentJsonObject.Get('DueDateTime', JsonToken) and JsonToken.IsObject() then begin
            NestedJsonObject := JsonToken.AsObject();
            GetStringPropertyValueFromJObjectByName(NestedJsonObject, 'DateTime', DueDateTime);
            GetStringPropertyValueFromJObjectByName(NestedJsonObject, 'TimeZone', DueTimeZone);
        end;
        if CurrentJsonObject.Get('StartDateTime', JsonToken) and JsonToken.IsObject() then begin
            NestedJsonObject := JsonToken.AsObject();
            GetStringPropertyValueFromJObjectByName(NestedJsonObject, 'DateTime', StartDateTime);
            GetStringPropertyValueFromJObjectByName(NestedJsonObject, 'TimeZone', StartTimeZone);
        end;

        GetEnumPropertyValueFromJObjectByName(CurrentJsonObject, 'FlagStatus', FlagStatusOption);
        FlagStatus := FlagStatusOption;
    end;

    procedure AddFlag(CompletedDateTime: Text; CompletedTimeZone: Text; DueDateTime: Text; DueTimeZone: Text; StartDateTime: Text; StartTimeZone: Text; FlagStatus: Option)
    var
        JObject: JsonObject;
        CurrentJsonObject: JsonObject;
    begin
        GetJSONObject(CurrentJsonObject);

        JObject.Add('DateTime', CompletedDateTime);
        JObject.Add('TimeZone', CompletedTimeZone);
        CurrentJsonObject.Add('CompletedDateTime', JObject);
        Clear(JObject);

        JObject.Add('DateTime', DueDateTime);
        JObject.Add('TimeZone', DueTimeZone);
        CurrentJsonObject.Add('DueDateTime', JObject);
        Clear(JObject);
        JObject.Add('DateTime', StartDateTime);
        JObject.Add('TimeZone', StartTimeZone);
        CurrentJsonObject.Add('StartDateTime', JObject);
        FlagStatusOption := FlagStatus;
        CurrentJsonObject.Add('FlagStatus', Format(FlagStatusOption, 0, 0));
    end;

    procedure GetCategory(Index: Integer; var Category: Text)
    var
        JsonToken: JsonToken;
    begin
        if Index >= GetCollectionCount() then
            exit;

        GetTokenFromCollectionByIndex(JsonToken, Index);
        GetStringValueFromJsonToken(JsonToken, Category);
    end;

    procedure AddCategory(Category: Text)
    begin
        AddValueToCollection(Category);
    end;

    local procedure HasPostalAddress(Type: Option): Boolean
    var
        JObject: JsonObject;
    begin
        AddressType := Type;
        exit(GetJObjectFromCollectionByPropertyValue(JObject, 'Type', Format(AddressType, 0, 0)))
    end;

    procedure HasHomeAddressOrPhone(PostalAddressesString: Text; PhonesString: Text; WebsitesString: Text): Boolean
    var
        HasAddress: Boolean;
        HasPhones: Boolean;
    begin
        InitializeCollection(PostalAddressesString);
        HasAddress := HasPostalAddress(AddressType::Home);
        InitializeCollection(PhonesString);
        HasPhones := HasPhone(PhoneType::Home) or HasPhone(PhoneType::HomeFax);
        InitializeCollection(WebsitesString);
        exit(HasAddress or HasPhones or HasWebsite(WebsiteType::Home));
    end;

    procedure HasBusinessAddressOrPhone(PostalAddressesString: Text; PhonesString: Text; WebsitesString: Text): Boolean
    var
        HasAddress: Boolean;
        HasPhones: Boolean;
    begin
        InitializeCollection(PostalAddressesString);
        HasAddress := HasPostalAddress(AddressType::Business);
        InitializeCollection(PhonesString);
        HasPhones := HasPhone(PhoneType::Business) or HasPhone(PhoneType::BusinessFax);
        InitializeCollection(WebsitesString);
        exit(HasAddress or HasPhones or HasWebsite(WebsiteType::Work));
    end;

    procedure HasBusinessAddress(PostalAddressesString: Text): Boolean
    begin
        InitializeCollection(PostalAddressesString);
        exit(HasPostalAddress(AddressType::Business));
    end;

    procedure HasOtherAddressOrPhone(PostalAddressesString: Text; PhonesString: Text; WebsitesString: Text): Boolean
    var
        HasAddress: Boolean;
        HasPhones: Boolean;
    begin
        InitializeCollection(PostalAddressesString);
        HasAddress := HasPostalAddress(AddressType::Other);
        InitializeCollection(PhonesString);
        HasPhones := HasPhone(PhoneType::Other) or HasPhone(PhoneType::OtherFax);
        InitializeCollection(WebsitesString);
        exit(HasAddress or HasPhones or HasWebsite(WebsiteType::Other));
    end;

    local procedure UpdatePostalAddress(Type: Option; Address: Text[100]; Address2: Text[50]; City: Text[30]; County: Text[30]; CountryRegionCode: Code[10]; PostCode: Code[20])
    var
        JObject: JsonObject;
    begin
        AddressType := Type;
        if (Address = '') and (Address2 = '') and (City = '') and (County = '') and (PostCode = '') then begin
            if GetJObjectFromCollectionByPropertyValue(JObject, 'Type', Format(AddressType, 0, 0)) then
                RemoveSelectedJObjectFromCollection();
            exit;
        end;

        if not GetJObjectFromCollectionByPropertyValue(JObject, 'Type', Format(AddressType, 0, 0)) then begin
            JObject.Add('Type', Format(AddressType, 0, 0));
            AddJObjectToCollection(JObject);
            GetJObjectFromCollectionByPropertyValue(JObject, 'Type', Format(AddressType, 0, 0));
        end;
        ReplaceOrAddJPropertyInJObject(JObject, 'Street', ConcatenateStreet(Address, Address2));
        ReplaceOrAddJPropertyInJObject(JObject, 'City', City);
        ReplaceOrAddJPropertyInJObject(JObject, 'State', County);
        ReplaceOrAddJPropertyInJObject(JObject, 'CountryOrRegion', CountryRegionCode);
        ReplaceOrAddJPropertyInJObject(JObject, 'PostalCode', PostCode);
    end;

    procedure UpdateHomeAddress(PostalAddressesString: Text; Address: Text[100]; Address2: Text[50]; City: Text[30]; County: Text[30]; CountryRegionCode: Code[10]; PostCode: Code[20]): Text
    begin
        InitializeCollection(PostalAddressesString);
        UpdatePostalAddress(AddressType::Home, Address, Address2, City, County, CountryRegionCode, PostCode);
        exit(WriteCollectionToString());
    end;

    procedure UpdateBusinessAddress(PostalAddressesString: Text; Address: Text[100]; Address2: Text[50]; City: Text[30]; County: Text[30]; CountryRegionCode: Code[10]; PostCode: Code[20]): Text
    begin
        InitializeCollection(PostalAddressesString);
        UpdatePostalAddress(AddressType::Business, Address, Address2, City, County, CountryRegionCode, PostCode);
        exit(WriteCollectionToString());
    end;

    procedure UpdateOtherAddress(PostalAddressesString: Text; Address: Text[100]; Address2: Text[50]; City: Text[30]; County: Text[30]; CountryRegionCode: Code[10]; PostCode: Code[20]): Text
    begin
        InitializeCollection(PostalAddressesString);
        UpdatePostalAddress(AddressType::Other, Address, Address2, City, County, CountryRegionCode, PostCode);
        exit(WriteCollectionToString());
    end;

    procedure GetHomeAddress(PostalAddressesString: Text; var Address: Text[100]; var Address2: Text[50]; var City: Text[30]; var County: Text[30]; var CountryRegionCode: Code[10]; var PostCode: Code[20])
    begin
        InitializeCollection(PostalAddressesString);
        GetPostalAddressByType(AddressType::Home, Address, Address2, City, County, CountryRegionCode, PostCode);
    end;

    procedure GetBusinessAddress(PostalAddressesString: Text; var Address: Text[100]; var Address2: Text[50]; var City: Text[30]; var County: Text[30]; var CountryRegionCode: Code[10]; var PostCode: Code[20])
    begin
        InitializeCollection(PostalAddressesString);
        GetPostalAddressByType(AddressType::Business, Address, Address2, City, County, CountryRegionCode, PostCode);
    end;

    procedure GetOtherAddress(PostalAddressesString: Text; var Address: Text[100]; var Address2: Text[50]; var City: Text[30]; var County: Text[30]; var CountryRegionCode: Code[10]; var PostCode: Code[20])
    begin
        InitializeCollection(PostalAddressesString);
        GetPostalAddressByType(AddressType::Other, Address, Address2, City, County, CountryRegionCode, PostCode);
    end;

    local procedure HasPhone(Type: Option): Boolean
    var
        JObject: JsonObject;
    begin
        PhoneType := Type;
        exit(GetJObjectFromCollectionByPropertyValue(JObject, 'Type', Format(PhoneType, 0, 0)));
    end;

    local procedure UpdatePhone(Type: Option; Number: Text)
    var
        JObject: JsonObject;
    begin
        PhoneType := Type;
        if not GetJObjectFromCollectionByPropertyValue(JObject, 'Type', Format(PhoneType, 0, 0)) then begin
            if Number = '' then
                exit;
            JObject.Add('Type', Format(PhoneType, 0, 0));
            AddJObjectToCollection(JObject);
            GetJObjectFromCollectionByPropertyValue(JObject, 'Type', Format(PhoneType, 0, 0))
        end;
        ReplaceOrAddJPropertyInJObject(JObject, 'Number', Number);
    end;

    procedure UpdateHomePhone(PhonesString: Text; Number: Text): Text
    begin
        InitializeCollection(PhonesString);
        UpdatePhone(PhoneType::Home, Number);
        exit(WriteCollectionToString());
    end;

    procedure UpdateBusinessPhone(PhonesString: Text; Number: Text): Text
    begin
        InitializeCollection(PhonesString);
        UpdatePhone(PhoneType::Business, Number);
        exit(WriteCollectionToString());
    end;

    procedure UpdateMobilePhone(PhonesString: Text; Number: Text): Text
    begin
        InitializeCollection(PhonesString);
        UpdatePhone(PhoneType::Mobile, Number);
        exit(WriteCollectionToString());
    end;

    procedure UpdateOtherPhone(PhonesString: Text; Number: Text): Text
    begin
        InitializeCollection(PhonesString);
        UpdatePhone(PhoneType::Other, Number);
        exit(WriteCollectionToString());
    end;

    procedure UpdateAssistantPhone(PhonesString: Text; Number: Text): Text
    begin
        InitializeCollection(PhonesString);
        UpdatePhone(PhoneType::Assistant, Number);
        exit(WriteCollectionToString());
    end;

    procedure UpdateHomeFaxPhone(PhonesString: Text; Number: Text): Text
    begin
        InitializeCollection(PhonesString);
        UpdatePhone(PhoneType::HomeFax, Number);
        exit(WriteCollectionToString());
    end;

    procedure UpdateBusinessFaxPhone(PhonesString: Text; Number: Text): Text
    begin
        InitializeCollection(PhonesString);
        UpdatePhone(PhoneType::BusinessFax, Number);
        exit(WriteCollectionToString());
    end;

    procedure UpdateOtherFaxPhone(PhonesString: Text; Number: Text): Text
    begin
        InitializeCollection(PhonesString);
        UpdatePhone(PhoneType::OtherFax, Number);
        exit(WriteCollectionToString());
    end;

    procedure UpdatePagerPhone(PhonesString: Text; Number: Text): Text
    begin
        InitializeCollection(PhonesString);
        UpdatePhone(PhoneType::Pager, Number);
        exit(WriteCollectionToString());
    end;

    procedure UpdateRadioPhone(PhonesString: Text; Number: Text): Text
    begin
        InitializeCollection(PhonesString);
        UpdatePhone(PhoneType::Radio, Number);
        exit(WriteCollectionToString());
    end;

    procedure GetHomePhone(PhonesString: Text; var Number: Text)
    begin
        InitializeCollection(PhonesString);
        GetPhoneByType(PhoneType::Home, Number);
    end;

    procedure GetBusinessPhone(PhonesString: Text; var Number: Text)
    begin
        InitializeCollection(PhonesString);
        GetPhoneByType(PhoneType::Business, Number);
    end;

    procedure GetMobilePhone(PhonesString: Text; var Number: Text)
    begin
        InitializeCollection(PhonesString);
        GetPhoneByType(PhoneType::Mobile, Number);
    end;

    procedure GetOtherPhone(PhonesString: Text; var Number: Text)
    begin
        InitializeCollection(PhonesString);
        GetPhoneByType(PhoneType::Other, Number);
    end;

    procedure GetAssistantPhone(PhonesString: Text; var Number: Text)
    begin
        InitializeCollection(PhonesString);
        GetPhoneByType(PhoneType::Assistant, Number);
    end;

    procedure GetHomeFaxPhone(PhonesString: Text; var Number: Text)
    begin
        InitializeCollection(PhonesString);
        GetPhoneByType(PhoneType::HomeFax, Number);
    end;

    procedure GetBusinessFaxPhone(PhonesString: Text; var Number: Text)
    begin
        InitializeCollection(PhonesString);
        GetPhoneByType(PhoneType::BusinessFax, Number);
    end;

    procedure GetOtherFaxPhone(PhonesString: Text; var Number: Text)
    begin
        InitializeCollection(PhonesString);
        GetPhoneByType(PhoneType::OtherFax, Number);
    end;

    procedure GetPagerPhone(PhonesString: Text; var Number: Text)
    begin
        InitializeCollection(PhonesString);
        GetPhoneByType(PhoneType::Pager, Number);
    end;

    procedure GetRadioPhone(PhonesString: Text; var Number: Text)
    begin
        InitializeCollection(PhonesString);
        GetPhoneByType(PhoneType::Radio, Number);
    end;

    local procedure HasWebsite(Type: Option): Boolean
    var
        JObject: JsonObject;
    begin
        WebsiteType := Type;
        exit(GetJObjectFromCollectionByPropertyValue(JObject, 'Type', Format(WebsiteType, 0, 0)));
    end;

    procedure GetWorkWebsite(WebsitesString: Text; var Address: Text[80])
    var
        Name: Text;
        DisplayName: Text;
    begin
        InitializeCollection(WebsitesString);
        GetWebsiteByType(WebsiteType::Work, Address, Name, DisplayName);
    end;

    procedure GetHomeWebsite(WebsitesString: Text; var Address: Text[80])
    var
        Name: Text;
        DisplayName: Text;
    begin
        InitializeCollection(WebsitesString);
        GetWebsiteByType(WebsiteType::Home, Address, Name, DisplayName);
    end;

    procedure UpdateWorkWebsite(WebsitesString: Text; Address: Text[80]): Text
    begin
        InitializeCollection(WebsitesString);
        UpdateWebsite(WebsiteType::Work, Address);
        exit(WriteCollectionToString());
    end;

    procedure UpdateHomeWebsite(WebsitesString: Text; Address: Text[80]): Text
    begin
        InitializeCollection(WebsitesString);
        UpdateWebsite(WebsiteType::Home, Address);
        exit(WriteCollectionToString());
    end;

    procedure HasBusinessType(BusinessTypeString: Text): Boolean
    begin
        exit(HasExtendedProperty(BusinessTypeString, BusinessTypePropertyIdTxt));
    end;

    [TryFunction]
    procedure TryGetBusinessTypeValue(BusinessTypeString: Text; var Value: Text)
    var
        JsonObject: JsonObject;
        PropertyId: Text;
    begin
        InitializeObject(BusinessTypeString);
        GetJSONObject(JsonObject);
        GetStringPropertyValueFromJObjectByName(JsonObject, 'PropertyId', PropertyId);
        if not (PropertyId = BusinessTypePropertyIdTxt) then
            Error(PropertyIdErr, BusinessTypePropertyIdTxt, PropertyId);
        GetStringPropertyValueFromJObjectByName(JsonObject, 'Value', Value);
        Evaluate(BusinessType, Value, 0);
    end;

    procedure GetBusinessType(BusinessTypeString: Text; var Type: Option)
    var
        JsonObject: JsonObject;
        PropertyId: Text;
    begin
        InitializeObject(BusinessTypeString);
        GetJSONObject(JsonObject);
        if GetStringPropertyValueFromJObjectByName(JsonObject, 'PropertyId', PropertyId) then
            if PropertyId = BusinessTypePropertyIdTxt then begin
                GetEnumPropertyValueFromJObjectByName(JsonObject, 'Value', BusinessType);
                Type := BusinessType;
                exit;
            end;

        Type := BusinessType::Individual;
    end;

    procedure AddBusinessType(Type: Option): Text
    var
        JsonObject: JsonObject;
    begin
        InitializeEmptyObject();
        GetJSONObject(JsonObject);
        BusinessType := Type;
        JsonObject.Add('PropertyId', BusinessTypePropertyIdTxt);
        JsonObject.Add('Value', Format(BusinessType, 0, 0));
        exit(WriteObjectToString());
    end;

    local procedure HasExtendedProperty(ExtendedPropertyString: Text; ExpectedPropertyId: Text): Boolean
    var
        JsonObject: JsonObject;
        PropertyId: Text;
    begin
        InitializeObject(ExtendedPropertyString);
        GetJSONObject(JsonObject);
        if GetStringPropertyValueFromJObjectByName(JsonObject, 'PropertyId', PropertyId) then
            exit(ExpectedPropertyId = PropertyId);
    end;

    local procedure GetExtendedPropertyBoolValue(ExtendedPropertyString: Text; ExpectedPropertyId: Text; var Value: Text)
    var
        JsonObject: JsonObject;
        PropertyId: Text;
        BooleanValue: Boolean;
    begin
        InitializeObject(ExtendedPropertyString);
        GetJSONObject(JsonObject);
        GetStringPropertyValueFromJObjectByName(JsonObject, 'PropertyId', PropertyId);
        if not (PropertyId = ExpectedPropertyId) then
            Error(PropertyIdErr, ExpectedPropertyId, PropertyId);
        GetStringPropertyValueFromJObjectByName(JsonObject, 'Value', Value);
        Evaluate(BooleanValue, Value, 2);
    end;

    procedure HasIsCustomer(IsCustomerString: Text): Boolean
    begin
        exit(HasExtendedProperty(IsCustomerString, IsCustomerPropertyIdTxt));
    end;

    procedure GetIsCustomer(IsCustomerString: Text) IsCustomer: Boolean
    var
        JsonObject: JsonObject;
        PropertyId: Text;
    begin
        InitializeObject(IsCustomerString);
        GetJSONObject(JsonObject);

        if GetStringPropertyValueFromJObjectByName(JsonObject, 'PropertyId', PropertyId) then
            if PropertyId = IsCustomerPropertyIdTxt then begin
                GetBoolPropertyValueFromJObjectByName(JsonObject, 'Value', IsCustomer);
                exit(IsCustomer);
            end;

        exit(false);
    end;

    [TryFunction]
    procedure TryGetIsCustomerValue(IsCustomerString: Text; var Value: Text)
    begin
        GetExtendedPropertyBoolValue(IsCustomerString, IsCustomerPropertyIdTxt, Value);
    end;

    procedure AddIsCustomer(IsCustomer: Boolean): Text
    var
        JsonObject: JsonObject;
    begin
        InitializeEmptyObject();
        GetJSONObject(JsonObject);

        JsonObject.Add('PropertyId', IsCustomerPropertyIdTxt);
        JsonObject.Add('Value', Format(IsCustomer, 0, 2));

        exit(WriteObjectToString());
    end;

    procedure HasIsVendor(IsVendorString: Text): Boolean
    begin
        exit(HasExtendedProperty(IsVendorString, IsVendorPropertyIdTxt));
    end;

    procedure GetIsVendor(IsVendorString: Text) IsVendor: Boolean
    var
        JsonObject: JsonObject;
        PropertyId: Text;
    begin
        InitializeObject(IsVendorString);
        GetJSONObject(JsonObject);

        if GetStringPropertyValueFromJObjectByName(JsonObject, 'PropertyId', PropertyId) then
            if PropertyId = IsVendorPropertyIdTxt then begin
                GetBoolPropertyValueFromJObjectByName(JsonObject, 'Value', IsVendor);
                exit(IsVendor);
            end;
        exit(false);
    end;

    [TryFunction]
    procedure TryGetIsVendorValue(IsVendorString: Text; var Value: Text)
    begin
        GetExtendedPropertyBoolValue(IsVendorString, IsVendorPropertyIdTxt, Value);
    end;

    procedure AddIsVendor(IsVendor: Boolean): Text
    var
        JsonObject: JsonObject;
    begin
        InitializeEmptyObject();
        GetJSONObject(JsonObject);

        JsonObject.Add('PropertyId', IsVendorPropertyIdTxt);
        JsonObject.Add('Value', Format(IsVendor, 0, 2));

        exit(WriteObjectToString());
    end;

    procedure HasIsBank(IsBankString: Text): Boolean
    begin
        exit(HasExtendedProperty(IsBankString, IsBankPropertyIdTxt));
    end;

    procedure GetIsBank(IsBankString: Text) IsBank: Boolean
    var
        JsonObject: JsonObject;
        PropertyId: Text;
    begin
        InitializeObject(IsBankString);
        GetJSONObject(JsonObject);

        if GetStringPropertyValueFromJObjectByName(JsonObject, 'PropertyId', PropertyId) then
            if PropertyId = IsBankPropertyIdTxt then begin
                GetBoolPropertyValueFromJObjectByName(JsonObject, 'Value', IsBank);
                exit(IsBank);
            end;
        exit(false);
    end;

    [TryFunction]
    procedure TryGetIsBankValue(IsBankString: Text; var Value: Text)
    begin
        GetExtendedPropertyBoolValue(IsBankString, IsBankPropertyIdTxt, Value);
    end;

    procedure AddIsBank(IsBank: Boolean): Text
    var
        JsonObject: JsonObject;
    begin
        InitializeEmptyObject();
        GetJSONObject(JsonObject);

        JsonObject.Add('PropertyId', IsBankPropertyIdTxt);
        JsonObject.Add('Value', Format(IsBank, 0, 2));

        exit(WriteObjectToString());
    end;

    procedure GetIsNavCreated(IsNavCreatedString: Text) IsNavCreated: Boolean
    var
        JsonObject: JsonObject;
        PropertyId: Text;
    begin
        InitializeObject(IsNavCreatedString);
        GetJSONObject(JsonObject);

        if GetStringPropertyValueFromJObjectByName(JsonObject, 'PropertyId', PropertyId) then
            if PropertyId = IsNavCreatedPropertyIdTxt then begin
                GetBoolPropertyValueFromJObjectByName(JsonObject, 'Value', IsNavCreated);
                exit(IsNavCreated);
            end;
        exit(false);
    end;

    procedure AddIsNavCreated(IsNavCreated: Boolean): Text
    var
        JsonObject: JsonObject;
    begin
        InitializeEmptyObject();
        GetJSONObject(JsonObject);

        JsonObject.Add('PropertyId', IsNavCreatedPropertyIdTxt);
        JsonObject.Add('Value', Format(IsNavCreated, 0, 2));

        exit(WriteObjectToString());
    end;

    procedure GetNavIntegrationId(NavIntegrationIdString: Text) NavIntegrationId: Guid
    var
        JsonObject: JsonObject;
        PropertyId: Text;
    begin
        InitializeObject(NavIntegrationIdString);
        GetJSONObject(JsonObject);
        if GetStringPropertyValueFromJObjectByName(JsonObject, 'PropertyId', PropertyId) then
            if PropertyId = NavIntegrationIdTxt then
                GetGuidPropertyValueFromJObjectByName(JsonObject, 'Value', NavIntegrationId);

        exit(NavIntegrationId);
    end;

    procedure AddNavIntegrationId(IntegrationId: Guid): Text
    var
        JsonObject: JsonObject;
    begin
        InitializeEmptyObject();
        GetJSONObject(JsonObject);
        JsonObject.Add('PropertyId', NavIntegrationIdTxt);
        JsonObject.Add('Value', Format(IntegrationId, 0, 9));

        exit(WriteObjectToString());
    end;

    procedure HasIsContact(IsContactString: Text): Boolean
    begin
        exit(HasExtendedProperty(IsContactString, IsContactPropertyIdTxt));
    end;

    procedure GetIsContact(IsContactString: Text) IsContact: Boolean
    var
        JsonObject: JsonObject;
        PropertyId: Text;
    begin
        InitializeObject(IsContactString);
        GetJSONObject(JsonObject);

        if GetStringPropertyValueFromJObjectByName(JsonObject, 'PropertyId', PropertyId) then
            if PropertyId = IsContactPropertyIdTxt then begin
                GetBoolPropertyValueFromJObjectByName(JsonObject, 'Value', IsContact);
                exit(IsContact);
            end;

        exit(false);
    end;

    [TryFunction]
    procedure TryGetIsContactValue(IsContactString: Text; var Value: Text)
    begin
        GetExtendedPropertyBoolValue(IsContactString, IsContactPropertyIdTxt, Value);
    end;

    procedure AddIsContact(IsContact: Boolean): Text
    var
        JsonObject: JsonObject;
    begin
        InitializeEmptyObject();
        GetJSONObject(JsonObject);

        JsonObject.Add('PropertyId', IsContactPropertyIdTxt);
        JsonObject.Add('Value', Format(IsContact, 0, 2));

        exit(WriteObjectToString());
    end;

    procedure HasIsLead(IsLeadString: Text): Boolean
    begin
        exit(HasExtendedProperty(IsLeadString, IsLeadPropertyIdTxt));
    end;

    procedure GetIsLead(IsLeadString: Text) IsLead: Boolean
    var
        JsonObject: JsonObject;
        PropertyId: Text;
    begin
        InitializeObject(IsLeadString);
        GetJSONObject(JsonObject);

        if GetStringPropertyValueFromJObjectByName(JsonObject, 'PropertyId', PropertyId) then
            if PropertyId = IsLeadPropertyIdTxt then begin
                GetBoolPropertyValueFromJObjectByName(JsonObject, 'Value', IsLead);
                exit(IsLead);
            end;

        exit(false);
    end;

    [TryFunction]
    procedure TryGetIsLeadValue(IsLeadString: Text; var Value: Text)
    begin
        GetExtendedPropertyBoolValue(IsLeadString, IsLeadPropertyIdTxt, Value);
    end;

    procedure HasIsPartner(IsPartnerString: Text): Boolean
    begin
        exit(HasExtendedProperty(IsPartnerString, IsPartnerPropertyIdTxt));
    end;

    procedure GetIsPartner(IsPartnerString: Text) IsPartner: Boolean
    var
        JsonObject: JsonObject;
        PropertyId: Text;
    begin
        InitializeObject(IsPartnerString);
        GetJSONObject(JsonObject);

        if GetStringPropertyValueFromJObjectByName(JsonObject, 'PropertyId', PropertyId) then
            if PropertyId = IsPartnerPropertyIdTxt then begin
                GetBoolPropertyValueFromJObjectByName(JsonObject, 'Value', IsPartner);
                exit(IsPartner);
            end;

        exit(false);
    end;

    [TryFunction]
    procedure TryGetIsPartnerValue(IsPartnerString: Text; var Value: Text)
    begin
        GetExtendedPropertyBoolValue(IsPartnerString, IsPartnerPropertyIdTxt, Value);
    end;

    procedure ConcatenateStreet(Address: Text; Address2: Text): Text
    var
        TypeHelper: Codeunit "Type Helper";
    begin
        if Address2 = '' then
            exit(Address);
        exit(Address + TypeHelper.CRLFSeparator() + Address2);
    end;

    procedure SplitStreet(Street: Text; var Address: Text[100]; var Address2: Text[50])
    var
        TypeHelper: Codeunit "Type Helper";
        NewLinePos: Integer;
    begin
        NewLinePos := StrPos(Street, TypeHelper.CRLFSeparator());
        if NewLinePos = 0 then begin
            Address := CopyStr(Street, 1, MaxStrLen(Address));
            exit;
        end;

        if NewLinePos > MaxStrLen(Address) then
            Address := CopyStr(Street, 1, MaxStrLen(Address))
        else
            Address := CopyStr(Street, 1, NewLinePos - 1);
        Address2 := CopyStr(Street, NewLinePos + 2);
    end;

    procedure FindCountryRegionCode(CountryOrRegion: Text): Code[10]
    var
        CountryRegion: Record "Country/Region";
        Regex: DotNet Regex;
        Match: DotNet Match;
        Matches: DotNet MatchCollection;
        Abbreviation: Text;
    begin
        if CountryOrRegion = '' then
            exit('');

        if StrLen(CountryOrRegion) <= MaxStrLen(CountryRegion.Code) then
            if CountryRegion.Get(CountryOrRegion) then
                exit(CountryRegion.Code);

        CountryRegion.SetRange(Name, CountryOrRegion);
        if CountryRegion.Count = 1 then begin
            CountryRegion.FindFirst();
            exit(CountryRegion.Code);
        end;

        if StrPos(CountryOrRegion, ' ') > 0 then begin
            Matches := Regex.Matches(CountryOrRegion, '\b([A-Z])');
            if Matches.Count > 0 then begin
                foreach Match in Matches do
                    Abbreviation += Match.Value();
                if CountryRegion.Get(Abbreviation) then
                    exit(CountryRegion.Code);
            end;
        end;

        CountryRegion.Init();
        CountryRegion.Code := CopyStr(CountryOrRegion, 1, MaxStrLen(CountryRegion.Code));
        CountryRegion.Name := CopyStr(CountryOrRegion, 1, MaxStrLen(CountryRegion.Name));
        CountryRegion.Insert(true);
        exit(CountryRegion.Code);
    end;

    procedure GetContactComments(Contact: Record Contact): Text
    var
        RlshpMgtCommentLine: Record "Rlshp. Mgt. Comment Line";
        TypeHelper: Codeunit "Type Helper";
        CommentString: Text;
    begin
        RlshpMgtCommentLine.SetRange("Table Name", RlshpMgtCommentLine."Table Name"::Contact);
        RlshpMgtCommentLine.SetRange("No.", Contact."No.");
        if RlshpMgtCommentLine.FindSet() then
            repeat
                if (CommentString <> '') or (RlshpMgtCommentLine.Comment = '') then
                    CommentString += TypeHelper.CRLFSeparator();
                CommentString += RlshpMgtCommentLine.Comment;
            until RlshpMgtCommentLine.Next() = 0;
        exit(CommentString);
    end;

    procedure SetContactComments(Contact: Record Contact; PersonalNotes: Text)
    var
        RlshpMgtCommentLine: Record "Rlshp. Mgt. Comment Line";
    begin
        RlshpMgtCommentLine.SetRange("Table Name", RlshpMgtCommentLine."Table Name"::Contact);
        RlshpMgtCommentLine.SetRange("No.", Contact."No.");
        if not RlshpMgtCommentLine.IsEmpty() then
            RlshpMgtCommentLine.DeleteAll();
        if PersonalNotes <> '' then begin
            RlshpMgtCommentLine."Table Name" := RlshpMgtCommentLine."Table Name"::Contact;
            RlshpMgtCommentLine."No." := Contact."No.";
            RlshpMgtCommentLine.Date := Today;
            InsertNextContactCommentLine(RlshpMgtCommentLine, PersonalNotes);
        end;
    end;

    local procedure InsertNextContactCommentLine(var RlshpMgtCommentLine: Record "Rlshp. Mgt. Comment Line"; RemainingPersonalNotes: Text)
    var
        TypeHelper: Codeunit "Type Helper";
        CrLfPos: Integer;
    begin
        CrLfPos := StrPos(RemainingPersonalNotes, TypeHelper.CRLFSeparator());

        if (CrLfPos <> 0) and (CrLfPos <= MaxStrLen(RlshpMgtCommentLine.Comment) + 1) then begin
            RlshpMgtCommentLine.Comment := CopyStr(RemainingPersonalNotes, 1, CrLfPos - 1);
            RemainingPersonalNotes := CopyStr(RemainingPersonalNotes, CrLfPos + 2);
        end else begin
            RlshpMgtCommentLine.Comment := CopyStr(RemainingPersonalNotes, 1, MaxStrLen(RlshpMgtCommentLine.Comment));
            RemainingPersonalNotes := CopyStr(RemainingPersonalNotes, MaxStrLen(RlshpMgtCommentLine.Comment) + 1);
        end;

        RlshpMgtCommentLine."Line No." += 10000;
        RlshpMgtCommentLine.Insert();
        RlshpMgtCommentLine.Date := 0D;
        if RemainingPersonalNotes <> '' then
            InsertNextContactCommentLine(RlshpMgtCommentLine, RemainingPersonalNotes);
    end;

    procedure InitializeCollection(JSONString: Text)
    begin
        ResetSelectedCollectionIndex();
        Clear(JsonArrayState);
        if JSONString <> '' then
            JsonArrayState.ReadFrom(JSONString);
    end;

    procedure InitializeObject(JSONString: Text)
    begin
        ResetSelectedCollectionIndex();
        Clear(JsonObjectState);
        if JSONString <> '' then
            JsonObjectState.ReadFrom(JSONString);
    end;

    procedure IsBlankOrEmptyJsonObject(JSONString: Text): Boolean
    begin
        exit((JSONString = '') or (JSONString = '{}'));
    end;

    procedure WriteCollectionToString(): Text
    var
        JsonText: Text;
    begin
        JsonArrayState.WriteTo(JsonText);
        exit(JsonText);
    end;

    procedure WriteObjectToString(): Text
    var
        JsonText: Text;
    begin
        JsonObjectState.WriteTo(JsonText);
        exit(JsonText);
    end;

    local procedure InitializeEmptyObject()
    begin
        ResetSelectedCollectionIndex();
        Clear(JsonObjectState);
    end;

    local procedure GetCollectionCount(): Integer
    begin
        exit(JsonArrayState.Count());
    end;

    local procedure GetJSONObject(var JObject: JsonObject)
    begin
        JObject := JsonObjectState;
    end;

    local procedure GetJObjectFromCollectionByIndex(var JObject: JsonObject; Index: Integer): Boolean
    var
        JsonToken: JsonToken;
    begin
        ResetSelectedCollectionIndex();
        if not GetTokenFromCollectionByIndex(JsonToken, Index) then
            exit(false);
        if not JsonToken.IsObject() then
            exit(false);
        JObject := JsonToken.AsObject();
        SelectedCollectionIndex := Index;
        HasSelectedCollectionIndex := true;
        exit(true);
    end;

    local procedure GetTokenFromCollectionByIndex(var JsonToken: JsonToken; Index: Integer): Boolean
    begin
        if (Index < 0) or (Index >= JsonArrayState.Count()) then
            exit(false);
        exit(JsonArrayState.Get(Index, JsonToken));
    end;

    local procedure GetJObjectFromCollectionByPropertyValue(var JObject: JsonObject; PropertyName: Text; Value: Text): Boolean
    var
        CandidateToken: JsonToken;
        CandidateObject: JsonObject;
        CandidateValue: Text;
        Index: Integer;
    begin
        ResetSelectedCollectionIndex();
        Clear(JObject);
        for Index := 0 to JsonArrayState.Count() - 1 do begin
            JsonArrayState.Get(Index, CandidateToken);
            if CandidateToken.IsObject() then begin
                CandidateObject := CandidateToken.AsObject();
                if GetStringPropertyValueFromJObjectByName(CandidateObject, PropertyName, CandidateValue) then
                    if CandidateValue = Value then begin
                        JObject := CandidateObject;
                        SelectedCollectionIndex := Index;
                        HasSelectedCollectionIndex := true;
                        exit(true);
                    end;
            end;
        end;
    end;

    local procedure RemoveSelectedJObjectFromCollection()
    begin
        if not HasSelectedCollectionIndex then
            exit;
        if SelectedCollectionIndex < 0 then begin
            ResetSelectedCollectionIndex();
            exit;
        end;
        if SelectedCollectionIndex >= JsonArrayState.Count() then begin
            ResetSelectedCollectionIndex();
            exit;
        end;
        JsonArrayState.RemoveAt(SelectedCollectionIndex);
        ResetSelectedCollectionIndex();
    end;

    local procedure GetStringPropertyValueFromJObjectByName(JObject: JsonObject; PropertyName: Text; var Value: Text): Boolean
    var
        JsonToken: JsonToken;
    begin
        Clear(Value);
        if not JObject.Get(PropertyName, JsonToken) then
            exit(false);
        if JsonToken.IsValue() then begin
            if JsonToken.AsValue().IsNull() or JsonToken.AsValue().IsUndefined() then
                exit(true);
            Value := JsonToken.AsValue().AsText();
        end else
            JsonToken.WriteTo(Value);
        exit(true);
    end;

    local procedure GetStringValueFromJsonToken(JsonToken: JsonToken; var Value: Text)
    begin
        Clear(Value);
        if not JsonToken.IsValue() then
            exit;
        if JsonToken.AsValue().IsNull() or JsonToken.AsValue().IsUndefined() then
            exit;
        Value := JsonToken.AsValue().AsText();
    end;

    local procedure ResetSelectedCollectionIndex()
    begin
        SelectedCollectionIndex := -1;
        HasSelectedCollectionIndex := false;
    end;

    local procedure GetEnumPropertyValueFromJObjectByName(JObject: JsonObject; PropertyName: Text; var Value: Option)
    var
        TextValue: Text;
    begin
        GetStringPropertyValueFromJObjectByName(JObject, PropertyName, TextValue);
        Evaluate(Value, TextValue, 0);
    end;

    local procedure GetBoolPropertyValueFromJObjectByName(JObject: JsonObject; PropertyName: Text; var Value: Boolean): Boolean
    var
        TextValue: Text;
    begin
        if not GetStringPropertyValueFromJObjectByName(JObject, PropertyName, TextValue) then
            exit(false);
        Evaluate(Value, TextValue, 2);
        exit(true);
    end;

    local procedure GetGuidPropertyValueFromJObjectByName(JObject: JsonObject; PropertyName: Text; var Value: Guid): Boolean
    var
        TextValue: Text;
    begin
        if not GetStringPropertyValueFromJObjectByName(JObject, PropertyName, TextValue) then
            exit(false);
        exit(Evaluate(Value, TextValue));
    end;

    local procedure AddJObjectToCollection(JObject: JsonObject)
    begin
        JsonArrayState.Add(JObject.AsToken().Clone());
    end;

    local procedure AddValueToCollection(Value: Text)
    begin
        JsonArrayState.Add(Value);
    end;

    local procedure ReplaceOrAddJPropertyInJObject(var JObject: JsonObject; PropertyName: Text; Value: Text): Boolean
    var
        OldValue: Text;
    begin
        if JObject.Contains(PropertyName) then begin
            GetStringPropertyValueFromJObjectByName(JObject, PropertyName, OldValue);
            JObject.Replace(PropertyName, Value);
            exit(OldValue <> Value);
        end;
        JObject.Add(PropertyName, Value);
        exit(true);
    end;
}
