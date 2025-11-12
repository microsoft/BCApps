// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

page 534 "Reminder Attach Beginning Line"
{
    PageType = ListPart;
    SourceTable = "Reminder Attachment Text Line";
    Caption = 'Reminder Attachment Beginning Text Line';
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
                    ToolTip = 'Specifies the text of the reminder attachment beginning line for the selected language.';
                    ApplicationArea = All;
                }
            }
        }
    }
}