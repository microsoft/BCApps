namespace Microsoft.Test.DemoTool;

using Microsoft.DemoTool.Helpers;
using Microsoft.Sales.Reminder;

codeunit 148050 "Contoso Reminder Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure ReminderHelperStoresCommunicationText()
    var
        ContosoReminder: Codeunit "Contoso Reminder";
        ReminderTerms: Record "Reminder Terms";
        ReminderLevel: Record "Reminder Level";
        ReminderAttachmentText: Record "Reminder Attachment Text";
        ReminderAttachmentTextLine: Record "Reminder Attachment Text Line";
        ReminderEmailText: Record "Reminder Email Text";
        ReminderGuid: Guid;
    begin
        ContosoReminder.SetOverwriteData(true);
        ContosoReminder.InsertReminderTerms('CTEST', 'Contoso reminder test');
        ContosoReminder.InsertReminderLevel('CTEST', 1, '<2D>', 0, '<7D>');

        ReminderGuid := CreateGuid();
        ContosoReminder.InsertReminderAttachText(
            ReminderGuid, 'CTEST', 1, 'ENU', Enum::"Reminder Text Source Type"::"Reminder Level",
            'Reminder', 'Beginning text', 'Inline fee', 'Ending text');
        ContosoReminder.InsertReminderEmailText(
            'CTEST', 1, 'ENU', Enum::"Reminder Text Source Type"::"Reminder Level",
            'Subject', 'Greeting', 'Body text', 'Closing');

        ReminderLevel.Get('CTEST', 1);
        ReminderAttachmentText.Get(ReminderLevel."Reminder Attachment Text", 'ENU');
        Assert.AreEqual('Inline fee', ReminderAttachmentText."Inline Fee Description", 'The inline fee description was not stored.');

        ReminderAttachmentTextLine.SetRange(Id, ReminderAttachmentText.Id);
        ReminderAttachmentTextLine.SetRange("Language Code", 'ENU');
        ReminderAttachmentTextLine.SetRange(Position, ReminderAttachmentTextLine.Position::"Beginning Line");
        ReminderAttachmentTextLine.FindFirst();
        Assert.AreEqual('Beginning text', ReminderAttachmentTextLine.Text, 'The attachment beginning line was not stored.');
        ReminderAttachmentTextLine.SetRange(Position, ReminderAttachmentTextLine.Position::"Ending Line");
        ReminderAttachmentTextLine.FindFirst();
        Assert.AreEqual('Ending text', ReminderAttachmentTextLine.Text, 'The attachment ending line was not stored.');

        ReminderEmailText.Get(ReminderLevel."Reminder Email Text", 'ENU');
        Assert.AreEqual('Body text', ReminderEmailText.GetBodyText(), 'The reminder email body was not stored.');

        ReminderEmailText.Delete(true);
        ReminderAttachmentText.Delete(true);
        ReminderLevel.Delete(true);
        ReminderTerms.Get('CTEST');
        ReminderTerms.Delete(true);
    end;

    [Test]
    procedure ReminderHelperCompletesExistingAttachmentText()
    var
        ContosoReminder: Codeunit "Contoso Reminder";
        ReminderTerms: Record "Reminder Terms";
        ReminderLevel: Record "Reminder Level";
        ReminderAttachmentText: Record "Reminder Attachment Text";
        ReminderAttachmentTextLine: Record "Reminder Attachment Text Line";
        ReminderGuid: Guid;
    begin
        ContosoReminder.SetOverwriteData(false);
        ContosoReminder.InsertReminderTerms('CTEST2', 'Contoso reminder rerun test');
        ContosoReminder.InsertReminderLevel('CTEST2', 1, '<2D>', 0, '<7D>');

        ReminderGuid := CreateGuid();
        ReminderAttachmentText.Init();
        ReminderAttachmentText.Validate(Id, ReminderGuid);
        ReminderAttachmentText.Validate("Language Code", 'ENU');
        ReminderAttachmentText.Validate("Source Type", Enum::"Reminder Text Source Type"::"Reminder Level");
        ReminderAttachmentText.Insert(true);
        ReminderLevel.Get('CTEST2', 1);
        ReminderLevel.Validate("Reminder Attachment Text", ReminderGuid);
        ReminderLevel.Modify(true);

        ContosoReminder.InsertReminderAttachText(
            ReminderGuid, 'CTEST2', 1, 'ENU', Enum::"Reminder Text Source Type"::"Reminder Level",
            'Reminder', 'Beginning text', 'Inline fee', 'Ending text');

        ReminderAttachmentTextLine.Get(ReminderGuid, 'ENU', ReminderAttachmentTextLine.Position::"Beginning Line", 10000);
        Assert.AreEqual('Beginning text', ReminderAttachmentTextLine.Text, 'The missing attachment beginning line was not added.');
        ReminderAttachmentTextLine.Get(ReminderGuid, 'ENU', ReminderAttachmentTextLine.Position::"Ending Line", 10000);
        Assert.AreEqual('Ending text', ReminderAttachmentTextLine.Text, 'The missing attachment ending line was not added.');

        ReminderAttachmentTextLine.SetRange(Id, ReminderGuid);
        ReminderAttachmentTextLine.DeleteAll(true);
        ReminderAttachmentText.Delete(true);
        ReminderLevel.Delete(true);
        ReminderTerms.Get('CTEST2');
        ReminderTerms.Delete(true);
    end;
}
