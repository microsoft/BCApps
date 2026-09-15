// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.StandardCost;

reportextension 99000781 "Mfg. CalcInventoryValueTest" extends "Calc. Inventory Value - Test"
{
    dataset
    {
        addafter(ItemLedgEntryErrBufLoop)
        {
            dataitem(ProdBOMVersionErrBufLoop; System.Utilities.Integer)
            {
                DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                column(Text002; Text002Lbl)
                {
                }
                column(ProdBOMVersionErrBuf__Production_BOM_No__; TempProdBOMVersionErrBuf."Production BOM No.")
                {
                }
                column(ProdBOMVersionErrBuf__Version_Code_; TempProdBOMVersionErrBuf."Version Code")
                {
                }
                column(ProdBOMVersionErrBuf_Description; TempProdBOMVersionErrBuf.Description)
                {
                }
                column(ProdBOMVersionErrBuf__Starting_Date_; Format(TempProdBOMVersionErrBuf."Starting Date"))
                {
                }
                column(ProdBOMVersionErrBuf_Status; TempProdBOMVersionErrBuf.Status)
                {
                }
                column(Text002Caption; Text002CaptionLbl)
                {
                }
                column(ProdBOMVersionErrBuf_StatusCaption; ProdBOMVersionErrBuf_StatusCaptionLbl)
                {
                }
                column(ProdBOMVersionErrBuf__Starting_Date_Caption; ProdBOMVersionErrBuf__Starting_Date_CaptionLbl)
                {
                }
                column(ProdBOMVersionErrBuf_DescriptionCaption; ProdBOMVersionErrBuf_DescriptionCaptionLbl)
                {
                }
                column(ProdBOMVersionErrBuf__Version_Code_Caption; ProdBOMVersionErrBuf__Version_Code_CaptionLbl)
                {
                }
                column(ProdBOMVersionErrBuf__Production_BOM_No__Caption; ProdBOMVersionErrBuf__Production_BOM_No__CaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                var
                    OK: Boolean;
                begin
                    if Number = 1 then
                        OK := TempProdBOMVersionErrBuf.Find('-')
                    else
                        OK := TempProdBOMVersionErrBuf.Next() <> 0;
                    if not OK then
                        CurrReport.Break();

                    if TempProdBOMVersionErrBuf."Version Code" = '' then begin
                        ProdBOMHeader.Get(TempProdBOMVersionErrBuf."Production BOM No.");
                        TempProdBOMVersionErrBuf.Description := ProdBOMHeader.Description;
                        TempProdBOMVersionErrBuf.Status := ProdBOMHeader.Status;
                    end else begin
                        ProdBOMVersion.Get(TempProdBOMVersionErrBuf."Production BOM No.", TempProdBOMVersionErrBuf."Version Code");
                        TempProdBOMVersionErrBuf.Description := ProdBOMVersion.Description;
                        TempProdBOMVersionErrBuf."Starting Date" := ProdBOMVersion."Starting Date";
                        TempProdBOMVersionErrBuf.Status := ProdBOMVersion.Status;
                    end;
                    TempProdBOMVersionErrBuf.Modify();
                end;
            }
            dataitem(RtngVersionErrBufLoop; System.Utilities.Integer)
            {
                DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                column(Text003; Text003Lbl)
                {
                }
                column(RtngVersionErrBuf_Status; TempRtngVersionErrBuf.Status)
                {
                }
                column(RtngVersionErrBuf__Starting_Date_; Format(TempRtngVersionErrBuf."Starting Date"))
                {
                }
                column(RtngVersionErrBuf_Description; TempRtngVersionErrBuf.Description)
                {
                }
                column(RtngVersionErrBuf__Version_Code_; TempRtngVersionErrBuf."Version Code")
                {
                }
                column(RtngVersionErrBuf__Routing_No__; TempRtngVersionErrBuf."Routing No.")
                {
                }
                column(Text003Caption; Text003CaptionLbl)
                {
                }
                column(RtngVersionErrBuf_StatusCaption; RtngVersionErrBuf_StatusCaptionLbl)
                {
                }
                column(RtngVersionErrBuf__Starting_Date_Caption; RtngVersionErrBuf__Starting_Date_CaptionLbl)
                {
                }
                column(RtngVersionErrBuf_DescriptionCaption; RtngVersionErrBuf_DescriptionCaptionLbl)
                {
                }
                column(RtngVersionErrBuf__Version_Code_Caption; RtngVersionErrBuf__Version_Code_CaptionLbl)
                {
                }
                column(RtngVersionErrBuf__Routing_No__Caption; RtngVersionErrBuf__Routing_No__CaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                var
                    OK: Boolean;
                begin
                    if Number = 1 then
                        OK := TempRtngVersionErrBuf.Find('-')
                    else
                        OK := TempRtngVersionErrBuf.Next() <> 0;
                    if not OK then
                        CurrReport.Break();

                    if TempRtngVersionErrBuf."Version Code" = '' then begin
                        RtngHeader.Get(TempRtngVersionErrBuf."Routing No.");
                        TempRtngVersionErrBuf.Description := RtngHeader.Description;
                        TempRtngVersionErrBuf.Status := RtngHeader.Status;
                    end else begin
                        RtngVersion.Get(TempRtngVersionErrBuf."Routing No.", TempRtngVersionErrBuf."Version Code");
                        TempRtngVersionErrBuf.Description := RtngVersion.Description;
                        TempRtngVersionErrBuf."Starting Date" := RtngVersion."Starting Date";
                        TempRtngVersionErrBuf.Status := RtngVersion.Status;
                    end;
                    TempRtngVersionErrBuf.Modify();
                end;
            }
        }
    }

    var
        ProdBOMHeader: Record "Production BOM Header";
        ProdBOMVersion: Record "Production BOM Version";
        RtngHeader: Record "Routing Header";
        RtngVersion: Record "Routing Version";
        CalcStdCost: Codeunit "Calculate Standard Cost";

        Text002Lbl: Label 'The standard cost cannot be calculated before the following production BOMs are certified.';
        Text002CaptionLbl: Label 'Warning!';
        ProdBOMVersionErrBuf_StatusCaptionLbl: Label 'Status';
        ProdBOMVersionErrBuf__Starting_Date_CaptionLbl: Label 'Starting Date';
        ProdBOMVersionErrBuf_DescriptionCaptionLbl: Label 'Description';
        ProdBOMVersionErrBuf__Version_Code_CaptionLbl: Label 'Version Code';
        ProdBOMVersionErrBuf__Production_BOM_No__CaptionLbl: Label 'No.';
        Text003Lbl: Label 'The standard cost cannot be calculated before the following production routings are certified.';
        Text003CaptionLbl: Label 'Warning!';
        RtngVersionErrBuf_StatusCaptionLbl: Label 'Status';
        RtngVersionErrBuf__Starting_Date_CaptionLbl: Label 'Starting Date';
        RtngVersionErrBuf_DescriptionCaptionLbl: Label 'Description';
        RtngVersionErrBuf__Version_Code_CaptionLbl: Label 'Version Code';
        RtngVersionErrBuf__Routing_No__CaptionLbl: Label 'Routing No.';

    protected var
        TempProdBOMVersionErrBuf: Record Microsoft.Manufacturing.ProductionBOM."Production BOM Version" temporary;
        TempRtngVersionErrBuf: Record Microsoft.Manufacturing.Routing."Routing Version" temporary;

    internal procedure CalculateStandardCost(var Item: Record Item; PostingDate: Date; CalcBase: Enum "Inventory Value Calc. Base")
    begin
        if CalcBase = CalcBase::"Standard Cost - Manufacturing" then begin
            CalcStdCost.SetProperties(PostingDate, true, false, true, '', true);
            CalcStdCost.TestPreconditions(Item, TempProdBOMVersionErrBuf, TempRtngVersionErrBuf);
        end;
    end;
}