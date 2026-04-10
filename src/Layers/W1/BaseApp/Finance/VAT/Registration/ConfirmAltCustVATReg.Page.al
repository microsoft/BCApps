// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Registration;

using System.Diagnostics;

/// <summary>
/// Confirmation dialog for alternative customer VAT registration number changes.
/// Displays change log details and allows user confirmation for VAT registration updates with option to suppress future notifications.
/// </summary>
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

    /// <summary>
    /// Configures the dialog display with custom instruction text and column captions.
    /// </summary>
    /// <param name="NewInstructionText">Instruction text to display to user</param>
    /// <param name="NewOldValueCaption">Caption for old value column</param>
    /// <param name="NewNewValueCaption">Caption for new value column</param>
    procedure SetUIControls(NewInstructionText: Text; NewOldValueCaption: Text; NewNewValueCaption: Text)
    begin
        InstructionText := NewInstructionText;
        OldValueCaption := NewOldValueCaption;
        NewValueCaption := NewNewValueCaption;
    end;

    /// <summary>
    /// Populates the dialog with change log entries from temporary table.
    /// </summary>
    /// <param name="TempChangeLogEntry">Temporary change log entries to display</param>
    procedure SetSource(var TempChangeLogEntry: Record "Change Log Entry" temporary)
    begin
        if not TempChangeLogEntry.FindSet() then
            exit;
        repeat
            Rec := TempChangeLogEntry;
            Rec.Insert();
        until TempChangeLogEntry.Next() = 0;
    end;

    /// <summary>
    /// Returns whether user selected the option to not show this dialog again.
    /// </summary>
    /// <returns>True if user checked the "Don't show again" option</returns>
    procedure DontShowAgainOptionSelected(): Boolean
    begin
        exit(DontShowAgain);
    end;
}
