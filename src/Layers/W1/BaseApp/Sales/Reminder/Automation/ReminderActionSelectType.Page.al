// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using Microsoft.Utilities;

/// <summary>
/// Displays a list of available action types for selection when adding a new reminder automation action.
/// </summary>
page 6751 "Reminder Action Select Type"
{
    Caption = 'Select action type';
    Editable = false;
    PageType = List;
    SourceTable = "Name/Value Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1000)
            {
                ShowCaption = false;
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name.';
                }
            }
        }
    }

    /// <summary>
    /// Adds an action type item to the list for selection.
    /// </summary>
    /// <param name="ItemName">The display name of the action type.</param>
    /// <param name="ItemValue">The value identifier of the action type.</param>
    procedure AddItem(ItemName: Text[250]; ItemValue: Text[250])
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
        Rec.Name := ItemName;
        Rec.Value := ItemValue;
        Rec.Insert();
    end;
}
