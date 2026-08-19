// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Analysis;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Setup;

codeunit 7111 "Insert Analysis Line"
{

    trigger OnRun()
    begin
    end;

    procedure InsertItems(var AnalysisLine: Record "Analysis Line")
    var
        Item: Record Item;
        ItemList: Page "Item List";
        ItemCount: Integer;
        AnalysisLineNo: Integer;
    begin
        ItemList.LookupMode(true);
        if ItemList.RunModal() = ACTION::LookupOK then begin
            ItemList.SetSelection(Item);
            ItemCount := Item.Count();
            if ItemCount > 0 then begin
                MoveAnalysisLines(AnalysisLine, AnalysisLineNo, ItemCount);

                if Item.Find('-') then
                    repeat
                        InsertAnalysisLine(
                          AnalysisLine, AnalysisLineNo,
                          Item.Description, Item."No.", AnalysisLine.Type::Item, false, 0);
                    until Item.Next() = 0;
            end;
        end;
    end;

    procedure InsertCust(var AnalysisLine: Record "Analysis Line")
    var
        Cust: Record Customer;
        CustList: Page "Customer List";
        CustCount: Integer;
        AnalysisLineNo: Integer;
    begin
        CustList.LookupMode(true);
        if CustList.RunModal() = ACTION::LookupOK then begin
            CustList.SetSelection(Cust);
            CustCount := Cust.Count();
            if CustCount > 0 then begin
                MoveAnalysisLines(AnalysisLine, AnalysisLineNo, CustCount);

                if Cust.Find('-') then
                    repeat
                        InsertAnalysisLine(
                          AnalysisLine, AnalysisLineNo,
                          Cust.Name, Cust."No.", AnalysisLine.Type::Customer, false, 0);
                    until Cust.Next() = 0;
            end;
        end;
    end;

    procedure InsertVend(var AnalysisLine: Record "Analysis Line")
    var
        Vend: Record Vendor;
        VendList: Page "Vendor List";
        VendCount: Integer;
        AnalysisLineNo: Integer;
    begin
        VendList.LookupMode(true);
        if VendList.RunModal() = ACTION::LookupOK then begin
            VendList.SetSelection(Vend);
            VendCount := Vend.Count();
            if VendCount > 0 then begin
                MoveAnalysisLines(AnalysisLine, AnalysisLineNo, VendCount);

                if Vend.Find('-') then
                    repeat
                        InsertAnalysisLine(
                          AnalysisLine, AnalysisLineNo,
                          Vend.Name, Vend."No.", AnalysisLine.Type::Vendor, false, 0);
                    until Vend.Next() = 0;
            end;
        end;
    end;

    procedure InsertItemGrDim(var AnalysisLine: Record "Analysis Line")
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup.TestField("Item Group Dimension Code");
        InsertGroup(
          AnalysisLine,
          InventorySetup."Item Group Dimension Code",
          AnalysisLine.Type::"Item Group");
    end;

    procedure InsertCustGrDim(var AnalysisLine: Record "Analysis Line")
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        SalesSetup.Get();
        SalesSetup.TestField("Customer Group Dimension Code");
        InsertGroup(
          AnalysisLine,
          SalesSetup."Customer Group Dimension Code",
          AnalysisLine.Type::"Customer Group");
    end;

    procedure InsertSalespersonPurchaser(var AnalysisLine: Record "Analysis Line")
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        SalesSetup.Get();
        SalesSetup.TestField("Salesperson Dimension Code");
        InsertGroup(
          AnalysisLine,
          SalesSetup."Salesperson Dimension Code",
          AnalysisLine.Type::"Sales/Purchase person");
    end;

    procedure InsertGroup(var AnalysisLine: Record "Analysis Line"; GroupDimCode: Code[20]; TotalingType: Enum "Analysis Line Type")
    var
        DimVal: Record "Dimension Value";
        DimValList: Page "Dimension Value List";
        DimValCount: Integer;
        AnalysisLineNo: Integer;
    begin
        DimVal.FilterGroup := 2;
        DimVal.SetRange("Dimension Code", GroupDimCode);
        DimVal.FilterGroup := 0;
        DimValList.SetTableView(DimVal);
        DimValList.LookupMode(true);
        if DimValList.RunModal() = ACTION::LookupOK then begin
            DimValList.SetSelection(DimVal);
            DimValCount := DimVal.Count();
            if DimValCount > 0 then begin
                MoveAnalysisLines(AnalysisLine, AnalysisLineNo, DimValCount);

                if DimVal.Find('-') then
                    repeat
                        InsertAnalysisLine(
                          AnalysisLine, AnalysisLineNo,
                          DimVal.Name, DimVal.Code, TotalingType,
                          DimVal."Dimension Value Type" <> DimVal."Dimension Value Type"::Standard,
                          DimVal.Indentation);
                    until DimVal.Next() = 0;
            end;
        end;
    end;

    local procedure MoveAnalysisLines(var AnalysisLine: Record "Analysis Line"; var AnalysisLineNo: Integer; NewLineCount: Integer)
    var
        i: Integer;
    begin
        AnalysisLineNo := AnalysisLine."Line No.";
        AnalysisLine.SetRange("Analysis Area", AnalysisLine."Analysis Area");
        AnalysisLine.SetRange("Analysis Line Template Name", AnalysisLine."Analysis Line Template Name");
        if AnalysisLine.Find('+') then
            repeat
                i := AnalysisLine."Line No.";
                if i >= AnalysisLineNo then begin
                    AnalysisLine.Delete();
                    AnalysisLine."Line No." := i + 10000 * NewLineCount;
                    AnalysisLine.Insert(true);
                end;
            until (i <= AnalysisLineNo) or (AnalysisLine.Next(-1) = 0);

        if AnalysisLineNo = 0 then
            AnalysisLineNo := 10000;
    end;

    local procedure InsertAnalysisLine(var AnalysisLine: Record "Analysis Line"; var AnalysisLineNo: Integer; Text: Text[100]; No: Code[20]; Type2: Enum "Analysis Line Type"; Bold2: Boolean; Indent: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertAnalysisLine(AnalysisLine, AnalysisLineNo, Text, No, Type2, Bold2, Indent, IsHandled);
        if IsHandled then
            exit;

        AnalysisLine.Init();
        AnalysisLine."Line No." := AnalysisLineNo;
        AnalysisLineNo := AnalysisLineNo + 10000;
        AnalysisLine.Description := Text;
        AnalysisLine.Range := No;
        AnalysisLine."Row Ref. No." := CopyStr(No, 1, MaxStrLen(AnalysisLine."Row Ref. No."));
        AnalysisLine.Type := Type2;
        AnalysisLine.Bold := Bold2;
        AnalysisLine.Indentation := Indent;
        AnalysisLine.Insert(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertAnalysisLine(var AnalysisLine: Record "Analysis Line"; var AnalysisLineNo: Integer; Text: Text[100]; No: Code[20]; Type2: Enum "Analysis Line Type"; Bold2: Boolean; Indent: Integer; var IsHandled: Boolean)
    begin
    end;
}

