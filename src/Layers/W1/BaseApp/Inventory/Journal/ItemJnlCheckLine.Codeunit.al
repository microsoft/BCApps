// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Journal;

using Microsoft.CRM.Team;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Preview;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Setup;
using Microsoft.Warehouse.Journal;
using System.Security.User;

codeunit 21 "Item Jnl.-Check Line"
{
    TableNo = "Item Journal Line";

    trigger OnRun()
    begin
        RunCheck(Rec);
    end;

    var
        Location: Record Location;
        InvtSetup: Record "Inventory Setup";
        GLSetup: Record "General Ledger Setup";
        ItemLedgEntry: Record "Item Ledger Entry";
        ItemJnlLine2: Record "Item Journal Line";
        ItemJnlLine3: Record "Item Journal Line";
        DimMgt: Codeunit DimensionManagement;
        CalledFromInvtPutawayPick: Boolean;
        CalledFromAdjustment: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'cannot be a closing date';
        Text003: Label 'must not be negative when %1 is %2';
        Text004: Label 'must have the same value as %1';
        Text005: Label 'must be %1 or %2 when %3 is %4';
        Text006: Label 'must equal %1 - %2 when %3 is %4 and %5 is %6';
        DimCombBlockedErr: Label 'The combination of dimensions used in item journal line %1, %2, %3 is blocked. %4.', Comment = '%1 = Journal Template Name; %2 = Journal Batch Name; %3 = Line No.';
        DimCausedErr: Label 'A dimension used in item journal line %1, %2, %3 has caused an error. %4.', Comment = '%1 = Journal Template Name; %2 = Journal Batch Name; %3 = Line No.';
        Text011: Label '%1 must not be equal to %2';
        UseInTransitLocationErr: Label 'You can use In-Transit location %1 for transfer orders only.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure RunCheck(var ItemJournalLine: Record "Item Journal Line")
    var
        Item: Record Item;
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        IsHandled: Boolean;
        ShouldCheckApplication: Boolean;
        ShouldCheckDiscountAmount: Boolean;
        ShouldCheckLocationCode: Boolean;
    begin
        GLSetup.Get();
        InvtSetup.Get();

        if ItemJournalLine.EmptyLine() then begin
            if not ItemJournalLine.IsValueEntryForDeletedItem() then
                exit;
        end else
            if not ItemJournalLine.OnlyStopTime() then
                ItemJournalLine.TestField("Item No.", ErrorInfo.Create());

        Item.ReadIsolation(IsolationLevel::ReadUncommitted);
        IsHandled := false;
        OnBeforeGetItem(Item, IsHandled, ItemJournalLine);
        if not IsHandled then
            if Item.Get(ItemJournalLine."Item No.") then
                Item.TestField("Base Unit of Measure", ErrorInfo.Create());

        IsHandled := false;
        OnAfterGetItem(Item, ItemJournalLine, IsHandled);
        if IsHandled then
            exit;

        if ItemJournalLine."Posting No. Series" = '' then
            ItemJournalLine.TestField("Document No.", ErrorInfo.Create());
        ItemJournalLine.TestField("Gen. Prod. Posting Group", ErrorInfo.Create());

        CheckDates(ItemJournalLine);

        IsHandled := false;
        OnBeforeCheckLocation(ItemJournalLine, IsHandled);
        if not IsHandled then
            if InvtSetup."Location Mandatory" and
                (ItemJournalLine."Value Entry Type" = ItemJournalLine."Value Entry Type"::"Direct Cost") and
               (ItemJournalLine.Quantity <> 0) and
               not ItemJournalLine.Adjustment and
               not ItemJournalLine.Correction
            then begin
                ShouldCheckLocationCode := (ItemJournalLine.Type <> ItemJournalLine.Type::Resource) and (Item.Type = Item.Type::Inventory) and
                   (not ItemJournalLine."Direct Transfer" or (ItemJournalLine."Document Type" = ItemJournalLine."Document Type"::"Transfer Shipment"));
                OnRunCheckOnAfterCalcShouldCheckLocationCode(ItemJournalLine, ShouldCheckLocationCode);
                if ShouldCheckLocationCode then
                    ItemJournalLine.TestField("Location Code", ErrorInfo.Create());
                if (ItemJournalLine."Entry Type" = ItemJournalLine."Entry Type"::Transfer) and
                   (not ItemJournalLine."Direct Transfer" or (ItemJournalLine."Document Type" = ItemJournalLine."Document Type"::"Transfer Receipt"))
                then
                    ItemJournalLine.TestField("New Location Code", ErrorInfo.Create())
                else
                    ItemJournalLine.TestField("New Location Code", '', ErrorInfo.Create());
                if GLSetup."Journal Templ. Name Mandatory" and
                    (InvtSetup."Automatic Cost Posting" or InvtSetup."Expected Cost Posting to G/L")
                then begin
                    InvtSetup.TestField("Invt. Cost Jnl. Template Name", ErrorInfo.Create());
                    InvtSetup.TestField("Invt. Cost Jnl. Batch Name", ErrorInfo.Create());
                end;
            end;

        CheckVariantMandatory(ItemJournalLine, Item);

        CheckInTransitLocations(ItemJournalLine);

        if Item.IsInventoriableType() then
            CheckBins(ItemJournalLine)
        else
            ItemJournalLine.TestField("Bin Code", '', ErrorInfo.Create());

        ShouldCheckDiscountAmount := ItemJournalLine."Entry Type" in [ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemJournalLine."Entry Type"::"Negative Adjmt."];
        OnRunCheckOnAfterCalcShouldCheckDiscountAmount(ItemJournalLine, ShouldCheckDiscountAmount);
        if ShouldCheckDiscountAmount then
            ItemJournalLine.TestField("Discount Amount", 0, ErrorInfo.Create());

        if ItemJournalLine."Entry Type" = ItemJournalLine."Entry Type"::Transfer then begin
            if (ItemJournalLine."Value Entry Type" = ItemJournalLine."Value Entry Type"::"Direct Cost") and
               (ItemJournalLine."Item Charge No." = '') and
               not ItemJournalLine.Adjustment
            then
                ItemJournalLine.TestField(Amount, 0, ErrorInfo.Create());
            ItemJournalLine.TestField("Discount Amount", 0, ErrorInfo.Create());
            if (ItemJournalLine.Quantity < 0) and not ItemJournalLine.Correction then
                ItemJournalLine.FieldError(Quantity, ErrorInfo.Create(StrSubstNo(Text003, ItemJournalLine.FieldCaption("Entry Type"), ItemJournalLine."Entry Type"), true));
            if ItemJournalLine.Quantity <> ItemJournalLine."Invoiced Quantity" then
                ItemJournalLine.FieldError("Invoiced Quantity", ErrorInfo.Create(StrSubstNo(Text004, ItemJournalLine.FieldCaption(Quantity)), true));
        end;

        if not ItemJournalLine."Phys. Inventory" then begin
            CheckEmptyQuantity(ItemJournalLine);
            ItemJournalLine.TestField("Qty. (Calculated)", 0, ErrorInfo.Create());
            ItemJournalLine.TestField("Qty. (Phys. Inventory)", 0, ErrorInfo.Create());
        end else
            CheckPhysInventory(ItemJournalLine);

        CheckOutputFields(ItemJournalLine);

        ShouldCheckApplication := ItemJournalLine."Applies-from Entry" <> 0;
        OnRunCheckOnAfterCalcShouldCheckApplication(ItemJournalLine, ShouldCheckApplication);
        if ShouldCheckApplication then begin
            ItemLedgEntry.Get(ItemJournalLine."Applies-from Entry");
            ItemLedgEntry.TestField("Item No.", ItemJournalLine."Item No.", ErrorInfo.Create());
            ItemLedgEntry.TestField("Variant Code", ItemJournalLine."Variant Code", ErrorInfo.Create());
            ItemLedgEntry.TestField(Positive, false, ErrorInfo.Create());
            if ItemJournalLine."Applies-to Entry" = ItemJournalLine."Applies-from Entry" then
                Error(
                    ErrorInfo.Create(
                        StrSubstNo(
                            Text011,
                            ItemJournalLine.FieldCaption("Applies-to Entry"),
                            ItemJournalLine.FieldCaption("Applies-from Entry")),
                        true));
        end;

        OnRunOnCheckWarehouse(ItemJournalLine, CalledFromAdjustment, CalledFromInvtPutawayPick);

        IsHandled := false;
        OnRunCheckOnBeforeTestFieldAppliesToEntry(ItemJournalLine, IsHandled);
        if not isHandled then
            if (ItemJournalLine."Value Entry Type" <> ItemJournalLine."Value Entry Type"::"Direct Cost") or (ItemJournalLine."Item Charge No." <> '') then
                if ItemJournalLine."Inventory Value Per" = ItemJournalLine."Inventory Value Per"::" " then
                    ItemJournalLine.TestField("Applies-to Entry", ErrorInfo.Create());

        CheckDimensions(ItemJournalLine);

        if (ItemJournalLine."Entry Type" in
            [ItemJournalLine."Entry Type"::Purchase, ItemJournalLine."Entry Type"::Sale, ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemJournalLine."Entry Type"::"Negative Adjmt."]) and
           (not GenJnlPostPreview.IsActive())
        then
            ItemJournalLine.CheckItemJournalLineRestriction();

        OnAfterCheckItemJnlLine(ItemJournalLine, CalledFromInvtPutawayPick, CalledFromAdjustment);
    end;

    local procedure CheckOutputFields(var ItemJournalLine: Record "Item Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckOutputFields(ItemJournalLine, IsHandled);
        if IsHandled then
            exit;

        OnCheckOutputFields(ItemJournalLine);
    end;

    local procedure CheckEmptyQuantity(ItemJnlLine: Record "Item Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckEmptyQuantity(ItemJnlLine, IsHandled);
        if IsHandled then
            exit;

        OnCheckEmptyQuantity(ItemJnlLine);
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Clear(Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    procedure SetCalledFromInvtPutawayPick(NewCalledFromInvtPutawayPick: Boolean)
    begin
        CalledFromInvtPutawayPick := NewCalledFromInvtPutawayPick;
    end;

    procedure SetCalledFromAdjustment(NewCalledFromAdjustment: Boolean)
    begin
        CalledFromAdjustment := NewCalledFromAdjustment;
    end;

    local procedure CheckBins(ItemJnlLine: Record "Item Journal Line")
    var
        WMSManagement: Codeunit "WMS Management";
        IsHandled: Boolean;
        ShouldExit: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckBins(ItemJnlLine, IsHandled, CalledFromAdjustment);
        if IsHandled then
            exit;

        if (ItemJnlLine."Item Charge No." <> '') or (ItemJnlLine."Value Entry Type" <> ItemJnlLine."Value Entry Type"::"Direct Cost") or (ItemJnlLine.Quantity = 0) then
            exit;

        if ItemJnlLine."Entry Type" = ItemJnlLine."Entry Type"::Transfer then begin
            GetLocation(ItemJnlLine."New Location Code");
            CheckNewBinCode(ItemJnlLine);
        end else begin
            GetLocation(ItemJnlLine."Location Code");
            if not Location."Bin Mandatory" or Location."Directed Put-away and Pick" then
                exit;
        end;

        if ItemJnlLine."Drop Shipment" or ItemJnlLine.OnlyStopTime() or (ItemJnlLine."Quantity (Base)" = 0) or ItemJnlLine.Adjustment or CalledFromAdjustment then
            exit;

        ShouldExit := false;
        OnCheckBinsOnCheckForEntryTypeOutput(ItemJnlLine, ShouldExit);
        if ShouldExit then
            exit;

        IsHandled := false;
        OnCheckBinsOnBeforeCheckNonZeroQuantity(ItemJnlLine, CalledFromAdjustment, IsHandled);
        if not IsHandled then
            if ItemJnlLine.Quantity <> 0 then
                case ItemJnlLine."Entry Type" of
                    ItemJnlLine."Entry Type"::Purchase,
                  ItemJnlLine."Entry Type"::"Positive Adjmt.",
                  ItemJnlLine."Entry Type"::Output,
                  ItemJnlLine."Entry Type"::"Assembly Output":
                        WMSManagement.CheckInbOutbBin(ItemJnlLine."Location Code", ItemJnlLine."Bin Code", ItemJnlLine.Quantity > 0);
                    ItemJnlLine."Entry Type"::Sale,
                  ItemJnlLine."Entry Type"::"Negative Adjmt.",
                  ItemJnlLine."Entry Type"::Consumption,
                  ItemJnlLine."Entry Type"::"Assembly Consumption":
                        WMSManagement.CheckInbOutbBin(ItemJnlLine."Location Code", ItemJnlLine."Bin Code", ItemJnlLine.Quantity < 0);
                    ItemJnlLine."Entry Type"::Transfer:
                        begin
                            GetLocation(ItemJnlLine."Location Code");
                            if Location."Bin Mandatory" and not Location."Directed Put-away and Pick" then
                                WMSManagement.CheckInbOutbBin(ItemJnlLine."Location Code", ItemJnlLine."Bin Code", ItemJnlLine.Quantity < 0);
                            if (ItemJnlLine."New Location Code" <> '') and (ItemJnlLine."New Bin Code" <> '') then
                                WMSManagement.CheckInbOutbBin(ItemJnlLine."New Location Code", ItemJnlLine."New Bin Code", ItemJnlLine.Quantity > 0);
                        end;
                end;
    end;

    local procedure CheckNewBinCode(ItemJnlLine: Record "Item Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckNewBinCode(ItemJnlLine, Location, IsHandled);
        if IsHandled then
            exit;

        if Location."Bin Mandatory" and not Location."Directed Put-away and Pick" then
            ItemJnlLine.TestField("New Bin Code", ErrorInfo.Create());
    end;

    local procedure CheckDates(ItemJnlLine: Record "Item Journal Line")
    var
        InvtPeriod: Record "Inventory Period";
        UserSetupManagement: Codeunit "User Setup Management";
        DateCheckDone: Boolean;
        ShouldShowError: Boolean;
    begin
        ItemJnlLine.TestField("Posting Date", ErrorInfo.Create());
        if ItemJnlLine."Posting Date" <> NormalDate(ItemJnlLine."Posting Date") then
            ItemJnlLine.FieldError("Posting Date", ErrorInfo.Create(Text000, true));

        OnBeforeDateNotAllowed(ItemJnlLine, DateCheckDone);
        if not DateCheckDone then
            UserSetupManagement.CheckAllowedPostingDate(ItemJnlLine."Posting Date");

        ShouldShowError := not InvtPeriod.IsValidDate(ItemJnlLine."Posting Date");
        OnCheckDatesOnAfterCalcShouldShowError(ItemJnlLine, ShouldShowError, CalledFromAdjustment);
        if ShouldShowError then
            InvtPeriod.ShowError(ItemJnlLine."Posting Date");

        if ItemJnlLine."Document Date" <> 0D then
            if ItemJnlLine."Document Date" <> NormalDate(ItemJnlLine."Document Date") then
                ItemJnlLine.FieldError("Document Date", ErrorInfo.Create(Text000, true));
    end;

    local procedure CheckDimensions(ItemJnlLine: Record "Item Journal Line")
    var
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckDimensions(ItemJnlLine, CalledFromAdjustment, IsHandled);
        if IsHandled then
            exit;

        if not ItemJnlLine.IsValueEntryForDeletedItem() and not ItemJnlLine.Correction and not CalledFromAdjustment then begin
            if not DimMgt.CheckDimIDComb(ItemJnlLine."Dimension Set ID") then
                Error(
                    ErrorInfo.Create(
                        StrSubstNo(
                            DimCombBlockedErr, ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", ItemJnlLine."Line No.", DimMgt.GetDimCombErr()),
                        true));
            if ItemJnlLine."Item Charge No." = '' then begin
                TableID[1] := Database::Item;
                No[1] := ItemJnlLine."Item No.";
            end else begin
                TableID[1] := Database::"Item Charge";
                No[1] := ItemJnlLine."Item Charge No.";
            end;
            TableID[2] := Database::"Salesperson/Purchaser";
            No[2] := ItemJnlLine."Salespers./Purch. Code";
            OnCheckDimensionsOnAfterSetTableValues(ItemJnlLine, TableID, No);

            if ItemJnlLine."New Dimension Set ID" <> 0 then begin
                TableID[4] := Database::Location;
                No[4] := ItemJnlLine."Location Code";
                CheckDimensionsAfterAssignDimTableIDs(ItemJnlLine, TableID, No, ItemJnlLine."Dimension Set ID");
                TableID[4] := Database::Location;
                No[4] := ItemJnlLine."New Location Code";
                CheckDimensionsAfterAssignDimTableIDs(ItemJnlLine, TableID, No, ItemJnlLine."New Dimension Set ID");
            end else begin
                // This condition will ensure locations default dimension is not checked as for Item charge lines, location in item journal is populated from document line
                if ItemJnlLine."Item Charge No." = '' then begin
                    TableID[4] := Database::Location;
                    No[4] := ItemJnlLine."Location Code";
                    TableID[5] := Database::Location;
                    No[5] := ItemJnlLine."New Location Code";
                end;
                if (ItemJnlLine."Entry Type" = ItemJnlLine."Entry Type"::Transfer) then begin
                    CheckDimensionsAfterAssignDimTableIDs(ItemJnlLine, TableID, No, ItemJnlLine."Dimension Set ID");
                    if (DimMgt.CheckDefaultDimensionHasCodeMandatory(TableID, No)) and
                       (ItemJnlLine."Value Entry Type" <> ItemJnlLine."Value Entry Type"::Revaluation)
                    then
                        CheckDimensionsAfterAssignDimTableIDs(ItemJnlLine, TableID, No, ItemJnlLine."New Dimension Set ID");
                end else
                    CheckDimensionsAfterAssignDimTableIDs(ItemJnlLine, TableID, No, ItemJnlLine."Dimension Set ID");
            end;

            if (ItemJnlLine."Entry Type" = ItemJnlLine."Entry Type"::Transfer) and
               (ItemJnlLine."Value Entry Type" <> ItemJnlLine."Value Entry Type"::Revaluation)
            then
                if not DimMgt.CheckDimIDComb(ItemJnlLine."Dimension Set ID") then begin
                    if ItemJnlLine."Line No." <> 0 then
                        Error(
                            ErrorInfo.Create(
                                StrSubstNo(DimCausedErr, ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", ItemJnlLine."Line No.", DimMgt.GetDimValuePostingErr()),
                            true));
                    Error(ErrorInfo.Create(StrSubstNo(DimMgt.GetDimValuePostingErr()), true));
                end;
        end;
    end;

    local procedure CheckPhysInventory(ItemJnlLine: Record "Item Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPhysInventory(ItemJnlLine, IsHandled);
        if IsHandled then
            exit;

        if not
           (ItemJnlLine."Entry Type" in
            [ItemJnlLine."Entry Type"::"Positive Adjmt.", ItemJnlLine."Entry Type"::"Negative Adjmt."])
        then begin
            ItemJnlLine2."Entry Type" := ItemJnlLine2."Entry Type"::"Positive Adjmt.";
            ItemJnlLine3."Entry Type" := ItemJnlLine3."Entry Type"::"Negative Adjmt.";
            ItemJnlLine.FieldError(
                "Entry Type",
                ErrorInfo.Create(
                    StrSubstNo(
                        Text005, ItemJnlLine2."Entry Type", ItemJnlLine3."Entry Type", ItemJnlLine.FieldCaption("Phys. Inventory"), true),
                    true));
        end;
        if (ItemJnlLine."Entry Type" = ItemJnlLine."Entry Type"::"Positive Adjmt.") and
           (ItemJnlLine."Qty. (Phys. Inventory)" - ItemJnlLine."Qty. (Calculated)" <> ItemJnlLine.Quantity)
        then
            ItemJnlLine.FieldError(
                Quantity,
                 ErrorInfo.Create(
                    StrSubstNo(
                        Text006, ItemJnlLine.FieldCaption("Qty. (Phys. Inventory)"), ItemJnlLine.FieldCaption("Qty. (Calculated)"),
                        ItemJnlLine.FieldCaption("Entry Type"), ItemJnlLine."Entry Type", ItemJnlLine.FieldCaption("Phys. Inventory"), true),
                    true));
        if (ItemJnlLine."Entry Type" = ItemJnlLine."Entry Type"::"Negative Adjmt.") and
           (ItemJnlLine."Qty. (Calculated)" - ItemJnlLine."Qty. (Phys. Inventory)" <> ItemJnlLine.Quantity)
        then
            ItemJnlLine.FieldError(
                Quantity,
                ErrorInfo.Create(
                    StrSubstNo(
                        Text006, ItemJnlLine.FieldCaption("Qty. (Calculated)"), ItemJnlLine.FieldCaption("Qty. (Phys. Inventory)"),
                        ItemJnlLine.FieldCaption("Entry Type"), ItemJnlLine."Entry Type", ItemJnlLine.FieldCaption("Phys. Inventory"), true),
                    true));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckItemJnlLine(var ItemJnlLine: Record "Item Journal Line"; CalledFromInvtPutawayPick: Boolean; CalledFromAdjustment: Boolean)
    begin
    end;

    local procedure CheckInTransitLocation(LocationCode: Code[10])
    begin
        if Location.IsInTransit(LocationCode) then
            Error(ErrorInfo.Create(StrSubstNo(UseInTransitLocationErr, LocationCode), true));
    end;

    local procedure CheckInTransitLocations(var ItemJnlLine: Record "Item Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckInTransitLocations(ItemJnlLine, IsHandled);
        if IsHandled then
            exit;

        if ((ItemJnlLine."Entry Type" <> ItemJnlLine."Entry Type"::Transfer) or (ItemJnlLine."Order Type" <> ItemJnlLine."Order Type"::Transfer)) and
               not ItemJnlLine.Adjustment
        then begin
            CheckInTransitLocation(ItemJnlLine."Location Code");
            CheckInTransitLocation(ItemJnlLine."New Location Code");
        end;
    end;

    local procedure CheckVariantMandatory(var ItemJournalLine: Record "Item Journal Line"; var Item: Record Item)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckVariantMandatory(ItemJournalLine, IsHandled);
        if IsHandled then
            exit;

        if ItemJournalLine."Item Charge No." <> '' then
            exit;

        if ItemJournalLine."Inventory Value Per" in [ItemJournalLine."Inventory Value Per"::Item, ItemJournalLine."Inventory Value Per"::Location] then
            exit;

        if Item.IsVariantMandatory(InvtSetup."Variant Mandatory if Exists") then
            ItemJournalLine.TestField("Variant Code", ErrorInfo.Create());
    end;

    local procedure CheckDimensionsAfterAssignDimTableIDs(
        ItemJnlLine: Record "Item Journal Line";
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
        DimSetID: Integer)
    begin
        OnCheckDimensionsOnAfterAssignDimTableIDs(ItemJnlLine, TableID, No);
        if not DimMgt.CheckDimValuePosting(TableID, No, DimSetID) then begin
            if ItemJnlLine."Line No." <> 0 then
                Error(
                    ErrorInfo.Create(
                        StrSubstNo(DimCausedErr, ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", ItemJnlLine."Line No.", DimMgt.GetDimValuePostingErr()),
                    true));
            Error(ErrorInfo.Create(StrSubstNo(DimMgt.GetDimValuePostingErr()), true));
        end;
    end;

#if not CLEAN26
    internal procedure RunOnAfterAssignInvtPickRequired(ItemJournalLine: Record "Item Journal Line"; Location2: Record Location; var InvtPickLocation: Boolean)
    begin
        OnAfterAssignInvtPickRequired(ItemJournalLine, Location2, InvtPickLocation);
    end;

    [Obsolete('Moved to codeunits Asm./Mfg. Item Jnl.-Check-Line', '26.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignInvtPickRequired(ItemJournalLine: Record "Item Journal Line"; Location: Record Location; var InvtPickLocation: Boolean)
    begin
    end;
#endif

#if not CLEAN26
    internal procedure RunOnAfterAssignWhsePickRequired(ItemJournalLine: Record "Item Journal Line"; Location2: Record Location; var WhsePickLocation: Boolean)
    begin
        OnAfterAssignWhsePickRequired(ItemJournalLine, Location2, WhsePickLocation);
    end;

    [Obsolete('Moved to codeunits Asm./Mfg. Item Jnl.-Check-Line', '26.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignWhsePickRequired(ItemJournalLine: Record "Item Journal Line"; Location: Record Location; var WhsePickLocation: Boolean)
    begin
    end;
#endif

#if not CLEAN26
    internal procedure RunOnAfterAssignInvtPutAwayRequired(ItemJournalLine: Record "Item Journal Line"; Location2: Record Location; var InvtPutAwayLocation: Boolean)
    begin
        OnAfterAssignInvtPutAwayRequired(ItemJournalLine, Location2, InvtPutAwayLocation);
    end;

    [Obsolete('Moved to codeunits Asm./Mfg. Item Jnl.-Check-Line', '26.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignInvtPutAwayRequired(ItemJournalLine: Record "Item Journal Line"; Location: Record Location; var InvtPutAwayLocation: Boolean)
    begin
    end;
#endif

#if not CLEAN26
    internal procedure RunOnAfterCheckFindProdOrderLine(ItemJournalLine: Record "Item Journal Line"; ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line")
    begin
        OnAfterCheckFindProdOrderLine(ItemJournalLine, ProdOrderLine);
    end;

    [Obsolete('Moved to codeunits Mfg. Item Jnl.-Check-Line', '26.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckFindProdOrderLine(ItemJournalLine: Record "Item Journal Line"; ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetItem(Item: Record Item; var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBins(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean; CalledFromAdjustment: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDimensions(var ItemJournalLine: Record "Item Journal Line"; CalledFromAdjustment: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckInTransitLocations(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckLocation(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN26
    internal procedure RunOnBeforeCheckSubcontracting(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
        OnBeforeCheckSubcontracting(ItemJournalLine, IsHandled);
    end;

    [Obsolete('Moved to codeunits Mfg. Item Jnl.-Check-Line', '26.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSubcontracting(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;
#endif

#if not CLEAN26
    internal procedure RunOnBeforeCheckWarehouse(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
        OnBeforeCheckWarehouse(ItemJournalLine, IsHandled);
    end;

    [Obsolete('Moved to codeunits Mfg. Item Jnl.-Check-Line', '26.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckWarehouse(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;
#endif

#if not CLEAN26
    internal procedure RunOnBeforeCheckWarehouseLastOutputOperation(var ItemJournalLine: Record "Item Journal Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
        OnBeforeCheckWarehouseLastOutputOperation(ItemJournalLine, Result, IsHandled);
    end;

    [Obsolete('Moved to codeunits Mfg. Item Jnl.-Check-Line', '26.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckWarehouseLastOutputOperation(var ItemJournalLine: Record "Item Journal Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckOutputFields(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDateNotAllowed(ItemJnlLine: Record "Item Journal Line"; var DateCheckDone: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPhysInventory(ItemJnlLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckEmptyQuantity(ItemJnlLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckNewBinCode(ItemJnlLine: Record "Item Journal Line"; Location: Record Location; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckBinsOnBeforeCheckNonZeroQuantity(ItemJnlLine: Record "Item Journal Line"; var CalledFromAdjustment: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckDatesOnAfterCalcShouldShowError(var ItemJournalLine: Record "Item Journal Line"; var ShouldShowError: Boolean; CalledFromAdjustment: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckDimensionsOnAfterAssignDimTableIDs(var ItemJnlLine: Record "Item Journal Line"; var TableID: array[10] of Integer; var No: array[10] of Code[20])
    begin
    end;

#if not CLEAN26
    internal procedure RunOnRunCheckOnAfterCalcShouldCheckItemNo(ItemJournalLine: Record "Item Journal Line"; ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; CalledFromAdjustment2: Boolean; var ShouldCheckItemNo: Boolean)
    begin
        OnRunCheckOnAfterCalcShouldCheckItemNo(ItemJournalLine, ProdOrderLine, CalledFromAdjustment2, ShouldCheckItemNo);
    end;

    [Obsolete('Moved to codeunits Mfg. Item Jnl.-Check-Line', '26.0')]
    [IntegrationEvent(false, false)]
    local procedure OnRunCheckOnAfterCalcShouldCheckItemNo(ItemJournalLine: Record "Item Journal Line"; ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; CalledFromAdjustment: Boolean; var ShouldCheckItemNo: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnRunCheckOnAfterCalcShouldCheckLocationCode(var ItemJournalLine: Record "Item Journal Line"; var ShouldCheckLocationCode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunCheckOnAfterCalcShouldCheckDiscountAmount(var ItemJournalLine: Record "Item Journal Line"; var ShouldCheckDiscountAmount: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckVariantMandatory(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunCheckOnAfterCalcShouldCheckApplication(var ItemJournalLine: Record "Item Journal Line"; var ShouldCheckApplication: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunCheckOnBeforeTestFieldAppliesToEntry(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetItem(var Item: Record Item; var IsHandled: Boolean; ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnCheckWarehouse(var ItemJournalLine: Record "Item Journal Line"; CalledFromAdjustment: Boolean; CalledFromInvtPutawayPick: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckDimensionsOnAfterSetTableValues(ItemJournalLine: Record "Item Journal Line"; var TableID: array[10] of Integer; var No: array[10] of Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckEmptyQuantity(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [InternalEvent(false)]
    local procedure OnCheckOutputFields(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [InternalEvent(false)]
    local procedure OnCheckBinsOnCheckForEntryTypeOutput(var ItemJournalLine: Record "Item Journal Line"; var ShouldExit: Boolean)
    begin
    end;
}

