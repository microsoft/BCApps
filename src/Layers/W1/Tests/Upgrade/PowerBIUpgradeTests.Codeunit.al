codeunit 135963 "PowerBI Upgrade Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [PowerBI]
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidatePowerBIOptinImage()
    var
        MediaRepository: Record "Media Repository";
        UpgradeStatus: Codeunit "Upgrade Status";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        Assert: Codeunit "Library Assert";
        RecordVariant: Variant;
    begin
        if not UpgradeStatus.UpgradeTriggered() then
            exit;

        if UpgradeStatus.UpgradeTagPresentBeforeUpgrade(UpgradeTagDefinitions.GetUpgradePowerBIOptinImageUpgradeTag()) then
            exit;

        MediaRepository.SetRange("File Name", 'PowerBi-OptIn-480px.png');

        MediaRepository.SetRange("Display Target", Format(ClientType::Web));
        RecordVariant := MediaRepository;
        Assert.RecordIsNotEmpty(RecordVariant);

        MediaRepository.SetRange("Display Target", Format(ClientType::Tablet));
        RecordVariant := MediaRepository;
        Assert.RecordIsNotEmpty(RecordVariant);

        MediaRepository.SetRange("Display Target", Format(ClientType::Phone));
        RecordVariant := MediaRepository;
        Assert.RecordIsNotEmpty(RecordVariant);
    end;
}