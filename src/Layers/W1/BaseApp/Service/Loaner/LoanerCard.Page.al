// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Loaner;

using Microsoft.Service.Comment;

page 5922 "Loaner Card"
{
    Caption = 'Loaner Card';
    PageType = Card;
    RefreshOnActivate = true;
    SourceTable = Loaner;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Service;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Service;
                }
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = ItemTracking;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Service;
                }
                field(Lent; Rec.Lent)
                {
                    ApplicationArea = Service;
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Service;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Service;
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = Service;
                }
                field("Last Date Modified"; Rec."Last Date Modified")
                {
                    ApplicationArea = Service;
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
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("L&oaner")
            {
                Caption = 'L&oaner';
                Image = Loaners;
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Service Comment Sheet";
                    RunPageLink = "Table Name" = const(Loaner),
                                  "Table Subtype" = const("0"),
                                  "No." = field("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action("Loaner E&ntries")
                {
                    ApplicationArea = Service;
                    Caption = 'Loaner E&ntries';
                    Image = Entries;
                    RunObject = Page "Loaner Entries";
                    RunPageLink = "Loaner No." = field("No.");
                    RunPageView = sorting("Loaner No.")
                                  order(ascending);
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the history of the loaner.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("&Receive")
                {
                    ApplicationArea = Service;
                    Caption = '&Receive';
                    Image = ReceiveLoaner;
                    ToolTip = 'Record that the loaner is received at your company.';

                    trigger OnAction()
                    var
                        ServLoanerMgt: Codeunit ServLoanerManagement;
                    begin
                        ServLoanerMgt.Receive(Rec);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Receive_Promoted"; "&Receive")
                {
                }
            }
        }
    }
}

