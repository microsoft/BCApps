// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.Sales.History;

codeunit 28072 "Sales Tax Inv.-Printed"
{
    Permissions = TableData "Sales Invoice Header" = rimd,
                  TableData "Sales Tax Invoice Header" = rimd;
    TableNo = "Sales Tax Invoice Header";

    trigger OnRun()
    begin
        Rec.Find();
        Rec."No. Printed" := Rec."No. Printed" + 1;
        Rec.Modify();

        SalesTaxInvLine.SetRange("Document No.", Rec."No.");
        if SalesTaxInvLine.FindFirst() then begin
            SalesInvHeader.SetRange("No.", SalesTaxInvLine."External Document No.");
            if SalesInvHeader.FindFirst() then begin
                SalesInvHeader."Printed Tax Document" := true;
                SalesInvHeader.Modify();
            end;
        end;

        Commit();
    end;

    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesTaxInvLine: Record "Sales Tax Invoice Line";
}

