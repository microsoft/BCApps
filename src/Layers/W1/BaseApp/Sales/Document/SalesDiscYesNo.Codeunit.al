// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using System.Utilities;

codeunit 61 "Sales-Disc. (Yes/No)"
{
    TableNo = "Sales Line";

    trigger OnRun()
    var
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnRun(Rec, IsHandled);
        if IsHandled then
            exit;

        SalesLine.Copy(Rec);
        if ConfirmManagement.GetResponseOrDefault(Text000, true) then
            CODEUNIT.Run(CODEUNIT::"Sales-Calc. Discount", SalesLine);
        Rec := SalesLine;
    end;

    var
        SalesLine: Record "Sales Line";

#pragma warning disable AA0074
        Text000: Label 'Do you want to calculate the invoice discount?';
#pragma warning restore AA0074

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;
}

