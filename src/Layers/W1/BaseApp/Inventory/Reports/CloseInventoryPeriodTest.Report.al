// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Assembly.History;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Setup;
using Microsoft.Utilities;
using System.Environment;
using System.Utilities;

report 1004 "Close Inventory Period - Test"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Inventory/Reports/CloseInventoryPeriodTest.rdlc';
    Caption = 'Close Inventory Period - Test';
    EnableHyperlinks = true;

    dataset
    {
        dataitem("Inventory Period"; "Inventory Period")
        {
            DataItemTableView = sorting("Ending Date");
            RequestFilterFields = "Ending Date";
            dataitem(Header; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(CompanyName; COMPANYPROPERTY.DisplayName())
                {
                }
                column(TodayFormatted; Format(Today, 0, 4))
                {
                }
                column(Name_InvtPeriod; "Inventory Period".Name)
                {
                }
                column(EndingDateFormat_InvtPeriod; Format("Inventory Period"."Ending Date"))
                {
                }
                column(ClosedFormat_InvtPeriod; Format("Inventory Period".Closed))
                {
                }
                column(PageNoCaption; PageCaptionLbl)
                {
                }
                column(CloseInventoryPeriodTestCaption; CloseInventPeriodTestCaptionLbl)
                {
                }
                column(ClosedCaption_InvtPeriod; "Inventory Period".FieldCaption(Closed))
                {
                }
                column(NameCaption_InvtPeriod; "Inventory Period".FieldCaption(Name))
                {
                }
                column(PeriodEndingDateCaption; EndingDateCaptionLbl)
                {
                }
                column(PeriodErrorText; PeriodErrorText)
                {
                }
                dataitem("Avg. Cost Adjmt. Entry Point"; "Avg. Cost Adjmt. Entry Point")
                {
                    DataItemTableView = sorting("Item No.", "Cost Is Adjusted", "Valuation Date");

                    trigger OnAfterGetRecord()
                    begin
                        if "Item No." <> LastItemNoStored then begin
                            StoreItemInErrorBuffer("Item No.", DATABASE::"Avg. Cost Adjmt. Entry Point", Text008, '', '', 0);
                            LastItemNoStored := "Item No.";
                        end;
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetRange("Cost Is Adjusted", false);
                        SetRange("Valuation Date", 0D, "Inventory Period"."Ending Date");
                        LastItemNoStored := '';
                    end;
                }
                dataitem("Inventory Adjmt. Entry (Order)"; "Inventory Adjmt. Entry (Order)")
                {
                    DataItemTableView = sorting("Cost is Adjusted", "Allow Online Adjustment") where("Cost is Adjusted" = const(false), "Is Finished" = const(true));

                    trigger OnAfterGetRecord()
                    var
                        ValueEntry: Record "Value Entry";
                    begin
                        ValueEntry.SetCurrentKey("Order Type", "Order No.", "Order Line No.");
                        ValueEntry.SetRange("Order Type", "Order Type");
                        ValueEntry.SetRange("Order No.", "Order No.");
                        ValueEntry.SetRange("Order Line No.", "Order Line No.");
                        case "Order Type" of
                            "Order Type"::Production:
                                ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::Output);
                            "Order Type"::Assembly:
                                ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::"Assembly Output");
                            else
                                OnCaseOrderTypeElse(ValueEntry);
                        end;
                        ValueEntry.SetRange("Valuation Date", 0D, "Inventory Period"."Ending Date");

                        if not ValueEntry.IsEmpty() then
                            StoreOrderInErrorBuffer("Inventory Adjmt. Entry (Order)");
                    end;
                }
                dataitem("Item Ledger Entry"; "Item Ledger Entry")
                {
                    DataItemTableView = sorting("Item No.", Open, "Variant Code", Positive, "Location Code", "Posting Date", "Entry No.");

                    trigger OnAfterGetRecord()
                    begin
                        StoreItemInErrorBuffer("Item No.", DATABASE::"Item Ledger Entry", StrSubstNo(Text003, "Entry No."), '', '', 0);
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetRange(Open, true);
                        SetRange(Positive, false);
                        SetRange("Posting Date", 0D, "Inventory Period"."Ending Date");
                    end;
                }
                dataitem(Item; Item)
                {
                    DataItemTableView = sorting("No.");
                    column(Description_Item; Description)
                    {
                    }
                    column(No_Item; "No.")
                    {
                    }
                    column(NoteText; NoteText)
                    {
                    }
                    column(DescriptionCaption_Item; FieldCaption(Description))
                    {
                    }
                    column(ItemHyperlink; ItemHyperlink)
                    {
                    }
                    column(NoCaption_Item; FieldCaption("No."))
                    {
                    }
                    dataitem(ItemErrorLoop; "Integer")
                    {
                        DataItemTableView = sorting(Number);
                        column(TempItemErrorBufferErrorText; TempItemErrorBuffer."Error Text")
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            GetErrorBuffer(TempItemErrorBuffer, Number = 1);
                        end;

                        trigger OnPreDataItem()
                        begin
                            TempItemErrorBuffer.SetRange("Source No.", Item."No.");
                            TempItemErrorBuffer.SetRange("Source Table", DATABASE::"Avg. Cost Adjmt. Entry Point");
                            SetRange(Number, 1, TempItemErrorBuffer.Count);
                        end;
                    }
                    dataitem(ItemOrderErrorLoop; "Integer")
                    {
                        DataItemTableView = sorting(Number);
                        column(ItemOrderErrorLoopErrorText; TempItemErrorBuffer."Error Text")
                        {
                        }
                        column(ErrorHyperlink; ErrorHyperlink)
                        {
                        }
                        column(ErrorHyperlinkAnchor; ErrorHyperlinkAnchor)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            GetErrorBuffer(TempItemErrorBuffer, Number = 1);

                            if TempItemErrorBufferBookmark.Get(TempItemErrorBuffer."Error No.") then begin
                                ErrorHyperlink := GenerateHyperlink(TempItemErrorBufferBookmark."Error Text", TempItemErrorBufferBookmark."Source Ref. No.");
                                ErrorHyperlinkAnchor := TempItemErrorBufferBookmark."Source No." + ':';
                            end else begin
                                ErrorHyperlink := '';
                                ErrorHyperlinkAnchor := '';
                            end;
                        end;

                        trigger OnPreDataItem()
                        begin
                            TempItemErrorBuffer.SetRange("Source No.", Item."No.");
                            TempItemErrorBuffer.SetRange("Source Table", DATABASE::"Inventory Adjmt. Entry (Order)");
                            SetRange(Number, 1, TempItemErrorBuffer.Count);
                        end;
                    }
                    dataitem(ItemLedgErrorLoop; "Integer")
                    {
                        DataItemTableView = sorting(Number);
                        column(ItemLedgErrorLoopErrorText; TempItemErrorBuffer."Error Text")
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            GetErrorBuffer(TempItemErrorBuffer, Number = 1);
                        end;

                        trigger OnPreDataItem()
                        begin
                            TempItemErrorBuffer.SetRange("Source No.", Item."No.");
                            TempItemErrorBuffer.SetRange("Source Table", DATABASE::"Item Ledger Entry");
                            if not TempItemErrorBuffer.IsEmpty() and (NoteText = '') then
                                NoteText := Text004;
                            SetRange(Number, 1, TempItemErrorBuffer.Count);
                        end;
                    }

                    trigger OnAfterGetRecord()
                    var
                        RecRef: RecordRef;
                    begin
                        RecRef.GetTable(Item);
                        ItemHyperlink := GenerateHyperlink(Format(RecRef.RecordId, 0, 10), PAGE::"Item Card");
                    end;

                    trigger OnPostDataItem()
                    begin
                        TempItemErrorBuffer.Reset();
                        TempItemErrorBuffer.DeleteAll();
                        TempItemErrorBufferBookmark.Reset();
                        TempItemErrorBufferBookmark.DeleteAll();
                    end;

                    trigger OnPreDataItem()
                    begin
                        Item2.MarkedOnly(true);
                        Copy(Item2);
                    end;
                }
            }

            trigger OnAfterGetRecord()
            begin
                if "Ending Date" = 0D then
                    PeriodErrorText := StrSubstNo(Text001, FieldCaption("Ending Date"), Name)
                else
                    PeriodErrorText := '';
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        Item2: Record Item;
        TempItemErrorBuffer: Record "Error Buffer" temporary;
        TempItemErrorBufferBookmark: Record "Error Buffer" temporary;
        ClientTypeManagement: Codeunit "Client Type Management";
        PeriodErrorText: Text[250];
        NoteText: Text[250];
        ItemHyperlink: Text;
        ErrorHyperlink: Text;
        ErrorHyperlinkAnchor: Code[21];
        LastItemNoStored: Code[20];

