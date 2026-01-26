// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Foundation.Navigate;
using Microsoft.Purchases.Vendor;

page 5005273 "Issued Delivery Reminder"
{
    Caption = 'Issued Delivery Reminder';
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Document;
    SourceTable = "Issued Deliv. Reminder Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                Editable = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the No. field on the delivery reminder header.';
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the vendor who you want to post a delivery reminder for.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the same field in the original delivery reminder.';
                }
                field(Address; Rec.Address)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the same field in the original delivery reminder.';
                }
                field("Address 2"; Rec."Address 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the same field in the original delivery reminder.';
                }
                field("Post Code"; Rec."Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Post Code/City';
                    ToolTip = 'Specifies the value of the same field in the original delivery reminder.';
                }
                field(City; Rec.City)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the same field in the original delivery reminder.';
                }
                field(Contact; Rec.Contact)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the same field in the original delivery reminder.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the same field in the original delivery reminder.';
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the value of the same field in the original delivery reminder.';
                }
                field("Pre-Assigned No."; Rec."Pre-Assigned No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the same field in the original delivery reminder.';
                }
                field("Reminder Level"; Rec."Reminder Level")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the value of the same field in the original delivery reminder.';
                }
                field("Reminder Terms Code"; Rec."Reminder Terms Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the same field in the original delivery reminder.';
                }
                field("No. Printed"; Rec."No. Printed")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how many times the delivery reminder has been printed.';
                }
            }
            part("Issued Delivery Reminder Lines"; "Issued Delivery Reminder Sub")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                SubPageLink = "Document No." = field("No.");
            }
        }
        area(factboxes)
        {
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
            group("&Reminder")
            {
                Caption = '&Reminder';
                Image = Reminder;
                action(Vendor)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendor';
                    Image = Vendor;
                    RunObject = Page "Vendor List";
                    RunPageLink = "No." = field("Vendor No.");
                    ToolTip = 'View or edit detailed information about the vendor on the reminder.';
                }
                action("Co&mments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Delivery Reminder Comment Line";
                    RunPageLink = "No." = field("No.");
                    RunPageView = sorting("Document Type", "No.", "Line No.")
                                  where("Document Type" = const("Issued Delivery Reminder"));
                    ToolTip = 'View or add comments for the record.';
                }
            }
        }
        area(processing)
        {
            action(PrintReport)
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                ToolTip = 'Prepare to print the document. The report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                var
                    PrintDocumentComfort: Codeunit "Print Document Comfort";
                begin
                    PrintDocumentComfort.IssuedDeliveryRemindPrint(Rec, true);
                end;
            }
            action(Navigate)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Find entries...';
                Image = Navigate;
                ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';

                trigger OnAction()
                begin
                    Navigate.SetDoc(Rec."Posting Date", Rec."No.");
                    Navigate.Run();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(PrintReport_Promoted; PrintReport)
                {
                }
                actionref(Navigate_Promoted; Navigate)
                {
                }
            }
        }
    }

    var
        Navigate: Page Navigate;
}

