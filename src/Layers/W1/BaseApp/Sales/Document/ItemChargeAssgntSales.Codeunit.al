// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Finance.Currency;
using Microsoft.Foundation.UOM;
using Microsoft.Sales.History;

codeunit 5807 "Item Charge Assgnt. (Sales)"
{
    Permissions = TableData "Sales Header" = r,
                  TableData "Sales Line" = r,
                  TableData "Sales Shipment Line" = r,
                  TableData "Item Charge Assignment (Sales)" = rimd,
                  TableData "Return Receipt Line" = r;

    trigger OnRun()
    begin
    end;

    var
        UOMMgt: Codeunit "Unit of Measure Management";

        SuggestItemChargeMsg: Label 'Select how to distribute the assigned item charge when the document has more than one line of type Item.';
        EquallyTok: Label 'Equally';
        ByAmountTok: Label 'By Amount';
        ByWeightTok: Label 'By Weight';
        ByVolumeTok: Label 'By Volume';
        ItemChargeAssignedMenu4Lbl: Label '%1,%2,%3,%4', Locked = true;
        ItemChargesNotAssignedErr: Label 'No item charges were assigned.';

    procedure InsertItemChargeAssignment(ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)"; ApplToDocType: Enum "Sales Applies-to Document Type"; ApplToDocNo: Code[20]; ApplToDocLineNo: Integer; ItemNo: Code[20]; Description: Text[100]; var NextLineNo: Integer)
    begin
        InsertItemChargeAssignmentWithValues(
            ItemChargeAssgntSales, ApplToDocType, ApplToDocNo, ApplToDocLineNo, ItemNo, Description, 0, 0, NextLineNo);
    end;

    procedure InsertItemChargeAssignmentWithValues(FromItemChargeAssgntSales: Record "Item Charge Assignment (Sales)"; ApplToDocType: Enum "Sales Applies-to Document Type"; FromApplToDocNo: Code[20]; FromApplToDocLineNo: Integer; FromItemNo: Code[20]; FromDescription: Text[100]; QtyToAssign: Decimal; AmountToAssign: Decimal; var NextLineNo: Integer)
    var
        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
    begin
        InsertItemChargeAssignmentWithValuesTo(
          FromItemChargeAssgntSales, ApplToDocType, FromApplToDocNo, FromApplToDocLineNo, FromItemNo, FromDescription,
          QtyToAssign, AmountToAssign, NextLineNo, ItemChargeAssgntSales);
    end;

    procedure InsertItemChargeAssignmentWithValuesTo(FromItemChargeAssgntSales: Record "Item Charge Assignment (Sales)"; ApplToDocType: Enum "Sales Applies-to Document Type"; FromApplToDocNo: Code[20]; FromApplToDocLineNo: Integer; FromItemNo: Code[20]; FromDescription: Text[100]; QtyToAssign: Decimal; AmountToAssign: Decimal; var NextLineNo: Integer; var ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertItemChargeAssignmentWithValuesTo(FromItemChargeAssgntSales, ItemChargeAssgntSales, ApplToDocType, FromApplToDocNo, FromApplToDocLineNo, FromItemNo, FromDescription, NextLineNo, QtyToAssign, AmountToAssign, IsHandled);
        if IsHandled then
            exit;

        NextLineNo := NextLineNo + 10000;

        ItemChargeAssgntSales."Document No." := FromItemChargeAssgntSales."Document No.";
        ItemChargeAssgntSales."Document Type" := FromItemChargeAssgntSales."Document Type";
        ItemChargeAssgntSales."Document Line No." := FromItemChargeAssgntSales."Document Line No.";
        ItemChargeAssgntSales."Item Charge No." := FromItemChargeAssgntSales."Item Charge No.";
        ItemChargeAssgntSales."Line No." := NextLineNo;
        ItemChargeAssgntSales."Applies-to Doc. No." := FromApplToDocNo;
        ItemChargeAssgntSales."Applies-to Doc. Type" := ApplToDocType;
        ItemChargeAssgntSales."Applies-to Doc. Line No." := FromApplToDocLineNo;
        ItemChargeAssgntSales."Item No." := FromItemNo;
        ItemChargeAssgntSales.Description := FromDescription;
        ItemChargeAssgntSales."Unit Cost" := FromItemChargeAssgntSales."Unit Cost";
        if QtyToAssign <> 0 then begin
            ItemChargeAssgntSales."Amount to Assign" := AmountToAssign;
            ItemChargeAssgntSales.Validate("Qty. to Assign", QtyToAssign);
        end;
        OnBeforeInsertItemChargeAssgntWithAssignValues(ItemChargeAssgntSales, FromItemChargeAssgntSales);
        ItemChargeAssgntSales.Insert();
    end;

    procedure Summarize(var TempToItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)" temporary; var ToItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)")
    begin
        TempToItemChargeAssignmentSales.SetCurrentKey("Applies-to Doc. Type", "Applies-to Doc. No.", "Applies-to Doc. Line No.");
        if TempToItemChargeAssignmentSales.FindSet() then
            repeat
                if (TempToItemChargeAssignmentSales."Item Charge No." <> ToItemChargeAssignmentSales."Item Charge No.") or
                   (TempToItemChargeAssignmentSales."Applies-to Doc. No." <> ToItemChargeAssignmentSales."Applies-to Doc. No.") or
                   (TempToItemChargeAssignmentSales."Applies-to Doc. Line No." <> ToItemChargeAssignmentSales."Applies-to Doc. Line No.")
                then begin
                    if ToItemChargeAssignmentSales."Line No." <> 0 then
                        ToItemChargeAssignmentSales.Insert();
                    ToItemChargeAssignmentSales := TempToItemChargeAssignmentSales;
                    ToItemChargeAssignmentSales."Qty. to Assign" := 0;
                    ToItemChargeAssignmentSales."Amount to Assign" := 0;
                    ToItemChargeAssignmentSales."Qty. to Handle" := 0;
                    ToItemChargeAssignmentSales."Amount to Handle" := 0;
                end;
                ToItemChargeAssignmentSales."Qty. to Assign" += TempToItemChargeAssignmentSales."Qty. to Assign";
                ToItemChargeAssignmentSales."Amount to Assign" += TempToItemChargeAssignmentSales."Amount to Assign";
                ToItemChargeAssignmentSales."Qty. to Handle" += TempToItemChargeAssignmentSales."Qty. to Handle";
                ToItemChargeAssignmentSales."Amount to Handle" += TempToItemChargeAssignmentSales."Amount to Handle";
            until TempToItemChargeAssignmentSales.Next() = 0;
        if ToItemChargeAssignmentSales."Line No." <> 0 then
            ToItemChargeAssignmentSales.Insert();
    end;

    procedure CreateDocChargeAssgn(LastItemChargeAssgntSales: Record "Item Charge Assignment (Sales)"; ShipmentNo: Code[20])
    var
        FromSalesLine: Record "Sales Line";
        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
        NextLineNo: Integer;
    begin
        OnBeforeCreateDocChargeAssgn(LastItemChargeAssgntSales, FromSalesLine);

        FromSalesLine.SetRange("Document Type", LastItemChargeAssgntSales."Document Type");
        FromSalesLine.SetRange("Document No.", LastItemChargeAssgntSales."Document No.");
        FromSalesLine.SetRange(Type, FromSalesLine.Type::Item);
        OnCreateDocChargeAssgnOnAfterFromSalesLineSetFilters(LastItemChargeAssgntSales, FromSalesLine);
        if FromSalesLine.Find('-') then begin
            NextLineNo := LastItemChargeAssgntSales."Line No.";
            ItemChargeAssgntSales.SetRange("Document Type", LastItemChargeAssgntSales."Document Type");
            ItemChargeAssgntSales.SetRange("Document No.", LastItemChargeAssgntSales."Document No.");
            ItemChargeAssgntSales.SetRange("Document Line No.", LastItemChargeAssgntSales."Document Line No.");
            ItemChargeAssgntSales.SetRange("Applies-to Doc. No.", LastItemChargeAssgntSales."Document No.");
            repeat
                if (FromSalesLine.Quantity <> 0) and
                   (FromSalesLine.Quantity <> FromSalesLine."Quantity Invoiced") and
                   (FromSalesLine."Job No." = '') and
                   ((ShipmentNo = '') or (FromSalesLine."Shipment No." = ShipmentNo)) and
                   FromSalesLine."Allow Item Charge Assignment"
                then begin
                    ItemChargeAssgntSales.SetRange("Applies-to Doc. Line No.", FromSalesLine."Line No.");
                    if not ItemChargeAssgntSales.FindFirst() then
                        InsertItemChargeAssignment(
                          LastItemChargeAssgntSales, FromSalesLine."Document Type",
                          FromSalesLine."Document No.", FromSalesLine."Line No.",
                          FromSalesLine."No.", FromSalesLine.Description, NextLineNo);
                end;
            until FromSalesLine.Next() = 0;
        end;

        OnAfterCreateDocChargeAssgnt(LastItemChargeAssgntSales, ShipmentNo);
    end;

    procedure CreateShptChargeAssgnt(var FromSalesShptLine: Record "Sales Shipment Line"; ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)")
    var
        ItemChargeAssgntSales2: Record "Item Charge Assignment (Sales)";
        Nextline: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateShptChargeAssgnt(FromSalesShptLine, ItemChargeAssgntSales, IsHandled);
        if IsHandled then
            exit;

        Nextline := ItemChargeAssgntSales."Line No.";
        ItemChargeAssgntSales2.SetRange("Document Type", ItemChargeAssgntSales."Document Type");
        ItemChargeAssgntSales2.SetRange("Document No.", ItemChargeAssgntSales."Document No.");
        ItemChargeAssgntSales2.SetRange("Document Line No.", ItemChargeAssgntSales."Document Line No.");
        ItemChargeAssgntSales2.SetRange(
          "Applies-to Doc. Type", ItemChargeAssgntSales2."Applies-to Doc. Type"::Shipment);
        repeat
            FromSalesShptLine.TestField("Job No.", '');
            ItemChargeAssgntSales2.SetRange("Applies-to Doc. No.", FromSalesShptLine."Document No.");
            ItemChargeAssgntSales2.SetRange("Applies-to Doc. Line No.", FromSalesShptLine."Line No.");
            if not ItemChargeAssgntSales2.FindFirst() then
                InsertItemChargeAssignment(
                    ItemChargeAssgntSales, ItemChargeAssgntSales2."Applies-to Doc. Type"::Shipment,
                    FromSalesShptLine."Document No.", FromSalesShptLine."Line No.",
                    FromSalesShptLine."No.", FromSalesShptLine.Description, Nextline);
        until FromSalesShptLine.Next() = 0;
    end;

    procedure CreateRcptChargeAssgnt(var FromReturnRcptLine: Record "Return Receipt Line"; ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)")
    var
        ItemChargeAssgntSales2: Record "Item Charge Assignment (Sales)";
        Nextline: Integer;
    begin
        Nextline := ItemChargeAssgntSales."Line No.";
        ItemChargeAssgntSales2.SetRange("Document Type", ItemChargeAssgntSales."Document Type");
        ItemChargeAssgntSales2.SetRange("Document No.", ItemChargeAssgntSales."Document No.");
        ItemChargeAssgntSales2.SetRange("Document Line No.", ItemChargeAssgntSales."Document Line No.");
        ItemChargeAssgntSales2.SetRange(
          "Applies-to Doc. Type", ItemChargeAssgntSales2."Applies-to Doc. Type"::"Return Receipt");
        repeat
            FromReturnRcptLine.TestField("Job No.", '');
            ItemChargeAssgntSales2.SetRange("Applies-to Doc. No.", FromReturnRcptLine."Document No.");
            ItemChargeAssgntSales2.SetRange("Applies-to Doc. Line No.", FromReturnRcptLine."Line No.");
            if not ItemChargeAssgntSales2.FindFirst() then
                InsertItemChargeAssignment(
                    ItemChargeAssgntSales, ItemChargeAssgntSales2."Applies-to Doc. Type"::"Return Receipt",
                    FromReturnRcptLine."Document No.", FromReturnRcptLine."Line No.",
                    FromReturnRcptLine."No.", FromReturnRcptLine.Description, Nextline);
        until FromReturnRcptLine.Next() = 0;
    end;

    procedure SuggestAssignment(SalesLine: Record "Sales Line"; TotalQtyToAssign: Decimal; TotalAmtToAssign: Decimal)
    begin
        SuggestAssignment(SalesLine, TotalQtyToAssign, TotalAmtToAssign, TotalQtyToAssign, TotalAmtToAssign)
    end;

    procedure SuggestAssignment(SalesLine: Record "Sales Line"; TotalQtyToAssign: Decimal; TotalAmtToAssign: Decimal; TotalQtyToHandle: Decimal; TotalAmtToHandle: Decimal)
    var
        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
        Selection: Integer;
        SelectionTxt: Text;
        SuggestItemChargeMenuTxt: Text;
        SuggestItemChargeMessageTxt: Text;
        IsHandled: Boolean;
    begin
        SalesLine.TestField("Qty. to Invoice");
        ItemChargeAssgntSales.SetRange("Document Type", SalesLine."Document Type");
        ItemChargeAssgntSales.SetRange("Document No.", SalesLine."Document No.");
        ItemChargeAssgntSales.SetRange("Document Line No.", SalesLine."Line No.");
        if ItemChargeAssgntSales.IsEmpty() then
            exit;

        IsHandled := false;
        OnSuggestAssignmentOnBeforeSelectionItemChargeAssign(ItemChargeAssgntSales, SalesLine, TotalQtyToAssign, TotalAmtToAssign, IsHandled);
        if IsHandled then
            exit;

        Selection := 1;
        SuggestItemChargeMenuTxt :=
          StrSubstNo(ItemChargeAssignedMenu4Lbl, AssignEquallyMenuText(), AssignByAmountMenuText(), AssignByWeightMenuText(), AssignByVolumeMenuText());
        if ItemChargeAssgntSales.Count > 1 then begin
            Selection := 2;
            SuggestItemChargeMessageTxt := SuggestItemChargeMsg;
            OnBeforeShowSuggestItemChargeAssignStrMenu(SalesLine, SuggestItemChargeMenuTxt, SuggestItemChargeMessageTxt, Selection);
            if SuggestItemChargeMenuTxt = '' then
                exit;
            if StrLen(DelChr(SuggestItemChargeMenuTxt, '=', DelChr(SuggestItemChargeMenuTxt, '=', ','))) > 1 then
                Selection := StrMenu(SuggestItemChargeMenuTxt, Selection, SuggestItemChargeMessageTxt)
            else
                Selection := 1;
        end;
        if Selection = 0 then
            exit;

        SelectionTxt := SelectStr(Selection, SuggestItemChargeMenuTxt);
        OnSuggestAssignmentOnBeforeAssignItemCharges(SalesLine, ItemChargeAssgntSales);
        AssignItemCharges(SalesLine, TotalQtyToAssign, TotalAmtToAssign, TotalQtyToHandle, TotalAmtToHandle, SelectionTxt);
    end;

    procedure AssignItemCharges(SalesLine: Record "Sales Line"; TotalQtyToAssign: Decimal; TotalAmtToAssign: Decimal; SelectedOptionValue: Integer)
    begin
        AssignItemCharges(SalesLine, TotalQtyToAssign, TotalAmtToAssign, GetSelectionText(SelectedOptionValue));
    end;

    local procedure GetSelectionText(OptionValue: Integer): Text
    var
        SuggestItemChargeMenuTxt: Text;
    begin
        SuggestItemChargeMenuTxt :=
            StrSubstNo(ItemChargeAssignedMenu4Lbl, AssignEquallyMenuText(), AssignByAmountMenuText(), AssignByWeightMenuText(), AssignByVolumeMenuText());
        exit(SelectStr(OptionValue + 1, SuggestItemChargeMenuTxt));
    end;

    procedure AssignItemCharges(SalesLine: Record "Sales Line"; TotalQtyToAssign: Decimal; TotalAmtToAssign: Decimal; SelectionTxt: Text)
    begin
        AssignItemCharges(SalesLine, TotalQtyToAssign, TotalAmtToAssign, TotalQtyToAssign, TotalAmtToAssign, SelectionTxt);
    end;

    procedure AssignItemCharges(SalesLine: Record "Sales Line"; TotalQtyToAssign: Decimal; TotalAmtToAssign: Decimal; TotalQtyToHandle: Decimal; TotalAmtToHandle: Decimal; SelectionTxt: Text)
    var
        Currency: Record Currency;
        SalesHeader: Record "Sales Header";
        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
        ItemChargesAssigned: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAssignItemCharges(SalesLine, TotalQtyToAssign, TotalAmtToAssign, IsHandled, SelectionTxt);
        if IsHandled then
            exit;

        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        if not Currency.Get(SalesHeader."Currency Code") then
            Currency.InitRoundingPrecision();

        ItemChargeAssgntSales.SetRange("Document Type", SalesLine."Document Type");
        ItemChargeAssgntSales.SetRange("Document No.", SalesLine."Document No.");
        ItemChargeAssgntSales.SetRange("Document Line No.", SalesLine."Line No.");
        if ItemChargeAssgntSales.FindFirst() then begin
            ItemChargeAssgntSales.ModifyAll("Amount to Assign", 0);
            ItemChargeAssgntSales.ModifyAll("Qty. to Assign", 0);
            ItemChargeAssgntSales.ModifyAll("Amount to Handle", 0);
            ItemChargeAssgntSales.ModifyAll("Qty. to Handle", 0);

            case SelectionTxt of
                AssignEquallyMenuText():
                    AssignEqually(ItemChargeAssgntSales, Currency, TotalQtyToAssign, TotalAmtToAssign, TotalQtyToHandle, TotalAmtToHandle);
                AssignByAmountMenuText():
                    AssignByAmount(ItemChargeAssgntSales, Currency, SalesHeader, TotalQtyToAssign, TotalAmtToAssign, TotalQtyToHandle, TotalAmtToHandle);
                AssignByWeightMenuText():
                    AssignByWeight(ItemChargeAssgntSales, Currency, TotalQtyToAssign);
                AssignByVolumeMenuText():
                    AssignByVolume(ItemChargeAssgntSales, Currency, TotalQtyToAssign);
                else begin
                    OnAssignItemCharges(
                      SelectionTxt, ItemChargeAssgntSales, Currency, SalesHeader, TotalQtyToAssign, TotalAmtToAssign, ItemChargesAssigned);
                    if not ItemChargesAssigned then
                        Error(ItemChargesNotAssignedErr);
                end;
            end;
        end;
    end;

    procedure AssignEquallyMenuText(): Text
    begin
        exit(EquallyTok)
    end;

    procedure AssignByAmountMenuText(): Text
    begin
        exit(ByAmountTok)
    end;

    procedure AssignByWeightMenuText(): Text
    begin
        exit(ByWeightTok)
    end;

    procedure AssignByVolumeMenuText(): Text
    begin
        exit(ByVolumeTok)
    end;

    local procedure AssignEqually(var ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)"; Currency: Record Currency; TotalQtyToAssign: Decimal; TotalAmtToAssign: Decimal; TotalQtyToHandle: Decimal; TotalAmtToHandle: Decimal)
    var
        TempItemChargeAssgntSales: Record "Item Charge Assignment (Sales)" temporary;
        RemainingNumOfLines: Integer;
    begin
        repeat
            if not ItemChargeAssignmentSales.SalesLineInvoiced() then begin
                TempItemChargeAssgntSales.Init();
                TempItemChargeAssgntSales := ItemChargeAssignmentSales;
                TempItemChargeAssgntSales.Insert();
            end;
        until ItemChargeAssignmentSales.Next() = 0;

        if TempItemChargeAssgntSales.FindSet(true) then begin
            RemainingNumOfLines := TempItemChargeAssgntSales.Count();
            repeat
                ItemChargeAssignmentSales.Get(
                  TempItemChargeAssgntSales."Document Type",
                  TempItemChargeAssgntSales."Document No.",
                  TempItemChargeAssgntSales."Document Line No.",
                  TempItemChargeAssgntSales."Line No.");
                ItemChargeAssignmentSales."Qty. to Assign" :=
                  Round(TotalQtyToAssign / RemainingNumOfLines, UOMMgt.QtyRndPrecision());
                ItemChargeAssignmentSales."Amount to Assign" :=
                  Round(
                    ItemChargeAssignmentSales."Qty. to Assign" / TotalQtyToAssign * TotalAmtToAssign,
                    Currency."Amount Rounding Precision");
                ItemChargeAssignmentSales."Qty. to Handle" := ItemChargeAssignmentSales."Qty. to Assign";
                ItemChargeAssignmentSales."Amount to Handle" := ItemChargeAssignmentSales."Amount to Assign";
                TotalQtyToAssign -= ItemChargeAssignmentSales."Qty. to Assign";
                TotalAmtToAssign -= ItemChargeAssignmentSales."Amount to Assign";
                TotalQtyToHandle -= ItemChargeAssignmentSales."Qty. to Handle";
                TotalAmtToHandle -= ItemChargeAssignmentSales."Amount to Handle";
                RemainingNumOfLines := RemainingNumOfLines - 1;
                OnAssignEquallyOnBeforeItemChargeAssignmentSalesModify(ItemChargeAssignmentSales);
                ItemChargeAssignmentSales.Modify();
            until TempItemChargeAssgntSales.Next() = 0;
        end;
        TempItemChargeAssgntSales.DeleteAll();
    end;

    local procedure AssignByAmount(var ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)"; Currency: Record Currency; SalesHeader: Record "Sales Header"; TotalQtyToAssign: Decimal; TotalAmtToAssign: Decimal; TotalQtyToHandle: Decimal; TotalAmtToHandle: Decimal)
    var
        TempItemChargeAssgntSales: Record "Item Charge Assignment (Sales)" temporary;
        SalesLine: Record "Sales Line";
        SalesShptLine: Record "Sales Shipment Line";
        CurrExchRate: Record "Currency Exchange Rate";
        ReturnRcptLine: Record "Return Receipt Line";
        CurrencyCode: Code[10];
        TotalAppliesToDocLineAmount: Decimal;
        IsHandled: Boolean;
    begin
        repeat
            if not ItemChargeAssignmentSales.SalesLineInvoiced() then begin
                TempItemChargeAssgntSales.Init();
                TempItemChargeAssgntSales := ItemChargeAssignmentSales;
                case ItemChargeAssignmentSales."Applies-to Doc. Type" of
                    ItemChargeAssignmentSales."Applies-to Doc. Type"::Quote,
                    ItemChargeAssignmentSales."Applies-to Doc. Type"::Order,
                    ItemChargeAssignmentSales."Applies-to Doc. Type"::Invoice,
                    ItemChargeAssignmentSales."Applies-to Doc. Type"::"Return Order",
                    ItemChargeAssignmentSales."Applies-to Doc. Type"::"Credit Memo":
                        begin
                            IsHandled := false;
                            OnAssignByAmountOnBeforeGetSalesLine(SalesLine, ItemChargeAssignmentSales, IsHandled);
                            if not IsHandled then
                                SalesLine.Get(
                                  ItemChargeAssignmentSales."Applies-to Doc. Type",
                                  ItemChargeAssignmentSales."Applies-to Doc. No.",
                                  ItemChargeAssignmentSales."Applies-to Doc. Line No.");
                            TempItemChargeAssgntSales."Applies-to Doc. Line Amount" :=
                              Abs(SalesLine."Line Amount");
                        end;
                    ItemChargeAssignmentSales."Applies-to Doc. Type"::"Return Receipt":
                        begin
                            ReturnRcptLine.Get(
                              ItemChargeAssignmentSales."Applies-to Doc. No.",
                              ItemChargeAssignmentSales."Applies-to Doc. Line No.");
                            CurrencyCode := ReturnRcptLine.GetCurrencyCode();
                            if CurrencyCode = SalesHeader."Currency Code" then
                                TempItemChargeAssgntSales."Applies-to Doc. Line Amount" :=
                                  Abs(ReturnRcptLine."Item Charge Base Amount")
                            else
                                TempItemChargeAssgntSales."Applies-to Doc. Line Amount" :=
                                  CurrExchRate.ExchangeAmtFCYToFCY(
                                    SalesHeader."Posting Date", CurrencyCode, SalesHeader."Currency Code",
                                    Abs(ReturnRcptLine."Item Charge Base Amount"));
                        end;
                    ItemChargeAssignmentSales."Applies-to Doc. Type"::Shipment:
                        begin
                            SalesShptLine.Get(
                              ItemChargeAssignmentSales."Applies-to Doc. No.",
                              ItemChargeAssignmentSales."Applies-to Doc. Line No.");
                            CurrencyCode := SalesShptLine.GetCurrencyCode();
                            if CurrencyCode = SalesHeader."Currency Code" then
                                TempItemChargeAssgntSales."Applies-to Doc. Line Amount" :=
                                  Abs(SalesShptLine."Item Charge Base Amount")
                            else
                                TempItemChargeAssgntSales."Applies-to Doc. Line Amount" :=
                                  CurrExchRate.ExchangeAmtFCYToFCY(
                                    SalesHeader."Posting Date", CurrencyCode, SalesHeader."Currency Code",
                                    Abs(SalesShptLine."Item Charge Base Amount"));
                        end;
                end;
                OnAssignByAmountOnAfterAssignAppliesToDocLineAmount(ItemChargeAssignmentSales, TempItemChargeAssgntSales, SalesHeader, TotalQtyToAssign, TotalAmtToAssign);
                if TempItemChargeAssgntSales."Applies-to Doc. Line Amount" <> 0 then
                    TempItemChargeAssgntSales.Insert()
                else begin
                    ItemChargeAssignmentSales."Amount to Assign" := 0;
                    ItemChargeAssignmentSales."Qty. to Assign" := 0;
                    ItemChargeAssignmentSales."Amount to Handle" := 0;
                    ItemChargeAssignmentSales."Qty. to Handle" := 0;
                    ItemChargeAssignmentSales.Modify();
                end;
                TotalAppliesToDocLineAmount += TempItemChargeAssgntSales."Applies-to Doc. Line Amount";
            end;
        until ItemChargeAssignmentSales.Next() = 0;

        OnAssignByAmountOnBeforeModifyItemChargeAssignmentSalesLoop(ItemChargeAssignmentSales, TempItemChargeAssgntSales, TotalAppliesToDocLineAmount, SalesHeader, TotalQtyToAssign, TotalAmtToAssign);

        if TempItemChargeAssgntSales.FindSet(true) then
            repeat
                ItemChargeAssignmentSales.Get(
                  TempItemChargeAssgntSales."Document Type",
                  TempItemChargeAssgntSales."Document No.",
                  TempItemChargeAssgntSales."Document Line No.",
                  TempItemChargeAssgntSales."Line No.");
                if TotalQtyToAssign <> 0 then begin
                    ItemChargeAssignmentSales."Qty. to Assign" :=
                      Round(
                        TempItemChargeAssgntSales."Applies-to Doc. Line Amount" / TotalAppliesToDocLineAmount * TotalQtyToAssign,
                        UOMMgt.QtyRndPrecision());
                    ItemChargeAssignmentSales."Amount to Assign" :=
                      Round(
                        ItemChargeAssignmentSales."Qty. to Assign" / TotalQtyToAssign * TotalAmtToAssign,
                        Currency."Amount Rounding Precision");
                    ItemChargeAssignmentSales."Qty. to Handle" := ItemChargeAssignmentSales."Qty. to Assign";
                    ItemChargeAssignmentSales."Amount to Handle" := ItemChargeAssignmentSales."Amount to Assign";
                    TotalQtyToAssign -= ItemChargeAssignmentSales."Qty. to Assign";
                    TotalAmtToAssign -= ItemChargeAssignmentSales."Amount to Assign";
                    TotalQtyToHandle -= ItemChargeAssignmentSales."Qty. to Handle";
                    TotalAmtToHandle -= ItemChargeAssignmentSales."Amount to Handle";
                    TotalAppliesToDocLineAmount -= TempItemChargeAssgntSales."Applies-to Doc. Line Amount";
                    OnAssignByAmountOnBeforeItemChargeAssignmentSalesModify(ItemChargeAssignmentSales);
                    ItemChargeAssignmentSales.Modify();
                end;
            until TempItemChargeAssgntSales.Next() = 0;

        TempItemChargeAssgntSales.DeleteAll();
    end;

    local procedure AssignByWeight(var ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)"; Currency: Record Currency; TotalQtyToAssign: Decimal)
    var
        TempItemChargeAssgntSales: Record "Item Charge Assignment (Sales)" temporary;
        LineArray: array[3] of Decimal;
        TotalGrossWeight: Decimal;
        QtyRemaining: Decimal;
        AmountRemaining: Decimal;
    begin
        repeat
            if not ItemChargeAssignmentSales.SalesLineInvoiced() then begin
                TempItemChargeAssgntSales.Init();
                TempItemChargeAssgntSales := ItemChargeAssignmentSales;
                TempItemChargeAssgntSales.Insert();
                GetItemValues(TempItemChargeAssgntSales, LineArray);
                TotalGrossWeight := TotalGrossWeight + (LineArray[2] * LineArray[1]);
            end;
        until ItemChargeAssignmentSales.Next() = 0;
        OnAssignByWeightOnAfterCalcTotalGrossWeight(ItemChargeAssignmentSales, TotalGrossWeight, Currency);

        QtyRemaining := 0;
        if TempItemChargeAssgntSales.FindSet(true) then
            repeat
                GetItemValues(TempItemChargeAssgntSales, LineArray);
                if TotalGrossWeight <> 0 then
                    TempItemChargeAssgntSales."Qty. to Assign" :=
                      (TotalQtyToAssign * LineArray[2] * LineArray[1]) / TotalGrossWeight + QtyRemaining
                else
                    TempItemChargeAssgntSales."Qty. to Assign" := 0;
                TempItemChargeAssgntSales."Qty. to Handle" := TempItemChargeAssgntSales."Qty. to Assign";
                AssignSalesItemCharge(ItemChargeAssignmentSales, TempItemChargeAssgntSales, Currency, QtyRemaining, AmountRemaining);
            until TempItemChargeAssgntSales.Next() = 0;
        OnAssignByWeightOnBeforeTempItemChargeAssgntSalesDelete(ItemChargeAssignmentSales, QtyRemaining, TotalQtyToAssign, Currency);
        TempItemChargeAssgntSales.DeleteAll();
    end;

    local procedure AssignByVolume(var ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)"; Currency: Record Currency; TotalQtyToAssign: Decimal)
    var
        TempItemChargeAssgntSales: Record "Item Charge Assignment (Sales)" temporary;
        LineArray: array[3] of Decimal;
        TotalUnitVolume: Decimal;
        QtyRemaining: Decimal;
        AmountRemaining: Decimal;
    begin
        repeat
            if not ItemChargeAssignmentSales.SalesLineInvoiced() then begin
                TempItemChargeAssgntSales.Init();
                TempItemChargeAssgntSales := ItemChargeAssignmentSales;
                TempItemChargeAssgntSales.Insert();
                GetItemValues(TempItemChargeAssgntSales, LineArray);
                TotalUnitVolume := TotalUnitVolume + (LineArray[3] * LineArray[1]);
            end;
        until ItemChargeAssignmentSales.Next() = 0;

        QtyRemaining := 0;
        AmountRemaining := 0;
        if TempItemChargeAssgntSales.FindSet(true) then
            repeat
                GetItemValues(TempItemChargeAssgntSales, LineArray);
                if TotalUnitVolume <> 0 then
                    TempItemChargeAssgntSales."Qty. to Assign" :=
                      (TotalQtyToAssign * LineArray[3] * LineArray[1]) / TotalUnitVolume + QtyRemaining
                else
                    TempItemChargeAssgntSales."Qty. to Assign" := 0;
                TempItemChargeAssgntSales."Qty. to Handle" := TempItemChargeAssgntSales."Qty. to Assign";
                AssignSalesItemCharge(ItemChargeAssignmentSales, TempItemChargeAssgntSales, Currency, QtyRemaining, AmountRemaining);
            until TempItemChargeAssgntSales.Next() = 0;
        TempItemChargeAssgntSales.DeleteAll();
    end;

    procedure AssignSalesItemCharge(var ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)"; ItemChargeAssignmentSales2: Record "Item Charge Assignment (Sales)"; Currency: Record Currency; var QtyRemaining: Decimal; var AmountRemaining: Decimal)
    begin
        ItemChargeAssignmentSales.Get(
          ItemChargeAssignmentSales2."Document Type",
          ItemChargeAssignmentSales2."Document No.",
          ItemChargeAssignmentSales2."Document Line No.",
          ItemChargeAssignmentSales2."Line No.");
        ItemChargeAssignmentSales."Qty. to Assign" :=
          Round(ItemChargeAssignmentSales2."Qty. to Assign", UOMMgt.QtyRndPrecision());
        ItemChargeAssignmentSales."Amount to Assign" :=
          ItemChargeAssignmentSales."Qty. to Assign" * ItemChargeAssignmentSales."Unit Cost" + AmountRemaining;
        AmountRemaining := ItemChargeAssignmentSales."Amount to Assign" -
          Round(ItemChargeAssignmentSales."Amount to Assign", Currency."Amount Rounding Precision");
        QtyRemaining := ItemChargeAssignmentSales2."Qty. to Assign" - ItemChargeAssignmentSales."Qty. to Assign";
        ItemChargeAssignmentSales."Amount to Assign" :=
          Round(ItemChargeAssignmentSales."Amount to Assign", Currency."Amount Rounding Precision");
        ItemChargeAssignmentSales."Qty. to Handle" := ItemChargeAssignmentSales."Qty. to Assign";
        ItemChargeAssignmentSales."Amount to Handle" := ItemChargeAssignmentSales."Amount to Assign";
        ItemChargeAssignmentSales.Modify();
    end;

    procedure GetItemValues(TempItemChargeAssgntSales: Record "Item Charge Assignment (Sales)" temporary; var DecimalArray: array[3] of Decimal)
    var
        SalesLine: Record "Sales Line";
        SalesShptLine: Record "Sales Shipment Line";
        ReturnRcptLine: Record "Return Receipt Line";
    begin
        Clear(DecimalArray);
        case TempItemChargeAssgntSales."Applies-to Doc. Type" of
            TempItemChargeAssgntSales."Applies-to Doc. Type"::Quote,
            TempItemChargeAssgntSales."Applies-to Doc. Type"::Order,
            TempItemChargeAssgntSales."Applies-to Doc. Type"::Invoice,
            TempItemChargeAssgntSales."Applies-to Doc. Type"::"Return Order",
            TempItemChargeAssgntSales."Applies-to Doc. Type"::"Credit Memo":
                begin
                    SalesLine.Get(TempItemChargeAssgntSales."Applies-to Doc. Type", TempItemChargeAssgntSales."Applies-to Doc. No.", TempItemChargeAssgntSales."Applies-to Doc. Line No.");
                    DecimalArray[1] := SalesLine.Quantity;
                    DecimalArray[2] := SalesLine."Gross Weight";
                    DecimalArray[3] := SalesLine."Unit Volume";
                end;
            TempItemChargeAssgntSales."Applies-to Doc. Type"::"Return Receipt":
                begin
                    ReturnRcptLine.Get(TempItemChargeAssgntSales."Applies-to Doc. No.", TempItemChargeAssgntSales."Applies-to Doc. Line No.");
                    DecimalArray[1] := ReturnRcptLine.Quantity;
                    DecimalArray[2] := ReturnRcptLine."Gross Weight";
                    DecimalArray[3] := ReturnRcptLine."Unit Volume";
                end;
            TempItemChargeAssgntSales."Applies-to Doc. Type"::Shipment:
                begin
                    SalesShptLine.Get(TempItemChargeAssgntSales."Applies-to Doc. No.", TempItemChargeAssgntSales."Applies-to Doc. Line No.");
                    DecimalArray[1] := SalesShptLine.Quantity;
                    DecimalArray[2] := SalesShptLine."Gross Weight";
                    DecimalArray[3] := SalesShptLine."Unit Volume";
                end;
        end;

        OnAfterGetItemValues(TempItemChargeAssgntSales, DecimalArray);
    end;

    procedure SuggestAssignmentFromLine(var FromItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)")
    var
        Currency: Record Currency;
        SalesHeader: Record "Sales Header";
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        TempItemChargeAssgntSales: Record "Item Charge Assignment (Sales)" temporary;
        TotalAmountToAssign: Decimal;
        TotalQtyToAssign: Decimal;
        TotalAmountToHandle: Decimal;
        TotalQtyToHandle: Decimal;
        ItemChargeAssgntLineAmt: Decimal;
        ItemChargeAssgntLineQty: Decimal;
    begin
        SalesHeader.Get(FromItemChargeAssignmentSales."Document Type", FromItemChargeAssignmentSales."Document No.");
        if not Currency.Get(SalesHeader."Currency Code") then
            Currency.InitRoundingPrecision();

        GetItemChargeAssgntLineAmounts(
          FromItemChargeAssignmentSales."Document Type", FromItemChargeAssignmentSales."Document No.", FromItemChargeAssignmentSales."Document Line No.",
          ItemChargeAssgntLineQty, ItemChargeAssgntLineAmt);

        if not ItemChargeAssignmentSales.Get(FromItemChargeAssignmentSales."Document Type", FromItemChargeAssignmentSales."Document No.", FromItemChargeAssignmentSales."Document Line No.", FromItemChargeAssignmentSales."Line No.") then
            exit;

        ItemChargeAssignmentSales."Qty. to Assign" := FromItemChargeAssignmentSales."Qty. to Assign";
        ItemChargeAssignmentSales."Amount to Assign" := FromItemChargeAssignmentSales."Amount to Assign";
        ItemChargeAssignmentSales."Qty. to Handle" := FromItemChargeAssignmentSales."Qty. to Handle";
        ItemChargeAssignmentSales."Amount to Handle" := FromItemChargeAssignmentSales."Amount to Handle";
        ItemChargeAssignmentSales.Modify();

        ItemChargeAssignmentSales.SetRange("Document Type", FromItemChargeAssignmentSales."Document Type");
        ItemChargeAssignmentSales.SetRange("Document No.", FromItemChargeAssignmentSales."Document No.");
        ItemChargeAssignmentSales.SetRange("Document Line No.", FromItemChargeAssignmentSales."Document Line No.");
        ItemChargeAssignmentSales.CalcSums("Qty. to Assign", "Amount to Assign", "Qty. to Handle", "Amount to Handle");
        TotalQtyToAssign := ItemChargeAssignmentSales."Qty. to Assign";
        TotalAmountToAssign := ItemChargeAssignmentSales."Amount to Assign";
        TotalQtyToHandle := ItemChargeAssignmentSales."Qty. to Handle";
        TotalAmountToHandle := ItemChargeAssignmentSales."Amount to Handle";

        if TotalAmountToAssign = ItemChargeAssgntLineAmt then begin
            FromItemChargeAssignmentSales.Find();
            exit;
        end;

        if TotalQtyToAssign = ItemChargeAssgntLineQty then begin
            TotalAmountToAssign := ItemChargeAssgntLineAmt;
            TotalAmountToHandle := ItemChargeAssgntLineAmt;
            ItemChargeAssignmentSales.FindSet();
            repeat
                if not ItemChargeAssignmentSales.SalesLineInvoiced() then begin
                    TempItemChargeAssgntSales := ItemChargeAssignmentSales;
                    TempItemChargeAssgntSales.Insert();
                end;
            until ItemChargeAssignmentSales.Next() = 0;

            if TempItemChargeAssgntSales.FindSet() then
                repeat
                    ItemChargeAssignmentSales.Get(
                      TempItemChargeAssgntSales."Document Type",
                      TempItemChargeAssgntSales."Document No.",
                      TempItemChargeAssgntSales."Document Line No.",
                      TempItemChargeAssgntSales."Line No.");
                    if TotalQtyToAssign <> 0 then begin
                        ItemChargeAssignmentSales."Amount to Assign" :=
                          Round(
                            ItemChargeAssignmentSales."Qty. to Assign" / TotalQtyToAssign * TotalAmountToAssign,
                            Currency."Amount Rounding Precision");
                        if TotalQtyToHandle <> 0 then
                            ItemChargeAssignmentSales."Amount to Handle" :=
                              Round(
                                ItemChargeAssignmentSales."Qty. to Handle" / TotalQtyToHandle * TotalAmountToHandle,
                                Currency."Amount Rounding Precision");
                        TotalQtyToAssign -= ItemChargeAssignmentSales."Qty. to Assign";
                        TotalAmountToAssign -= ItemChargeAssignmentSales."Amount to Assign";
                        TotalQtyToHandle -= ItemChargeAssignmentSales."Qty. to Handle";
                        TotalAmountToHandle -= ItemChargeAssignmentSales."Amount to Handle";
                        ItemChargeAssignmentSales.Modify();
                    end;
                until TempItemChargeAssgntSales.Next() = 0;
        end;

        FromItemChargeAssignmentSales.Find();
    end;

    local procedure GetItemChargeAssgntLineAmounts(DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20]; DocumentLineNo: Integer; var ItemChargeAssgntLineQty: Decimal; var ItemChargeAssgntLineAmt: Decimal)
    var
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        Currency: Record Currency;
    begin
        SalesHeader.Get(DocumentType, DocumentNo);
        if SalesHeader."Currency Code" = '' then
            Currency.InitRoundingPrecision()
        else
            Currency.Get(SalesHeader."Currency Code");

        SalesLine.Get(DocumentType, DocumentNo, DocumentLineNo);
        SalesLine.TestField(Type, SalesLine.Type::"Charge (Item)");
        SalesLine.TestField("No.");
        SalesLine.TestField(Quantity);

        if (SalesLine."Inv. Discount Amount" = 0) and
           (SalesLine."Line Discount Amount" = 0) and
           (not SalesHeader."Prices Including VAT")
        then
            ItemChargeAssgntLineAmt := SalesLine."Line Amount"
        else
            if SalesHeader."Prices Including VAT" then
                ItemChargeAssgntLineAmt :=
                  Round((SalesLine."Line Amount" - SalesLine."Inv. Discount Amount") / (1 + SalesLine."VAT %" / 100),
                    Currency."Amount Rounding Precision")
            else
                ItemChargeAssgntLineAmt := SalesLine."Line Amount" - SalesLine."Inv. Discount Amount";

        ItemChargeAssgntLineAmt :=
          Round(
            ItemChargeAssgntLineAmt * (SalesLine."Qty. to Invoice" / SalesLine.Quantity),
            Currency."Amount Rounding Precision");
        ItemChargeAssgntLineQty := SalesLine."Qty. to Invoice";
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDocChargeAssgnt(var LastItemChargeAssgntSales: Record "Item Charge Assignment (Sales)"; var ShipmentNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetItemValues(TempItemChargeAssgntSales: Record "Item Charge Assignment (Sales)" temporary; var DecimalArray: array[3] of Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAssignByWeightOnAfterCalcTotalGrossWeight(var ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)"; TotalGrossWeight: Decimal; Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAssignByWeightOnBeforeTempItemChargeAssgntSalesDelete(var ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)"; QtyRemaining: Decimal; TotalQtyToAssign: Decimal; Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAssignByAmountOnAfterAssignAppliesToDocLineAmount(ItemChargeAssignmentSale: Record "Item Charge Assignment (Sales)"; var TempItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)" temporary; SalesHeader: Record "Sales Header"; TotalQtyToAssign: Decimal; TotalAmtToAssign: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAssignItemCharges(var SalesLine: Record "Sales Line"; TotalQtyToAssign: Decimal; TotalAmtToAssign: Decimal; var IsHandled: Boolean; SelectionTxt: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateDocChargeAssgn(var LastItemChargeAssgntSales: Record "Item Charge Assignment (Sales)"; var FromSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertItemChargeAssgntWithAssignValues(var ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)"; FromItemChargeAssgntSales: Record "Item Charge Assignment (Sales)")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertItemChargeAssignmentWithValuesTo(var FromItemChargeAssgntSales: Record "Item Charge Assignment (Sales)"; var ItemChargeAssgntSales: record "Item Charge Assignment (Sales)"; var ApplToDocType: Enum "Sales Applies-to Document Type"; var FromApplToDocNo: Code[20]; var FromApplToDocLineNo: Integer; var FromItemNo: Code[20]; var FromDescription: Text[100]; var NextLineNo: Integer; var qtytoAssign: decimal; var AmounttoAssign: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowSuggestItemChargeAssignStrMenu(SalesLine: Record "Sales Line"; var SuggestItemChargeMenuTxt: Text; var SuggestItemChargeMessageTxt: Text; var Selection: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAssignItemCharges(SelectionTxt: Text; var ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)"; Currency: Record Currency; SalesHeader: Record "Sales Header"; TotalQtyToAssign: Decimal; TotalAmtToAssign: Decimal; var ItemChargesAssigned: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAssignEquallyOnBeforeItemChargeAssignmentSalesModify(var ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateDocChargeAssgnOnAfterFromSalesLineSetFilters(var LastItemChargeAssgntSales: Record "Item Charge Assignment (Sales)"; var FromSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAssignByAmountOnBeforeItemChargeAssignmentSalesModify(var ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSuggestAssignmentOnBeforeSelectionItemChargeAssign(var ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)"; SalesLine: Record "Sales Line"; TotalQtyToAssign: Decimal; TotalAmtToAssign: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSuggestAssignmentOnBeforeAssignItemCharges(var SalesLine: Record "Sales Line"; ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAssignByAmountOnBeforeGetSalesLine(var SalesLine: Record "Sales Line"; ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateShptChargeAssgnt(var FromSalesShptLine: Record "Sales Shipment Line"; var ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAssignByAmountOnBeforeModifyItemChargeAssignmentSalesLoop(var ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)"; var TempItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)" temporary; var TotalAppliesToDocLineAmount: Decimal; SalesHeader: Record "Sales Header"; TotalQtyToAssign: Decimal; TotalAmtToAssign: Decimal)
    begin
    end;
}

