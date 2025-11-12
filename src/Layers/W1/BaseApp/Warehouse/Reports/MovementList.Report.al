// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Reports;

using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Activity;
using System.Email;
using System.Utilities;

report 7301 "Movement List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Warehouse/Reports/MovementList.rdlc';
    AccessByPermission = TableData Location = R;
    ApplicationArea = Warehouse;
    Caption = 'Warehouse Movement';
    UsageCategory = Documents;
    WordMergeDataItem = "Warehouse Activity Header";

    dataset
    {
        dataitem("Warehouse Activity Header"; "Warehouse Activity Header")
        {
            DataItemTableView = sorting(Type, "No.") where(Type = filter(Movement | "Invt. Movement"));
            RequestFilterFields = "No.", "No. Printed";
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(CompanyName; COMPANYPROPERTY.DisplayName())
                {
                }
                column(WhseActivHeaderCaption; "Warehouse Activity Header".TableCaption + ': ' + MovementFilter)
                {
                }
                column(MovementFilter; MovementFilter)
                {
                }
                column(SumUpLines; SumUpLines)
                {
                }
                column(ShowLotSN; ShowLotSN)
                {
                }
                column(InvtMovement; InvtMovement)
                {
                }
                column(SortMethod_WhseActivHeader; "Warehouse Activity Header"."Sorting Method")
                {
                    IncludeCaption = true;
                }
                column(AssignedUserID_WhseActivHeader; "Warehouse Activity Header"."Assigned User ID")
                {
                    IncludeCaption = true;
                }
                column(No1_WhseActivHeader; "Warehouse Activity Header"."No.")
                {
                    IncludeCaption = true;
                }
                column(LocCode_WhseActivHeader; "Warehouse Activity Header"."Location Code")
                {
                    IncludeCaption = true;
                }
                column(SourceDoc_WhseActivLine; "Warehouse Activity Line"."Source Document")
                {
                    IncludeCaption = true;
                }
                column(LocationBinMandatory; Location."Bin Mandatory")
                {
                }
                column(MovementListCaption; MovementListCaptionLbl)
                {
                }
                column(DueDateCaption; DueDateCaptionLbl)
                {
                }
                column(QtyHandledCaption; QtyHandledCaptionLbl)
                {
                }
                column(SourceNoCaption; SourceNoCaptionLbl)
                {
                }
                column(DestinationTypeCaption; DestinationTypeCaptionLbl)
                {
                }
                column(DestinationNoCaption; DestinationNoCaptionLbl)
                {
                }
                column(ItemNoCaption; ItemNoCaptionLbl)
                {
                }
                column(DescriptionCaption; DescriptionCaptionLbl)
                {
                }
                column(VariantCodeCaption; VariantCodeCaptionLbl)
                {
                }
                column(ShelfNoCaption; ShelfNoCaptionLbl)
                {
                }
                column(QuantityBaseCaption; QuantityBaseCaptionLbl)
                {
                }
                column(QtytoHandleCaption; QtytoHandleCaptionLbl)
                {
                }
                column(UOMCodeCaption; UOMCodeCaptionLbl)
                {
                }
                column(ActionTypeCaption; ActionTypeCaptionLbl)
                {
                }
                column(ZoneCodeCaption; ZoneCodeCaptionLbl)
                {
                }
                column(BinCodeCaption; BinCodeCaptionLbl)
                {
                }
                dataitem("Warehouse Activity Line"; "Warehouse Activity Line")
                {
                    DataItemLink = "Activity Type" = field(Type), "No." = field("No.");
                    DataItemLinkReference = "Warehouse Activity Header";
                    DataItemTableView = sorting("Activity Type", "No.", "Sorting Sequence No.");

                    trigger OnAfterGetRecord()
                    begin
                        if SumUpLines then begin
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
                dataitem(WhseActivLine; "Warehouse Activity Line")
                {
                    DataItemLink = "Activity Type" = field(Type), "No." = field("No.");
                    DataItemLinkReference = "Warehouse Activity Header";
                    DataItemTableView = sorting("Activity Type", "No.", "Sorting Sequence No.");
                    column(SourceNo_WhseActivLine; "Source No.")
                    {
                        IncludeCaption = false;
                    }
                    column(SourceDocumentText; SourceDocumentText)
                    {
                    }
                    column(ShelfNo_WhseActivLine; "Shelf No.")
                    {
                        IncludeCaption = false;
                    }
                    column(ItemNo_WhseActivLine; "Item No.")
                    {
                        IncludeCaption = false;
                    }
                    column(Description_WhseActivLine; Description)
                    {
                        IncludeCaption = false;
                    }
                    column(VariantCode_WhseActivLine; "Variant Code")
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
                    column(QtytoHandle_WhseActivLine; "Qty. to Handle")
                    {
                        IncludeCaption = false;
                    }
                    column(QtyBase_WhseActivLine; "Qty. (Base)")
                    {
                        IncludeCaption = false;
                    }
                    column(DestType_WhseActivLine; "Destination Type")
                    {
                        IncludeCaption = false;
                    }
                    column(DestNo_WhseActivLine; "Destination No.")
                    {
                        IncludeCaption = false;
                    }
                    column(ZoneCode_WhseActivLine; "Zone Code")
                    {
                        IncludeCaption = false;
                    }
                    column(BinCode_WhseActivLine; "Bin Code")
                    {
                        IncludeCaption = false;
                    }
                    column(ActionType_WhseActivLine; "Action Type")
                    {
                        IncludeCaption = false;
                    }
                    column(LotNo_WhseActivLine; "Lot No.")
                    {
                        IncludeCaption = false;
                    }
                    column(SerialNo_WhseActivLine; "Serial No.")
                    {
                        IncludeCaption = true;
                    }
                    column(LineNo_WhseActivLine; "Line No.")
                    {
                    }
                    column(EmptyStringCaption; EmptyStringCaptionLbl)
                    {
                    }
                    dataitem(WhseActivLine2; "Warehouse Activity Line")
                    {
                        DataItemLink = "Activity Type" = field("Activity Type"), "No." = field("No."), "Bin Code" = field("Bin Code"), "Item No." = field("Item No."), "Action Type" = field("Action Type"), "Variant Code" = field("Variant Code"), "Unit of Measure Code" = field("Unit of Measure Code"), "Due Date" = field("Due Date");
                        DataItemTableView = sorting("Activity Type", "No.", "Bin Code", "Breakbulk No.", "Action Type");
                        column(LotNo_WhseActivLine2; "Lot No.")
                        {
                            IncludeCaption = true;
                        }
                        column(SerialNo_WhseActivLine2; "Serial No.")
                        {
                            IncludeCaption = true;
                        }
                        column(QtyBase_WhseActivLine2; "Qty. (Base)")
                        {
                        }
                        column(QtytoHandl_WhseActivLine2; "Qty. to Handle")
                        {
                        }
                        column(LineNo_WhseActivLine2; "Line No.")
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
                InvtMovement := Type = Type::"Invt. Movement";
                if InvtMovement then
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
        Caption = 'Movement List';
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(SetBreakbulkFilter; BreakbulkFilter)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Set Breakbulk Filter';
                        Editable = BreakbulkEditable;
                        ToolTip = 'Specifies if you do not want to view the intermediate lines the program creates, when it changes the unit of measure in movement instructions.';
                    }
                    field(SumUpLines; SumUpLines)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Sum up Lines';
                        Editable = SumUpLinesEditable;
                        ToolTip = 'Specifies if you want the program to sum up the lines for each item, for example, several movement lines originating from different source documents that concern the same item and bins.';
                    }
                    field(ShowSlNoLotNo; ShowLotSN)
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Show Serial/Lot Number';
                        ToolTip = 'Specifies if you want to show lot and serial number information for each line with items that use item tracking.';
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
    }

    trigger OnPreReport()
    begin
        MovementFilter := "Warehouse Activity Header".GetFilters();
    end;

    var
        Location: Record Location;
        TempWhseActivLine: Record "Warehouse Activity Line" temporary;
        MovementFilter: Text;
        SourceDocumentText: Text[30];
        BreakbulkFilter: Boolean;
        SumUpLines: Boolean;
        ShowLotSN: Boolean;
        HideOptions: Boolean;
        InvtMovement: Boolean;
        Counter: Integer;
        BreakbulkEditable: Boolean;
        SumUpLinesEditable: Boolean;
        MovementListCaptionLbl: Label 'Movement List';
        DueDateCaptionLbl: Label 'Due Date';
        QtyHandledCaptionLbl: Label 'Qty. Handled';
        SourceNoCaptionLbl: Label 'Source No.';
        DestinationTypeCaptionLbl: Label 'Destination Type';
        DestinationNoCaptionLbl: Label 'Destination No.';
        ItemNoCaptionLbl: Label 'Item No.';
        DescriptionCaptionLbl: Label 'Description';
        VariantCodeCaptionLbl: Label 'Variant Code';
        ShelfNoCaptionLbl: Label 'Shelf No.';
        QuantityBaseCaptionLbl: Label 'Qty. (Base)';
        QtytoHandleCaptionLbl: Label 'Qty. to Handle';
        UOMCodeCaptionLbl: Label 'Unit of Measure Code';
        ActionTypeCaptionLbl: Label 'Action Type';
        ZoneCodeCaptionLbl: Label 'Zone Code';
        BinCodeCaptionLbl: Label 'Bin Code';
        EmptyStringCaptionLbl: Label '____________';

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

    procedure SetInventory(SetHideOptions: Boolean)
    begin
        HideOptions := SetHideOptions;
    end;
}

