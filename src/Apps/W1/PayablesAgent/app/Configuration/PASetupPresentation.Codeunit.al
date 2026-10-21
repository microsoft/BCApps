// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;



codeunit 3351 "PA Setup Presentation"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    Permissions = tabledata "PA Known Sender" = r;

    #region Known senders presentation

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

    procedure PolicyLabel(Policy: Enum "PA Email Review Policy"): Text
    var
        AlwaysLbl: Label 'Always';
        NeverLbl: Label 'Never';
        OnlyIfUntrustedLbl: Label 'Manage per sender';
    begin
        case Policy of
            Policy::Always:
                exit(AlwaysLbl);
            Policy::Never:
                exit(NeverLbl);
            Policy::OnlyIfUntrusted:
                exit(OnlyIfUntrustedLbl);
        end;
        exit('');
    end;

    #endregion

    #region Setup page interactions

    internal procedure OpenAdditionalFieldsSetup(): Boolean
    var
        PADraftBasedSetup: Codeunit "PA Draft Based Setup";
    begin
        PASetup.GetSetup();
        if not PASetup.SupportsAdditionalFields() then
            exit(false);
        exit(PADraftBasedSetup.OpenAdditionalFieldsSetup());
    end;

    #endregion

    var
        PASetup: Codeunit "PA Setup";
}
