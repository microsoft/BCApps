// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Upgrade;
page 9998 PageName
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
                field(Tag; rec.Tag) { }
                field("Tag Timestamp"; rec."Tag Timestamp") { }
                field(Company; rec.Company) { }
            }
        }
    }
}