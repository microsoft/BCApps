// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.History;

using Microsoft.Inventory.Comment;

page 6567 "Posted Invt. Receipt"
{
    Caption = 'Posted Invt. Receipt';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Document;
    SourceTable = "Invt. Receipt Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Posting Description"; Rec."Posting Description")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    Editable = false;
                }
                field("Gen. Bus. Posting Group"; Rec."Gen. Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Purchaser Code"; Rec."Purchaser Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field(Correction; Rec.Correction)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
            }
            part(ReceiptLines; "Posted Invt. Receipt Subform")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Document No." = field("No.");
            }
            group(Control1900309501)
            {
                Caption = 'Dimensions';
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                }
            }
            group(Statistics)
            {
                Caption = 'Statistics';
                field(LineQty; LineQty)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 0;
                    Caption = 'Quantity';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies how many pieces of the item are processed.';
                }
                field(TotalParcels; TotalParcels)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 0;
                    Caption = 'Parcels';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the total number of parcels in the document.';
                }
                field(TotalNetWeight; TotalNetWeight)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 0;
                    Caption = 'Net Weight';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the net weight of the item. You may need the net weight to complete customs documents, waybills, and other forms.';
                }
                field(TotalGrossWeight; TotalGrossWeight)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 0;
                    Caption = 'Gross Weight';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the gross weight, including the weight of any packaging, of the catalog item.';
                }
                field(TotalVolume; TotalVolume)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 0;
                    Caption = 'Volume';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the total volume of the items in the document.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Receipt")
            {
                Caption = '&Receipt';
                Image = Receipt;
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Inventory Comment Sheet";
                    RunPageLink = "Document Type" = const("Posted Inventory Receipt"),
                                  "No." = field("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action(Dimensions)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to journal lines to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowDimensions();
                        CurrPage.Update();
                    end;
                }
            }
        }
        area(processing)
        {
            action("&Print")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                var
                    InvtRcptHeader: Record "Invt. Receipt Header";
                begin
                    InvtRcptHeader := Rec;
                    CurrPage.SetSelectionFilter(InvtRcptHeader);
                    InvtRcptHeader.PrintRecords(true);
                end;
            }
            action("&Navigate")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Find entries...';
                Image = Navigate;
                ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';

                trigger OnAction()
                begin
                    Rec.Navigate();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Print_Promoted"; "&Print")
                {
                }
                actionref("&Navigate_Promoted"; "&Navigate")
                {
                }
            }
            group(Category_Receipt)
            {
                Caption = 'Receipt';

                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        CalcTotals();
    end;

    var
        LineQty: Decimal;
        TotalNetWeight: Decimal;
        TotalGrossWeight: Decimal;
        TotalVolume: Decimal;
        TotalParcels: Decimal;

    procedure CalcTotals()
    var
        InvtRcptLine: Record "Invt. Receipt Line";
    begin
        ClearAll();

        InvtRcptLine.SetRange("Document No.", Rec."No.");
        if InvtRcptLine.Find('-') then
            repeat
                LineQty := LineQty + InvtRcptLine.Quantity;
                TotalNetWeight += InvtRcptLine.Quantity * InvtRcptLine."Net Weight";
                TotalGrossWeight += InvtRcptLine.Quantity * InvtRcptLine."Gross Weight";
                TotalVolume += InvtRcptLine.Quantity * InvtRcptLine."Unit Volume";
                if InvtRcptLine."Units per Parcel" > 0 then
                    TotalParcels += Round(InvtRcptLine.Quantity / InvtRcptLine."Units per Parcel", 1, '>');
            until InvtRcptLine.Next() = 0;
    end;
}

