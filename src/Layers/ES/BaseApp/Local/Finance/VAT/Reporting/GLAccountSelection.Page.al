// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.GeneralLedger.Account;

page 10734 "G/L Account Selection"
{
    Caption = 'G/L Account Selection';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Worksheet;
    SourceTable = "G/L Account Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1100000)
            {
                ShowCaption = false;
                field("Include G/L Acc. in 347"; Rec."Include G/L Acc. in 347")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Include G/L Acc. in Cash';
                    ToolTip = 'Specifies if the account is includes in report 347.';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies if the number of the account.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies if the name of the account.';
                }
            }
        }
    }

    actions
    {
    }

    [Scope('OnPrem')]
    procedure GetGLAccSelBuf(var TheGLAccSelectionBuf: Record "G/L Account Buffer")
    begin
        TheGLAccSelectionBuf.DeleteAll();
        if Rec.Find('-') then
            repeat
                TheGLAccSelectionBuf := Rec;
                TheGLAccSelectionBuf.Insert();
            until Rec.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure InsertGLAccSelBuf(NewSelected: Boolean; NewNo: Code[20]; NewName: Text[100])
    var
        GLAccount: Record "G/L Account";
    begin
        if NewName = '' then
            if GLAccount.Get(NewNo) then
                NewName := GLAccount.Name;

        Rec.Init();
        Rec."Include G/L Acc. in 347" := NewSelected;
        Rec."No." := NewNo;
        Rec.Name := NewName;
        Rec.Insert();
    end;
}

