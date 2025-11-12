// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Structure;

page 9126 "Lot Numbers by Bin FactBox"
{
    Caption = 'Lot Numbers by Bin';
    PageType = ListPart;
    SourceTable = "Lot Bin Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control7)
            {
                ShowCaption = false;
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the item that exists as lot numbers in the bin.';
                    Visible = false;
                }
                field("Zone Code"; Rec."Zone Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the zone that is assigned to the bin where the lot number exists.';
                    Visible = false;
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the bin where the lot number exists.';
                }
                field("Lot No."; Rec."Lot No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the lot number that exists in the bin.';
                }
                field("Qty. (Base)"; Rec."Qty. (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies how many items with the lot number exist in the bin.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnFindRecord(Which: Text): Boolean
    begin
        FillTempTable();
        exit(Rec.Find(Which));
    end;

    local procedure FillTempTable()
    var
        LotNosByBinCode: Query "Lot Numbers by Bin";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFillTempTable(Rec, IsHandled);
        if IsHandled then
            exit;

        LotNosByBinCode.SetRange(Item_No, Rec.GetRangeMin("Item No."));
        LotNosByBinCode.SetRange(Variant_Code, Rec.GetRangeMin("Variant Code"));
        LotNosByBinCode.SetRange(Location_Code, Rec.GetRangeMin("Location Code"));
        LotNosByBinCode.SetFilter(Lot_No, '<>%1', '');
        OnFillTempTableOnAfterLotNosByBinCodeSetFilters(LotNosByBinCode);
        LotNosByBinCode.Open();

        Rec.DeleteAll();

        while LotNosByBinCode.Read() do begin
            Rec.Init();
            Rec."Item No." := LotNosByBinCode.Item_No;
            Rec."Variant Code" := LotNosByBinCode.Variant_Code;
            Rec."Zone Code" := LotNosByBinCode.Zone_Code;
            Rec."Bin Code" := LotNosByBinCode.Bin_Code;
            Rec."Location Code" := LotNosByBinCode.Location_Code;
            Rec."Lot No." := LotNosByBinCode.Lot_No;
            OnFillTempTableOnAfterPopulateLotNosByBinCodeFields(Rec, LotNosByBinCode);
            if Rec.Find() then begin
                Rec."Qty. (Base)" += LotNosByBinCode.Sum_Qty_Base;
                Rec.Modify();
            end else begin
                Rec."Qty. (Base)" := LotNosByBinCode.Sum_Qty_Base;
                Rec.Insert();
            end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFillTempTableOnAfterLotNosByBinCodeSetFilters(var LotNosByBinCode: Query "Lot Numbers by Bin")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFillTempTableOnAfterPopulateLotNosByBinCodeFields(var LotBinBuffer: record "Lot Bin Buffer"; var LotNosByBinCode: query "Lot Numbers by Bin")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFillTempTable(var LotBinBuffer: Record "Lot Bin Buffer"; var IsHandled: Boolean)
    begin
    end;
}

