// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Finance.Currency;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Transfer;
using Microsoft.Purchases.History;
using Microsoft.Sales.History;

codeunit 5805 "Item Charge Assgnt. (Purch.)"
{
    Permissions = TableData "Purchase Header" = r,
                  TableData "Purchase Line" = r,
                  TableData "Purch. Rcpt. Line" = r,
                  TableData "Item Charge Assignment (Purch)" = rimd,
                  TableData "Return Shipment Line" = r;

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
        ItemChargesNotAssignedErr: Label 'No item charges were assigned.';
        ItemChargeAssignedMenu4Lbl: Label '%1,%2,%3,%4', Locked = true;
        ItemChargeAssignedMenu3Lbl: Label '%1,%2,%3', Locked = true;

    procedure InsertItemChargeAssignment(ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)"; ApplToDocType: Enum "Purchase Applies-to Document Type"; ApplToDocNo2: Code[20]; ApplToDocLineNo2: Integer; ItemNo2: Code[20]; Description2: Text[100]; var NextLineNo: Integer)
    begin
        InsertItemChargeAssignmentWithValues(
          ItemChargeAssgntPurch, ApplToDocType, ApplToDocNo2, ApplToDocLineNo2, ItemNo2, Description2, 0, 0, NextLineNo);
    end;

    procedure InsertItemChargeAssignmentWithValues(FromItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)"; ApplToDocType: Enum "Purchase Applies-to Document Type"; FromApplToDocNo: Code[20]; FromApplToDocLineNo: Integer; FromItemNo: Code[20]; FromDescription: Text[100]; QtyToAssign: Decimal; AmountToAssign: Decimal; var NextLineNo: Integer)
    var
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
    begin
        InsertItemChargeAssignmentWithValuesTo(
          FromItemChargeAssgntPurch, ApplToDocType, FromApplToDocNo, FromApplToDocLineNo, FromItemNo, FromDescription,
          QtyToAssign, AmountToAssign, NextLineNo, ItemChargeAssgntPurch);
    end;

    procedure InsertItemChargeAssignmentWithValuesTo(
        FromItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)"; ApplToDocType: Enum "Purchase Applies-to Document Type";
        FromApplToDocNo: Code[20]; FromApplToDocLineNo: Integer; FromItemNo: Code[20]; FromDescription: Text[100];
        QtyToAssign: Decimal; AmountToAssign: Decimal; var NextLineNo: Integer; var ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertItemChargeAssignmentWithValuesTo(FromItemChargeAssgntPurch, ItemChargeAssgntPurch, ApplToDocType, FromApplToDocNo, FromApplToDocLineNo, FromItemNo, FromDescription, NextLineNo, QtyToAssign, AmountToAssign, IsHandled);
        if IsHandled then
            exit;

        NextLineNo := NextLineNo + 10000;

        ItemChargeAssgntPurch."Document No." := FromItemChargeAssgntPurch."Document No.";
        ItemChargeAssgntPurch."Document Type" := FromItemChargeAssgntPurch."Document Type";
        ItemChargeAssgntPurch."Document Line No." := FromItemChargeAssgntPurch."Document Line No.";
        ItemChargeAssgntPurch."Item Charge No." := FromItemChargeAssgntPurch."Item Charge No.";
        ItemChargeAssgntPurch."Line No." := NextLineNo;
        ItemChargeAssgntPurch."Applies-to Doc. No." := FromApplToDocNo;
        ItemChargeAssgntPurch."Applies-to Doc. Type" := ApplToDocType;
        ItemChargeAssgntPurch."Applies-to Doc. Line No." := FromApplToDocLineNo;
        ItemChargeAssgntPurch."Item No." := FromItemNo;
        ItemChargeAssgntPurch.Description := FromDescription;
        ItemChargeAssgntPurch."Unit Cost" := FromItemChargeAssgntPurch."Unit Cost";
        if QtyToAssign <> 0 then begin
            ItemChargeAssgntPurch."Amount to Assign" := AmountToAssign;
            ItemChargeAssgntPurch.Validate("Qty. to Assign", QtyToAssign);
        end;
        OnBeforeInsertItemChargeAssgntWithAssignValues(ItemChargeAssgntPurch, FromItemChargeAssgntPurch);
        ItemChargeAssgntPurch.Insert();
    end;

    procedure Summarize(var TempToItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)" temporary; var ToItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)")
    begin
        TempToItemChargeAssignmentPurch.SetCurrentKey("Applies-to Doc. Type", "Applies-to Doc. No.", "Applies-to Doc. Line No.");
        if TempToItemChargeAssignmentPurch.FindSet() then
            repeat
                if (TempToItemChargeAssignmentPurch."Item Charge No." <> ToItemChargeAssignmentPurch."Item Charge No.") or
                   (TempToItemChargeAssignmentPurch."Applies-to Doc. No." <> ToItemChargeAssignmentPurch."Applies-to Doc. No.") or
                   (TempToItemChargeAssignmentPurch."Applies-to Doc. Line No." <> ToItemChargeAssignmentPurch."Applies-to Doc. Line No.")
                then begin
                    if ToItemChargeAssignmentPurch."Line No." <> 0 then
                        ToItemChargeAssignmentPurch.Insert();
                    ToItemChargeAssignmentPurch := TempToItemChargeAssignmentPurch;
                    ToItemChargeAssignmentPurch."Qty. to Assign" := 0;
                    ToItemChargeAssignmentPurch."Amount to Assign" := 0;
                    ToItemChargeAssignmentPurch."Qty. to Handle" := 0;
                    ToItemChargeAssignmentPurch."Amount to Handle" := 0;
                end;
                ToItemChargeAssignmentPurch."Qty. to Assign" += TempToItemChargeAssignmentPurch."Qty. to Assign";
                ToItemChargeAssignmentPurch."Amount to Assign" += TempToItemChargeAssignmentPurch."Amount to Assign";
                ToItemChargeAssignmentPurch."Qty. to Handle" += TempToItemChargeAssignmentPurch."Qty. to Handle";
                ToItemChargeAssignmentPurch."Amount to Handle" += TempToItemChargeAssignmentPurch."Amount to Handle";
            until TempToItemChargeAssignmentPurch.Next() = 0;
        if ToItemChargeAssignmentPurch."Line No." <> 0 then
            ToItemChargeAssignmentPurch.Insert();
    end;

    procedure CreateDocChargeAssgnt(LastItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)"; ReceiptNo: Code[20])
    var
        FromPurchLine: Record "Purchase Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        NextLineNo: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateDocChargeAssgn(LastItemChargeAssgntPurch, FromPurchLine, ReceiptNo, IsHandled);
        if not IsHandled then begin
            FromPurchLine.SetRange("Document Type", LastItemChargeAssgntPurch."Document Type");
            FromPurchLine.SetRange("Document No.", LastItemChargeAssgntPurch."Document No.");
            FromPurchLine.SetRange(Type, FromPurchLine.Type::Item);
            OnCreateDocChargeAssgntOnAfterFromPurchLineSetFilters(LastItemChargeAssgntPurch, FromPurchLine);
            if FromPurchLine.Find('-') then begin
                NextLineNo := LastItemChargeAssgntPurch."Line No.";
                ItemChargeAssgntPurch.Reset();
                ItemChargeAssgntPurch.SetRange("Document Type", LastItemChargeAssgntPurch."Document Type");
                ItemChargeAssgntPurch.SetRange("Document No.", LastItemChargeAssgntPurch."Document No.");
                ItemChargeAssgntPurch.SetRange("Document Line No.", LastItemChargeAssgntPurch."Document Line No.");
                ItemChargeAssgntPurch.SetRange("Applies-to Doc. No.", LastItemChargeAssgntPurch."Document No.");
                repeat
                    if (FromPurchLine.Quantity <> 0) and
                       (FromPurchLine.Quantity <> FromPurchLine."Quantity Invoiced") and
                       (not FromPurchLine.IsWorkCenter()) and
                       ((ReceiptNo = '') or (FromPurchLine."Receipt No." = ReceiptNo)) and
                       FromPurchLine."Allow Item Charge Assignment"
                    then begin
                        ItemChargeAssgntPurch.SetRange("Applies-to Doc. Line No.", FromPurchLine."Line No.");
                        if not ItemChargeAssgntPurch.FindFirst() then
                            InsertItemChargeAssignment(
                                LastItemChargeAssgntPurch, FromPurchLine."Document Type",
                                FromPurchLine."Document No.", FromPurchLine."Line No.",
                                FromPurchLine."No.", FromPurchLine.Description, NextLineNo);
                    end;
                until FromPurchLine.Next() = 0;
            end;
        end;

        OnAfterCreateDocChargeAssgnt(LastItemChargeAssgntPurch, ReceiptNo);
    end;

    procedure CreateRcptChargeAssgnt(var FromPurchRcptLine: Record "Purch. Rcpt. Line"; ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)")
    var
        ItemChargeAssgntPurch2: Record "Item Charge Assignment (Purch)";
        NextLine: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateRcptChargeAssgnt(FromPurchRcptLine, ItemChargeAssgntPurch, IsHandled);
        if IsHandled then
            exit;

        CheckFromPurchRcptLineWorkCenter(FromPurchRcptLine);
        NextLine := ItemChargeAssgntPurch."Line No.";
        ItemChargeAssgntPurch2.SetRange("Document Type", ItemChargeAssgntPurch."Document Type");
        ItemChargeAssgntPurch2.SetRange("Document No.", ItemChargeAssgntPurch."Document No.");
        ItemChargeAssgntPurch2.SetRange("Document Line No.", ItemChargeAssgntPurch."Document Line No.");
        ItemChargeAssgntPurch2.SetRange(
          "Applies-to Doc. Type", ItemChargeAssgntPurch2."Applies-to Doc. Type"::Receipt);
        repeat
            ItemChargeAssgntPurch2.SetRange("Applies-to Doc. No.", FromPurchRcptLine."Document No.");
            ItemChargeAssgntPurch2.SetRange("Applies-to Doc. Line No.", FromPurchRcptLine."Line No.");
            if not ItemChargeAssgntPurch2.FindFirst() then
                InsertItemChargeAssignment(
                    ItemChargeAssgntPurch, ItemChargeAssgntPurch2."Applies-to Doc. Type"::Receipt,
                    FromPurchRcptLine."Document No.", FromPurchRcptLine."Line No.",
                    FromPurchRcptLine."No.", FromPurchRcptLine.Description, NextLine);
        until FromPurchRcptLine.Next() = 0;
    end;

    local procedure CheckFromPurchRcptLineWorkCenter(FromPurchRcptLine: Record "Purch. Rcpt. Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckFromPurchRcptLineWorkCenter(FromPurchRcptLine, IsHandled);
        if IsHandled then
            exit;

        FromPurchRcptLine.TestWorkCenterNo();
    end;

    procedure CreateTransferRcptChargeAssgnt(var FromTransRcptLine: Record "Transfer Receipt Line"; ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)")
    var
        ItemChargeAssgntPurch2: Record "Item Charge Assignment (Purch)";
        NextLine: Integer;
    begin
        NextLine := ItemChargeAssgntPurch."Line No.";
        ItemChargeAssgntPurch2.SetRange("Document Type", ItemChargeAssgntPurch."Document Type");
        ItemChargeAssgntPurch2.SetRange("Document No.", ItemChargeAssgntPurch."Document No.");
        ItemChargeAssgntPurch2.SetRange("Document Line No.", ItemChargeAssgntPurch."Document Line No.");
        ItemChargeAssgntPurch2.SetRange(
          "Applies-to Doc. Type", ItemChargeAssgntPurch2."Applies-to Doc. Type"::"Transfer Receipt");
        repeat
            ItemChargeAssgntPurch2.SetRange("Applies-to Doc. No.", FromTransRcptLine."Document No.");
            ItemChargeAssgntPurch2.SetRange("Applies-to Doc. Line No.", FromTransRcptLine."Line No.");
            if not ItemChargeAssgntPurch2.FindFirst() then
                InsertItemChargeAssignment(
                    ItemChargeAssgntPurch, ItemChargeAssgntPurch2."Applies-to Doc. Type"::"Transfer Receipt",
                    FromTransRcptLine."Document No.", FromTransRcptLine."Line No.",
                    FromTransRcptLine."Item No.", FromTransRcptLine.Description, NextLine);
        until FromTransRcptLine.Next() = 0;
    end;

    procedure CreateShptChargeAssgnt(var FromReturnShptLine: Record "Return Shipment Line"; ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)")
    var
        ItemChargeAssgntPurch2: Record "Item Charge Assignment (Purch)";
        NextLine: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateShptChargeAssgnt(FromReturnShptLine, ItemChargeAssgntPurch, IsHandled);
        if not IsHandled then
            FromReturnShptLine.TestField("Job No.", '');
        NextLine := ItemChargeAssgntPurch."Line No.";
        ItemChargeAssgntPurch2.SetRange("Document Type", ItemChargeAssgntPurch."Document Type");
        ItemChargeAssgntPurch2.SetRange("Document No.", ItemChargeAssgntPurch."Document No.");
        ItemChargeAssgntPurch2.SetRange("Document Line No.", ItemChargeAssgntPurch."Document Line No.");
        ItemChargeAssgntPurch2.SetRange(
          "Applies-to Doc. Type", ItemChargeAssgntPurch2."Applies-to Doc. Type"::"Return Shipment");
        repeat
            ItemChargeAssgntPurch2.SetRange("Applies-to Doc. No.", FromReturnShptLine."Document No.");
            ItemChargeAssgntPurch2.SetRange("Applies-to Doc. Line No.", FromReturnShptLine."Line No.");
            if not ItemChargeAssgntPurch2.FindFirst() then
                InsertItemChargeAssignment(
                    ItemChargeAssgntPurch, ItemChargeAssgntPurch2."Applies-to Doc. Type"::"Return Shipment",
                    FromReturnShptLine."Document No.", FromReturnShptLine."Line No.",
                    FromReturnShptLine."No.", FromReturnShptLine.Description, NextLine);
        until FromReturnShptLine.Next() = 0;
    end;

    procedure CreateSalesShptChargeAssgnt(var FromSalesShptLine: Record "Sales Shipment Line"; ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)")
    var
        ItemChargeAssgntPurch2: Record "Item Charge Assignment (Purch)";
        NextLine: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateSalesShptChargeAssgnt(FromSalesShptLine, ItemChargeAssgntPurch, IsHandled);
        if not IsHandled then
            FromSalesShptLine.TestField("Job No.", '');
        NextLine := ItemChargeAssgntPurch."Line No.";
        ItemChargeAssgntPurch2.SetRange("Document Type", ItemChargeAssgntPurch."Document Type");
        ItemChargeAssgntPurch2.SetRange("Document No.", ItemChargeAssgntPurch."Document No.");
        ItemChargeAssgntPurch2.SetRange("Document Line No.", ItemChargeAssgntPurch."Document Line No.");
        ItemChargeAssgntPurch2.SetRange(
          "Applies-to Doc. Type", ItemChargeAssgntPurch2."Applies-to Doc. Type"::"Sales Shipment");
        repeat
            IsHandled := false;
            OnCreateSalesShptChargeAssgntOnBeforeInsertItemChargeAssignment(FromSalesShptLine, ItemChargeAssgntPurch, NextLine, IsHandled);
            if not IsHandled then begin
                ItemChargeAssgntPurch2.SetRange("Applies-to Doc. No.", FromSalesShptLine."Document No.");
                ItemChargeAssgntPurch2.SetRange("Applies-to Doc. Line No.", FromSalesShptLine."Line No.");
                if not ItemChargeAssgntPurch2.FindFirst() then
                    InsertItemChargeAssignment(
                        ItemChargeAssgntPurch, ItemChargeAssgntPurch2."Applies-to Doc. Type"::"Sales Shipment",
                        FromSalesShptLine."Document No.", FromSalesShptLine."Line No.",
                        FromSalesShptLine."No.", FromSalesShptLine.Description, NextLine);
            end;
        until FromSalesShptLine.Next() = 0;
    end;

    procedure CreateReturnRcptChargeAssgnt(var FromReturnRcptLine: Record "Return Receipt Line"; ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)")
    var
        ItemChargeAssgntPurch2: Record "Item Charge Assignment (Purch)";
        NextLine: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateReturnRcptChargeAssgnt(FromReturnRcptLine, ItemChargeAssgntPurch, IsHandled);
        if not IsHandled then
            FromReturnRcptLine.TestField("Job No.", '');
        NextLine := ItemChargeAssgntPurch."Line No.";
        ItemChargeAssgntPurch2.SetRange("Document Type", ItemChargeAssgntPurch."Document Type");
        ItemChargeAssgntPurch2.SetRange("Document No.", ItemChargeAssgntPurch."Document No.");
        ItemChargeAssgntPurch2.SetRange("Document Line No.", ItemChargeAssgntPurch."Document Line No.");
        ItemChargeAssgntPurch2.SetRange(
          "Applies-to Doc. Type", ItemChargeAssgntPurch2."Applies-to Doc. Type"::"Return Receipt");
        repeat
            ItemChargeAssgntPurch2.SetRange("Applies-to Doc. No.", FromReturnRcptLine."Document No.");
            ItemChargeAssgntPurch2.SetRange("Applies-to Doc. Line No.", FromReturnRcptLine."Line No.");
            if not ItemChargeAssgntPurch2.FindFirst() then
                InsertItemChargeAssignment(
                    ItemChargeAssgntPurch, ItemChargeAssgntPurch2."Applies-to Doc. Type"::"Return Receipt",
                    FromReturnRcptLine."Document No.", FromReturnRcptLine."Line No.",
                    FromReturnRcptLine."No.", FromReturnRcptLine.Description, NextLine);
        until FromReturnRcptLine.Next() = 0;
    end;

    procedure SuggestAssgnt(PurchLine: Record "Purchase Line"; TotalQtyToAssign: Decimal; TotalAmtToAssign: Decimal)
    begin
        SuggestAssgnt(PurchLine, TotalQtyToAssign, TotalAmtToAssign, TotalQtyToAssign, TotalAmtToAssign)
    end;

    procedure SuggestAssgnt(PurchLine: Record "Purchase Line"; TotalQtyToAssign: Decimal; TotalAmtToAssign: Decimal; TotalQtyToHandle: Decimal; TotalAmtToHandle: Decimal)
    var
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        Selection: Integer;
        SelectionTxt: Text;
        SuggestItemChargeMenuTxt: Text;
        SuggestItemChargeMessageTxt: Text;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSuggestAssgnt(PurchLine, ItemChargeAssgntPurch, TotalQtyToAssign, TotalAmtToAssign, TotalQtyToHandle, TotalAmtToHandle, Selection, SelectionTxt, SuggestItemChargeMenuTxt, SuggestItemChargeMessageTxt, IsHandled);
        if IsHandled then
            exit;

        PurchLine.TestField("Qty. to Invoice");
        ItemChargeAssgntPurch.SetRange("Document Type", PurchLine."Document Type");
        ItemChargeAssgntPurch.SetRange("Document No.", PurchLine."Document No.");
        ItemChargeAssgntPurch.SetRange("Document Line No.", PurchLine."Line No.");
        if ItemChargeAssgntPurch.IsEmpty() then
            exit;

        ItemChargeAssgntPurch.SetRange("Applies-to Doc. Type", ItemChargeAssgntPurch."Applies-to Doc. Type"::"Transfer Receipt");

        IsHandled := false;
        OnSuggestAssgntOnAfterItemChargeAssgntPurchSetFilters(ItemChargeAssgntPurch, PurchLine, TotalQtyToAssign, TotalAmtToAssign, IsHandled);
        if IsHandled then
            exit;

        Selection := 1;
        if ItemChargeAssgntPurch.IsEmpty() then
            SuggestItemChargeMenuTxt :=
              StrSubstNo(ItemChargeAssignedMenu4Lbl, AssignEquallyMenuText(), AssignByAmountMenuText(), AssignByWeightMenuText(), AssignByVolumeMenuText())
        else
            SuggestItemChargeMenuTxt :=
              StrSubstNo(ItemChargeAssignedMenu3Lbl, AssignEquallyMenuText(), AssignByWeightMenuText(), AssignByVolumeMenuText());
        ItemChargeAssgntPurch.SetRange("Applies-to Doc. Type");

        if ItemChargeAssgntPurch.Count > 1 then begin
            Selection := 2;
            SuggestItemChargeMessageTxt := SuggestItemChargeMsg;
            OnBeforeShowSuggestItemChargeAssignStrMenu(PurchLine, SuggestItemChargeMenuTxt, SuggestItemChargeMessageTxt, Selection);
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
        OnSuggestAssgntOnBeforeAssignItemCharges(PurchLine, ItemChargeAssgntPurch);
        AssignItemCharges(PurchLine, TotalQtyToAssign, TotalAmtToAssign, TotalQtyToHandle, TotalAmtToHandle, SelectionTxt);
    end;

    procedure AssignItemCharges(PurchLine: Record "Purchase Line"; TotalQtyToAssign: Decimal; TotalAmtToAssign: Decimal; SelectedOptionValue: Integer)
    begin
        AssignItemCharges(PurchLine, TotalQtyToAssign, TotalAmtToAssign, GetSelectionText(SelectedOptionValue));
    end;

    local procedure GetSelectionText(OptionValue: Integer): Text
    var
        SuggestItemChargeMenuTxt: Text;
    begin
        SuggestItemChargeMenuTxt :=
            StrSubstNo(ItemChargeAssignedMenu4Lbl, AssignEquallyMenuText(), AssignByAmountMenuText(), AssignByWeightMenuText(), AssignByVolumeMenuText());
        exit(SelectStr(OptionValue + 1, SuggestItemChargeMenuTxt));
    end;

    procedure AssignItemCharges(PurchLine: Record "Purchase Line"; TotalQtyToAssign: Decimal; TotalAmtToAssign: Decimal; SelectionTxt: Text)
    begin
        AssignItemCharges(PurchLine, TotalQtyToAssign, TotalAmtToAssign, TotalQtyToAssign, TotalAmtToAssign, SelectionTxt);
    end;

    procedure AssignItemCharges(PurchLine: Record "Purchase Line"; TotalQtyToAssign: Decimal; TotalAmtToAssign: Decimal; TotalQtyToHandle: Decimal; TotalAmtToHandle: Decimal; SelectionTxt: Text)
    var
        Currency: Record Currency;
        PurchHeader: Record "Purchase Header";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        ItemChargesAssigned: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAssignItemCharges(PurchLine, TotalQtyToAssign, TotalAmtToAssign, IsHandled, TotalQtyToHandle, TotalAmtToHandle, SelectionTxt);
        if IsHandled then
            exit;

        PurchLine.TestField("Qty. to Invoice");
        PurchHeader.Get(PurchLine."Document Type", PurchLine."Document No.");
        if not Currency.Get(PurchHeader."Currency Code") then
            Currency.InitRoundingPrecision();

        ItemChargeAssgntPurch.SetRange("Document Type", PurchLine."Document Type");
        ItemChargeAssgntPurch.SetRange("Document No.", PurchLine."Document No.");
        ItemChargeAssgntPurch.SetRange("Document Line No.", PurchLine."Line No.");

        if not ItemChargeAssgntPurch.IsEmpty() then begin
            ItemChargeAssgntPurch.ModifyAll("Amount to Assign", 0);
            ItemChargeAssgntPurch.ModifyAll("Qty. to Assign", 0);
            ItemChargeAssgntPurch.ModifyAll("Amount to Handle", 0);
            ItemChargeAssgntPurch.ModifyAll("Qty. to Handle", 0);
            OnAssignItemChargesFromLineOnAfterItemChargeAssignmentModifyAll(PurchLine, ItemChargeAssgntPurch);
            ItemChargeAssgntPurch.FindSet();

            case SelectionTxt of
                AssignEquallyMenuText():
                    AssignEqually(ItemChargeAssgntPurch, Currency, TotalQtyToAssign, TotalAmtToAssign, TotalQtyToHandle, TotalAmtToHandle);
                AssignByAmountMenuText():
                    AssignByAmount(ItemChargeAssgntPurch, Currency, PurchHeader, TotalQtyToAssign, TotalAmtToAssign, TotalQtyToHandle, TotalAmtToHandle);
                AssignByWeightMenuText():
                    AssignByWeight(ItemChargeAssgntPurch, Currency, TotalQtyToAssign);
                AssignByVolumeMenuText():
                    AssignByVolume(ItemChargeAssgntPurch, Currency, TotalQtyToAssign);
                else begin
                    OnAssignItemCharges(
                      SelectionTxt, ItemChargeAssgntPurch, Currency, PurchHeader, TotalQtyToAssign, TotalAmtToAssign, ItemChargesAssigned);
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

    procedure ReverseItemChargeAssgnt(ItemChargeAssgnt: Record "Item Charge Assignment (Purch)"; CancelledQuantity: Decimal)
    begin
        if ItemChargeAssgnt."Qty. Assigned" = 0 then
            exit;

        ItemChargeAssgnt."Qty. Assigned" -= CancelledQuantity;
        ItemChargeAssgnt."Qty. to Assign" += CancelledQuantity;
        ItemChargeAssgnt.Validate("Qty. to Handle", ItemChargeAssgnt."Qty. to Assign");
        ItemChargeAssgnt.Modify();
    end;

    local procedure AssignEqually(var ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)"; Currency: Record Currency; TotalQtyToAssign: Decimal; TotalAmtToAssign: Decimal; TotalQtyToHandle: Decimal; TotalAmtToHandle: Decimal)
    var
        TempItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)" temporary;
        RemainingNumOfLines: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAssignEqually(ItemChargeAssgntPurch, Currency, TotalQtyToAssign, TotalAmtToAssign, IsHandled);
        if IsHandled then
            exit;

        repeat
            if not ItemChargeAssgntPurch.PurchLineInvoiced() then begin
                TempItemChargeAssgntPurch := ItemChargeAssgntPurch;
                TempItemChargeAssgntPurch.Insert();
            end;
        until ItemChargeAssgntPurch.Next() = 0;

        if TempItemChargeAssgntPurch.FindSet(true) then begin
            RemainingNumOfLines := TempItemChargeAssgntPurch.Count();
            repeat
                ItemChargeAssgntPurch.Get(
                  TempItemChargeAssgntPurch."Document Type",
                  TempItemChargeAssgntPurch."Document No.",
                  TempItemChargeAssgntPurch."Document Line No.",
                  TempItemChargeAssgntPurch."Line No.");
                ItemChargeAssgntPurch."Qty. to Assign" := Round(TotalQtyToAssign / RemainingNumOfLines, UOMMgt.QtyRndPrecision());
                ItemChargeAssgntPurch."Amount to Assign" :=
                  Round(
                    ItemChargeAssgntPurch."Qty. to Assign" / TotalQtyToAssign * TotalAmtToAssign,
                    Currency."Amount Rounding Precision");
                ItemChargeAssgntPurch."Qty. to Handle" := ItemChargeAssgntPurch."Qty. to Assign";
                ItemChargeAssgntPurch."Amount to Handle" := ItemChargeAssgntPurch."Amount to Assign";
                OnAssignEquallyOnAfterAmountToAssignCalculated(ItemChargeAssgntPurch);
                TotalQtyToAssign -= ItemChargeAssgntPurch."Qty. to Assign";
                TotalAmtToAssign -= ItemChargeAssgntPurch."Amount to Assign";
                TotalQtyToHandle -= ItemChargeAssgntPurch."Qty. to Handle";
                TotalAmtToHandle -= ItemChargeAssgntPurch."Amount to Handle";
                RemainingNumOfLines := RemainingNumOfLines - 1;
                OnAssignEquallyOnBeforeItemChargeAssignmentPurchModify(ItemChargeAssgntPurch);
                ItemChargeAssgntPurch.Modify();
                OnAssignEquallyOnAfterItemChargeAssignmentPurchModify(ItemChargeAssgntPurch);
            until TempItemChargeAssgntPurch.Next() = 0;
        end;
        TempItemChargeAssgntPurch.DeleteAll();
    end;

    local procedure AssignByAmount(var ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)"; Currency: Record Currency; PurchHeader: Record "Purchase Header"; TotalQtyToAssign: Decimal; TotalAmtToAssign: Decimal; TotalQtyToHandle: Decimal; TotalAmtToHandle: Decimal)
    var
        TempItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)" temporary;
        PurchLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        CurrExchRate: Record "Currency Exchange Rate";
        ReturnRcptLine: Record "Return Receipt Line";
        ReturnShptLine: Record "Return Shipment Line";
        SalesShptLine: Record "Sales Shipment Line";
        CurrencyCode: Code[10];
        TotalAppliesToDocLineAmount: Decimal;
    begin
        repeat
            if not ItemChargeAssgntPurch.PurchLineInvoiced() then begin
                TempItemChargeAssgntPurch := ItemChargeAssgntPurch;
                case ItemChargeAssgntPurch."Applies-to Doc. Type" of
                    ItemChargeAssgntPurch."Applies-to Doc. Type"::Quote,
                    ItemChargeAssgntPurch."Applies-to Doc. Type"::Order,
                    ItemChargeAssgntPurch."Applies-to Doc. Type"::Invoice,
                    ItemChargeAssgntPurch."Applies-to Doc. Type"::"Return Order",
                    ItemChargeAssgntPurch."Applies-to Doc. Type"::"Credit Memo":
                        begin
                            GetPurchLineForItemChargeAssgntPurch(PurchLine, ItemChargeAssgntPurch);
                            TempItemChargeAssgntPurch."Applies-to Doc. Line Amount" :=
                              Abs(PurchLine."Line Amount");
                        end;
                    ItemChargeAssgntPurch."Applies-to Doc. Type"::Receipt:
                        begin
                            PurchRcptLine.Get(
                              ItemChargeAssgntPurch."Applies-to Doc. No.",
                              ItemChargeAssgntPurch."Applies-to Doc. Line No.");
                            CurrencyCode := PurchRcptLine.GetCurrencyCodeFromHeader();
                            if CurrencyCode = PurchHeader."Currency Code" then
                                TempItemChargeAssgntPurch."Applies-to Doc. Line Amount" :=
                                  Abs(PurchRcptLine."Item Charge Base Amount")
                            else
                                TempItemChargeAssgntPurch."Applies-to Doc. Line Amount" :=
                                  CurrExchRate.ExchangeAmtFCYToFCY(
                                    PurchHeader."Posting Date", CurrencyCode, PurchHeader."Currency Code",
                                    Abs(PurchRcptLine."Item Charge Base Amount"));
                        end;
                    ItemChargeAssgntPurch."Applies-to Doc. Type"::"Return Shipment":
                        begin
                            ReturnShptLine.Get(
                              ItemChargeAssgntPurch."Applies-to Doc. No.",
                              ItemChargeAssgntPurch."Applies-to Doc. Line No.");
                            CurrencyCode := ReturnShptLine.GetCurrencyCode();
                            if CurrencyCode = PurchHeader."Currency Code" then
                                TempItemChargeAssgntPurch."Applies-to Doc. Line Amount" :=
                                  Abs(ReturnShptLine."Item Charge Base Amount")
                            else
                                TempItemChargeAssgntPurch."Applies-to Doc. Line Amount" :=
                                  CurrExchRate.ExchangeAmtFCYToFCY(
                                    PurchHeader."Posting Date", CurrencyCode, PurchHeader."Currency Code",
                                    Abs(ReturnShptLine."Item Charge Base Amount"));
                        end;
                    ItemChargeAssgntPurch."Applies-to Doc. Type"::"Sales Shipment":
                        begin
                            SalesShptLine.Get(
                              ItemChargeAssgntPurch."Applies-to Doc. No.",
                              ItemChargeAssgntPurch."Applies-to Doc. Line No.");
                            CurrencyCode := SalesShptLine.GetCurrencyCode();
                            if CurrencyCode = PurchHeader."Currency Code" then
                                TempItemChargeAssgntPurch."Applies-to Doc. Line Amount" :=
                                  Abs(SalesShptLine."Item Charge Base Amount")
                            else
                                TempItemChargeAssgntPurch."Applies-to Doc. Line Amount" :=
                                  CurrExchRate.ExchangeAmtFCYToFCY(
                                    PurchHeader."Posting Date", CurrencyCode, PurchHeader."Currency Code",
                                    Abs(SalesShptLine."Item Charge Base Amount"));
                        end;
                    ItemChargeAssgntPurch."Applies-to Doc. Type"::"Return Receipt":
                        begin
                            ReturnRcptLine.Get(
                              ItemChargeAssgntPurch."Applies-to Doc. No.",
                              ItemChargeAssgntPurch."Applies-to Doc. Line No.");
                            CurrencyCode := ReturnRcptLine.GetCurrencyCode();
                            if CurrencyCode = PurchHeader."Currency Code" then
                                TempItemChargeAssgntPurch."Applies-to Doc. Line Amount" :=
                                  Abs(ReturnRcptLine."Item Charge Base Amount")
                            else
                                TempItemChargeAssgntPurch."Applies-to Doc. Line Amount" :=
                                  CurrExchRate.ExchangeAmtFCYToFCY(
                                    PurchHeader."Posting Date", CurrencyCode, PurchHeader."Currency Code",
                                    Abs(ReturnRcptLine."Item Charge Base Amount"));
                        end;
                end;
                OnAssignByAmountOnAfterAssignAppliesToDocLineAmount(ItemChargeAssgntPurch, TempItemChargeAssgntPurch, PurchHeader, TotalQtyToAssign, TotalAmtToAssign);
                if TempItemChargeAssgntPurch."Applies-to Doc. Line Amount" <> 0 then
                    TempItemChargeAssgntPurch.Insert()
                else begin
                    ItemChargeAssgntPurch."Amount to Assign" := 0;
                    ItemChargeAssgntPurch."Qty. to Assign" := 0;
                    ItemChargeAssgntPurch."Amount to Handle" := 0;
                    ItemChargeAssgntPurch."Qty. to Handle" := 0;
                    ItemChargeAssgntPurch.Modify();
                end;
                TotalAppliesToDocLineAmount += TempItemChargeAssgntPurch."Applies-to Doc. Line Amount";
            end;
        until ItemChargeAssgntPurch.Next() = 0;

        if TempItemChargeAssgntPurch.FindSet(true) then
            repeat
                ItemChargeAssgntPurch.Get(
                  TempItemChargeAssgntPurch."Document Type",
                  TempItemChargeAssgntPurch."Document No.",
                  TempItemChargeAssgntPurch."Document Line No.",
                  TempItemChargeAssgntPurch."Line No.");
                if TotalQtyToAssign <> 0 then begin
                    ItemChargeAssgntPurch."Qty. to Assign" :=
                      Round(
                        TempItemChargeAssgntPurch."Applies-to Doc. Line Amount" / TotalAppliesToDocLineAmount * TotalQtyToAssign,
                        UOMMgt.QtyRndPrecision());
                    ItemChargeAssgntPurch."Amount to Assign" :=
                      Round(
                        ItemChargeAssgntPurch."Qty. to Assign" / TotalQtyToAssign * TotalAmtToAssign,
                        Currency."Amount Rounding Precision");
                    ItemChargeAssgntPurch."Qty. to Handle" := ItemChargeAssgntPurch."Qty. to Assign";
                    ItemChargeAssgntPurch."Amount to Handle" := ItemChargeAssgntPurch."Amount to Assign";
                    OnAssignByAmountOnAfterAmountToAssignCalculated(ItemChargeAssgntPurch, TempItemChargeAssgntPurch);
                    TotalQtyToAssign -= ItemChargeAssgntPurch."Qty. to Assign";
                    TotalAmtToAssign -= ItemChargeAssgntPurch."Amount to Assign";
                    TotalQtyToHandle -= ItemChargeAssgntPurch."Qty. to Handle";
                    TotalAmtToHandle -= ItemChargeAssgntPurch."Amount to Handle";
                    TotalAppliesToDocLineAmount -= TempItemChargeAssgntPurch."Applies-to Doc. Line Amount";
                    OnAssignByAmountOnBeforeItemChargeAssignmentPurchModify(ItemChargeAssgntPurch);
                    ItemChargeAssgntPurch.Modify();
                    OnAssignByAmountOnAfterItemChargeAssignmentPurchModify(ItemChargeAssgntPurch);
                end;
            until TempItemChargeAssgntPurch.Next() = 0;
        TempItemChargeAssgntPurch.DeleteAll();
    end;

    local procedure GetPurchLineForItemChargeAssgntPurch(var PurchaseLine: Record "Purchase Line"; var ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetPurchLineForItemChargeAssgntPurch(PurchaseLine, ItemChargeAssgntPurch, IsHandled);
        if IsHandled then
            exit;

        PurchaseLine.Get(ItemChargeAssgntPurch."Applies-to Doc. Type", ItemChargeAssgntPurch."Applies-to Doc. No.", ItemChargeAssgntPurch."Applies-to Doc. Line No.");
    end;

    local procedure AssignByWeight(var ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)"; Currency: Record Currency; TotalQtyToAssign: Decimal)
    var
        TempItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)" temporary;
        LineAray: array[3] of Decimal;
        TotalGrossWeight: Decimal;
        QtyRemainder: Decimal;
        AmountRemainder: Decimal;
    begin
        repeat
            if not ItemChargeAssgntPurch.PurchLineInvoiced() then begin
                TempItemChargeAssgntPurch.Init();
                TempItemChargeAssgntPurch := ItemChargeAssgntPurch;
                TempItemChargeAssgntPurch.Insert();
                GetItemValues(TempItemChargeAssgntPurch, LineAray);
                TotalGrossWeight := TotalGrossWeight + (LineAray[2] * LineAray[1]);
            end;
        until ItemChargeAssgntPurch.Next() = 0;
        OnAssignByWeightOnAfterCalcTotalGrossWeight(ItemChargeAssgntPurch, TotalGrossWeight, TempItemChargeAssgntPurch);

        QtyRemainder := 0;
        AmountRemainder := 0;
        if TempItemChargeAssgntPurch.FindSet(true) then
            repeat
                GetItemValues(TempItemChargeAssgntPurch, LineAray);
                if TotalGrossWeight <> 0 then
                    TempItemChargeAssgntPurch."Qty. to Assign" :=
                      (TotalQtyToAssign * LineAray[2] * LineAray[1]) / TotalGrossWeight + QtyRemainder
                else
                    TempItemChargeAssgntPurch."Qty. to Assign" := 0;
                TempItemChargeAssgntPurch."Qty. to Handle" := TempItemChargeAssgntPurch."Qty. to Assign";
                AssignPurchItemCharge(ItemChargeAssgntPurch, TempItemChargeAssgntPurch, Currency, QtyRemainder, AmountRemainder);
            until TempItemChargeAssgntPurch.Next() = 0;
        OnAssignByWeightOnBeforeTempItemChargeAssgntPurchDelete(ItemChargeAssgntPurch, QtyRemainder, TotalQtyToAssign, Currency);
        TempItemChargeAssgntPurch.DeleteAll();
    end;

    local procedure AssignByVolume(var ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)"; Currency: Record Currency; TotalQtyToAssign: Decimal)
    var
        TempItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)" temporary;
        LineAray: array[3] of Decimal;
        TotalUnitVolume: Decimal;
        QtyRemainder: Decimal;
        AmountRemainder: Decimal;
    begin
        repeat
            if not ItemChargeAssgntPurch.PurchLineInvoiced() then begin
                TempItemChargeAssgntPurch.Init();
                TempItemChargeAssgntPurch := ItemChargeAssgntPurch;
                TempItemChargeAssgntPurch.Insert();
                GetItemValues(TempItemChargeAssgntPurch, LineAray);
                TotalUnitVolume := TotalUnitVolume + (LineAray[3] * LineAray[1]);
            end;
        until ItemChargeAssgntPurch.Next() = 0;
        OnAssignByVolumeOnAfterCalcTotalUnitVolume(ItemChargeAssgntPurch, TotalUnitVolume, TempItemChargeAssgntPurch);

        QtyRemainder := 0;
        if TempItemChargeAssgntPurch.FindSet(true) then
            repeat
                GetItemValues(TempItemChargeAssgntPurch, LineAray);
                if TotalUnitVolume <> 0 then
                    TempItemChargeAssgntPurch."Qty. to Assign" :=
                      (TotalQtyToAssign * LineAray[3] * LineAray[1]) / TotalUnitVolume + QtyRemainder
                else
                    TempItemChargeAssgntPurch."Qty. to Assign" := 0;
                TempItemChargeAssgntPurch."Qty. to Handle" := TempItemChargeAssgntPurch."Qty. to Assign";
                AssignPurchItemCharge(ItemChargeAssgntPurch, TempItemChargeAssgntPurch, Currency, QtyRemainder, AmountRemainder);
            until TempItemChargeAssgntPurch.Next() = 0;
        TempItemChargeAssgntPurch.DeleteAll();
    end;

    procedure AssignPurchItemCharge(var ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)"; ItemChargeAssgntPurch2: Record "Item Charge Assignment (Purch)"; Currency: Record Currency; var QtyRemainder: Decimal; var AmountRemainder: Decimal)
    begin
        ItemChargeAssgntPurch.Get(
          ItemChargeAssgntPurch2."Document Type",
          ItemChargeAssgntPurch2."Document No.",
          ItemChargeAssgntPurch2."Document Line No.",
          ItemChargeAssgntPurch2."Line No.");
        ItemChargeAssgntPurch."Qty. to Assign" := Round(ItemChargeAssgntPurch2."Qty. to Assign", UOMMgt.QtyRndPrecision());
        ItemChargeAssgntPurch."Amount to Assign" :=
          ItemChargeAssgntPurch."Qty. to Assign" * ItemChargeAssgntPurch."Unit Cost" + AmountRemainder;
        AmountRemainder := ItemChargeAssgntPurch."Amount to Assign" -
          Round(ItemChargeAssgntPurch."Amount to Assign", Currency."Amount Rounding Precision");
        QtyRemainder := ItemChargeAssgntPurch2."Qty. to Assign" - ItemChargeAssgntPurch."Qty. to Assign";
        ItemChargeAssgntPurch."Amount to Assign" :=
          Round(ItemChargeAssgntPurch."Amount to Assign", Currency."Amount Rounding Precision");
        ItemChargeAssgntPurch."Qty. to Handle" := ItemChargeAssgntPurch."Qty. to Assign";
        ItemChargeAssgntPurch."Amount to Handle" := ItemChargeAssgntPurch."Amount to Assign";
        OnAssignPurchItemChargeOnBeforeItemChargeAssignmentPurchModify(ItemChargeAssgntPurch);
        ItemChargeAssgntPurch.Modify();
    end;

    procedure GetItemValues(TempItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)" temporary; var DecimalArray: array[3] of Decimal)
    var
        PurchLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ReturnShptLine: Record "Return Shipment Line";
        TransferRcptLine: Record "Transfer Receipt Line";
        SalesShptLine: Record "Sales Shipment Line";
        ReturnRcptLine: Record "Return Receipt Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetItemValues(TempItemChargeAssgntPurch, DecimalArray, IsHandled);
        if not IsHandled then begin

            Clear(DecimalArray);
            case TempItemChargeAssgntPurch."Applies-to Doc. Type" of
                TempItemChargeAssgntPurch."Applies-to Doc. Type"::Quote,
                TempItemChargeAssgntPurch."Applies-to Doc. Type"::Order,
                TempItemChargeAssgntPurch."Applies-to Doc. Type"::Invoice,
                TempItemChargeAssgntPurch."Applies-to Doc. Type"::"Return Order",
                TempItemChargeAssgntPurch."Applies-to Doc. Type"::"Credit Memo":
                    begin
                        PurchLine.Get(TempItemChargeAssgntPurch."Applies-to Doc. Type", TempItemChargeAssgntPurch."Applies-to Doc. No.", TempItemChargeAssgntPurch."Applies-to Doc. Line No.");
                        DecimalArray[1] := PurchLine.Quantity;
                        DecimalArray[2] := PurchLine."Gross Weight";
                        DecimalArray[3] := PurchLine."Unit Volume";
                        OnGetItemValuesOnAfterGetPurchLine(PurchLine, TempItemChargeAssgntPurch, DecimalArray);
                    end;
                TempItemChargeAssgntPurch."Applies-to Doc. Type"::Receipt:
                    begin
                        PurchRcptLine.Get(TempItemChargeAssgntPurch."Applies-to Doc. No.", TempItemChargeAssgntPurch."Applies-to Doc. Line No.");
                        DecimalArray[1] := PurchRcptLine.Quantity;
                        DecimalArray[2] := PurchRcptLine."Gross Weight";
                        DecimalArray[3] := PurchRcptLine."Unit Volume";
                        OnGetItemValuesOnAfterGetPurchRcptLine(PurchRcptLine, TempItemChargeAssgntPurch, DecimalArray);
                    end;
                TempItemChargeAssgntPurch."Applies-to Doc. Type"::"Return Receipt":
                    begin
                        ReturnRcptLine.Get(TempItemChargeAssgntPurch."Applies-to Doc. No.", TempItemChargeAssgntPurch."Applies-to Doc. Line No.");
                        DecimalArray[1] := ReturnRcptLine.Quantity;
                        DecimalArray[2] := ReturnRcptLine."Gross Weight";
                        DecimalArray[3] := ReturnRcptLine."Unit Volume";
                        OnGetItemValuesOnAfterGetReturnRcptLine(ReturnRcptLine, TempItemChargeAssgntPurch, DecimalArray);
                    end;
                TempItemChargeAssgntPurch."Applies-to Doc. Type"::"Return Shipment":
                    begin
                        ReturnShptLine.Get(TempItemChargeAssgntPurch."Applies-to Doc. No.", TempItemChargeAssgntPurch."Applies-to Doc. Line No.");
                        DecimalArray[1] := ReturnShptLine.Quantity;
                        DecimalArray[2] := ReturnShptLine."Gross Weight";
                        DecimalArray[3] := ReturnShptLine."Unit Volume";
                        OnGetItemValuesOnAfterGetReturnShptLine(ReturnShptLine, TempItemChargeAssgntPurch, DecimalArray);
                    end;
                TempItemChargeAssgntPurch."Applies-to Doc. Type"::"Transfer Receipt":
                    begin
                        TransferRcptLine.Get(TempItemChargeAssgntPurch."Applies-to Doc. No.", TempItemChargeAssgntPurch."Applies-to Doc. Line No.");
                        DecimalArray[1] := TransferRcptLine.Quantity;
                        DecimalArray[2] := TransferRcptLine."Gross Weight";
                        DecimalArray[3] := TransferRcptLine."Unit Volume";
                        OnGetItemValuesOnAfterGetTransferRcptLine(TransferRcptLine, TempItemChargeAssgntPurch, DecimalArray);
                    end;
                TempItemChargeAssgntPurch."Applies-to Doc. Type"::"Sales Shipment":
                    begin
                        SalesShptLine.Get(TempItemChargeAssgntPurch."Applies-to Doc. No.", TempItemChargeAssgntPurch."Applies-to Doc. Line No.");
                        DecimalArray[1] := SalesShptLine.Quantity;
                        DecimalArray[2] := SalesShptLine."Gross Weight";
                        DecimalArray[3] := SalesShptLine."Unit Volume";
                        OnGetItemValuesOnAfterGetSalesShptLine(SalesShptLine, TempItemChargeAssgntPurch, DecimalArray);
                    end;
            end;
        end;

        OnAfterGetItemValues(TempItemChargeAssgntPurch, DecimalArray);
    end;

    procedure SuggestAssgntFromLine(var FromItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)")
    var
        Currency: Record Currency;
        PurchHeader: Record "Purchase Header";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        TempItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)" temporary;
        TotalAmountToAssign: Decimal;
        TotalQtyToAssign: Decimal;
        TotalAmountToHandle: Decimal;
        TotalQtyToHandle: Decimal;
        ItemChargeAssgntLineAmt: Decimal;
        ItemChargeAssgntLineQty: Decimal;
    begin
        PurchHeader.Get(FromItemChargeAssignmentPurch."Document Type", FromItemChargeAssignmentPurch."Document No.");
        if not Currency.Get(PurchHeader."Currency Code") then
            Currency.InitRoundingPrecision();

        GetItemChargeAssgntLineAmounts(
          FromItemChargeAssignmentPurch."Document Type", FromItemChargeAssignmentPurch."Document No.", FromItemChargeAssignmentPurch."Document Line No.",
          ItemChargeAssgntLineQty, ItemChargeAssgntLineAmt);

        if not ItemChargeAssignmentPurch.Get(FromItemChargeAssignmentPurch."Document Type", FromItemChargeAssignmentPurch."Document No.", FromItemChargeAssignmentPurch."Document Line No.", FromItemChargeAssignmentPurch."Line No.") then
            exit;

        ItemChargeAssignmentPurch."Qty. to Assign" := FromItemChargeAssignmentPurch."Qty. to Assign";
        ItemChargeAssignmentPurch."Amount to Assign" := FromItemChargeAssignmentPurch."Amount to Assign";
        ItemChargeAssignmentPurch."Qty. to Handle" := FromItemChargeAssignmentPurch."Qty. to Handle";
        ItemChargeAssignmentPurch."Amount to Handle" := FromItemChargeAssignmentPurch."Amount to Handle";
        OnSuggestAssgntFromLineOnBeforeItemChargeAssignmentPurchModify(ItemChargeAssignmentPurch);
        ItemChargeAssignmentPurch.Modify();

        ItemChargeAssignmentPurch.SetRange("Document Type", FromItemChargeAssignmentPurch."Document Type");
        ItemChargeAssignmentPurch.SetRange("Document No.", FromItemChargeAssignmentPurch."Document No.");
        ItemChargeAssignmentPurch.SetRange("Document Line No.", FromItemChargeAssignmentPurch."Document Line No.");
        ItemChargeAssignmentPurch.CalcSums("Qty. to Assign", "Amount to Assign", "Qty. to Handle", "Amount to Handle");
        TotalQtyToAssign := ItemChargeAssignmentPurch."Qty. to Assign";
        TotalAmountToAssign := ItemChargeAssignmentPurch."Amount to Assign";
        TotalQtyToHandle := ItemChargeAssignmentPurch."Qty. to Handle";
        TotalAmountToHandle := ItemChargeAssignmentPurch."Amount to Handle";

        if TotalAmountToAssign = ItemChargeAssgntLineAmt then begin
            FromItemChargeAssignmentPurch.Find();
            exit;
        end;

        if TotalQtyToAssign = ItemChargeAssgntLineQty then begin
            TotalAmountToAssign := ItemChargeAssgntLineAmt;
            TotalAmountToHandle := ItemChargeAssgntLineAmt;
            ItemChargeAssignmentPurch.FindSet();
            repeat
                if not ItemChargeAssignmentPurch.PurchLineInvoiced() then begin
                    TempItemChargeAssgntPurch := ItemChargeAssignmentPurch;
                    TempItemChargeAssgntPurch.Insert();
                end;
            until ItemChargeAssignmentPurch.Next() = 0;

            if TempItemChargeAssgntPurch.FindSet() then
                repeat
                    ItemChargeAssignmentPurch.Get(
                      TempItemChargeAssgntPurch."Document Type",
                      TempItemChargeAssgntPurch."Document No.",
                      TempItemChargeAssgntPurch."Document Line No.",
                      TempItemChargeAssgntPurch."Line No.");
                    if TotalQtyToAssign <> 0 then begin
                        ItemChargeAssignmentPurch."Amount to Assign" :=
                          Round(
                            ItemChargeAssignmentPurch."Qty. to Assign" / TotalQtyToAssign * TotalAmountToAssign,
                            Currency."Amount Rounding Precision");
                        if TotalQtyToHandle <> 0 then
                            ItemChargeAssignmentPurch."Amount to Handle" :=
                              Round(
                                ItemChargeAssignmentPurch."Qty. to Handle" / TotalQtyToHandle * TotalAmountToHandle,
                                Currency."Amount Rounding Precision");
                        TotalQtyToAssign -= ItemChargeAssignmentPurch."Qty. to Assign";
                        TotalAmountToAssign -= ItemChargeAssignmentPurch."Amount to Assign";
                        TotalQtyToHandle -= ItemChargeAssignmentPurch."Qty. to Handle";
                        TotalAmountToHandle -= ItemChargeAssignmentPurch."Amount to Handle";
                        ItemChargeAssignmentPurch.Modify();
                    end;
                until TempItemChargeAssgntPurch.Next() = 0;
        end;

        ItemChargeAssignmentPurch.Get(FromItemChargeAssignmentPurch."Document Type", FromItemChargeAssignmentPurch."Document No.", FromItemChargeAssignmentPurch."Document Line No.", FromItemChargeAssignmentPurch."Line No.");

        FromItemChargeAssignmentPurch := ItemChargeAssignmentPurch;
    end;

    local procedure GetItemChargeAssgntLineAmounts(DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20]; DocumentLineNo: Integer; var ItemChargeAssgntLineQty: Decimal; var ItemChargeAssgntLineAmt: Decimal)
    var
        PurchLine: Record "Purchase Line";
        PurchHeader: Record "Purchase Header";
        Currency: Record Currency;
    begin
        PurchHeader.Get(DocumentType, DocumentNo);
        if not Currency.Get(PurchHeader."Currency Code") then
            Currency.InitRoundingPrecision();

        PurchLine.Get(DocumentType, DocumentNo, DocumentLineNo);
        PurchLine.TestField(Type, PurchLine.Type::"Charge (Item)");
        PurchLine.TestField("No.");
        PurchLine.TestField(Quantity);

        if (PurchLine."Inv. Discount Amount" = 0) and
           (PurchLine."Line Discount Amount" = 0) and
           (not PurchHeader."Prices Including VAT")
        then
            ItemChargeAssgntLineAmt := PurchLine."Line Amount"
        else
            if PurchHeader."Prices Including VAT" then
                ItemChargeAssgntLineAmt :=
                  Round((PurchLine."Line Amount" - PurchLine."Inv. Discount Amount") / (1 + PurchLine."VAT %" / 100),
                    Currency."Amount Rounding Precision")
            else
                ItemChargeAssgntLineAmt := PurchLine."Line Amount" - PurchLine."Inv. Discount Amount";

        ItemChargeAssgntLineAmt :=
          Round(
            ItemChargeAssgntLineAmt * (PurchLine."Qty. to Invoice" / PurchLine.Quantity),
            Currency."Amount Rounding Precision");
        ItemChargeAssgntLineQty := PurchLine."Qty. to Invoice";
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDocChargeAssgnt(var LastItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)"; var ReceiptNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetItemValues(var TempItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)" temporary; var DecimalArray: array[3] of Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAssignByWeightOnAfterCalcTotalGrossWeight(var ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)"; TotalGrossWeight: Decimal; var TempItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAssignByVolumeOnAfterCalcTotalUnitVolume(var ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)"; TotalUnitVolume: Decimal; var TempItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAssignByWeightOnBeforeTempItemChargeAssgntPurchDelete(var ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)"; QtyRemainder: Decimal; QtyToAssign: Decimal; Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateDocChargeAssgntOnAfterFromPurchLineSetFilters(var LastItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)"; var FromPurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAssignItemCharges(var PurchaseLine: Record "Purchase Line"; TotalQtyToAssign: Decimal; TotalAmtToAssign: Decimal; var IsHandled: Boolean; TotalQtyToHandle: Decimal; TotalAmtToHandle: Decimal; SelectionTxt: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAssignEqually(var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"; Currency: Record Currency; TotalQtyToAssign: Decimal; TotalAmtToAssign: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateDocChargeAssgn(var LastItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)"; var FromPurchLine: Record "Purchase Line"; ReceiptNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateRcptChargeAssgnt(var FromPurchRcptLine: Record "Purch. Rcpt. Line"; ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateShptChargeAssgnt(var FromReturnShptLine: Record "Return Shipment Line"; ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateSalesShptChargeAssgnt(var FromSalesShptLine: Record "Sales Shipment Line"; ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateReturnRcptChargeAssgnt(var FromReturnRcptLine: Record "Return Receipt Line"; ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetItemValues(var TempItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)" temporary; var DecimalArray: array[3] of Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertItemChargeAssgntWithAssignValues(var ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)"; FromItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowSuggestItemChargeAssignStrMenu(PurchLine: Record "Purchase Line"; var SuggestItemChargeMenuTxt: Text; var SuggestItemChargeMessageTxt: Text; var Selection: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetPurchLineForItemChargeAssgntPurch(var PurchaseLine: Record "Purchase Line"; var ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAssignItemCharges(SelectionTxt: Text; var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"; Currency: Record Currency; PurchaseHeader: Record "Purchase Header"; TotalQtyToAssign: Decimal; TotalAmtToAssign: Decimal; var ItemChargesAssigned: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAssignEquallyOnAfterAmountToAssignCalculated(var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAssignEquallyOnAfterItemChargeAssignmentPurchModify(var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAssignEquallyOnBeforeItemChargeAssignmentPurchModify(var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAssignByAmountOnAfterAmountToAssignCalculated(var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"; TempItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAssignByAmountOnAfterItemChargeAssignmentPurchModify(var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAssignByAmountOnBeforeItemChargeAssignmentPurchModify(var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSuggestAssgntOnAfterItemChargeAssgntPurchSetFilters(var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"; PurchLine: Record "Purchase Line"; TotalQtyToAssign: Decimal; TotalAmtToAssign: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSuggestAssgntOnBeforeAssignItemCharges(var PurchaseLine: Record "Purchase Line"; ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAssignByAmountOnAfterAssignAppliesToDocLineAmount(ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"; var TempItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)" temporary; PurchHeader: Record "Purchase Header"; TotalQtyToAssign: Decimal; TotalAmtToAssign: Decimal);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesShptChargeAssgntOnBeforeInsertItemChargeAssignment(var FromSalesShipmentLine: Record "Sales Shipment Line"; ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"; NextLine: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetItemValuesOnAfterGetPurchLine(PurchaseLine: Record "Purchase Line"; TempItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)" temporary; var DecimalArray: array[3] of Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetItemValuesOnAfterGetPurchRcptLine(PurchRcptLine: Record "Purch. Rcpt. Line"; TempItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)" temporary; var DecimalArray: array[3] of Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetItemValuesOnAfterGetReturnRcptLine(ReturnReceiptLine: Record "Return Receipt Line"; TempItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)" temporary; var DecimalArray: array[3] of Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetItemValuesOnAfterGetReturnShptLine(ReturnShipmentLine: Record "Return Shipment Line"; TempItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)" temporary; var DecimalArray: array[3] of Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetItemValuesOnAfterGetTransferRcptLine(TransferReceiptLine: Record "Transfer Receipt Line"; TempItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)" temporary; var DecimalArray: array[3] of Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetItemValuesOnAfterGetSalesShptLine(SalesShipmentLine: Record "Sales Shipment Line"; TempItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)" temporary; var DecimalArray: array[3] of Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckFromPurchRcptLineWorkCenter(FromPurchRcptLine: Record "Purch. Rcpt. Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeSuggestAssgnt(var PurchaseLine: Record "Purchase Line"; var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"; TotalQtyToAssign: Decimal; TotalAmtToAssign: Decimal; TotalQtyToHandle: Decimal; TotalAmtToHandle: Decimal; var Selection: Integer; var SelectionTxt: Text; var SuggestItemChargeMenuTxt: Text; var SuggestItemChargeMessageTxt: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAssignPurchItemChargeOnBeforeItemChargeAssignmentPurchModify(var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSuggestAssgntFromLineOnBeforeItemChargeAssignmentPurchModify(var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAssignItemChargesFromLineOnAfterItemChargeAssignmentModifyAll(PurchLine: Record "Purchase Line"; var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertItemChargeAssignmentWithValuesTo(var FromItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)"; var ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)"; var ApplToDocType: Enum "Purchase Applies-to Document Type"; var FromApplToDocNo: Code[20]; var FromApplToDocLineNo: Integer; var FromItemNo: Code[20]; var FromDescription: Text[100]; var NextLineNo: Integer; var QtyToAssign: Decimal; var AmountToAssign: Decimal; var IsHandled: Boolean)
    begin
    end;
}

