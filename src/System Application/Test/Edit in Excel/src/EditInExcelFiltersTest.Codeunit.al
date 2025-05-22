// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Integration.Excel;

using System.TestLibraries.Integration.Excel;
using System.Integration.Excel;
using System;
using System.TestLibraries.Utilities;
codeunit 132526 "Edit in Excel Filters Test"
{
    Subtype = Test;
    EventSubscriberInstance = Manual;

    var
        LibraryAssert: Codeunit "Library Assert";

    [Test]
    procedure TestEditInExcelFieldFilterGetCollectionTypeReturnsCorrectAndOperator()
    var
        EditinExcelFilters: Codeunit "Edit in Excel Filters";
        EditInExcelFilter: Interface "Edit in Excel Field Filter v2";
        FieldName: Text;
        EditInExcelFilterCollectionType: Enum "Edit in Excel Filter Collection Type";
    begin
        FieldName := 'No_';

        EditinExcelFilters.AddFieldV2(FieldName, "Edit in Excel Filter Collection Type"::"and", Enum::"Edit in Excel Edm Type"::"Edm.String");
        EditinExcelFilters.GetV2(FieldName).AddFilterValueV2(Enum::"Edit in Excel Filter Type"::Equal, '10000');
        EditinExcelFilters.GetV2(FieldName).AddFilterValueV2(Enum::"Edit in Excel Filter Type"::Equal, '10001');

        EditInExcelFilter := EditinExcelFilters.GetV2(FieldName);
        EditInExcelFilterCollectionType := EditInExcelFilter.GetCollectionType();
        LibraryAssert.AreEqual("Edit in Excel Filter Collection Type"::"and", EditInExcelFilterCollectionType, 'Field filter created with an AND operator should have a collection type of AND.')
    end;

    [Test]
    procedure TestEditInExcelFieldFilterGetCollectionTypeReturnsCorrectOrOperator()
    var
        EditinExcelFilters: Codeunit "Edit in Excel Filters";
        EditInExcelFilter: Interface "Edit in Excel Field Filter v2";
        FieldName: Text;
        EditInExcelFilterCollectionType: Enum "Edit in Excel Filter Collection Type";
    begin
        FieldName := 'No_';

        EditinExcelFilters.AddFieldV2(FieldName, "Edit in Excel Filter Collection Type"::"or", Enum::"Edit in Excel Edm Type"::"Edm.String");
        EditinExcelFilters.GetV2(FieldName).AddFilterValueV2(Enum::"Edit in Excel Filter Type"::Equal, '10000');
        EditinExcelFilters.GetV2(FieldName).AddFilterValueV2(Enum::"Edit in Excel Filter Type"::Equal, '10001');

        EditInExcelFilter := EditinExcelFilters.GetV2(FieldName);
        EditInExcelFilterCollectionType := EditInExcelFilter.GetCollectionType();
        LibraryAssert.AreEqual("Edit in Excel Filter Collection Type"::"or", EditInExcelFilterCollectionType, 'Field filter created with an OR operator should have a collection type of OR.')
    end;

    [Test]
    procedure TestEditInExcelStructuredFiltersDateTime()
    var
        EditinExcelTestLibrary: Codeunit "Edit in Excel Test Library";
        EditinExcelFilters: Codeunit "Edit in Excel Filters";
        JsonFilter: Text;
        JsonPayload: Text;
        DateText: Text;
        FilterJsonObject: JsonObject;
        PayloadJsonObject: JsonObject;
        FieldFilters: DotNet GenericDictionary2;
        FilterCollectionNode: DotNet FilterCollectionNode;
        FilterBinaryNode: DotNet FilterBinaryNode;
    begin
        // [Scenario] User clicks "Edit in Excel" without choosing additional filters. BC sends the default date filter

        // [Given] A Json Structured filter and Payload, TenantWebservice exist and is enabled
        JsonFilter := '{"type":"and","childNodes":[{"type":"and","childNodes":[{"type":"ge","leftNode":{"type":"var","name":"Date_Filter"},"rightNode":{"type":"Edm.DateTimeOffset constant","value":"0001-01-01T00:00:00"}},{"type":"le","leftNode":{"type":"var","name":"Date_Filter"},"rightNode":{"type":"Edm.DateTimeOffset constant","value":"2024-01-25T00:00:00"}}]}]}';
        JsonPayload := '{ "fieldPayload": {"Date_Filter": {"alName": "Date Filter","validInODataFilter": true,"edmType": "Edm.DateTimeOffset"}}}';
        LibraryAssert.IsTrue(FilterJsonObject.ReadFrom(JsonFilter), 'Could not read json filter');
        LibraryAssert.IsTrue(PayloadJsonObject.ReadFrom(JsonPayload), 'Could not read json payload');

        // [When] Edit in Excel filters are created
        EditinExcelTestLibrary.ReadFromJsonFilters(EditinExcelFilters, FilterJsonObject, PayloadJsonObject, Page::"Edit in Excel List");

        // [Then] The filters match expectations
        EditinExcelTestLibrary.GetFilters(EditinExcelFilters, FieldFilters);
        LibraryAssert.IsFalse(IsNull(FieldFilters), 'No field filters created.');
        LibraryAssert.AreEqual(1, FieldFilters.Count(), 'Incorrect number of fields being filtered.');
        FilterCollectionNode := FieldFilters.Item('Date_Filter');
        LibraryAssert.AreEqual(2, FilterCollectionNode.Collection.Count(), 'Incorrect number of filters for field 0');
        LibraryAssert.AreEqual('and', FilterCollectionNode.Operator, 'Incorrect operator for field 0');

        FilterBinaryNode := FilterCollectionNode.Collection.Item(0);
        LibraryAssert.AreEqual('Date_Filter', FilterBinaryNode.Left.Field, 'Incorrect field name for field 0 filter 0');
        LibraryAssert.AreEqual('Edm.DateTimeOffset', FilterBinaryNode.Left.Type, 'Incorrect type for field 0 filter 0');
        LibraryAssert.AreEqual('ge', FilterBinaryNode.Operator, 'Incorrect operator for field 0 filter 0');
        DateText := '0001-01-01T00:00:00';
        LibraryAssert.AreEqual(DateText, FilterBinaryNode.Right, 'Incorrect Right value for field 0 filter 0');

        FilterBinaryNode := FilterCollectionNode.Collection.Item(1);
        LibraryAssert.AreEqual('Date_Filter', FilterBinaryNode.Left.Field, 'Incorrect field name for field 0 filter 1');
        LibraryAssert.AreEqual('Edm.DateTimeOffset', FilterBinaryNode.Left.Type, 'Incorrect type for field 0 filter 1');
        LibraryAssert.AreEqual('le', FilterBinaryNode.Operator, 'Incorrect operator for field 0 filter 1');
        DateText := '2024' + '-01-25T00:00:00';
        LibraryAssert.AreEqual(DateText, FilterBinaryNode.Right, 'Incorrect Right value for field 0 filter 1');
    end;

    [Test]
    procedure TestEditInExcelRemoveFiltersOnFieldsNotExposedOnThePage()
    var
        EditinExcelTestLibrary: Codeunit "Edit in Excel Test Library";
        EditinExcelFilters: Codeunit "Edit in Excel Filters";
        JsonFilter: Text;
        JsonPayload: Text;
        FilterJsonObject: JsonObject;
        PayloadJsonObject: JsonObject;
        FieldFilters: DotNet GenericDictionary2;
    begin
        // [Scenario] User clicks "Edit in Excel" without choosing additional filters. BC sends the default date filter

        // [Given] A Json Structured filter and Payload, TenantWebservice exist and is enabled
        JsonFilter := '{ "type": "and", "childNodes": [ { "type": "ge", "leftNode": { "type": "var", "name": "Field_Not_Exposed" }, "rightNode": { "type": "Edm.DateTimeOffset constant", "value": "0001-01-01T00:00:00"}}]}';
        JsonPayload := '{ "fieldPayload": {"Field_Not_Exposed": {"alName": "Field Not Exposed","validInODataFilter": true,"edmType": "Edm.DateTimeOffset"}}}';
        LibraryAssert.IsTrue(FilterJsonObject.ReadFrom(JsonFilter), 'Could not read json filter');
        LibraryAssert.IsTrue(PayloadJsonObject.ReadFrom(JsonPayload), 'Could not read json payload');

        // [When] Edit in Excel filters are created
        EditinExcelTestLibrary.ReadFromJsonFilters(EditinExcelFilters, FilterJsonObject, PayloadJsonObject, Page::"Edit in Excel List");

        // [Then] The filters match expectations
        EditinExcelTestLibrary.GetFilters(EditinExcelFilters, FieldFilters);

        LibraryAssert.IsTrue(IsNull(FieldFilters), 'FieldFilters is initialized, but should be null');
    end;

    [Test]
    procedure TestEditInExcelRemoveFiltersOnFieldsNotExposedOnThePageExceptForOneThatIs()
    var
        EditinExcelTestLibrary: Codeunit "Edit in Excel Test Library";
        EditinExcelFilters: Codeunit "Edit in Excel Filters";
        JsonFilter: Text;
        JsonPayload: Text;
        FilterJsonObject: JsonObject;
        PayloadJsonObject: JsonObject;
        FieldFilters: DotNet GenericDictionary2;
    begin
        // [Scenario] User clicks "Edit in Excel" without choosing additional filters. BC sends the default date filter

        // [Given] A Json Structured filter and Payload, TenantWebservice exist and is enabled
        JsonFilter := '{"type":"and","childNodes":[{"type":"eq","leftNode":{"type":"var","name":"No"},"rightNode":{"type":"Edm.String constant","value":"1"}},{"type":"gt","leftNode":{"type":"var","name":"SystemCreatedAt"},"rightNode":{"type":"Edm.DateTimeOffset constant","value":"2024-06-08T06:00:00.0000000Z"}},{"type":"eq","leftNode":{"type":"var","name":"SystemCreatedBy"},"rightNode":{"type":"Edm.String constant","value":"{CA4755DA-D377-45B0-8B70-D723F621C68B}"}},{"type":"gt","leftNode":{"type":"var","name":"SystemModifiedAt"},"rightNode":{"type":"Edm.DateTimeOffset constant","value":"2024-06-08T06:00:00.0000000Z"}},{"type":"eq","leftNode":{"type":"var","name":"SystemModifiedBy"},"rightNode":{"type":"Edm.String constant","value":"{CA4755DA-D377-45B0-8B70-D723F621C68B}"}}]}';
        JsonPayload := '{ "fieldPayload": {"No": {"alName": "No","validInODataFilter": true,"edmType": "Edm.DateTimeOffset"}, "SystemCreatedAt": {"alName": "SystemCreatedAt","validInODataFilter": true,"edmType": "Edm.DateTimeOffset"}, "SystemCreatedBy":{"alName": "SystemCreatedBy","validInODataFilter": true,"edmType": "Edm.DateTimeOffset"}, "SystemModifiedAt": {"alName": "SystemModifiedAt","validInODataFilter": true,"edmType": "Edm.DateTimeOffset"}, "SystemModifiedBy": {"alName": "SystemModifiedBy","validInODataFilter": true,"edmType": "Edm.DateTimeOffset"}}}';
        LibraryAssert.IsTrue(FilterJsonObject.ReadFrom(JsonFilter), 'Could not read json filter');
        LibraryAssert.IsTrue(PayloadJsonObject.ReadFrom(JsonPayload), 'Could not read json payload');

        // [When] Edit in Excel filters are created
        EditinExcelTestLibrary.ReadFromJsonFilters(EditinExcelFilters, FilterJsonObject, PayloadJsonObject, Page::"Edit in Excel List");

        // [Then] The filters match expectations
        EditinExcelTestLibrary.GetFilters(EditinExcelFilters, FieldFilters);
        LibraryAssert.IsFalse(IsNull(FieldFilters), 'No field filters created.');
        LibraryAssert.AreEqual(1, FieldFilters.Count(), 'All field filters should be removed except for "No" which is exposed on the page.');
    end;

    [Test]
    procedure TestEditInExcelStructuredFilterOneChosenFilter()
    var
        EditinExcelTestLibrary: Codeunit "Edit in Excel Test Library";
        EditinExcelFilters: Codeunit "Edit in Excel Filters";
        JsonFilter: Text;
        JsonPayload: Text;
        DateText: Text;
        FilterJsonObject: JsonObject;
        PayloadJsonObject: JsonObject;
        FieldFilters: DotNet GenericDictionary2;
        FilterCollectionNode: DotNet FilterCollectionNode;
        FilterBinaryNode: DotNet FilterBinaryNode;
    begin
        // [Scenario] User chooses one filter, with BC appending the default date filter as well

        // [Given] Filter and Payload JSON Objects, containing the date filter and the filter chosen by the user
        JsonFilter := '{"type":"and","childNodes":[{"type":"eq","leftNode":{"type":"var","name":"Id"},"rightNode":{"type":"Edm.String constant","value":"01121212"}},{"type":"or","childNodes":[{"type":"ge","leftNode":{"type":"var","name":"Date_Filter"},"rightNode":{"type":"Edm.DateTimeOffset constant","value":"0001-01-01T00:00:00"}},{"type":"le","leftNode":{"type":"var","name":"Date_Filter"},"rightNode":{"type":"Edm.DateTimeOffset constant","value":"2024-01-25T00:00:00"}}]}]}';
        JsonPayload := '{ "fieldPayload": { "Id": { "alName": "Id", "validInODataFilter": true, "edmType": "Edm.String" }, "Date_Filter": { "alName": "Date Filter", "validInODataFilter": true, "edmType": "Edm.DateTimeOffset" }}}';
        LibraryAssert.IsTrue(FilterJsonObject.ReadFrom(JsonFilter), 'Could not read json filter');
        LibraryAssert.IsTrue(PayloadJsonObject.ReadFrom(JsonPayload), 'Could not read json payload');

        // [When] Edit in Excel filters are created
        EditinExcelTestLibrary.ReadFromJsonFilters(EditinExcelFilters, FilterJsonObject, PayloadJsonObject, Page::"Edit in Excel List");

        // [Then] The filters match expectations
        EditinExcelTestLibrary.GetFilters(EditinExcelFilters, FieldFilters);
        LibraryAssert.IsFalse(IsNull(FieldFilters), 'No field filters created.');
        LibraryAssert.AreEqual(2, FieldFilters.Count(), 'Incorrect number of fields being filtered.');

        // Date_Filter filter
        FilterCollectionNode := FieldFilters.Item('Date_Filter');
        LibraryAssert.AreEqual(2, FilterCollectionNode.Collection.Count(), 'Incorrect number of filters for field 0');
        LibraryAssert.AreEqual('or', FilterCollectionNode.Operator, 'Incorrect operator for field 0');

        FilterBinaryNode := FilterCollectionNode.Collection.Item(0);
        LibraryAssert.AreEqual('Date_Filter', FilterBinaryNode.Left.Field, 'Incorrect field name for field 0 filter 0');
        LibraryAssert.AreEqual('Edm.DateTimeOffset', FilterBinaryNode.Left.Type, 'Incorrect type for field 0 filter 0');
        LibraryAssert.AreEqual('ge', FilterBinaryNode.Operator, 'Incorrect operator for field 0 filter 0');
        DateText := '0001-01-01T00:00:00';
        LibraryAssert.AreEqual(DateText, FilterBinaryNode.Right, 'Incorrect Right value for field 0 filter 0');

        FilterBinaryNode := FilterCollectionNode.Collection.Item(1);
        LibraryAssert.AreEqual('Date_Filter', FilterBinaryNode.Left.Field, 'Incorrect field name for field 0 filter 1');
        LibraryAssert.AreEqual('Edm.DateTimeOffset', FilterBinaryNode.Left.Type, 'Incorrect type for field 0 filter 1');
        LibraryAssert.AreEqual('le', FilterBinaryNode.Operator, 'Incorrect operator for field 0 filter 1');
        DateText := '2024' + '-01-25T00:00:00';
        LibraryAssert.AreEqual(DateText, FilterBinaryNode.Right, 'Incorrect Right value for field 0 filter 1');

        // No filter
        FilterCollectionNode := FieldFilters.Item('Id');
        LibraryAssert.AreEqual(1, FilterCollectionNode.Collection.Count(), 'Incorrect number of filters for field 1');
        LibraryAssert.AreEqual('and', FilterCollectionNode.Operator, 'Incorrect operator for field 1');

        FilterBinaryNode := FilterCollectionNode.Collection.Item(0);
        LibraryAssert.AreEqual('Id', FilterBinaryNode.Left.Field, 'Incorrect field name for field 1 filter 1');
        LibraryAssert.AreEqual('Edm.String', FilterBinaryNode.Left.Type, 'Incorrect type for field 1 filter 1');
        LibraryAssert.AreEqual('eq', FilterBinaryNode.Operator, 'Incorrect operator for field 1 filter 1');
        LibraryAssert.AreEqual('01121212', FilterBinaryNode.Right, 'Incorrect Right value for field 1 filter 1');
    end;

    [Test]
    procedure TestEditInExcelDoNotRemoveFilterWhenFieldIsNotExposedOnPageButIsKey()
    var
        EditinExcelTestLibrary: Codeunit "Edit in Excel Test Library";
        EditinExcelFilters: Codeunit "Edit in Excel Filters";
        JsonFilter: Text;
        JsonPayload: Text;
        FilterJsonObject: JsonObject;
        PayloadJsonObject: JsonObject;
        FieldFilters: DotNet GenericDictionary2;
    begin
        // [Scenario] User clicks "Edit in Excel" without choosing additional filters. BC sends the default date filter

        // [Given] A Json Structured filter and Payload, TenantWebservice exist and is enabled
        JsonFilter := '{"type":"eq","leftNode":{"type":"var","name":"Id"},"rightNode":{"type":"Edm.String constant","value":"01121212"}}';
        JsonPayload := '{ "fieldPayload": { "Id": { "alName": "Id", "validInODataFilter": true, "edmType": "Edm.String" }}}';
        LibraryAssert.IsTrue(FilterJsonObject.ReadFrom(JsonFilter), 'Could not read json filter');
        LibraryAssert.IsTrue(PayloadJsonObject.ReadFrom(JsonPayload), 'Could not read json payload');

        // [When] Edit in Excel filters are created
        EditinExcelTestLibrary.ReadFromJsonFilters(EditinExcelFilters, FilterJsonObject, PayloadJsonObject, Page::"Edit in Excel List 2");

        // [Then] The filters match expectations
        EditinExcelTestLibrary.GetFilters(EditinExcelFilters, FieldFilters);

        LibraryAssert.IsFalse(IsNull(FieldFilters), 'No field filters created.');
        LibraryAssert.AreEqual(1, FieldFilters.Count(), 'The field "Id" is filtered out despite being a key in the underlying table.');
    end;

    [Test]
    procedure TestEditInExcelStructuredFilterSingleFilter()
    var
        EditinExcelTestLibrary: Codeunit "Edit in Excel Test Library";
        EditinExcelFilters: Codeunit "Edit in Excel Filters";
        JsonFilter: Text;
        JsonPayload: Text;
        FilterJsonObject: JsonObject;
        PayloadJsonObject: JsonObject;
        FieldFilters: DotNet GenericDictionary2;
        FilterCollectionNode: DotNet FilterCollectionNode;
        FilterBinaryNode: DotNet FilterBinaryNode;
    begin
        // [Scenario] Edit in Excel API is called with only a single filter passed

        // [Given] A Filter object with one filter, Payload object
        JsonFilter := '{"type":"eq","leftNode":{"type":"var","name":"Id"},"rightNode":{"type":"Edm.String constant","value":"01121212"}}';
        JsonPayload := '{ "fieldPayload": { "Id": { "alName": "Id", "validInODataFilter": true, "edmType": "Edm.String" }}}';
        LibraryAssert.IsTrue(FilterJsonObject.ReadFrom(JsonFilter), 'Could not read json filter');
        LibraryAssert.IsTrue(PayloadJsonObject.ReadFrom(JsonPayload), 'Could not read json payload');

        // [When] Edit in Excel filters are created
        EditinExcelTestLibrary.ReadFromJsonFilters(EditinExcelFilters, FilterJsonObject, PayloadJsonObject, Page::"Edit in Excel List");

        // [Then] The filters match expectations
        EditinExcelTestLibrary.GetFilters(EditinExcelFilters, FieldFilters);
        LibraryAssert.IsFalse(IsNull(FieldFilters), 'No field filters created.');
        LibraryAssert.AreEqual(1, FieldFilters.Count(), 'Incorrect number of fields being filtered.');

        // Id filter
        FilterCollectionNode := FieldFilters.Item('Id');
        LibraryAssert.AreEqual(1, FilterCollectionNode.Collection.Count(), 'Incorrect number of filters for field 0');
        LibraryAssert.AreEqual('and', FilterCollectionNode.Operator, 'Incorrect operator for field 0');

        FilterBinaryNode := FilterCollectionNode.Collection.Item(0);
        LibraryAssert.AreEqual('Id', FilterBinaryNode.Left.Field, 'Incorrect field name for field 0 filter 1');
        LibraryAssert.AreEqual('Edm.String', FilterBinaryNode.Left.Type, 'Incorrect type for field 0 filter 1');
        LibraryAssert.AreEqual('eq', FilterBinaryNode.Operator, 'Incorrect operator for field 0 filter 1');
        LibraryAssert.AreEqual('01121212', FilterBinaryNode.Right, 'Incorrect Right value for field 0 filter 1');
    end;

    [Test]
    procedure TestEditInExcelStructuredFilterNoFilter()
    var
        EditinExcelTestLibrary: Codeunit "Edit in Excel Test Library";
        EditinExcelFilters: Codeunit "Edit in Excel Filters";
        JsonFilter: Text;
        JsonPayload: Text;
        FilterJsonObject: JsonObject;
        PayloadJsonObject: JsonObject;
        FieldFilters: DotNet GenericDictionary2;
    begin
        // [Scenario] Empty JSON filter object is passed when calling Edit in Excel

        // [Given] An empty object is passed in filter and payload
        JsonFilter := '{}';
        JsonPayload := '{}';
        LibraryAssert.IsTrue(FilterJsonObject.ReadFrom(JsonFilter), 'Could not read json filter');
        LibraryAssert.IsTrue(PayloadJsonObject.ReadFrom(JsonPayload), 'Could not read json payload');

        // [When] Edit in Excel filters are created
        EditinExcelTestLibrary.ReadFromJsonFilters(EditinExcelFilters, FilterJsonObject, PayloadJsonObject, Page::"Edit in Excel List");

        // [Then] The filters match expectations
        EditinExcelTestLibrary.GetFilters(EditinExcelFilters, FieldFilters);
        LibraryAssert.IsTrue(IsNull(FieldFilters), 'Field filters were created.');
    end;

    [Test]
    procedure TestEditInExcelStructuredFilterIllegalFilter()
    var
        EditinExcelTestLibrary: Codeunit "Edit in Excel Test Library";
        EditinExcelFilters: Codeunit "Edit in Excel Filters";
        JsonFilter: Text;
        JsonPayload: Text;
        FilterJsonObject: JsonObject;
        PayloadJsonObject: JsonObject;
        FieldFilters: DotNet GenericDictionary2;
        FilterCollectionNode: DotNet FilterCollectionNode;
        FilterBinaryNode: DotNet FilterBinaryNode;
    begin
        // [Scenario] API is called with a json filter that contains bor "OR" and "AND" operators, which is not supported by OData

        // [Given] A Json filter with both or and and operator on the Date field, Json Payload
        JsonFilter := '{"type":"and","childNodes":[{"type":"eq","leftNode":{"type":"var","name":"Id"},"rightNode":{"type":"Edm.String constant","value":"1000"}},{"type":"or","childNodes":[{"type":"ge","leftNode":{"type":"var","name":"Id"},"rightNode":{"type":"Edm.String constant","value":"0"}},{"type":"le","leftNode":{"type":"var","name":"Id"},"rightNode":{"type":"Edm.String constant","value":"100"}}]}]}';
        JsonPayload := '{ "fieldPayload": { "Id": { "alName": "Id", "validInODataFilter": true, "edmType": "Edm.String" }}}';
        LibraryAssert.IsTrue(FilterJsonObject.ReadFrom(JsonFilter), 'Could not read json filter');
        LibraryAssert.IsTrue(PayloadJsonObject.ReadFrom(JsonPayload), 'Could not read json payload');

        // [When] Edit in Excel filters are created
        EditinExcelTestLibrary.ReadFromJsonFilters(EditinExcelFilters, FilterJsonObject, PayloadJsonObject, Page::"Edit in Excel List");

        // [Then] The filters match expectations
        EditinExcelTestLibrary.GetFilters(EditinExcelFilters, FieldFilters);
        LibraryAssert.IsFalse(IsNull(FieldFilters), 'No field filters created.');
        LibraryAssert.AreEqual(1, FieldFilters.Count(), 'Incorrect number of fields being filtered.');

        // Id filter
        FilterCollectionNode := FieldFilters.Item('Id');
        LibraryAssert.AreEqual(1, FilterCollectionNode.Collection.Count(), 'Incorrect number of filters for field 0');
        LibraryAssert.AreEqual('and', FilterCollectionNode.Operator, 'Incorrect operator for field 0');

        FilterBinaryNode := FilterCollectionNode.Collection.Item(0);
        LibraryAssert.AreEqual('Id', FilterBinaryNode.Left.Field, 'Incorrect field name for field 0 filter 1');
        LibraryAssert.AreEqual('Edm.String', FilterBinaryNode.Left.Type, 'Incorrect type for field 0 filter 1');
        LibraryAssert.AreEqual('eq', FilterBinaryNode.Operator, 'Incorrect operator for field 0 filter 1');
        LibraryAssert.AreEqual('1000', FilterBinaryNode.Right, 'Incorrect Right value for field 0 filter 1');
    end;
}
