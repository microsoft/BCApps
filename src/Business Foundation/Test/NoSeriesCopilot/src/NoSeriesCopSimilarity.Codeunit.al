// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries.Test;

using System.Reflection;
using System.TestLibraries.Utilities;
using System.TestTools.AITestToolkit;
using System.TestTools.TestRunner;

codeunit 133692 "No. Series Cop. Similarity"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = AITest;

    var
        Assert: Codeunit "Library Assert";
        AITTestContext: Codeunit "AIT Test Context";
        NoSeriesCopilotTestLib: Codeunit "Library - No. Series Copilot";
        RankTooLowErr: Label 'The expected field ranked %1.', Comment = '%1 = Rank of the expected field';
        SimilarityTooLowErr: Label 'The expected field scored %1.', Comment = '%1 = Similarity of the expected field';
        UnknownComparedFieldErr: Label 'Unknown compared field %1.', Comment = '%1 = Name of a Field table field from the dataset';

    [Test]
    procedure SimilarityRanksExpectedSetupField()
    var
        ExpectedData: Codeunit "Test Input Json";
        Expected: Codeunit "Test Input Json";
        Results: JsonArray;
        TestOutput: JsonObject;
        TestOutputText: Text;
        Rank: Integer;
        Similarity: Decimal;
        HighestSimilarity: Decimal;
        Found: Boolean;
    begin
        // [SCENARIO] Platform semantic similarity ranks the expected setup field high enough for the compared Field table fields
        // [GIVEN] A search text and the Field table fields to compare, from the dataset
        // [WHEN] The setup number series fields are ranked by similarity
        Results := NoSeriesCopilotTestLib.FindSimilarSetupFields(
            AITTestContext.GetQuery().ValueAsText(), GetComparedFieldIds(AITTestContext.GetInput().Element('compared_fields').ValueAsText()), MaxResultsToLog());
        HighestSimilarity := GetSimilarity(Results, 0);

        ExpectedData := AITTestContext.GetExpectedData();
        Expected := ExpectedData.ElementAt(0);
        Expected.ElementExists('table_name', Found);
        if Found then
            FindRank(Results, Expected.Element('table_name').ValueAsText(), Expected.Element('field_name').ValueAsText(), Rank, Similarity);

        TestOutput.Add('rank', Rank);
        TestOutput.Add('similarity', Similarity);
        TestOutput.Add('highestSimilarity', HighestSimilarity);
        TestOutput.Add('results', Results);
        TestOutput.WriteTo(TestOutputText);
        AITTestContext.SetTestOutput(TestOutputText);

        // [THEN] The expected field reaches the rank and similarity limits, or an unrelated text stays below the similarity limit
        if not Found then begin
            Assert.IsTrue(HighestSimilarity < Expected.Element('max_similarity').ValueAsDecimal(), 'An unrelated text must stay below the similarity limit.');
            exit;
        end;

        Assert.AreNotEqual(0, Rank, 'The expected field was not ranked.');
        Assert.IsTrue(Rank <= Expected.Element('max_rank').ValueAsInteger(), StrSubstNo(RankTooLowErr, Rank));
        Assert.IsTrue(Similarity >= Expected.Element('min_similarity').ValueAsDecimal(), StrSubstNo(SimilarityTooLowErr, Similarity));
    end;

    local procedure GetComparedFieldIds(ComparedFields: Text) FieldIds: List of [Integer]
    var
        Field: Record Field;
        ComparedField: Text;
    begin
        foreach ComparedField in ComparedFields.Split(',') do
            case ComparedField.Trim() of
                'TableName':
                    FieldIds.Add(Field.FieldNo(TableName));
                'FieldName':
                    FieldIds.Add(Field.FieldNo(FieldName));
                'Field Caption':
                    FieldIds.Add(Field.FieldNo("Field Caption"));
                else
                    Assert.Fail(StrSubstNo(UnknownComparedFieldErr, ComparedField));
            end;
    end;

    local procedure FindRank(Results: JsonArray; TableName: Text; FieldName: Text; var Rank: Integer; var Similarity: Decimal)
    var
        Result: JsonToken;
        Value: JsonToken;
        i: Integer;
    begin
        for i := 0 to Results.Count() - 1 do begin
            Results.Get(i, Result);
            Result.AsObject().Get('tableName', Value);
            if Value.AsValue().AsText() = TableName then begin
                Result.AsObject().Get('fieldName', Value);
                if Value.AsValue().AsText() = FieldName then begin
                    Rank := i + 1;
                    Similarity := GetSimilarity(Results, i);
                    exit;
                end;
            end;
        end;
    end;

    local procedure GetSimilarity(Results: JsonArray; Index: Integer): Decimal
    var
        Result: JsonToken;
        Value: JsonToken;
    begin
        if Index >= Results.Count() then
            exit(0);

        Results.Get(Index, Result);
        Result.AsObject().Get('similarity', Value);
        exit(Value.AsValue().AsDecimal());
    end;

    local procedure MaxResultsToLog(): Integer
    begin
        exit(50);
    end;
}
