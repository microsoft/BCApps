codeunit 135974 "Reminder Comm. Upgrade Tests"
{
    Subtype = Test;

    [Test]
    procedure LegacyReminderCommunicationDataIsMigrated()
    var
        ReminderAttachmentText: Record "Reminder Attachment Text";
        ReminderAttachmentTextLine: Record "Reminder Attachment Text Line";
        ReminderEmailText: Record "Reminder Email Text";
        ReminderLevel: Record "Reminder Level";
        ReminderTerms: Record "Reminder Terms";
        UpgradeStatus: Codeunit "Upgrade Status";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        Assert: Codeunit "Library Assert";
        LanguageCode: Code[10];
    begin
        if not UpgradeStatus.UpgradeTriggered() then
            exit;

        if UpgradeStatus.UpgradeTagPresentBeforeUpgrade(UpgradeTagDefinitions.GetReminderCommunicationMigrationTag()) then
            exit;

        LanguageCode := GetLanguageCode();
        ReminderTerms.Get('UPGRM1');
        ReminderLevel.Get(ReminderTerms.Code, 1);
        Assert.IsFalse(IsNullGuid(ReminderTerms."Reminder Attachment Text"), 'Reminder terms attachment text ID was not migrated.');
        Assert.IsFalse(IsNullGuid(ReminderTerms."Reminder Email Text"), 'Reminder terms email text ID was not migrated.');
        Assert.IsFalse(IsNullGuid(ReminderLevel."Reminder Attachment Text"), 'Reminder level attachment text ID was not migrated.');
        Assert.IsFalse(IsNullGuid(ReminderLevel."Reminder Email Text"), 'Reminder level email text ID was not migrated.');

        ReminderAttachmentText.Get(ReminderLevel."Reminder Attachment Text", LanguageCode);
        Assert.AreEqual('Legacy level fee', ReminderAttachmentText."Inline Fee Description", 'Reminder level fee description was not migrated.');
        ReminderAttachmentTextLine.Get(
            ReminderAttachmentText.Id, LanguageCode, ReminderAttachmentTextLine.Position::"Beginning Line", 10000);
        Assert.AreEqual('Legacy beginning', ReminderAttachmentTextLine.Text, 'Beginning text was not migrated.');
        ReminderAttachmentTextLine.Get(
            ReminderAttachmentText.Id, LanguageCode, ReminderAttachmentTextLine.Position::"Ending Line", 10000);
        Assert.AreEqual('Legacy ending', ReminderAttachmentTextLine.Text, 'Ending text was not migrated.');

        ReminderEmailText.Get(ReminderLevel."Reminder Email Text", LanguageCode);
        Assert.AreEqual('Legacy email body', ReminderEmailText.GetBodyText(), 'Email body was not migrated.');

        ReminderAttachmentText.Get(ReminderTerms."Reminder Attachment Text", LanguageCode);
        Assert.AreEqual('Legacy translated fee', ReminderAttachmentText."Inline Fee Description", 'Translated reminder terms fee was not migrated.');
        Assert.IsTrue(
            UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetReminderCommunicationMigrationTag()),
            'Reminder communication migration upgrade tag was not set.');
    end;

    [Test]
    procedure ExistingReminderCommunicationDataIsPreservedAndMigrationIsIdempotent()
    var
        ReminderAttachmentText: Record "Reminder Attachment Text";
        ReminderAttachmentTextLine: Record "Reminder Attachment Text Line";
        ReminderEmailText: Record "Reminder Email Text";
        ReminderLevel: Record "Reminder Level";
        ReminderCommunication: Codeunit "Reminder Communication";
        UpgradeStatus: Codeunit "Upgrade Status";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        Assert: Codeunit "Library Assert";
        LanguageCode: Code[10];
        LineCount: Integer;
    begin
        if not UpgradeStatus.UpgradeTriggered() then
            exit;

        if UpgradeStatus.UpgradeTagPresentBeforeUpgrade(UpgradeTagDefinitions.GetReminderCommunicationMigrationTag()) then
            exit;

        LanguageCode := GetLanguageCode();
        ReminderLevel.Get('UPGRM2', 1);
        ReminderAttachmentText.Get(ReminderLevel."Reminder Attachment Text", LanguageCode);
        Assert.AreEqual('Permanent level fee', ReminderAttachmentText."Inline Fee Description", 'Existing fee description was overwritten.');

        ReminderAttachmentTextLine.Get(
            ReminderAttachmentText.Id, LanguageCode, ReminderAttachmentTextLine.Position::"Beginning Line", 10000);
        Assert.AreEqual('Permanent beginning', ReminderAttachmentTextLine.Text, 'Existing beginning text was overwritten.');
        ReminderAttachmentTextLine.Get(
            ReminderAttachmentText.Id, LanguageCode, ReminderAttachmentTextLine.Position::"Ending Line", 10000);
        Assert.AreEqual('Legacy ending', ReminderAttachmentTextLine.Text, 'Missing ending text was not migrated.');

        ReminderEmailText.Get(ReminderLevel."Reminder Email Text", LanguageCode);
        Assert.AreEqual('Permanent email body', ReminderEmailText.GetBodyText(), 'Existing email body was overwritten.');

        ReminderAttachmentTextLine.SetRange(Id, ReminderAttachmentText.Id);
        ReminderAttachmentTextLine.SetRange("Language Code", LanguageCode);
        LineCount := ReminderAttachmentTextLine.Count();

        ReminderCommunication.MigrateLegacyCommunicationData();

        Assert.AreEqual(LineCount, ReminderAttachmentTextLine.Count(), 'Rerunning migration inserted duplicate attachment text lines.');
        ReminderAttachmentTextLine.Get(
            ReminderAttachmentText.Id, LanguageCode, ReminderAttachmentTextLine.Position::"Beginning Line", 10000);
        Assert.AreEqual('Permanent beginning', ReminderAttachmentTextLine.Text, 'Rerunning migration overwrote existing beginning text.');
        ReminderEmailText.Get(ReminderLevel."Reminder Email Text", LanguageCode);
        Assert.AreEqual('Permanent email body', ReminderEmailText.GetBodyText(), 'Rerunning migration overwrote existing email body.');
    end;

    local procedure GetLanguageCode(): Code[10]
    var
        Language: Codeunit Language;
    begin
        exit(Language.GetLanguageCode(Language.GetDefaultApplicationLanguageId()));
    end;
}
