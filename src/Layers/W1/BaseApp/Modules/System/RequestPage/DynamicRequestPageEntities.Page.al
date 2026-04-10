// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Automation;

page 1535 "Dynamic Request Page Entities"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Dynamic Request Page Entities';
    PageType = List;
    SourceTable = "Dynamic Request Page Entity";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the workflow event condition.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the workflow event condition.';
                }
                field("Table ID"; Rec."Table ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the table that the workflow event condition applies to.';
                }
                field("Table Name"; Rec."Table Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the table that the workflow event condition applies to.';
                    Visible = false;
                }
                field("Table Caption"; Rec."Table Caption")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the caption of the table that the workflow event condition applies to.';
                }
                field("Related Table ID"; Rec."Related Table ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the table that the workflow event condition applies to.';
                }
                field("Related Table Name"; Rec."Related Table Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the related table that the workflow event condition applies to.';
                    Visible = false;
                }
                field("Related Table Caption"; Rec."Related Table Caption")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the caption of the related table that the workflow event condition applies to.';
                }
                field("Sequence No."; Rec."Sequence No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the order of approvers when an approval workflow involves more than one approver.';
                }
            }
        }
    }

    actions
    {
    }
}

