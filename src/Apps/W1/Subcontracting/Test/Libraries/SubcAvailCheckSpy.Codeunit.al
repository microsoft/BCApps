// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Transfer;

/// <summary>
/// Test spy that records whether the standard item-availability check ("Item-Check Avail.")
/// was performed for a transfer line. Used to assert that WIP item transfer lines do NOT trigger
/// the availability warning path when their quantity is edited through the Transfer Order page.
/// </summary>
codeunit 149913 "Subc. Avail. Check Spy"
{
    SingleInstance = true;
    EventSubscriberInstance = Manual;

    var
        InvokedItemNo: Code[20];
        Invoked: Boolean;

    /// <summary>
    /// Resets the recorded availability-check state before a test action runs.
    /// </summary>
    procedure Reset()
    begin
        Invoked := false;
        InvokedItemNo := '';
    end;

    /// <summary>
    /// Returns true when the availability-check event was raised for the specified item.
    /// </summary>
    /// <param name="ItemNo">The item number to compare with the recorded invocation.</param>
    /// <returns>True if the spy captured an availability-check invocation for the item; otherwise, false.</returns>
    procedure WasInvokedForItem(ItemNo: Code[20]): Boolean
    begin
        exit(Invoked and (InvokedItemNo = ItemNo));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item-Check Avail.", OnBeforeTransferLineShowWarning, '', false, false)]
    local procedure CaptureTransferLineAvailabilityCheck(TransferLine: Record "Transfer Line"; var IsWarning: Boolean; var IsHandled: Boolean)
    begin
        Invoked := true;
        InvokedItemNo := TransferLine."Item No.";
    end;
}
