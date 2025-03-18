// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

/// <summary>
/// This page shows the database activity monitor setup.
/// </summary>
page 6283 "Database Act. Monitor Lines"
{
    PageType = ListPart;
    Caption = 'Database Activity Monitor Lines';
    SourceTable = "Database Act. Monitor Line";

    layout
    {
        area(Content)
        {
            repeater(MainGroup)
            {
                field("Table ID"; Rec."Table ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'The ID of the table';
                }
                field("Table Name"; Rec."Table Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'The name of the table';
                    Editable = false;
                }
                field("Table Caption"; Rec."Table Caption")
                {
                    ApplicationArea = All;
                    ToolTip = 'The caption of the table';
                    Editable = false;
                    Visible = false;
                }
                field("Log Delete"; "Log Delete")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether to log delete operations.';
                    Importance = Promoted;
                }
                field("Log Insert"; "Log Insert")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether to log insert operations.';
                    Importance = Promoted;
                }
                field("Log Modify"; "Log Modify")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether to log modify operations.';
                    Importance = Promoted;
                }
                field("Log Rename"; "Log Rename")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether to log rename operations.';
                    Importance = Promoted;
                }
            }
        }
    }
}