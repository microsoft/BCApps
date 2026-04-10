// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Contract;

using System.Security.User;

page 6063 "Contract Change Log"
{
    Caption = 'Contract Change Log';
    DataCaptionExpression = GetCaption();
    Editable = false;
    PageType = List;
    SourceTable = "Contract Change Log";
    SourceTableView = sorting("Contract No.", "Change No.")
                      order(descending);

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Contract Part"; Rec."Contract Part")
                {
                    ApplicationArea = Service;
                }
                field("Type of Change"; Rec."Type of Change")
                {
                    ApplicationArea = Service;
                }
                field("Field Description"; Rec."Field Description")
                {
                    ApplicationArea = Service;
                }
                field("New Value"; Rec."New Value")
                {
                    ApplicationArea = Service;
                }
                field("Old Value"; Rec."Old Value")
                {
                    ApplicationArea = Service;
                }
                field("Date of Change"; Rec."Date of Change")
                {
                    ApplicationArea = Service;
                }
                field("Service Item No."; Rec."Service Item No.")
                {
                    ApplicationArea = Service;
                }
                field("Serv. Contract Line No."; Rec."Serv. Contract Line No.")
                {
                    ApplicationArea = Service;
                }
                field("Time of Change"; Rec."Time of Change")
                {
                    ApplicationArea = Service;
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = Service;

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation(Rec."User ID");
                    end;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }

    local procedure GetCaption(): Text
    var
        ServContract: Record "Service Contract Header";
    begin
        if not ServContract.Get(Rec."Contract Type", Rec."Contract No.") then
            exit(StrSubstNo('%1', Rec."Contract No."));

        exit(StrSubstNo('%1 %2', Rec."Contract No.", ServContract.Description));
    end;
}

