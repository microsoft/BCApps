// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Outlook;

page 1609 "Office Welcome Dlg"
{
    Caption = 'Welcome!';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    ShowFilter = false;

    layout
    {
        area(content)
        {
            group(Control2)
            {
                Caption = '';
                Editable = false;
                Enabled = false;
                label(InboxWelcomeMessage)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Welcome to your business inbox in Outlook.';
                    Editable = false;
                    Enabled = false;
                    HideValue = true;
                    ShowCaption = true;
                    ToolTip = 'Specifies a welcome message, related to your business inbox in Outlook.';
                }
                label(InboxHelpMessage)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Your business inbox in Outlook shows business data based on your contacts. Open one of the two evaluation email messages that we sent to your inbox, and then open the add-in again.';
                    Editable = false;
                    Enabled = false;
                    HideValue = true;
                    ShowCaption = true;
                    ToolTip = 'Specifies a description of your business inbox in Outlook.';
                }
            }
        }
    }

    actions
    {
    }
}

