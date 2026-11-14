codeunit 135975 "Reminder Line Cleanup Tests"
{
    Subtype = Test;

    [Test]
    procedure OrphanReminderLinesAreDeleted()
    var
        ReminderLine: Record "Reminder Line";
        UpgradeStatus: Codeunit "Upgrade Status";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        Assert: Codeunit "Library Assert";
    begin
        if not UpgradeStatus.UpgradeTriggered() then
            exit;

        if UpgradeStatus.UpgradeTagPresentBeforeUpgrade(UpgradeTagDefinitions.GetDeleteOrphanReminderLinesTag()) then
            exit;

        ReminderLine.SetRange("Reminder No.", '');
        Assert.IsTrue(ReminderLine.IsEmpty(), 'Reminder lines with a blank Reminder No. were not deleted.');

        Assert.IsTrue(ReminderLine.Get('UPG-RMD-VALID', 10000), 'A valid reminder line was deleted.');
        Assert.IsTrue(
            UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetDeleteOrphanReminderLinesTag()),
            'Orphan reminder line cleanup upgrade tag was not set.');
    end;
}
