// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Inventory.Requisition;

codeunit 139999 "Subc. Keep Carried Out ReqLine"
{
    EventSubscriberInstance = Manual;

    var
        TempKeptRequisitionLine: Record "Requisition Line" temporary;

    /// <summary>
    /// Returns whether the before-delete event for carried-out lines was handled for the given requisition line.
    /// </summary>
    /// <param name="RequisitionLine">The requisition line to look for.</param>
    /// <returns>True if the line was kept by this subscriber; otherwise, false.</returns>
    procedure WasKept(RequisitionLine: Record "Requisition Line"): Boolean
    begin
        exit(TempKeptRequisitionLine.Get(RequisitionLine."Worksheet Template Name", RequisitionLine."Journal Batch Name", RequisitionLine."Line No."));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Req. Wksh.-Make Order", OnFinalizeOrderHeaderOnBeforeReqLine2Delete, '', false, false)]
    local procedure KeepCarriedOutLineOnFinalizeOrderHeaderOnBeforeReqLine2Delete(var RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
        TempKeptRequisitionLine := RequisitionLine;
        if TempKeptRequisitionLine.Insert() then;
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Req. Wksh.-Make Order", OnBeforeDeleteReqLines, '', false, false)]
    local procedure KeepRemainingLinesOnBeforeDeleteReqLines(var IsHandled: Boolean)
    begin
        IsHandled := true;
    end;
}