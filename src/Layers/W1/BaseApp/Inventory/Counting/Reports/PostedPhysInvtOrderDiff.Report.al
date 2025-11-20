// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.Reports;

using Microsoft.Finance.Dimension;
using Microsoft.Inventory.Counting.Document;
using Microsoft.Inventory.Counting.History;
using Microsoft.Inventory.Counting.Tracking;
using System.Utilities;

report 5876 "Posted Phys. Invt. Order Diff."
{
    DefaultLayout = RDLC;
    RDLCLayout = './Inventory/Counting/Reports/PostedPhysInvtOrderDiff.rdlc';
    ApplicationArea = Warehouse;
    Caption = 'Posted Phys. Invt. Order Diff.';
    UsageCategory = ReportsAndAnalysis;
    WordMergeDataItem = "Posted Phys. Invt. Order Hdr";

    dataset
    {
        dataitem("Posted Phys. Invt. Order Hdr"; "Pstd. Phys. Invt. Order Hdr")
        {
            RequestFilterFields = "No.";
            column(Post__Phys__Invt__Order_Header_No_; "No.")
            {
            }
            dataitem(PageCounter; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(USERID; UserId)
                {
                }
                column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
                {
                }
                column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
                {
                }
                column(ShowDim; ShowDim)
                {
                }
                column(Post__Phys__Invt__Order_Header___Posting_Date_; Format("Posted Phys. Invt. Order Hdr"."Posting Date"))
                {
                }
                column(Post__Phys__Invt__Order_Header___No__; "Posted Phys. Invt. Order Hdr"."No.")
                {
                }
                column(Post__Phys__Invt__Order_Header___Person_Responsible_; "Posted Phys. Invt. Order Hdr"."Person Responsible")
                {
                }
                column(Post__Phys__Invt__Order_Header___No__Finished_Recordings_; "Posted Phys. Invt. Order Hdr"."No. Finished Recordings")
                {
                }
                column(Post__Phys__Invt__Order_Header__Description; "Posted Phys. Invt. Order Hdr".Description)
                {
                }
                column(PageCounter_Number; Number)
                {
                }
                column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
                {
                }
                column(Posted_Phys__Inventory_Order_Difference_ListCaption; Posted_Phys__Inventory_Order_Difference_ListCaptionLbl)
                {
                }
                column(Post__Phys__Invt__Order_Header___Posting_Date_Caption; Post__Phys__Invt__Order_Header___Posting_Date_CaptionLbl)
                {
                }
                column(Post__Phys__Invt__Order_Header___No__Caption; "Posted Phys. Invt. Order Hdr".FieldCaption("No."))
                {
                }
                column(Post__Phys__Invt__Order_Header___Person_Responsible_Caption; "Posted Phys. Invt. Order Hdr".FieldCaption("Person Responsible"))
                {
                }
                column(Post__Phys__Invt__Order_Header___No__Finished_Recordings_Caption; "Posted Phys. Invt. Order Hdr".FieldCaption("No. Finished Recordings"))
                {
                }
                column(Post__Phys__Invt__Order_Header__DescriptionCaption; "Posted Phys. Invt. Order Hdr".FieldCaption(Description))
                {
                }
                dataitem("Pstd. Phys. Invt. Order Line"; "Pstd. Phys. Invt. Order Line")
                {
                    DataItemLink = "Document No." = field("No.");
                    DataItemLinkReference = "Posted Phys. Invt. Order Hdr";
                    DataItemTableView = sorting("Document No.", "Line No.");
                    column(Posted_Phys__Invt__Order_Line__Item_No__; "Item No.")
                    {
                    }
                    column(Posted_Phys__Invt__Order_Line__Location_Code_; "Location Code")
                    {
                    }
                    column(Posted_Phys__Invt__Order_Line__Bin_Code_; "Bin Code")
                    {
                    }
                    column(Posted_Phys__Invt__Order_Line_Description; Description)
                    {
                    }
                    column(Posted_Phys__Invt__Order_Line__Base_Unit_of_Measure_Code_; "Base Unit of Measure Code")
                    {
                    }
                    column(Posted_Phys__Invt__Order_Line__Qty__Expected__Base__; "Qty. Expected (Base)")
                    {
                    }
                    column(Posted_Phys__Invt__Order_Line__Variant_Code_; "Variant Code")
                    {
                    }
                    column(Posted_Phys__Invt__Order_Line__Qty__Recorded__Base__; "Qty. Recorded (Base)")
                    {
                    }
                    column(AmountPos; AmountPos)
                    {
                    }
                    column(AmountNeg; AmountNeg)
                    {
                    }
                    column(QtyPos; QtyPos)
                    {
                        DecimalPlaces = 0 : 5;
                    }
                    column(QtyNeg; QtyNeg)
                    {
                        DecimalPlaces = 0 : 5;
                    }
                    column(Posted_Phys__Invt__Order_Line__No__Finished_Rec__Lines_; "No. Finished Rec.-Lines")
                    {
                    }
                    column(Posted_Phys__Invt__Order_Line__Recorded_without_Order_; Format("Recorded Without Order"))
                    {
                    }
                    column(PrintAnEmptyLine; PrintAnEmptyLine)
                    {
                    }
                    column(AmountPos_Control49; AmountPos)
                    {
                    }
                    column(AmountNeg_Control50; AmountNeg)
                    {
                    }
                    column(NewAmountPos; NewAmountPos)
                    {
                    }
                    column(NewAmountNeg; NewAmountNeg)
                    {
                    }
                    column(Posted_Phys__Invt__Order_Line_Document_No_; "Document No.")
                    {
                    }
                    column(Posted_Phys__Invt__Order_Line_Line_No_; "Line No.")
                    {
                    }
                    column(Posted_Phys__Invt__Order_Line__Item_No__Caption; FieldCaption("Item No."))
                    {
                    }
                    column(Posted_Phys__Invt__Order_Line__Location_Code_Caption; FieldCaption("Location Code"))
                    {
                    }
                    column(Posted_Phys__Invt__Order_Line__Bin_Code_Caption; FieldCaption("Bin Code"))
                    {
                    }
                    column(Posted_Phys__Invt__Order_Line_DescriptionCaption; FieldCaption(Description))
                    {
                    }
                    column(Posted_Phys__Invt__Order_Line__Base_Unit_of_Measure_Code_Caption; FieldCaption("Base Unit of Measure Code"))
                    {
                    }
                    column(Posted_Phys__Invt__Order_Line__Qty__Expected__Base__Caption; FieldCaption("Qty. Expected (Base)"))
                    {
                    }
                    column(Posted_Phys__Invt__Order_Line__Variant_Code_Caption; FieldCaption("Variant Code"))
                    {
                    }
                    column(Posted_Phys__Invt__Order_Line__Qty__Recorded__Base__Caption; FieldCaption("Qty. Recorded (Base)"))
                    {
                    }
                    column(QtyPosCaption; QtyPosCaptionLbl)
                    {
                    }
                    column(QtyNegCaption; QtyNegCaptionLbl)
                    {
                    }
                    column(AmountPosCaption; AmountPosCaptionLbl)
                    {
                    }
                    column(AmountNegCaption; AmountNegCaptionLbl)
                    {
                    }
                    column(Posted_Phys__Invt__Order_Line__No__Finished_Rec__Lines_Caption; FieldCaption("No. Finished Rec.-Lines"))
                    {
                    }
                    column(Posted_Phys__Invt__Order_Line__Recorded_without_Order_Caption; Posted_Phys__Invt__Order_Line__Recorded_without_Order_CaptionLbl)
                    {
                    }
                    column(TotalsCaption; TotalsCaptionLbl)
                    {
                    }
                    dataitem(DiffListBufferLoop; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                        column(TempPhysInvtCountBuffer__Track__Qty__Pos___Base__; TempPhysInvtCountBuffer."Track. Qty. Pos. (Base)")
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(TempPhysInvtCountBuffer__Track__Qty__Neg___Base__; TempPhysInvtCountBuffer."Track. Qty. Neg. (Base)")
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(TempPhysInvtCountBuffer__Track__Lot_No__; TempPhysInvtCountBuffer."Track. Lot No.")
                        {
                        }
                        column(TempPhysInvtCountBuffer__Track__Serial_No__; TempPhysInvtCountBuffer."Track. Serial No.")
                        {
                        }
                        column(TempPhysInvtCountBuffer__Rec__Qty___Base__; TempPhysInvtCountBuffer."Rec. Qty. (Base)")
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(TempPhysInvtCountBuffer__Rec__Lot_No__; TempPhysInvtCountBuffer."Rec. Lot No.")
                        {
                        }
                        column(TempPhysInvtCountBuffer__Rec__Serial_No__; TempPhysInvtCountBuffer."Rec. Serial No.")
                        {
                        }
                        column(TempPhysInvtCountBuffer__Rec__No__; TempPhysInvtCountBuffer."Rec. No.")
                        {
                        }
                        column(TempPhysInvtCountBuffer__Exp__Qty___Base__; TempPhysInvtCountBuffer."Exp. Qty. (Base)")
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(TempPhysInvtCountBuffer__Exp__Lot_No__; TempPhysInvtCountBuffer."Exp. Lot No.")
                        {
                        }
                        column(TempPhysInvtCountBuffer__Exp__Serial_No__; TempPhysInvtCountBuffer."Exp. Serial No.")
                        {
                        }
                        column(TempPhysInvtCountBuffer__Track__Qty__Pos___Base___Control85; TempPhysInvtCountBuffer."Track. Qty. Pos. (Base)")
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(TempPhysInvtCountBuffer__Track__Qty__Neg___Base___Control86; TempPhysInvtCountBuffer."Track. Qty. Neg. (Base)")
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(TempPhysInvtCountBuffer__Rec__Qty___Base___Control87; TempPhysInvtCountBuffer."Rec. Qty. (Base)")
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(TempPhysInvtCountBuffer__Exp__Qty___Base___Control90; TempPhysInvtCountBuffer."Exp. Qty. (Base)")
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(DiffListBufferLoop_Number; Number)
                        {
                        }
                        column(Item_Tracking_LinesCaption; Item_Tracking_LinesCaptionLbl)
                        {
                        }
                        column(TempPhysInvtCountBuffer__Track__Qty__Pos___Base__Caption; TempPhysInvtCountBuffer__Track__Qty__Pos___Base__CaptionLbl)
                        {
                        }
                        column(TempPhysInvtCountBuffer__Track__Qty__Neg___Base__Caption; TempPhysInvtCountBuffer__Track__Qty__Neg___Base__CaptionLbl)
                        {
                        }
                        column(TempPhysInvtCountBuffer__Track__Lot_No__Caption; TempPhysInvtCountBuffer__Track__Lot_No__CaptionLbl)
                        {
                        }
                        column(TempPhysInvtCountBuffer__Track__Serial_No__Caption; TempPhysInvtCountBuffer__Track__Serial_No__CaptionLbl)
                        {
                        }
                        column(TempPhysInvtCountBuffer__Rec__Qty___Base__Caption; TempPhysInvtCountBuffer__Rec__Qty___Base__CaptionLbl)
                        {
                        }
                        column(Recording_LinesCaption; Recording_LinesCaptionLbl)
                        {
                        }
                        column(TempPhysInvtCountBuffer__Rec__Lot_No__Caption; TempPhysInvtCountBuffer__Rec__Lot_No__CaptionLbl)
                        {
                        }
                        column(TempPhysInvtCountBuffer__Rec__Serial_No__Caption; TempPhysInvtCountBuffer__Rec__Serial_No__CaptionLbl)
                        {
                        }
                        column(TempPhysInvtCountBuffer__Rec__No__Caption; TempPhysInvtCountBuffer__Rec__No__CaptionLbl)
                        {
                        }
                        column(TempPhysInvtCountBuffer__Exp__Qty___Base__Caption; TempPhysInvtCountBuffer__Exp__Qty___Base__CaptionLbl)
                        {
                        }
                        column(Expected_Tracking_LinesCaption; Expected_Tracking_LinesCaptionLbl)
                        {
                        }
                        column(TempPhysInvtCountBuffer__Exp__Lot_No__Caption; TempPhysInvtCountBuffer__Exp__Lot_No__CaptionLbl)
                        {
                        }
                        column(TempPhysInvtCountBuffer__Exp__Serial_No__Caption; TempPhysInvtCountBuffer__Exp__Serial_No__CaptionLbl)
                        {
                        }
                        column(TotalsCaption_Control91; TotalsCaption_Control91Lbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            LineCount := LineCount + 1;
                            if LineCount > NoOfBufferLines then
                                CurrReport.Break();

                            if LineCount = 1 then
                                TempPhysInvtCountBuffer.Find('-')
                            else
                                TempPhysInvtCountBuffer.Next();
                        end;

                        trigger OnPreDataItem()
                        begin
                            if NoOfBufferLines = 0 then
                                CurrReport.Break();

                            LineCount := 0;

                            TempPhysInvtCountBuffer.Reset();
                        end;
                    }
                    dataitem(LineDimensionLoop; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                        column(DimText; DimText)
                        {
                        }
                        column(DimText_Control44; DimText)
                        {
                        }
                        column(Number; Number)
                        {
                        }
                        column(DimTextCaption; DimTextCaptionLbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if Number = 1 then begin
                                if not DimSetEntry.FindSet() then
                                    CurrReport.Break();
                            end else
                                if not Continue then
                                    CurrReport.Break();

                            Clear(DimText);
                            Continue := false;
                            repeat
                                OldDimText := DimText;
                                if DimText = '' then
                                    DimText := StrSubstNo(
                                        '%1 %2', DimSetEntry."Dimension Code", DimSetEntry."Dimension Value Code")
                                else
                                    DimText :=
                                      StrSubstNo(
                                        '%1, %2 %3', DimText,
                                        DimSetEntry."Dimension Code", DimSetEntry."Dimension Value Code");
                                if StrLen(DimText) > MaxStrLen(OldDimText) then begin
                                    DimText := OldDimText;
                                    Continue := true;
                                    exit;
                                end;
                            until (DimSetEntry.Next() = 0);
                        end;

                        trigger OnPreDataItem()
                        begin
                            AmountPos := 0;
                            AmountNeg := 0;
                            QtyPos := 0;
                            QtyNeg := 0;

                            if not ShowDim then
                                CurrReport.Break();

                            if LineIsEmpty then
                                CurrReport.Break();

                            DimSetEntry.SetRange("Dimension Set ID", "Pstd. Phys. Invt. Order Line"."Dimension Set ID");
                        end;
                    }
                    dataitem("Integer"; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = const(1));

                        trigger OnPreDataItem()
                        begin
                            AmountPos := 0;
                            AmountNeg := 0;
                            QtyPos := 0;
                            QtyNeg := 0;
                        end;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        LineIsEmpty := EmptyLine();

                        QtyPos := 0;
                        QtyNeg := 0;
                        AmountPos := 0;
                        AmountNeg := 0;

                        if not LineIsEmpty then
                            case "Entry Type" of
                                "Entry Type"::"Positive Adjmt.":
                                    begin
                                        QtyPos := "Quantity (Base)";
                                        AmountPos := "Unit Amount" * QtyPos;
                                    end;
                                "Entry Type"::"Negative Adjmt.":
                                    begin
                                        QtyNeg := "Quantity (Base)";
                                        AmountNeg := "Unit Amount" * QtyNeg;
                                    end;
                            end;

                        // Tracking Information:
                        TempPhysInvtCountBuffer.DeleteAll();
                        NoOfBufferLines := 0;
                        if not LineIsEmpty and "Use Item Tracking" then
                            CreateDiffListBuffer("Pstd. Phys. Invt. Order Line", NoOfBufferLines);

                        PrintAnEmptyLine := NoOfBufferLines > 0;
                        NewAmountPos += AmountPos;
                        NewAmountNeg += AmountNeg;
                    end;

                    trigger OnPreDataItem()
                    begin
                        NewAmountPos := 0;
                        NewAmountNeg := 0;
                    end;
                }
            }
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
                    field(ShowDimensions; ShowDim)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Dimensions';
                        ToolTip = 'Specifies if you want dimensions information for the journal lines to be included in the report.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        TempPhysInvtCountBuffer: Record "Phys. Invt. Count Buffer" temporary;
        DimSetEntry: Record "Dimension Set Entry";
        DimText: Text[120];
        OldDimText: Text[120];
        NoOfBufferLines: Integer;
        LineCount: Integer;
        QtyPos: Decimal;
        QtyNeg: Decimal;
        AmountPos: Decimal;
        AmountNeg: Decimal;
        ShowDim: Boolean;
        Continue: Boolean;
        LineIsEmpty: Boolean;
        PrintAnEmptyLine: Boolean;
        NewAmountPos: Decimal;
        NewAmountNeg: Decimal;
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Posted_Phys__Inventory_Order_Difference_ListCaptionLbl: Label 'Posted Phys. Inventory Order Difference List';
        Post__Phys__Invt__Order_Header___Posting_Date_CaptionLbl: Label 'Posting Date';
        QtyPosCaptionLbl: Label 'Qty. Pos.';
        QtyNegCaptionLbl: Label 'Qty. Neg.';
        AmountPosCaptionLbl: Label 'Amount Pos.';
        AmountNegCaptionLbl: Label 'Amount Neg.';
        Posted_Phys__Invt__Order_Line__Recorded_without_Order_CaptionLbl: Label 'Recorded Without Order';
        TotalsCaptionLbl: Label 'Totals';
        Item_Tracking_LinesCaptionLbl: Label 'Item Tracking Lines';
        TempPhysInvtCountBuffer__Track__Qty__Pos___Base__CaptionLbl: Label 'Qty. Pos. (Base)';
        TempPhysInvtCountBuffer__Track__Qty__Neg___Base__CaptionLbl: Label 'Qty Neg. (Base)';
        TempPhysInvtCountBuffer__Track__Lot_No__CaptionLbl: Label 'Lot No.';
        TempPhysInvtCountBuffer__Track__Serial_No__CaptionLbl: Label 'Serial No.';
        TempPhysInvtCountBuffer__Rec__Qty___Base__CaptionLbl: Label 'Recorded Qty. (Base)';
        Recording_LinesCaptionLbl: Label 'Recording Lines';
        TempPhysInvtCountBuffer__Rec__Lot_No__CaptionLbl: Label 'Lot No.';
        TempPhysInvtCountBuffer__Rec__Serial_No__CaptionLbl: Label 'Serial No.';
        TempPhysInvtCountBuffer__Rec__No__CaptionLbl: Label 'Recording No.';
        TempPhysInvtCountBuffer__Exp__Qty___Base__CaptionLbl: Label 'Exp. Qty. (Base)';
        Expected_Tracking_LinesCaptionLbl: Label 'Expected Item Tracking';
        TempPhysInvtCountBuffer__Exp__Lot_No__CaptionLbl: Label 'Lot No.';
        TempPhysInvtCountBuffer__Exp__Serial_No__CaptionLbl: Label 'Serial No.';
        TotalsCaption_Control91Lbl: Label 'Totals';
        DimTextCaptionLbl: Label 'Line Dimensions';

    procedure CreateDiffListBuffer(PstdPhysInvtOrderLine: Record "Pstd. Phys. Invt. Order Line"; var NoOfBufferLines: Integer)
    var
        PstdExpInvtOrderTracking: Record "Pstd.Exp.Invt.Order.Tracking";
        PstdPhysInvtRecordLine: Record "Pstd. Phys. Invt. Record Line";
        PhysInvtCountBuffer: Record "Phys. Invt. Count Buffer";
        NextLineNo: Integer;
        LastLineNo: Integer;
    begin
        NoOfBufferLines := 0;

        NextLineNo := 1;
        PstdExpInvtOrderTracking.Reset();
        PstdExpInvtOrderTracking.SetRange("Order No", PstdPhysInvtOrderLine."Document No.");
        PstdExpInvtOrderTracking.SetRange("Order Line No.", PstdPhysInvtOrderLine."Line No.");
        if PstdExpInvtOrderTracking.Find('-') then
            repeat
                FindOrCreateDiffListBuffer(NoOfBufferLines, NextLineNo);
                TempPhysInvtCountBuffer."Exp. Serial No." := PstdExpInvtOrderTracking."Serial No.";
                TempPhysInvtCountBuffer."Exp. Lot No." := PstdExpInvtOrderTracking."Lot No.";
                TempPhysInvtCountBuffer."Exp. Package No." := PstdExpInvtOrderTracking."Package No.";
                TempPhysInvtCountBuffer."Exp. Qty. (Base)" := PstdExpInvtOrderTracking."Quantity (Base)";
                TempPhysInvtCountBuffer.Modify();
            until PstdExpInvtOrderTracking.Next() = 0;

        NextLineNo := 1;
        PstdPhysInvtRecordLine.Reset();
        PstdPhysInvtRecordLine.SetCurrentKey("Order No.", "Order Line No.");
        PstdPhysInvtRecordLine.SetRange("Order No.", PstdPhysInvtOrderLine."Document No.");
        PstdPhysInvtRecordLine.SetRange("Order Line No.", PstdPhysInvtOrderLine."Line No.");
        if PstdPhysInvtRecordLine.Find('-') then
            repeat
                FindOrCreateDiffListBuffer(NoOfBufferLines, NextLineNo);
                TempPhysInvtCountBuffer."Rec. No." := PstdPhysInvtRecordLine."Recording No.";
                TempPhysInvtCountBuffer."Rec. Line No." := PstdPhysInvtRecordLine."Line No.";
                TempPhysInvtCountBuffer."Rec. Serial No." := PstdPhysInvtRecordLine."Serial No.";
                TempPhysInvtCountBuffer."Rec. Lot No." := PstdPhysInvtRecordLine."Lot No.";
                TempPhysInvtCountBuffer."Rec. Qty. (Base)" := PstdPhysInvtRecordLine."Quantity (Base)";
                TempPhysInvtCountBuffer.Modify();
            until PstdPhysInvtRecordLine.Next() = 0;

        LastLineNo := NextLineNo - 1;
        PhysInvtCountBuffer.SetFilter("Line No.", '%1..%2', 0, LastLineNo);
        if PhysInvtCountBuffer.Find('-') then
            repeat
                if PhysInvtCountBuffer."Exp. Serial No." <> '' then
                    TempPhysInvtCountBuffer.SetRange("Rec. Serial No.", PhysInvtCountBuffer."Exp. Serial No.");
                if PhysInvtCountBuffer."Exp. Lot No." <> '' then
                    TempPhysInvtCountBuffer.SetRange("Rec. Lot No.", PhysInvtCountBuffer."Exp. Lot No.");
                if TempPhysInvtCountBuffer.Find('-') then
                    case true of
                        PhysInvtCountBuffer."Rec. Qty. (Base)" - TempPhysInvtCountBuffer."Exp. Qty. (Base)" < 0:
                            begin
                                UpdateBufferTracking(
                                  PhysInvtCountBuffer."Exp. Serial No.", PhysInvtCountBuffer."Exp. Lot No.",
                                  0, PhysInvtCountBuffer."Rec. Qty. (Base)" - TempPhysInvtCountBuffer."Exp. Qty. (Base)");
                                TempPhysInvtCountBuffer.Modify();
                            end;
                        PhysInvtCountBuffer."Rec. Qty. (Base)" - TempPhysInvtCountBuffer."Exp. Qty. (Base)" > 0:
                            begin
                                UpdateBufferTracking(
                                  PhysInvtCountBuffer."Exp. Serial No.", PhysInvtCountBuffer."Exp. Lot No.",
                                  PhysInvtCountBuffer."Rec. Qty. (Base)" - TempPhysInvtCountBuffer."Exp. Qty. (Base)", 0);
                                TempPhysInvtCountBuffer.Modify();
                            end;
                    end
                else begin
                    TempPhysInvtCountBuffer.SetRange("Rec. Serial No.");
                    TempPhysInvtCountBuffer.SetRange("Rec. Lot No.");
                    InsertBufferTracking(
                      PhysInvtCountBuffer."Exp. Serial No.", PhysInvtCountBuffer."Exp. Lot No.",
                      0, -PhysInvtCountBuffer."Exp. Qty. (Base)", NextLineNo);
                end;
            until PhysInvtCountBuffer.Next() = 0;

        TempPhysInvtCountBuffer.Reset();
        PhysInvtCountBuffer.SetFilter("Line No.", '%1..%2', 0, LastLineNo);
        if PhysInvtCountBuffer.Find('-') then
            repeat
                if PhysInvtCountBuffer."Rec. Serial No." <> '' then
                    TempPhysInvtCountBuffer.SetRange("Exp. Serial No.", PhysInvtCountBuffer."Rec. Serial No.");
                if PhysInvtCountBuffer."Rec. Lot No." <> '' then
                    TempPhysInvtCountBuffer.SetRange("Exp. Lot No.", PhysInvtCountBuffer."Rec. Lot No.");
                if TempPhysInvtCountBuffer.Find('-') then
                    case true of
                        PhysInvtCountBuffer."Rec. Qty. (Base)" - TempPhysInvtCountBuffer."Exp. Qty. (Base)" < 0:
                            begin
                                UpdateBufferTracking(
                                  PhysInvtCountBuffer."Exp. Serial No.", PhysInvtCountBuffer."Exp. Lot No.",
                                  0, PhysInvtCountBuffer."Rec. Qty. (Base)" - TempPhysInvtCountBuffer."Exp. Qty. (Base)");
                                TempPhysInvtCountBuffer.Modify();
                            end;
                        PhysInvtCountBuffer."Rec. Qty. (Base)" - TempPhysInvtCountBuffer."Exp. Qty. (Base)" > 0:
                            begin
                                UpdateBufferTracking(
                                  PhysInvtCountBuffer."Exp. Serial No.", PhysInvtCountBuffer."Exp. Lot No.",
                                  PhysInvtCountBuffer."Rec. Qty. (Base)" - TempPhysInvtCountBuffer."Exp. Qty. (Base)", 0);
                                TempPhysInvtCountBuffer.Modify();
                            end;
                    end
                else begin
                    TempPhysInvtCountBuffer.SetRange("Exp. Serial No.");
                    TempPhysInvtCountBuffer.SetRange("Exp. Lot No.");
                    InsertBufferTracking(
                      PhysInvtCountBuffer."Rec. Serial No.", PhysInvtCountBuffer."Rec. Lot No.",
                      PhysInvtCountBuffer."Rec. Qty. (Base)", 0, NextLineNo);
                end;
            until PhysInvtCountBuffer.Next() = 0;
    end;

    procedure FindOrCreateDiffListBuffer(var NoOfBufferLines: Integer; var NextLineNo: Integer)
    begin
        if NextLineNo > NoOfBufferLines then begin
            TempPhysInvtCountBuffer.Init();
            TempPhysInvtCountBuffer."Line No." := NextLineNo;
            TempPhysInvtCountBuffer.Insert();
            NoOfBufferLines := NoOfBufferLines + 1;
        end else
            if NextLineNo = 1 then
                TempPhysInvtCountBuffer.Find('-')
            else
                TempPhysInvtCountBuffer.Next();

        NextLineNo := NextLineNo + 1;
    end;

    local procedure InsertBufferTracking(SerialNo: Code[50]; LotNo: Code[50]; PosQty: Decimal; NegQty: Decimal; var NextLineNo: Integer)
    begin
        TempPhysInvtCountBuffer.SetRange(TempPhysInvtCountBuffer."Track. Serial No.", '');
        TempPhysInvtCountBuffer.SetRange(TempPhysInvtCountBuffer."Track. Lot No.", '');
        if TempPhysInvtCountBuffer.Find('-') then begin
            UpdateBufferTracking(SerialNo, LotNo, PosQty, NegQty);
            TempPhysInvtCountBuffer.Modify();
        end else begin
            TempPhysInvtCountBuffer.Init();
            TempPhysInvtCountBuffer."Line No." := NextLineNo;
            UpdateBufferTracking(SerialNo, LotNo, PosQty, NegQty);
            TempPhysInvtCountBuffer.Insert();
            NextLineNo := NextLineNo + 1;
            NoOfBufferLines := NoOfBufferLines + 1;
        end;
    end;

    local procedure UpdateBufferTracking(SerialNo: Code[50]; LotNo: Code[50]; PosQty: Decimal; NegQty: Decimal)
    begin
        TempPhysInvtCountBuffer."Track. Serial No." := SerialNo;
        TempPhysInvtCountBuffer."Track. Lot No." := LotNo;
        TempPhysInvtCountBuffer."Track. Qty. Pos. (Base)" := PosQty;
        TempPhysInvtCountBuffer."Track. Qty. Neg. (Base)" := NegQty;
    end;
}

