// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Document;

using Microsoft.Foundation.ExtendedText;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.History;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Tracking;

codeunit 5857 "Copy Invt. Document Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        ItemCheckAvail: Codeunit "Item-Check Avail.";
        TransferOldExtLines: Codeunit "Transfer Old Ext. Text Lines";
        ItemTrackingManagement: Codeunit "Item Tracking Management";
        InvtDocType: Enum "Invt. Doc. Document Type From";
        GlobalFromDocType: Enum "Invt. Doc. Document Type From";
        IncludeHeader: Boolean;
        RecalculateLines: Boolean;
        CreateToHeader: Boolean;
        HideDialog: Boolean;
        IsCorrection: Boolean;
        CopyItemTracking: Boolean;
        FillAppliesFields: Boolean;
        MissingDocumentNoErr: Label 'Please enter a Document No.';
        CannotCopyToItselfErr: Label '%1 %2 cannot be copied onto itself.', Comment = '%1 = document type, %2 = document number';
        LinesWillBeDeletedQst: Label 'The existing lines for %1 %2 will be deleted.\\Do you want to continue?', Comment = '%1 = document type, %2 = document number';
        LinesNotCopiedMsg: Label 'The document line(s) with a G/L account where direct posting is not allowed have not been copied to the new document by the Copy Document batch job.';
        LinesNotAppliedMsg: Label 'There is %1 document line(s) with Item Tracking which requires manual specify of apply to/from numbers within Item Tracking Lines', Comment = '%1-line count';

    procedure SetProperties(NewIncludeHeader: Boolean; NewRecalculateLines: Boolean; NewCreateToHeader: Boolean; NewHideDialog: Boolean; NewFillAppliesFields: Boolean)
    begin
        IncludeHeader := NewIncludeHeader;
        RecalculateLines := NewRecalculateLines;
        CreateToHeader := NewCreateToHeader;
        HideDialog := NewHideDialog;
        FillAppliesFields := NewFillAppliesFields;
    end;

    procedure SetCopyItemTracking(NewCopyItemTracking: Boolean)
    begin
        CopyItemTracking := NewCopyItemTracking;
    end;

    procedure CopyAsCorrection(NewIsCorrection: Boolean)
    begin
        IsCorrection := NewIsCorrection;
    end;

    procedure CopyItemDoc(FromDocType: Enum "Invt. Doc. Document Type From"; FromDocNo: Code[20]; var ToInvtDocHeader: Record "Invt. Document Header")
    var
        ToInvtDocLine: Record "Invt. Document Line";
        OldInvtDocHeader: Record "Invt. Document Header";
        FromInvtDocHeader: Record "Invt. Document Header";
        FromInvtDocLine: Record "Invt. Document Line";
        FromInvtRcptHeader: Record "Invt. Receipt Header";
        FromInvtRcptLine: Record "Invt. Receipt Line";
        FromInvtShptHeader: Record "Invt. Shipment Header";
        FromInvtShptLine: Record "Invt. Shipment Line";
        NextLineNo: Integer;
        LinesNotCopied: Integer;
        LinesSkipApplies: Integer;
    begin
        if not CreateToHeader then begin
            ToInvtDocHeader.TestField(Status, ToInvtDocHeader.Status::Open);
            if FromDocNo = '' then
                Error(MissingDocumentNoErr);
            ToInvtDocHeader.Find();
        end;
        TransferOldExtLines.ClearLineNumbers();
        GlobalFromDocType := FromDocType;
        case FromDocType of
            InvtDocType::Receipt,
            InvtDocType::Shipment:
                begin
                    FromInvtDocHeader.Get(FromDocType, FromDocNo);
                    if (FromInvtDocHeader."Document Type" = ToInvtDocHeader."Document Type") and
                       (FromInvtDocHeader."No." = ToInvtDocHeader."No.")
                    then
                        Error(CannotCopyToItselfErr, ToInvtDocHeader."Document Type", ToInvtDocHeader."No.");

                    FromInvtDocLine.SetRange("Document Type", FromInvtDocHeader."Document Type");
                    FromInvtDocLine.SetRange("Document No.", FromInvtDocHeader."No.");
                    if FromInvtDocLine.Find('-') then
                        repeat
                            if FromInvtDocLine.Quantity > 0 then begin
                                ToInvtDocLine."Item No." := FromInvtDocLine."Item No.";
                                ToInvtDocLine."Variant Code" := FromInvtDocLine."Variant Code";
                                ToInvtDocLine."Location Code" := FromInvtDocLine."Location Code";
                                ToInvtDocLine."Bin Code" := FromInvtDocLine."Bin Code";
                                ToInvtDocLine."Unit of Measure Code" := FromInvtDocLine."Unit of Measure Code";
                                ToInvtDocLine."Qty. per Unit of Measure" := FromInvtDocLine."Qty. per Unit of Measure";
                                ToInvtDocLine."Qty. Rounding Precision" := FromInvtDocLine."Qty. Rounding Precision";
                                ToInvtDocLine."Qty. Rounding Precision (Base)" := FromInvtDocLine."Qty. Rounding Precision (Base)";
                                ToInvtDocLine.Quantity := FromInvtDocLine.Quantity;
                                CheckItemAvailable(ToInvtDocHeader, ToInvtDocLine);
                            end;
                        until FromInvtDocLine.Next() = 0;
                    if not IncludeHeader and not RecalculateLines then
                        FromInvtDocHeader.TestField("Gen. Bus. Posting Group", ToInvtDocHeader."Gen. Bus. Posting Group");
                end;
            InvtDocType::"Posted Receipt":
                begin
                    FromInvtRcptHeader.Get(FromDocNo);
                    FromInvtRcptLine.SetRange("Document No.", FromInvtRcptHeader."No.");
                    if FromInvtRcptLine.Find('-') then
                        repeat
                            if FromInvtRcptLine.Quantity > 0 then begin
                                ToInvtDocLine."Item No." := FromInvtRcptLine."Item No.";
                                ToInvtDocLine."Variant Code" := FromInvtRcptLine."Variant Code";
                                ToInvtDocLine."Location Code" := FromInvtRcptLine."Location Code";
                                ToInvtDocLine."Bin Code" := FromInvtRcptLine."Bin Code";
                                ToInvtDocLine."Unit of Measure Code" := FromInvtRcptLine."Unit of Measure Code";
                                ToInvtDocLine."Qty. per Unit of Measure" := FromInvtRcptLine."Qty. per Unit of Measure";
                                ToInvtDocLine."Qty. Rounding Precision" := FromInvtRcptLine."Qty. Rounding Precision";
                                ToInvtDocLine."Qty. Rounding Precision (Base)" := FromInvtRcptLine."Qty. Rounding Precision (Base)";
                                ToInvtDocLine.Quantity := FromInvtRcptLine.Quantity;
                                CheckItemAvailable(ToInvtDocHeader, ToInvtDocLine);
                            end;
                        until FromInvtRcptLine.Next() = 0;
                    if not IncludeHeader and not RecalculateLines then
                        FromInvtRcptHeader.TestField("Gen. Bus. Posting Group", ToInvtDocHeader."Gen. Bus. Posting Group");
                end;
            InvtDocType::"Posted Shipment":
                begin
                    FromInvtShptHeader.Get(FromDocNo);
                    FromInvtShptLine.SetRange("Document No.", FromInvtShptHeader."No.");
                    if FromInvtShptLine.Find('-') then
                        repeat
                            if FromInvtShptLine.Quantity > 0 then begin
                                ToInvtDocLine."Item No." := FromInvtShptLine."Item No.";
                                ToInvtDocLine."Variant Code" := FromInvtShptLine."Variant Code";
                                ToInvtDocLine."Location Code" := FromInvtShptLine."Location Code";
                                ToInvtDocLine."Bin Code" := FromInvtShptLine."Bin Code";
                                ToInvtDocLine."Unit of Measure Code" := FromInvtShptLine."Unit of Measure Code";
                                ToInvtDocLine."Qty. per Unit of Measure" := FromInvtShptLine."Qty. per Unit of Measure";
                                ToInvtDocLine."Qty. Rounding Precision" := FromInvtShptLine."Qty. Rounding Precision";
                                ToInvtDocLine."Qty. Rounding Precision (Base)" := FromInvtShptLine."Qty. Rounding Precision (Base)";
                                ToInvtDocLine.Quantity := FromInvtShptLine.Quantity;
                                CheckItemAvailable(ToInvtDocHeader, ToInvtDocLine);
                            end;
                        until FromInvtShptLine.Next() = 0;
                    if not IncludeHeader and not RecalculateLines then
                        FromInvtShptHeader.TestField("Gen. Bus. Posting Group", ToInvtDocHeader."Gen. Bus. Posting Group");
                end;
        end;

        ToInvtDocLine.LockTable();

        if CreateToHeader then begin
            ToInvtDocHeader.Insert(true);
            ToInvtDocLine.SetRange("Document Type", ToInvtDocHeader."Document Type");
            ToInvtDocLine.SetRange("Document No.", ToInvtDocHeader."No.");
        end else begin
            ToInvtDocLine.SetRange("Document Type", ToInvtDocHeader."Document Type");
            ToInvtDocLine.SetRange("Document No.", ToInvtDocHeader."No.");
            if IncludeHeader then
                if ToInvtDocLine.FindFirst() then begin
                    Commit();
                    if not Confirm(LinesWillBeDeletedQst, true, ToInvtDocHeader."Document Type", ToInvtDocHeader."No.") then
                        exit;
                    ToInvtDocLine.DeleteAll(true);
                end;
        end;

        if ToInvtDocLine.FindLast() then
            NextLineNo := ToInvtDocLine."Line No."
        else
            NextLineNo := 0;

        if IncludeHeader then begin
            OldInvtDocHeader := ToInvtDocHeader;
            case FromDocType of
                InvtDocType::Receipt,
                InvtDocType::Shipment:
                    begin
                        ToInvtDocHeader.TransferFields(FromInvtDocHeader, false);
                        if OldInvtDocHeader."Posting Date" = 0D then
                            ToInvtDocHeader."Posting Date" := WorkDate()
                        else
                            ToInvtDocHeader."Posting Date" := OldInvtDocHeader."Posting Date";
                    end;
                InvtDocType::"Posted Receipt":
                    ToInvtDocHeader.TransferFields(FromInvtRcptHeader, false);
                InvtDocType::"Posted Shipment":
                    ToInvtDocHeader.TransferFields(FromInvtShptHeader, false);
            end;
            ToInvtDocHeader.Status := ToInvtDocHeader.Status::Open;
            ToInvtDocHeader."No. Series" := OldInvtDocHeader."No. Series";
            ToInvtDocHeader."Posting Description" := OldInvtDocHeader."Posting Description";
            ToInvtDocHeader."Posting No." := OldInvtDocHeader."Posting No.";
            ToInvtDocHeader."Posting No. Series" := OldInvtDocHeader."Posting No. Series";
            ToInvtDocHeader."No. Printed" := 0;
            if IsCorrection then
                ToInvtDocHeader.Correction := IsCorrection;

            if CreateToHeader then
                ToInvtDocHeader.Modify(true)
            else
                ToInvtDocHeader.Modify();
        end;

        LinesNotCopied := 0;
        LinesSkipApplies := 0;
        case FromDocType of
            InvtDocType::Receipt,
            InvtDocType::Shipment:
                begin
                    FromInvtDocLine.Reset();
                    FromInvtDocLine.SetRange("Document Type", FromInvtDocHeader."Document Type");
                    FromInvtDocLine.SetRange("Document No.", FromInvtDocHeader."No.");
                    OnCopyItemDocOnBeforeLoopFromInventoryDocumentLine(FromInvtDocLine);
                    if FromInvtDocLine.Find('-') then
                        repeat
                            CopyInvtDocLine(ToInvtDocHeader, ToInvtDocLine, FromInvtDocHeader, FromInvtDocLine, NextLineNo, LinesNotCopied, LinesSkipApplies);
                        until FromInvtDocLine.Next() = 0;
                end;
            InvtDocType::"Posted Receipt":
                begin
                    FromInvtDocHeader.TransferFields(FromInvtRcptHeader);
                    FromInvtRcptLine.Reset();
                    FromInvtRcptLine.SetRange("Document No.", FromInvtRcptHeader."No.");
                    OnCopyItemDocOnBeforeLoopFromInventoryReceiptLine(FromInvtRcptLine);
                    if FromInvtRcptLine.Find('-') then
                        repeat
                            FromInvtDocLine.TransferFields(FromInvtRcptLine);
                            CopyInvtDocLine(
                              ToInvtDocHeader, ToInvtDocLine, FromInvtDocHeader, FromInvtDocLine,
                              NextLineNo, LinesNotCopied, LinesSkipApplies);
                        until FromInvtRcptLine.Next() = 0;
                end;
            InvtDocType::"Posted Shipment":
                begin
                    FromInvtDocHeader.TransferFields(FromInvtShptHeader);
                    FromInvtDocHeader."Document Type" := FromInvtDocHeader."Document Type"::Shipment;
                    FromInvtShptLine.Reset();
                    FromInvtShptLine.SetRange("Document No.", FromInvtShptHeader."No.");
                    OnCopyItemDocOnBeforeLoopFromInventoryShipmentLine(FromInvtShptLine);
                    if FromInvtShptLine.Find('-') then
                        repeat
                            FromInvtDocLine.TransferFields(FromInvtShptLine);
                            CopyInvtDocLine(ToInvtDocHeader, ToInvtDocLine, FromInvtDocHeader, FromInvtDocLine, NextLineNo, LinesNotCopied, LinesSkipApplies);
                        until FromInvtShptLine.Next() = 0;
                end;
        end;

        if LinesNotCopied > 0 then
            Message(LinesNotCopiedMsg);

        if LinesSkipApplies > 0 then
            Message(LinesNotAppliedMsg, LinesSkipApplies);
    end;

    local procedure CopyInvtDocLine(var ToInvtDocHeader: Record "Invt. Document Header"; var ToInvtDocLine: Record "Invt. Document Line"; var FromInvtDocHeader: Record "Invt. Document Header"; var FromInvtDocLine: Record "Invt. Document Line"; var NextLineNo: Integer; var LinesNotCopied: Integer; var LinesSkipApplies: Integer)
    var
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        CopyThisLine: Boolean;
        IsHandled: Boolean;
        DifferentLocationsErr: Label 'Location Code %1 from document %2 is not same as Location Code %3. This is not allowed without Recalculate Lines is selected.', Comment = '%1 - Location Code, %2 - Document No., %3 - Location Code';
    begin
        CopyThisLine := true;

        if not RecalculateLines then
            if FromInvtDocHeader."Location Code" <> ToInvtDocHeader."Location Code" then
                Error(DifferentLocationsErr, FromInvtDocHeader."Location Code", FromInvtDocHeader."No.", ToInvtDocHeader."Location Code");

        if RecalculateLines then
            ToInvtDocLine.Init()
        else
            ToInvtDocLine := FromInvtDocLine;
        NextLineNo := NextLineNo + 10000;
        ToInvtDocLine."Document Type" := ToInvtDocHeader."Document Type";
        ToInvtDocLine."Document No." := ToInvtDocHeader."No.";
        ToInvtDocLine."Line No." := NextLineNo;
        if RecalculateLines then begin
            ToInvtDocLine.Validate(Description, FromInvtDocLine.Description);
            if FromInvtDocLine."Item No." <> '' then begin
                ToInvtDocLine.Validate("Item No.", FromInvtDocLine."Item No.");
                ToInvtDocLine.Validate("Variant Code", FromInvtDocLine."Variant Code");
                ToInvtDocLine.Validate("Location Code", ToInvtDocHeader."Location Code");
                ToInvtDocLine.Validate("Unit of Measure Code", FromInvtDocLine."Unit of Measure Code");
                ToInvtDocLine.Validate(Quantity, FromInvtDocLine.Quantity);
            end;
        end else begin
            ToInvtDocLine."Reserved Quantity Inbnd." := 0;
            ToInvtDocLine."Reserved Qty. Inbnd. (Base)" := 0;
            ToInvtDocLine."Reserved Quantity Outbnd." := 0;
            ToInvtDocLine."Reserved Qty. Outbnd. (Base)" := 0;
            ToInvtDocLine."Applies-from Entry" := 0;
            ToInvtDocLine."Applies-to Entry" := 0;
            if not CreateToHeader then
                ToInvtDocLine."Document Date" := ToInvtDocHeader."Document Date";
        end;

        if CopyItemTracking then begin
            TempItemLedgerEntry.Reset();
            TempItemLedgerEntry.DeleteAll();

            IsHandled := false;
            OnCopyInvtDocLineOnBeforeCopyItemTrackingAndAppliesValues(ToInvtDocHeader, ToInvtDocLine, FromInvtDocHeader, FromInvtDocLine, GlobalFromDocType, CopyThisLine, IsHandled);
            if not IsHandled then begin
                case GlobalFromDocType of
                    GlobalFromDocType::"Posted Receipt":
                        GetItemLedgEntries(Enum::"Item Ledger Document Type"::"Inventory Receipt", FromInvtDocLine."Document No.", FromInvtDocLine."Line No.", TempItemLedgerEntry, true);
                    GlobalFromDocType::"Posted Shipment":
                        GetItemLedgEntries(Enum::"Item Ledger Document Type"::"Inventory Shipment", FromInvtDocLine."Document No.", FromInvtDocLine."Line No.", TempItemLedgerEntry, true);
                end;

                UpdateInvtDocumentLineWithTrackingAndAppliesValue(TempItemLedgerEntry, ToInvtDocLine, ToInvtDocHeader, FillAppliesFields, LinesSkipApplies);
            end;
        end;

        if CopyThisLine then
            ToInvtDocLine.Insert()
        else
            LinesNotCopied := LinesNotCopied + 1;

        OnAfterCopyInvtDocLine(ToInvtDocLine, FromInvtDocHeader, FromInvtDocLine);
    end;

    procedure CheckItemAvailable(var ToInvtDocHeader: Record "Invt. Document Header"; var ToInvtDocLine: Record "Invt. Document Line")
    begin
        if HideDialog then
            exit;

        ToInvtDocLine."Document Type" := ToInvtDocHeader."Document Type";
        ToInvtDocLine."Document No." := ToInvtDocHeader."No.";
        ToInvtDocLine."Line No." := 0;

        if ToInvtDocLine."Document Date" = 0D then
            if ToInvtDocHeader."Document Date" <> 0D then
                ToInvtDocLine.Validate("Document Date", ToInvtDocHeader."Document Date")
            else
                ToInvtDocLine.Validate("Document Date", WorkDate());

        ItemCheckAvail.InvtDocCheckLine(ToInvtDocLine);
    end;

    procedure GetItemDocLedgerEntryNo(DocNo: Code[20]; DocType: Integer; DocLineNo: Integer): Integer
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.Reset();
        ItemLedgerEntry.SetCurrentKey("Document No.", "Document Type", "Document Line No.");
        ItemLedgerEntry.SetRange("Document No.", DocNo);
        ItemLedgerEntry.SetRange("Document Type", DocType);
        ItemLedgerEntry.SetRange("Document Line No.", DocLineNo);
        if ItemLedgerEntry.FindFirst() then
            if not ItemLedgerEntry.TrackingExists() then
                exit(ItemLedgerEntry."Entry No.");

        exit(0);
    end;

    local procedure UpdateInvtDocumentLineWithTrackingAndAppliesValue(var ItemLedgerEntryBuffer: Record "Item Ledger Entry"; var ToInvtDocumentLine: Record "Invt. Document Line"; ToInvtDocumentHeader: Record "Invt. Document Header"; SetAppliesFields: Boolean; var LinesSkipApplies: Integer)
    var
        DoSetAppliesFields: Boolean;
        ForLineSkipApplies: Integer;
    begin
        if ToInvtDocumentLine.Quantity = 0 then
            exit;

        if ItemLedgerEntryBuffer.FindSet() then
            repeat
                DoSetAppliesFields := SetAppliesFields and
                    (ItemLedgerEntryBuffer."Location Code" = ToInvtDocumentHeader."Location Code") and
                    ((ItemLedgerEntryBuffer."Remaining Quantity" <> 0) or (ItemLedgerEntryBuffer."Shipped Qty. Not Returned" <> 0));

                if SetAppliesFields and not DoSetAppliesFields then
                    ForLineSkipApplies += 1;

                if ItemLedgerEntryBuffer.TrackingExists() then
                    CopyItemLedgEntryTrkgToInvtDocumentLine(ItemLedgerEntryBuffer, ToInvtDocumentLine, ToInvtDocumentHeader, DoSetAppliesFields)
                else
                    if DoSetAppliesFields then
                        if ((ToInvtDocumentLine."Document Type" = ToInvtDocumentLine."Document Type"::Receipt) and not ToInvtDocumentHeader.Correction)
                            or ((ToInvtDocumentLine."Document Type" = ToInvtDocumentLine."Document Type"::Shipment) and ToInvtDocumentHeader.Correction) then
                            ToInvtDocumentLine.Validate("Applies-from Entry", ItemLedgerEntryBuffer."Entry No.")
                        else
                            ToInvtDocumentLine.Validate("Applies-to Entry", ItemLedgerEntryBuffer."Entry No.");
            until ItemLedgerEntryBuffer.Next() = 0;

        if ForLineSkipApplies > 0 then
            LinesSkipApplies += 1;
    end;

    local procedure CopyItemLedgEntryTrkgToInvtDocumentLine(var ItemLedgerEntryBuffer: Record "Item Ledger Entry"; var ToInvtDocumentLine: Record "Invt. Document Line"; ToInvtDocumentHeader: Record "Invt. Document Header"; SetAppliesFields: Boolean)
    var
        QtyBase: Decimal;
        SignFactor: Integer;
        EntriesExist: Boolean;
    begin
        GetSignFactor(ItemLedgerEntryBuffer."Document Type", ItemLedgerEntryBuffer.Positive, ToInvtDocumentLine."Document Type", ToInvtDocumentHeader.Correction, SignFactor);
        if ItemLedgerEntryBuffer."Document Type" = ItemLedgerEntryBuffer."Document Type"::"Inventory Receipt" then
            QtyBase := ItemLedgerEntryBuffer."Remaining Quantity" * SignFactor
        else
            QtyBase := ItemLedgerEntryBuffer."Shipped Qty. Not Returned" * SignFactor;

        if (QtyBase = 0) or not SetAppliesFields then
            QtyBase := ItemLedgerEntryBuffer.Quantity * SignFactor;

        InsertReservEntryForInvtDocumentLine(ItemLedgerEntryBuffer, ToInvtDocumentLine, QtyBase, EntriesExist, SetAppliesFields, ToInvtDocumentHeader.Correction);
    end;

    local procedure GetSignFactor(ItemLedgerEntryDocType: Enum "Item Ledger Document Type"; ItemLedgerEntryPositive: Boolean; InvtLineDocType: Enum "Invt. Doc. Document Type"; IsCorrection: Boolean; var SignFactor: Integer)
    begin
        SignFactor := 1;
        case true of
            (ItemLedgerEntryDocType = ItemLedgerEntryDocType::"Inventory Receipt")
            and ItemLedgerEntryPositive
            and (InvtLineDocType = InvtLineDocType::Shipment)
            and not IsCorrection:
                SignFactor := -1;

            (ItemLedgerEntryDocType = ItemLedgerEntryDocType::"Inventory Receipt")
            and ItemLedgerEntryPositive
            and (InvtLineDocType = InvtLineDocType::Receipt)
            and IsCorrection:
                SignFactor := -1;

            (ItemLedgerEntryDocType = ItemLedgerEntryDocType::"Inventory Receipt")
            and not ItemLedgerEntryPositive
            and (InvtLineDocType = InvtLineDocType::Receipt)
            and not IsCorrection:
                SignFactor := -1;

            (ItemLedgerEntryDocType = ItemLedgerEntryDocType::"Inventory Receipt")
            and not ItemLedgerEntryPositive
            and (InvtLineDocType = InvtLineDocType::Shipment)
            and IsCorrection:
                SignFactor := -1;

            (ItemLedgerEntryDocType = ItemLedgerEntryDocType::"Inventory Shipment")
            and ItemLedgerEntryPositive
            and (InvtLineDocType = InvtLineDocType::Shipment)
            and not IsCorrection:
                SignFactor := -1;

            (ItemLedgerEntryDocType = ItemLedgerEntryDocType::"Inventory Shipment")
            and ItemLedgerEntryPositive
            and (InvtLineDocType = InvtLineDocType::Receipt)
            and IsCorrection:
                SignFactor := -1;

            (ItemLedgerEntryDocType = ItemLedgerEntryDocType::"Inventory Shipment")
            and not ItemLedgerEntryPositive
            and (InvtLineDocType = InvtLineDocType::Receipt)
            and not IsCorrection:
                SignFactor := -1;

            (ItemLedgerEntryDocType = ItemLedgerEntryDocType::"Inventory Shipment")
            and not ItemLedgerEntryPositive
            and (InvtLineDocType = InvtLineDocType::Shipment)
            and IsCorrection:
                SignFactor := -1;
        end;
    end;

    local procedure InsertReservEntryForInvtDocumentLine(ItemLedgerEntryBuffer: Record "Item Ledger Entry"; InvtDocumentLine: Record "Invt. Document Line"; QtyBase: Decimal; var EntriesExist: Boolean; SetAppliesFields: Boolean; IsCorrection: Boolean)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        if not ItemLedgerEntryBuffer.TrackingExists() or (QtyBase = 0) then
            exit;

        ItemLedgerEntryBuffer."Location Code" := InvtDocumentLine."Location Code";
        InitReservEntry(ReservationEntry, ItemLedgerEntryBuffer, QtyBase, InvtDocumentLine."Posting Date", EntriesExist);
        ReservationEntry.SetSource(DATABASE::"Invt. Document Line", InvtDocumentLine."Document Type".AsInteger(), InvtDocumentLine."Document No.", InvtDocumentLine."Line No.", '', 0);
        ReservationEntry."Reservation Status" := ReservationEntry."Reservation Status"::Prospect;
        ReservationEntry.Description := InvtDocumentLine.Description;

        if SetAppliesFields then
            if ((InvtDocumentLine."Document Type" = InvtDocumentLine."Document Type"::Receipt) and not IsCorrection)
            or ((InvtDocumentLine."Document Type" = InvtDocumentLine."Document Type"::Shipment) and IsCorrection) then
                ReservationEntry."Appl.-from Item Entry" := ItemLedgerEntryBuffer."Entry No."
            else
                ReservationEntry."Appl.-to Item Entry" := ItemLedgerEntryBuffer."Entry No.";

        ReservationEntry.UpdateItemTracking();
        ReservationEntry.Insert();
    end;

    local procedure InitReservEntry(var ReservationEntry: Record "Reservation Entry"; ItemLedgerEntryBuffer: Record "Item Ledger Entry"; QtyBase: Decimal; Date: Date; var EntriesExist: Boolean)
    begin
        ReservationEntry.Init();
        ReservationEntry."Item No." := ItemLedgerEntryBuffer."Item No.";
        ReservationEntry."Location Code" := ItemLedgerEntryBuffer."Location Code";
        ReservationEntry."Variant Code" := ItemLedgerEntryBuffer."Variant Code";
        ReservationEntry."Qty. per Unit of Measure" := ItemLedgerEntryBuffer."Qty. per Unit of Measure";
        ReservationEntry.CopyTrackingFromItemLedgEntry(ItemLedgerEntryBuffer);
        ReservationEntry."Quantity Invoiced (Base)" := 0;
        ReservationEntry.Validate("Quantity (Base)", QtyBase);
        ReservationEntry.Positive := (ReservationEntry."Quantity (Base)" > 0);
        ReservationEntry."Entry No." := 0;
        if ReservationEntry.Positive then begin
            ReservationEntry."Warranty Date" := ItemLedgerEntryBuffer."Warranty Date";
            ReservationEntry."Expiration Date" := ItemTrackingManagement.ExistingExpirationDate(ItemLedgerEntryBuffer, false, EntriesExist);
            ReservationEntry."Expected Receipt Date" := Date;
        end else
            ReservationEntry."Shipment Date" := Date;
        ReservationEntry."Creation Date" := WorkDate();
        ReservationEntry."Created By" := CopyStr(UserId(), 1, MaxStrLen(ReservationEntry."Created By"));
    end;

    local procedure GetItemLedgEntries(DocumentType: Enum "Item Ledger Document Type"; DocumentNo: Code[20]; DocumentLineNo: Integer; var TempItemLedgerEntry: Record "Item Ledger Entry" temporary; SetQuantity: Boolean)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
    begin
        if SetQuantity then begin
            TempItemLedgerEntry.Reset();
            TempItemLedgerEntry.DeleteAll();
        end;

        FilterPstdDocLineValueEntries(ValueEntry, DocumentType, DocumentNo, DocumentLineNo);
        ValueEntry.SetFilter("Invoiced Quantity", '<>0');
        if ValueEntry.FindSet() then
            repeat
                ItemLedgerEntry.Get(ValueEntry."Item Ledger Entry No.");
                TempItemLedgerEntry := ItemLedgerEntry;
                if SetQuantity then begin
                    TempItemLedgerEntry.Quantity := ValueEntry."Invoiced Quantity";

                    if ItemLedgerEntry.Positive then begin
                        if Abs(TempItemLedgerEntry."Remaining Quantity") > Abs(TempItemLedgerEntry.Quantity) then
                            TempItemLedgerEntry."Remaining Quantity" := TempItemLedgerEntry.Quantity;
                    end
                    else
                        if Abs(TempItemLedgerEntry."Shipped Qty. Not Returned") > Abs(TempItemLedgerEntry.Quantity) then
                            TempItemLedgerEntry."Shipped Qty. Not Returned" := TempItemLedgerEntry.Quantity;
                end;
                if TempItemLedgerEntry.Insert() then;
            until ValueEntry.Next() = 0;
    end;

    local procedure FilterPstdDocLineValueEntries(var ValueEntry: Record "Value Entry"; DocumentType: Enum "Item Ledger Document Type"; DocumentNo: Code[20]; DocumentLineNo: Integer)
    begin
        ValueEntry.Reset();
        ValueEntry.SetCurrentKey("Document No.");
        ValueEntry.SetRange("Document No.", DocumentNo);
        ValueEntry.SetRange("Document Type", DocumentType);
        ValueEntry.SetRange("Document Line No.", DocumentLineNo);
    end;

    [IntegrationEvent(false, false)]
    procedure OnCopyInvtDocLineOnBeforeCopyItemTrackingAndAppliesValues(var ToInvtDocumentHeader: Record "Invt. Document Header"; var ToInvtDocumentLine: Record "Invt. Document Line"; var FromInvtDocumentHeader: Record "Invt. Document Header"; var FromInvtDocumentLine: Record "Invt. Document Line"; FromInvtDocType: Enum "Invt. Doc. Document Type From"; var CopyThisLine: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyInvtDocLine(var ToInvtDocumentLine: Record "Invt. Document Line"; var FromInvtDocumentHeader: Record "Invt. Document Header"; var FromInvtDocumentLine: Record "Invt. Document Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyItemDocOnBeforeLoopFromInventoryDocumentLine(var FromInvtDocumentLine: Record "Invt. Document Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyItemDocOnBeforeLoopFromInventoryReceiptLine(var FromInvtReceiptLine: Record "Invt. Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyItemDocOnBeforeLoopFromInventoryShipmentLine(var FromInvtShipmentLine: Record "Invt. Shipment Line")
    begin
    end;
}

