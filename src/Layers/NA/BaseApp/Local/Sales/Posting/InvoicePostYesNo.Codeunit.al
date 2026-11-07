// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Posting;

using Microsoft.Sales.Document;

codeunit 10021 "Invoice-Post (Yes/No)"
{
    TableNo = "Sales Header";

    trigger OnRun()
    begin
        SalesHeader.Copy(Rec);
        Code();
        Rec := SalesHeader;
    end;

    var
        SalesHeader: Record "Sales Header";
        SalesPost: Codeunit "Sales-Post";
        Text1020001: Label 'Do you want to invoice the %1?';

    local procedure "Code"()
    begin
        if SalesHeader."Document Type" = SalesHeader."Document Type"::Order then begin
            if not Confirm(Text1020001, false, SalesHeader."Document Type") then
                exit;
            SalesHeader.Ship := false;
            SalesHeader.Invoice := true;
            SalesPost.Run(SalesHeader);
        end;
    end;
}

