// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Environment;

page 670 "Concurrent Session List"
{
    Caption = 'Concurrent Session List';
    Editable = false;
    PageType = List;
    ShowFilter = false;
    SourceTable = "Active Session";
    SourceTableView = where("Client Type" = filter(<> "Web Service" & <> "Management Client" & <> NAS & <> "Client Service"));

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(CurrentSession; IsCurrentSession())
                {
                    ApplicationArea = Suite;
                    Caption = 'Current Session';
                    ToolTip = 'Specifies if the line describes the current session.';
                }
                field("Session ID"; Rec."Session ID")
                {
                    ApplicationArea = Suite;
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = Suite;
                }
                field("Client Type"; Rec."Client Type")
                {
                    ApplicationArea = Suite;
                }
                field("Client Computer Name"; Rec."Client Computer Name")
                {
                    ApplicationArea = Suite;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        Rec.SetRange("Server Instance ID", ServiceInstanceId());
    end;

    local procedure IsCurrentSession(): Boolean
    begin
        exit(Rec."Session ID" = SessionId());
    end;
}

