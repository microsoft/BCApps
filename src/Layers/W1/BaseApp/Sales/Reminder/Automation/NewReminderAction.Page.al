// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using Microsoft.Utilities;

/// <summary>
/// Provides a dialog for creating new automation actions within a reminder action group.
/// </summary>
page 6750 "New Reminder Action"
{
    Caption = 'New Reminder Action';
    PageType = StandardDialog;
    SourceTable = "Name/Value Buffer";
    SourceTableTemporary = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    DataCaptionExpression = '';

    layout
    {
        area(content)
        {
            group(General)
            {
                ShowCaption = false;
                field(ActionId; ActionId)
                {
                    Caption = 'Code';
                    ApplicationArea = All;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the reminder action code.';

                    trigger OnValidate()
                    begin
                        GlobalActionId := ActionId;
                    end;
                }
            }
            repeater(Control1000)
            {
                Editable = false;
                ShowCaption = false;
                field(Name; Rec.Name)
                {
                    Caption = 'Reminder action type.';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the reminder action type.';
                }
            }
        }
    }

    /// <summary>
    /// Adds a new action type item to the list of available reminder actions.
    /// </summary>
    /// <param name="ItemName">The display name of the action type.</param>
    /// <param name="ItemValue">The value identifier of the action type.</param>
    procedure AddItem(ItemName: Text; ItemValue: Text)
    var
        NextID: Integer;
    begin
        Rec.LockTable();
        if Rec.FindLast() then
            NextID := Rec.ID + 1
        else
            NextID := 1;

        Rec.Init();
        Rec.ID := NextID;
        Rec.Name := CopyStr(ItemName, 1, MaxStrLen(Rec.Name));
        Rec.Value := CopyStr(ItemValue, 1, MaxStrLen(Rec.Value));
        Rec.Insert();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction in [CloseAction::Cancel, CloseAction::LookupCancel] then
            exit;

        if ActionId = '' then begin
            Message(MustProvideActionIDMsg);
            exit(false)
        end;

        SelectedAction := Rec.Name;
        exit(true);
    end;

    /// <summary>
    /// Gets the action code entered by the user.
    /// </summary>
    /// <returns>The action code value.</returns>
    procedure GetActionId(): Code[50]
    begin
        exit(GlobalActionId);
    end;

    /// <summary>
    /// Gets the name of the selected action type.
    /// </summary>
    /// <returns>The name of the selected action type.</returns>
    procedure GetSelectedAction(): Text
    begin
        exit(SelectedAction);
    end;

    trigger OnOpenPage()
    begin
        Rec.FindFirst();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        ActionId := GlobalActionId;
    end;

    var
        ActionId: Code[50];
        GlobalActionId: Code[50];
        SelectedAction: Text;
        MustProvideActionIDMsg: Label 'You must provide Code value.';
}

