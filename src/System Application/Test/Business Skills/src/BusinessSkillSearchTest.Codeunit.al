// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Test.AI.BusinessSkills;

using System.AI.BusinessSkills;
using System.Search;
using System.TestLibraries.AI.BusinessSkills;
using System.TestLibraries.Utilities;

/// <summary>
/// Verifies direct virtual-table search, current-identity result mapping, and safe request validation without model execution.
/// </summary>
codeunit 130052 "Business Skill Search Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;
    RequiredTestIsolation = Codeunit;

    /// <summary>
    /// Search uses the virtual table's title and description fields, never instruction content.
    /// </summary>
    [Test]
    procedure SemanticSearchSelectsExactlyTitleAndDescription()
    var
        Skill: Record "Business Skill";
        FieldIds: List of [Integer];
    begin
        // [GIVEN] The canonical virtual skill table.
        // [WHEN] Selecting the fields passed to native semantic search.
        FieldIds := SearchImpl.SearchFieldIds();

        // [THEN] Searchable metadata uses real table field numbers and excludes instructions.
        Assert.AreEqual(2, FieldIds.Count(), 'Search only title and description.');
        Assert.AreEqual(Skill.FieldNo(Title), FieldIds.Get(1), 'Use the canonical title field.');
        Assert.AreEqual(Skill.FieldNo(Description), FieldIds.Get(2), 'Use the canonical description field.');
    end;

    /// <summary>
    /// Empty and inactive-only catalogs return an empty response without invoking native search.
    /// </summary>
    [Test]
    procedure EmptyAndInactiveCatalogsAvoidNativeSearch()
    var
        Skill: Record "Business Skill";
        Response: JsonObject;
    begin
        // [GIVEN] An empty catalog.
        Initialize();

        // [WHEN] Searching before and after creating an inactive skill.
        Response.ReadFrom(Search.Search('valid query', 5));
        AssertEnvelope(Response, 5, 0);
        Skill.Get(LibraryBusinessSkill.CreateSkill('Inactive', SecretStrSubstNo('Private instructions')));
        Management.DeactivateSkill(Skill.ID);
        Response.ReadFrom(Search.Search('valid query', 5));

        // [THEN] Inactive records do not enter semantic ranking.
        AssertEnvelope(Response, 5, 0);
    end;

    /// <summary>
    /// The existing AL candidate bound is enforced before privacy approval or model execution.
    /// </summary>
    [Test]
    procedure CapacityRejects1001BeforeNativeSearch()
    var
        Skill: Record "Business Skill";
        Index: Integer;
    begin
        // [GIVEN] More than 1000 active skills.
        Initialize();
        for Index := 1 to 1001 do
            CreateActiveSkill(Skill, 'Instructions');
        Commit();

        // [WHEN] Requesting a semantic search.
        asserterror Search.Search('valid query', 1);

        // [THEN] The request fails explicitly rather than silently truncating the candidate set.
        Assert.ExpectedError('The search includes more than 1000 available skills.');
    end;

    /// <summary>
    /// Native system identities, negative scores and rank order survive mapping and the requested top limit.
    /// </summary>
    [Test]
    procedure ResponsePreservesNativeScoresAndTopK()
    var
        FirstSkill: Record "Business Skill";
        SecondSkill: Record "Business Skill";
        TempResult: Record "Similarity Result" temporary;
        Response: JsonObject;
        Hits: JsonArray;
    begin
        // [GIVEN] Native results referencing real system identities with negative scores.
        Initialize();
        CreateActiveSkill(FirstSkill, PadStr('x', 5000, 'x'));
        CreateActiveSkill(SecondSkill, 'Second body');
        AddResult(TempResult, 1, FirstSkill.SystemId, -0.1);
        AddResult(TempResult, 2, SecondSkill.SystemId, -0.3);

        // [WHEN] Mapping the ranking at two requested limits.
        Response := SearchImpl.ToResponse(TempResult, 2);
        AssertEnvelope(Response, 2, 2);
        Hits := GetValue(Response, 'hits').AsArray();
        AssertHit(GetHit(Hits, 0), FirstSkill, 1, -0.1);
        AssertHit(GetHit(Hits, 1), SecondSkill, 2, -0.3);
        Response := SearchImpl.ToResponse(TempResult, 1);

        // [THEN] Only the highest ranked hit is returned for top one, without altering its score.
        AssertEnvelope(Response, 1, 1);
        AssertHit(GetHit(GetValue(Response, 'hits').AsArray(), 0), FirstSkill, 1, -0.1);
    end;

    /// <summary>
    /// Deleted, unknown and inactive result identities are omitted; remaining ranks are contiguous.
    /// </summary>
    [Test]
    procedure ResponseSkipsDeletedAndInactiveSkills()
    var
        DeletedSkill: Record "Business Skill";
        InactiveSkill: Record "Business Skill";
        ActiveSkill: Record "Business Skill";
        TempResult: Record "Similarity Result" temporary;
        Response: JsonObject;
    begin
        // [GIVEN] Ranked identities whose eligibility changes after native retrieval.
        Initialize();
        CreateActiveSkill(DeletedSkill, 'Deleted body');
        CreateActiveSkill(InactiveSkill, 'Inactive body');
        CreateActiveSkill(ActiveSkill, 'Active body');
        AddResult(TempResult, 1, DeletedSkill.SystemId, 0.9);
        AddResult(TempResult, 2, InactiveSkill.SystemId, 0.8);
        AddResult(TempResult, 3, CreateGuid(), 0.7);
        AddResult(TempResult, 4, ActiveSkill.SystemId, 0.6);
        Management.DeactivateSkill(DeletedSkill.ID);
        Management.DeleteSkill(DeletedSkill.ID);
        Management.DeactivateSkill(InactiveSkill.ID);

        // [WHEN] Resolving native system IDs against current records.
        Response := SearchImpl.ToResponse(TempResult, 4);

        // [THEN] Only current active content is represented; there is no catalog-snapshot failure.
        AssertEnvelope(Response, 4, 1);
        AssertHit(GetHit(GetValue(Response, 'hits').AsArray(), 0), ActiveSkill, 1, 0.6);
    end;

    /// <summary>
    /// Metadata changes are returned without snapshot rejection, content exposure, or writes during result mapping.
    /// </summary>
    [Test]
    procedure ResponseUsesCurrentMetadataWithoutMutatingSource()
    var
        Skill: Record "Business Skill";
        CurrentSkill: Record "Business Skill";
        TempResult: Record "Similarity Result" temporary;
        Response: JsonObject;
        Body: Text;
    begin
        // [GIVEN] A ranked skill whose metadata changes while its complete Unicode body remains unchanged.
        Initialize();
        Body := UnicodeBody();
        CreateActiveSkill(Skill, Body);
        AddResult(TempResult, 1, Skill.SystemId, 0.5);
        Skill.Title := 'Updated title';
        Skill.Description := 'Updated searchable description';
        Management.UpdateSkillRecord(Skill.ID, Skill, Body);
        Skill.Get(Skill.ID);

        // [WHEN] Mapping the result after the metadata edit.
        Response := SearchImpl.ToResponse(TempResult, 1);

        // [THEN] Current metadata and revision are returned without mutating the source or returning its body.
        AssertEnvelope(Response, 1, 1);
        AssertHit(GetHit(GetValue(Response, 'hits').AsArray(), 0), Skill, 1, 0.5);
        CurrentSkill.Get(Skill.ID);
        Assert.AreEqual(Skill.SystemRowVersion, CurrentSkill.SystemRowVersion, 'Mapping must not update the source.');
        Assert.IsTrue(SkillText.ContentEquals(Body, SkillText.GetSkillText(CurrentSkill)), 'Preserve the complete Unicode body.');
    end;

    /// <summary>
    /// Duplicate identities, unordered scores and gaps in native ranking fail explicitly.
    /// </summary>
    [Test]
    procedure ResponseRejectsMalformedRanking()
    var
        FirstSkill: Record "Business Skill";
        SecondSkill: Record "Business Skill";
        TempResult: Record "Similarity Result" temporary;
    begin
        // [GIVEN] Two distinct ranked skills.
        Initialize();
        CreateActiveSkill(FirstSkill, 'First body');
        CreateActiveSkill(SecondSkill, 'Second body');
        Commit();
        AddResult(TempResult, 1, FirstSkill.SystemId, 0.5);
        AddResult(TempResult, 2, FirstSkill.SystemId, 0.4);

        // [WHEN] Native ranking repeats an identity, reverses scores or skips a rank.
        // [THEN] Mapping rejects each malformed result instead of returning partial hits.
        asserterror SearchImpl.ToResponse(TempResult, 1);
        Assert.ExpectedError('invalid ranked results');
        TempResult.Get(2);
        TempResult."System ID" := SecondSkill.SystemId;
        TempResult.Similarity := 0.9;
        TempResult.Modify();
        asserterror SearchImpl.ToResponse(TempResult, 2);
        Assert.ExpectedError('invalid ranked results');
        TempResult.Get(2);
        TempResult.Similarity := 0.4;
        TempResult.Modify();
        TempResult.Rename(3);
        asserterror SearchImpl.ToResponse(TempResult, 2);
        Assert.ExpectedError('invalid ranked results');
    end;

    /// <summary>
    /// Every Search call validates missing queries and top bounds before native retrieval.
    /// </summary>
    [Test]
    procedure SearchValidatesRequestsBeforeNative()
    var
        Response: JsonObject;
    begin
        // [GIVEN] An empty catalog with valid and invalid request inputs.
        Initialize();
        Commit();

        // [WHEN] Searching with supported boundaries, then invalid queries and limits.
        Response.ReadFrom(Search.Search(' valid ', 1));
        AssertEnvelope(Response, 1, 0);
        Response.ReadFrom(Search.Search(PadStr('x', 20000, 'x'), 50));
        AssertEnvelope(Response, 50, 0);

        // [THEN] Only valid requests return responses.
        asserterror Search.Search('', 1);
        Assert.ExpectedError('Enter a search query.');
        asserterror Search.Search('   ', 1);
        Assert.ExpectedError('Enter a search query.');
        asserterror Search.Search('valid', 0);
        Assert.ExpectedError('The result limit must be at least 1.');
        asserterror Search.Search('valid', 51);
        Assert.ExpectedError('The result limit cannot exceed 50.');
    end;

    local procedure Initialize()
    begin
        LibraryBusinessSkill.CleanAll();
    end;

    local procedure CreateActiveSkill(var Skill: Record "Business Skill"; Body: Text)
    begin
        Skill.Get(LibraryBusinessSkill.CreateSkill('Search fixture', Body));
        Management.ActivateSkill(Skill.ID);
        Skill.Get(Skill.ID);
    end;

    local procedure UnicodeBody(): Text
    var
        Builder: TextBuilder;
        LineBreak: Text;
        Block: Text;
        Index: Integer;
    begin
        Builder.AppendLine('');
        LineBreak := Builder.ToText();
        Clear(Builder);
        Block := LineBreak + 'æøå Ω 漢字 € 🙂 <&"' + LineBreak + LineBreak + 'Trailing spaces  ';
        for Index := 1 to 2000 do
            Builder.Append(Block);
        exit(PadStr(Builder.ToText(), 99998, 'x') + '  ');
    end;

    local procedure AddResult(var TempResult: Record "Similarity Result" temporary; Number: Integer; SystemId: Guid; Score: Decimal)
    begin
        TempResult.Init();
        TempResult."No." := Number;
        TempResult."System ID" := SystemId;
        TempResult.Similarity := Score;
        TempResult.Insert();
    end;

    local procedure GetValue(Value: JsonObject; Name: Text): JsonToken
    var
        Token: JsonToken;
    begin
        Assert.IsTrue(Value.Get(Name, Token), 'Required JSON property is missing: ' + Name);
        exit(Token);
    end;

    local procedure GetHit(Hits: JsonArray; Index: Integer): JsonObject
    var
        Token: JsonToken;
    begin
        Assert.IsTrue(Hits.Get(Index, Token), 'Expected a ranked hit.');
        exit(Token.AsObject());
    end;

    local procedure AssertEnvelope(Response: JsonObject; Top: Integer; Count: Integer)
    begin
        Assert.AreEqual(2, GetValue(Response, 'schemaVersion').AsValue().AsInteger(), 'Use schema version 2.');
        Assert.AreEqual('bc.semantic.similarity', GetValue(Response, 'scoreKind').AsValue().AsText(), 'Scores are native similarity.');
        Assert.IsTrue(GetValue(Response, 'higherIsBetter').AsValue().AsBoolean(), 'Higher scores rank first.');
        Assert.AreEqual('semantic', GetValue(Response, 'retrievalMode').AsValue().AsText(), 'No silent lexical fallback.');
        Assert.IsTrue(GetValue(Response, 'scoresAvailable').AsValue().AsBoolean(), 'Semantic responses expose scores.');
        Assert.IsFalse(GetValue(Response, 'resultsTruncated').AsValue().AsBoolean(), 'A successful search is not truncated.');
        Assert.AreEqual(Top, GetValue(Response, 'requestedTop').AsValue().AsInteger(), 'Echo the requested limit.');
        Assert.AreEqual(Count, GetValue(Response, 'returnedCount').AsValue().AsInteger(), 'Report returned eligible hits.');
        Assert.AreEqual(Count, GetValue(Response, 'hits').AsArray().Count(), 'The count must match the hit array.');
    end;

    local procedure AssertHit(Hit: JsonObject; Skill: Record "Business Skill"; Rank: Integer; Score: Decimal)
    var
        SystemId: Guid;
        Token: JsonToken;
    begin
        Assert.AreEqual(Skill.ID, GetValue(Hit, 'id').AsValue().AsBigInteger(), 'Return the canonical numeric ID.');
        Evaluate(SystemId, GetValue(Hit, 'systemId').AsValue().AsText());
        Assert.AreEqual(Skill.SystemId, SystemId, 'Return the real system identity.');
        Assert.AreEqual(Format(Skill.SystemRowVersion, 0, 9), GetValue(Hit, 'revision').AsValue().AsText(), 'Return the current revision.');
        Assert.AreEqual(Rank, GetValue(Hit, 'rank').AsValue().AsInteger(), 'Returned ranks must be contiguous.');
        Assert.AreEqual(Score, GetValue(Hit, 'score').AsValue().AsDecimal(), 'Preserve the native score.');
        Assert.AreEqual(Skill.Title, GetValue(Hit, 'title').AsValue().AsText(), 'Use the current title.');
        Assert.AreEqual(Skill.Description, GetValue(Hit, 'description').AsValue().AsText(), 'Use the current description.');
        Assert.IsFalse(Hit.Get('skillText', Token), 'Ranking must not expose instruction content.');
        Assert.IsFalse(Hit.Get('matchExcerpt', Token), 'Metadata search must not invent body excerpts.');
    end;

    var
        Assert: Codeunit "Library Assert";
        LibraryBusinessSkill: Codeunit "Library - Business Skill";
        Management: Codeunit "Business Skill Management";
        Search: Codeunit "Business Skill Search";
        SearchImpl: Codeunit "Business Skill Search Impl.";
        SkillText: Codeunit "Business Skill Text";
}
