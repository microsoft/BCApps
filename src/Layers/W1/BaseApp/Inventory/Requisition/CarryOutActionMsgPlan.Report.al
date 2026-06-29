// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Requisition;

using Microsoft.Foundation.Navigate;
using Microsoft.Inventory.Planning;
using Microsoft.Purchases.Document;

report 99001020 "Carry Out Action Msg. - Plan."
{
    Caption = 'Carry Out Action Msg. - Plan.';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Requisition Line"; "Requisition Line")
        {
#pragma warning disable AL0254
            DataItemTableView = sorting("Worksheet Template Name", "Journal Batch Name", "Vendor No.", "Sell-to Customer No.", "Ship-to Code", "Order Address Code", "Currency Code", "Ref. Order Type", "Ref. Order Status", "Ref. Order No.", "Low-Level Code", "Location Code", "Transfer-from Code");
#pragma warning restore AL0254
            RequestFilterHeading = 'Planning Line';

            trigger OnAfterGetRecord()
            begin
                OnBeforeRequisitionLineOnAfterGetRecord("Requisition Line", CombineTransferOrders);

                if not HideDialog then
                    WindowUpdate();

                if not "Accept Action Message" then
                    CurrReport.Skip();

                Commit();
                RunCarryOutActionsByRefOrderType("Requisition Line");
                Commit();

                OnAfterRequisitionLineOnAfterGetRecord("Requisition Line", ProdOrderChoice.AsInteger());
            end;

            trigger OnPostDataItem()
            begin
                if not HideDialog then
                    Window.Close();

                CarryOutAction.PrintTransferOrders();
                OnPostDataItemOnPrintOrders();

                if PurchOrderChoice in [PurchOrderChoice::"Make Purch. Orders",
                                        PurchOrderChoice::"Make Purch. Orders & Print"]
                then begin
                    SetRange("Accept Action Message", true);

                    if PurchaseSuggestionExists("Requisition Line") then begin
                        PurchOrderHeader."Order Date" := WorkDate();
                        PurchOrderHeader."Posting Date" := WorkDate();

                        EndOrderDate := WorkDate();

                        PrintOrders := (PurchOrderChoice = PurchOrderChoice::"Make Purch. Orders & Print");

                        Clear(ReqWkshMakeOrders);
                        ReqWkshMakeOrders.SetCreatedDocumentBuffer(TempDocumentEntry);
                        ReqWkshMakeOrders.Set(PurchOrderHeader, EndOrderDate, PrintOrders);
                        if not NoPlanningResiliency then
                            ReqWkshMakeOrders.SetPlanningResiliency();
                        ReqWkshMakeOrders.CarryOutBatchAction("Requisition Line");
                        CounterFailed := CounterFailed + ReqWkshMakeOrders.GetFailedCounter();
                    end;
                end;

                ShowResult();
            end;

            trigger OnPreDataItem()
            begin
                LockTable();

                SetReqLineFilters();
                if not Find('-') then
                    Error(Text000);

                if PurchOrderChoice = PurchOrderChoice::"Copy to Req. Wksh" then
                    CheckCopyToWksh(ReqWkshTemp, ReqWksh);
                if TransOrderChoice = TransOrderChoice::"Copy to Req. Wksh" then
                    CheckCopyToWksh(TransWkshTemp, TransWkshName);
                if ProdOrderChoice = ProdOrderChoice::"Copy to Req. Wksh" then
                    CheckCopyToWksh(ProdWkshTempl, ProdWkshName);

                if not HideDialog then
                    Window.Open(Text012);
                CheckPreconditions();
                CounterTotal := Count;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    group("Production Order")
                    {
                        Caption = 'Production Order';
                        field(ProductionOrder; ProdOrderChoice)
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Production Order';
                            ToolTip = 'Specifies that you want to create production orders for item with the Prod. Order replenishment system. You can select to create either planned or firm planned production order, and you can have the new order documents printed.';
                        }
                    }
                    group("Assembly Order")
                    {
                        Caption = 'Assembly Order';
                        field(AsmOrderChoice; AsmOrderChoice)
                        {
                            ApplicationArea = Assembly;
                            Caption = 'Assembly Order';
                            ToolTip = 'Specifies the assembly orders that are created for items with the Assembly replenishment method.';
                        }
                    }
                    group("Purchase Order")
                    {
                        Caption = 'Purchase Order';
                        field(PurchaseOrder; PurchOrderChoice)
                        {
                            ApplicationArea = Planning;
                            Caption = 'Purchase Order';
                            ToolTip = 'Specifies that you want to create purchase orders for items with the Purchase replenishment method. You can have the new order documents printed.';

                            trigger OnValidate()
                            begin
                                PurchOrderCopyToReqWksh := PurchOrderChoice = PurchOrderChoice::"Copy to Req. Wksh";
                            end;
                        }
                        group(Control10)
                        {
                            ShowCaption = false;
                            Visible = PurchOrderCopyToReqWksh;
                            field(ReqTemp; ReqWkshTemp)
                            {
                                ApplicationArea = Planning;
                                Caption = 'Req. Wksh. Template';
                                Enabled = true;
                                TableRelation = "Req. Wksh. Template";
                                ToolTip = 'Specifies that you want to copy the planning line proposals for transfer orders to this requisition worksheet template.';

                                trigger OnLookup(var Text: Text): Boolean
                                begin
                                    if PAGE.RunModal(PAGE::"Req. Worksheet Templates", ReqWkshTmpl) = ACTION::LookupOK then begin
                                        Text := ReqWkshTmpl.Name;
                                        exit(true);
                                    end;
                                    exit(false);
                                end;

                                trigger OnValidate()
                                begin
                                    ReqWksh := '';
                                end;
                            }
                            field(ReqName; ReqWksh)
                            {
                                ApplicationArea = Planning;
                                Caption = 'Req. Wksh. Name';
                                Enabled = true;
                                TableRelation = "Requisition Wksh. Name".Name;
                                ToolTip = 'Specifies that you want to copy the planning line proposals for transfer orders to this requisition worksheet name.';

                                trigger OnLookup(var Text: Text): Boolean
                                begin
                                    ReqWkshName.SetFilter("Worksheet Template Name", ReqWkshTemp);
                                    if PAGE.RunModal(PAGE::"Req. Wksh. Names", ReqWkshName) = ACTION::LookupOK then begin
                                        Text := ReqWkshName.Name;
                                        exit(true);
                                    end;
                                    exit(false);
                                end;
                            }
                        }
                    }
                    group("Transfer Order")
                    {
                        Caption = 'Transfer Order';
                        field(TransOrderChoice; TransOrderChoice)
                        {
                            ApplicationArea = Location;
                            Caption = 'Transfer Order';
                            ToolTip = 'Specifies that you want to create transfer orders for items with the Transfer replenishment method in the SKU card. You can have the new order documents printed.';

                            trigger OnValidate()
                            begin
                                TransOrderCopyToReqWksh := TransOrderChoice = TransOrderChoice::"Copy to Req. Wksh";
                            end;
                        }
                        group(Control3)
                        {
                            ShowCaption = false;
                            Visible = TransOrderCopyToReqWksh;
                            field(TransTemp; TransWkshTemp)
                            {
                                ApplicationArea = Planning;
                                Caption = 'Req. Wksh. Template';
                                Enabled = true;
                                TableRelation = "Req. Wksh. Template";
                                ToolTip = 'Specifies that you want to copy the planning line proposals for transfer orders to this requisition worksheet template.';

                                trigger OnLookup(var Text: Text): Boolean
                                begin
                                    if PAGE.RunModal(PAGE::"Req. Worksheet Templates", ReqWkshTmpl) = ACTION::LookupOK then begin
                                        Text := ReqWkshTmpl.Name;
                                        exit(true);
                                    end;
                                    exit(false);
                                end;

                                trigger OnValidate()
                                begin
                                    TransWkshName := '';
                                end;
                            }
                            field(TransName; TransWkshName)
                            {
                                ApplicationArea = Planning;
                                Caption = 'Req. Wksh. Name';
                                Enabled = true;
                                TableRelation = "Requisition Wksh. Name".Name;
                                ToolTip = 'Specifies that you want to copy the planning line proposals for transfer orders to this requisition worksheet name.';

                                trigger OnLookup(var Text: Text): Boolean
                                begin
                                    ReqWkshName.SetFilter("Worksheet Template Name", TransWkshTemp);
                                    if PAGE.RunModal(PAGE::"Req. Wksh. Names", ReqWkshName) = ACTION::LookupOK then begin
                                        Text := ReqWkshName.Name;
                                        exit(true);
                                    end;
                                    exit(false);
                                end;
                            }
                        }
                    }
                    field(CombineTransferOrders; CombineTransferOrders)
                    {
                        ApplicationArea = Location;
                        Caption = 'Combine Transfer Orders';
                        ToolTip = 'Specifies whether to combine transfer orders with other orders that are being sent to and from the same locations.';
                    }
                }
                field(NoPlanningResiliency; NoPlanningResiliency)
                {
                    ApplicationArea = Planning;
                    Caption = 'Stop and Show First Error';
                    ToolTip = 'Specifies whether to stop as soon as the batch job encounters an error.';
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            PurchOrderCopyToReqWksh := false;
            TransOrderCopyToReqWksh := false;
        end;

        trigger OnOpenPage()
        begin
            PurchOrderCopyToReqWksh := PurchOrderChoice = PurchOrderChoice::"Copy to Req. Wksh";
            TransOrderCopyToReqWksh := TransOrderChoice = TransOrderChoice::"Copy to Req. Wksh";
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        OnAfterInitReport();
    end;

    trigger OnPreReport()
    begin
        OnBeforePreReport();
    end;

    var
        PurchOrderHeader: Record "Purchase Header";
        ReqWkshTmpl: Record "Req. Wksh. Template";
        ReqWkshName: Record "Requisition Wksh. Name";
        ReqLineFilters: Record "Requisition Line";
        TempDocumentEntry: Record "Document Entry" temporary;
        CarryOutAction: Codeunit "Carry Out Action";
        ReqWkshMakeOrders: Codeunit "Req. Wksh.-Make Order";
        Window: Dialog;
        ReqWkshTemp: Code[10];
        ReqWksh: Code[10];
        TransWkshTemp: Code[10];
        TransWkshName: Code[10];
        ProdWkshTempl: Code[10];
        ProdWkshName: Code[10];
        PrintOrders: Boolean;
        CombineTransferOrders: Boolean;
        ReserveforPlannedProd: Boolean;
        HideDialog: Boolean;
        Counter: Integer;
        CounterTotal: Integer;
        CounterFailed: Integer;
        EndOrderDate: Date;
        PurchOrderCopyToReqWksh: Boolean;
        TransOrderCopyToReqWksh: Boolean;

#pragma warning disable AA0074
        Text000: Label 'There are no planning lines to make orders for.';
        Text007: Label 'This template and worksheet are currently active. ';
        Text008: Label 'You must select a different template name or worksheet name to copy to.';
        Text009: Label 'You must select a worksheet to copy to';
        Text010: Label 'Components were not reserved for orders with status Planned.';
#pragma warning disable AA0470
        Text011: Label 'You must make order for both line %1 and %2 because they are associated.';
        Text012: Label 'Carrying Out Actions  #1########## @2@@@@@@@@@@@@@';
        Text013: Label 'Not all Requisition Lines were carried out.\A total of %1 lines were not carried out because of errors encountered.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    protected var
        ProdOrderChoice: Enum Microsoft.Manufacturing.Document."Planning Create Prod. Order";
        PurchOrderChoice: Enum "Planning Create Purchase Order";
        TransOrderChoice: Enum "Planning Create Transfer Order";
        AsmOrderChoice: Enum "Planning Create Assembly Order";
        NoPlanningResiliency: Boolean;
        CurrReqWkshTemp: Code[10];
        CurrReqWkshName: Code[10];

    procedure CarryOutActions(SourceType: Enum "Planning Create Source Type"; Choice: Option; WkshTempl: Code[10]; WkshName: Code[10])
    begin
        if NoPlanningResiliency then begin
            CarryOutAction.SetParameters(SourceType, Choice, WkshTempl, WkshName);
            CarryOutAction.Run("Requisition Line");
        end else
            if not CarryOutAction.TryCarryOutAction(SourceType, "Requisition Line", Choice, WkshTempl, WkshName) then begin
                CounterFailed := CounterFailed + 1;
                OnCarryOutActionsOnAfterUpdateCounterFailed("Requisition Line", WkshTempl, WkshName);
            end;
    end;

    local procedure RunCarryOutActionsByRefOrderType(var RequisitionLine: Record "Requisition Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunCarryOutActionsByRefOrderType(RequisitionLine, PurchOrderChoice, ReqWkshTemp, ReqWksh, NoPlanningResiliency, CounterFailed, IsHandled);
        if IsHandled then
            exit;

        case RequisitionLine."Ref. Order Type" of
            RequisitionLine."Ref. Order Type"::"Prod. Order":
                if ProdOrderChoice <> ProdOrderChoice::" " then
                    CarryOutActions(Enum::"Planning Create Source Type"::Production, ProdOrderChoice.AsInteger(), ProdWkshTempl, ProdWkshName);
            RequisitionLine."Ref. Order Type"::Purchase:
                if PurchOrderChoice = PurchOrderChoice::"Copy to Req. Wksh" then
                    CarryOutActions(Enum::"Planning Create Source Type"::Purchase, PurchOrderChoice.AsInteger(), ReqWkshTemp, ReqWksh);
            RequisitionLine."Ref. Order Type"::Transfer:
                if TransOrderChoice <> TransOrderChoice::" " then begin
                    CarryOutAction.SetSplitTransferOrders(not CombineTransferOrders);
                    CarryOutActions(Enum::"Planning Create Source Type"::Transfer, TransOrderChoice.AsInteger(), TransWkshTemp, TransWkshName);
                end;
            RequisitionLine."Ref. Order Type"::Assembly:
                if AsmOrderChoice <> AsmOrderChoice::" " then
                    CarryOutActions(Enum::"Planning Create Source Type"::Assembly, AsmOrderChoice.AsInteger(), '', '');
            else
                CurrReport.Skip();
        end;
    end;

    procedure SetCreatedDocumentBuffer(var TempDocumentEntryNew: Record "Document Entry" temporary)
    begin
        TempDocumentEntry.Copy(TempDocumentEntryNew, true);
        CarryOutAction.SetCreatedDocumentBuffer(TempDocumentEntryNew);
    end;

    procedure SetReqWkshLine(var CurrentReqLine: Record "Requisition Line")
    begin
        CurrReqWkshTemp := CurrentReqLine."Worksheet Template Name";
        CurrReqWkshName := CurrentReqLine."Journal Batch Name";
        ReqLineFilters.Copy(CurrentReqLine);
    end;

    procedure SetDemandOrder(var ReqLine: Record "Requisition Line"; MfgUserTempl: Record "Manufacturing User Template")
    begin
        SetReqWkshLine(ReqLine);

        InitializeRequest(
          MfgUserTempl."Create Production Order".AsInteger(),
          MfgUserTempl."Create Purchase Order".AsInteger(),
          MfgUserTempl."Create Transfer Order".AsInteger(),
          MfgUserTempl."Create Assembly Order".AsInteger());

        ReqWkshTemp := MfgUserTempl."Purchase Req. Wksh. Template";
        ReqWksh := MfgUserTempl."Purchase Wksh. Name";
        ProdWkshTempl := MfgUserTempl."Prod. Req. Wksh. Template";
        ProdWkshName := MfgUserTempl."Prod. Wksh. Name";
        TransWkshTemp := MfgUserTempl."Transfer Req. Wksh. Template";
        TransWkshName := MfgUserTempl."Transfer Wksh. Name";

        case MfgUserTempl."Make Orders" of
            MfgUserTempl."Make Orders"::"The Active Line":
                begin
                    ReqLineFilters := ReqLine;
                    ReqLineFilters.SetRecFilter();
                end;
            MfgUserTempl."Make Orders"::"The Active Order":
                begin
                    ReqLineFilters.SetCurrentKey(
                      ReqLineFilters."User ID", ReqLineFilters."Demand Type", ReqLineFilters."Demand Subtype", ReqLineFilters."Demand Order No.", ReqLineFilters."Demand Line No.", ReqLineFilters."Demand Ref. No.");
                    ReqLineFilters.CopyFilters(ReqLine);
                    ReqLineFilters.SetRange(ReqLineFilters."Demand Type", ReqLine."Demand Type");
                    ReqLineFilters.SetRange(ReqLineFilters."Demand Subtype", ReqLine."Demand Subtype");
                    ReqLineFilters.SetRange(ReqLineFilters."Demand Order No.", ReqLine."Demand Order No.");
                end;
            MfgUserTempl."Make Orders"::"All Lines":
                begin
                    ReqLineFilters.SetCurrentKey(
                      ReqLineFilters."User ID", ReqLineFilters."Worksheet Template Name", ReqLineFilters."Journal Batch Name", ReqLineFilters."Line No.");
                    ReqLineFilters.Copy(ReqLine);
                end;
        end;

        OnAfterSetDemandOrder(ReqLine, MfgUserTempl, ReqLineFilters);
    end;

    procedure InitializeRequest(NewProdOrderChoice: Option; NewPurchOrderChoice: Option; NewTransOrderChoice: Option; NewAsmOrderChoice: Option)
    begin
        ProdOrderChoice := Enum::Microsoft.Manufacturing.Document."Planning Create Prod. Order".FromInteger(NewProdOrderChoice);
        PurchOrderChoice := Enum::"Planning Create Purchase Order".FromInteger(NewPurchOrderChoice);
        TransOrderChoice := Enum::"Planning Create Transfer Order".FromInteger(NewTransOrderChoice);
        AsmOrderChoice := Enum::"Planning Create Assembly Order".FromInteger(NewAsmOrderChoice);
    end;

    procedure InitializeRequest2(NewProdOrderChoice: Option; NewPurchOrderChoice: Option; NewTransOrderChoice: Option; NewAsmOrderChoice: Option; NewReqWkshTemp: Code[10]; NewReqWksh: Code[10]; NewTransWkshTemp: Code[10]; NewTransWkshName: Code[10])
    begin
        InitializeRequest(NewProdOrderChoice, NewPurchOrderChoice, NewTransOrderChoice, NewAsmOrderChoice);
        ReqWkshTemp := NewReqWkshTemp;
        ReqWksh := NewReqWksh;
        TransWkshTemp := NewTransWkshTemp;
        TransWkshName := NewTransWkshName;
    end;

    procedure SetHideDialog(NewHideDialog: Boolean)
    begin
        HideDialog := NewHideDialog;
    end;

    local procedure SetReqLineFilters()
    begin
        if ReqLineFilters.GetFilters <> '' then
            "Requisition Line".CopyFilters(ReqLineFilters);
        "Requisition Line".SetRange("Worksheet Template Name", CurrReqWkshTemp);
        if CurrReqWkshTemp <> '' then
            "Requisition Line".SetRange("Journal Batch Name", CurrReqWkshName);
        "Requisition Line".FilterGroup(2);
        "Requisition Line".SetRange(Type, "Requisition Line".Type::Item);
        "Requisition Line".SetFilter("Action Message", '<>%1', "Requisition Line"."Action Message"::" ");
        "Requisition Line".FilterGroup(0);
        OnAfterSetReqLineFilters("Requisition Line");
    end;

    local procedure CheckCopyToWksh(ToReqWkshTempl: Code[10]; ToReqWkshName: Code[10])
    begin
        if (ToReqWkshTempl <> '') and
           (CurrReqWkshTemp = ToReqWkshTempl) and
           (CurrReqWkshName = ToReqWkshName)
        then
            Error(Text007 + Text008);

        if (ToReqWkshTempl = '') or (ToReqWkshName = '') then
            Error(Text009);
    end;

    local procedure CheckPreconditions()
    begin
        repeat
            CheckLine();
        until "Requisition Line".Next() = 0;
    end;

    local procedure CheckLine()
    var
        ReqLine2: Record "Requisition Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckLine("Requisition Line", PurchOrderChoice.AsInteger(), TransOrderChoice.AsInteger(), IsHandled);
        if IsHandled then
            exit;

        if "Requisition Line"."Planning Line Origin" <> "Requisition Line"."Planning Line Origin"::"Order Planning" then
            exit;

        CheckAssociations("Requisition Line");

        if "Requisition Line"."Planning Level" > 0 then
            exit;

        CheckSupplyFrom();

        CheckDemandType();

        ReqLine2.ReadIsolation := ReqLine2.ReadIsolation::ReadUncommitted;
        ReqLine2.SetFilter("User ID", '<>%1', UserId);
        ReqLine2.SetRange("Demand Type", "Requisition Line"."Demand Type");
        ReqLine2.SetRange("Demand Subtype", "Requisition Line"."Demand Subtype");
        ReqLine2.SetRange("Demand Order No.", "Requisition Line"."Demand Order No.");
        ReqLine2.SetRange("Demand Line No.", "Requisition Line"."Demand Line No.");
        ReqLine2.SetRange("Demand Ref. No.", "Requisition Line"."Demand Ref. No.");
        if not ReqLine2.IsEmpty then
            ReqLine2.DeleteAll(true);
    end;

    local procedure CheckDemandType()
    begin
        OnCheckDemandType("Requisition Line");
    end;

    local procedure CheckAssociations(var ReqLine: Record "Requisition Line")
    var
        ReqLine2: Record "Requisition Line";
        ReqLine3: Record "Requisition Line";
    begin
        ReqLine3.Copy(ReqLine);
        ReqLine2 := ReqLine;

        if ReqLine2."Planning Level" > 0 then
            while (ReqLine2.Next(-1) <> 0) and (ReqLine2."Planning Level" > 0) do;

        repeat
            ReqLine3 := ReqLine2;
            if not ReqLine3.Find() then
                Error(Text011, ReqLine."Line No.", ReqLine2."Line No.");
        until (ReqLine2.Next() = 0) or (ReqLine2."Planning Level" = 0)
    end;

    local procedure CheckSupplyFrom()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckSupplyFrom("Requisition Line", PurchOrderChoice.AsInteger(), TransOrderChoice.AsInteger(), IsHandled);
        if IsHandled then
            exit;

        if "Requisition Line"."Replenishment System" in ["Requisition Line"."Replenishment System"::Purchase, "Requisition Line"."Replenishment System"::Transfer] then
            "Requisition Line".TestField("Requisition Line"."Supply From");
    end;

    local procedure ShowResult()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowResult(IsHandled);
        if IsHandled then
            exit;

        if ReserveforPlannedProd then
            Message(Text010);

        if CounterFailed > 0 then
            if GetLastErrorText() = '' then
                Message(Text013, CounterFailed)
            else
                Message(GetLastErrorText);
    end;

    local procedure WindowUpdate()
    begin
        Counter := Counter + 1;
        Window.Update(1, "Requisition Line"."No.");
        Window.Update(2, Round(Counter / CounterTotal * 10000, 1));
    end;

    local procedure PurchaseSuggestionExists(var RequisitionLine: Record "Requisition Line"): Boolean
    var
        StopLoop: Boolean;
        PurchaseExists: Boolean;
    begin
        if RequisitionLine.FindSet() then
            repeat
                PurchaseExists := RequisitionLine."Ref. Order Type" = RequisitionLine."Ref. Order Type"::Purchase;
                if not PurchaseExists then
                    StopLoop := RequisitionLine.Next() = 0
                else
                    StopLoop := true;
            until StopLoop;
        if PurchaseExists then
            RequisitionLine.SetRange("Ref. Order Type", RequisitionLine."Ref. Order Type"::Purchase);
        exit(PurchaseExists);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetDemandOrder(var RequisitionLine: Record "Requisition Line"; MfgUserTempl: Record "Manufacturing User Template"; var ReqLineFilters: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetReqLineFilters(var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckSupplyFrom(RequisitionLine: Record "Requisition Line"; PurchOrderChoice: Option " ","Make Purch. Orders","Make Purch. Orders & Print","Copy to Req. Wksh"; TransOrderChoice: Option " ","Make Trans. Orders","Make Trans. Orders & Print","Copy to Req. Wksh"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckLine(RequisitionLine: Record "Requisition Line"; PurchOrderChoice: Option " ","Make Purch. Orders","Make Purch. Orders & Print","Copy to Req. Wksh"; TransOrderChoice: Option " ","Make Trans. Orders","Make Trans. Orders & Print","Copy to Req. Wksh"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforePreReport()
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeRunCarryOutActionsByRefOrderType(var RequisitionLine: Record "Requisition Line"; PurchOrderChoice: Enum "Planning Create Purchase Order"; ReqWkshTemp: Code[10]; ReqWksh: Code[10]; NoPlanningResiliency: Boolean; var CounterFailed: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRequisitionLineOnAfterGetRecord(var RequisitionLine: Record "Requisition Line"; var CombineTransferOrders: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeShowResult(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRequisitionLineOnAfterGetRecord(var RequisitionLine: Record "Requisition Line"; ProdOrderChoice: Option)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterInitReport()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCarryOutActionsOnAfterUpdateCounterFailed(var RequisitionLine: Record "Requisition Line"; WkshTempl: Code[10]; WkshName: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckDemandType(RequisitionLine: Record "Requisition Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDataItemOnPrintOrders()
    begin
    end;
}

