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
                    ToolTip = 'Specifies the part of the contract that was changed.';
                }
                field("Type of Change"; Rec."Type of Change")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the type of change on the contract.';
                }
                field("Field Description"; Rec."Field Description")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the description of the field that was modified.';
                }
                field("New Value"; Rec."New Value")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the contents of the modified field after the change has taken place.';
                }
                field("Old Value"; Rec."Old Value")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the contents of the modified field before the change takes place.';
                }
                field("Date of Change"; Rec."Date of Change")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date of the change.';
                }
                field("Service Item No."; Rec."Service Item No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the item on the service contract line, for which a log entry was created.';
                }
                field("Serv. Contract Line No."; Rec."Serv. Contract Line No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the service contract line for which a log entry was created.';
                }
                field("Time of Change"; Rec."Time of Change")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the time of the change.';
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';

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

