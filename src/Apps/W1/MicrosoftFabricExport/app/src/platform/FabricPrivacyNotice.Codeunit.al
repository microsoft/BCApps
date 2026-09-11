namespace Microsoft.FabricExport;

using System.Privacy;

codeunit 9129 "Fabric Privacy Notice"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        PrivacyNoticeIdTok: Label 'MicrosoftFabricExport', Locked = true;
        IntegrationServiceNameTxt: Label 'Microsoft Fabric Export - Open Mirroring';
        NotApprovedErr: Label 'Exporting data to Microsoft Fabric requires the privacy notice to be approved.';
        OpenSetupActionTxt: Label 'Open Fabric Platform Setup';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Privacy Notice", OnRegisterPrivacyNotices, '', false, false)]
    local procedure RegisterPrivacyNotice(var TempPrivacyNotice: Record "Privacy Notice" temporary)
    begin
        TempPrivacyNotice.Init();
        TempPrivacyNotice.ID := PrivacyNoticeIdTok;
        TempPrivacyNotice."Integration Service Name" := IntegrationServiceNameTxt;
        if not TempPrivacyNotice.Insert() then;
    end;

    internal procedure IsApproved(): Boolean
    var
        PrivacyNotice: Codeunit "Privacy Notice";
    begin
        exit(PrivacyNotice.GetPrivacyNoticeApprovalState(PrivacyNoticeIdTok) = "Privacy Notice Approval State"::Agreed);
    end;

    // Shows the consent dialog when GUI is available, then fails closed (with a navigation
    // action back to setup) if the notice still isn't approved — covers both the interactive
    // setup-page flow and non-interactive callers such as the service-enabled API actions.
    internal procedure EnsureApproved()
    var
        PrivacyNotice: Codeunit "Privacy Notice";
        ErrInfo: ErrorInfo;
    begin
        if GuiAllowed() and not IsApproved() then
            PrivacyNotice.ConfirmPrivacyNoticeApproval(PrivacyNoticeIdTok);

        if IsApproved() then
            exit;

        ErrInfo.Message := NotApprovedErr;
        ErrInfo.DataClassification := DataClassification::SystemMetadata;
        ErrInfo.PageNo := Page::"Fabric Platform Setup";
        ErrInfo.AddNavigationAction(OpenSetupActionTxt);
        Error(ErrInfo);
    end;
}
