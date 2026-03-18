// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Request;

using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Sales.Document;
using Microsoft.Warehouse.Activity;

report 7323 "Create Invt Put-away/Pick/Mvmt"
{
    AccessByPermission = TableData Location = R;
    ApplicationArea = Warehouse;
    Caption = 'Create Inventory Put-away/Pick/Movement';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("Warehouse Request"; "Warehouse Request")
        {
            DataItemTableView = sorting("Source Document", "Source No.");
            RequestFilterFields = "Source Document", "Source No.", "Location Code";

            trigger OnAfterGetRecord()
            var
                ATOMvmntCreated: Integer;
                TotalATOMvmtToBeCreated: Integer;
            begin
                Window.Update(1, "Source Document");
                Window.Update(2, "Source No.");

                case Type of
                    Type::Inbound:
                        TotalPutAwayCounter += 1;
                    Type::Outbound:
                        if CreatePick then
                            TotalPickCounter += 1
                        else
                            TotalMovementCounter += 1;
                end;

                ReadIsolation := IsolationLevel::UpdLock;

                if CheckWhseRequest("Warehouse Request") then
                    CurrReport.Skip();

                if ((Type = Type::Inbound) and (WarehouseActivityHeader.Type <> WarehouseActivityHeader.Type::"Invt. Put-away")) or
                   ((Type = Type::Outbound) and ((WarehouseActivityHeader.Type <> WarehouseActivityHeader.Type::"Invt. Pick") and
                                                 (WarehouseActivityHeader.Type <> WarehouseActivityHeader.Type::"Invt. Movement"))) or
                   ("Source Type" <> WarehouseActivityHeader."Source Type") or
                   ("Source Subtype" <> WarehouseActivityHeader."Source Subtype") or
                   ("Source No." <> WarehouseActivityHeader."Source No.") or
                   ("Location Code" <> WarehouseActivityHeader."Location Code")
                then begin
                    case Type of
                        Type::Inbound:
                            if not CreateInvtPutAway.CheckSourceDoc("Warehouse Request") then
                                CurrReport.Skip();
                        Type::Outbound:
                            if not CreateInvtPickMovement.CheckSourceDoc("Warehouse Request") then
                                CurrReport.Skip();
                    end;
                    InitWhseActivHeader();
                end;

                case Type of
                    Type::Inbound:
                        begin
                            CreateInvtPutAway.SetWhseRequest("Warehouse Request", true);
                            CreateInvtPutAway.AutoCreatePutAway(WarehouseActivityHeader);
                        end;
                    Type::Outbound:
                        begin
                            CreateInvtPickMovement.SetWhseRequest("Warehouse Request", true);
                            CreateInvtPickMovement.AutoCreatePickOrMove(WarehouseActivityHeader);
                        end;
                end;

                if WarehouseActivityHeader."No." <> '' then begin
                    DocumentCreated := true;
                    case Type of
                        Type::Inbound:
                            PutAwayCounter := PutAwayCounter + 1;
                        Type::Outbound:
                            if CreatePick then begin
                                PickCounter := PickCounter + 1;

                                CreateInvtPickMovement.GetATOMovementsCounters(ATOMvmntCreated, TotalATOMvmtToBeCreated);
                                MovementCounter += ATOMvmntCreated;
                                TotalMovementCounter += TotalATOMvmtToBeCreated;
                            end else
                                MovementCounter += 1;
                    end;
                    if PrintDocument then
                        InsertTempWhseActivHdr();
                    Commit();
                end;
            end;

            trigger OnPostDataItem()
            var
                ExpiredItemMessageText: Text[100];
                Msg: Text;
            begin
                ExpiredItemMessageText := CreateInvtPickMovement.GetExpiredItemMessage();
                if TempWarehouseActivityHeader.Find('-') then
                    PrintNewDocuments();

                Window.Close();
                if not SuppressMessagesState then
                    if DocumentCreated then begin
                        if PutAwayCounter > 0 then
                            AddToText(Msg, StrSubstNo(Text005, WarehouseActivityHeader.Type::"Invt. Put-away", PutAwayCounter, TotalPutAwayCounter));
                        if PickCounter > 0 then
                            AddToText(Msg, StrSubstNo(Text005, WarehouseActivityHeader.Type::"Invt. Pick", PickCounter, TotalPickCounter));
                        if MovementCounter > 0 then
                            AddToText(Msg, StrSubstNo(Text005, WarehouseActivityHeader.Type::"Invt. Movement", MovementCounter, TotalMovementCounter));

                        if CreatePutAway or CreatePick then
                            Msg += ExpiredItemMessageText;

                        Message(Msg);
                    end else begin
                        Msg := Text004 + ' ' + ExpiredItemMessageText;
                        Message(Msg);
                    end;
            end;

            trigger OnPreDataItem()
            begin
                if CreatePutAway and not (CreatePick or CreateMovement) then
                    SetRange(Type, Type::Inbound);
                if not CreatePutAway and (CreatePick or CreateMovement) then
                    SetRange(Type, Type::Outbound);

                Window.Open(
                  Text001 +
                  Text002 +
                  Text003);

                DocumentCreated := false;

                if CreatePick or CreateMovement then
                    CreateInvtPickMovement.SetReportGlobals(PrintDocument, ShowError, ReservedFromStock);

                CreateInvtPickMovement.SetSourceDocDetailsFilter("Warehouse Source Filter");
                CreateInvtPutAway.SetSourceDocDetailsFilter("Warehouse Source Filter");
            end;
        }
        dataitem("Warehouse Source Filter"; "Warehouse Source Filter")
        {
            DataItemTableView = sorting(Type, Code);
            RequestFilterFields = "Item No. Filter", "Variant Code Filter", "Shipment Date Filter", "Receipt Date Filter", "Job No.", "Job Task No. Filter";
            RequestFilterHeading = 'Document details';
            UseTemporary = true;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group("Warehouse Documents")
                {
                    Caption = 'Warehouse Documents';

                    field(CreateInventorytPutAway; CreatePutAway)
                    {
                        Caption = 'Create Invt. Put-Away';
                        ToolTip = 'Specifies if you want to create inventory put-away documents for all source documents that are included in the filter and for which a put-away document is appropriate.';

                        trigger OnValidate()
                        begin
                            if not (CreatePick or CreateMovement) then
                                ReservedFromStock := ReservedFromStock::" ";
                        end;
                    }
                    field(CInvtPick; CreatePick)
                    {
                        Caption = 'Create Invt. Pick';
                        ToolTip = 'Specifies if you want to create inventory pick documents for all source documents that are included in the filter and for which a pick document is appropriate.';

                        trigger OnValidate()
                        begin
                            CreateMovement := false;
                            if not (CreatePick or CreateMovement) then
                                ReservedFromStock := ReservedFromStock::" ";
                        end;
                    }
                    field(CInvtMvmt; CreateMovement)
                    {
                        Caption = 'Create Invt. Movement';
                        ToolTip = 'Specifies if you want to create inventory movement documents for all source documents that are included in the filter and for which a movement document is appropriate.';

                        trigger OnValidate()
                        begin
                            CreatePick := false;
                            if not (CreatePick or CreateMovement) then
                                ReservedFromStock := ReservedFromStock::" ";
                        end;
                    }
                }
                group(Options)
                {
                    Caption = 'Options';

                    field("Reserved From Stock"; ReservedFromStock)
                    {
                        Caption = 'Reserved from stock';
                        ToolTip = 'Specifies if you want to include only source document lines that are fully or partially reserved from current stock.';
                        ValuesAllowed = " ", "Full and Partial", Full;

                        trigger OnValidate()
                        begin
                            if CreatePutAway and not (CreatePick or CreateMovement) then
                                ReservedFromStock := ReservedFromStock::" ";
                        end;
                    }
                    field(PrintDocument; PrintDocument)
                    {
                        Caption = 'Print Document';
                        ToolTip = 'Specifies if you want the document to be printed.';
                    }
                    field(ShowError; ShowError)
                    {
                        Caption = 'Show Error';
                        ToolTip = 'Specifies if the report shows error information.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            OnBeforeOpenPage();
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        TempWarehouseActivityHeader.DeleteAll();
    end;

    trigger OnPreReport()
    begin
        if not (CreatePutAway or CreatePick or CreateMovement) then
            Error(Text008);

        CreateInvtPickMovement.SetInvtMovement(CreateMovement);
    end;

    var
        CreateInvtPutAway: Codeunit "Create Inventory Put-away";
        CreateInvtPickMovement: Codeunit "Create Inventory Pick/Movement";
        WhseDocPrint: Codeunit "Warehouse Document-Print";
        Window: Dialog;
        DocumentCreated: Boolean;
        PutAwayCounter: Integer;
        PickCounter: Integer;
        MovementCounter: Integer;
        TotalPutAwayCounter: Integer;
        TotalPickCounter: Integer;
        TotalMovementCounter: Integer;

#pragma warning disable AA0074
        Text001: Label 'Creating Inventory Activities...\\';
#pragma warning disable AA0470
        Text002: Label 'Source Type     #1##########\';
        Text003: Label 'Source No.      #2##########';
#pragma warning restore AA0470
        Text004: Label 'There is nothing to create.';
#pragma warning disable AA0470
        Text005: Label 'Number of %1 activities created: %2 out of a total of %3.';
#pragma warning restore AA0470
        Text006: Label '%1\\%2', Locked = true;
        Text008: Label 'You must select Create Invt. Put-away, Create Invt. Pick, or Create Invt. Movement.';
#pragma warning restore AA0074

    protected var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        TempWarehouseActivityHeader: Record "Warehouse Activity Header" temporary;
        ReservedFromStock: Enum "Reservation From Stock";
        CreatePutAway: Boolean;
        CreatePick: Boolean;
        CreateMovement: Boolean;
        PrintDocument: Boolean;
        ShowError: Boolean;
        SuppressMessagesState: Boolean;

    local procedure InitWhseActivHeader()
    begin
        WarehouseActivityHeader.Init();
        case "Warehouse Request".Type of
            "Warehouse Request".Type::Inbound:
                WarehouseActivityHeader.Type := WarehouseActivityHeader.Type::"Invt. Put-away";
            "Warehouse Request".Type::Outbound:
                if CreatePick then
                    WarehouseActivityHeader.Type := WarehouseActivityHeader.Type::"Invt. Pick"
                else
                    WarehouseActivityHeader.Type := WarehouseActivityHeader.Type::"Invt. Movement";
        end;
        WarehouseActivityHeader."No." := '';
        WarehouseActivityHeader."Location Code" := "Warehouse Request"."Location Code";

        OnAfterInitWhseActivHeader(WarehouseActivityHeader, "Warehouse Request");
    end;

    local procedure InsertTempWhseActivHdr()
    begin
        TempWarehouseActivityHeader.Init();
        TempWarehouseActivityHeader := WarehouseActivityHeader;
        TempWarehouseActivityHeader.Insert();
    end;

    local procedure PrintNewDocuments()
    begin
        repeat
            case TempWarehouseActivityHeader.Type of
                TempWarehouseActivityHeader.Type::"Invt. Put-away":
                    WhseDocPrint.PrintInvtPutAwayHeader(TempWarehouseActivityHeader, false);
                TempWarehouseActivityHeader.Type::"Invt. Pick":
                    WhseDocPrint.PrintInvtPickHeader(TempWarehouseActivityHeader, false);
                TempWarehouseActivityHeader.Type::"Invt. Movement":
                    WhseDocPrint.PrintInvtMovementHeader(TempWarehouseActivityHeader, false);
            end;
        until TempWarehouseActivityHeader.Next() = 0;
    end;

    local procedure CheckWhseRequest(var WarehouseRequest: Record "Warehouse Request") SkipRecord: Boolean
    var
        SalesHeader: Record "Sales Header";
        TransferHeader: Record "Transfer Header";
        GetSrcDocOutbound: Codeunit "Get Source Doc. Outbound";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckWhseRequest(WarehouseRequest, ShowError, SkipRecord, IsHandled);
        if IsHandled then
            exit(SkipRecord);

        if WarehouseRequest."Document Status" <> WarehouseRequest."Document Status"::Released then
            SkipRecord := true
        else
            if (WarehouseRequest.Type = WarehouseRequest.Type::Outbound) and
                (WarehouseRequest."Shipping Advice" = WarehouseRequest."Shipping Advice"::Complete)
            then
                case WarehouseRequest."Source Type" of
                    Database::"Sales Line":
                        if WarehouseRequest."Source Subtype" = WarehouseRequest."Source Subtype"::"1" then begin
                            SkipRecord := not SalesHeader.Get(SalesHeader."Document Type"::Order, WarehouseRequest."Source No.");
                            if not SkipRecord then
                                SkipRecord := GetSrcDocOutbound.CheckSalesHeader(SalesHeader, ShowError);
                        end;
                    Database::"Transfer Line":
                        begin
                            SkipRecord := not TransferHeader.Get(WarehouseRequest."Source No.");
                            if not SkipRecord then
                                SkipRecord := GetSrcDocOutbound.CheckTransferHeader(TransferHeader, ShowError);
                        end;
                end;
        OnAfterCheckWhseRequest(WarehouseRequest, SkipRecord);
    end;

    procedure InitializeRequest(NewCreateInvtPutAway: Boolean; NewCreateInvtPick: Boolean; NewCreateInvtMovement: Boolean; NewPrintDocument: Boolean; NewShowError: Boolean)
    begin
        CreatePutAway := NewCreateInvtPutAway;
        CreatePick := NewCreateInvtPick;
        CreateMovement := NewCreateInvtMovement;
        PrintDocument := NewPrintDocument;
        ShowError := NewShowError;
    end;

    procedure SuppressMessages(NewState: Boolean)
    begin
        SuppressMessagesState := NewState;
    end;

    local procedure AddToText(var OrigText: Text; Addendum: Text)
    begin
        if OrigText = '' then
            OrigText := Addendum
        else
            OrigText := StrSubstNo(Text006, OrigText, Addendum);
    end;

    procedure GetMovementCounters(var MovementsCreated: Integer; var TotalMovementsToBeCreated: Integer)
    begin
        MovementsCreated := MovementCounter;
        TotalMovementsToBeCreated := TotalMovementCounter;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckWhseRequest(var WarehouseRequest: Record "Warehouse Request"; var SkipRecord: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitWhseActivHeader(var WarehouseActivityHeader: Record "Warehouse Activity Header"; var WarehouseRequest: Record "Warehouse Request")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckWhseRequest(var WarehouseRequest: Record "Warehouse Request"; ShowError: Boolean; var SkipRecord: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenPage()
    begin
    end;
}

