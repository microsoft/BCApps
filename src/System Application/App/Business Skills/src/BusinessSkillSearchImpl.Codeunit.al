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
/// Searches the complete bounded candidate set and delegates canonical result validation to the projection codeunit.
/// </summary>
codeunit 4169 "Business Skill Search Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure Search(query: Text; top: Integer): Text
    var
        TempCandidate: Record "Business Skill Search Buffer" temporary;
        TempResult: Record "Similarity Result" temporary;
        Projection: Codeunit "Business Skill Search Proj.";
        SemanticSearch: Codeunit "Semantic Search";
        Target: RecordRef;
        FieldIds: List of [Integer];
        Result: JsonObject;
        ResultText: Text;
        ExpectedSnapshot: Text;
    begin
        Projection.ValidateRequest(query, top);
        Projection.Build(TempCandidate, ExpectedSnapshot);
        if not TempCandidate.IsEmpty() then begin
            RequireAzureOpenAIApproval();
            Target.GetTable(TempCandidate);
            SemanticSearch.SetSearchTarget(Target);
            // Eligibility is applied before ranking; validate the complete bounded cohort before top-K.
            SemanticSearch.SetMaxResults(TempCandidate.Count());
            FieldIds := SearchFieldIds();
            if not SemanticSearch.FindSimilarByField(query.Trim(), FieldIds, TempResult) then
                Error(SearchUnavailableErr);
            Target.Close();
        end;
        Result := Projection.ToResponse(TempCandidate, TempResult, top, ExpectedSnapshot);
        Result.WriteTo(ResultText);
        exit(ResultText);
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
        TempCandidate: Record "Business Skill Search Buffer";
        FieldIds: List of [Integer];
    begin
        FieldIds.Add(TempCandidate.FieldNo(Title));
        FieldIds.Add(TempCandidate.FieldNo(Description));
        exit(FieldIds);
    end;

    var
        AzureOpenAIApprovalRequiredErr: Label 'Azure OpenAI privacy approval is required before searching business skills. Ask an administrator to approve Azure OpenAI for everyone in Privacy Notices Status.';
        SearchUnavailableErr: Label 'Native semantic skill search is unavailable.';
}