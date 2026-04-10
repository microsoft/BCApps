codeunit 135977 "Upgrade Privacy Notices Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";

    [Test]
    [Scope('OnPrem')]
    procedure ValidatePrivacyNoticesHasBeenApproved()
    var
        PrivacyNotice: Codeunit "Privacy Notice";
        PrivacyNoticeRegistrations: Codeunit "Privacy Notice Registrations";
        UpgradeStatus: Codeunit "Upgrade Status";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if not UpgradeStatus.UpgradeTriggered() then
            exit;

        if UpgradeStatus.UpgradeTagPresentBeforeUpgrade(UpgradeTagDefinitions.GetUpdateInitialPrivacyNoticesTag()) then
            exit;

        Assert.AreEqual("Privacy Notice Approval State"::Agreed, PrivacyNotice.GetPrivacyNoticeApprovalState(PrivacyNoticeRegistrations.GetOneDrivePrivacyNoticeId()), 'OneDrive integration was not agreed to.');
        Assert.AreEqual("Privacy Notice Approval State"::Agreed, PrivacyNotice.GetPrivacyNoticeApprovalState(PrivacyNoticeRegistrations.GetExchangePrivacyNoticeId()), 'Exchange integration was not agreed to.');
    end;
}
