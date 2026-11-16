// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.AI.BusinessSkills;

using System.Search;
using System.Security.Encryption;

/// <summary>
/// Builds one bounded title/description candidate per eligible skill for semantic retrieval.
/// Validates ranked candidates against canonical identities, revisions, and catalog snapshots before returning hits.
/// </summary>
codeunit 4170 "Business Skill Search Proj."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure ValidateRequest(Query: Text; Top: Integer)
    begin
        if Query.Trim() = '' then
            RejectRequest(QueryRequiredErr, QueryRequiredReasonTok);
        if Top < 1 then
            RejectRequest(StrSubstNo(TopTooSmallErr, 1), TopTooSmallReasonTok);
        if Top > 50 then
            RejectRequest(StrSubstNo(TopTooLargeErr, 50), TopTooLargeReasonTok);
    end;

    local procedure RejectRequest(ErrorMessage: Text; Reason: Text)
    begin
        Session.LogMessage(
            '0000VSK', RequestRejectedTelemetryMsg, Verbosity::Warning, DataClassification::SystemMetadata,
            TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok, 'Reason', Reason);
        Error(ErrorMessage);
    end;

    procedure Build(var TempCandidate: Record "Business Skill Search Buffer" temporary; var ExpectedSnapshot: Text)
    var
        Skill: Record "Business Skill";
        Management: Codeunit "Business Skill Management";
        Snapshot: Text;
    begin
        Clear(ExpectedSnapshot);
        TempCandidate.Reset();
        TempCandidate.DeleteAll();
        Management.SetAvailableSkillsFilter(Skill);
        CheckCapacity(Skill.Count());
        Snapshot := SourceSnapshot();
        if Skill.FindSet() then
            repeat
                AppendSkill(Skill, Snapshot, TempCandidate);
            until Skill.Next() = 0;
        if Snapshot <> SourceSnapshot() then
            Error(ChangedDuringSearchErr);
        // Empty projections have no candidate row on which to retain their request context.
        ExpectedSnapshot := Snapshot;
    end;

    /// <summary>Copies only persisted searchable metadata; blank descriptions remain title-only candidates.</summary>
    procedure AppendSkill(Skill: Record "Business Skill"; Snapshot: Text; var TempCandidate: Record "Business Skill Search Buffer" temporary)
    begin
        if IsNullGuid(Skill.SystemId) or (Skill.Title.Trim() = '') then
            Error(IncompleteSkillErr);
        CheckCapacity(TempCandidate.Count() + 1);
        Clear(TempCandidate);
        TempCandidate."Candidate ID" := CandidateId(Skill.SystemId);
        TempCandidate.SystemId := TempCandidate."Candidate ID";
        TempCandidate."Skill ID" := Skill.ID;
        TempCandidate."Skill System ID" := Skill.SystemId;
        TempCandidate."Skill Revision" := Format(Skill.SystemRowVersion, 0, 9);
        TempCandidate.Title := Skill.Title;
        TempCandidate.Description := Skill.Description;
        TempCandidate."Catalog Snapshot" := CopyStr(Snapshot, 1, MaxStrLen(TempCandidate."Catalog Snapshot"));
        TempCandidate.Insert(false, true);
    end;

    local procedure CheckCapacity(CandidateCount: Integer)
    begin
        if CandidateCount > MaximumCandidates() then
            RejectRequest(StrSubstNo(CapacityErr, MaximumCandidates()), CapacityExceededReasonTok);
    end;

    /// <summary>Validates the complete ranked candidate set before returning top current skills with raw native scores.</summary>
    procedure ToResponse(var TempCandidate: Record "Business Skill Search Buffer" temporary; var TempResult: Record "Similarity Result" temporary; Top: Integer; ExpectedSnapshot: Text): JsonObject
    var
        Skill: Record "Business Skill";
        Management: Codeunit "Business Skill Management";
        SeenCandidates: List of [Guid];
        SeenSkills: List of [BigInteger];
        Hits: JsonArray;
        Response: JsonObject;
        Hit: JsonObject;
        PreviousScore: Decimal;
        ResultNumber: Integer;
        Snapshot: Text;
    begin
        if Top < 1 then
            Error(TopTooSmallErr, 1);
        if Top > 50 then
            Error(TopTooLargeErr, 50);
        TempCandidate.Reset();
        TempResult.Reset();
        Snapshot := SourceSnapshot();
        if (StrLen(ExpectedSnapshot) <> 64) or (ExpectedSnapshot <> Snapshot) then
            Error(ChangedDuringSearchErr);
        if TempResult.Count() <> TempCandidate.Count() then
            Error(IncompleteResultsErr);
        PreviousScore := 0;
        if TempResult.FindSet() then
            repeat
                ResultNumber += 1;
                if (TempResult."No." <> ResultNumber) or SeenCandidates.Contains(TempResult."System ID") then
                    Error(IncompleteResultsErr);
                if (ResultNumber > 1) and (TempResult.Similarity > PreviousScore) then
                    Error(IncompleteResultsErr);
                if not TempCandidate.Get(TempResult."System ID") then
                    Error(IncompleteResultsErr);
                if TempCandidate."Catalog Snapshot" <> Snapshot then
                    Error(ChangedDuringSearchErr);
                SeenCandidates.Add(TempResult."System ID");
                PreviousScore := TempResult.Similarity;
                if SeenSkills.Contains(TempCandidate."Skill ID") then
                    Error(IncompleteResultsErr);
                Skill.Reset();
                Skill.SetRange(ID, TempCandidate."Skill ID");
                Skill.SetRange(SystemId, TempCandidate."Skill System ID");
                if not Skill.FindFirst() then
                    Error(ChangedDuringSearchErr);
                if not Management.IsSkillAvailable(Skill) then
                    Error(ChangedDuringSearchErr);
                if Format(Skill.SystemRowVersion, 0, 9) <> TempCandidate."Skill Revision" then
                    Error(ChangedDuringSearchErr);
                if Hits.Count() < Top then begin
                    Clear(Hit);
                    Hit.Add('id', Skill.ID);
                    Hit.Add('systemId', Skill.SystemId);
                    Hit.Add('revision', TempCandidate."Skill Revision");
                    Hit.Add('rank', Hits.Count() + 1);
                    Hit.Add('score', TempResult.Similarity);
                    Hit.Add('title', Skill.Title);
                    Hit.Add('description', Skill.Description);
                    Hits.Add(Hit);
                end;
                SeenSkills.Add(Skill.ID);
            until TempResult.Next() = 0;
        if Snapshot <> SourceSnapshot() then
            Error(ChangedDuringSearchErr);
        Response.Add('schemaVersion', 2);
        Response.Add('hits', Hits);
        Response.Add('scoreKind', 'bc.semantic.similarity');
        Response.Add('higherIsBetter', true);
        Response.Add('retrievalMode', 'semantic');
        Response.Add('scoresAvailable', true);
        Response.Add('resultsTruncated', false);
        Response.Add('requestedTop', Top);
        Response.Add('returnedCount', Hits.Count());
        Response.Add('candidateWindowTruncated', false);
        Response.Add('indexCoverage', 'complete');
        exit(Response);
    end;

    procedure MaximumCandidates(): Integer
    begin
        exit(1000);
    end;

    local procedure SourceSnapshot(): Text
    var
        Skill: Record "Business Skill";
        Cryptography: Codeunit "Cryptography Management";
        Algorithm: Option MD5,SHA1,SHA256,SHA384,SHA512;
        Rows: JsonArray;
        Snapshot: Text;
    begin
        Rows.Add(CompanyName());
        // Canonical identities and revisions detect content and lifecycle changes.
        Skill.SetLoadFields(SystemId, SystemRowVersion);
        if Skill.FindSet() then
            repeat
                Rows.Add('S:' + Format(Skill.SystemId) + ':' + Format(Skill.SystemRowVersion, 0, 9));
            until Skill.Next() = 0;
        Rows.WriteTo(Snapshot);
        exit(Cryptography.GenerateHash(Snapshot, Algorithm::SHA256));
    end;

    local procedure CandidateId(SkillSystemId: Guid): Guid
    var
        Cryptography: Codeunit "Cryptography Management";
        Algorithm: Option MD5,SHA1,SHA256,SHA384,SHA512;
        Hash: Text;
        Result: Guid;
    begin
        // The projection version is part of the key; content hashes in native search detect subsequent text edits.
        Hash := Cryptography.GenerateHash('BusinessSkill-Metadata-v3|' + Format(SkillSystemId, 0, 9), Algorithm::SHA256);
        if StrLen(Hash) <> 64 then
            Error(IncompleteResultsErr);
        if not Evaluate(Result, '{' + CopyStr(Hash, 1, 8) + '-' + CopyStr(Hash, 9, 4) + '-' + CopyStr(Hash, 13, 4) + '-' + CopyStr(Hash, 17, 4) + '-' + CopyStr(Hash, 21, 12) + '}') then
            Error(IncompleteResultsErr);
        exit(Result);
    end;

    var
        QueryRequiredErr: Label 'Enter a search query.';
        TopTooSmallErr: Label 'The result limit must be at least %1.', Comment = '%1 = minimum result limit';
        TopTooLargeErr: Label 'The result limit cannot exceed %1.', Comment = '%1 = maximum result limit';
        RequestRejectedTelemetryMsg: Label 'Business Skill search request was rejected.', Locked = true;
        TelemetryCategoryTok: Label 'Business Skill Search', Locked = true;
        QueryRequiredReasonTok: Label 'QueryRequired', Locked = true;
        TopTooSmallReasonTok: Label 'TopBelowMinimum', Locked = true;
        TopTooLargeReasonTok: Label 'TopAboveMaximum', Locked = true;
        CapacityExceededReasonTok: Label 'CandidateLimitExceeded', Locked = true;
        CapacityErr: Label 'The search includes more than %1 available skills. Reduce the number of active skills and try again.', Comment = '%1 = maximum number of skills';
        IncompleteSkillErr: Label 'An active skill has incomplete searchable content.';
        IncompleteResultsErr: Label 'The semantic search result does not cover the authorized candidate set. Search is unavailable.';
        ChangedDuringSearchErr: Label 'The skill catalog changed during search. Repeat the search to retrieve current content.';
}