#pragma warning disable AA0074
        Text001: Label '%1 is missing in Inventory Period %2.', Comment = '%1 = FIELDCAPTION("Ending Date"), %2 = "Name"';
#pragma warning disable AA0470
        Text003: Label 'Item Ledger Entry %1 is open.*';
#pragma warning restore AA0470
        Text004: Label '*Close the open Item Ledger Entry, for example by posting related inbound transactions, in order to resolve the negative inventory and thereby allow the Inventory Period to be closed.';
#pragma warning restore AA0074
        PageCaptionLbl: Label 'Page';
        CloseInventPeriodTestCaptionLbl: Label 'Close Inventory Period - Test';
        EndingDateCaptionLbl: Label 'Ending Date';
#pragma warning disable AA0074
        Text008: Label 'The item has entries in this period that have not been adjusted.';
#pragma warning disable AA0470
        Text009: Label 'This %1 Order has not been adjusted.';
#pragma warning restore AA0470
        Text010: Label 'Posted Assembly';
#pragma warning restore AA0074

    procedure StoreItemInErrorBuffer(ItemNo: Code[20]; SourceTableNo: Integer; ErrorText: Text[250]; Recordbookmark: Text[250]; HyperlinkSourceRecNo: Code[20]; HyperlinkPageID: Integer)
    begin
        TempItemErrorBuffer."Error No." += 1;
        TempItemErrorBuffer."Error Text" := ErrorText;
        TempItemErrorBuffer."Source Table" := SourceTableNo;
        TempItemErrorBuffer."Source No." := ItemNo;
        TempItemErrorBuffer.Insert();

        if Recordbookmark <> '' then begin
            TempItemErrorBufferBookmark."Error No." := TempItemErrorBuffer."Error No.";
            TempItemErrorBufferBookmark."Error Text" := Recordbookmark;
            TempItemErrorBufferBookmark."Source No." := HyperlinkSourceRecNo;
            TempItemErrorBufferBookmark."Source Ref. No." := HyperlinkPageID;
            TempItemErrorBufferBookmark.Insert();
        end;

        if ItemNo <> '' then begin
            Item2.Get(ItemNo);
            Item2.Mark(true);
        end;
    end;

    local procedure StoreOrderInErrorBuffer(InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)")
    var
        PostedAssemblyHeader: Record "Posted Assembly Header";
        RecRef: RecordRef;
        Bookmark: Text[250];
    begin
        OnStoreOrderInErrorBuffer(InventoryAdjmtEntryOrder);
        case InventoryAdjmtEntryOrder."Order Type" of
            InventoryAdjmtEntryOrder."Order Type"::Assembly:
                begin
                    PostedAssemblyHeader.SetRange("Order No.", InventoryAdjmtEntryOrder."Order No.");
                    if PostedAssemblyHeader.FindSet() then
                        repeat
                            RecRef.GetTable(PostedAssemblyHeader);
                            Bookmark := Format(RecRef.RecordId, 0, 10);
                            StoreItemInErrorBuffer(
                                InventoryAdjmtEntryOrder."Item No.", DATABASE::"Inventory Adjmt. Entry (Order)",
                                StrSubstNo(Text009, Text010), Bookmark, PostedAssemblyHeader."No.", PAGE::"Posted Assembly Order");
                        until PostedAssemblyHeader.Next() = 0;
                end;
        end;
    end;

    local procedure GetErrorBuffer(var TempItemErrorBuffer: Record "Error Buffer" temporary; GetFirstRecord: Boolean)
    begin
        if GetFirstRecord then
            TempItemErrorBuffer.FindSet()
        else
            TempItemErrorBuffer.Next();
    end;

    local procedure GenerateHyperlink(Bookmark: Text[250]; PageID: Integer): Text
    begin
        if Bookmark = '' then
            exit('');

        // Generates a URL such as dynamicsnav://hostname:port/instance/company/runpage?page=pageId&bookmark=recordId&mode=View.
        exit(GetUrl(ClientTypeManagement.GetCurrentClientType(), CompanyName, OBJECTTYPE::Page, PageID) +
          StrSubstNo('&amp;bookmark=%1&mode=View', Bookmark));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCaseOrderTypeElse(var ValueEntry: Record "Value Entry");
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnStoreOrderInErrorBuffer(InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)")
    begin
    end;
}

