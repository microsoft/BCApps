// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

page 149037 "AIT Log Entries Part"
{
    Caption = 'AI Log Entries';
    PageType = ListPart;
    ApplicationArea = All;
    Editable = false;
    SourceTable = "AIT Log Entry";
    Extensible = false;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                FreezeColumn = Status;

                field(CodeunitID; Rec."Codeunit ID")
                {
                }
                field(CodeunitName; Rec."Codeunit Name")
                {
                }
                field("Procedure Name"; Rec."Procedure Name")
                {
                }
                field(Status; Rec.Status)
                {
                    StyleExpr = StatusStyleExpr;
                }
                field(Message; ErrorMessage)
                {
                    Caption = 'Error Message';
                    ToolTip = 'Specifies the error message from the test.';
                    Style = Unfavorable;

                    trigger OnDrillDown()
                    begin
                        Message(ErrorMessage);
                    end;
                }
                field("Error Call Stack"; ErrorCallStack)
                {
                    Caption = 'Call stack';
                    Editable = false;
                    ToolTip = 'Specifies the call stack for this error.';

                    trigger OnDrillDown()
                    begin
                        Message(ErrorCallStack);
                    end;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action("Log Entries")
            {
                Caption = 'Log Entries';
                Image = Entries;
                ToolTip = 'Open log entries.';
                RunObject = page "AIT Log Entries";
                RunPageLink = "Test Suite Code" = field("Test Suite Code"), Version = field(Version);
            }
        }
    }

    var
        ErrorMessage: Text;
        ErrorCallStack: Text;
        StatusStyleExpr: Text;

    trigger OnOpenPage()
    begin
        Rec.SetFilterForFailedTestProcedures();
    end;

    trigger OnAfterGetRecord()
    var
        AITLogEntryCU: Codeunit "AIT Log Entry";
    begin
        AITLogEntryCU.SetErrorFields(Rec, ErrorMessage, ErrorCallStack);
        AITLogEntryCU.SetStatusStyleExpr(Rec, StatusStyleExpr);
    end;
}