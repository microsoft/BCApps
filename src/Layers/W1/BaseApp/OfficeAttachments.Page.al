// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#pragma warning disable AA0247
page 2021 "Office Attachments"
{
    Caption = 'Office Attachments';
    DataCaptionExpression = PageCaptionTxt;
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = StandardDialog;
    SourceTable = "Exchange Object";
    SourceTableTemporary = true;
    SourceTableView = sorting(Name)
                      order(ascending);

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Selected; Rec.Selected)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Attach';
                    ToolTip = 'Select';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Name';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        if Rec.Count = 1 then begin
            Rec.Selected := true;
            Rec.Modify();
        end
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction in [Action::OK, Action::LookupOK] then
            onSave();
    end;

    local procedure onSave(): Boolean
    begin
        Rec.SetRange(Selected, true);
        if Rec.FindSet() then begin
            repeat
                OfficeMgt.SendToAttachments(Rec);
            until Rec.Next() = 0;
            OfficeMgt.DisplaySuccessMessage(Rec);
        end;
    end;

    var
        OfficeMgt: Codeunit "Office Management";
        PageCaptionTxt: Label 'Select Attachment to Send';
}

