// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Archive;

using Microsoft.Foundation.Reporting;
using System.Security.User;

page 6625 "Blanket Purch. Order Archives"
{
    ApplicationArea = Suite;
    Caption = 'Blanket Purchase Order Archives';
    CardPageID = "Blanket Purchase Order Archive";
    Editable = false;
    PageType = List;
    SourceTable = "Purchase Header Archive";
    SourceTableView = where("Document Type" = const("Blanket Order"));
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Control29)
            {
                ShowCaption = false;
                field("Version No."; Rec."Version No.")
                {
                    ApplicationArea = Suite;
                }
                field("Date Archived"; Rec."Date Archived")
                {
                    ApplicationArea = Suite;
                }
                field("Time Archived"; Rec."Time Archived")
                {
                    ApplicationArea = Suite;
                }
                field("Archived By"; Rec."Archived By")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the user who archived the document.';

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation(Rec."Archived By");
                    end;
                }
                field("Interaction Exist"; Rec."Interaction Exist")
                {
                    ApplicationArea = RelationshipMgmt;
                }
                field("Buy-from Vendor No."; Rec."Buy-from Vendor No.")
                {
                    ApplicationArea = Suite;
                }
                field("Order Address Code"; Rec."Order Address Code")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Buy-from Vendor Name"; Rec."Buy-from Vendor Name")
                {
                    ApplicationArea = Suite;
                }
                field("Vendor Authorization No."; Rec."Vendor Authorization No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the compensation agreement identification number, sometimes referred to as the RMA No. (Returns Materials Authorization).';
                }
                field("Buy-from Post Code"; Rec."Buy-from Post Code")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Buy-from Country/Region Code"; Rec."Buy-from Country/Region Code")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Buy-from Contact"; Rec."Buy-from Contact")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Pay-to Vendor No."; Rec."Pay-to Vendor No.")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Pay-to Name"; Rec."Pay-to Name")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Pay-to Post Code"; Rec."Pay-to Post Code")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Pay-to Country/Region Code"; Rec."Pay-to Country/Region Code")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Pay-to Contact"; Rec."Pay-to Contact")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Ship-to Code"; Rec."Ship-to Code")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Ship-to Name"; Rec."Ship-to Name")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the name of the company at the address to which the items were shipped.';
                    Visible = false;
                }
                field("Ship-to Post Code"; Rec."Ship-to Post Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the postal code of the address.';
                    Visible = false;
                }
                field("Ship-to Country/Region Code"; Rec."Ship-to Country/Region Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the country/region code of the address.';
                    Visible = false;
                }
                field("Ship-to Contact"; Rec."Ship-to Contact")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the name of a contact person at the address that the items were shipped to.';
                    Visible = false;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the date when the document was posted.';
                    Visible = false;
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    Visible = true;
                }
                field("Purchaser Code"; Rec."Purchaser Code")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the currency code for the amount on the line.';
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control35; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control34; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Print)
            {
                ApplicationArea = Suite;
                Caption = 'Print';
                Image = Print;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                var
                    DocPrint: Codeunit "Document-Print";
                begin
                    DocPrint.PrintPurchHeaderArch(Rec);
                end;
            }
            action(Comments)
            {
                ApplicationArea = Comments;
                Caption = 'Comments';
                Image = ViewComments;
                RunObject = Page "Purch. Archive Comment Sheet";
                RunPageLink = "Document Type" = const("Blanket Order");
                ToolTip = 'View or add comments for the record.';
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
                actionref(Comments_Promoted; Comments)
                {
                }
            }
        }
    }
}

