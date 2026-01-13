// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;

codeunit 99001536 "Subc. ItemChargeAssPurchExt"
{
    var
        SubManagementSetup: Record "Subc. Management Setup";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Charge Assgnt. (Purch.)", OnBeforeCreateRcptChargeAssgnt, '', false, false)]
    local procedure "Item Charge Assgnt. (Purch.)_OnBeforeCreateRcptChargeAssgnt"(var FromPurchRcptLine: Record "Purch. Rcpt. Line"; ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"; var IsHandled: Boolean)
    begin
        if not SubManagementSetup.ItemChargeToRcptSubReferenceEnabled() then
            exit;

        IsHandled := true;
        CreateRcptChargeAssgnt(FromPurchRcptLine, ItemChargeAssignmentPurch);
    end;

    local procedure CreateRcptChargeAssgnt(var FromPurchRcptLine: Record "Purch. Rcpt. Line"; ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)")
    var
        ItemChargeAssgntPurch2: Record "Item Charge Assignment (Purch)";
        ItemChargeAssgntPurchCU: Codeunit "Item Charge Assgnt. (Purch.)";
        NextLine: Integer;
    begin
        NextLine := ItemChargeAssgntPurch."Line No.";
        ItemChargeAssgntPurch2.SetRange("Document Type", ItemChargeAssgntPurch."Document Type");
        ItemChargeAssgntPurch2.SetRange("Document No.", ItemChargeAssgntPurch."Document No.");
        ItemChargeAssgntPurch2.SetRange("Document Line No.", ItemChargeAssgntPurch."Document Line No.");
        ItemChargeAssgntPurch2.SetRange("Applies-to Doc. Type", "Purchase Applies-to Document Type"::Receipt);
        repeat
            ItemChargeAssgntPurch2.SetRange("Applies-to Doc. No.", FromPurchRcptLine."Document No.");
            ItemChargeAssgntPurch2.SetRange("Applies-to Doc. Line No.", FromPurchRcptLine."Line No.");
            if ItemChargeAssgntPurch2.IsEmpty() then
                ItemChargeAssgntPurchCU.InsertItemChargeAssignment(
                    ItemChargeAssgntPurch, "Purchase Applies-to Document Type"::Receipt,
                    FromPurchRcptLine."Document No.", FromPurchRcptLine."Line No.",
                    FromPurchRcptLine."No.", FromPurchRcptLine.Description, NextLine);
        until FromPurchRcptLine.Next() = 0;
    end;
}