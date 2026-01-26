// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Finance.GeneralLedger.Setup;
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
        GLSetup.Get();
        if GLSetup."Payment Discount Type" <> GLSetup."Payment Discount Type"::"Calc. Pmt. Disc. on Lines" then begin
            if ConfirmManagement.GetResponseOrDefault(Text000, true) then
                CODEUNIT.Run(CODEUNIT::"Sales-Calc. Discount", SalesLine);
        end else
            if ConfirmManagement.GetResponseOrDefault(Text1100000, true) then
                CODEUNIT.Run(CODEUNIT::"Sales-Calc. Discount", SalesLine);

        Rec := SalesLine;
    end;

    var
        SalesLine: Record "Sales Line";
        GLSetup: Record "General Ledger Setup";

#pragma warning disable AA0074
        Text000: Label 'Do you want to calculate the invoice discount?';
        Text1100000: Label 'Do you want to calculate the invoice discount and payment discount?';
#pragma warning restore AA0074

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;
}

