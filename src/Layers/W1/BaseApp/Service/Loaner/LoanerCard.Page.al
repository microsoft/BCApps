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
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';

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
                    ToolTip = 'Specifies a description of the loaner.';
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies an additional description of the loaner.';
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the unit price of the loaner.';
                }
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the serial number for the loaner for the service item.';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field(Lent; Rec.Lent)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that the loaner has been lent to a customer.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the document type of the loaner entry.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the service document for the service item that was lent.';
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
                }
                field("Last Date Modified"; Rec."Last Date Modified")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when the loaner card was last modified.';
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

