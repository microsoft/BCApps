// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using Microsoft.Bank.BankAccount;
using Microsoft.Foundation.PaymentTerms;

codeunit 27031 "Update SAT Payment Catalogs"
{

    trigger OnRun()
    begin
        SwapSATPaymentCatalogs();
    end;

    local procedure SwapSATPaymentCatalogs()
    var
        PaymentTerms: Record "Payment Terms";
        PaymentMethod: Record "Payment Method";
        SATPaymentMethod: Record "SAT Payment Method";
        SATPaymentTerm: Record "SAT Payment Term";
        TempSATPaymentTerm: Record "SAT Payment Term" temporary;
    begin
        if SATPaymentMethod.IsEmpty() and SATPaymentTerm.IsEmpty() then
            exit;

        PaymentMethod.ModifyAll("SAT Method of Payment", '');
        PaymentTerms.ModifyAll("SAT Payment Term", '');

        if SATPaymentTerm.FindSet() then
            repeat
                TempSATPaymentTerm := SATPaymentTerm;
                TempSATPaymentTerm.Insert();
            until SATPaymentTerm.Next() = 0;
        SATPaymentTerm.DeleteAll();

        if SATPaymentMethod.FindSet() then
            repeat
                SATPaymentTerm.TransferFields(SATPaymentMethod);
                SATPaymentTerm.Insert();
            until SATPaymentMethod.Next() = 0;
        SATPaymentMethod.DeleteAll();

        if TempSATPaymentTerm.FindSet() then
            repeat
                SATPaymentMethod.TransferFields(TempSATPaymentTerm);
                SATPaymentMethod.Insert();
            until TempSATPaymentTerm.Next() = 0;
        TempSATPaymentTerm.DeleteAll();
    end;
}

