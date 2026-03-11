// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Purchases.Document;
using System.Utilities;

codeunit 99001509 "Subc. CrPurchSubcon(Yes/No)"
{
    TableNo = "Purchase Line";

    trigger OnRun()
    var
        PurchaseLine: Record "Purchase Line";
        NothingToCreateErr: Label 'There is nothing to create.';
    begin
        if not Rec.Find() then
            Error(NothingToCreateErr);

        PurchaseLine.Copy(Rec);

        CheckPurchaseLine(PurchaseLine);

        CreateProductionOrderFromPurchaseLine(PurchaseLine);

        Rec := PurchaseLine;
    end;

    local procedure CheckPurchaseLine(PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine.TestField(Type, "Purchase Line Type"::Item);
        PurchaseLine.TestField("Prod. Order No.", '');
        PurchaseLine.TestField("Prod. Order Line No.", 0);
        PurchaseLine.TestField("Qty. Assigned", 0);
        PurchaseLine.TestField("Qty. Rcd. Not Invoiced", 0);

        PurchaseLine.TestStatusOpen();
    end;

    local procedure CreateProductionOrderFromPurchaseLine(var PurchaseLine: Record "Purchase Line")
    var
        HideDialog: Boolean;
    begin
        if not HideDialog then
            if not ConfirmCreateProductionOrder(PurchaseLine) then
                exit;

        Codeunit.Run(Codeunit::"Subc. Create Prod. Ord. Opt.", PurchaseLine);
    end;

    local procedure ConfirmCreateProductionOrder(var PurchaseLine: Record "Purchase Line"): Boolean
    var
        ConfirmManagement: Codeunit "Confirm Management";
        PostConfirmQst: Label 'Do you want to create a production order from %1, %2 line no. %3?', Comment = '%1=Document Type, %2=Document No., %3=Line No.';
    begin
        if not ConfirmManagement.GetResponse(StrSubstNo(PostConfirmQst, Format(PurchaseLine."Document Type"), PurchaseLine."Document No.", PurchaseLine."Line No."), true) then
            exit(false);

        exit(true);
    end;
}