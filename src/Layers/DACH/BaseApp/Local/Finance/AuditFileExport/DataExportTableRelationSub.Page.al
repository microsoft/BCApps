// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AuditFileExport;

page 11008 "Data Export Table Relation Sub"
{
    Caption = 'Data Export Table Relationships';
    DelayedInsert = true;
    PageType = ListPart;
    PopulateAllFields = true;
    SourceTable = "Data Export Table Relation";

    layout
    {
        area(content)
        {
            repeater(Control1140000)
            {
                ShowCaption = false;
                field("From Field No."; Rec."From Field No.")
                {
                    ApplicationArea = Basic, Suite;
                    LookupPageID = "Data Export Field List";
                    ToolTip = 'Specifies the number of the field, in the parent table, that forms the table relationship.';
                }
                field("From Field Name"; Rec."From Field Name")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    Lookup = false;
                    ToolTip = 'Specifies the name of the field that you selected in the From Field No. field.';
                }
                field("To Field No."; Rec."To Field No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the field in the indented table that forms the table relationship.';
                }
                field("To Field Name"; Rec."To Field Name")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    Lookup = false;
                    ToolTip = 'Specifies the name of the field that you selected in the To Field No. field.';
                }
            }
        }
    }

    actions
    {
    }
}

