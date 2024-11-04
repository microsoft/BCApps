// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Upgrade;
page 9998 "Upgrade Tags"
{
    PageType = List;
    ApplicationArea = All;
    Caption = 'Upgrade Tags';
    UsageCategory = Lists;
    SourceTable = "Upgrade Tags";
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(Tag; Rec.Tag) { }
                field("Tag Timestamp"; Rec."Tag Timestamp") { }
                field(Company; Rec.Company) { }
            }
        }
    }
}