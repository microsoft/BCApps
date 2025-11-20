// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

page 547 "Reminder Attach Ending Line"
{
    PageType = ListPart;
    SourceTable = "Reminder Attachment Text Line";
    Caption = 'Reminder Attachment Ending Text Line';
    Editable = true;
    AutoSplitKey = true;
    DelayedInsert = true;
    ModifyAllowed = true;
    DeleteAllowed = true;
    MultipleNewLines = true;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(Text; Rec.Text)
                {
                    Caption = 'Text';
                    ToolTip = 'Specifies the text of the reminder attachment ending line for the selected language.';
                    ApplicationArea = All;
                }
            }
        }
    }
}