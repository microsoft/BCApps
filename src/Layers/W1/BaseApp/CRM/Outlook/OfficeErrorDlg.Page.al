// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Outlook;

page 1608 "Office Error Dlg"
{
    Caption = 'Something went wrong';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    ShowFilter = false;

    layout
    {
        area(content)
        {
            label(Control3)
            {
                Editable = false;
                Enabled = false;
                HideValue = true;
                ShowCaption = false;
                Caption = '';
            }
            field(ErrorText; ErrorText)
            {
                ApplicationArea = All;
                Editable = false;
                Enabled = false;
                MultiLine = true;
                ShowCaption = false;
                ToolTip = 'Specifies the text you enter that applies to the error.';
            }
        }
    }

    actions
    {
    }

    trigger OnInit()
    var
        OfficeErrorEngine: Codeunit "Office Error Engine";
    begin
        ErrorText := OfficeErrorEngine.GetError();
    end;

    var
        ErrorText: Text;
}

