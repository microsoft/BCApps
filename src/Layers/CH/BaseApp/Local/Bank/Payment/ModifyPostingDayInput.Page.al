// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

page 35561 "Modify Posting Day Input"
{
    Caption = 'Modify Posting Day Input';
    PageType = Card;

    layout
    {
        area(content)
        {
            group(Control1150008)
            {
                ShowCaption = false;
                label(Control1150000)
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = Text19009817;
                    ShowCaption = false;
                }
                field(NewPostingDate; NewPostingDate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'New Date';
                    ToolTip = 'Specifies the new credit date that you enter by using the value suggested during the LSV collection.';
                }
            }
        }
    }

    actions
    {
    }

    var
        NewPostingDate: Date;
        Text19009817: Label 'Modify Posting Date';

    [Scope('OnPrem')]
    procedure SetNewPostingDate(var PDate: Date)
    begin
        NewPostingDate := PDate;
    end;

    [Scope('OnPrem')]
    procedure GetNewPostingDate(var PDate: Date)
    begin
        PDate := NewPostingDate;
    end;
}

