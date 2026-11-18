// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item.Substitution;

pageextension 7330 "Item Substitution Entry Ext." extends "Item Substitution Entry"
{
    actions
    {
        addfirst(Prompting)
        {
            action("Suggest Substitution Prompting")
            {
                ApplicationArea = All;
                Caption = 'Suggest with Copilot';
                Image = SparkleFilled;
                ToolTip = 'Get item substitution suggestion from Copilot';
                Enabled = false;
                Visible = false;

                trigger OnAction()
                begin
                    ItemSubstDiscontNotif.SendNotification();
                end;
            }
        }
    }

    var
        ItemSubstDiscontNotif: Codeunit "Item Subst. Discont. Notif.";

    trigger OnOpenPage()
    begin
        ItemSubstDiscontNotif.SendNotification();
    end;
}