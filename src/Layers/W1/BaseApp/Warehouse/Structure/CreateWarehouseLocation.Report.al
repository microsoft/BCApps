// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Structure;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Worksheet;

report 5756 "Create Warehouse Location"
{
    ApplicationArea = Warehouse;
    Caption = 'Create Warehouse Location';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    requestpage
    {
        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(LocCode; LocCode)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Location Code';
                        ToolTip = 'Specifies the location where the warehouse activity takes place.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            Clear(Location);
                            if LocCode <> '' then
                                Location.Code := LocCode;
                            if Page.RunModal(0, Location) = Action::LookupOK then begin
                                Location.TestField("Bin Mandatory", false);
                                Location.TestField("Use As In-Transit", false);
                                Location.TestField("Directed Put-away and Pick", false);
                                LocCode := Location.Code;
                            end;
                        end;

                        trigger OnValidate()
                        begin
                            Location.Get(LocCode);
                            Location.TestField("Bin Mandatory", false);
                            Location.TestField("Use As In-Transit", false);
                            Location.TestField("Directed Put-away and Pick", false);
                        end;
                    }
                    field(AdjBinCode; AdjBinCode)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Adjustment Bin Code';
                        ToolTip = 'Specifies the code of the item on the bin list.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            Bin.Reset();
                            if LocCode <> '' then
                                Bin.SetRange("Location Code", LocCode);

                            if Page.RunModal(0, Bin) = Action::LookupOK then begin
                                if LocCode = '' then
                                    LocCode := Bin."Location Code";
                                AdjBinCode := Bin.Code;
                            end;
                        end;

                        trigger OnValidate()
                        begin
                            if AdjBinCode <> '' then
                                if LocCode <> '' then
                                    Bin.Get(LocCode, AdjBinCode)
                                else begin
                                    Bin.SetRange(Code, AdjBinCode);
                                    Bin.FindFirst();
                                    LocCode := Bin."Location Code";
                                end;
                        end;
                    }
                }
            }
        }
    }

    trigger OnPostReport()
    var
        WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line";
    begin
        Location."Bin Mandatory" := true;
        Location.Validate("Directed Put-away and Pick", true);
        Location.Validate("Adjustment Bin Code", AdjBinCode);
        OnPostReportOnBeforeLocationModify(Location);
        Location.Modify();

        if TempWhseJnlLine.Find('-') then
            repeat
                WhseJnlRegisterLine.RegisterWhseJnlLine(TempWhseJnlLine);
            until TempWhseJnlLine.Next() = 0;

        if not HideValidationDialog then begin
            Window.Close();
            Message(Text004);
        end;
    end;

    trigger OnPreReport()
    var
        GroupedItemLedgerEntries: Query "Grouped Item Ledger Entries";
        ErrorInfo: ErrorInfo;
        ItemNo: Code[20];
    begin
        Check();

        TempWhseJnlLine.Reset();
        TempWhseJnlLine.DeleteAll();
        LastLineNo := 0;
        ItemNo := '';
        Bin.Get(LocCode, AdjBinCode);

        if not HideValidationDialog then
            Window.Open(StrSubstNo(ProcessingTxt, LocCode) + ItemNoInProgressTxt);

        GroupedItemLedgerEntries.SetRange(Location_Code, LocCode);
        GroupedItemLedgerEntries.Open();
        while GroupedItemLedgerEntries.Read() do begin
            if not HideValidationDialog then
                if ItemNo <> GroupedItemLedgerEntries.Item_No then begin
                    Window.Update(100, GroupedItemLedgerEntries.Item_No);
                    ItemNo := GroupedItemLedgerEntries.Item_No;
                end;

            if GroupedItemLedgerEntries.Remaining_Quantity < 0 then begin
                ErrorInfo.ErrorType(ErrorType::Client);
                ErrorInfo.Verbosity(Verbosity::Error);
                ErrorInfo.Message(BuildErrorText(GroupedItemLedgerEntries));
                ErrorInfo.Title(NegativeInventoryErr);
                Error(ErrorInfo);
            end;

            if GroupedItemLedgerEntries.Remaining_Quantity > 0 then
                CreateWhseJnlLine(GroupedItemLedgerEntries);
        end;
    end;

    var
        TempWhseJnlLine: Record "Warehouse Journal Line" temporary;
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        Location: Record Location;
        Bin: Record Bin;
        WMSMgt: Codeunit "WMS Management";
        UOMMgt: Codeunit "Unit of Measure Management";
        Window: Dialog;
        LocCode: Code[10];
        AdjBinCode: Code[20];
        LastLineNo: Integer;
