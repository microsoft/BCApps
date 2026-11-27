// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries.Test;

using Microsoft.Foundation.NoSeries;
using System.Reflection;
using System.Search;

codeunit 134520 "Library - No. Series Copilot"
{
    procedure Generate(var NoSeriesGeneration: Record "No. Series Generation"; var NoSeriesGenerationDetail: Record "No. Series Generation Detail"; InputText: Text)
    var 
        NoSeriesCopilotImpl: Codeunit "No. Series Copilot Impl.";
    begin
        NoSeriesCopilotImpl.Generate(NoSeriesGeneration, NoSeriesGenerationDetail, InputText);
    end;

    /// <summary>
    /// Gets whether the keyword matcher of No. Series Copilot treats two texts as relevant to each other.
    /// </summary>
    /// <param name="FirstString">The table and field text of a number series field.</param>
    /// <param name="SecondString">The entity text extracted from the user request.</param>
    /// <returns>True if the keyword nearness reaches the required threshold; otherwise false.</returns>
    procedure IsKeywordMatch(FirstString: Text; SecondString: Text): Boolean
    var
        TextMatchImpl: Codeunit "No. Series Text Match Impl.";
    begin
        exit(TextMatchImpl.IsRelevant(FirstString, SecondString));
    end;

    /// <summary>
    /// Gets the keyword nearness that No. Series Copilot calculates between two texts.
    /// </summary>
    /// <param name="FirstString">The table and field text of a number series field.</param>
    /// <param name="SecondString">The entity text extracted from the user request.</param>
    /// <returns>How much of the shorter text is found in the other one, from 0 to 1.</returns>
    procedure GetKeywordNearness(FirstString: Text; SecondString: Text): Decimal
    var
        TextMatchImpl: Codeunit "No. Series Text Match Impl.";
    begin
        exit(TextMatchImpl.GetNearness(FirstString, SecondString));
    end;

    /// <summary>
    /// Rescales a similarity to 0..1 between fixed bounds, the same way No. Series Copilot search methods do.
    /// </summary>
    procedure CalcNormalizedSimilarity(OriginalSimilarity: Decimal; LowerBound: Decimal; UpperBound: Decimal): Decimal
    var
        TempSearchResult: Record "No. Series Cop. Search Result" temporary;
    begin
        exit(TempSearchResult.CalcNormalizedSimilarity(OriginalSimilarity, LowerBound, UpperBound));
    end;

    /// <summary>
    /// Counts how many of the normalized similarities remain after No. Series Copilot keeps only the best matches of the found fields.
    /// </summary>
    /// <param name="NormalizedSimilarities">The normalized similarities of the found fields.</param>
    /// <param name="MaxDistanceFromBest">How far below the highest normalized similarity a field may be and still be kept.</param>
    /// <returns>The number of kept similarities.</returns>
    procedure CountSimilaritiesNearBest(NormalizedSimilarities: List of [Decimal]; MaxDistanceFromBest: Decimal): Integer
    var
        TempSearchResult: Record "No. Series Cop. Search Result" temporary;
        NormalizedSimilarity: Decimal;
        FieldNo: Integer;
    begin
        foreach NormalizedSimilarity in NormalizedSimilarities do begin
            FieldNo += 1;
            TempSearchResult.AddField(0, FieldNo, Enum::"No. Series Cop. Search Method"::Semantic, NormalizedSimilarity, NormalizedSimilarity);
        end;
        TempSearchResult.KeepBestMatches(MaxDistanceFromBest);
        exit(TempSearchResult.Count());
    end;

    /// <summary>
    /// Runs every No. Series Copilot search method for the entities and returns the union of the found setup fields.
    /// Semantic search needs the Azure OpenAI privacy notice to be accepted.
    /// </summary>
    /// <param name="Entities">The entities extracted from the user request.</param>
    /// <returns>One object per found field with tableName, fieldName, method, originalSimilarity, and normalizedSimilarity (originalSimilarity rescaled to 0..1).</returns>
    procedure SearchRelevantFields(Entities: List of [Text]) Results: JsonArray
    var
        TempSetupNoSeriesField: Record Field temporary;
        TempSearchResult: Record "No. Series Cop. Search Result" temporary;
        ToolsImpl: Codeunit "No. Series Cop. Tools Impl.";
        Result: JsonObject;
    begin
        GetSetupNoSeriesFields(TempSetupNoSeriesField);
        ToolsImpl.SearchRelevantFields(Entities, TempSetupNoSeriesField, TempSearchResult);

        if TempSearchResult.FindSet() then
            repeat
                TempSetupNoSeriesField.Get(TempSearchResult."Table No.", TempSearchResult."Field No.");
                Clear(Result);
                Result.Add('tableName', TempSetupNoSeriesField.TableName);
                Result.Add('fieldName', TempSetupNoSeriesField.FieldName);
                Result.Add('method', Format(TempSearchResult."Search Method"));
                Result.Add('originalSimilarity', TempSearchResult."Original Similarity");
                Result.Add('normalizedSimilarity', TempSearchResult."Normalized Similarity");
                Results.Add(Result);
            until TempSearchResult.Next() = 0;
    end;

    /// <summary>
    /// Ranks the setup number series fields by platform semantic similarity, using the same search target as No. Series Copilot.
    /// Semantic search needs the Azure OpenAI privacy notice to be accepted.
    /// </summary>
    /// <param name="SearchText">The text to compare with the fields.</param>
    /// <param name="FieldIds">The numbers of the Field table fields whose values are compared, for example Field Caption.</param>
    /// <param name="MaxResults">The number of most similar fields to return; must be below 1000.</param>
    /// <returns>One object per field in descending similarity with rank, tableName, fieldName, fieldCaption, and similarity.</returns>
    procedure FindSimilarSetupFields(SearchText: Text; FieldIds: List of [Integer]; MaxResults: Integer) Results: JsonArray
    var
        Field: Record Field;
        TempSetupNoSeriesField: Record Field temporary;
        TempSimilarityResult: Record "Similarity Result" temporary;
        SemanticSearch: Codeunit "Semantic Search";
        SemanticSearchImpl: Codeunit "No. Series Semantic Search";
        SearchTarget: RecordRef;
        Result: JsonObject;
        Rank: Integer;
    begin
        GetSetupNoSeriesFields(TempSetupNoSeriesField);
        SemanticSearchImpl.MarkFieldsToSearchIn(SearchTarget, TempSetupNoSeriesField);
        SemanticSearch.SetMaxResults(MaxResults);
        SemanticSearch.SetSearchTarget(SearchTarget);
        SemanticSearch.FindSimilarByField(SearchText, FieldIds, TempSimilarityResult);

        TempSimilarityResult.SetCurrentKey(Similarity);
        TempSimilarityResult.Ascending(false);
        if TempSimilarityResult.FindSet() then
            repeat
                if Field.GetBySystemId(TempSimilarityResult."System ID") then begin
                    Rank += 1;
                    Clear(Result);
                    Result.Add('rank', Rank);
                    Result.Add('tableName', Field.TableName);
                    Result.Add('fieldName', Field.FieldName);
                    Result.Add('fieldCaption', Field."Field Caption");
                    Result.Add('similarity', TempSimilarityResult.Similarity);
                    Results.Add(Result);
                end;
            until TempSimilarityResult.Next() = 0;
    end;

    /// <summary>
    /// Gets the number of Field records that semantic search compares.
    /// </summary>
    /// <returns>The number of marked records in the search target.</returns>
    procedure GetSemanticSearchTargetCount(): Integer
    var
        TempSetupNoSeriesField: Record Field temporary;
        SemanticSearchImpl: Codeunit "No. Series Semantic Search";
        SearchTarget: RecordRef;
    begin
        GetSetupNoSeriesFields(TempSetupNoSeriesField);
        SemanticSearchImpl.MarkFieldsToSearchIn(SearchTarget, TempSetupNoSeriesField);
        exit(SearchTarget.Count());
    end;

    /// <summary>
    /// Gets the number of number series fields on setup tables that No. Series Copilot can suggest.
    /// </summary>
    /// <returns>The number of number series fields on setup tables.</returns>
    procedure GetSetupNoSeriesFieldCount(): Integer
    var
        TempSetupNoSeriesField: Record Field temporary;
    begin
        GetSetupNoSeriesFields(TempSetupNoSeriesField);
        exit(TempSetupNoSeriesField.Count());
    end;

    local procedure GetSetupNoSeriesFields(var TempSetupNoSeriesField: Record Field temporary)
    var
        TempSetupTable: Record "Table Metadata" temporary;
        ToolsImpl: Codeunit "No. Series Cop. Tools Impl.";
    begin
        ToolsImpl.RetrieveSetupTables(TempSetupTable);
        ToolsImpl.RetrieveNoSeriesFields(TempSetupTable, TempSetupNoSeriesField);
    end;
}
