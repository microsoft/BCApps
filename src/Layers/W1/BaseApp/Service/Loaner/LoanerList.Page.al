// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Loaner;

using Microsoft.Service.Comment;
using Microsoft.Service.Document;

page 5923 "Loaner List"
{
    ApplicationArea = Service;
    Caption = 'Loaners';
    CardPageID = "Loaner Card";
    Editable = false;
    PageType = List;
    SourceTable = Loaner;
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a description of the loaner.';
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies an additional description of the loaner.';
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
        area(creation)
        {
            action("New Service Order")
            {
                ApplicationArea = Service;
                Caption = 'New Service Order';
                Image = Document;
                RunObject = Page "Service Order";
                RunPageMode = Create;
                ToolTip = 'Create an order for specific service work to be performed on a customer''s item. ';
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(Receive)
                {
                    ApplicationArea = Service;
                    Caption = 'Receive';
                    Image = ReceiveLoaner;
                    ToolTip = 'Register that a loaner has been received back from the service customer.';

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
            group(Category_New)
            {
                Caption = 'New';

                actionref("New Service Order_Promoted"; "New Service Order")
                {
                }
            }
        }
    }
}