#pragma warning disable AA0074
        Text001: Label 'Enter a location code.';
        Text002: Label 'Enter an adjustment bin code.';
        Text004: Label 'The conversion was successfully completed.';
#pragma warning restore AA0074
        NegativeInventoryErr: Label 'Negative inventory was found in the location. You must clear this negative inventory in the program before you can proceed with the conversion.';
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text006: Label 'Location %1 cannot be converted because at least one %2 is not completely posted yet.\\Post or delete all of them before restarting the conversion batch job.';
        Text007: Label 'Location %1 cannot be converted because at least one %2 is not completely registered yet.\\Register or delete all of them before restarting the conversion batch job.';
        Text008: Label 'Location %1 cannot be converted because at least one %2 exists.\\Delete all of them before restarting the conversion batch job.';
#pragma warning restore AA0470
        Text010: Label 'Inventory exists on this location. By choosing Yes from this warning, you are confirming that you want to enable this location to use Warehouse Management Systems by running a batch job to create warehouse entries for the inventory in this location.\\';
        Text011: Label 'If you want to proceed, you must first ensure that no negative inventory exists in the location. Negative inventory is not allowed in a location that uses warehouse management logic and must be cleared by posting a suitable quantity to inventory. ';
        Text012: Label 'You can perform a check for negative inventory by using the Items with Negative Inventory report.\\';
        Text013: Label 'If you can confirm that no negative inventory exists in the location, proceed with the conversion batch job. If negative inventory is found, the batch job will stop with an error message. ';
        Text014: Label 'The result of this batch job is that initial warehouse entries will be created. You must balance these initial warehouse entries on the adjustment bin by posting a warehouse physical inventory journal or a warehouse item journal to assign zones and bins to items.\';
        Text015: Label 'You must create zones and bins before posting a warehouse physical inventory.\\';
#pragma warning disable AA0470
        Text016: Label 'Location %1 will be a warehouse management location after the batch job has run successfully. This conversion cannot be reversed or undone after it has run.';
#pragma warning restore AA0470
        Text017: Label '\\Do you really want to proceed?';
