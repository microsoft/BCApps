// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Transfer;

codeunit 99001545 "Subc. TransferPost Ext"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post (Yes/No)", OnCodeOnBeforePostTransferOrder, '', false, false)]
    local procedure OnCodeOnBeforePostTransferOrder(var TransHeader: Record "Transfer Header"; var IsHandled: Boolean)
    begin
        OverrideDefaultTransferPosting(TransHeader, IsHandled);
    end;

    local procedure OverrideDefaultTransferPosting(var TransferHeader: Record "Transfer Header"; var IsHandled: Boolean)
    var
        TransferOrderPostReceipt: Codeunit "TransferOrder-Post Receipt";
        TransferOrderPostShipment: Codeunit "TransferOrder-Post Shipment";
        TransferOrderPostTransfer: Codeunit "TransferOrder-Post Transfer";
    begin
        case TransferHeader."Direct Transfer Posting" of
            TransferHeader."Direct Transfer Posting"::"Receipt and Shipment":
                begin
                    TransferOrderPostShipment.Run(TransferHeader);
                    TransferOrderPostReceipt.Run(TransferHeader);
                end;
            TransferHeader."Direct Transfer Posting"::"Direct Transfer":
                TransferOrderPostTransfer.Run(TransferHeader);
            TransferHeader."Direct Transfer Posting"::Empty:
                exit;
        end;

        IsHandled := true;
    end;
}