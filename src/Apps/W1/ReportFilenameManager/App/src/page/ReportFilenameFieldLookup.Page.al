// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting.FileNaming;

using System.Reflection;

page 8131 "Report Filename Field Lookup"
{
    // Picks the document's language field by caption. The pattern stores the field number, which
    // survives renames and translations. Only fields related to the Language table are listed.

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