#pragma warning disable AA0470
        Text018: Label 'There is nothing to convert for %1 %2 ''%3''.';
        Text019: Label 'Location %1 cannot be converted because at least one %2 exists for this location.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        ProcessingTxt: Label 'Location %1 is being converted to a directed put-away and pick location.\\This might take some time so please be patient.\\', Comment = '%1: Location Code';
        ItemNoInProgressTxt: Label 'Processing item number #100##################.', Comment = '#100 - Item No.';
        ErrorInfoTxt: Label '%1: %2', Locked = true, Comment = '%1: FieldCaption, %2: FieldValue';

    protected var
        HideValidationDialog: Boolean;

    local procedure Check()
    var
        WhseEntry: Record "Warehouse Entry";
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        if LocCode = '' then
            Error(Text001);
        if AdjBinCode = '' then
            Error(Text002);

        ItemLedgEntry.Reset();
        ItemLedgEntry.SetRange("Location Code", LocCode);
        ItemLedgEntry.SetRange(Open, true);
        if not ItemLedgEntry.IsEmpty() then begin
            if not HideValidationDialog then
                if not Confirm(StrSubstNo('%1 %2 %3 %4 %5 %6 %7 %8',
                       Text010, Text011, Text012, Text013, Text014,
                       Text015, StrSubstNo(Text016, LocCode), Text017), false)
                then
                    CurrReport.Quit();
        end else
            Error(Text018, Location.TableCaption(), Location.FieldCaption(Code), LocCode);

        WhseEntry.SetRange("Location Code", LocCode);
        if not WhseEntry.IsEmpty() then
            Error(Text019, LocCode, WhseEntry.TableCaption());

        Location.Get(LocCode);
        Location.TestField("Adjustment Bin Code", '');
        CheckWhseDocs();
    end;

    local procedure CheckWhseDocs()
    var
        WhseRcptHeader: Record "Warehouse Receipt Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WhseActivHeader: Record "Warehouse Activity Header";
        WhseWkshLine: Record "Whse. Worksheet Line";
    begin
        WhseRcptHeader.SetRange("Location Code", Location.Code);
        if not WhseRcptHeader.IsEmpty() then
            Error(
              Text006,
              Location.Code,
              WhseRcptHeader.TableCaption());

        WarehouseShipmentHeader.SetRange("Location Code", Location.Code);
        if not WarehouseShipmentHeader.IsEmpty() then
            Error(
              Text006,
              Location.Code,
              WarehouseShipmentHeader.TableCaption());

        WhseActivHeader.SetCurrentKey("Location Code");
        WhseActivHeader.SetRange("Location Code", Location.Code);
        if WhseActivHeader.FindFirst() then
            Error(
              Text007,
              Location.Code,
              WhseActivHeader.Type);

        WhseWkshLine.SetRange("Location Code", Location.Code);
        if not WhseWkshLine.IsEmpty() then
            Error(
              Text008,
              Location.Code,
              WhseWkshLine.TableCaption());
    end;

    local procedure CreateWhseJnlLine(GroupedItemLedgerEntries: Query "Grouped Item Ledger Entries")
    begin
        LastLineNo += 10000;

        TempWhseJnlLine.Init();
        TempWhseJnlLine."Entry Type" := TempWhseJnlLine."Entry Type"::"Positive Adjmt.";
        TempWhseJnlLine."Line No." := LastLineNo;
        TempWhseJnlLine."Location Code" := GroupedItemLedgerEntries.Location_Code;
        TempWhseJnlLine."Item No." := GroupedItemLedgerEntries.Item_No;
        TempWhseJnlLine."Variant Code" := GroupedItemLedgerEntries.Variant_Code;

        TempWhseJnlLine."Unit of Measure Code" := GroupedItemLedgerEntries.Unit_of_Measure_Code;
        if TempWhseJnlLine."Unit of Measure Code" = '' then begin
            GetItem(GroupedItemLedgerEntries.Item_No);
            TempWhseJnlLine."Unit of Measure Code" := Item."Base Unit of Measure";
        end;
        GetItemUnitOfMeasure(GroupedItemLedgerEntries.Item_No, GroupedItemLedgerEntries.Unit_of_Measure_Code);

        TempWhseJnlLine.Quantity := UOMMgt.CalcQtyFromBase(GroupedItemLedgerEntries.Remaining_Quantity, ItemUnitOfMeasure."Qty. per Unit of Measure");
        TempWhseJnlLine."Qty. (Base)" := GroupedItemLedgerEntries.Remaining_Quantity;
        TempWhseJnlLine."Qty. (Absolute)" := Abs(TempWhseJnlLine.Quantity);
        TempWhseJnlLine."Qty. (Absolute, Base)" := Abs(TempWhseJnlLine."Qty. (Base)");
        TempWhseJnlLine.Cubage := TempWhseJnlLine."Qty. (Absolute)" * ItemUnitOfMeasure.Cubage;
        TempWhseJnlLine.Weight := TempWhseJnlLine."Qty. (Absolute)" * ItemUnitOfMeasure.Weight;

        TempWhseJnlLine."Serial No." := GroupedItemLedgerEntries.Serial_No_;
        TempWhseJnlLine."Lot No." := GroupedItemLedgerEntries.Lot_No_;
        TempWhseJnlLine."Package No." := GroupedItemLedgerEntries.Package_No_;

        TempWhseJnlLine.Validate("Zone Code", Bin."Zone Code");
        TempWhseJnlLine."Bin Code" := AdjBinCode;
        TempWhseJnlLine."To Bin Code" := AdjBinCode;
        WMSMgt.CheckWhseJnlLine(TempWhseJnlLine, 0, 0, false);

        TempWhseJnlLine."User ID" := CopyStr(UserId(), 1, MaxStrLen(TempWhseJnlLine."User ID"));
        TempWhseJnlLine."Registering Date" := WorkDate();
        OnCreateWhseJnlLineOnBeforeTempWhseJnlLineInsert(TempWhseJnlLine);
        TempWhseJnlLine.Insert();
    end;

    local procedure GetItem(ItemNo: Code[20])
    begin
        if Item."No." <> ItemNo then
            Item.Get(ItemNo);
    end;

    local procedure GetItemUnitOfMeasure(ItemNo: Code[20]; UOMCode: Code[10])
    begin
        if (ItemUnitOfMeasure."Item No." <> ItemNo) or
           (ItemUnitOfMeasure.Code <> UOMCode)
        then
            if not ItemUnitOfMeasure.Get(ItemNo, UOMCode) then
                ItemUnitOfMeasure.Init();
    end;

    local procedure BuildErrorText(GroupedItemLedgerEntries: Query "Grouped Item Ledger Entries"): Text
    var
        ErrorText: TextBuilder;
    begin
        ErrorText.AppendLine(StrSubstNo(ErrorInfoTxt, GroupedItemLedgerEntries.ColumnCaption(Location_Code), GroupedItemLedgerEntries.Location_Code));
        ErrorText.AppendLine(StrSubstNo(ErrorInfoTxt, GroupedItemLedgerEntries.ColumnCaption(Item_No), GroupedItemLedgerEntries.Item_No));
        if GroupedItemLedgerEntries.Variant_Code <> '' then
            ErrorText.AppendLine(StrSubstNo(ErrorInfoTxt, GroupedItemLedgerEntries.ColumnCaption(Variant_Code), GroupedItemLedgerEntries.Variant_Code));
        if GroupedItemLedgerEntries.Unit_of_Measure_Code <> '' then
            ErrorText.AppendLine(StrSubstNo(ErrorInfoTxt, GroupedItemLedgerEntries.ColumnCaption(Unit_of_Measure_Code), GroupedItemLedgerEntries.Unit_of_Measure_Code));
        if GroupedItemLedgerEntries.Lot_No_ <> '' then
            ErrorText.AppendLine(StrSubstNo(ErrorInfoTxt, GroupedItemLedgerEntries.ColumnCaption(Lot_No_), GroupedItemLedgerEntries.Lot_No_));
        if GroupedItemLedgerEntries.Serial_No_ <> '' then
            ErrorText.AppendLine(StrSubstNo(ErrorInfoTxt, GroupedItemLedgerEntries.ColumnCaption(Serial_No_), GroupedItemLedgerEntries.Serial_No_));
        if GroupedItemLedgerEntries.Package_No_ <> '' then
            ErrorText.AppendLine(StrSubstNo(ErrorInfoTxt, GroupedItemLedgerEntries.ColumnCaption(Package_No_), GroupedItemLedgerEntries.Package_No_));

        exit(ErrorText.ToText());
    end;

    procedure InitializeRequest(LocationCode: Code[10]; AdjustmentBinCode: Code[20])
    begin
        LocCode := LocationCode;
        AdjBinCode := AdjustmentBinCode;
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

#if not CLEAN25
    [Obsolete('This event is obsolete and will be removed in a future version.', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnCreateWhseJnlLineOnBeforeCheck(var WarehouseJournalLine: Record "Warehouse Journal Line"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnPostReportOnBeforeLocationModify(var Location: Record Location)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateWhseJnlLineOnBeforeTempWhseJnlLineInsert(var WarehouseJournalLine: Record "Warehouse Journal Line")
    begin
    end;
}

