// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries.Test;

using System.TestLibraries.Utilities;
using System.TestTools.AITestToolkit;
using System.TestTools.TestRunner;

codeunit 133691 "No. Series Cop. Search Accu."
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = AITest;

    var
        Assert: Codeunit "Library Assert";
        AITTestContext: Codeunit "AIT Test Context";
        NoSeriesCopilotTestLib: Codeunit "Library - No. Series Copilot";
        FieldNotFoundErr: Label '%1 / %2 was not found.', Comment = '%1 = Setup table name, %2 = Field name';

    [Test]
    procedure SearchFindsExpectedSetupFields()
    var
        ExpectedData: Codeunit "Test Input Json";
        ExpectedField: Codeunit "Test Input Json";
        Entities: List of [Text];
        Results: JsonArray;
        i: Integer;
        ResultsText: Text;
    begin
        // [SCENARIO] Keyword and semantic search together find the setup number series fields for an entity
        // [GIVEN] An entity from the dataset
        Entities.Add(AITTestContext.GetQuery().ValueAsText());

        // [WHEN] All search methods run
        Results := NoSeriesCopilotTestLib.SearchRelevantFields(Entities);
        Results.WriteTo(ResultsText);
        AITTestContext.SetTestOutput(ResultsText);

        // [THEN] Every expected field is found, and an unrelated entity finds nothing
        ExpectedData := AITTestContext.GetExpectedData();
        if ExpectedData.GetElementCount() = 0 then
            Assert.AreEqual(0, Results.Count(), 'An unrelated entity must not find any setup field.');

        for i := 0 to ExpectedData.GetElementCount() - 1 do begin
            ExpectedField := ExpectedData.ElementAt(i);
            Assert.IsTrue(
                ContainsField(Results, ExpectedField.Element('table_name').ValueAsText(), ExpectedField.Element('field_name').ValueAsText()),
                StrSubstNo(FieldNotFoundErr, ExpectedField.Element('table_name').ValueAsText(), ExpectedField.Element('field_name').ValueAsText()));
        end;
    end;

    local procedure ContainsField(Results: JsonArray; TableName: Text; FieldName: Text): Boolean
    var
        Result: JsonToken;
        Value: JsonToken;
    begin
        foreach Result in Results do begin
            Result.AsObject().Get('tableName', Value);
            if Value.AsValue().AsText() = TableName then begin
                Result.AsObject().Get('fieldName', Value);
                if Value.AsValue().AsText() = FieldName then
                    exit(true);
            end;
        end;
        exit(false);
    end;
}
