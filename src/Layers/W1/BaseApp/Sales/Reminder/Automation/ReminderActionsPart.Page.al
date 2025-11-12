// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

page 6755 "Reminder Actions Part"
{
    PageType = ListPart;
    SourceTable = "Reminder Action";
    DeleteAllowed = false;
    DelayedInsert = true;
    MultipleNewLines = false;
    InsertAllowed = false;
    Editable = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Order; Rec.Order)
                {
                    ApplicationArea = All;
                    Caption = 'Order';
                    ToolTip = 'Specifies the order in which the actions will be performed.';
                    Editable = false;
                }
                field(ActionType; Rec.Type)
                {
                    ApplicationArea = All;
                    Caption = 'Type';
                    ToolTip = 'Specifies the type of the action.';
                    Editable = false;

                    trigger OnValidate()
                    begin
                        UpdateReminderAction();
                    end;
                }
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                    Caption = 'Code';
                    ToolTip = 'Specifies the code of the action.';
                    Editable = false;
                }
                field(Summary; SummaryText)
                {
                    ApplicationArea = All;
                    Caption = 'Step summary';
                    ToolTip = 'Specifies a short summary of the action. For more details, select the Setup button.';
                    Editable = false;
                }
                field(StopOnError; Rec."Stop on Error")
                {
                    ApplicationArea = All;
                    Caption = 'Stop on error';
                    ToolTip = 'Specifies if the job should stop if an error occurs during this action. If not selected, the job will attempt to process all records and actions.';
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(New)
            {
                ApplicationArea = All;
                Caption = 'New';
                ToolTip = 'Create new reminder action.';
                Image = New;
                Enabled = EnableAction;
                trigger OnAction()
                begin
                    CreateNewReminderAction();
                    CurrPage.Update();
                end;
            }
            action(Setup)
            {
                ApplicationArea = All;
                Caption = 'Setup';
                ToolTip = 'Setup reminder action.';
                Image = Setup;
                Enabled = EnableAction;
                trigger OnAction()
                begin
                    UpdateReminderAction();
                    ReminderAction.Setup();
                end;
            }
            action(Delete)
            {
                ApplicationArea = All;
                Caption = 'Delete';
                ToolTip = 'Delete the reminder action.';
                Image = Delete;
                Enabled = EnableAction;
                trigger OnAction()
                begin
                    UpdateReminderAction();
                    ReminderAction.Delete();
                    Rec.Delete();
                end;
            }
            action(MoveUp)
            {
                ApplicationArea = All;
                Caption = 'Move up';
                ToolTip = 'Move reminder action up in the list. This will change the order of when the action is performed.';
                Image = MoveUp;
                Enabled = EnableAction;
                trigger OnAction()
                begin
                    Rec.MoveUp();
                end;
            }
            action(MoveDown)
            {
                ApplicationArea = All;
                Caption = 'Move down';
                ToolTip = 'Move reminder action down in the list. This will change the order of when the action is performed.';
                Image = MoveDown;
                Enabled = EnableAction;
                trigger OnAction()
                begin
                    Rec.MoveDown();
                end;
            }
            action(SetClearStopOnErrors)
            {
                ApplicationArea = All;
                Caption = 'Set stop on error';
                ToolTip = 'Choosing this option will set stop on error, which means if the error occurs during this action job will stop immediatelly and will not proceed with other actions.';
                Image = ErrorLog;
                Enabled = EnableAction;

                trigger OnAction()
                begin
                    Rec."Stop on Error" := true;
                    Rec.Modify();
                end;
            }
            action(ClearStopOnErrors)
            {
                ApplicationArea = All;
                Caption = 'Clear stop on error';
                ToolTip = 'Choosing this option will remove set stop on error, which means if the error occurs during this action job will log the error and proceed with other actions.';
                Image = Log;
                Enabled = EnableAction;

                trigger OnAction()
                begin
                    Rec."Stop on Error" := false;
                    Rec.Modify();
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetCurrentKey(Rec.Order);
        Rec.Ascending(true);
        UpdateReminderAction();
    end;

    local procedure SelectReminderAction(var ReminderActionCode: Code[50]; var NewEnumReminderAction: Enum "Reminder Action"): Interface "Reminder Action"
    var
        NewReminderActionPage: Page "New Reminder Action";
        SelectedReminderActionInterface: Interface "Reminder Action";
        ReminderActionIndex: Integer;
        SelectedReminderActionName: Text;
    begin
        foreach ReminderActionIndex in NewEnumReminderAction.Ordinals do
            NewReminderActionPage.AddItem(Format("Reminder Action".FromInteger(ReminderActionIndex)), '');

        NewReminderActionPage.LookupMode(true);
        if not (NewReminderActionPage.RunModal() in [Action::LookupOK, Action::OK]) then
            Error('');

        SelectedReminderActionName := NewReminderActionPage.GetSelectedAction();

        Evaluate(NewEnumReminderAction, SelectedReminderActionName);
        SelectedReminderActionInterface := NewEnumReminderAction;
        ReminderActionCode := NewReminderActionPage.GetActionId();
        exit(SelectedReminderActionInterface);
    end;

    procedure CreateNewReminderAction()
    var
        NewReminderAction: Record "Reminder Action";
    begin
        NewReminderAction."Reminder Action Group Code" := GetReminderActionGroupCode();
        NewReminderAction.Order := NewReminderAction.GetNextOrderNumber();

        ReminderAction := SelectReminderAction(NewReminderAction.Code, NewReminderAction.Type);
        if not ReminderAction.CreateNew(NewReminderAction.Code, NewReminderAction."Reminder Action Group Code") then
            Error('');

        Commit();
        ReminderAction.Setup();
        SummaryText := ReminderAction.GetSummary();
        NewReminderAction.Insert();
    end;

    trigger OnAfterGetRecord()
    begin
        UpdateReminderAction();
        SummaryText := ReminderAction.GetSummary();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateReminderAction();
    end;

    local procedure UpdateReminderAction()
    begin
        ReminderAction := Rec.GetReminderActionInterface();
    end;

    local procedure GetReminderActionGroupCode(): Code[50]
    var
        ReminderActionGroupCode: Code[50];
    begin
        Rec.FilterGroup(4);
        ReminderActionGroupCode := CopyStr(Rec.GetFilter("Reminder Action Group Code"), 1, MaxStrLen(ReminderActionGroupCode));
        Rec.FilterGroup(0);
        exit(ReminderActionGroupCode);
    end;

    internal procedure EnableActions()
    begin
        EnableAction := true;
        CurrPage.Update();
    end;

    var
        ReminderAction: Interface "Reminder Action";
        SummaryText: Text;
        EnableAction: Boolean;
}