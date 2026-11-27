// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries.Test;

using System.TestLibraries.Utilities;

codeunit 133690 "No. Series Cop. Search Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [No. Series] [Copilot] [Search]
    end;

    var
        Assert: Codeunit "Library Assert";
        NoSeriesCopilotTestLib: Codeunit "Library - No. Series Copilot";

    [Test]
    procedure KeywordMatchFindsFieldNamedLikeEntity()
    var
        IsMatch: Boolean;
    begin
        // [SCENARIO] An entity that appears in the setup field name is matched by keyword
        // [GIVEN] The text of the customer number series field and the entity "customer"
        // [WHEN] Keyword relevance is evaluated
        IsMatch := NoSeriesCopilotTestLib.IsKeywordMatch('Sales Receivables Setup Customer Nos', 'customer');

        // [THEN] The field is a keyword match
        Assert.IsTrue(IsMatch, 'The entity "customer" must match the customer number series field by keyword.');
    end;

    [Test]
    procedure KeywordMatchMissesSynonym()
    var
        IsMatch: Boolean;
    begin
        // [SCENARIO] An entity with a different word for the same thing is not matched by keyword, so semantic search is needed
        // [GIVEN] The text of the item number series field and the entity "products"
        // [WHEN] Keyword relevance is evaluated
        IsMatch := NoSeriesCopilotTestLib.IsKeywordMatch('Inventory Setup Item Nos', 'products');

        // [THEN] The field is not a keyword match
        Assert.IsFalse(IsMatch, 'The entity "products" must not match the item number series field by keyword.');
    end;

    [Test]
    procedure KeywordNearnessIsFullWhenEntityIsContainedInField()
    var
        Nearness: Decimal;
    begin
        // [SCENARIO] An entity found completely in the setup field text gets the highest keyword nearness
        // [GIVEN] The text of the customer number series field and the entity "customer"
        // [WHEN] Keyword nearness is calculated
        Nearness := NoSeriesCopilotTestLib.GetKeywordNearness('Sales Receivables Setup Customer Nos', 'customer');

        // [THEN] The nearness is 1
        Assert.AreEqual(1, Nearness, 'The entity "customer" is fully contained in the customer number series field text.');
    end;

    [Test]
    procedure KeywordNearnessIsPartialWhenEntityIsMostlyContainedInField()
    var
        Nearness: Decimal;
    begin
        // [SCENARIO] An entity found mostly in the setup field text is a keyword match below the highest nearness
        // [GIVEN] The text of the sales order number series field and the entity "sales orders"
        // [WHEN] Keyword nearness is calculated
        Nearness := NoSeriesCopilotTestLib.GetKeywordNearness('Sales Receivables Setup Order Nos', 'sales orders');

        // [THEN] 11 of 12 characters are matched, which is a keyword match with nearness below 1
        Assert.AreEqual(0.91, Nearness, 'The entity "sales orders" must match 11 of its 12 characters in the sales order number series field text.');
    end;

    [Test]
    procedure CalcNormalizedSimilarityRescalesBetweenBounds()
    begin
        // [SCENARIO] Similarities are rescaled between the bounds of their search method, so keyword and semantic similarities are comparable
        // [GIVEN] The semantic search bounds 0.28 and 0.7
        // [WHEN] Similarities below, at, between, and above the bounds are rescaled
        // [THEN] The lower bound and below become 0, the upper bound and above become 1, and scores between are linear
        Assert.AreEqual(0, NoSeriesCopilotTestLib.CalcNormalizedSimilarity(0.1, 0.28, 0.7), 'A similarity below the lower bound must become 0.');
        Assert.AreEqual(0, NoSeriesCopilotTestLib.CalcNormalizedSimilarity(0.28, 0.28, 0.7), 'A similarity at the lower bound must become 0.');
        Assert.AreEqual(0.5, NoSeriesCopilotTestLib.CalcNormalizedSimilarity(0.49, 0.28, 0.7), 'A similarity halfway between the bounds must become 0.5.');
        Assert.AreEqual(1, NoSeriesCopilotTestLib.CalcNormalizedSimilarity(0.7, 0.28, 0.7), 'A similarity at the upper bound must become 1.');
        Assert.AreEqual(1, NoSeriesCopilotTestLib.CalcNormalizedSimilarity(0.9, 0.28, 0.7), 'A similarity above the upper bound must become 1.');
    end;

    [Test]
    procedure FieldsFarBelowBestSimilarityAreRemoved()
    var
        NormalizedSimilarities: List of [Decimal];
        KeptCount: Integer;
    begin
        // [SCENARIO] Only fields close to the best match of an entity are kept, so weak matches are not suggested next to a clear match
        // [GIVEN] Normalized similarities 1, 0.8, 0.7, 0.69, and 0.2
        NormalizedSimilarities.AddRange(1, 0.8, 0.7, 0.69, 0.2);

        // [WHEN] Fields more than 0.3 below the best similarity are removed
        KeptCount := NoSeriesCopilotTestLib.CountSimilaritiesNearBest(NormalizedSimilarities, 0.3);

        // [THEN] 1, 0.8, and 0.7 are kept
        Assert.AreEqual(3, KeptCount, 'Only the similarities at most 0.3 below the best one must be kept.');
    end;

    [Test]
    procedure EmptyResultStaysEmptyWhenKeepingBestMatches()
    var
        NormalizedSimilarities: List of [Decimal];
        KeptCount: Integer;
    begin
        // [SCENARIO] An entity without any found field stays without fields
        // [GIVEN] No normalized similarities
        // [WHEN] Fields more than 0.3 below the best similarity are removed
        KeptCount := NoSeriesCopilotTestLib.CountSimilaritiesNearBest(NormalizedSimilarities, 0.3);

        // [THEN] No field is kept
        Assert.AreEqual(0, KeptCount, 'An empty search result must stay empty.');
    end;

    [Test]
    procedure SemanticSearchTargetHoldsOnlySetupNoSeriesFields()
    var
        SetupNoSeriesFieldCount: Integer;
        SearchTargetCount: Integer;
    begin
        // [SCENARIO] Semantic search compares only the number series fields on setup tables, so every result can be suggested
        // [GIVEN] The number series fields on setup tables
        SetupNoSeriesFieldCount := NoSeriesCopilotTestLib.GetSetupNoSeriesFieldCount();
        Assert.AreNotEqual(0, SetupNoSeriesFieldCount, 'The test company must have setup tables with number series fields.');

        // [WHEN] The fields to search in are marked on the semantic search target
        SearchTargetCount := NoSeriesCopilotTestLib.GetSemanticSearchTargetCount();

        // [THEN] The search target holds exactly the number series fields on setup tables
        Assert.AreEqual(SetupNoSeriesFieldCount, SearchTargetCount, 'The semantic search target must hold exactly the number series fields on setup tables.');
    end;
}
