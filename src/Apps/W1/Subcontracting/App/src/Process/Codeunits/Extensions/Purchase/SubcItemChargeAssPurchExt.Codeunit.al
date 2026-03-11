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
        SubcManagementSetup: Record "Subc. Management Setup";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Charge Assgnt. (Purch.)", OnBeforeCreateRcptChargeAssgnt, '', false, false)]
    local procedure "Item Charge Assgnt. (Purch.)_OnBeforeCreateRcptChargeAssgnt"(var FromPurchRcptLine: Record "Purch. Rcpt. Line"; ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"; var IsHandled: Boolean)
    begin
        if not SubcManagementSetup.ItemChargeToRcptSubReferenceEnabled() then
            exit;

        IsHandled := true;
        CreateRcptChargeAssgnt(FromPurchRcptLine, ItemChargeAssignmentPurch);
    end;

    local procedure CreateRcptChargeAssgnt(var FromPurchRcptLine: Record "Purch. Rcpt. Line"; ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)")
    var
        ItemChargeAssignmentPurch2: Record "Item Charge Assignment (Purch)";
        ItemChargeAssgntPurch: Codeunit "Item Charge Assgnt. (Purch.)";
        NextLine: Integer;
    begin
        NextLine := ItemChargeAssignmentPurch."Line No.";
        ItemChargeAssignmentPurch2.SetRange("Document Type", ItemChargeAssignmentPurch."Document Type");
        ItemChargeAssignmentPurch2.SetRange("Document No.", ItemChargeAssignmentPurch."Document No.");
        ItemChargeAssignmentPurch2.SetRange("Document Line No.", ItemChargeAssignmentPurch."Document Line No.");
        ItemChargeAssignmentPurch2.SetRange("Applies-to Doc. Type", "Purchase Applies-to Document Type"::Receipt);
        repeat
            ItemChargeAssignmentPurch2.SetRange("Applies-to Doc. No.", FromPurchRcptLine."Document No.");
            ItemChargeAssignmentPurch2.SetRange("Applies-to Doc. Line No.", FromPurchRcptLine."Line No.");
            if ItemChargeAssignmentPurch2.IsEmpty() then
                ItemChargeAssgntPurch.InsertItemChargeAssignment(
                    ItemChargeAssignmentPurch, "Purchase Applies-to Document Type"::Receipt,
                    FromPurchRcptLine."Document No.", FromPurchRcptLine."Line No.",
                    FromPurchRcptLine."No.", FromPurchRcptLine.Description, NextLine);
        until FromPurchRcptLine.Next() = 0;
    end;
}