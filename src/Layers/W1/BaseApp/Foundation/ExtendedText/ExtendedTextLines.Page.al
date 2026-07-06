// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.ExtendedText;

page 387 "Extended Text Lines"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    LinksAllowed = false;
    MultipleNewLines = true;
    PageType = ListPart;
    SourceTable = "Extended Text Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Text; Rec.Text)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the text. You can use both numbers and letters. There are no restrictions as to the number of lines you can use.';
                }
            }
        }
    }

    actions
    {
    }
}

