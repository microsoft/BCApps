// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Transfer;

using Microsoft.Inventory.Setup;

codeunit 5707 "TransferOrder-Post + Print"
{
    TableNo = "Transfer Header";

    trigger OnRun()
    begin
        TransHeader.Copy(Rec);
        Code();
        Rec := TransHeader;
    end;

    var
        TransHeader: Record "Transfer Header";

#pragma warning disable AA0074
        Text000: Label '&Ship,&Receive';
#pragma warning restore AA0074

    local procedure "Code"()
    var
        InventorySetup: Record "Inventory Setup";
        TransLine: Record "Transfer Line";
        TransferPostShipment: Codeunit "TransferOrder-Post Shipment";
        TransferPostReceipt: Codeunit "TransferOrder-Post Receipt";
        TransferPostTransfer: Codeunit "TransferOrder-Post Transfer";
        DefaultNumber: Integer;
        Selection: Option " ",Shipment,Receipt;
        IsHandled: Boolean;
    begin
        OnBeforePost(TransHeader, IsHandled, TransferPostShipment, TransferPostReceipt);
        if IsHandled then
            exit;

        DefaultNumber := 0;
        TransLine.SetRange("Document No.", TransHeader."No.");
        if TransLine.Find('-') then
            repeat
                if (TransLine."Quantity Shipped" < TransLine.Quantity) and
                   (DefaultNumber = 0)
                then
                    DefaultNumber := Selection::Shipment;
                if (TransLine."Quantity Received" < TransLine.Quantity) and
                   (DefaultNumber = 0)
                then
                    DefaultNumber := Selection::Receipt;
            until (TransLine.Next() = 0) or (DefaultNumber > 0);

        IsHandled := false;
        OnRunOnBeforePrepareAndPrintReport(TransHeader, DefaultNumber, Selection, IsHandled);
        if not IsHandled then
            if TransHeader."Direct Transfer" then begin
                InventorySetup.Get();
                if InventorySetup."Direct Transfer Posting" = InventorySetup."Direct Transfer Posting"::"Receipt and Shipment" then begin
                    TransferPostShipment.Run(TransHeader);
                    TransferPostReceipt.Run(TransHeader);
                    PrintShipment(TransHeader."Last Shipment No.");
                    PrintReceipt(TransHeader."Last Receipt No.");
                end else begin
                    TransferPostTransfer.Run(TransHeader);
                    PrintDirectTransfer(TransHeader."Last Shipment No.");
                end;
            end else begin
                if DefaultNumber = 0 then
                    DefaultNumber := Selection::Shipment;
                Selection := StrMenu(Text000, DefaultNumber);
                case Selection of
                    0:
                        exit;
                    Selection::Shipment:
                        TransferPostShipment.Run(TransHeader);
                    Selection::Receipt:
                        TransferPostReceipt.Run(TransHeader);
                end;
                PrintReport(TransHeader, Selection);
            end;

        OnAfterPost(TransHeader, Selection);
    end;

    procedure PrintReport(TransHeaderSource: Record "Transfer Header"; Selection: Option " ",Shipment,Receipt)
    begin
        case Selection of
            Selection::Shipment:
                PrintShipment(TransHeaderSource."Last Shipment No.");
            Selection::Receipt:
                PrintReceipt(TransHeaderSource."Last Receipt No.");
        end;
    end;

    procedure PrintShipment(DocNo: Code[20])
    var
        TransShptHeader: Record "Transfer Shipment Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrintShipment(DocNo, IsHandled);
        if IsHandled then
            exit;

        if TransShptHeader.Get(DocNo) then begin
            TransShptHeader.SetRecFilter();
            TransShptHeader.PrintRecords(false);
        end;
    end;

    procedure PrintReceipt(DocNo: Code[20])
    var
        TransRcptHeader: Record "Transfer Receipt Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrintReceipt(DocNo, IsHandled);
        if IsHandled then
            exit;

        if TransRcptHeader.Get(DocNo) then begin
            TransRcptHeader.SetRecFilter();
            TransRcptHeader.PrintRecords(false);
        end;
    end;

    procedure PrintDirectTransfer(DocNo: Code[20])
    var
        DirectTransHeader: Record "Direct Trans. Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrintDirectTransfer(DocNo, IsHandled);
        if IsHandled then
            exit;

        if DirectTransHeader.Get(DocNo) then begin
            DirectTransHeader.SetRecFilter();
            DirectTransHeader.PrintRecords(false);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPost(var TransHeader: Record "Transfer Header"; Selection: Option " ",Shipment,Receipt)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePost(var TransHeader: Record "Transfer Header"; var IsHandled: Boolean; var TransferOrderPostShipment: Codeunit "TransferOrder-Post Shipment"; var TransferOrderPostReceipt: Codeunit "TransferOrder-Post Receipt")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintReceipt(DocNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintShipment(DocNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintDirectTransfer(DocNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforePrepareAndPrintReport(var TransferHeader: Record "Transfer Header"; var DefaultNumber: Integer; var Selection: Option; var IsHandled: Boolean)
    begin
    end;
}

