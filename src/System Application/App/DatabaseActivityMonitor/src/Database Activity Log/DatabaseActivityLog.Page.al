// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

page 6280 "Database Activity Log"
{
    PageType = ListPart;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "Database Activity Log";
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(MainGroup)
            {
                field(SystemCreatedAt; Rec.SystemCreatedAt)
                {
                    ApplicationArea = All;
                    ToolTip = 'The date and time when the record was created';
                }
                field("Transaction Order"; Rec."Transaction Order")
                {
                    ToolTip = 'The order of the transaction';
                }
                field("Trigger Name"; Rec."Trigger Name")
                {
                    ToolTip = 'The name of the trigger';
                }
                field("Table ID"; Rec."Table ID")
                {
                    ToolTip = 'The ID of the table';
                }
                field("Table Name"; Rec."Table Name")
                {
                    ToolTip = 'The name of the table';
                }
                field("Publisher Name"; "Publisher Name")
                {
                    ToolTip = 'The name of the publisher';
                }
                field("App Name"; Rec."App Name")
                {
                    ToolTip = 'The name of the app';
                }
                field("Call Stack"; Rec."Call Stack")
                {
                    ToolTip = 'The callstack';

                    trigger OnDrillDown()
                    begin
                        Message(Rec."Call Stack");
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        CallstackTxt := Rec."Call Stack";
    end;

    var
        CallstackTxt: Text;
}
