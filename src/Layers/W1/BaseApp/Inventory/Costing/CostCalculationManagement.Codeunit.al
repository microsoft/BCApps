// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using Microsoft.Assembly.History;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Transfer;
using Microsoft.Projects.Resources.Ledger;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Purchases.History;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;

codeunit 5836 "Cost Calculation Management"
{
    Permissions = TableData "Item Ledger Entry" = r,
                  TableData "Value Entry" = r;

    SingleInstance = true;

    procedure ResourceCostPerUnit(No: Code[20]; var DirUnitCost: Decimal; var IndirCostPct: Decimal; var OvhdRate: Decimal; var UnitCost: Decimal)
    var
        Resource: Record Resource;
    begin
        Resource.Get(No);
        DirUnitCost := Resource."Direct Unit Cost";
        OvhdRate := 0;
        IndirCostPct := Resource."Indirect Cost %";
        UnitCost := Resource."Unit Cost";
    end;

    procedure CalcDirCost(Cost: Decimal; OvhdCost: Decimal; VarPurchCost: Decimal): Decimal
    begin
        exit(Cost - OvhdCost - VarPurchCost);
    end;

    procedure CalcDirUnitCost(UnitCost: Decimal; OvhdRate: Decimal; IndirCostPct: Decimal): Decimal
    begin
        exit((UnitCost - OvhdRate) / (1 + IndirCostPct / 100));
    end;

    procedure CalcOvhdCost(DirCost: Decimal; IndirCostPct: Decimal; OvhdRate: Decimal; QtyBase: Decimal): Decimal
    begin
        exit(DirCost * IndirCostPct / 100 + OvhdRate * QtyBase);
    end;

    procedure CalcUnitCost(DirCost: Decimal; IndirCostPct: Decimal; OvhdRate: Decimal; RndgPrec: Decimal): Decimal
    begin
        exit(Round(DirCost * (1 + IndirCostPct / 100) + OvhdRate, RndgPrec));
    end;

    procedure GetRndgSetup(var GLSetup: Record "General Ledger Setup"; var Currency: Record Currency; var RndgSetupRead: Boolean)
    begin
        if RndgSetupRead then
            exit;
        GLSetup.Get();
        GLSetup.TestField("Amount Rounding Precision");
        GLSetup.TestField("Unit-Amount Rounding Precision");
        if GLSetup."Additional Reporting Currency" <> '' then begin
            Currency.Get(GLSetup."Additional Reporting Currency");
            Currency.TestField("Amount Rounding Precision");
            Currency.TestField("Unit-Amount Rounding Precision");
        end;
        RndgSetupRead := true;
    end;

    procedure TransferCost(var Cost: Decimal; var UnitCost: Decimal; SrcCost: Decimal; Qty: Decimal; UnitAmtRndgPrec: Decimal)
    begin
        Cost := SrcCost;
        if Qty <> 0 then
            UnitCost := Round(Cost / Qty, UnitAmtRndgPrec);
    end;

    procedure SplitItemLedgerEntriesExist(var TempItemLedgEntry: Record "Item Ledger Entry" temporary; QtyBase: Decimal; ItemLedgEntryNo: Integer): Boolean
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        ItemLedgEntry2: Record "Item Ledger Entry";
    begin
        if ItemLedgEntryNo = 0 then
            exit(false);
        TempItemLedgEntry.Reset();
        TempItemLedgEntry.DeleteAll();
        if ItemLedgEntry.Get(ItemLedgEntryNo) and (ItemLedgEntry.Quantity <> QtyBase) then
            if ItemLedgEntry2.Get(ItemLedgEntry."Entry No." - 1) and
               IsSameDocLineItemLedgEntry(ItemLedgEntry, ItemLedgEntry2, QtyBase)
            then begin
                TempItemLedgEntry := ItemLedgEntry2;
                TempItemLedgEntry.Insert();
                TempItemLedgEntry := ItemLedgEntry;
                TempItemLedgEntry.Insert();
                exit(true);
            end;

        exit(false);
    end;

    local procedure IsSameDocLineItemLedgEntry(ItemLedgEntry: Record "Item Ledger Entry"; ItemLedgEntry2: Record "Item Ledger Entry"; QtyBase: Decimal): Boolean
    begin
        exit(
              (ItemLedgEntry2."Document Type" = ItemLedgEntry."Document Type") and
              (ItemLedgEntry2."Document No." = ItemLedgEntry."Document No.") and
              (ItemLedgEntry2."Document Line No." = ItemLedgEntry."Document Line No.") and
              (ItemLedgEntry2."Posting Date" = ItemLedgEntry."Posting Date") and
              (ItemLedgEntry2."Source Type" = ItemLedgEntry."Source Type") and
              (ItemLedgEntry2."Source No." = ItemLedgEntry."Source No.") and
              (ItemLedgEntry2."Entry Type" = ItemLedgEntry."Entry Type") and
              (ItemLedgEntry2."Item No." = ItemLedgEntry."Item No.") and
              (ItemLedgEntry2."Location Code" = ItemLedgEntry."Location Code") and
              (ItemLedgEntry2."Variant Code" = ItemLedgEntry."Variant Code") and
              (QtyBase = ItemLedgEntry2.Quantity + ItemLedgEntry.Quantity) and
              (ItemLedgEntry2.Quantity = ItemLedgEntry2."Invoiced Quantity"));
    end;

    procedure CalcSalesLineCostLCY(SalesLine: Record "Sales Line"; QtyType: Option General,Invoicing) TotalAdjCostLCY: Decimal
    var
        PostedQtyBase: Decimal;
        RemQtyToCalcBase: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcSalesLineCostLCY(SalesLine, QtyType, IsHandled, TotalAdjCostLCY);
        if IsHandled then
            exit;
        case SalesLine."Document Type" of
            SalesLine."Document Type"::Order, SalesLine."Document Type"::Invoice:
                if ((SalesLine."Quantity Shipped" <> 0) or (SalesLine."Shipment No." <> '')) and
                   ((QtyType = QtyType::General) or (SalesLine."Qty. to Invoice" > SalesLine."Qty. to Ship"))
                then
                    CalcSalesLineShptAdjCostLCY(SalesLine, QtyType, TotalAdjCostLCY, PostedQtyBase, RemQtyToCalcBase);
            SalesLine."Document Type"::"Return Order", SalesLine."Document Type"::"Credit Memo":
                if ((SalesLine."Return Qty. Received" <> 0) or (SalesLine."Return Receipt No." <> '')) and
                   ((QtyType = QtyType::General) or (SalesLine."Qty. to Invoice" > SalesLine."Return Qty. to Receive"))
                then
                    CalcSalesLineRcptAdjCostLCY(SalesLine, QtyType, TotalAdjCostLCY, PostedQtyBase, RemQtyToCalcBase);
        end;
    end;

    procedure CalcSalesLineShptAdjCostLCY(SalesLine: Record "Sales Line"; QtyType: Option General,Invoicing; var TotalAdjCostLCY: Decimal; var PostedQtyBase: Decimal; var RemQtyToCalcBase: Decimal)
    var
        SalesShptLine: Record "Sales Shipment Line";
        UOMMgt: Codeunit "Unit of Measure Management";
        QtyShippedNotInvcdBase: Decimal;
        AdjCostLCY: Decimal;
    begin
        if SalesLine."Shipment No." <> '' then begin
            SalesShptLine.SetRange("Document No.", SalesLine."Shipment No.");
            SalesShptLine.SetRange("Line No.", SalesLine."Shipment Line No.");
        end else begin
            SalesShptLine.SetCurrentKey("Order No.", "Order Line No.");
            SalesShptLine.SetRange("Order No.", SalesLine."Document No.");
            SalesShptLine.SetRange("Order Line No.", SalesLine."Line No.");
        end;
        SalesShptLine.SetRange(Correction, false);
        OnCalcSalesLineShptAdjCostLCYBeforeSalesShptLineFind(SalesShptLine, SalesLine);
        if QtyType = QtyType::Invoicing then begin
            SalesShptLine.SetFilter(SalesShptLine."Qty. Shipped Not Invoiced", '<>0');
            RemQtyToCalcBase := SalesLine."Qty. to Invoice (Base)" - SalesLine."Qty. to Ship (Base)";
        end else
            RemQtyToCalcBase := SalesLine."Quantity (Base)";

        if SalesShptLine.FindSet() then
            repeat
                if SalesShptLine."Qty. per Unit of Measure" = 0 then
                    QtyShippedNotInvcdBase := SalesShptLine."Qty. Shipped Not Invoiced"
                else
                    QtyShippedNotInvcdBase :=
                      Round(SalesShptLine."Qty. Shipped Not Invoiced" * SalesShptLine."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());

                AdjCostLCY := CalcSalesShptLineCostLCY(SalesShptLine, QtyType);

                case true of
                    QtyType = QtyType::Invoicing:
                        if RemQtyToCalcBase > QtyShippedNotInvcdBase then begin
                            TotalAdjCostLCY := TotalAdjCostLCY + AdjCostLCY;
                            RemQtyToCalcBase := RemQtyToCalcBase - QtyShippedNotInvcdBase;
                            PostedQtyBase := PostedQtyBase + QtyShippedNotInvcdBase;
                        end else begin
                            PostedQtyBase := PostedQtyBase + RemQtyToCalcBase;
                            TotalAdjCostLCY :=
                              TotalAdjCostLCY + AdjCostLCY / QtyShippedNotInvcdBase * RemQtyToCalcBase;
                            RemQtyToCalcBase := 0;
                        end;
                    SalesLine."Shipment No." <> '':
                        begin
                            PostedQtyBase := PostedQtyBase + QtyShippedNotInvcdBase;
                            TotalAdjCostLCY :=
                              TotalAdjCostLCY + AdjCostLCY / SalesShptLine."Quantity (Base)" * RemQtyToCalcBase;
                            RemQtyToCalcBase := 0;
                        end;
                    else begin
                        PostedQtyBase := PostedQtyBase + SalesShptLine."Quantity (Base)";
                        TotalAdjCostLCY := TotalAdjCostLCY + AdjCostLCY;
                    end;
                end;
            until (SalesShptLine.Next() = 0) or (RemQtyToCalcBase = 0);
    end;

    procedure CalcSalesLineRcptAdjCostLCY(SalesLine: Record "Sales Line"; QtyType: Option General,Invoicing; var TotalAdjCostLCY: Decimal; var PostedQtyBase: Decimal; var RemQtyToCalcBase: Decimal)
    var
        ReturnRcptLine: Record "Return Receipt Line";
        UOMMgt: Codeunit "Unit of Measure Management";
        RtrnQtyRcvdNotInvcdBase: Decimal;
        AdjCostLCY: Decimal;
    begin
        if SalesLine."Return Receipt No." <> '' then begin
            ReturnRcptLine.SetRange("Document No.", SalesLine."Return Receipt No.");
            ReturnRcptLine.SetRange("Line No.", SalesLine."Return Receipt Line No.");
        end else begin
            ReturnRcptLine.SetCurrentKey("Return Order No.", "Return Order Line No.");
            ReturnRcptLine.SetRange("Return Order No.", SalesLine."Document No.");
            ReturnRcptLine.SetRange("Return Order Line No.", SalesLine."Line No.");
        end;
        ReturnRcptLine.SetRange(Correction, false);
        if QtyType = QtyType::Invoicing then begin
            ReturnRcptLine.SetFilter(ReturnRcptLine."Return Qty. Rcd. Not Invd.", '<>0');
            RemQtyToCalcBase :=
              SalesLine."Qty. to Invoice (Base)" - SalesLine."Return Qty. to Receive (Base)";
        end else
            RemQtyToCalcBase := SalesLine."Quantity (Base)";

        if ReturnRcptLine.FindSet() then
            repeat
                if ReturnRcptLine."Qty. per Unit of Measure" = 0 then
                    RtrnQtyRcvdNotInvcdBase := ReturnRcptLine."Return Qty. Rcd. Not Invd."
                else
                    RtrnQtyRcvdNotInvcdBase :=
                      Round(ReturnRcptLine."Return Qty. Rcd. Not Invd." * ReturnRcptLine."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());

                AdjCostLCY := CalcReturnRcptLineCostLCY(ReturnRcptLine, QtyType);

                case true of
                    QtyType = QtyType::Invoicing:
                        if RemQtyToCalcBase > RtrnQtyRcvdNotInvcdBase then begin
                            TotalAdjCostLCY := TotalAdjCostLCY + AdjCostLCY;
                            RemQtyToCalcBase := RemQtyToCalcBase - RtrnQtyRcvdNotInvcdBase;
                            PostedQtyBase := PostedQtyBase + RtrnQtyRcvdNotInvcdBase;
                        end else begin
                            PostedQtyBase := PostedQtyBase + RemQtyToCalcBase;
                            TotalAdjCostLCY :=
                              TotalAdjCostLCY + AdjCostLCY / RtrnQtyRcvdNotInvcdBase * RemQtyToCalcBase;
                            RemQtyToCalcBase := 0;
                        end;
                    SalesLine."Return Receipt No." <> '':
                        begin
                            PostedQtyBase := PostedQtyBase + RtrnQtyRcvdNotInvcdBase;
                            TotalAdjCostLCY :=
                              TotalAdjCostLCY + AdjCostLCY / ReturnRcptLine."Quantity (Base)" * RemQtyToCalcBase;
                            RemQtyToCalcBase := 0;
                        end;
                    else begin
                        PostedQtyBase := PostedQtyBase + ReturnRcptLine."Quantity (Base)";
                        TotalAdjCostLCY := TotalAdjCostLCY + AdjCostLCY;
                    end;
                end;
            until (ReturnRcptLine.Next() = 0) or (RemQtyToCalcBase = 0);
    end;

    local procedure CalcSalesShptLineCostLCY(SalesShptLine: Record "Sales Shipment Line"; QtyType: Option General,Invoicing,Shipping) AdjCostLCY: Decimal
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        ReturnRcptLine: Record "Return Receipt Line";
        IsHandled: Boolean;
    begin
        if (SalesShptLine.Quantity = 0) or (SalesShptLine.Type = SalesShptLine.Type::"Charge (Item)") then
            exit(0);

        if SalesShptLine.Type = SalesShptLine.Type::Item then begin
            SalesShptLine.FilterPstdDocLnItemLedgEntries(ItemLedgEntry);
            if ItemLedgEntry.IsEmpty() then
                exit(0);
            AdjCostLCY := CalcPostedDocLineCostLCY(ItemLedgEntry, QtyType);

            IsHandled := false;
            OnBeforeRelatedReturnReceiptExists(SalesShptLine, ReturnRcptLine, IsHandled);
            if IsHandled then
                exit;

            if RelatedReturnReceiptExist(SalesShptLine, ReturnRcptLine) then
                repeat
                    AdjCostLCY += CalcReturnRcptLineCostLCY(ReturnRcptLine, QtyType);
                until ReturnRcptLine.Next() = 0;
        end else
            if QtyType = QtyType::Invoicing then
                AdjCostLCY := -SalesShptLine."Qty. Shipped Not Invoiced" * SalesShptLine."Unit Cost (LCY)"
            else
                AdjCostLCY := -SalesShptLine.Quantity * SalesShptLine."Unit Cost (LCY)";
    end;

    local procedure RelatedReturnReceiptExist(var SalesShptLine: Record "Sales Shipment Line"; var ReturnRcptLine: Record "Return Receipt Line"): Boolean
    var
        ReturnValue: Boolean;
        IsHandled: Boolean;
    begin
        if SalesShptLine."Item Shpt. Entry No." = 0 then exit;

        IsHandled := false;
        OnBeforeSetFiltersRelatedReturnReceiptExists(SalesShptLine, ReturnRcptLine, ReturnValue, IsHandled);
        if IsHandled then
            exit(ReturnValue);

        ReturnRcptLine.SetRange("Appl.-from Item Entry", SalesShptLine."Item Shpt. Entry No.");
        if ReturnRcptLine.FindSet() then
            exit(true);
    end;

    local procedure CalcReturnRcptLineCostLCY(ReturnRcptLine: Record "Return Receipt Line"; QtyType: Option General,Invoicing,Shipping) AdjCostLCY: Decimal
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        if (ReturnRcptLine.Quantity = 0) or (ReturnRcptLine.Type = ReturnRcptLine.Type::"Charge (Item)") then
            exit(0);

        if ReturnRcptLine.Type = ReturnRcptLine.Type::Item then begin
            ReturnRcptLine.FilterPstdDocLnItemLedgEntries(ItemLedgEntry);
            if ItemLedgEntry.IsEmpty() then
                exit(0);
            AdjCostLCY := CalcPostedDocLineCostLCY(ItemLedgEntry, QtyType);
        end else
            if QtyType = QtyType::Invoicing then
                AdjCostLCY := ReturnRcptLine."Return Qty. Rcd. Not Invd." * ReturnRcptLine."Unit Cost (LCY)"
            else
                AdjCostLCY := ReturnRcptLine.Quantity * ReturnRcptLine."Unit Cost (LCY)";
    end;

    procedure CalcPostedDocLineCostLCY(var ItemLedgEntry: Record "Item Ledger Entry"; QtyType: Option General,Invoicing,Shipping,Consuming) AdjCostLCY: Decimal
    var
        ValueEntry: Record "Value Entry";
    begin
        ItemLedgEntry.FindSet();
        repeat
            if (QtyType = QtyType::Invoicing) or (QtyType = QtyType::Consuming) then begin
                ItemLedgEntry.CalcFields("Cost Amount (Expected)");
                AdjCostLCY := AdjCostLCY + ItemLedgEntry."Cost Amount (Expected)";
            end else begin
                ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgEntry."Entry No.");
                ValueEntry.SetFilter("Entry Type", '<>%1', ValueEntry."Entry Type"::Revaluation);
                ValueEntry.SetRange("Item Charge No.", '');
                ValueEntry.CalcSums("Cost Amount (Expected)", "Cost Amount (Actual)");
                AdjCostLCY += ValueEntry."Cost Amount (Expected)" + ValueEntry."Cost Amount (Actual)";
            end;
        until ItemLedgEntry.Next() = 0;
    end;

    procedure CalcSalesInvLineCostLCY(SalesInvLine: Record "Sales Invoice Line") AdjCostLCY: Decimal
    var
        ValueEntry: Record "Value Entry";
    begin
        if SalesInvLine.Quantity = 0 then
            exit(0);

        if SalesInvLine.Type in [SalesInvLine.Type::Item, SalesInvLine.Type::"Charge (Item)"] then begin
            SalesInvLine.FilterPstdDocLineValueEntries(ValueEntry);
            AdjCostLCY := -SumValueEntriesCostAmt(ValueEntry);
        end else
            AdjCostLCY := SalesInvLine.Quantity * SalesInvLine."Unit Cost (LCY)";
    end;

    procedure CalcSalesInvLineNonInvtblCostAmt(SalesInvoiceLine: Record "Sales Invoice Line"): Decimal
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Document No.", SalesInvoiceLine."Document No.");
        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Sales Invoice");
        ValueEntry.SetRange("Document Line No.", SalesInvoiceLine."Line No.");
        ValueEntry.CalcSums("Cost Amount (Non-Invtbl.)");
        exit(-ValueEntry."Cost Amount (Non-Invtbl.)");
    end;

    procedure CalcSalesCrMemoLineCostLCY(SalesCrMemoLine: Record "Sales Cr.Memo Line") AdjCostLCY: Decimal
    var
        ValueEntry: Record "Value Entry";
    begin
        if SalesCrMemoLine.Quantity = 0 then
            exit(0);

        if SalesCrMemoLine.Type in [SalesCrMemoLine.Type::Item, SalesCrMemoLine.Type::"Charge (Item)"] then begin
            SalesCrMemoLine.FilterPstdDocLineValueEntries(ValueEntry);
            AdjCostLCY := SumValueEntriesCostAmt(ValueEntry);
        end else
            AdjCostLCY := SalesCrMemoLine.Quantity * SalesCrMemoLine."Unit Cost (LCY)";
    end;

    procedure CalcSalesCrMemoLineNonInvtblCostAmt(SalesCrMemoLine: Record "Sales Cr.Memo Line"): Decimal
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Document No.", SalesCrMemoLine."Document No.");
        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Sales Credit Memo");
        ValueEntry.SetRange("Document Line No.", SalesCrMemoLine."Line No.");
        ValueEntry.CalcSums("Cost Amount (Non-Invtbl.)");
        exit(ValueEntry."Cost Amount (Non-Invtbl.)");
    end;


    procedure CalcCustLedgAdjmtCostLCY(CustLedgEntry: Record "Cust. Ledger Entry"): Decimal
    var
        ValueEntry: Record "Value Entry";
    begin
        if not (CustLedgEntry."Document Type" in [CustLedgEntry."Document Type"::Invoice, CustLedgEntry."Document Type"::"Credit Memo"]) then
            CustLedgEntry.FieldError(CustLedgEntry."Document Type");

        ValueEntry.SetCurrentKey("Document No.");
        ValueEntry.SetRange("Document No.", CustLedgEntry."Document No.");
        if CustLedgEntry."Document Type" = CustLedgEntry."Document Type"::Invoice then
            ValueEntry.SetFilter(
              "Document Type",
              '%1|%2',
              ValueEntry."Document Type"::"Sales Invoice", ValueEntry."Document Type"::"Service Invoice")
        else
            ValueEntry.SetFilter(
              "Document Type",
              '%1|%2',
              ValueEntry."Document Type"::"Sales Credit Memo", ValueEntry."Document Type"::"Service Credit Memo");
        ValueEntry.SetRange(Adjustment, true);
        exit(SumValueEntriesCostAmt(ValueEntry));
    end;

    procedure CalcCustAdjmtCostLCY(var Customer: Record Customer): Decimal
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetCurrentKey("Source Type", "Source No.");
        ValueEntry.SetRange("Source Type", ValueEntry."Source Type"::Customer);
        ValueEntry.SetRange("Source No.", Customer."No.");
        ValueEntry.SetFilter("Posting Date", Customer.GetFilter("Date Filter"));
        ValueEntry.SetFilter("Global Dimension 1 Code", Customer.GetFilter("Global Dimension 1 Filter"));
        ValueEntry.SetFilter("Global Dimension 2 Code", Customer.GetFilter("Global Dimension 2 Filter"));
        ValueEntry.SetRange(Adjustment, true);

        ValueEntry.CalcSums("Cost Amount (Actual)");
        exit(ValueEntry."Cost Amount (Actual)");
    end;

    procedure CalcCustLedgActualCostLCY(CustLedgEntry: Record "Cust. Ledger Entry"): Decimal
    var
        ValueEntry: Record "Value Entry";
    begin
        if not (CustLedgEntry."Document Type" in [CustLedgEntry."Document Type"::Invoice, CustLedgEntry."Document Type"::"Credit Memo"]) then
            CustLedgEntry.FieldError(CustLedgEntry."Document Type");

        ValueEntry.SetCurrentKey("Document No.");
        ValueEntry.SetRange("Document No.", CustLedgEntry."Document No.");
        if CustLedgEntry."Document Type" = CustLedgEntry."Document Type"::Invoice then
            ValueEntry.SetFilter(
              "Document Type",
              '%1|%2',
              ValueEntry."Document Type"::"Sales Invoice", ValueEntry."Document Type"::"Service Invoice")
        else
            ValueEntry.SetFilter(
              "Document Type",
              '%1|%2',
              ValueEntry."Document Type"::"Sales Credit Memo", ValueEntry."Document Type"::"Service Credit Memo");
        ValueEntry.SetFilter("Entry Type", '<> %1', ValueEntry."Entry Type"::Revaluation);
        exit(SumValueEntriesCostAmt(ValueEntry));
    end;

    procedure CalcCustActualCostLCY(var Customer: Record Customer) CostAmt: Decimal
    var
        ValueEntry: Record "Value Entry";
        ResLedgerEntry: Record "Res. Ledger Entry";
    begin
        ValueEntry.SetRange("Source Type", ValueEntry."Source Type"::Customer);
        ValueEntry.SetRange("Source No.", Customer."No.");
        ValueEntry.SetFilter("Posting Date", Customer.GetFilter("Date Filter"));
        ValueEntry.SetFilter("Global Dimension 1 Code", Customer.GetFilter("Global Dimension 1 Filter"));
        ValueEntry.SetFilter("Global Dimension 2 Code", Customer.GetFilter("Global Dimension 2 Filter"));
        ValueEntry.SetFilter("Entry Type", '<> %1', ValueEntry."Entry Type"::Revaluation);
        OnCalcCustActualCostLCYOnAfterFilterValueEntry(Customer, ValueEntry);
        ValueEntry.CalcSums("Cost Amount (Actual)");
        CostAmt := ValueEntry."Cost Amount (Actual)";

        ResLedgerEntry.SetRange("Entry Type", ResLedgerEntry."Entry Type"::Sale);
        ResLedgerEntry.SetRange("Source Type", ResLedgerEntry."Source Type"::Customer);
        ResLedgerEntry.SetRange("Source No.", Customer."No.");
        ResLedgerEntry.SetFilter("Posting Date", Customer.GetFilter("Date Filter"));
        ResLedgerEntry.SetFilter("Global Dimension 1 Code", Customer.GetFilter("Global Dimension 1 Filter"));
        ResLedgerEntry.SetFilter("Global Dimension 2 Code", Customer.GetFilter("Global Dimension 2 Filter"));
        OnCalcCustActualCostLCYOnAfterFilterResLedgerEntry(Customer, ResLedgerEntry);
        ResLedgerEntry.CalcSums(ResLedgerEntry."Total Cost");
        CostAmt += ResLedgerEntry."Total Cost";
    end;

    procedure NonInvtblCostAmt(var Customer: Record Customer): Decimal
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange(ValueEntry."Source Type", ValueEntry."Source Type"::Customer);
        ValueEntry.SetRange(ValueEntry."Source No.", Customer."No.");
        ValueEntry.SetFilter(ValueEntry."Posting Date", Customer.GetFilter("Date Filter"));
        ValueEntry.SetFilter(ValueEntry."Global Dimension 1 Code", Customer.GetFilter("Global Dimension 1 Filter"));
        ValueEntry.SetFilter(ValueEntry."Global Dimension 2 Code", Customer.GetFilter("Global Dimension 2 Filter"));
        ValueEntry.CalcSums(ValueEntry."Cost Amount (Non-Invtbl.)");
        exit(ValueEntry."Cost Amount (Non-Invtbl.)");
    end;

    procedure SumValueEntriesCostAmt(var ValueEntry: Record "Value Entry") CostAmt: Decimal
    begin
        ValueEntry.CalcSums("Cost Amount (Actual)");
        CostAmt := ValueEntry."Cost Amount (Actual)";
        exit(CostAmt);
    end;

    procedure GetDocType(TableNo: Integer): Integer
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        case TableNo of
            Database::"Purch. Rcpt. Header":
                exit(ItemLedgEntry."Document Type"::"Purchase Receipt".AsInteger());
            Database::"Purch. Inv. Header":
                exit(ItemLedgEntry."Document Type"::"Purchase Invoice".AsInteger());
            Database::"Purch. Cr. Memo Hdr.":
                exit(ItemLedgEntry."Document Type"::"Purchase Credit Memo".AsInteger());
            Database::"Return Shipment Header":
                exit(ItemLedgEntry."Document Type"::"Purchase Return Shipment".AsInteger());
            Database::"Sales Shipment Header":
                exit(ItemLedgEntry."Document Type"::"Sales Shipment".AsInteger());
            Database::"Sales Invoice Header":
                exit(ItemLedgEntry."Document Type"::"Sales Invoice".AsInteger());
            Database::"Sales Cr.Memo Header":
                exit(ItemLedgEntry."Document Type"::"Sales Credit Memo".AsInteger());
            Database::"Return Receipt Header":
                exit(ItemLedgEntry."Document Type"::"Sales Return Receipt".AsInteger());
            Database::"Transfer Shipment Header":
                exit(ItemLedgEntry."Document Type"::"Transfer Shipment".AsInteger());
            Database::"Transfer Receipt Header":
                exit(ItemLedgEntry."Document Type"::"Transfer Receipt".AsInteger());
            Database::"Posted Assembly Header":
                exit(ItemLedgEntry."Document Type"::"Posted Assembly".AsInteger());
        end;
    end;



    procedure AdjustForRevNegCon(var ActMatCost: Decimal; var ActMatCostCostACY: Decimal; var ItemLedgEntry: Record "Item Ledger Entry")
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetCurrentKey("Item Ledger Entry No.", "Entry Type");
        ItemLedgEntry.SetRange(Positive, true);
        if ItemLedgEntry.FindSet() then
            repeat
                ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgEntry."Entry No.");
                ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::Revaluation);
                ValueEntry.CalcSums("Cost Amount (Actual)", "Cost Amount (Actual) (ACY)");
                ActMatCost += ValueEntry."Cost Amount (Actual)";
                ActMatCostCostACY += ValueEntry."Cost Amount (Actual) (ACY)";
            until ItemLedgEntry.Next() = 0;
    end;

    procedure CanIncNonInvCostIntoProductionItem() Result: Boolean
    begin
        OnCanIncNonInvCostIntoProductionItem(Result);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcSalesLineCostLCY(SalesLine: Record "Sales Line"; QtyType: Option General,Invoicing; var IsHandled: Boolean; var TotalAdjCostLCY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcSalesLineShptAdjCostLCYBeforeSalesShptLineFind(var SalesShptLine: Record "Sales Shipment Line"; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcCustActualCostLCYOnAfterFilterValueEntry(var Customer: Record Customer; var ValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcCustActualCostLCYOnAfterFilterResLedgerEntry(var Customer: Record Customer; var ResLedgerEntry: Record "Res. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRelatedReturnReceiptExists(var SalesShptLine: Record "Sales Shipment Line"; var ReturnRcptLine: Record "Return Receipt Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetFiltersRelatedReturnReceiptExists(var SalesShptLine: Record "Sales Shipment Line"; var ReturnRcptLine: Record "Return Receipt Line"; var ReturnValue: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCanIncNonInvCostIntoProductionItem(var Result: Boolean)
    begin
    end;
}
