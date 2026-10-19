// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol.BE;

using Microsoft.Finance.VAT.Calculation;
using Microsoft.Peppol;
using Microsoft.Sales.Document;

/// <summary>
/// Needed to add into the LegalMonetaryTotal the Belgian escompte compensation (if applicable). We are storing the compensation in the VAT Amount Line records.
/// </summary>
codeunit 37318 "PEPPOL30 BE Monetary Info" implements "PEPPOL Monetary Info Provider"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        PEPPOL30: Codeunit "PEPPOL30";
        Escompte: Codeunit "PEPPOL30 BE Escompte";

    procedure GetLegalMonetaryInfo(SalesHeader: Record "Sales Header"; var TempSalesLine: Record "Sales Line" temporary; var VATAmtLine: Record "VAT Amount Line"; var LineExtensionAmount: Text; var LegalMonetaryTotalCurrencyID: Text; var TaxExclusiveAmount: Text; var TaxExclusiveAmountCurrencyID: Text; var TaxInclusiveAmount: Text; var TaxInclusiveAmountCurrencyID: Text; var AllowanceTotalAmount: Text; var AllowanceTotalAmountCurrencyID: Text; var ChargeTotalAmount: Text; var ChargeTotalAmountCurrencyID: Text; var PrepaidAmount: Text; var PrepaidCurrencyID: Text; var PayableRoundingAmount: Text; var PayableRndingAmountCurrencyID: Text; var PayableAmount: Text; var PayableAmountCurrencyID: Text)
    var
        CompensationAmount: Decimal;
        RealVATBase: Decimal;
        RealInvDiscount: Decimal;
        RealPmtDiscount: Decimal;
        RealAmtInclVAT: Decimal;
        CurrencyId: Text;
    begin
        if not HasCompensationLine(VATAmtLine) then begin
            PEPPOL30.GetLegalMonetaryInfo(SalesHeader, TempSalesLine, VATAmtLine, LineExtensionAmount, LegalMonetaryTotalCurrencyID, TaxExclusiveAmount, TaxExclusiveAmountCurrencyID, TaxInclusiveAmount, TaxInclusiveAmountCurrencyID, AllowanceTotalAmount, AllowanceTotalAmountCurrencyID, ChargeTotalAmount, ChargeTotalAmountCurrencyID, PrepaidAmount, PrepaidCurrencyID, PayableRoundingAmount, PayableRndingAmountCurrencyID, PayableAmount, PayableAmountCurrencyID);
            exit;
        end;

        VATAmtLine.Reset();
        if VATAmtLine.FindSet() then
            repeat
                if Escompte.IsCompensationLine(VATAmtLine) then
                    CompensationAmount += VATAmtLine."VAT Base"
                else begin
                    RealVATBase += VATAmtLine."VAT Base";
                    RealInvDiscount += VATAmtLine."Invoice Discount Amount";
                    RealPmtDiscount += VATAmtLine."Pmt. Discount Amount";
                    RealAmtInclVAT += VATAmtLine."Amount Including VAT";
                end;
            until VATAmtLine.Next() = 0;

        CurrencyId := Escompte.DocumentCurrencyCode(SalesHeader);

        LineExtensionAmount := Format(Round(RealVATBase, 0.01) + Round(RealInvDiscount, 0.01), 0, 9);
        LegalMonetaryTotalCurrencyID := CurrencyId;

        TaxExclusiveAmount := Format(Round(RealVATBase - RealPmtDiscount + CompensationAmount, 0.01), 0, 9);
        TaxExclusiveAmountCurrencyID := CurrencyId;

        TaxInclusiveAmount := Format(Round(RealAmtInclVAT - RealPmtDiscount + CompensationAmount, 0.01, '>'), 0, 9);
        TaxInclusiveAmountCurrencyID := CurrencyId;

        AllowanceTotalAmount := Format(Round(RealInvDiscount + RealPmtDiscount, 0.01), 0, 9);
        AllowanceTotalAmountCurrencyID := CurrencyId;

        ChargeTotalAmount := Format(Round(CompensationAmount, 0.01), 0, 9);
        ChargeTotalAmountCurrencyID := CurrencyId;

        PrepaidAmount := '0.00';
        PrepaidCurrencyID := CurrencyId;

        if TempSalesLine."Line No." = 0 then begin
            PayableRoundingAmount := Format(RealAmtInclVAT - Round(RealAmtInclVAT, 0.01), 0, 9);
            PayableRndingAmountCurrencyID := CurrencyId;
            PayableAmount := Format(Round(RealAmtInclVAT - RealPmtDiscount + CompensationAmount, 0.01), 0, 9);
            PayableAmountCurrencyID := CurrencyId;
        end else begin
            PayableRoundingAmount := Format(TempSalesLine."Amount Including VAT", 0, 9);
            PayableRndingAmountCurrencyID := CurrencyId;
            PayableAmount := Format(Round(RealAmtInclVAT + TempSalesLine."Amount Including VAT" - RealPmtDiscount + CompensationAmount, 0.01), 0, 9);
            PayableAmountCurrencyID := CurrencyId;
        end;
    end;

    procedure GetLegalMonetaryDocAmounts(SalesHeader: Record "Sales Header"; var VATAmtLine: Record "VAT Amount Line"; var LineExtensionAmount: Text; var LegalMonetaryTotalCurrencyID: Text; var TaxExclusiveAmount: Text; var TaxExclusiveAmountCurrencyID: Text; var TaxInclusiveAmount: Text; var TaxInclusiveAmountCurrencyID: Text; var AllowanceTotalAmount: Text; var AllowanceTotalAmountCurrencyID: Text; var ChargeTotalAmount: Text; var ChargeTotalAmountCurrencyID: Text)
    begin
        PEPPOL30.GetLegalMonetaryDocAmounts(SalesHeader, VATAmtLine, LineExtensionAmount, LegalMonetaryTotalCurrencyID, TaxExclusiveAmount, TaxExclusiveAmountCurrencyID, TaxInclusiveAmount, TaxInclusiveAmountCurrencyID, AllowanceTotalAmount, AllowanceTotalAmountCurrencyID, ChargeTotalAmount, ChargeTotalAmountCurrencyID);
    end;

    procedure GetInvoiceRoundingLine(var TempSalesLine: Record "Sales Line" temporary; SalesLine: Record "Sales Line")
    begin
        PEPPOL30.GetInvoiceRoundingLine(TempSalesLine, SalesLine);
    end;

    local procedure HasCompensationLine(var VATAmtLine: Record "VAT Amount Line"): Boolean
    var
        Found: Boolean;
    begin
        VATAmtLine.Reset();
        VATAmtLine.SetRange("VAT Identifier", Escompte.GetCompensationVATIdentifier());
        Found := not VATAmtLine.IsEmpty();
        VATAmtLine.Reset();
        exit(Found);
    end;
}
