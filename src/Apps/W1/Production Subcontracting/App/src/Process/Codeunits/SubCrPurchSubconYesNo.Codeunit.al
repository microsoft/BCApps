// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Purchases.Document;
using System.Utilities;

codeunit 99001509 "Sub. CrPurchSubcon(Yes/No)"
{
    TableNo = "Purchase Line";

    var
        PurchaseLine: Record "Purchase Line";
        NothingToCreateErr: Label 'There is nothing to create.';

    trigger OnRun()
    begin
        if not Rec.Find() then
            Error(NothingToCreateErr);

        PurchaseLine.Copy(Rec);

        CheckPurchaseLine(PurchaseLine);

        CreateProductionOrderFromPurchaseLine(PurchaseLine);

        Rec := PurchaseLine;
    end;

    local procedure CheckPurchaseLine(PurchLine: Record "Purchase Line")
    begin
        PurchLine.TestField(Type, "Purchase Line Type"::Item);
        PurchLine.TestField("Prod. Order No.", '');
        PurchLine.TestField("Prod. Order Line No.", 0);
        PurchLine.TestField("Qty. Assigned", 0);
        PurchLine.TestField("Qty. Rcd. Not Invoiced", 0);

        PurchLine.TestStatusOpen();
    end;

    local procedure CreateProductionOrderFromPurchaseLine(var PurchLine: Record "Purchase Line")
    var
        HideDialog: Boolean;
    begin
        if not HideDialog then
            if not ConfirmCreateProductionOrder(PurchLine) then
                exit;

        Codeunit.Run(Codeunit::"Sub. Create Prod. Ord. Opt.", PurchLine);
    end;

    local procedure ConfirmCreateProductionOrder(var PurchLine: Record "Purchase Line"): Boolean
    var
        ConfirmManagement: Codeunit "Confirm Management";
        PostConfirmQst: Label 'Do you want to create a production order from %1, %2 line no. %3?', Comment = '%1=Document Type, %2=Document No., %3=Line No.';
    begin
        if not ConfirmManagement.GetResponse(StrSubstNo(PostConfirmQst, Format(PurchLine."Document Type"), PurchLine."Document No.", PurchLine."Line No."), true) then
            exit(false);

        exit(true);
    end;
}