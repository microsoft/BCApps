// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Graph;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Foundation.UOM;
using Microsoft.Integration.Entity;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Sales.Customer;
using System;
using System.Text;

codeunit 5468 "Graph Mgt - Complex Types"
{

    trigger OnRun()
    begin
    end;

    var
        CodePropertyTxt: Label 'code', Locked = true;
        DescriptionPropertyTxt: Label 'description', Locked = true;
        PostalAddressTxt: Label 'PostalAddress', Locked = true;
        PostalAddressDescriptionTxt: Label 'Graph CDM - Postal Address complex type';
        DimensionTxt: Label 'Dimension', Locked = true;
        DimensionDescriptionTxt: Label 'Graph CDM - Dimension complex type.';
        NullJSONTxt: Label 'null', Locked = true;
        BookingsDateTxt: Label 'BookingsDate', Locked = true;
        BookingsDateDescriptionTxt: Label 'Graph CDM - Bookings Date complex type';
        DocumentLineObjectDetailsNoTxt: Label 'number', Locked = true;
        DocumentLineObjectDetailsNameTxt: Label 'displayName', Locked = true;
        DocumentLineObjectDetailsDescriptionTxt: Label 'description', Locked = true;
        DocumentLineObjectDetailsTxt: Label 'documentLineObjectDetails', Locked = true;
        DocumentLineObjectDetailsEDMDescriptionTxt: Label 'Graph API - Complex type exposing details of the line object that is being sold.';
        DimensionErr: Label 'The Dimension does not exist. Identification fields and values: Code=%1.', Comment = '%1 is just the short code value of the name for the dimensions';

    procedure GetDocumentLineObjectDetailsEDM(): Text
    var
        SalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate";
    begin
        exit(
          StrSubstNo('<ComplexType Name="%1">', 'documentLineObjectDetailsType') +
          StrSubstNo('<Property Name="%1" Type="Edm.String" Nullable="true" MaxLength="%2"/>',
            DocumentLineObjectDetailsNoTxt, MaxStrLen(SalesInvoiceLineAggregate."No.")) +
          StrSubstNo('<Property Name="%1" Type="Edm.String" Nullable="true" MaxLength="%2"/>',
            DocumentLineObjectDetailsNameTxt, MaxStrLen(SalesInvoiceLineAggregate.Description)) +
          '</ComplexType>');
    end;

    procedure GetDocumentLineObjectDetailsJSON(No: Text; Name: Text): Text
    var
        JSONManagement: Codeunit "JSON Management";
        JsonObject: DotNet JObject;
    begin
        JSONManagement.InitializeEmptyObject();
        JSONManagement.GetJSONObject(JsonObject);

        if No <> '' then
            JSONManagement.AddJPropertyToJObject(JsonObject, DocumentLineObjectDetailsNoTxt, No);

        if Name <> '' then
            JSONManagement.AddJPropertyToJObject(JsonObject, DocumentLineObjectDetailsNameTxt, Name);

        exit(JSONManagement.WriteObjectToString());
    end;

    procedure ParseDocumentLineObjectDetailsFromJSON(JSON: Text; var No: Code[20]; var Name: Text[100]; var Description: Text[50])
    var
        JSONManagement: Codeunit "JSON Management";
        JsonObject: DotNet JObject;
        NoTxt: Text;
        NameTxt: Text;
        DescriptionTxt: Text;
    begin
        Clear(No);
        Clear(Name);
        Clear(Description);

        JSONManagement.InitializeObject(JSON);
        JSONManagement.GetJSONObject(JsonObject);
        if JSONManagement.GetStringPropertyValueFromJObjectByName(JsonObject, DocumentLineObjectDetailsNoTxt, NoTxt) then
            No := CopyStr(NoTxt, 1, 20);

        if JSONManagement.GetStringPropertyValueFromJObjectByName(JsonObject, DocumentLineObjectDetailsNameTxt, NameTxt) then
            Name := CopyStr(NameTxt, 1, 50);

        if JSONManagement.GetStringPropertyValueFromJObjectByName(JsonObject, DocumentLineObjectDetailsDescriptionTxt, DescriptionTxt) then
            Description := CopyStr(DescriptionTxt, 1, 50);
    end;

    procedure GetBookingsDateEDM(): Text
    begin
        exit(
          '<ComplexType Name="dateTimeTimeZoneType">' +
          '  <Property Name="dateTime" Type="Edm.String" Nullable="false" />' +
          '  <Property Name="timeZone" Type="Edm.String" />' +
          '</ComplexType>');
    end;

    procedure GetBookingsDateJSON(DateTime: DateTime; var JSON: Text)
    var
        JSONManagement: Codeunit "JSON Management";
        JsonObject: DotNet JObject;
        DateString: Text;
    begin
        DateString := Format(DateTime, 0, '<Year4>-<Month,2>-<Day,2>T<Hours24,2>:<Minutes,2>:<Seconds,2>.0000001Z');

        JSONManagement.InitializeEmptyObject();
        JSONManagement.GetJSONObject(JsonObject);
        JSONManagement.AddJPropertyToJObject(JsonObject, 'dateTime', DateString);
        JSONManagement.AddJPropertyToJObject(JsonObject, 'timeZone', 'UTC');

        JSON := JSONManagement.WriteObjectToString();
    end;

    procedure GetCodeAndDescriptionEDM(TypeName: Text[32]; CodeField: Code[50]; DescriptionField: Text[250]): Text
    begin
        if StrPos(TypeName, 'Type') = 0 then
            TypeName := TypeName + 'Type';

        exit(
          StrSubstNo('<ComplexType Name="%1">', TypeName) +
          StrSubstNo('<Property Name="%1" Type="Edm.String" Nullable="true" MaxLength="%2"/>',
            CodePropertyTxt, MaxStrLen(CodeField)) +
          StrSubstNo('<Property Name="%1" Type="Edm.String" Nullable="true" MaxLength="%2"/>',
            DescriptionPropertyTxt, MaxStrLen(DescriptionField)) +
          '</ComplexType>');
    end;

    procedure GetCodeAndDescriptionJSON("Code": Code[50]; Description: Text[250]; var JSON: Text)
    var
        JSONManagement: Codeunit "JSON Management";
        JsonObject: DotNet JObject;
    begin
        JSONManagement.InitializeEmptyObject();
        JSONManagement.GetJSONObject(JsonObject);
        JSONManagement.AddJPropertyToJObject(JsonObject, CodePropertyTxt, Code);
        JSONManagement.AddJPropertyToJObject(JsonObject, DescriptionPropertyTxt, Description);
        JSON := JSONManagement.WriteObjectToString();
    end;

    procedure GetCodeAndDescriptionFromJSON(JSON: Text; var "Code": Code[50]; var Description: Text[250])
    var
        JSONManagement: Codeunit "JSON Management";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        JsonObject: DotNet JObject;
        CodeText: Text;
    begin
        if JSON = NullJSONTxt then begin
            Clear(Code);
            Clear(Description);
            exit;
        end;

        JSONManagement.InitializeObject(JSON);
        JSONManagement.GetJSONObject(JsonObject);

        GraphMgtGeneralTools.GetMandatoryStringPropertyFromJObject(JsonObject, CodePropertyTxt, CodeText);
        JSONManagement.GetStringPropertyValueFromJObjectByName(JsonObject, DescriptionPropertyTxt, Description);
        Code := CopyStr(CodeText, 1, MaxStrLen(Code));
    end;

    procedure GetPostalAddressEDM(): Text
    var
        DummyCustomer: Record Customer;
    begin
        // Additional 2 characters representing \r\n are added between address and address 2
        exit(
          '<ComplexType Name="postalAddressType">' +
          StrSubstNo('<Property Name="street" Type="Edm.String" Nullable="true" MaxLength="%1" />',
            MaxStrLen(DummyCustomer.Address) + MaxStrLen(DummyCustomer."Address 2") + 2) +
          StrSubstNo('<Property Name="city" Type="Edm.String" Nullable="true" MaxLength="%1" />',
            MaxStrLen(DummyCustomer.City)) +
          StrSubstNo('<Property Name="state" Type="Edm.String" Nullable="true" MaxLength="%1" />',
            MaxStrLen(DummyCustomer.County)) +
          StrSubstNo('<Property Name="countryLetterCode" Type="Edm.String" Nullable="true" MaxLength="%1" />',
            MaxStrLen(DummyCustomer."Country/Region Code")) +
          StrSubstNo('<Property Name="postalCode" Type="Edm.String" Nullable="true" MaxLength="%1" />',
            MaxStrLen(DummyCustomer."Post Code")) +
          '</ComplexType>');
    end;

    procedure GetUnitOfMeasureJSON(UnitOfMeasureCode: Code[20]): Text
    var
        UnitOfMeasure: Record "Unit of Measure";
        JSONManagement: Codeunit "JSON Management";
        GraphCollectionMgtItem: Codeunit "Graph Collection Mgt - Item";
        JsonObject: DotNet JObject;
    begin
        if UnitOfMeasureCode = '' then
            exit('');

        if not UnitOfMeasure.Get(UnitOfMeasureCode) then
            exit('');

        JSONManagement.InitializeEmptyObject();
        JSONManagement.GetJSONObject(JsonObject);

        // TODO: Refactor from item
        JSONManagement.AddJPropertyToJObject(JsonObject, GraphCollectionMgtItem.UOMComplexTypeUnitCode(), UnitOfMeasure.Code);
        if UnitOfMeasure.Description <> '' then
            JSONManagement.AddJPropertyToJObject(JsonObject, GraphCollectionMgtItem.UOMComplexTypeUnitName(), UnitOfMeasure.Description);

        if UnitOfMeasure.Symbol <> '' then
            JSONManagement.AddJPropertyToJObject(JsonObject, GraphCollectionMgtItem.UOMComplexTypeSymbol(), UnitOfMeasure.Symbol);

        exit(JSONManagement.WriteObjectToString());
    end;

    procedure ApplyPostalAddressFromJSON(JSON: Text; var EntityRecRef: RecordRef; Line1FieldNo: Integer; Line2FieldNo: Integer; CityFieldNo: Integer; StateFieldNo: Integer; CountryCodeFieldNo: Integer; PostCodeFieldNo: Integer)
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        JSONManagement: Codeunit "JSON Management";
        JsonObject: DotNet JObject;
        TempStreet: Text;
        Line1: Text[100];
        Line2: Text[50];
        City: Text;
        State: Text;
        CountryCode: Text;
        PostCode: Text;
    begin
        if NullJSONTxt <> JSON then begin
            JSONManagement.InitializeObject(JSON);
            JSONManagement.GetJSONObject(JsonObject);

            GraphMgtGeneralTools.GetMandatoryStringPropertyFromJObject(JsonObject, 'street', TempStreet);
            GraphCollectionMgtContact.SplitStreet(TempStreet, Line1, Line2);
            GraphMgtGeneralTools.GetMandatoryStringPropertyFromJObject(JsonObject, 'city', City);
            JSONManagement.GetStringPropertyValueFromJObjectByName(JsonObject, 'state', State);
            GraphMgtGeneralTools.GetMandatoryStringPropertyFromJObject(JsonObject, 'countryLetterCode', CountryCode);
            GraphMgtGeneralTools.GetMandatoryStringPropertyFromJObject(JsonObject, 'postalCode', PostCode);
        end;


        Validate(EntityRecRef, Line1FieldNo, Line1);
        Validate(EntityRecRef, Line2FieldNo, Line2);
        Validate(EntityRecRef, CountryCodeFieldNo, CountryCode);
        Validate(EntityRecRef, CityFieldNo, City);
        Validate(EntityRecRef, PostCodeFieldNo, PostCode);
        Validate(EntityRecRef, StateFieldNo, State);
    end;

    procedure GetPostalAddressJSON(Line1: Text; Line2: Text; City: Text; State: Text; CountryCode: Code[10]; PostCode: Code[20]; var JSON: Text)
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        JSONManagement: Codeunit "JSON Management";
        JsonObject: DotNet JObject;
    begin
        JSONManagement.InitializeEmptyObject();
        JSONManagement.GetJSONObject(JsonObject);

        JSONManagement.AddJPropertyToJObject(JsonObject, 'street', GraphCollectionMgtContact.ConcatenateStreet(Line1, Line2));
        JSONManagement.AddJPropertyToJObject(JsonObject, 'city', City);
        JSONManagement.AddJPropertyToJObject(JsonObject, 'state', State);
        JSONManagement.AddJPropertyToJObject(JsonObject, 'countryLetterCode', CountryCode);
        JSONManagement.AddJPropertyToJObject(JsonObject, 'postalCode', PostCode);

        JSON := JSONManagement.WriteObjectToString();
    end;

    procedure GetDimensionEDM(): Text
    begin
        exit(
          '<ComplexType Name="dimensionType">' +
          '<Property Name="code" Type="Edm.String" Nullable="false" />' +
          '<Property Name="displayName" Type="Edm.String" Nullable="true" />' +
          '<Property Name="valueCode" Type="Edm.String" Nullable="false" />' +
          '<Property Name="valueDisplayName" Type="Edm.String" Nullable="true" />' +
          '</ComplexType>');
    end;

    procedure GetDimensionsJSON(DimensionSetId: Integer): Text
    var
        DimensionSetEntry: Record "Dimension Set Entry";
        JSONManagement: Codeunit "JSON Management";
        JsonObject: DotNet JObject;
        JsonArray: DotNet JArray;
    begin
        DimensionSetEntry.SetRange("Dimension Set ID", DimensionSetId);
        if not DimensionSetEntry.FindSet() then
            exit('');

        JSONManagement.InitializeEmptyCollection();
        JSONManagement.GetJsonArray(JsonArray);

        repeat
            GetDimensionJObject(DimensionSetEntry, JsonObject);
            JSONManagement.AddJObjectToJArray(JsonArray, JsonObject);
        until DimensionSetEntry.Next() = 0;

        exit(JSONManagement.WriteCollectionToString());
    end;

    local procedure GetDimensionJObject(var DimensionSetEntry: Record "Dimension Set Entry"; var JsonObject: DotNet JObject)
    var
        JSONManagement: Codeunit "JSON Management";
    begin
        JSONManagement.InitializeEmptyObject();
        JSONManagement.GetJSONObject(JsonObject);
        DimensionSetEntry.CalcFields("Dimension Name", "Dimension Value Name");
        JSONManagement.AddJPropertyToJObject(JsonObject, 'code', DimensionSetEntry."Dimension Code");
        JSONManagement.AddJPropertyToJObject(JsonObject, 'displayName', DimensionSetEntry."Dimension Name");
        JSONManagement.AddJPropertyToJObject(JsonObject, 'valueCode', DimensionSetEntry."Dimension Value Code");
        JSONManagement.AddJPropertyToJObject(JsonObject, 'valueDisplayName', DimensionSetEntry."Dimension Value Name");
    end;

    procedure GetDimensionSetFromJSON(DimensionsJSON: Text; OldDimensionSetId: Integer; var NewDimensionSetId: Integer)
    var
        TempDimensionSetEntry: Record "Dimension Set Entry" temporary;
        DimensionManagement: Codeunit DimensionManagement;
        JSONManagement: Codeunit "JSON Management";
        LineJsonObject: DotNet JObject;
        I: Integer;
        NumberOfLines: Integer;
        "Code": Code[20];
        Value: Code[20];
    begin
        JSONManagement.InitializeCollection(DimensionsJSON);
        NumberOfLines := JSONManagement.GetCollectionCount();
        for I := 1 to NumberOfLines do begin
            JSONManagement.GetJObjectFromCollectionByIndex(LineJsonObject, I - 1);
            GetDimensionFromJObject(LineJsonObject, Code, Value);
            TempDimensionSetEntry.Init();
            TempDimensionSetEntry."Dimension Set ID" := OldDimensionSetId;
            TempDimensionSetEntry."Dimension Code" := Code;
            TempDimensionSetEntry."Dimension Value Code" := Value;
            TempDimensionSetEntry.Insert(true);
        end;

        NewDimensionSetId := DimensionManagement.GetDimensionSetID(TempDimensionSetEntry);
    end;

    local procedure GetDimensionFromJObject(var JsonObject: DotNet JObject; var "Code": Code[20]; var Value: Code[20])
    var
        Dimension: Record Dimension;
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        CodeText: Text;
        ValueText: Text;
    begin
        GraphMgtGeneralTools.GetMandatoryStringPropertyFromJObject(JsonObject, 'code', CodeText);
        GraphMgtGeneralTools.GetMandatoryStringPropertyFromJObject(JsonObject, 'valueCode', ValueText);
        Code := CopyStr(CodeText, 1, MaxStrLen(Code));
        if Code <> '' then
            if not Dimension.Get(Code) then
                Error(DimensionErr, Code);
        Value := CopyStr(ValueText, 1, MaxStrLen(Value));
    end;

    [Scope('OnPrem')]
    procedure InsertOrUpdateBookingsDate()
    var
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        EDM: Text;
    begin
        EDM := GetBookingsDateEDM();
        GraphMgtGeneralTools.InsertOrUpdateODataType(UpperCase(BookingsDateTxt), BookingsDateDescriptionTxt, EDM);
    end;

    local procedure InsertOrUpdateDocumentLineObjectDescription()
    var
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        EDM: Text;
    begin
        EDM := GetDocumentLineObjectDetailsEDM();
        GraphMgtGeneralTools.InsertOrUpdateODataType(
          UpperCase(DocumentLineObjectDetailsTxt), DocumentLineObjectDetailsEDMDescriptionTxt, EDM);
    end;

    [Scope('OnPrem')]
    procedure InsertOrUpdatePostalAddress()
    var
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        EDM: Text;
    begin
        EDM := GetPostalAddressEDM();
        GraphMgtGeneralTools.InsertOrUpdateODataType(UpperCase(PostalAddressTxt), PostalAddressDescriptionTxt, EDM);
    end;

    local procedure InsertOrUpdateDimension()
    var
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        EDM: Text;
    begin
        EDM := GetDimensionEDM();
        GraphMgtGeneralTools.InsertOrUpdateODataType(UpperCase(DimensionTxt), DimensionDescriptionTxt, EDM);
    end;

    local procedure Validate(var EntityRecRef: RecordRef; FieldNo: Integer; Value: Variant)
    var
        FieldRef: FieldRef;
    begin
        FieldRef := EntityRecRef.Field(FieldNo);
        FieldRef.Validate(Value);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Graph Mgt - General Tools", 'ApiSetup', '', false, false)]
    local procedure HandleApiSetup()
    begin
        InsertOrUpdatePostalAddress();
        InsertOrUpdateBookingsDate();
        InsertOrUpdateDocumentLineObjectDescription();
        InsertOrUpdateDimension();
    end;

    procedure GetSalesLineDescriptionComplexType(var SalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate"): Text
    var
        FixedAsset: Record "Fixed Asset";
        Item: Record Item;
        GLAccount: Record "G/L Account";
        Resource: Record Resource;
        ItemCharge: Record "Item Charge";
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
        Name: Text;
    begin
        if SalesInvoiceLineAggregate."No." = '' then
            exit;

        case SalesInvoiceLineAggregate.Type of
            SalesInvoiceLineAggregate.Type::" ":
                exit;
            SalesInvoiceLineAggregate.Type::"Charge (Item)":
                begin
                    ItemCharge.Get(SalesInvoiceLineAggregate."No.");
                    Name := ItemCharge.Description;
                end;
            SalesInvoiceLineAggregate.Type::Resource:
                begin
                    Resource.Get(SalesInvoiceLineAggregate."No.");
                    Name := Resource.Name;
                end;
            SalesInvoiceLineAggregate.Type::"Fixed Asset":
                begin
                    FixedAsset.Get(SalesInvoiceLineAggregate."No.");
                    Name := FixedAsset.Description;
                end;
            SalesInvoiceLineAggregate.Type::"G/L Account":
                begin
                    GLAccount.Get(SalesInvoiceLineAggregate."No.");
                    Name := GLAccount.Name;
                end;
            SalesInvoiceLineAggregate.Type::Item:
                begin
                    Item.Get(SalesInvoiceLineAggregate."No.");
                    Name := Item.Description;
                end;
        end;

        exit(GraphMgtComplexTypes.GetDocumentLineObjectDetailsJSON(SalesInvoiceLineAggregate."No.", Name));
    end;

    procedure GetPurchaseLineDescriptionComplexType(var PurchInvLineAggregate: Record "Purch. Inv. Line Aggregate"): Text
    var
        FixedAsset: Record "Fixed Asset";
        Item: Record Item;
        GLAccount: Record "G/L Account";
        ItemCharge: Record "Item Charge";
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
        Name: Text;
    begin
        if PurchInvLineAggregate."No." = '' then
            exit;

        case PurchInvLineAggregate.Type of
            PurchInvLineAggregate.Type::" ":
                exit;
            PurchInvLineAggregate.Type::"Charge (Item)":
                begin
                    ItemCharge.Get(PurchInvLineAggregate."No.");
                    Name := ItemCharge.Description;
                end;
            PurchInvLineAggregate.Type::"Fixed Asset":
                begin
                    FixedAsset.Get(PurchInvLineAggregate."No.");
                    Name := FixedAsset.Description;
                end;
            PurchInvLineAggregate.Type::"G/L Account":
                begin
                    GLAccount.Get(PurchInvLineAggregate."No.");
                    Name := GLAccount.Name;
                end;
            PurchInvLineAggregate.Type::Item:
                begin
                    Item.Get(PurchInvLineAggregate."No.");
                    Name := Item.Description;
                end;
        end;

        exit(GraphMgtComplexTypes.GetDocumentLineObjectDetailsJSON(PurchInvLineAggregate."No.", Name));
    end;
}

