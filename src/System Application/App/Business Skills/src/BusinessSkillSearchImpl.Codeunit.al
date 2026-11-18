// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.AI.BusinessSkills;

using System.AI;
using System.Privacy;
using System.Search;

/// <summary>
/// Coordinates native semantic ranking of skill titles and descriptions.
/// Searches the active virtual records and resolves ranked results against their current system identities.
/// </summary>
codeunit 4169 "Business Skill Search Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure Search(Query: Text; Top: Integer): Text
    var
        Skill: Record "Business Skill";
        TempResult: Record "Similarity Result" temporary;
        SemanticSearch: Codeunit "Semantic Search";
        Management: Codeunit "Business Skill Management";
        Target: RecordRef;
        FieldIds: List of [Integer];
        Result: JsonObject;
        ResultText: Text;
    begin
        ValidateRequest(Query, Top);
        Management.SetAvailableSkillsFilter(Skill);
        if Skill.Count() > 1000 then
            RejectRequest(StrSubstNo(CapacityErr, 1000), CapacityExceededReasonTok);
        if not Skill.IsEmpty() then begin
            RequireAzureOpenAIApproval();
            Skill.SetLoadFields(SystemId, Title, Description);
            Target.GetTable(Skill);
            SemanticSearch.SetSearchTarget(Target);
            SemanticSearch.SetMaxResults(Top);
            FieldIds := SearchFieldIds();
            if not SemanticSearch.FindSimilarByField(Query.Trim(), FieldIds, TempResult) then
                Error(SearchUnavailableErr);
            Target.Close();
        end;
        Result := ToResponse(TempResult, Top);
        Result.WriteTo(ResultText);
        exit(ResultText);
    end;

    local procedure ValidateRequest(Query: Text; Top: Integer)
    begin
        if Query.Trim() = '' then
            RejectRequest(QueryRequiredErr, QueryRequiredReasonTok);
        ValidateTop(Top);
    end;

    local procedure ValidateTop(Top: Integer)
    begin
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

    /// <summary>
    /// Maps native system IDs to current active skills, omitting deleted or inactive hits without a catalog-wide snapshot.
    /// </summary>
    internal procedure ToResponse(var TempResult: Record "Similarity Result" temporary; Top: Integer): JsonObject
    var
        Skill: Record "Business Skill";
        Management: Codeunit "Business Skill Management";
        SeenSystemIds: List of [Guid];
        Hits: JsonArray;
        Response: JsonObject;
        Hit: JsonObject;
        PreviousScore: Decimal;
        ResultNumber: Integer;
    begin
        ValidateTop(Top);
        TempResult.Reset();
        PreviousScore := 0;
        if TempResult.FindSet() then
            repeat
                ResultNumber += 1;
                if (TempResult."No." <> ResultNumber) or IsNullGuid(TempResult."System ID") or
                   SeenSystemIds.Contains(TempResult."System ID")
                then
                    Error(InvalidResultsErr);
                if (ResultNumber > 1) and (TempResult.Similarity > PreviousScore) then
                    Error(InvalidResultsErr);
                SeenSystemIds.Add(TempResult."System ID");
                PreviousScore := TempResult.Similarity;
                if Hits.Count() < Top then
                    if Skill.GetBySystemId(TempResult."System ID") then
                        if Management.IsSkillAvailable(Skill) then begin
                            if Skill.Title.Trim() = '' then
                                Error(IncompleteSkillErr);
                            Clear(Hit);
                            Hit.Add('id', Skill.ID);
                            Hit.Add('systemId', Skill.SystemId);
                            Hit.Add('revision', Format(Skill.SystemRowVersion, 0, 9));
                            Hit.Add('rank', Hits.Count() + 1);
                            Hit.Add('score', TempResult.Similarity);
                            Hit.Add('title', Skill.Title);
                            Hit.Add('description', Skill.Description);
                            Hits.Add(Hit);
                        end;
            until TempResult.Next() = 0;
        Response.Add('schemaVersion', 2);
        Response.Add('hits', Hits);
        Response.Add('scoreKind', 'bc.semantic.similarity');
        Response.Add('higherIsBetter', true);
        Response.Add('retrievalMode', 'semantic');
        Response.Add('scoresAvailable', true);
        Response.Add('resultsTruncated', false);
        Response.Add('requestedTop', Top);
        Response.Add('returnedCount', Hits.Count());
        exit(Response);
    end;

    local procedure RequireAzureOpenAIApproval()
    var
        PrivacyNotice: Codeunit "Privacy Notice";
        AIServiceName: Interface "AI Service Name";
    begin
        AIServiceName := Enum::"Azure AI Service Type"::"Azure OpenAI";
        if PrivacyNotice.GetPrivacyNoticeApprovalState(AIServiceName.GetServiceId(), false) <> Enum::"Privacy Notice Approval State"::Agreed then
            Error(AzureOpenAIApprovalRequiredErr);
    end;

    internal procedure SearchFieldIds(): List of [Integer]
    var
        Skill: Record "Business Skill";
        FieldIds: List of [Integer];
    begin
        FieldIds.Add(Skill.FieldNo(Title));
        FieldIds.Add(Skill.FieldNo(Description));
        exit(FieldIds);
    end;

    var
        AzureOpenAIApprovalRequiredErr: Label 'Azure OpenAI privacy approval is required before searching business skills. Ask an administrator to approve Azure OpenAI for everyone in Privacy Notices Status.';
        SearchUnavailableErr: Label 'Native semantic skill search is unavailable.';
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
        InvalidResultsErr: Label 'The semantic skill search returned invalid ranked results. Search is unavailable.';
}