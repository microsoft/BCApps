// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Automation;

page 1536 "Dynamic Request Page Fields"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Dynamic Request Page Fields';
    PageType = List;
    SourceTable = "Dynamic Request Page Field";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Table ID"; Rec."Table ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the table for the field that the workflow event condition applies to.';
                }
                field("Table Name"; Rec."Table Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the table for the field that the workflow event condition applies to.';
                    Visible = false;
                }
                field("Table Caption"; Rec."Table Caption")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the caption of the table for the field that the workflow event condition applies to.';
                }
                field("Field ID"; Rec."Field ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the field that the workflow event condition applies to.';
                }
                field("Field Name"; Rec."Field Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the field that the workflow event condition applies to.';
                    Visible = false;
                }
                field("Field Caption"; Rec."Field Caption")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the caption of the field that the workflow event condition applies to.';
                }
            }
        }
    }

    actions
    {
    }
}

