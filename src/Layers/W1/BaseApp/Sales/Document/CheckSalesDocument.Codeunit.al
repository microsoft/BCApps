// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Sales.Posting;

codeunit 9071 "Check Sales Document"
{
    TableNo = "Sales Header";

    trigger OnRun()
    begin
        RunCheck(Rec);
    end;

    local procedure RunCheck(var SalesHeader: Record "Sales Header")
    var
        SalesPost: Codeunit "Sales-Post";
    begin
        SalesPost.PrepareCheckDocument(SalesHeader);
        SalesPost.CheckSalesDocument(SalesHeader);
    end;
}
