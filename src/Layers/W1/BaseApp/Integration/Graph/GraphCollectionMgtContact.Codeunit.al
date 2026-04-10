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
        JSONManagement: Codeunit "JSON Management";
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
        JObject: DotNet JObject;
    begin
        Clear(Name);
        Clear(Address);
        if Index >= JSONManagement.GetCollectionCount() then
            exit;

        JSONManagement.GetJObjectFromCollectionByIndex(JObject, Index);
        JSONManagement.GetStringPropertyValueFromJObjectByName(JObject, 'Name', Name);
        JSONManagement.GetStringPropertyValueFromJObjectByName(JObject, 'Address', Address);
    end;

    procedure AddEmailAddress(Name: Text; Address: Text)
    var
        JObject: DotNet JObject;
    begin
        if Address = '' then
            exit;

        JObject := JObject.JObject();
        JSONManagement.AddJPropertyToJObject(JObject, 'Name', Name);
        JSONManagement.AddJPropertyToJObject(JObject, 'Address', Address);
        JSONManagement.AddJObjectToCollection(JObject);
    end;

    procedure UpdateEmailAddress(EmailAddressesString: Text; Index: Integer; Address: Text): Text
    var
        JObject: DotNet JObject;
    begin
        JSONManagement.InitializeCollection(EmailAddressesString);
        if Index > JSONManagement.GetCollectionCount() then // cannot add where index would leave empty slots.
            exit(EmailAddressesString);

        if JSONManagement.GetJObjectFromCollectionByIndex(JObject, Index) then begin
            JSONManagement.ReplaceOrAddJPropertyInJObject(JObject, 'Name', '');
            JSONManagement.ReplaceOrAddJPropertyInJObject(JObject, 'Address', Address)
        end else
            AddEmailAddress('', Address);

        exit(JSONManagement.WriteCollectionToString());
    end;

    procedure GetWebsiteByIndex(Index: Integer; var Type: Option; var Address: Text; var DisplayName: Text; var Name: Text)
    var
        JObject: DotNet JObject;
    begin
        if Index >= JSONManagement.GetCollectionCount() then
            exit;

        JSONManagement.GetJObjectFromCollectionByIndex(JObject, Index);
        JSONManagement.GetEnumPropertyValueFromJObjectByName(JObject, 'Type', Type);
        JSONManagement.GetStringPropertyValueFromJObjectByName(JObject, 'Address', Address);
        JSONManagement.GetStringPropertyValueFromJObjectByName(JObject, 'DisplayName', DisplayName);
        JSONManagement.GetStringPropertyValueFromJObjectByName(JObject, 'Name', Name);
    end;

    local procedure GetWebsiteByType(Type: Option; var Address: Text; var DisplayName: Text; var Name: Text)
    var
        JObject: DotNet JObject;
    begin
        WebsiteType := Type;
        if not JSONManagement.GetJObjectFromCollectionByPropertyValue(JObject, 'Type', Format(WebsiteType, 0, 0)) then
            exit;
        JSONManagement.GetStringPropertyValueFromJObjectByName(JObject, 'Address', Address);
        JSONManagement.GetStringPropertyValueFromJObjectByName(JObject, 'DisplayName', DisplayName);
        JSONManagement.GetStringPropertyValueFromJObjectByName(JObject, 'Name', Name);
    end;

    procedure AddWebsite(Type: Option; Address: Text; DisplayName: Text; Name: Text)
    var
        JObject: DotNet JObject;
    begin
        if Address = '' then
            exit;
        JObject := JObject.JObject();
        WebsiteType := Type;
        JSONManagement.AddJPropertyToJObject(JObject, 'Type', Format(WebsiteType, 0, 0));
        JSONManagement.AddJPropertyToJObject(JObject, 'Address', Address);
        JSONManagement.AddJPropertyToJObject(JObject, 'DisplayName', DisplayName);
        JSONManagement.AddJPropertyToJObject(JObject, 'Name', Name);
        JSONManagement.AddJObjectToCollection(JObject);
    end;

    procedure UpdateWebsite(Type: Option; Address: Text)
    var
        JObject: DotNet JObject;
    begin
        WebsiteType := Type;
        if not JSONManagement.GetJObjectFromCollectionByPropertyValue(JObject, 'Type', Format(WebsiteType, 0, 0)) then begin
            if Address = '' then
                exit;
            JObject := JObject.JObject();
            JSONManagement.AddJObjectToCollection(JObject);
        end else
            JObject.Remove('Type');
        JSONManagement.ReplaceOrAddJPropertyInJObject(JObject, 'Address', Address);
    end;

    procedure GetImAddress(Index: Integer; var ImAddress: Text)
    var
        JObject: DotNet JObject;
    begin
        if Index >= JSONManagement.GetCollectionCount() then
            exit;

        JSONManagement.GetJObjectFromCollectionByIndex(JObject, Index);
        JSONManagement.GetStringValueFromJObject(JObject, ImAddress);
    end;

    procedure AddImAddress(ImAddress: Text)
    var
        JObject: DotNet JObject;
    begin
        if ImAddress = '' then
            exit;

        JObject := JObject.JObject();
        JSONManagement.AddJValueToJObject(JObject, ImAddress);
        JSONManagement.AddJObjectToCollection(JObject);
    end;

    procedure GetPhoneByIndex(Index: Integer; var Type: Option; var Number: Text)
    var
        JObject: DotNet JObject;
    begin
        if Index >= JSONManagement.GetCollectionCount() then
            exit;

        JSONManagement.GetJObjectFromCollectionByIndex(JObject, Index);
        JSONManagement.GetEnumPropertyValueFromJObjectByName(JObject, 'Type', Type);
        JSONManagement.GetStringPropertyValueFromJObjectByName(JObject, 'Number', Number);
    end;

    procedure GetPhoneByType(Type: Option; var Number: Text)
    var
        JObject: DotNet JObject;
    begin
        PhoneType := Type;
        if not JSONManagement.GetJObjectFromCollectionByPropertyValue(JObject, 'Type', Format(PhoneType, 0, 0)) then
            exit;

        JSONManagement.GetStringPropertyValueFromJObjectByName(JObject, 'Number', Number);
    end;

    procedure AddPhone(Type: Option; Number: Text)
    var
        JObject: DotNet JObject;
    begin
        PhoneType := Type;
        if Number = '' then
            exit;

        JObject := JObject.JObject();
        JSONManagement.AddJPropertyToJObject(JObject, 'Type', Format(PhoneType, 0, 0));
        JSONManagement.AddJPropertyToJObject(JObject, 'Number', Number);
        JSONManagement.AddJObjectToCollection(JObject);
    end;

    procedure GetPostalAddressByIndex(Index: Integer; var Type: Option; var PostOfficeBox: Text; var Street: Text; var City: Text; var State: Text; var CountryOrRegion: Text; var PostalCode: Text)
    var
        JObject: DotNet JObject;
    begin
        if Index >= JSONManagement.GetCollectionCount() then
            exit;

        JSONManagement.GetJObjectFromCollectionByIndex(JObject, Index);
        JSONManagement.GetEnumPropertyValueFromJObjectByName(JObject, 'Type', Type);
        JSONManagement.GetStringPropertyValueFromJObjectByName(JObject, 'PostOfficeBox', PostOfficeBox);
        JSONManagement.GetStringPropertyValueFromJObjectByName(JObject, 'Street', Street);
        JSONManagement.GetStringPropertyValueFromJObjectByName(JObject, 'City', City);
        JSONManagement.GetStringPropertyValueFromJObjectByName(JObject, 'State', State);
        JSONManagement.GetStringPropertyValueFromJObjectByName(JObject, 'CountryOrRegion', CountryOrRegion);
        JSONManagement.GetStringPropertyValueFromJObjectByName(JObject, 'PostalCode', PostalCode);
    end;

    local procedure GetPostalAddressByType(Type: Option; var Address: Text[100]; var Address2: Text[50]; var City: Text[30]; var County: Text[30]; var CountryRegionCode: Code[10]; var PostCode: Code[20])
    var
        JObject: DotNet JObject;
        value: Text;
    begin
        AddressType := Type;
        if not JSONManagement.GetJObjectFromCollectionByPropertyValue(JObject, 'Type', Format(AddressType, 0, 0)) then
            exit;

        JSONManagement.GetStringPropertyValueFromJObjectByName(JObject, 'Street', value);
        SplitStreet(value, Address, Address2);
        JSONManagement.GetStringPropertyValueFromJObjectByName(JObject, 'City', value);
        City := CopyStr(value, 1, MaxStrLen(value));
        JSONManagement.GetStringPropertyValueFromJObjectByName(JObject, 'State', value);
        County := CopyStr(value, 1, MaxStrLen(value));
        JSONManagement.GetStringPropertyValueFromJObjectByName(JObject, 'CountryOrRegion', value);
        CountryRegionCode := FindCountryRegionCode(value);
        JSONManagement.GetStringPropertyValueFromJObjectByName(JObject, 'PostalCode', value);
        PostCode := CopyStr(value, 1, MaxStrLen(PostCode));
    end;

    procedure AddPostalAddress(Type: Option; PostOfficeBox: Text; Street: Text; City: Text; State: Text; CountryOrRegion: Text; PostalCode: Text)
    var
        JObject: DotNet JObject;
    begin
        JObject := JObject.JObject();
        AddressType := Type;
        JSONManagement.AddJPropertyToJObject(JObject, 'Type', Format(AddressType, 0, 0));
        JSONManagement.AddJPropertyToJObject(JObject, 'PostOfficeBox', PostOfficeBox);
        JSONManagement.AddJPropertyToJObject(JObject, 'Street', Street);
        JSONManagement.AddJPropertyToJObject(JObject, 'City', City);
        JSONManagement.AddJPropertyToJObject(JObject, 'State', State);
        JSONManagement.AddJPropertyToJObject(JObject, 'CountryOrRegion', CountryOrRegion);
        JSONManagement.AddJPropertyToJObject(JObject, 'PostalCode', PostalCode);
        JSONManagement.AddJObjectToCollection(JObject);
    end;

    procedure GetChildren(Index: Integer; var Child: Text)
    var
        JObject: DotNet JObject;
    begin
        if Index >= JSONManagement.GetCollectionCount() then
            exit;

        JSONManagement.GetJObjectFromCollectionByIndex(JObject, Index);
        JSONManagement.GetStringValueFromJObject(JObject, Child);
    end;

    procedure AddChildren(Child: Text)
    var
        JObject: DotNet JObject;
    begin
        if Child = '' then
            exit;

        JObject := JObject.JObject();
        JSONManagement.AddJValueToJObject(JObject, Child);
        JSONManagement.AddJObjectToCollection(JObject);
    end;

    procedure GetFlag(var CompletedDateTime: Text; var CompletedTimeZone: Text; var DueDateTime: Text; var DueTimeZone: Text; var StartDateTime: Text; var StartTimeZone: Text; var FlagStatus: Option)
    var
        JsonObject: DotNet JObject;
        JObjectVariant: Variant;
    begin
        JSONManagement.GetJSONObject(JsonObject);
        if JSONManagement.GetPropertyValueFromJObjectByName(JsonObject, 'CompletedDateTime', JObjectVariant) then begin
            JSONManagement.GetStringPropertyValueFromJObjectByName(JObjectVariant, 'CompletedDateTime', CompletedDateTime);
            JSONManagement.GetStringPropertyValueFromJObjectByName(JObjectVariant, 'CompletedTimeZone', CompletedTimeZone);
        end;
        if JSONManagement.GetPropertyValueFromJObjectByName(JsonObject, 'DueDateTime', JObjectVariant) then begin
            ;
            JSONManagement.GetStringPropertyValueFromJObjectByName(JObjectVariant, 'DateTime', DueDateTime);
            JSONManagement.GetStringPropertyValueFromJObjectByName(JObjectVariant, 'TimeZone', DueTimeZone);
        end;
        if JSONManagement.GetPropertyValueFromJObjectByName(JsonObject, 'StartDateTime', JObjectVariant) then begin
            ;
            JSONManagement.GetStringPropertyValueFromJObjectByName(JObjectVariant, 'DateTime', StartDateTime);
            JSONManagement.GetStringPropertyValueFromJObjectByName(JObjectVariant, 'TimeZone', StartTimeZone);
        end;

        JSONManagement.GetEnumPropertyValueFromJObjectByName(JsonObject, 'FlagStatus', FlagStatusOption);
        FlagStatus := FlagStatusOption;
    end;

    procedure AddFlag(CompletedDateTime: Text; CompletedTimeZone: Text; DueDateTime: Text; DueTimeZone: Text; StartDateTime: Text; StartTimeZone: Text; FlagStatus: Option)
    var
        JObject: DotNet JObject;
        JsonObject: DotNet JObject;
    begin
        JSONManagement.GetJSONObject(JsonObject);

        JObject := JObject.JObject();
        JSONManagement.AddJPropertyToJObject(JObject, 'DateTime', CompletedDateTime);
        JSONManagement.AddJPropertyToJObject(JObject, 'TimeZone', CompletedTimeZone);
        JSONManagement.AddJObjectToJObject(JsonObject, 'CompletedDateTime', JObject);
        JObject := JObject.JObject();

        JSONManagement.AddJPropertyToJObject(JObject, 'DateTime', DueDateTime);
        JSONManagement.AddJPropertyToJObject(JObject, 'TimeZone', DueTimeZone);
        JSONManagement.AddJObjectToJObject(JsonObject, 'DueDateTime', JObject);
        JObject := JObject.JObject();
        JSONManagement.AddJPropertyToJObject(JObject, 'DateTime', StartDateTime);
        JSONManagement.AddJPropertyToJObject(JObject, 'TimeZone', StartTimeZone);
        JSONManagement.AddJObjectToJObject(JsonObject, 'StartDateTime', JObject);
        FlagStatusOption := FlagStatus;
        JSONManagement.AddJPropertyToJObject(JsonObject, 'FlagStatus', Format(FlagStatusOption, 0, 0));
    end;

    procedure GetCategory(Index: Integer; var Category: Text)
    var
        JObject: DotNet JObject;
    begin
        if Index >= JSONManagement.GetCollectionCount() then
            exit;

        JSONManagement.GetJObjectFromCollectionByIndex(JObject, Index);
        JSONManagement.GetStringValueFromJObject(JObject, Category);
    end;

    procedure AddCategory(Category: Text)
    var
        JObject: DotNet JObject;
    begin
        JObject := JObject.JObject();
        JSONManagement.AddJValueToJObject(JObject, Category);
        JSONManagement.AddJObjectToCollection(JObject);
    end;

    local procedure HasPostalAddress(Type: Option): Boolean
    var
        JObject: DotNet JObject;
    begin
        AddressType := Type;
        exit(JSONManagement.GetJObjectFromCollectionByPropertyValue(JObject, 'Type', Format(AddressType, 0, 0)))
    end;

    procedure HasHomeAddressOrPhone(PostalAddressesString: Text; PhonesString: Text; WebsitesString: Text): Boolean
    var
        HasAddress: Boolean;
        HasPhones: Boolean;
    begin
        JSONManagement.InitializeCollection(PostalAddressesString);
        HasAddress := HasPostalAddress(AddressType::Home);
        JSONManagement.InitializeCollection(PhonesString);
        HasPhones := HasPhone(PhoneType::Home) or HasPhone(PhoneType::HomeFax);
        JSONManagement.InitializeCollection(WebsitesString);
        exit(HasAddress or HasPhones or HasWebsite(WebsiteType::Home));
    end;

    procedure HasBusinessAddressOrPhone(PostalAddressesString: Text; PhonesString: Text; WebsitesString: Text): Boolean
    var
        HasAddress: Boolean;
        HasPhones: Boolean;
    begin
        JSONManagement.InitializeCollection(PostalAddressesString);
        HasAddress := HasPostalAddress(AddressType::Business);
        JSONManagement.InitializeCollection(PhonesString);
        HasPhones := HasPhone(PhoneType::Business) or HasPhone(PhoneType::BusinessFax);
        JSONManagement.InitializeCollection(WebsitesString);
        exit(HasAddress or HasPhones or HasWebsite(WebsiteType::Work));
    end;

    procedure HasBusinessAddress(PostalAddressesString: Text): Boolean
    begin
        JSONManagement.InitializeCollection(PostalAddressesString);
        exit(HasPostalAddress(AddressType::Business));
    end;

    procedure HasOtherAddressOrPhone(PostalAddressesString: Text; PhonesString: Text; WebsitesString: Text): Boolean
    var
        HasAddress: Boolean;
        HasPhones: Boolean;
    begin
        JSONManagement.InitializeCollection(PostalAddressesString);
        HasAddress := HasPostalAddress(AddressType::Other);
        JSONManagement.InitializeCollection(PhonesString);
        HasPhones := HasPhone(PhoneType::Other) or HasPhone(PhoneType::OtherFax);
        JSONManagement.InitializeCollection(WebsitesString);
        exit(HasAddress or HasPhones or HasWebsite(WebsiteType::Other));
    end;

    local procedure UpdatePostalAddress(Type: Option; Address: Text[100]; Address2: Text[50]; City: Text[30]; County: Text[30]; CountryRegionCode: Code[10]; PostCode: Code[20])
    var
        JObject: DotNet JObject;
    begin
        AddressType := Type;
        if (Address = '') and (Address2 = '') and (City = '') and (County = '') and (PostCode = '') then begin
            if JSONManagement.GetJObjectFromCollectionByPropertyValue(JObject, 'Type', Format(AddressType, 0, 0)) then
                JObject.Remove();
            exit;
        end;

        if not JSONManagement.GetJObjectFromCollectionByPropertyValue(JObject, 'Type', Format(AddressType, 0, 0)) then begin
            JObject := JObject.JObject();
            JSONManagement.AddJPropertyToJObject(JObject, 'Type', Format(AddressType, 0, 0));
            JSONManagement.AddJObjectToCollection(JObject);
            JSONManagement.GetJObjectFromCollectionByPropertyValue(JObject, 'Type', Format(AddressType, 0, 0));
        end;
        JSONManagement.ReplaceOrAddJPropertyInJObject(JObject, 'Street', ConcatenateStreet(Address, Address2));
        JSONManagement.ReplaceOrAddJPropertyInJObject(JObject, 'City', City);
        JSONManagement.ReplaceOrAddJPropertyInJObject(JObject, 'State', County);
        JSONManagement.ReplaceOrAddJPropertyInJObject(JObject, 'CountryOrRegion', CountryRegionCode);
        JSONManagement.ReplaceOrAddJPropertyInJObject(JObject, 'PostalCode', PostCode);
    end;

    procedure UpdateHomeAddress(PostalAddressesString: Text; Address: Text[100]; Address2: Text[50]; City: Text[30]; County: Text[30]; CountryRegionCode: Code[10]; PostCode: Code[20]): Text
    begin
        JSONManagement.InitializeCollection(PostalAddressesString);
        UpdatePostalAddress(AddressType::Home, Address, Address2, City, County, CountryRegionCode, PostCode);
        exit(JSONManagement.WriteCollectionToString());
    end;

    procedure UpdateBusinessAddress(PostalAddressesString: Text; Address: Text[100]; Address2: Text[50]; City: Text[30]; County: Text[30]; CountryRegionCode: Code[10]; PostCode: Code[20]): Text
    begin
        JSONManagement.InitializeCollection(PostalAddressesString);
        UpdatePostalAddress(AddressType::Business, Address, Address2, City, County, CountryRegionCode, PostCode);
        exit(JSONManagement.WriteCollectionToString());
    end;

    procedure UpdateOtherAddress(PostalAddressesString: Text; Address: Text[100]; Address2: Text[50]; City: Text[30]; County: Text[30]; CountryRegionCode: Code[10]; PostCode: Code[20]): Text
    begin
        JSONManagement.InitializeCollection(PostalAddressesString);
        UpdatePostalAddress(AddressType::Other, Address, Address2, City, County, CountryRegionCode, PostCode);
        exit(JSONManagement.WriteCollectionToString());
    end;

    procedure GetHomeAddress(PostalAddressesString: Text; var Address: Text[100]; var Address2: Text[50]; var City: Text[30]; var County: Text[30]; var CountryRegionCode: Code[10]; var PostCode: Code[20])
    begin
        JSONManagement.InitializeCollection(PostalAddressesString);
        GetPostalAddressByType(AddressType::Home, Address, Address2, City, County, CountryRegionCode, PostCode);
    end;

    procedure GetBusinessAddress(PostalAddressesString: Text; var Address: Text[100]; var Address2: Text[50]; var City: Text[30]; var County: Text[30]; var CountryRegionCode: Code[10]; var PostCode: Code[20])
    begin
        JSONManagement.InitializeCollection(PostalAddressesString);
        GetPostalAddressByType(AddressType::Business, Address, Address2, City, County, CountryRegionCode, PostCode);
    end;

    procedure GetOtherAddress(PostalAddressesString: Text; var Address: Text[100]; var Address2: Text[50]; var City: Text[30]; var County: Text[30]; var CountryRegionCode: Code[10]; var PostCode: Code[20])
    begin
        JSONManagement.InitializeCollection(PostalAddressesString);
        GetPostalAddressByType(AddressType::Other, Address, Address2, City, County, CountryRegionCode, PostCode);
    end;

    local procedure HasPhone(Type: Option): Boolean
    var
        JObject: DotNet JObject;
    begin
        PhoneType := Type;
        exit(JSONManagement.GetJObjectFromCollectionByPropertyValue(JObject, 'Type', Format(PhoneType, 0, 0)));
    end;

    local procedure UpdatePhone(Type: Option; Number: Text)
    var
        JObject: DotNet JObject;
    begin
        PhoneType := Type;
        if not JSONManagement.GetJObjectFromCollectionByPropertyValue(JObject, 'Type', Format(PhoneType, 0, 0)) then begin
            if Number = '' then
                exit;
            JObject := JObject.JObject();
            JSONManagement.AddJPropertyToJObject(JObject, 'Type', Format(PhoneType, 0, 0));
            JSONManagement.AddJObjectToCollection(JObject);
            JSONManagement.GetJObjectFromCollectionByPropertyValue(JObject, 'Type', Format(PhoneType, 0, 0))
        end;
        JSONManagement.ReplaceOrAddJPropertyInJObject(JObject, 'Number', Number);
    end;

    procedure UpdateHomePhone(PhonesString: Text; Number: Text): Text
    begin
        JSONManagement.InitializeCollection(PhonesString);
        UpdatePhone(PhoneType::Home, Number);
        exit(JSONManagement.WriteCollectionToString());
    end;

    procedure UpdateBusinessPhone(PhonesString: Text; Number: Text): Text
    begin
        JSONManagement.InitializeCollection(PhonesString);
        UpdatePhone(PhoneType::Business, Number);
        exit(JSONManagement.WriteCollectionToString());
    end;

    procedure UpdateMobilePhone(PhonesString: Text; Number: Text): Text
    begin
        JSONManagement.InitializeCollection(PhonesString);
        UpdatePhone(PhoneType::Mobile, Number);
        exit(JSONManagement.WriteCollectionToString());
    end;

    procedure UpdateOtherPhone(PhonesString: Text; Number: Text): Text
    begin
        JSONManagement.InitializeCollection(PhonesString);
        UpdatePhone(PhoneType::Other, Number);
        exit(JSONManagement.WriteCollectionToString());
    end;

    procedure UpdateAssistantPhone(PhonesString: Text; Number: Text): Text
    begin
        JSONManagement.InitializeCollection(PhonesString);
        UpdatePhone(PhoneType::Assistant, Number);
        exit(JSONManagement.WriteCollectionToString());
    end;

    procedure UpdateHomeFaxPhone(PhonesString: Text; Number: Text): Text
    begin
        JSONManagement.InitializeCollection(PhonesString);
        UpdatePhone(PhoneType::HomeFax, Number);
        exit(JSONManagement.WriteCollectionToString());
    end;

    procedure UpdateBusinessFaxPhone(PhonesString: Text; Number: Text): Text
    begin
        JSONManagement.InitializeCollection(PhonesString);
        UpdatePhone(PhoneType::BusinessFax, Number);
        exit(JSONManagement.WriteCollectionToString());
    end;

    procedure UpdateOtherFaxPhone(PhonesString: Text; Number: Text): Text
    begin
        JSONManagement.InitializeCollection(PhonesString);
        UpdatePhone(PhoneType::OtherFax, Number);
        exit(JSONManagement.WriteCollectionToString());
    end;

    procedure UpdatePagerPhone(PhonesString: Text; Number: Text): Text
    begin
        JSONManagement.InitializeCollection(PhonesString);
        UpdatePhone(PhoneType::Pager, Number);
        exit(JSONManagement.WriteCollectionToString());
    end;

    procedure UpdateRadioPhone(PhonesString: Text; Number: Text): Text
    begin
        JSONManagement.InitializeCollection(PhonesString);
        UpdatePhone(PhoneType::Radio, Number);
        exit(JSONManagement.WriteCollectionToString());
    end;

    procedure GetHomePhone(PhonesString: Text; var Number: Text)
    begin
        JSONManagement.InitializeCollection(PhonesString);
        GetPhoneByType(PhoneType::Home, Number);
    end;

    procedure GetBusinessPhone(PhonesString: Text; var Number: Text)
    begin
        JSONManagement.InitializeCollection(PhonesString);
        GetPhoneByType(PhoneType::Business, Number);
    end;

    procedure GetMobilePhone(PhonesString: Text; var Number: Text)
    begin
        JSONManagement.InitializeCollection(PhonesString);
        GetPhoneByType(PhoneType::Mobile, Number);
    end;

    procedure GetOtherPhone(PhonesString: Text; var Number: Text)
    begin
        JSONManagement.InitializeCollection(PhonesString);
        GetPhoneByType(PhoneType::Other, Number);
    end;

    procedure GetAssistantPhone(PhonesString: Text; var Number: Text)
    begin
        JSONManagement.InitializeCollection(PhonesString);
        GetPhoneByType(PhoneType::Assistant, Number);
    end;

    procedure GetHomeFaxPhone(PhonesString: Text; var Number: Text)
    begin
        JSONManagement.InitializeCollection(PhonesString);
        GetPhoneByType(PhoneType::HomeFax, Number);
    end;

    procedure GetBusinessFaxPhone(PhonesString: Text; var Number: Text)
    begin
        JSONManagement.InitializeCollection(PhonesString);
        GetPhoneByType(PhoneType::BusinessFax, Number);
    end;

    procedure GetOtherFaxPhone(PhonesString: Text; var Number: Text)
    begin
        JSONManagement.InitializeCollection(PhonesString);
        GetPhoneByType(PhoneType::OtherFax, Number);
    end;

    procedure GetPagerPhone(PhonesString: Text; var Number: Text)
    begin
        JSONManagement.InitializeCollection(PhonesString);
        GetPhoneByType(PhoneType::Pager, Number);
    end;

    procedure GetRadioPhone(PhonesString: Text; var Number: Text)
    begin
        JSONManagement.InitializeCollection(PhonesString);
        GetPhoneByType(PhoneType::Radio, Number);
    end;

    local procedure HasWebsite(Type: Option): Boolean
    var
        JObject: DotNet JObject;
    begin
        WebsiteType := Type;
        exit(JSONManagement.GetJObjectFromCollectionByPropertyValue(JObject, 'Type', Format(WebsiteType, 0, 0)));
    end;

    procedure GetWorkWebsite(WebsitesString: Text; var Address: Text[80])
    var
        Name: Text;
        DisplayName: Text;
    begin
        JSONManagement.InitializeCollection(WebsitesString);
        GetWebsiteByType(WebsiteType::Work, Address, Name, DisplayName);
    end;

    procedure GetHomeWebsite(WebsitesString: Text; var Address: Text[80])
    var
        Name: Text;
        DisplayName: Text;
    begin
        JSONManagement.InitializeCollection(WebsitesString);
        GetWebsiteByType(WebsiteType::Home, Address, Name, DisplayName);
    end;

    procedure UpdateWorkWebsite(WebsitesString: Text; Address: Text[80]): Text
    begin
        JSONManagement.InitializeCollection(WebsitesString);
        UpdateWebsite(WebsiteType::Work, Address);
        exit(JSONManagement.WriteCollectionToString());
    end;

    procedure UpdateHomeWebsite(WebsitesString: Text; Address: Text[80]): Text
    begin
        JSONManagement.InitializeCollection(WebsitesString);
        UpdateWebsite(WebsiteType::Home, Address);
        exit(JSONManagement.WriteCollectionToString());
    end;

    procedure HasBusinessType(BusinessTypeString: Text): Boolean
    begin
        exit(HasExtendedProperty(BusinessTypeString, BusinessTypePropertyIdTxt));
    end;

    [TryFunction]
    procedure TryGetBusinessTypeValue(BusinessTypeString: Text; var Value: Text)
    var
        JsonObject: DotNet JObject;
        PropertyId: Text;
    begin
        JSONManagement.InitializeObject(BusinessTypeString);
        JSONManagement.GetJSONObject(JsonObject);
        JSONManagement.GetStringPropertyValueFromJObjectByName(JsonObject, 'PropertyId', PropertyId);
        if not (PropertyId = BusinessTypePropertyIdTxt) then
            Error(PropertyIdErr, BusinessTypePropertyIdTxt, PropertyId);
        JSONManagement.GetStringPropertyValueFromJObjectByName(JsonObject, 'Value', Value);
        Evaluate(BusinessType, Value, 0);
    end;

    procedure GetBusinessType(BusinessTypeString: Text; var Type: Option)
    var
        JsonObject: DotNet JObject;
        PropertyId: Text;
    begin
        JSONManagement.InitializeObject(BusinessTypeString);
        JSONManagement.GetJSONObject(JsonObject);
        if JSONManagement.GetStringPropertyValueFromJObjectByName(JsonObject, 'PropertyId', PropertyId) then
            if PropertyId = BusinessTypePropertyIdTxt then begin
                JSONManagement.GetEnumPropertyValueFromJObjectByName(JsonObject, 'Value', BusinessType);
                Type := BusinessType;
                exit;
            end;

        Type := BusinessType::Individual;
    end;

    procedure AddBusinessType(Type: Option): Text
    var
        JsonObject: DotNet JObject;
    begin
        JSONManagement.InitializeEmptyObject();
        JSONManagement.GetJSONObject(JsonObject);
        BusinessType := Type;
        JSONManagement.AddJPropertyToJObject(JsonObject, 'PropertyId', BusinessTypePropertyIdTxt);
        JSONManagement.AddJPropertyToJObject(JsonObject, 'Value', Format(BusinessType, 0, 0));
        exit(JSONManagement.WriteObjectToString());
    end;

    local procedure HasExtendedProperty(ExtendedPropertyString: Text; ExpectedPropertyId: Text): Boolean
    var
        JsonObject: DotNet JObject;
        PropertyId: Text;
    begin
        JSONManagement.InitializeObject(ExtendedPropertyString);
        JSONManagement.GetJSONObject(JsonObject);
        if JSONManagement.GetStringPropertyValueFromJObjectByName(JsonObject, 'PropertyId', PropertyId) then
            exit(ExpectedPropertyId = PropertyId);
    end;

    local procedure GetExtendedPropertyBoolValue(ExtendedPropertyString: Text; ExpectedPropertyId: Text; var Value: Text)
    var
        JsonObject: DotNet JObject;
        PropertyId: Text;
        BooleanValue: Boolean;
    begin
        JSONManagement.InitializeObject(ExtendedPropertyString);
        JSONManagement.GetJSONObject(JsonObject);
        JSONManagement.GetStringPropertyValueFromJObjectByName(JsonObject, 'PropertyId', PropertyId);
        if not (PropertyId = ExpectedPropertyId) then
            Error(PropertyIdErr, ExpectedPropertyId, PropertyId);
        JSONManagement.GetStringPropertyValueFromJObjectByName(JsonObject, 'Value', Value);
        Evaluate(BooleanValue, Value, 2);
    end;

    procedure HasIsCustomer(IsCustomerString: Text): Boolean
    begin
        exit(HasExtendedProperty(IsCustomerString, IsCustomerPropertyIdTxt));
    end;

    procedure GetIsCustomer(IsCustomerString: Text) IsCustomer: Boolean
    var
        JsonObject: DotNet JObject;
        PropertyId: Text;
    begin
        JSONManagement.InitializeObject(IsCustomerString);
        JSONManagement.GetJSONObject(JsonObject);

        if JSONManagement.GetStringPropertyValueFromJObjectByName(JsonObject, 'PropertyId', PropertyId) then
            if PropertyId = IsCustomerPropertyIdTxt then begin
                JSONManagement.GetBoolPropertyValueFromJObjectByName(JsonObject, 'Value', IsCustomer);
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
        JsonObject: DotNet JObject;
    begin
        JSONManagement.InitializeEmptyObject();
        JSONManagement.GetJSONObject(JsonObject);

        JSONManagement.AddJPropertyToJObject(JsonObject, 'PropertyId', IsCustomerPropertyIdTxt);
        JSONManagement.AddJPropertyToJObject(JsonObject, 'Value', Format(IsCustomer, 0, 2));

        exit(JSONManagement.WriteObjectToString());
    end;

    procedure HasIsVendor(IsVendorString: Text): Boolean
    begin
        exit(HasExtendedProperty(IsVendorString, IsVendorPropertyIdTxt));
    end;

    procedure GetIsVendor(IsVendorString: Text) IsVendor: Boolean
    var
        JsonObject: DotNet JObject;
        PropertyId: Text;
    begin
        JSONManagement.InitializeObject(IsVendorString);
        JSONManagement.GetJSONObject(JsonObject);

        if JSONManagement.GetStringPropertyValueFromJObjectByName(JsonObject, 'PropertyId', PropertyId) then
            if PropertyId = IsVendorPropertyIdTxt then begin
                JSONManagement.GetBoolPropertyValueFromJObjectByName(JsonObject, 'Value', IsVendor);
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
        JsonObject: DotNet JObject;
    begin
        JSONManagement.InitializeEmptyObject();
        JSONManagement.GetJSONObject(JsonObject);

        JSONManagement.AddJPropertyToJObject(JsonObject, 'PropertyId', IsVendorPropertyIdTxt);
        JSONManagement.AddJPropertyToJObject(JsonObject, 'Value', Format(IsVendor, 0, 2));

        exit(JSONManagement.WriteObjectToString());
    end;

    procedure HasIsBank(IsBankString: Text): Boolean
    begin
        exit(HasExtendedProperty(IsBankString, IsBankPropertyIdTxt));
    end;

    procedure GetIsBank(IsBankString: Text) IsBank: Boolean
    var
        JsonObject: DotNet JObject;
        PropertyId: Text;
    begin
        JSONManagement.InitializeObject(IsBankString);
        JSONManagement.GetJSONObject(JsonObject);

        if JSONManagement.GetStringPropertyValueFromJObjectByName(JsonObject, 'PropertyId', PropertyId) then
            if PropertyId = IsBankPropertyIdTxt then begin
                JSONManagement.GetBoolPropertyValueFromJObjectByName(JsonObject, 'Value', IsBank);
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
        JsonObject: DotNet JObject;
    begin
        JSONManagement.InitializeEmptyObject();
        JSONManagement.GetJSONObject(JsonObject);

        JSONManagement.AddJPropertyToJObject(JsonObject, 'PropertyId', IsBankPropertyIdTxt);
        JSONManagement.AddJPropertyToJObject(JsonObject, 'Value', Format(IsBank, 0, 2));

        exit(JSONManagement.WriteObjectToString());
    end;

    procedure GetIsNavCreated(IsNavCreatedString: Text) IsNavCreated: Boolean
    var
        JsonObject: DotNet JObject;
        PropertyId: Text;
    begin
        JSONManagement.InitializeObject(IsNavCreatedString);
        JSONManagement.GetJSONObject(JsonObject);

        if JSONManagement.GetStringPropertyValueFromJObjectByName(JsonObject, 'PropertyId', PropertyId) then
            if PropertyId = IsNavCreatedPropertyIdTxt then begin
                JSONManagement.GetBoolPropertyValueFromJObjectByName(JsonObject, 'Value', IsNavCreated);
                exit(IsNavCreated);
            end;
        exit(false);
    end;

    procedure AddIsNavCreated(IsNavCreated: Boolean): Text
    var
        JsonObject: DotNet JObject;
    begin
        JSONManagement.InitializeEmptyObject();
        JSONManagement.GetJSONObject(JsonObject);

        JSONManagement.AddJPropertyToJObject(JsonObject, 'PropertyId', IsNavCreatedPropertyIdTxt);
        JSONManagement.AddJPropertyToJObject(JsonObject, 'Value', Format(IsNavCreated, 0, 2));

        exit(JSONManagement.WriteObjectToString());
    end;

    procedure GetNavIntegrationId(NavIntegrationIdString: Text) NavIntegrationId: Guid
    var
        JsonObject: DotNet JObject;
        PropertyId: Text;
    begin
        JSONManagement.InitializeObject(NavIntegrationIdString);
        JSONManagement.GetJSONObject(JsonObject);
        if JSONManagement.GetStringPropertyValueFromJObjectByName(JsonObject, 'PropertyId', PropertyId) then
            if PropertyId = NavIntegrationIdTxt then
                JSONManagement.GetGuidPropertyValueFromJObjectByName(JsonObject, 'Value', NavIntegrationId);

        exit(NavIntegrationId);
    end;

    procedure AddNavIntegrationId(IntegrationId: Guid): Text
    var
        JsonObject: DotNet JObject;
    begin
        JSONManagement.InitializeEmptyObject();
        JSONManagement.GetJSONObject(JsonObject);
        JSONManagement.AddJPropertyToJObject(JsonObject, 'PropertyId', NavIntegrationIdTxt);
        JSONManagement.AddJPropertyToJObject(JsonObject, 'Value', IntegrationId);

        exit(JSONManagement.WriteObjectToString());
    end;

    procedure HasIsContact(IsContactString: Text): Boolean
    begin
        exit(HasExtendedProperty(IsContactString, IsContactPropertyIdTxt));
    end;

    procedure GetIsContact(IsContactString: Text) IsContact: Boolean
    var
        JsonObject: DotNet JObject;
        PropertyId: Text;
    begin
        JSONManagement.InitializeObject(IsContactString);
        JSONManagement.GetJSONObject(JsonObject);

        if JSONManagement.GetStringPropertyValueFromJObjectByName(JsonObject, 'PropertyId', PropertyId) then
            if PropertyId = IsContactPropertyIdTxt then begin
                JSONManagement.GetBoolPropertyValueFromJObjectByName(JsonObject, 'Value', IsContact);
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
        JsonObject: DotNet JObject;
    begin
        JSONManagement.InitializeEmptyObject();
        JSONManagement.GetJSONObject(JsonObject);

        JSONManagement.AddJPropertyToJObject(JsonObject, 'PropertyId', IsContactPropertyIdTxt);
        JSONManagement.AddJPropertyToJObject(JsonObject, 'Value', Format(IsContact, 0, 2));

        exit(JSONManagement.WriteObjectToString());
    end;

    procedure HasIsLead(IsLeadString: Text): Boolean
    begin
        exit(HasExtendedProperty(IsLeadString, IsLeadPropertyIdTxt));
    end;

    procedure GetIsLead(IsLeadString: Text) IsLead: Boolean
    var
        JsonObject: DotNet JObject;
        PropertyId: Text;
    begin
        JSONManagement.InitializeObject(IsLeadString);
        JSONManagement.GetJSONObject(JsonObject);

        if JSONManagement.GetStringPropertyValueFromJObjectByName(JsonObject, 'PropertyId', PropertyId) then
            if PropertyId = IsLeadPropertyIdTxt then begin
                JSONManagement.GetBoolPropertyValueFromJObjectByName(JsonObject, 'Value', IsLead);
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
        JsonObject: DotNet JObject;
        PropertyId: Text;
    begin
        JSONManagement.InitializeObject(IsPartnerString);
        JSONManagement.GetJSONObject(JsonObject);

        if JSONManagement.GetStringPropertyValueFromJObjectByName(JsonObject, 'PropertyId', PropertyId) then
            if PropertyId = IsPartnerPropertyIdTxt then begin
                JSONManagement.GetBoolPropertyValueFromJObjectByName(JsonObject, 'Value', IsPartner);
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
        JSONManagement.InitializeCollection(JSONString);
    end;

    procedure InitializeObject(JSONString: Text)
    begin
        JSONManagement.InitializeObject(JSONString);
    end;

    procedure IsBlankOrEmptyJsonObject(JSONString: Text): Boolean
    var
        JSONManagement2: Codeunit "JSON Management";
        EmptyJsonObjectString: Text;
    begin
        JSONManagement2.InitializeEmptyObject();
        EmptyJsonObjectString := JSONManagement2.WriteObjectToString();
        exit((JSONString = '') or (JSONString = EmptyJsonObjectString));
    end;

    procedure WriteCollectionToString(): Text
    begin
        exit(JSONManagement.WriteCollectionToString());
    end;

    procedure WriteObjectToString(): Text
    begin
        exit(JSONManagement.WriteObjectToString());
    end;
}

