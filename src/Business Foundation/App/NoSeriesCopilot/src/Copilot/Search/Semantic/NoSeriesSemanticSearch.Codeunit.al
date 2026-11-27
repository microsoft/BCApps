// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

using System.Reflection;
using System.Search;

codeunit 348 "No. Series Semantic Search" implements "No. Series Cop. Field Search"
{
    Access = Internal;
    InherentPermissions = X;
    InherentEntitlements = X;

    procedure Search(Entities: List of [Text]; var TempFieldToSearchIn: Record "Field" temporary; var TempSearchResult: Record "No. Series Cop. Search Result" temporary)
    var
        SearchTarget: RecordRef;
        Entity: Text;
    begin
        if TempFieldToSearchIn.IsEmpty() then
            exit;

        MarkFieldsToSearchIn(SearchTarget, TempFieldToSearchIn);
        foreach Entity in Entities do
            if Entity.Trim() <> '' then
                SearchEntity(Entity.Trim(), SearchTarget, TempSearchResult);
    end;

    local procedure SearchEntity(Entity: Text; var SearchTarget: RecordRef; var TempSearchResult: Record "No. Series Cop. Search Result" temporary)
    var
        Field: Record "Field";
        CaptionFieldIds: List of [Integer];
        QualifiedFieldIds: List of [Integer];
    begin
        // Captions alone match master data synonyms best, while captions such as "Order Nos." repeat across setup tables
        // and only the table name tells sales documents from purchase documents.
        CaptionFieldIds.Add(Field.FieldNo("Field Caption"));
        FindSimilarFields(Entity, CaptionFieldIds, SearchTarget, TempSearchResult);

        QualifiedFieldIds.Add(Field.FieldNo(TableName));
        QualifiedFieldIds.Add(Field.FieldNo(FieldName));
        QualifiedFieldIds.Add(Field.FieldNo("Field Caption"));
        FindSimilarFields(Entity, QualifiedFieldIds, SearchTarget, TempSearchResult);
    end;

    local procedure FindSimilarFields(Entity: Text; FieldIds: List of [Integer]; var SearchTarget: RecordRef; var TempSearchResult: Record "No. Series Cop. Search Result" temporary)
    var
        TempSimilarityResult: Record "Similarity Result" temporary;
    begin
        RunSemanticSearch(Entity, FieldIds, SearchTarget, TempSimilarityResult);
        KeepRelevantResults(TempSimilarityResult, TempSearchResult);
    end;

    local procedure RunSemanticSearch(Entity: Text; FieldIds: List of [Integer]; var SearchTarget: RecordRef; var TempSimilarityResult: Record "Similarity Result" temporary)
    var
        SemanticSearch: Codeunit "Semantic Search";
    begin
        SemanticSearch.SetMaxResults(MaxMatchesPerSearch());
        SemanticSearch.SetSearchTarget(SearchTarget);
        SemanticSearch.FindSimilarByField(Entity, FieldIds, TempSimilarityResult);
    end;

    local procedure KeepRelevantResults(var TempSimilarityResult: Record "Similarity Result" temporary; var TempSearchResult: Record "No. Series Cop. Search Result" temporary)
    begin
        TempSimilarityResult.SetFilter(Similarity, '>=%1', RequiredSimilarity());
        if TempSimilarityResult.FindSet() then
            repeat
                AddSimilarField(TempSimilarityResult, TempSearchResult);
            until TempSimilarityResult.Next() = 0;
    end;

    local procedure AddSimilarField(var TempSimilarityResult: Record "Similarity Result" temporary; var TempSearchResult: Record "No. Series Cop. Search Result" temporary)
    var
        Field: Record "Field";
    begin
        if not Field.GetBySystemId(TempSimilarityResult."System ID") then
            exit;

        TempSearchResult.AddField(
            Field.TableNo, Field."No.", Enum::"No. Series Cop. Search Method"::Semantic,
            TempSimilarityResult.Similarity, TempSearchResult.CalcNormalizedSimilarity(TempSimilarityResult.Similarity, RequiredSimilarity(), StrongSimilarity()));
    end;

    /// <summary>
    /// Opens the system Field table and marks the same fields as TempFieldToSearchIn, with only the marked fields in view.
    /// Semantic search cannot search a temporary table, so the platform searches the marked Field records instead.
    /// </summary>
    /// <param name="SearchTarget">The system Field table with the fields to search in marked; used as the semantic search target.</param>
    /// <param name="TempFieldToSearchIn">The fields to search in.</param>
    procedure MarkFieldsToSearchIn(var SearchTarget: RecordRef; var TempFieldToSearchIn: Record "Field" temporary)
    begin
        SearchTarget.Open(Database::"Field");
        if TempFieldToSearchIn.FindSet() then
            repeat
                MarkField(SearchTarget, TempFieldToSearchIn);
            until TempFieldToSearchIn.Next() = 0;
        SearchTarget.MarkedOnly(true);
    end;

    local procedure MarkField(var SearchTarget: RecordRef; var TempFieldToSearchIn: Record "Field" temporary)
    var
        Field: Record "Field";
    begin
        if not Field.Get(TempFieldToSearchIn.TableNo, TempFieldToSearchIn."No.") then
            exit;

        SearchTarget.GetBySystemId(Field.SystemId);
        SearchTarget.Mark(true);
    end;

    local procedure RequiredSimilarity(): Decimal
    begin
        exit(0.28);
    end;

    local procedure StrongSimilarity(): Decimal
    begin
        exit(0.7);
    end;

    local procedure MaxMatchesPerSearch(): Integer
    begin
        exit(5);
    end;
}
