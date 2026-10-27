// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;



codeunit 3351 "PA Setup Presentation" // TODO: I think this is a bit of a weird one in terms of the boundaries that define them, most are related to knownsenders functionality.. granted the "presentation" part is signaling that they are used for UX concerns... for the additional fields one, we can prob inline it in the caller. yeah, i think we should create the knownsenders codeunit as capabilti and put those concerns there, not sure if other things could eblong there... or wdyt? anywhere else? and maybe in this one, the presentation one, we move other logic that the page directly has... if applicable, idk..
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    Permissions = tabledata "PA Known Sender" = r;

    #region Known senders presentation

    var
        PASetup: Codeunit "PA Setup";

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
}
