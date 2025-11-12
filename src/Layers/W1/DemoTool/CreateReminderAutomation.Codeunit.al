codeunit 101295 "Create Reminder Automation"
{
    trigger OnRun()
    begin
        CreateAutomationToCreateReminders();
        CreateAutomationToSendReminders();
    end;

    local procedure CreateAutomationToCreateReminders()
    var
        DemoDataSetup: Record "Demo Data Setup";
        CreateReminderAction: Codeunit "Create Reminder Action";
        TableID: Integer;
        SetupSystemID: Guid;
    begin
        DemoDataSetup.Get();
        CreateReminderActionGroupRecord(CreateRemindersAutomationGroupCodeLbl, CreateRemindersAutomationDescriptionLbl, StrSubstNo(FilterLabelTxt, DemoDataSetup.DomesticCode(), DemoDataSetup.ForeignCode()));
        CreateReminderAction.CreateNew(CreateRemindersDefaultActionCodeLbl, CreateRemindersAutomationGroupCodeLbl);
        CreateReminderAction.GetSetupRecord(TableID, SetupSystemID);
        CreateReminderActionRecord(Enum::"Reminder Action"::"Create Reminder", CreateRemindersDefaultActionCodeLbl, CreateRemindersAutomationGroupCodeLbl, 1);
    end;

    local procedure CreateAutomationToSendReminders()
    var
        DemoDataSetup: Record "Demo Data Setup";
        SendRemindersSetup: Record "Send Reminders Setup";
        SendReminderAction: Codeunit "Send Reminder Action";
        TableID: Integer;
        SetupSystemID: Guid;
    begin
        DemoDataSetup.Get();
        CreateReminderActionGroupRecord(SendRemindersAutomationGroupCodeLbl, SendRemindersAutomationDescriptionLbl, DemoDataSetup.DomesticCode());
        SendReminderAction.CreateNew(EmailRemindersDefaultActionCodeLbl, SendRemindersAutomationGroupCodeLbl);
        SendReminderAction.GetSetupRecord(TableID, SetupSystemID);
        CreateReminderActionRecord(Enum::"Reminder Action"::"Send Reminder", EmailRemindersDefaultActionCodeLbl, SendRemindersAutomationGroupCodeLbl, 1);
        SendRemindersSetup.GetBySystemId(SetupSystemID);
        SendRemindersSetup."Use Document Sending Profile" := false;
        SendRemindersSetup."Send by Email" := true;
        SendRemindersSetup."Attach Invoice Documents" := SendRemindersSetup."Attach Invoice Documents"::All;
        SendRemindersSetup."Log Interaction" := true;
        SendRemindersSetup.Print := false;
        SendRemindersSetup.Modify();
    end;

    local procedure CreateReminderActionGroupRecord(ReminderActionGroupCode: Text; ReminderActionGroupDescription: Text; ReminderTermsFilter: Text)
    var
        ReminderActionGroup: Record "Reminder Action Group";
    begin
        ReminderActionGroup.Code := CopyStr(ReminderActionGroupCode, 1, MaxStrLen(ReminderActionGroup.Code));
        ReminderActionGroup.Description := CopyStr(ReminderActionGroupDescription, 1, MaxStrLen(ReminderActionGroup.Description));
        ReminderActionGroup.Insert(true);
        ReminderActionGroup.SetReminderTermsSelectionFilter(ReminderTermsFilter);
    end;

    local procedure CreateReminderActionRecord(ReminderActionType: Enum "Reminder Action"; CreateRemindersActionCode: Text; CreateRemindersActionGroupCode: Text; ReminderActionOrder: Integer)
    var
        ReminderAction: Record "Reminder Action";
    begin
        ReminderAction.Code := CopyStr(CreateRemindersActionCode, 1, MaxStrLen(ReminderAction.Code));
        ReminderAction.Type := ReminderActionType;
        ReminderAction."Reminder Action Group Code" := CopyStr(CreateRemindersActionGroupCode, 1, MaxStrLen(ReminderAction.Code));
        ReminderAction.Order := ReminderActionOrder;
        ReminderAction.Insert(true);
    end;

    var
        FilterLabelTxt: Label '%1|%2', Locked = true;
        CreateRemindersAutomationGroupCodeLbl: Label 'CREATE REMINDERS';
        CreateRemindersDefaultActionCodeLbl: Label 'DEFAULT';
        CreateRemindersAutomationDescriptionLbl: Label 'Create draft Reminders for all customers';
        SendRemindersAutomationGroupCodeLbl: Label 'SEND REMINDERS - DOMESTIC CUSTOMERS';
        EmailRemindersDefaultActionCodeLbl: Label 'SEND EMAIL';
        SendRemindersAutomationDescriptionLbl: Label 'Send Reminders for domestic customers';
}