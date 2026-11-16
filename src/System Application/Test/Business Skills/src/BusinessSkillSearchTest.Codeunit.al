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
/// Deterministic candidate projection, synthetic ranking, eligibility, and freshness contracts.
/// Covers semantic response validation, score preservation, and safe error reasons.
/// Empty-catalog requests avoid native/model execution.
/// </summary>
codeunit 130052 "Business Skill Search Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;
    RequiredTestIsolation = Codeunit;

    var
        Assert: Codeunit "Library Assert";
        LibraryBusinessSkill: Codeunit "Library - Business Skill";
        Management: Codeunit "Business Skill Management";
        Projection: Codeunit "Business Skill Search Proj.";
        SkillText: Codeunit "Business Skill Text";
        QueryRequiredErr: Label 'Enter a search query.', Locked = true;
        TopTooSmallErr: Label 'The result limit must be at least 1.', Locked = true;
        TopTooLargeErr: Label 'The result limit cannot exceed 50.', Locked = true;
        CapacityErr: Label 'The search includes more than 1000 available skills. Reduce the number of active skills and try again.', Locked = true;
        IncompleteResultsErr: Label 'The semantic search result does not cover the authorized candidate set. Search is unavailable.', Locked = true;
        ChangedErr: Label 'The skill catalog changed during search.', Locked = true;

    /// <summary>
    /// Verifies full Unicode instruction text survives metadata edits while searchable metadata refreshes and candidate identity stays stable.
    /// </summary>
    [Test]
    procedure MetadataProjectionPreservesFullBodyAndStableIdentity()
    var
        Skill: Record "Business Skill";
        TempCandidate: Record "Business Skill Search Buffer" temporary;
        TempAgain: Record "Business Skill Search Buffer" temporary;
        TextHelper: Codeunit "Business Skill Text";
        Body: Text;
        Snapshot: Text;
    begin
        // [GIVEN] An active skill with a full-length Unicode body and searchable metadata.
        Initialize();
        Body := UnicodeBody();
        CreateActiveSkill(Skill, Body);
        Skill.Description := CopyStr(PadStr('Searchable Unicode æøå Ω 漢字 € 🙂', 2048, 'x'), 1, 2048);
        Management.UpdateSkillRecord(Skill.ID, Skill, Body);
        Skill.Get(Skill.ID);
        CommitFixture();
        Assert.IsTrue(TextHelper.GetEncoding() = TextEncoding::UTF8, 'Persisted text must use UTF-8.');
        Assert.AreEqual(100000, StrLen(Body), 'Exercise the full supported body length.');
        Assert.AreEqual(Body, SkillText.GetSkillText(Skill), 'Persist the entire Unicode body.');
        // [WHEN] Candidates are projected before and after skill metadata updates.
        Projection.Build(TempCandidate, Snapshot);
        // [THEN] The body and stable identities remain intact while metadata refreshes.
        AssertCandidateMetadata(TempCandidate, Skill);
        Projection.Build(TempAgain, Snapshot);
        AssertStableCandidates(TempCandidate, TempAgain);

        Management.UpdateSkill(Skill.ID, 'Changed metadata only', Body);
        Skill.Get(Skill.ID);
        Skill.Description := 'Changed skill description';
        Management.UpdateSkillRecord(Skill.ID, Skill, Body);
        Skill.Get(Skill.ID);
        CommitFixture();
        Projection.Build(TempAgain, Snapshot);
        AssertStableCandidates(TempCandidate, TempAgain);
        AssertCandidateMetadata(TempAgain, Skill);
        TempAgain.FindFirst();
        Assert.AreEqual('Changed metadata only', TempAgain.Title, 'Stable IDs do not freeze titles.');
        Assert.AreEqual('Changed skill description', TempAgain.Description, 'Refresh the persisted skill description, without deriving instructions.');
        Assert.AreEqual(Body, SkillText.GetSkillText(Skill), 'Metadata edits preserve all 100000 instruction characters.');
    end;

    /// <summary>
    /// Verifies semantic retrieval searches only title and description fields in a temporary candidate buffer.
    /// </summary>
    [Test]
    procedure SemanticSearchSelectsExactlyTitleAndDescription()
    var
        TempCandidate: Record "Business Skill Search Buffer";
        Search: Codeunit "Business Skill Search";
        FieldIds: List of [Integer];
    begin
        // [GIVEN] The search buffer's available metadata fields.
        // [WHEN] The semantic search field list is requested.
        FieldIds := Search.SearchFieldIds();
        // [THEN] Only title and description are searchable, in that order.
        Assert.AreEqual(2, FieldIds.Count(), 'No body, identity or snapshot fields may participate.');
        Assert.AreEqual(TempCandidate.FieldNo(Title), FieldIds.Get(1), 'Title is the first searchable field.');
        Assert.AreEqual(TempCandidate.FieldNo(Description), FieldIds.Get(2), 'Description is the only other searchable field.');
        Assert.IsTrue(TempCandidate.IsTemporary(), 'Candidate metadata remains request-local.');
    end;

    /// <summary>
    /// Verifies projections accept exactly 1000 eligible skills, reject larger cohorts without partial results, and succeed after deactivation.
    /// </summary>
    [Test]
    procedure CapacityAccepts1000AndRejects1001()
    var
        Skill: Record "Business Skill";
        TempCandidate: Record "Business Skill Search Buffer" temporary;
        Response: JsonObject;
        Index: Integer;
        Snapshot: Text;
    begin
        // [GIVEN] A catalog at and then beyond the 1000-candidate limit.
        Initialize();
        Assert.AreEqual(1000, Projection.MaximumCandidates(), 'Capacity is an explicit contract.');
        for Index := 1 to 1000 do
            CreateActiveSkill(Skill, 'One body');
        CommitFixture();
        // [WHEN] The eligible catalog is projected.
        Projection.Build(TempCandidate, Snapshot);
        // [THEN] The limit is enforced without partial results; deactivation reduces the eligible cohort.
        Assert.AreEqual(1000, TempCandidate.Count(), 'Accept the exact candidate capacity.');
        CreateActiveSkill(Skill, 'Beyond capacity');
        CommitFixture();
        asserterror Projection.AppendSkill(Skill, '', TempCandidate);
        Assert.ExpectedError(CapacityErr);
        Assert.AreEqual(1000, TempCandidate.Count(), 'Do not append beyond the cap.');
        Response.Add('notReturned', true);
        asserterror Response := BuildResponseWithoutNative();
        Assert.ExpectedError(CapacityErr);
        AssertNoReturnedHits(Response);
        asserterror Projection.Build(TempCandidate, Snapshot);
        Assert.ExpectedError(CapacityErr);
        Assert.IsTrue(TempCandidate.IsEmpty(), 'Reject the initial cohort before building any candidates.');
        Assert.AreEqual('', Snapshot, 'A rejected search has no completed snapshot.');
        Management.DeactivateSkill(Skill.ID);
        CommitFixture();
        Projection.Build(TempCandidate, Snapshot);
        Assert.AreEqual(1000, TempCandidate.Count(), 'Inactive skills do not consume search capacity.');
    end;

    /// <summary>
    /// Verifies maximum-length instruction bodies still use one search candidate each and are not copied into descriptions.
    /// </summary>
    [Test]
    procedure LongBodiesDoNotConsumeAdditionalCandidateCapacity()
    var
        Skill: Record "Business Skill";
        TempCandidate: Record "Business Skill Search Buffer" temporary;
        Snapshot: Text;
        Index: Integer;
    begin
        // [GIVEN] Active skills with maximum-length instruction bodies.
        Initialize();
        for Index := 1 to 18 do
            CreateActiveSkill(Skill, PadStr('x', 100000, 'x'));
        CommitFixture();
        // [WHEN] Search candidates are projected.
        Projection.Build(TempCandidate, Snapshot);
        // [THEN] Each skill uses one slot and its body does not become a description.
        Assert.AreEqual(18, TempCandidate.Count(), 'Long bodies must not expand into segments or consume additional capacity.');
        TempCandidate.FindFirst();
        Assert.AreEqual('', TempCandidate.Description, 'Existing skills stay title-only; never derive or truncate the body.');
    end;

    /// <summary>
    /// Verifies projections include every active skill and exclude inactive skills.
    /// </summary>
    [Test]
    procedure BuildUsesActiveSkillsOnly()
    var
        FirstSkill: Record "Business Skill";
        SecondSkill: Record "Business Skill";
        TempCandidate: Record "Business Skill Search Buffer" temporary;
        ExcludedIds: List of [BigInteger];
        SkillId: BigInteger;
        Snapshot: Text;
    begin
        // [GIVEN] Active and inactive skills.
        Initialize();
        CreateEligibilityFixture(FirstSkill, SecondSkill, ExcludedIds);
        CommitFixture();
        // [WHEN] Candidates are built.
        Projection.Build(TempCandidate, Snapshot);
        // [THEN] Only the active skills appear.
        Assert.AreEqual(2, TempCandidate.Count(), 'Every active skill qualifies.');
        AssertCandidatePresent(TempCandidate, FirstSkill.ID);
        AssertCandidatePresent(TempCandidate, SecondSkill.ID);
        foreach SkillId in ExcludedIds do begin
            TempCandidate.SetRange("Skill ID", SkillId);
            Assert.IsTrue(TempCandidate.IsEmpty(), 'Inactive skills are excluded.');
        end;
        TempCandidate.Reset();
    end;

    /// <summary>
    /// Verifies response projection preserves negative native scores and rank order while limiting returned hits to top K.
    /// </summary>
    [Test]
    procedure ResponsePreservesNegativeScoresAndDistinctTopK()
    var
        LongSkill: Record "Business Skill";
        ShortSkill: Record "Business Skill";
        TempCandidate: Record "Business Skill Search Buffer" temporary;
        TempResult: Record "Similarity Result" temporary;
        Response: JsonObject;
        Hit: JsonObject;
        Hits: JsonArray;
        Snapshot: Text;
    begin
        // [GIVEN] Search candidates with negative similarity scores.
        Initialize();
        CreateActiveSkill(LongSkill, PadStr('x', 5000, 'x'));
        CreateActiveSkill(ShortSkill, 'Other parent');
        CommitFixture();
        Projection.Build(TempCandidate, Snapshot);
        Assert.AreEqual(2, TempCandidate.Count(), 'Each skill has one candidate regardless of body length.');
        AddResult(TempResult, 1, GetCandidateId(TempCandidate, LongSkill.ID), -0.1);
        AddResult(TempResult, 2, GetCandidateId(TempCandidate, ShortSkill.ID), -0.3);
        // [WHEN] A bounded response is projected from native results.
        Response := Projection.ToResponse(TempCandidate, TempResult, 2, Snapshot);
        // [THEN] Scores, result order, distinct identities, and response metadata are preserved.
        AssertEnvelope(Response, 2, 2);
        Hits := GetValue(Response, 'hits').AsArray();
        Hit := GetHit(Hits, 0);
        AssertHitIdentity(Hit, LongSkill, 1, -0.1);
        Assert.IsFalse(Hit.Contains('matchedSegment'), 'Metadata ranking has no artificial segment.');
        Assert.IsFalse(Hit.Contains('matchExcerpt'), 'Do not present a body excerpt as search evidence.');
        Assert.AreEqual('', GetValue(Hit, 'description').AsValue().AsText(), 'A missing description remains optional.');
        AssertHitIdentity(GetHit(Hits, 1), ShortSkill, 2, -0.3);
        Response := Projection.ToResponse(TempCandidate, TempResult, 1, Snapshot);
        AssertEnvelope(Response, 1, 1);
        AssertHitIdentity(GetHit(GetValue(Response, 'hits').AsArray(), 0), LongSkill, 1, -0.1);
    end;

    /// <summary>
    /// Verifies changing a skill's title or body after projection rejects its stale response.
    /// </summary>
    [Test]
    procedure ResponseRejectsChangedSkillRevision()
    var
        Skill: Record "Business Skill";
        TempCandidate: Record "Business Skill Search Buffer" temporary;
        TempResult: Record "Similarity Result" temporary;
        Snapshot: Text;
    begin
        // [GIVEN] A completed search snapshot for a skill.
        InitializeSingleResult(Skill, TempCandidate, TempResult, Snapshot);
        // [WHEN] That skill's title and body change before response projection.
        Management.UpdateSkill(Skill.ID, 'New title', 'New body');
        CommitFixture();
        // [THEN] The stale response is rejected.
        AssertRejectedResponse(TempCandidate, TempResult, ChangedErr, Snapshot);
    end;

    /// <summary>
    /// Verifies description edits invalidate old results while rebuilding preserves current metadata and the full unchanged body.
    /// </summary>
    [Test]
    procedure DescriptionChangeInvalidatesSearch()
    var
        Skill: Record "Business Skill";
        TempCandidate: Record "Business Skill Search Buffer" temporary;
        TempResult: Record "Similarity Result" temporary;
        Snapshot: Text;
        Body: Text;
    begin
        // [GIVEN] A projected skill whose searchable description changes.
        InitializeSingleResult(Skill, TempCandidate, TempResult, Snapshot);
        Body := SkillText.GetSkillText(Skill);
        Skill.Description := 'New searchable description';
        // [WHEN] The old result is returned.
        Management.UpdateSkillRecord(Skill.ID, Skill, Body);
        CommitFixture();
        // [THEN] The old snapshot fails and a fresh projection exposes updated metadata.
        AssertRejectedResponse(TempCandidate, TempResult, ChangedErr, Snapshot);
        Projection.Build(TempCandidate, Snapshot);
        Skill.Get(Skill.ID);
        AssertCandidateMetadata(TempCandidate, Skill);
    end;

    /// <summary>
    /// Verifies an empty snapshot is rejected when its inactive skill is reactivated.
    /// </summary>
    [Test]
    procedure EmptyProjectionRejectsReactivatedSkill()
    var
        Skill: Record "Business Skill";
        TempCandidate: Record "Business Skill Search Buffer" temporary;
        TempResult: Record "Similarity Result" temporary;
        Snapshot: Text;
    begin
        // [GIVEN] An empty projection of an inactive skill.
        Initialize();
        Skill.Get(LibraryBusinessSkill.CreateSkill('Initially inactive', 'Not discoverable yet'));
        Management.DeactivateSkill(Skill.ID);
        CommitFixture();
        Projection.Build(TempCandidate, Snapshot);
        Assert.IsTrue(TempCandidate.IsEmpty(), 'Inactive skills are not candidates.');
        // [WHEN] The member is activated.
        LibraryBusinessSkill.ActivateSkill(Skill.ID);
        CommitFixture();
        // [THEN] The old empty snapshot is rejected.
        AssertRejectedResponse(TempCandidate, TempResult, ChangedErr, Snapshot);
    end;

    /// <summary>
    /// Verifies even empty projections require the exact catalog snapshot used to build them.
    /// </summary>
    [Test]
    procedure EmptySnapshotRequiresExplicitCatalogIdentity()
    var
        TempCandidate: Record "Business Skill Search Buffer" temporary;
        TempResult: Record "Similarity Result" temporary;
        Response: JsonObject;
        Snapshot: Text;
    begin
        // [GIVEN] An empty catalog projection.
        Initialize();
        CommitFixture();
        Projection.Build(TempCandidate, Snapshot);
        Assert.AreEqual(64, StrLen(Snapshot), 'Even an empty projection must return its complete context snapshot.');
        Assert.IsTrue(TempCandidate.IsEmpty(), 'Snapshot transport must not add fake searchable candidates.');
        // [WHEN] Responses use valid, missing, mismatched, or fabricated snapshots.
        Response := Projection.ToResponse(TempCandidate, TempResult, 1, Snapshot);
        // [THEN] Only the explicit matching snapshot produces an empty response.
        AssertEnvelope(Response, 1, 0);
        AssertRejectedResponse(TempCandidate, TempResult, ChangedErr, '');
        AssertRejectedResponse(TempCandidate, TempResult, ChangedErr, PadStr('0', 64, '0'));
    end;

    /// <summary>
    /// Verifies nonempty projections reject responses with missing or fabricated snapshots.
    /// </summary>
    [Test]
    procedure NonemptyProjectionRequiresExplicitSnapshot()
    var
        Skill: Record "Business Skill";
        TempCandidate: Record "Business Skill Search Buffer" temporary;
        TempResult: Record "Similarity Result" temporary;
        Snapshot: Text;
    begin
        // [GIVEN] A nonempty projected candidate set.
        InitializeSingleResult(Skill, TempCandidate, TempResult, Snapshot);
        // [WHEN] Responses are attempted with missing and fabricated snapshots.
        // [THEN] The response is rejected as stale.
        AssertRejectedResponse(TempCandidate, TempResult, ChangedErr, '');
        AssertRejectedResponse(TempCandidate, TempResult, ChangedErr, PadStr('0', 64, '0'));
    end;

    /// <summary>
    /// Verifies a changed candidate beyond top K still invalidates the entire response cohort.
    /// </summary>
    [Test]
    procedure ResponseValidatesChangedParentBeyondTopK()
    var
        FirstSkill: Record "Business Skill";
        SecondSkill: Record "Business Skill";
        TempCandidate: Record "Business Skill Search Buffer" temporary;
        TempResult: Record "Similarity Result" temporary;
        Snapshot: Text;
    begin
        // [GIVEN] Ranked results containing a candidate beyond the requested top K.
        Initialize();
        CreateActiveSkill(FirstSkill, 'First parent');
        CreateActiveSkill(SecondSkill, 'Second parent');
        CommitFixture();
        Projection.Build(TempCandidate, Snapshot);
        AddResult(TempResult, 1, GetCandidateId(TempCandidate, FirstSkill.ID), 0.5);
        AddResult(TempResult, 2, GetCandidateId(TempCandidate, SecondSkill.ID), 0.4);
        // [WHEN] That candidate becomes inactive before response projection.
        Management.DeactivateSkill(SecondSkill.ID);
        CommitFixture();
        // [THEN] Validation rejects the entire stale cohort, not just returned hits.
        AssertRejectedResponse(TempCandidate, TempResult, ChangedErr, Snapshot);
    end;

    /// <summary>
    /// Verifies unknown candidate GUIDs and canonical parent skill GUIDs are rejected as incomplete native-result mappings.
    /// </summary>
    [Test]
    procedure ResponseRejectsUnknownAndParentIdentities()
    var
        Skill: Record "Business Skill";
        TempCandidate: Record "Business Skill Search Buffer" temporary;
        TempResult: Record "Similarity Result" temporary;
        Snapshot: Text;
    begin
        // [GIVEN] A valid projected candidate and native result.
        InitializeSingleResult(Skill, TempCandidate, TempResult, Snapshot);
        TempResult.Get(1);
        TempResult."System ID" := CreateGuid();
        // [WHEN] The native result refers to an unknown or canonical parent identity.
        TempResult.Modify();
        // [THEN] Projection rejects the incomplete candidate mapping.
        AssertRejectedResponse(TempCandidate, TempResult, IncompleteResultsErr, Snapshot);
        TempResult.Get(1);
        TempResult."System ID" := Skill.SystemId;
        TempResult.Modify();
        AssertRejectedResponse(TempCandidate, TempResult, IncompleteResultsErr, Snapshot);
    end;

    /// <summary>
    /// Verifies duplicate candidate identities are rejected even when the duplicate occurs beyond top K.
    /// </summary>
    [Test]
    procedure ResponseRejectsDuplicateCandidatesAfterTopK()
    var
        Skill: Record "Business Skill";
        TempCandidate: Record "Business Skill Search Buffer" temporary;
        TempResult: Record "Similarity Result" temporary;
        Snapshot: Text;
    begin
        // [GIVEN] Two projected candidates and native results.
        InitializeTwoResults(Skill, TempCandidate, TempResult, Snapshot);
        TempResult.Get(2);
        TempResult."System ID" := GetCandidateId(TempCandidate, Skill.ID);
        // [WHEN] A result after the top K repeats a candidate identity.
        TempResult.Modify();
        // [THEN] Projection rejects the duplicate even outside returned hits.
        AssertRejectedResponse(TempCandidate, TempResult, IncompleteResultsErr, Snapshot);
    end;

    /// <summary>
    /// Verifies unordered similarity scores and noncontiguous result ranks are rejected.
    /// </summary>
    [Test]
    procedure ResponseRejectsUnorderedScoresAndRankGaps()
    var
        Skill: Record "Business Skill";
        TempCandidate: Record "Business Skill Search Buffer" temporary;
        TempResult: Record "Similarity Result" temporary;
        Snapshot: Text;
    begin
        // [GIVEN] An ordered, contiguous native result cohort.
        InitializeTwoResults(Skill, TempCandidate, TempResult, Snapshot);
        TempResult.Get(2);
        TempResult.Similarity := 0.9;
        // [WHEN] Scores are reordered or a rank gap is introduced.
        TempResult.Modify();
        // [THEN] Response projection rejects the malformed ranking.
        AssertRejectedResponse(TempCandidate, TempResult, IncompleteResultsErr, Snapshot);
        TempResult.Get(2);
        TempResult.Similarity := 0.4;
        TempResult.Modify();
        TempResult.Rename(3);
        AssertRejectedResponse(TempCandidate, TempResult, IncompleteResultsErr, Snapshot);
    end;

    /// <summary>
    /// Verifies missing, extra-unknown, or empty native results never produce a partial candidate response.
    /// </summary>
    [Test]
    procedure ResponseRequiresCompleteNativeCohort()
    var
        Skill: Record "Business Skill";
        TempCandidate: Record "Business Skill Search Buffer" temporary;
        TempResult: Record "Similarity Result" temporary;
        SecondId: Guid;
        Snapshot: Text;
    begin
        // [GIVEN] Native results for a projected candidate cohort.
        InitializeTwoResults(Skill, TempCandidate, TempResult, Snapshot);
        TempResult.Get(2);
        SecondId := TempResult."System ID";
        // [WHEN] Results are missing, unknown, or otherwise incomplete.
        TempResult.Delete();
        // [THEN] No partial response is returned.
        AssertRejectedResponse(TempCandidate, TempResult, IncompleteResultsErr, Snapshot);
        AddResult(TempResult, 2, SecondId, 0.4);
        AddResult(TempResult, 3, CreateGuid(), 0.3);
        AssertRejectedResponse(TempCandidate, TempResult, IncompleteResultsErr, Snapshot);
        TempResult.DeleteAll();
        AssertRejectedResponse(TempCandidate, TempResult, IncompleteResultsErr, Snapshot);
    end;

    /// <summary>
    /// Verifies building a response from projected records leaves the persisted skill identity, revision, and body unchanged.
    /// </summary>
    [Test]
    procedure ReadProjectionDoesNotMutateSource()
    var
        Skill: Record "Business Skill";
        CurrentSkill: Record "Business Skill";
        TempCandidate: Record "Business Skill Search Buffer" temporary;
        TempResult: Record "Similarity Result" temporary;
        Response: JsonObject;
        Snapshot: Text;
    begin
        // [GIVEN] A persisted skill and its projected candidate.
        InitializeSingleResult(Skill, TempCandidate, TempResult, Snapshot);
        // [WHEN] The search response is read from the projection.
        Response := Projection.ToResponse(TempCandidate, TempResult, 1, Snapshot);
        // [THEN] The original skill record remains unchanged.
        AssertEnvelope(Response, 1, 1);
        CurrentSkill.Get(Skill.ID);
        Assert.AreEqual(Skill.SystemId, CurrentSkill.SystemId, 'Projection preserves source identity.');
        Assert.AreEqual(Skill.SystemRowVersion, CurrentSkill.SystemRowVersion, 'Projection must not update the source.');
        Assert.AreEqual('One body', SkillText.GetSkillText(CurrentSkill), 'Projection preserves full text.');
    end;

    /// <summary>
    /// Verifies an empty eligible catalog returns a parseable schema-v2 response without native search.
    /// </summary>
    [Test]
    procedure EmptyCatalogReturnsSchemaV2WithoutNative()
    var
        Search: Codeunit "Business Skill Search";
        Response: JsonObject;
    begin
        // [GIVEN] An empty eligible skill catalog.
        Initialize();
        CommitFixture();
        // [WHEN] Search runs against the empty catalog.
        // [THEN] A valid empty schema-v2 response is produced.
        Assert.IsTrue(Response.ReadFrom(Search.Search('valid query', 5)), 'Return parseable JSON.');
        AssertEnvelope(Response, 5, 0);
    end;

    /// <summary>
    /// Verifies valid request boundaries pass while missing queries, out-of-range limits fail before search.
    /// </summary>
    [Test]
    procedure ValidateRequestRejectsInvalidBoundsBeforeNative()
    var
        Search: Codeunit "Business Skill Search";
    begin
        // [GIVEN] Valid and invalid query and limit values.
        Initialize();
        CommitFixture();
        Projection.ValidateRequest('valid', 1);
        Projection.ValidateRequest(PadStr('x', 2000, 'x'), 50);
        Projection.ValidateRequest(' valid ', 1);
        // [WHEN] Requests with invalid limits and query values are validated.
        // [THEN] Supported boundaries pass and invalid inputs fail before native search.
        AssertInvalidRequest('', 1, QueryRequiredErr);
        AssertInvalidRequest('   ', 1, QueryRequiredErr);
        AssertInvalidRequest('valid', 0, TopTooSmallErr);
        AssertInvalidRequest('valid', 51, TopTooLargeErr);
        asserterror Search.Search('', 1);
        Assert.ExpectedError(QueryRequiredErr);
        asserterror Search.Search('valid', 51);
        Assert.ExpectedError(TopTooLargeErr);
    end;

    local procedure Initialize()
    begin
        LibraryBusinessSkill.CleanAll();
    end;

    local procedure CommitFixture()
    begin
        Commit();
    end;

    local procedure CreateActiveSkill(var Skill: Record "Business Skill"; Body: Text)
    var
        SkillId: BigInteger;
    begin
        SkillId := LibraryBusinessSkill.CreateSkill('Search fixture', Body);
        LibraryBusinessSkill.ActivateSkill(SkillId);
        Skill.Get(SkillId);
    end;

    local procedure CreateEligibilityFixture(var FirstSkill: Record "Business Skill"; var SecondSkill: Record "Business Skill"; var ExcludedIds: List of [BigInteger])
    var
        Skill: Record "Business Skill";
        SkillId: BigInteger;
    begin
        CreateActiveSkill(FirstSkill, 'First active body');
        CreateActiveSkill(SecondSkill, 'Second active body');
        SkillId := LibraryBusinessSkill.CreateSkill('Inactive excluded', 'Inactive body');
        Management.DeactivateSkill(SkillId);
        ExcludedIds.Add(SkillId);
        CreateActiveSkill(Skill, 'Deactivated body');
        Management.DeactivateSkill(Skill.ID);
        ExcludedIds.Add(Skill.ID);
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

    local procedure AssertCandidateMetadata(var TempCandidate: Record "Business Skill Search Buffer" temporary; Skill: Record "Business Skill")
    begin
        TempCandidate.Reset();
        TempCandidate.SetRange("Skill ID", Skill.ID);
        Assert.AreEqual(1, TempCandidate.Count(), 'Exactly one candidate per eligible skill.');
        TempCandidate.FindFirst();
        Assert.AreEqual(Skill.SystemId, TempCandidate."Skill System ID", 'Preserve canonical identity.');
        Assert.AreEqual(TempCandidate."Candidate ID", TempCandidate.SystemId, 'Native target identity is the candidate GUID.');
        Assert.AreNotEqual(Skill.SystemId, TempCandidate."Candidate ID", 'Canonical and candidate identities differ.');
        Assert.AreEqual(Format(Skill.SystemRowVersion, 0, 9), TempCandidate."Skill Revision", 'Preserve source revision.');
        Assert.AreEqual(64, StrLen(TempCandidate."Catalog Snapshot"), 'Retain a complete SHA256 snapshot.');
        Assert.AreEqual(Skill.Title, TempCandidate.Title, 'Copy the complete persisted title.');
        Assert.AreEqual(Skill.Description, TempCandidate.Description, 'Copy the complete description without deriving or truncating instructions.');
        TempCandidate.Reset();
    end;

    local procedure AssertStableCandidates(var Original: Record "Business Skill Search Buffer" temporary; var Current: Record "Business Skill Search Buffer" temporary)
    begin
        Original.Reset();
        Current.Reset();
        Assert.AreEqual(Original.Count(), Current.Count(), 'Metadata changes preserve candidate count.');
        Original.FindSet();
        repeat
            Assert.IsTrue(Current.Get(Original."Candidate ID"), 'Metadata changes preserve candidate IDs.');
            Assert.AreEqual(Original."Skill ID", Current."Skill ID", 'Stable identity retains the canonical skill.');
        until Original.Next() = 0;
    end;

    local procedure InitializeSingleResult(var Skill: Record "Business Skill"; var TempCandidate: Record "Business Skill Search Buffer" temporary; var TempResult: Record "Similarity Result" temporary; var Snapshot: Text)
    begin
        Initialize();
        CreateActiveSkill(Skill, 'One body');
        BuildSingleResult(Skill, TempCandidate, TempResult, Snapshot);
    end;

    local procedure BuildSingleResult(Skill: Record "Business Skill"; var TempCandidate: Record "Business Skill Search Buffer" temporary; var TempResult: Record "Similarity Result" temporary; var Snapshot: Text)
    begin
        CommitFixture();
        Projection.Build(TempCandidate, Snapshot);
        Assert.AreEqual(1, TempCandidate.Count(), 'The fixture must have exactly one candidate.');
        AddResult(TempResult, 1, GetCandidateId(TempCandidate, Skill.ID), 0.5);
    end;

    local procedure InitializeTwoResults(var Skill: Record "Business Skill"; var TempCandidate: Record "Business Skill Search Buffer" temporary; var TempResult: Record "Similarity Result" temporary; var Snapshot: Text)
    var
        OtherSkill: Record "Business Skill";
    begin
        Initialize();
        CreateActiveSkill(Skill, PadStr('x', 3000, 'x'));
        CreateActiveSkill(OtherSkill, 'Other instructions');
        CommitFixture();
        Projection.Build(TempCandidate, Snapshot);
        Assert.AreEqual(2, TempCandidate.Count(), 'The fixture must have two distinct candidates.');
        AddResult(TempResult, 1, GetCandidateId(TempCandidate, Skill.ID), 0.5);
        AddResult(TempResult, 2, GetCandidateId(TempCandidate, OtherSkill.ID), 0.4);
    end;

    local procedure AssertCandidatePresent(var TempCandidate: Record "Business Skill Search Buffer" temporary; SkillId: BigInteger)
    begin
        TempCandidate.SetRange("Skill ID", SkillId);
        Assert.AreEqual(1, TempCandidate.Count(), 'Return this eligible parent exactly once.');
        TempCandidate.Reset();
    end;

    local procedure GetCandidateId(var TempCandidate: Record "Business Skill Search Buffer" temporary; SkillId: BigInteger): Guid
    var
        Result: Guid;
    begin
        TempCandidate.Reset();
        TempCandidate.SetRange("Skill ID", SkillId);
        TempCandidate.FindFirst();
        Result := TempCandidate."Candidate ID";
        TempCandidate.Reset();
        exit(Result);
    end;

    local procedure AddResult(var TempResult: Record "Similarity Result" temporary; Number: Integer; CandidateId: Guid; Score: Decimal)
    begin
        // No. is the native result key; duplicate target GUIDs intentionally reach mapper validation.
        TempResult.Init();
        TempResult."No." := Number;
        TempResult."System ID" := CandidateId;
        TempResult.Similarity := Score;
        TempResult.Insert();
    end;

    local procedure BuildResponseWithoutNative(): JsonObject
    var
        TempCandidate: Record "Business Skill Search Buffer" temporary;
        TempResult: Record "Similarity Result" temporary;
        Snapshot: Text;
    begin
        Projection.Build(TempCandidate, Snapshot);
        exit(Projection.ToResponse(TempCandidate, TempResult, 1, Snapshot));
    end;

    local procedure AssertRejectedResponse(var TempCandidate: Record "Business Skill Search Buffer" temporary; var TempResult: Record "Similarity Result" temporary; ExpectedError: Text; Snapshot: Text)
    var
        Response: JsonObject;
    begin
        Response.Add('notReturned', true);
        asserterror Response := Projection.ToResponse(TempCandidate, TempResult, 1, Snapshot);
        Assert.ExpectedError(ExpectedError);
        AssertNoReturnedHits(Response);
    end;

    local procedure AssertNoReturnedHits(Response: JsonObject)
    var
        Value: JsonToken;
    begin
        Assert.IsFalse(Response.Get('hits', Value), 'Errors must not return partial hits.');
        Assert.IsTrue(GetValue(Response, 'notReturned').AsValue().AsBoolean(), 'Failed calls leave the caller response untouched.');
    end;

    local procedure AssertInvalidRequest(Query: Text; Top: Integer; ExpectedError: Text)
    begin
        asserterror Projection.ValidateRequest(Query, Top);
        Assert.ExpectedError(ExpectedError);
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
    var
        Hits: JsonArray;
        Token: JsonToken;
    begin
        Assert.AreEqual(2, GetValue(Response, 'schemaVersion').AsValue().AsInteger(), 'Use schema version 2.');
        Assert.AreEqual('bc.semantic.similarity', GetValue(Response, 'scoreKind').AsValue().AsText(), 'Scores are raw native similarity.');
        Assert.IsTrue(GetValue(Response, 'higherIsBetter').AsValue().AsBoolean(), 'Higher scores rank first.');
        Assert.AreEqual('semantic', GetValue(Response, 'retrievalMode').AsValue().AsText(), 'No silent lexical fallback.');
        Assert.IsTrue(GetValue(Response, 'scoresAvailable').AsValue().AsBoolean(), 'Semantic responses expose scores.');
        Assert.IsFalse(GetValue(Response, 'resultsTruncated').AsValue().AsBoolean(), 'Semantic results are not truncated.');
        Assert.AreEqual(Top, GetValue(Response, 'requestedTop').AsValue().AsInteger(), 'Echo unique-skill limit.');
        Assert.AreEqual(Count, GetValue(Response, 'returnedCount').AsValue().AsInteger(), 'Report unique skill count.');
        Assert.IsFalse(GetValue(Response, 'candidateWindowTruncated').AsValue().AsBoolean(), 'No candidate truncation.');
        Assert.AreEqual('complete', GetValue(Response, 'indexCoverage').AsValue().AsText(), 'Successful coverage is complete.');
        Hits := GetValue(Response, 'hits').AsArray();
        Assert.AreEqual(Count, Hits.Count(), 'The result count must match the array.');
        Assert.IsFalse(Response.Get('answer', Token), 'Retrieval must not masquerade as a generated answer.');
        Assert.IsFalse(Response.Get('summary', Token), 'Retrieval must not invent a generated summary.');
        Assert.IsFalse(Response.Get('embeddings', Token), 'Do not expose model embedding coordinates.');
    end;

    local procedure AssertHitIdentity(Hit: JsonObject; Skill: Record "Business Skill"; Rank: Integer; Score: Decimal)
    var
        SystemId: Guid;
        Token: JsonToken;
    begin
        Assert.AreEqual(Skill.ID, GetValue(Hit, 'id').AsValue().AsBigInteger(), 'Return the canonical numeric ID.');
        Assert.IsTrue(Evaluate(SystemId, GetValue(Hit, 'systemId').AsValue().AsText()), 'Return a valid parent GUID.');
        Assert.AreEqual(Skill.SystemId, SystemId, 'Do not substitute a candidate GUID for parent identity.');
        Assert.AreEqual(Format(Skill.SystemRowVersion, 0, 9), GetValue(Hit, 'revision').AsValue().AsText(), 'Return an invariant revision string.');
        Assert.AreEqual(Rank, GetValue(Hit, 'rank').AsValue().AsInteger(), 'Unique parent ranks are contiguous.');
        Assert.AreEqual(Score, GetValue(Hit, 'score').AsValue().AsDecimal(), 'Keep raw score without summing paths or clamping.');
        Assert.AreEqual(Skill.Title, GetValue(Hit, 'title').AsValue().AsText(), 'Use the current title.');
        Assert.IsFalse(Hit.Get('skillType', Token), 'The retired type payload is not an alias.');
        Assert.IsFalse(Hit.Get('scope', Token), 'Hits carry no scope field.');
        Assert.IsFalse(Hit.Get('isReadOnly', Token), 'Skill provenance/editability payloads are removed.');
        Assert.IsFalse(Hit.Get('answer', Token), 'A hit is retrieval, not an answer.');
    end;
}
