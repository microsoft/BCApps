// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.History;

using Microsoft.Foundation.Reporting;
using Microsoft.Inventory.Counting.Comment;
using Microsoft.Inventory.Counting.Reports;

page 5883 "Posted Phys. Invt. Order"
{
    ApplicationArea = Warehouse;
    Caption = 'Posted Phys. Invt. Order';
    InsertAllowed = false;
    PageType = Document;
    SourceTable = "Pstd. Phys. Invt. Order Hdr";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    ToolTip = 'Specifies the No. of the table physical inventory order header.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    ToolTip = 'Specifies the Description of the table physical inventory order header.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the Location Code of the table physical inventory order header.';
                }
                field("Person Responsible"; Rec."Person Responsible")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    ToolTip = 'Specifies the Person Responsible of the table physical inventory order header.';
                }
                field("No. Finished Recordings"; Rec."No. Finished Recordings")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    ToolTip = 'Specifies the No. Finished Recordings.';
                }
                field("Order Date"; Rec."Order Date")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    ToolTip = 'Specifies the Order Date of the table physical inventory order header.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    ToolTip = 'Specifies the Posting Date of the table physical inventory order header.';
                }
                field("Pre-Assigned No."; Rec."Pre-Assigned No.")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    ToolTip = 'Specifies the number of the physical inventory header, from which the posted physical inventory order was posted.';
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
            }
            part(OrderLines; "Posted Phys. Invt. Order Subf.")
            {
                ApplicationArea = Warehouse;
                SubPageLink = "Document No." = field("No.");
                SubPageView = sorting("Document No.", "Line No.");
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("O&rder")
            {
                Caption = 'O&rder';
                Image = "Order";
                action(Statistics)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Statistics';
                    Image = Statistics;
                    RunObject = Page "Posted Phys. Invt. Order Stat.";
                    RunPageLink = "No." = field("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'Show statistics.';
                }
                action("Co&mments")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Phys. Inventory Comment Sheet";
                    RunPageLink = "Document Type" = const("Posted Order"),
                                  "Order No." = field("No."),
                                  "Recording No." = const(0);
                    ToolTip = 'Show comments.';
                }
                action("&Recordings")
                {
                    ApplicationArea = Warehouse;
                    Caption = '&Recordings';
                    Image = Document;
                    RunObject = Page "Posted Phys. Invt. Rec. List";
                    RunPageLink = "Order No." = field("No.");
                    RunPageView = sorting("Order No.", "Recording No.");
                    ToolTip = 'Show recordings.';
                }
                action(Dimensions)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'Show dimensions.';

                    trigger OnAction()
                    begin
                        Rec.ShowDimensions();
                    end;
                }
            }
        }
        area(processing)
        {
            action(Print)
            {
                ApplicationArea = Warehouse;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                ToolTip = 'Print order.';

                trigger OnAction()
                var
                    DocPrint: Codeunit "Document-Print";
                begin
                    DocPrint.PrintPostedInvtOrder(Rec, true);
                end;
            }
            action("&Navigate")
            {
                ApplicationArea = Warehouse;
                Caption = 'Find entries...';
                Image = Navigate;
                ShortCutKey = 'Ctrl+Alt+Q';
                ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';

                trigger OnAction()
                begin
                    Rec.Navigate();
                end;
            }
        }
        area(reporting)
        {
            action("Posted Phys. Invt. Order Diff.")
            {
                ApplicationArea = Warehouse;
                Caption = 'Posted Phys. Invt. Order Diff.';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Posted Phys. Invt. Order Diff.";
                ToolTip = 'View or print the list of differences after counting.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Print_Promoted; Print)
                {
                }
                actionref("&Navigate_Promoted"; "&Navigate")
                {
                }
                actionref(Statistics_Promoted; Statistics)
                {
                }
            }
        }
    }
}

