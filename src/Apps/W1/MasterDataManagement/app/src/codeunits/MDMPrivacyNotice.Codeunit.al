namespace Microsoft.Integration.MDM;

using System.Privacy;

/// <summary>
/// Registers the privacy notice for cross-environment master data synchronization and gates data transfer on
/// its approval. The setup wizard records the durable platform approval; the HTTP transport verifies it before
/// every outbound call, so no master data leaves the environment without recorded per-integration consent.
/// </summary>
codeunit 7242 "MDM Privacy Notice"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        PrivacyNoticeIdTok: Label 'MDMCrossEnvSync', Locked = true;
        IntegrationServiceNameTxt: Label 'Master Data Management - cross-environment synchronization';
        NotApprovedErr: Label 'Cross-environment master data synchronization requires the privacy notice to be approved. Open Master Data Management Setup and approve sharing data between Business Central environments.';
        OpenSetupActionTxt: Label 'Open Master Data Management Setup';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Privacy Notice", OnRegisterPrivacyNotices, '', false, false)]
    local procedure RegisterPrivacyNotice(var TempPrivacyNotice: Record "Privacy Notice" temporary)
    begin
        TempPrivacyNotice.Init();
        TempPrivacyNotice.ID := PrivacyNoticeIdTok;
        TempPrivacyNotice."Integration Service Name" := IntegrationServiceNameTxt;
        if not TempPrivacyNotice.Insert() then;
    end;

    procedure GetPrivacyNoticeId(): Code[50]
    begin
        exit(PrivacyNoticeIdTok);
    end;

    procedure IsApproved(): Boolean
    var
        PrivacyNotice: Codeunit "Privacy Notice";
    begin
        exit(PrivacyNotice.GetPrivacyNoticeApprovalState(PrivacyNoticeIdTok, false) = "Privacy Notice Approval State"::Agreed);
    end;

    // Interactive: shows the platform notice and records the admin's decision (used from the setup wizard).
    procedure ConfirmApproval(): Boolean
    var
        PrivacyNotice: Codeunit "Privacy Notice";
    begin
        exit(PrivacyNotice.ConfirmPrivacyNoticeApproval(PrivacyNoticeIdTok, false));
    end;

    // Non-interactive gate for background/transport paths: fail closed if consent isn't recorded.
    procedure CheckApproved()
    var
        MasterDataManagementSetup: Record "Master Data Management Setup";
        ErrInfo: ErrorInfo;
    begin
        if IsApproved() then
            exit;
        ErrInfo.Message := NotApprovedErr;
        if MasterDataManagementSetup.Get() then begin
            ErrInfo.RecordId := MasterDataManagementSetup.RecordId();
            ErrInfo.AddNavigationAction(OpenSetupActionTxt);
        end;
        Error(ErrInfo);
    end;
}
