// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

codeunit 3351 "PA Known Senders"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "PA Known Sender" = R;

    procedure ClassifyKnownSendersUnusedByChange(NewPolicy: Enum "PA Email Review Policy"; NewMonitoredFolder: Text; var KnownSendersCount: Integer): Enum "PA Setup Change Impact"
    var
        KnownSender: Record "PA Known Sender";
    begin
        KnownSendersCount := KnownSender.Count();
        if KnownSendersCount = 0 then
            exit("PA Setup Change Impact"::None);
        exit(ClassifyByPolicyAndFolder(NewPolicy, NewMonitoredFolder));
    end;

    procedure ClassifyKnownSendersUnusedReason(SavedPolicy: Enum "PA Email Review Policy"; SavedMonitoredFolder: Text): Enum "PA Setup Change Impact"
    begin
        exit(ClassifyByPolicyAndFolder(SavedPolicy, SavedMonitoredFolder));
    end;

    local procedure ClassifyByPolicyAndFolder(Policy: Enum "PA Email Review Policy"; MonitoredFolder: Text): Enum "PA Setup Change Impact"
    begin
        if MonitoredFolder <> '' then
            exit("PA Setup Change Impact"::KnownSendersIgnoredByFolder);
        if Policy in [Policy::Always, Policy::Never] then
            exit("PA Setup Change Impact"::KnownSendersIgnoredByPolicy);
        exit("PA Setup Change Impact"::None);
    end;

    internal procedure ShouldRequestReview(WorkItem: Codeunit "PA Work Item"): Boolean
    var
        KnownSender: Record "PA Known Sender";
        PASetup: Codeunit "PA Setup";
        HeaderValue: Text;
        SenderAuthenticated: Boolean;
    begin
        if WorkItem.GetSourceType() <> "PA Source Type"::Email then
            exit(false);

        PASetup.LoadOrCreateSetup();
        case PASetup.GetEmailReviewPolicy() of
            "PA Email Review Policy"::Always,
            "PA Email Review Policy"::Unset:
                exit(true);
            "PA Email Review Policy"::Never:
                exit(false);
        end;
        if PASetup.GetEmailFolder() <> '' then
            exit(false);
        if WorkItem.TryGetEmailHeader('Authentication-Results', HeaderValue) then
            SenderAuthenticated := CompAuthPassed(HeaderValue);
        if not SenderAuthenticated then
            SenderAuthenticated := IsSenderInternal(WorkItem);
        if not SenderAuthenticated then
            exit(true);
        if KnownSender.GetForWorkItem(WorkItem, KnownSender) then
            exit(KnownSender."Sender Policy" <> "PA Sender Policy"::Approve);
        if IsSenderInternal(WorkItem) then
            exit(false);
        exit(true);
    end;

    local procedure IsSenderInternal(WorkItem: Codeunit "PA Work Item"): Boolean
    var
        HeaderValue: Text;
    begin
        if WorkItem.TryGetEmailHeader('X-MS-Exchange-Organization-AuthAs', HeaderValue) then
            exit(LowerCase(HeaderValue).Trim() = 'internal');
        exit(false);
    end;

    local procedure CompAuthPassed(AuthenticationResults: Text): Boolean
    begin
        exit(StrPos(LowerCase(AuthenticationResults), 'compauth=pass') > 0);
    end;
}
