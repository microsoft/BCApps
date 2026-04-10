// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Structure;

using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Document;

codeunit 7317 "Whse. Integration Management"
{

    trigger OnRun()
    begin
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%1 must not be the Adjustment Bin Code of the location %2.';
        Text001: Label 'The bin %1 is Dedicated.\Do you still want to use this bin?';
#pragma warning restore AA0470
        Text002: Label 'The update has been interrupted.';
#pragma warning disable AA0470
        Text003: Label 'Location %1 must be set up with Bin Mandatory if the %2 %3 uses it.', Comment = '%2 = Object No., %3 = Object No.';
#pragma warning restore AA0470
#pragma warning restore AA0074


    procedure CheckBinTypeAndCode(SourceTable: Integer; BinCodeFieldCaption: Text; LocationCode: Code[10]; BinCode: Code[20]; AdditionalIdentifier: Option)
    var
        BinType: Record "Bin Type";
        ItemJournalLine: Record "Item Journal Line";
        Location: Record Location;
        Bin: Record Bin;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckBinTypeAndCode(SourceTable, BinCodeFieldCaption, LocationCode, BinCode, AdditionalIdentifier, IsHandled);
        if IsHandled then
            exit;

        Location.Get(LocationCode);
        Location.TestField("Bin Mandatory");

        if not Location."Directed Put-away and Pick" then
            exit;

        if BinCode = Location."Adjustment Bin Code" then
            Error(Text000, BinCodeFieldCaption, LocationCode);

        IsHandled := false;
        OnCheckBinTypeCodeOnBeforeCheckPerSource(SourceTable, BinCodeFieldCaption, LocationCode, BinCode, AdditionalIdentifier, IsHandled);
        if IsHandled then
            exit;

        Bin.Get(LocationCode, BinCode);
        Bin.TestField("Bin Type Code");
        BinType.Get(Bin."Bin Type Code");
        case SourceTable of
            Database::"Warehouse Shipment Header",
            Database::"Warehouse Shipment Line":
                BinType.TestField(Ship, true);
            Database::"Warehouse Receipt Header",
            Database::"Warehouse Receipt Line":
                BinType.TestField(Receive, true);
            Database::Location:
                case BinCodeFieldCaption of
                    Location.FieldCaption("Open Shop Floor Bin Code"),
                    Location.FieldCaption("To-Production Bin Code"),
                    Location.FieldCaption("To-Assembly Bin Code"),
                    Location.FieldCaption("To-Job Bin Code"):
                        BinType.AllowPutawayOrQCBinsOnly();
                    Location.FieldCaption("From-Production Bin Code"),
                    Location.FieldCaption("From-Assembly Bin Code"):
                        BinType.AllowPutawayPickOrQCBinsOnly();
                end;
            Database::"Item Journal Line":
                case AdditionalIdentifier of
                    ItemJournalLine."Entry Type"::Output.AsInteger():
                        BinType.AllowPutawayPickOrQCBinsOnly();
                    ItemJournalLine."Entry Type"::Consumption.AsInteger():
                        BinType.AllowPutawayOrQCBinsOnly();
                end;
            else
                OnCheckBinTypeAndCode(Location, Bin, BinType, SourceTable, BinCodeFieldCaption, AdditionalIdentifier);
        end;
    end;



    procedure CheckIfBinDedicatedOnSrcDoc(LocationCode: Code[10]; var BinCode: Code[20]; IssueWarning: Boolean)
    var
        Bin: Record Bin;
    begin
        if BinCode <> '' then
            if Bin.Get(LocationCode, BinCode) then
                if Bin.Dedicated then
                    if IssueWarning then begin
                        if not
                           Confirm(
                             StrSubstNo(Text001, BinCode), false)
                        then
                            Error(Text002)
                    end else
                        BinCode := '';
    end;


    procedure CheckBinCodeForLocation(LocationCode: Code[10]; BinCode: Code[20]; BinCaption: Text; Number: Code[20])
    var
        Bin: Record Bin;
        Location: Record Location;
    begin
        if BinCode <> '' then begin
            Location.Get(LocationCode);
            if not Location."Bin Mandatory" then
                Error(Text003, Location.Code, Location.TableCaption(), Number);
            Bin.Get(LocationCode, BinCode);
            CheckBinTypeAndCode(Database::Location, BinCaption, LocationCode, BinCode, 0);
        end;
    end;


    procedure IsOpenShopFloorBin(LocationCode: Code[10]; BinCode: Code[20]) Result: Boolean
    var
        Location: Record Location;
    begin
        Location.Get(LocationCode);
        if BinCode = Location."Open Shop Floor Bin Code" then
            exit(true);

        OnAfterIsOpenShopFloorBin(LocationCode, BinCode, Result);
        exit(Result);
    end;





    [IntegrationEvent(false, false)]
    local procedure OnCheckBinTypeCodeOnBeforeCheckPerSource(SourceTable: Integer; BinCodeFieldCaption: Text; LocationCode: Code[10]; BinCode: Code[20]; AdditionalIdentifier: Option; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckBinTypeAndCode(Location: Record Location; Bin: Record Bin; BinType: Record "Bin Type"; SourceTable: Integer; BinCodeFieldCaption: Text; AdditionalIdentifier: Option)
    begin
    end;


    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBinTypeAndCode(SourceTable: Integer; BinCodeFieldCaption: Text; LocationCode: Code[10]; BinCode: Code[20]; AdditionalIdentifier: Option; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsOpenShopFloorBin(LocationCode: Code[10]; BinCode: Code[20]; var Result: Boolean);
    begin
    end;
}