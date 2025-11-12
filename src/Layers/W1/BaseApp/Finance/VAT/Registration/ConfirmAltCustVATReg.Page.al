// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Registration;

using System.Diagnostics;

page 205 "Confirm Alt. Cust. VAT Reg."
{
    DataCaptionExpression = '';
    Caption = 'Confirm Alternative Customer VAT Registration';
    PageType = StandardDialog;
    InsertAllowed = false;
    DeleteAllowed = false;
    LinksAllowed = false;
    SourceTable = "Change Log Entry";
    SourceTableTemporary = true;
    Extensible = false;

    layout
    {
        area(Content)
        {
            label(ConfirmationLbl)
            {
                ApplicationArea = Basic, Suite;
                CaptionClass = Format(InstructionText);
                Editable = false;
                ShowCaption = false;
            }
            repeater(Details)
            {
                Caption = 'Details';
                Editable = false;
                field("Field Caption"; Rec."Field Caption")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Field';
                }
                field(OldValue; Rec."Old Value")
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = Format(OldValueCaption);
                    StyleExpr = true;
                    Style = Strong;

                }
                field(NewValue; Rec."New Value")
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = Format(NewValueCaption);
                }
            }
            field(DontShowAgainField; DontShowAgain)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Don''t show again';
                ToolTip = 'If you select this option, the confirmation will not be shown again.';
            }
        }
    }

    var
        DontShowAgain: Boolean;
        InstructionText, OldValueCaption, NewValueCaption : Text;

    procedure SetUIControls(NewInstructionText: Text; NewOldValueCaption: Text; NewNewValueCaption: Text)
    begin
        InstructionText := NewInstructionText;
        OldValueCaption := NewOldValueCaption;
        NewValueCaption := NewNewValueCaption;
    end;

    procedure SetSource(var TempChangeLogEntry: Record "Change Log Entry" temporary)
    begin
        if not TempChangeLogEntry.FindSet() then
            exit;
        repeat
            Rec := TempChangeLogEntry;
            Rec.Insert();
        until TempChangeLogEntry.Next() = 0;
    end;

    procedure DontShowAgainOptionSelected(): Boolean
    begin
        exit(DontShowAgain);
    end;
}
