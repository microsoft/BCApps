// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.Journal;

using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Journal;
using Microsoft.Warehouse.Journal;

report 7380 "Calculate Phys. Invt. Counting"
{
    Caption = 'Calculate Phys. Invt. Counting';
    ProcessingOnly = true;

    dataset
    {
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(PostingDate; PostingDate)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the date for the posting of this batch job. By default, the system date is entered, but you can change it.';

                        trigger OnValidate()
                        begin
                            ValidatePostingDate();
                        end;
                    }
                    field(NextDocNo; NextDocNo)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Document No.';
                        ToolTip = 'Specifies the document number of the entry to be applied.';
                    }
                    field(ZeroQty; ZeroQty)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Items Not on Inventory';
                        ToolTip = 'Specifies if journal lines should be created for items that are not on inventory, that is, items where the value in the Qty. (Calculated) field is 0.';
                    }
                    group(Print)
                    {
                        Caption = 'Print';
                        field(PrintDoc; PrintDoc)
                        {
                            ApplicationArea = Warehouse;
                            Caption = 'Print List';
                            ToolTip = 'Specifies that you want to print the lists on which employees record the quantity of items they count in each bin.';

                            trigger OnValidate()
                            begin
                                if not PrintDoc then begin
                                    PrintDocPerItem := false;
                                    ShowQtyCalculated := false;
                                end;
                                ShowQtyCalcEnable := PrintDoc;
                                PrintPerItemEnable := PrintDoc;
                            end;
                        }
                        field(ShowQtyCalc; ShowQtyCalculated)
                        {
                            ApplicationArea = Warehouse;
                            Caption = 'Show Qty. Calculated';
                            Enabled = ShowQtyCalcEnable;
                            ToolTip = 'Specifies that the calculated quantity is shown on the resulting report.';
                        }
                        field(PrintPerItem; PrintDocPerItem)
                        {
                            ApplicationArea = Warehouse;
                            Caption = 'Per Item';
                            Enabled = PrintPerItemEnable;
                            ToolTip = 'Specifies if you want to sum up the inventory value per item ledger entry or per item.';
                            Visible = PrintPerItemVisible;
                        }
                    }
                    field(SortMethod; SortingMethod)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Sorting Method';
                        OptionCaption = ' ,Item,Bin';
                        ToolTip = 'Specifies how items are sorted on the resulting report.';
                        Visible = SortMethodVisible;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            PrintPerItemVisible := true;
            SortMethodVisible := true;
            PrintPerItemEnable := true;
            ShowQtyCalcEnable := true;
        end;

        trigger OnOpenPage()
        begin
            if PostingDate = 0D then
                PostingDate := WorkDate();
            ValidatePostingDate();

            ShowQtyCalcEnable := PrintDoc;
            PrintPerItemEnable := PrintDoc;
            SortMethodVisible := SourceJnl = SourceJnl::WhseJnl;
            PrintPerItemVisible := SourceJnl = SourceJnl::WhseJnl;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        OKPressed := true;
    end;

    var
        ItemJnlBatch: Record "Item Journal Batch";
        WhseJnlBatch: Record "Warehouse Journal Batch";
        PostingDate: Date;
        SourceJnl: Option ItemJnl,WhseJnl;
        SortingMethod: Option " ",Item,Bin;
        NextDocNo: Code[20];
        PrintDoc: Boolean;
        PrintDocPerItem: Boolean;
        ShowQtyCalculated: Boolean;
        ZeroQty: Boolean;
        OKPressed: Boolean;
        ShowQtyCalcEnable: Boolean;
        PrintPerItemEnable: Boolean;
        SortMethodVisible: Boolean;
        PrintPerItemVisible: Boolean;

    procedure GetRequest(var PostingDate2: Date; var NextDocNo2: Code[20]; var SortingMethod2: Option " ",Item,Bin; var PrintDoc2: Boolean; var PrintDocPerItem2: Boolean; var ZeroQty2: Boolean; var ShowQtyCalculated2: Boolean): Boolean
    begin
        PostingDate2 := PostingDate;
        NextDocNo2 := NextDocNo;
        SortingMethod2 := SortingMethod;
        PrintDoc2 := PrintDoc;
        PrintDocPerItem2 := PrintDocPerItem;
        ZeroQty2 := ZeroQty;
        ShowQtyCalculated2 := ShowQtyCalculated;
        exit(OKPressed);
    end;

    local procedure ValidatePostingDate()
    var
        NoSeries: Codeunit "No. Series";
    begin
        if SourceJnl = SourceJnl::ItemJnl then begin
            if ItemJnlBatch."No. Series" = '' then
                NextDocNo := ''
            else
                NextDocNo := NoSeries.PeekNextNo(ItemJnlBatch."No. Series", PostingDate);
        end else
            if WhseJnlBatch."No. Series" = '' then
                NextDocNo := ''
            else
                NextDocNo := NoSeries.PeekNextNo(WhseJnlBatch."No. Series", PostingDate);
    end;

    procedure SetItemJnlLine(NewItemJnlBatch: Record "Item Journal Batch")
    begin
        ItemJnlBatch := NewItemJnlBatch;
        SourceJnl := SourceJnl::ItemJnl;
    end;

    procedure SetWhseJnlLine(NewWhseJnlBatch: Record "Warehouse Journal Batch")
    begin
        WhseJnlBatch := NewWhseJnlBatch;
        SourceJnl := SourceJnl::WhseJnl;
    end;
}

