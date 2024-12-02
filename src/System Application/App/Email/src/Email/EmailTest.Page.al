// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Email;
using System;

page 8911 "Email Test"
{
    PageType = Card;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field(Input; Input)
            {
                ApplicationArea = All;
                Caption = 'Input';
                ToolTip = 'Specifies the input';
            }
            field(Output; Output)
            {
                ApplicationArea = All;
                Caption = 'Output';
                ToolTip = 'Specifies the output';
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(StripHTML)
            {
                ApplicationArea = All;
                Caption = 'Strip HTML';
                ToolTip = 'Strip HTML tags from the input';
                Image = Action;

                trigger OnAction()
                var
                    AppHtmlSanitizer: DotNet AppHtmlSanitizer;
                begin
                    AppHtmlSanitizer := AppHtmlSanitizer.AppHtmlSanitizer();
                    Output := AppHtmlSanitizer.SanitizeEmail(Input);
                end;
            }
        }
    }

    var
        Input: Text;
        Output: Text;
}
