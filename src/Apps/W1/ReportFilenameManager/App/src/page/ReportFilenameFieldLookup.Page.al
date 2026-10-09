// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
page 50116 "Report Filename Field Lookup"
{
    // Picks which field on the document holds its language, by caption. The pattern stores the
    // field number, because a number survives a rename and a translation where a name does
    // not - but the number never appears on a page. It lists only fields that relate to the
    // Language table, so it no longer says which table each field relates to: it is always that.

    Caption = 'Fields';
    PageType = List;
    ApplicationArea = All;
    SourceTable = Field;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Fields)
            {
                field("Field Caption"; Rec."Field Caption")
                {
                    Caption = 'Field';
                    ToolTip = 'Specifies the field on the record.';
                    ApplicationArea = All;
                }
            }
        }
    }
}
