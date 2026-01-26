// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.Sales.History;

codeunit 28074 "Sales Tax Cr.Memo-Printed"
{
    Permissions = TableData "Sales Cr.Memo Header" = rimd,
                  TableData "Sales Tax Cr.Memo Header" = rimd;
    TableNo = "Sales Tax Cr.Memo Header";

    trigger OnRun()
    begin
        Rec.Find();
        Rec."No. Printed" := Rec."No. Printed" + 1;
        Rec.Modify();

        SalesTaxCrMemoLine.SetRange("Document No.", Rec."No.");
        if SalesTaxCrMemoLine.FindFirst() then begin
            SalesCrMemoHeader.SetRange("No.", SalesTaxCrMemoLine."External Document No.");
            if SalesCrMemoHeader.FindFirst() then begin
                SalesCrMemoHeader."Printed Tax Document" := true;
                SalesCrMemoHeader.Modify();
            end;
        end;

        Commit();
    end;

    var
        SalesTaxCrMemoLine: Record "Sales Tax Cr.Memo Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
}

