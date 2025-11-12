// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Loaner;

using Microsoft.Service.Comment;
using Microsoft.Service.Document;

page 5921 "Available Loaners"
{
    Caption = 'Available Loaners';
    PageType = List;
    SourceTable = Loaner;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                Editable = false;
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the serial number for the loaner for the service item.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a description of the loaner.';
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = Comments;
                    ToolTip = 'Specifies that there is a comment for this loaner.';
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
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
                action(Card)
                {
                    ApplicationArea = Service;
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Page "Loaner Card";
                    RunPageLink = "No." = field("No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the record on the document or journal line.';
                }
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Service Comment Sheet";
                    RunPageLink = "Table Name" = const(Loaner),
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
                action(Receive)
                {
                    ApplicationArea = Service;
                    Caption = 'Receive';
                    Image = ReceiveLoaner;
                    ToolTip = 'Register that a loaner has been received back from the service customer.';

                    trigger OnAction()
                    var
                        LoanerEntry: Record "Loaner Entry";
                        ServItemLine: Record "Service Item Line";
                        ServLoanerMgt: Codeunit ServLoanerManagement;
                    begin
                        if Rec.Lent then begin
                            Clear(LoanerEntry);
                            LoanerEntry.SetCurrentKey("Document Type", "Document No.", "Loaner No.", Lent);
                            LoanerEntry.SetRange("Document Type", Rec."Document Type");
                            LoanerEntry.SetRange("Document No.", Rec."Document No.");
                            LoanerEntry.SetRange("Loaner No.", Rec."No.");
                            LoanerEntry.SetRange(Lent, true);
                            if LoanerEntry.FindFirst() then begin
                                ServItemLine.Get(LoanerEntry.GetServDocTypeFromDocType(), LoanerEntry."Document No.", LoanerEntry."Service Item Line No.");
                                ServLoanerMgt.ReceiveLoaner(ServItemLine);
                            end;
                        end else
                            Error(Text000, Rec.TableCaption(), Rec."No.");
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetRange(Blocked, false);
        Rec.SetRange(Lent, false);
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'You cannot receive %1 %2 because it has not been lent.', Comment = 'You cannot receive Loaner L00001 because it has not been lent.';
#pragma warning restore AA0470
#pragma warning restore AA0074
}

