// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Reports;

using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Activity;
using System.Email;
using System.Utilities;

report 5751 "Put-away List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Warehouse/Reports/PutawayList.rdlc';
    Caption = 'Put-away List';
    WordMergeDataItem = "Warehouse Activity Header";

    dataset
    {
        dataitem("Warehouse Activity Header"; "Warehouse Activity Header")
        {
            DataItemTableView = sorting(Type, "No.") where(Type = filter("Put-away" | "Invt. Put-away"));
            RequestFilterFields = "No.", "No. Printed";
            column(No_WhseActivHeader; "No.")
            {
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(CompanyName; COMPANYPROPERTY.DisplayName())
                {
                }
                column(TodayFormatted; Format(Today, 0, 4))
                {
                }
                column(Time; Time)
                {
                }
                column(SumUpLines; SumUpLines)
                {
                }
                column(ShowLotSN; ShowLotSN)
                {
                }
                column(InvtPutAway; InvtPutAway)
                {
                }
                column(BinMandatory; Location."Bin Mandatory")
                {
                }
                column(DirPutAwayAndPick; Location."Directed Put-away and Pick")
                {
                }
                column(PutAwayFilter; PutAwayFilter)
                {
                }
                column(TblCptnPutAwayFilter; "Warehouse Activity Header".TableCaption + ': ' + PutAwayFilter)
                {
                }
                column(No1_WhseActivHeader; "Warehouse Activity Header"."No.")
                {
                    IncludeCaption = true;
                }
                column(LocCode_WhseActivHeader; "Warehouse Activity Header"."Location Code")
                {
                    IncludeCaption = true;
                }
                column(AssgndUID_WhseActivHeader; "Warehouse Activity Header"."Assigned User ID")
                {
                    IncludeCaption = true;
                }
                column(SortingMthd_WhseActivHeader; "Warehouse Activity Header"."Sorting Method")
                {
                    IncludeCaption = true;
                }
                column(SrcDoc_WhseActivHeader; "Warehouse Activity Line"."Source Document")
                {
                    IncludeCaption = true;
                }
                column(CurrReportPAGENOCaption; CurrReportPAGENOCaptionLbl)
                {
                }
                column(PutawayListCaption; PutawayListCaptionLbl)
                {
                }
                column(WhseActLineDueDateCaption; WhseActLineDueDateCaptionLbl)
                {
                }
                column(QtyHandledCaption; QtyHandledCaptionLbl)
                {
                }
                dataitem("Warehouse Activity Line"; "Warehouse Activity Line")
                {
                    DataItemLink = "Activity Type" = field(Type), "No." = field("No.");
                    DataItemLinkReference = "Warehouse Activity Header";
                    DataItemTableView = sorting("Activity Type", "No.", "Sorting Sequence No.");

                    trigger OnAfterGetRecord()
                    begin
                        if SumUpLines and
                           ("Warehouse Activity Header"."Sorting Method" <>
                            "Warehouse Activity Header"."Sorting Method"::Document)
                        then begin
                            if TempWhseActivLine."No." = '' then begin
                                TempWhseActivLine := "Warehouse Activity Line";
                                TempWhseActivLine.Insert();
                                Mark(true);
                            end else begin
                                TempWhseActivLine.SetSumLinesFilters("Warehouse Activity Line");
                                if TempWhseActivLine.FindFirst() then begin
                                    TempWhseActivLine."Qty. (Base)" := TempWhseActivLine."Qty. (Base)" + "Qty. (Base)";
                                    TempWhseActivLine."Qty. to Handle" := TempWhseActivLine."Qty. to Handle" + "Qty. to Handle";
                                    TempWhseActivLine."Source No." := '';
                                    TempWhseActivLine.Modify();
                                end else begin
                                    TempWhseActivLine := "Warehouse Activity Line";
                                    TempWhseActivLine.Insert();
                                    Mark(true);
                                end;
                            end;
                        end else
                            Mark(true);
                        SetCrossDockMark("Cross-Dock Information");
                    end;

                    trigger OnPostDataItem()
                    begin
                        MarkedOnly(true);
                    end;

                    trigger OnPreDataItem()
                    begin
                        TempWhseActivLine.SetRange("Activity Type", "Warehouse Activity Header".Type);
                        TempWhseActivLine.SetRange("No.", "Warehouse Activity Header"."No.");
                        TempWhseActivLine.DeleteAll();
                        if BreakbulkFilter then
                            TempWhseActivLine.SetRange("Original Breakbulk", false);
                        Clear(TempWhseActivLine);
                    end;
                }
                dataitem(WhseActLine; "Warehouse Activity Line")
                {
                    DataItemLink = "Activity Type" = field(Type), "No." = field("No.");
                    DataItemLinkReference = "Warehouse Activity Header";
                    DataItemTableView = sorting("Activity Type", "No.", "Sorting Sequence No.");
                    column(SrcNo_WhseActivLine; "Source No.")
                    {
                        IncludeCaption = false;
                    }
                    column(SrcDoc_WhseActivLine; Format("Source Document"))
                    {
                    }
                    column(ShelfNo_WhseActivLine; "Shelf No.")
                    {
                        IncludeCaption = false;
                    }
                    column(ItemNo1_WhseActivLine; "Item No.")
                    {
                        IncludeCaption = false;
                    }
                    column(Desc_WhseActivLine; Description)
                    {
                        IncludeCaption = false;
                    }
                    column(CrsDocInfo_WhseActivLine; "Cross-Dock Information")
                    {
                        IncludeCaption = false;
                    }
                    column(UOMCode_WhseActivLine; "Unit of Measure Code")
                    {
                        IncludeCaption = false;
                    }
                    column(DueDate_WhseActivLine; Format("Due Date"))
                    {
                    }
                    column(QtyToHndl_WhseActivLine; "Qty. to Handle")
                    {
                        IncludeCaption = false;
                    }
                    column(QtyBase_WhseActivLine; "Qty. (Base)")
                    {
                        IncludeCaption = false;
                    }
                    column(CrossDockMark; CrossDockMark)
                    {
                    }
                    column(VariantCode_WhseActivLine; "Variant Code")
                    {
                        IncludeCaption = false;
                    }
                    column(ZoneCode_WhseActivLine; "Zone Code")
                    {
                        IncludeCaption = true;
                    }
                    column(BinCode_WhseActivLine; "Bin Code")
                    {
                        IncludeCaption = true;
                    }
                    column(ActionType_WhseActivLine; "Action Type")
                    {
                        IncludeCaption = true;
                    }
                    column(LotNo1_WhseActivLine; "Lot No.")
                    {
                        IncludeCaption = true;
                    }
                    column(SerialNo_WhseActivLine; "Serial No.")
                    {
                        IncludeCaption = true;
                    }
                    column(LineNo1_WhseActivLine; "Line No.")
                    {
                    }
                    column(BinRanking_WhseActivLine; "Bin Ranking")
                    {
                    }
                    column(EmptyStringCaption; EmptyStringCaptionLbl)
                    {
                    }
                    dataitem(WhseActLine2; "Warehouse Activity Line")
                    {
                        DataItemLink = "Activity Type" = field("Activity Type"), "No." = field("No."), "Bin Code" = field("Bin Code"), "Item No." = field("Item No."), "Action Type" = field("Action Type"), "Variant Code" = field("Variant Code"), "Unit of Measure Code" = field("Unit of Measure Code"), "Due Date" = field("Due Date");
                        DataItemTableView = sorting("Activity Type", "No.", "Bin Code", "Breakbulk No.", "Action Type");
                        column(LotNo_WhseActivLine; "Lot No.")
                        {
                        }
                        column(SerialNo2_WhseActivLine; "Serial No.")
                        {
                        }
                        column(QtyBase2_WhseActivLine; "Qty. (Base)")
                        {
                        }
                        column(QtyToHndl2_WhseActivLine; "Qty. to Handle")
                        {
                        }
                        column(LineNo_WhseActivLine; "Line No.")
                        {
                        }
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if SumUpLines then begin
                            TempWhseActivLine.Get("Activity Type", "No.", "Line No.");
                            "Qty. (Base)" := TempWhseActivLine."Qty. (Base)";
                            "Qty. to Handle" := TempWhseActivLine."Qty. to Handle";
                        end;
                        SetCrossDockMark("Cross-Dock Information");
                    end;

                    trigger OnPreDataItem()
                    begin
                        Copy("Warehouse Activity Line");
                        Counter := Count;
                        if Counter = 0 then
                            CurrReport.Break();

                        if BreakbulkFilter then
                            SetRange("Original Breakbulk", false);
                    end;
                }
            }

            trigger OnAfterGetRecord()
            begin
                this.GetLocation("Location Code");
                InvtPutAway := Type = Type::"Invt. Put-away";
                if InvtPutAway then
                    BreakbulkFilter := false
                else
                    BreakbulkFilter := "Breakbulk Filter";

                if not IsReportInPreviewMode() then
                    CODEUNIT.Run(CODEUNIT::"Whse.-Printed", "Warehouse Activity Header");
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(Breakbulk; BreakbulkFilter)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Set Breakbulk Filter';
                        Editable = BreakbulkEditable;
                        ToolTip = 'Specifies if you do not want to view the intermediate lines that are created when the unit of measure is changed in put-away instructions.';
                    }
                    field(SumUpLines; SumUpLines)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Sum up Lines';
                        Editable = SumUpLinesEditable;
                        ToolTip = 'Specifies if you want the lines to be summed up for each item, such as several put-away lines that originate from different source documents that concern the same item and bins.';
                    }
                    field(LotSerialNo; ShowLotSN)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Show Serial/Lot Number';
                        ToolTip = 'Specifies if you want to show lot and serial number information for items that use item tracking.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            SumUpLinesEditable := true;
            BreakbulkEditable := true;
        end;

        trigger OnOpenPage()
        begin
            if HideOptions then begin
                BreakbulkEditable := false;
                SumUpLinesEditable := false;
            end;
        end;
    }

    labels
    {
        WhseActLineItemNoCaption = 'Item No.';
        WhseActLineDescriptionCaption = 'Description';
        WhseActLineVariantCodeCaption = 'Variant Code';
        WhseActLineCrossDockInformationCaption = 'Cross-Dock Information';
        WhseActLineShelfNoCaption = 'Shelf No.';
        WhseActLineQtyBaseCaption = 'Quantity(Base)';
        WhseActLineQtytoHandleCaption = 'Quantity to Handle';
        WhseActLineUnitofMeasureCodeCaption = 'Unit of Measure Code';
        WhseActLineSourceNoCaption = 'Source No.';
    }

    trigger OnInitReport()
    begin
        OnBeforeOnInitReport(ShowLotSN);
    end;

    trigger OnPreReport()
    begin
        PutAwayFilter := "Warehouse Activity Header".GetFilters();
    end;

    var
        Location: Record Location;
        TempWhseActivLine: Record "Warehouse Activity Line" temporary;
        PutAwayFilter: Text;
        InvtPutAway: Boolean;
        Counter: Integer;
        CrossDockMark: Text[1];
        CurrReportPAGENOCaptionLbl: Label 'Page';
        PutawayListCaptionLbl: Label 'Put-away List';
        WhseActLineDueDateCaptionLbl: Label 'Due Date';
        QtyHandledCaptionLbl: Label 'Quantity Handled';
        EmptyStringCaptionLbl: Label '____________';

    protected var
        BreakbulkFilter: Boolean;
        HideOptions: Boolean;
        ShowLotSN: Boolean;
        SumUpLines: Boolean;
        BreakbulkEditable: Boolean;
        SumUpLinesEditable: Boolean;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Location.Init()
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    local procedure IsReportInPreviewMode(): Boolean
    var
        MailManagement: Codeunit "Mail Management";
    begin
        exit(CurrReport.Preview or MailManagement.IsHandlingGetEmailBody());
    end;

    procedure SetBreakbulkFilter(BreakbulkFilter2: Boolean)
    begin
        BreakbulkFilter := BreakbulkFilter2;
    end;

    procedure SetCrossDockMark(CrossDockInfo: Option)
    begin
        if CrossDockInfo <> 0 then
            CrossDockMark := '!'
        else
            CrossDockMark := '';
    end;

    procedure SetInventory(SetHideOptions: Boolean)
    begin
        HideOptions := SetHideOptions;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnInitReport(var ShowLotSN: Boolean)
    begin
    end;
}

