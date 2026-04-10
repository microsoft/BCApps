// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

using Microsoft.Finance.Dimension;
using Microsoft.Utilities;

/// <summary>
/// Lists all posted sales return receipt lines across documents for analysis and lookup.
/// </summary>
page 6663 "Posted Return Receipt Lines"
{
    Caption = 'Posted Return Receipt Lines';
    Editable = false;
    PageType = List;
    SourceTable = "Return Receipt Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = SalesReturnOrder;
                }
                field("Sell-to Customer No."; Rec."Sell-to Customer No.")
                {
                    ApplicationArea = SalesReturnOrder;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = SalesReturnOrder;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = SalesReturnOrder;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = SalesReturnOrder;
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = All;
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
                    ApplicationArea = SalesReturnOrder;
                    Visible = true;
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = SalesReturnOrder;
                    Visible = false;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = SalesReturnOrder;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = SalesReturnOrder;
                }
                field("Unit of Measure"; Rec."Unit of Measure")
                {
                    ApplicationArea = SalesReturnOrder;
                    Visible = false;
                }
                field("Appl.-to Item Entry"; Rec."Appl.-to Item Entry")
                {
                    ApplicationArea = SalesReturnOrder;
                    Visible = false;
                }
                field("Quantity Invoiced"; Rec."Quantity Invoiced")
                {
                    ApplicationArea = SalesReturnOrder;
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
        area(navigation)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action("Show Document")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Show Document';
                    Image = View;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'Open the document that the selected line exists on.';

                    trigger OnAction()
                    var
                        ReturnRcptHeader: Record "Return Receipt Header";
                        PageManagement: Codeunit "Page Management";
                    begin
                        ReturnRcptHeader.Get(Rec."Document No.");
                        PageManagement.PageRun(ReturnRcptHeader);
                    end;
                }
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowDimensions();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Show Document_Promoted"; "Show Document")
                {
                }
                actionref(Dimensions_Promoted; Dimensions)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetSecurityFilterOnRespCenter();
    end;
}

