// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.Reports;

using Microsoft.Finance.Dimension;
using Microsoft.Inventory.Counting.Document;
using Microsoft.Inventory.Counting.Recording;
using Microsoft.Inventory.Counting.Tracking;
using Microsoft.Inventory.Tracking;
using System.Utilities;

report 5875 "Phys. Invt. Order Diff. List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Inventory/Counting/Reports/PhysInvtOrderDiffList.rdlc';
    ApplicationArea = Warehouse;
    Caption = 'Phys. Invt. Order Diff. List';
    UsageCategory = ReportsAndAnalysis;
    WordMergeDataItem = "Phys. Invt. Order Header";

    dataset
    {
        dataitem("Phys. Invt. Order Header"; "Phys. Invt. Order Header")
        {
            RequestFilterFields = "No.";
            column(Phys__Inventory_Order_Header_No_; "No.")
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
                column(Phys__Inventory_Order_Header___Posting_Date_; Format("Phys. Invt. Order Header"."Posting Date"))
                {
                }
                column(Phys__Inventory_Order_Header___No__; "Phys. Invt. Order Header"."No.")
                {
                }
                column(Phys__Inventory_Order_Header__Status; "Phys. Invt. Order Header".Status)
                {
                }
                column(Phys__Inventory_Order_Header___Person_Responsible_; "Phys. Invt. Order Header"."Person Responsible")
                {
                }
                column(Phys__Inventory_Order_Header___No__Finished_Recordings_; "Phys. Invt. Order Header"."No. Finished Recordings")
                {
                }
                column(Phys__Inventory_Order_Header__Description; "Phys. Invt. Order Header".Description)
                {
                }
                column(StatusInt; StatusInt)
                {
                }
                column(ShowDim; ShowDim)
                {
                }
                column(PageCounter_Number; Number)
                {
                }
                column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
                {
                }
                column(Phys__Inventory_Order_Difference_ListCaption; Phys__Inventory_Order_Difference_ListCaptionLbl)
                {
                }
                column(Phys__Inventory_Order_Header___Posting_Date_Caption; Phys__Inventory_Order_Header___Posting_Date_CaptionLbl)
                {
                }
                column(Phys__Inventory_Order_Header___No__Caption; "Phys. Invt. Order Header".FieldCaption("No."))
                {
                }
                column(Phys__Inventory_Order_Header__StatusCaption; "Phys. Invt. Order Header".FieldCaption(Status))
                {
                }
                column(Phys__Inventory_Order_Header___Person_Responsible_Caption; "Phys. Invt. Order Header".FieldCaption("Person Responsible"))
                {
                }
                column(Phys__Inventory_Order_Header___No__Finished_Recordings_Caption; "Phys. Invt. Order Header".FieldCaption("No. Finished Recordings"))
                {
                }
                column(Phys__Inventory_Order_Header__DescriptionCaption; "Phys. Invt. Order Header".FieldCaption(Description))
                {
                }
                dataitem("Phys. Invt. Order Line"; "Phys. Invt. Order Line")
                {
                    DataItemLink = "Document No." = field("No.");
                    DataItemLinkReference = "Phys. Invt. Order Header";
                    DataItemTableView = sorting("Document No.", "Line No.");
                    column(Phys__Inventory_Order_Line__Item_No__; "Item No.")
                    {
                    }
                    column(Phys__Inventory_Order_Line__Location_Code_; "Location Code")
                    {
                    }
                    column(Phys__Inventory_Order_Line__Bin_Code_; "Bin Code")
                    {
                    }
                    column(Phys__Inventory_Order_Line_Description; Description)
                    {
                    }
                    column(Phys__Inventory_Order_Line__Base_Unit_of_Measure_Code_; "Base Unit of Measure Code")
                    {
                    }
                    column(Phys__Inventory_Order_Line__Qty__Expected__Base__; "Qty. Expected (Base)")
                    {
                    }
                    column(Phys__Inventory_Order_Line__Variant_Code_; "Variant Code")
                    {
                    }
                    column(Phys__Inventory_Order_Line__Qty__Recorded__Base__; "Qty. Recorded (Base)")
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
                    column(Phys__Inventory_Order_Line__No__Finished_Rec__Lines_; "No. Finished Rec.-Lines")
                    {
                    }
                    column(Phys__Inventory_Order_Line__Recorded_without_Order_; Format("Recorded Without Order"))
                    {
                    }
                    column(Phys__Inventory_Order_Line__Qty__Exp__Calculated_; "Qty. Exp. Calculated")
                    {
                    }
                    column(Phys__Inventory_Order_Line__In_Recording_Lines_; "On Recording Lines")
                    {
                    }
                    column(Phys__Inventory_Order_Line__Item_No___Control95; "Item No.")
                    {
                    }
                    column(Phys__Inventory_Order_Line__Location_Code__Control96; "Location Code")
                    {
                    }
                    column(Phys__Inventory_Order_Line__Bin_Code__Control97; "Bin Code")
                    {
                    }
                    column(Phys__Inventory_Order_Line_Description_Control98; Description)
                    {
                    }
                    column(Phys__Inventory_Order_Line__Base_Unit_of_Measure_Code__Control99; "Base Unit of Measure Code")
                    {
                    }
                    column(Phys__Inventory_Order_Line__Qty__Expected__Base___Control100; "Qty. Expected (Base)")
                    {
                    }
                    column(Phys__Inventory_Order_Line__Variant_Code__Control101; "Variant Code")
                    {
                    }
                    column(Phys__Inventory_Order_Line__Qty__Recorded__Base___Control102; "Qty. Recorded (Base)")
                    {
                    }
                    column(Text1000; UndefinedLbl)
                    {
                    }
                    column(Text1000_Control104; UndefinedLbl)
                    {
                    }
                    column(Text1000_Control105; UndefinedLbl)
                    {
                    }
                    column(Text1000_Control106; UndefinedLbl)
                    {
                    }
                    column(Phys__Inventory_Order_Line__No__Finished_Rec__Lines__Control107; "No. Finished Rec.-Lines")
                    {
                    }
                    column(Phys__Inventory_Order_Line__Recorded_without_Order__Control108; "Recorded Without Order")
                    {
                    }
                    column(Phys__Inventory_Order_Line__Item_No___Control109; "Item No.")
                    {
                    }
                    column(Phys__Inventory_Order_Line__Location_Code__Control110; "Location Code")
                    {
                    }
                    column(Phys__Inventory_Order_Line__Bin_Code__Control111; "Bin Code")
                    {
                    }
                    column(Phys__Inventory_Order_Line_Description_Control112; Description)
                    {
                    }
                    column(Phys__Inventory_Order_Line__Base_Unit_of_Measure_Code__Control113; "Base Unit of Measure Code")
                    {
                    }
                    column(Text1000_Control114; UndefinedLbl)
                    {
                    }
                    column(Phys__Inventory_Order_Line__Variant_Code__Control115; "Variant Code")
                    {
                    }
                    column(Phys__Inventory_Order_Line__Qty__Recorded__Base___Control116; "Qty. Recorded (Base)")
                    {
                    }
                    column(Text1000_Control117; UndefinedLbl)
                    {
                    }
                    column(Text1000_Control118; UndefinedLbl)
                    {
                    }
                    column(Text1000_Control119; UndefinedLbl)
                    {
                    }
                    column(Text1000_Control120; UndefinedLbl)
                    {
                    }
                    column(Phys__Inventory_Order_Line__No__Finished_Rec__Lines__Control121; "No. Finished Rec.-Lines")
                    {
                    }
                    column(Phys__Inventory_Order_Line__Recorded_without_Order__Control122; "Recorded Without Order")
                    {
                    }
                    column(Phys__Inventory_Order_Line__Item_No___Control123; "Item No.")
                    {
                    }
                    column(Phys__Inventory_Order_Line__Location_Code__Control124; "Location Code")
                    {
                    }
                    column(Phys__Inventory_Order_Line__Bin_Code__Control125; "Bin Code")
                    {
                    }
                    column(Phys__Inventory_Order_Line_Description_Control126; Description)
                    {
                    }
                    column(Phys__Inventory_Order_Line__Base_Unit_of_Measure_Code__Control127; "Base Unit of Measure Code")
                    {
                    }
                    column(Phys__Inventory_Order_Line__Qty__Expected__Base___Control128; "Qty. Expected (Base)")
                    {
                    }
                    column(Phys__Inventory_Order_Line__Variant_Code__Control129; "Variant Code")
                    {
                    }
                    column(Text1000_Control130; UndefinedLbl)
                    {
                    }
                    column(Text1000_Control131; UndefinedLbl)
                    {
                    }
                    column(Text1000_Control132; UndefinedLbl)
                    {
                    }
                    column(Text1000_Control133; UndefinedLbl)
                    {
                    }
                    column(Phys__Inventory_Order_Line__No__Finished_Rec__Lines__Control134; "No. Finished Rec.-Lines")
                    {
                    }
                    column(Phys__Inventory_Order_Line__Recorded_without_Order__Control135; "Recorded Without Order")
                    {
                    }
                    column(Text1000_Control136; UndefinedLbl)
                    {
                    }
                    column(Phys__Inventory_Order_Line__Item_No___Control137; "Item No.")
                    {
                    }
                    column(Phys__Inventory_Order_Line__Location_Code__Control138; "Location Code")
                    {
                    }
                    column(Phys__Inventory_Order_Line__Bin_Code__Control139; "Bin Code")
                    {
                    }
                    column(Phys__Inventory_Order_Line_Description_Control140; Description)
                    {
                    }
                    column(Phys__Inventory_Order_Line__Base_Unit_of_Measure_Code__Control141; "Base Unit of Measure Code")
                    {
                    }
                    column(Text1000_Control142; UndefinedLbl)
                    {
                    }
                    column(Phys__Inventory_Order_Line__Variant_Code__Control143; "Variant Code")
                    {
                    }
                    column(Text1000_Control144; UndefinedLbl)
                    {
                    }
                    column(Text1000_Control145; UndefinedLbl)
                    {
                    }
                    column(Text1000_Control146; UndefinedLbl)
                    {
                    }
                    column(Text1000_Control147; UndefinedLbl)
                    {
                    }
                    column(Phys__Inventory_Order_Line__No__Finished_Rec__Lines__Control148; "No. Finished Rec.-Lines")
                    {
                    }
                    column(Phys__Inventory_Order_Line__Recorded_without_Order__Control149; "Recorded Without Order")
                    {
                    }
                    column(Text1000_Control150; UndefinedLbl)
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
                    column(Phys__Inventory_Order_Line_Document_No_; "Document No.")
                    {
                    }
                    column(Phys__Inventory_Order_Line_Line_No_; "Line No.")
                    {
                    }
                    column(Phys__Inventory_Order_Line__Item_No__Caption; FieldCaption("Item No."))
                    {
                    }
                    column(Phys__Inventory_Order_Line__Location_Code_Caption; FieldCaption("Location Code"))
                    {
                    }
                    column(Phys__Inventory_Order_Line__Bin_Code_Caption; FieldCaption("Bin Code"))
                    {
                    }
                    column(Phys__Inventory_Order_Line_DescriptionCaption; FieldCaption(Description))
                    {
                    }
                    column(Phys__Inventory_Order_Line__Base_Unit_of_Measure_Code_Caption; FieldCaption("Base Unit of Measure Code"))
                    {
                    }
                    column(Phys__Inventory_Order_Line__Qty__Expected__Base__Caption; FieldCaption("Qty. Expected (Base)"))
                    {
                    }
                    column(Phys__Inventory_Order_Line__Variant_Code_Caption; FieldCaption("Variant Code"))
                    {
                    }
                    column(Phys__Inventory_Order_Line__Qty__Recorded__Base__Caption; FieldCaption("Qty. Recorded (Base)"))
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
                    column(Phys__Inventory_Order_Line__No__Finished_Rec__Lines_Caption; FieldCaption("No. Finished Rec.-Lines"))
                    {
                    }
                    column(Phys__Inventory_Order_Line__Recorded_without_Order_Caption; Phys__Inventory_Order_Line__Recorded_without_Order_CaptionLbl)
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
                        column(TempPhysInvtCountBuffer__Exp__Qty___Base___Control58; TempPhysInvtCountBuffer."Exp. Qty. (Base)")
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(TempPhysInvtCountBuffer__Rec__Qty___Base___Control62; TempPhysInvtCountBuffer."Rec. Qty. (Base)")
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(TempPhysInvtCountBuffer__Track__Qty__Pos___Base___Control63; TempPhysInvtCountBuffer."Track. Qty. Pos. (Base)")
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(TempPhysInvtCountBuffer__Track__Qty__Neg___Base___Control81; TempPhysInvtCountBuffer."Track. Qty. Neg. (Base)")
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(DiffListBufferLoop_Number; Number)
                        {
                        }
                        column(TempPhysInvtCountBuffer__Exp__Serial_No__Caption; TempPhysInvtCountBuffer__Exp__Serial_No__CaptionLbl)
                        {
                        }
                        column(TempPhysInvtCountBuffer__Exp__Lot_No__Caption; TempPhysInvtCountBuffer__Exp__Lot_No__CaptionLbl)
                        {
                        }
                        column(TempPhysInvtCountBuffer__Exp__Qty___Base__Caption; TempPhysInvtCountBuffer__Exp__Qty___Base__CaptionLbl)
                        {
                        }
                        column(TempPhysInvtCountBuffer__Rec__No__Caption; TempPhysInvtCountBuffer__Rec__No__CaptionLbl)
                        {
                        }
                        column(TempPhysInvtCountBuffer__Rec__Serial_No__Caption; TempPhysInvtCountBuffer__Rec__Serial_No__CaptionLbl)
                        {
                        }
                        column(TempPhysInvtCountBuffer__Rec__Lot_No__Caption; TempPhysInvtCountBuffer__Rec__Lot_No__CaptionLbl)
                        {
                        }
                        column(TempPhysInvtCountBuffer__Rec__Qty___Base__Caption; TempPhysInvtCountBuffer__Rec__Qty___Base__CaptionLbl)
                        {
                        }
                        column(TempPhysInvtCountBuffer__Track__Serial_No__Caption; TempPhysInvtCountBuffer__Track__Serial_No__CaptionLbl)
                        {
                        }
                        column(TempPhysInvtCountBuffer__Track__Lot_No__Caption; TempPhysInvtCountBuffer__Track__Lot_No__CaptionLbl)
                        {
                        }
                        column(TempPhysInvtCountBuffer__Track__Qty__Neg___Base__Caption; TempPhysInvtCountBuffer__Track__Qty__Neg___Base__CaptionLbl)
                        {
                        }
                        column(TempPhysInvtCountBuffer__Track__Qty__Pos___Base__Caption; TempPhysInvtCountBuffer__Track__Qty__Pos___Base__CaptionLbl)
                        {
                        }
                        column(Expected_Tracking_LinesCaption; Expected_Tracking_LinesCaptionLbl)
                        {
                        }
                        column(Recording_LinesCaption; Recording_LinesCaptionLbl)
                        {
                        }
                        column(Item_Tracking_LinesCaption; Item_Tracking_LinesCaptionLbl)
                        {
                        }
                        column(TotalsCaption_Control82; TotalsCaption_Control82Lbl)
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
                        column(Number; Number)
                        {
                        }
                        column(DimText_Control44; DimText)
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
                                    DimText := StrSubstNo('%1 - %2', DimSetEntry."Dimension Code", DimSetEntry."Dimension Value Code")
                                else
                                    DimText :=
                                      StrSubstNo(
                                        '%1; %2 - %3', DimText, DimSetEntry."Dimension Code", DimSetEntry."Dimension Value Code");
                                if StrLen(DimText) > MaxStrLen(OldDimText) then begin
                                    DimText := OldDimText;
                                    Continue := true;
                                    exit;
                                end;
                            until (DimSetEntry.Next() = 0);
                        end;

                        trigger OnPreDataItem()
                        begin
                            if not ShowDim then
                                CurrReport.Break();

                            if LineIsEmpty then
                                CurrReport.Break();
                        end;
                    }
                    dataitem("Integer"; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = const(1));
                    }

                    trigger OnAfterGetRecord()
                    begin
                        LineIsEmpty := EmptyLine();

                        QtyPos := 0;
                        QtyNeg := 0;
                        AmountPos := 0;
                        AmountNeg := 0;

                        if not LineIsEmpty then begin
                            DimSetEntry.SetRange("Dimension Set ID", "Dimension Set ID");
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
                        end;

                        // Tracking Information:
                        TempPhysInvtCountBuffer.DeleteAll();
                        NoOfBufferLines := 0;
                        if not LineIsEmpty and "Use Item Tracking" then
                            CreateDiffListBuffer("Phys. Invt. Order Line", NoOfBufferLines);

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

            trigger OnAfterGetRecord()
            begin
                StatusInt := Status.AsInteger();
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
        StatusInt: Integer;
        NewAmountPos: Decimal;
        NewAmountNeg: Decimal;
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Phys__Inventory_Order_Difference_ListCaptionLbl: Label 'Phys. Inventory Order Difference List';
        Phys__Inventory_Order_Header___Posting_Date_CaptionLbl: Label 'Posting Date';
        UndefinedLbl: Label 'Undefined';
        QtyPosCaptionLbl: Label 'Qty. Pos.';
        QtyNegCaptionLbl: Label 'Qty. Neg.';
        AmountPosCaptionLbl: Label 'Amount Pos.';
        AmountNegCaptionLbl: Label 'Amount Neg.';
        Phys__Inventory_Order_Line__Recorded_without_Order_CaptionLbl: Label 'Recorded Without Order';
        TotalsCaptionLbl: Label 'Totals';
        TempPhysInvtCountBuffer__Exp__Serial_No__CaptionLbl: Label 'Serial No.';
        TempPhysInvtCountBuffer__Exp__Lot_No__CaptionLbl: Label 'Lot No.';
        TempPhysInvtCountBuffer__Exp__Qty___Base__CaptionLbl: Label 'Exp. Qty. (Base)';
        TempPhysInvtCountBuffer__Rec__No__CaptionLbl: Label 'Recording No.';
        TempPhysInvtCountBuffer__Rec__Serial_No__CaptionLbl: Label 'Serial No.';
        TempPhysInvtCountBuffer__Rec__Lot_No__CaptionLbl: Label 'Lot No.';
        TempPhysInvtCountBuffer__Rec__Qty___Base__CaptionLbl: Label 'Recorded Qty. (Base)';
        TempPhysInvtCountBuffer__Track__Serial_No__CaptionLbl: Label 'Serial No.';
        TempPhysInvtCountBuffer__Track__Lot_No__CaptionLbl: Label 'Lot No.';
        TempPhysInvtCountBuffer__Track__Qty__Neg___Base__CaptionLbl: Label 'Qty Neg. (Base)';
        TempPhysInvtCountBuffer__Track__Qty__Pos___Base__CaptionLbl: Label 'Qty. Pos. (Base)';
        Expected_Tracking_LinesCaptionLbl: Label 'Expected Item Tracking';
        Recording_LinesCaptionLbl: Label 'Recording Lines';
        Item_Tracking_LinesCaptionLbl: Label 'Item Tracking Lines';
        TotalsCaption_Control82Lbl: Label 'Totals';
        DimTextCaptionLbl: Label 'Line Dimensions';

    procedure CreateDiffListBuffer(PhysInvtOrderLine: Record "Phys. Invt. Order Line"; var NoOfBufferLines: Integer)
    var
        ExpInvtOrderTracking: Record "Exp. Invt. Order Tracking";
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
        ReservEntry: Record "Reservation Entry";
        NextLineNo: Integer;
    begin
        NoOfBufferLines := 0;
        NextLineNo := 1;
        ExpInvtOrderTracking.Reset();
        ExpInvtOrderTracking.SetRange("Order No", PhysInvtOrderLine."Document No.");
        ExpInvtOrderTracking.SetRange("Order Line No.", PhysInvtOrderLine."Line No.");
        if ExpInvtOrderTracking.FindSet() then
            repeat
                FindOrCreateDiffListBuffer(NoOfBufferLines, NextLineNo);
                TempPhysInvtCountBuffer."Exp. Serial No." := ExpInvtOrderTracking."Serial No.";
                TempPhysInvtCountBuffer."Exp. Lot No." := ExpInvtOrderTracking."Lot No.";
                TempPhysInvtCountBuffer."Exp. Package No." := ExpInvtOrderTracking."Package No.";
                TempPhysInvtCountBuffer."Exp. Qty. (Base)" := ExpInvtOrderTracking."Quantity (Base)";
                TempPhysInvtCountBuffer.Modify();
            until ExpInvtOrderTracking.Next() = 0;
        NextLineNo := 1;
        PhysInvtRecordLine.Reset();
        PhysInvtRecordLine.SetCurrentKey("Order No.", "Order Line No.");
        PhysInvtRecordLine.SetRange("Order No.", PhysInvtOrderLine."Document No.");
        PhysInvtRecordLine.SetRange("Order Line No.", PhysInvtOrderLine."Line No.");
        if PhysInvtRecordLine.Find('-') then
            repeat
                FindOrCreateDiffListBuffer(NoOfBufferLines, NextLineNo);
                TempPhysInvtCountBuffer."Rec. No." := PhysInvtRecordLine."Recording No.";
                TempPhysInvtCountBuffer."Rec. Line No." := PhysInvtRecordLine."Line No.";
                TempPhysInvtCountBuffer."Rec. Serial No." := PhysInvtRecordLine."Serial No.";
                TempPhysInvtCountBuffer."Rec. Lot No." := PhysInvtRecordLine."Lot No.";
                TempPhysInvtCountBuffer."Rec. Qty. (Base)" := PhysInvtRecordLine."Quantity (Base)";
                TempPhysInvtCountBuffer.Modify();
            until PhysInvtRecordLine.Next() = 0;

        NextLineNo := 1;
        ReservEntry.Reset();
        ReservEntry.SetSourceFilter(DATABASE::"Phys. Invt. Order Line", 0, PhysInvtOrderLine."Document No.", PhysInvtOrderLine."Line No.", true);
        ReservEntry.SetSourceFilter('', 0);
        if ReservEntry.FindSet() then
            repeat
                FindOrCreateDiffListBuffer(NoOfBufferLines, NextLineNo);
                TempPhysInvtCountBuffer."Track. Serial No." := ReservEntry."Serial No.";
                TempPhysInvtCountBuffer."Track. Lot No." := ReservEntry."Lot No.";
                if ReservEntry.Positive then begin
                    TempPhysInvtCountBuffer."Track. Qty. Neg. (Base)" := 0;
                    TempPhysInvtCountBuffer."Track. Qty. Pos. (Base)" := ReservEntry.Quantity;
                end else begin
                    TempPhysInvtCountBuffer."Track. Qty. Neg. (Base)" := ReservEntry.Quantity;
                    TempPhysInvtCountBuffer."Track. Qty. Pos. (Base)" := 0;
                end;
                TempPhysInvtCountBuffer.Modify();
            until ReservEntry.Next() = 0;
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
}

