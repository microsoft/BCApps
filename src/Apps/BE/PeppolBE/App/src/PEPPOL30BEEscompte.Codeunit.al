// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol.BE;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Sales.Document;

/// <summary>
/// Shared helpers for the Belgian payment-discount (escompte) compensation. In Belgium VAT is kept on the discounted base, even when the invoice is reported with the full amount.
/// To avoid reporting a reduced amount payable (the discount is only conditional) a compensating Exempt (category E) breakdown line is added. 
/// </summary>
codeunit 37316 "PEPPOL30 BE Escompte"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        CompensationChargeReasonTxt: Label 'Payment discount not deducted from the amount payable';
        CompensationExemptionReasonTxt: Label 'Conditional early-payment discount, not part of the taxable amount';

    /// <summary>
    /// The VAT Amount Line "VAT Identifier" used to mark this compensation line. Internal to the buffer, not written to the PEPPOL document.
    /// </summary>
    procedure GetCompensationVATIdentifier(): Code[20]
    begin
        exit('ESCOMPTE-COMP');
    end;

    /// <summary>
    /// The PEPPOL VAT category code used for the compensation line and charge.
    /// </summary>
    procedure GetExemptTaxCategory(): Code[10]
    begin
        exit('E');
    end;

    /// <summary>
    /// Returns whether the given VAT amount line is the synthetic escompte compensation line.
    /// </summary>
    procedure IsCompensationLine(VATAmtLine: Record "VAT Amount Line"): Boolean
    begin
        exit(VATAmtLine."VAT Identifier" = GetCompensationVATIdentifier());
    end;

    /// <summary>
    /// The AllowanceChargeReason used on the compensating Exempt charge.
    /// </summary>
    procedure GetCompensationChargeReason(): Text
    begin
        exit(CompensationChargeReasonTxt);
    end;

    /// <summary>
    /// The VAT exemption reason used on the compensating Exempt VAT breakdown.
    /// </summary>
    procedure GetCompensationExemptionReason(): Text
    begin
        exit(CompensationExemptionReasonTxt);
    end;

    /// <summary>
    /// Document's currency code (inline with PEPPOL's implementation).
    /// </summary>
    procedure DocumentCurrencyCode(SalesHeader: Record "Sales Header"): Text
    var
        GLSetup: Record "General Ledger Setup";
    begin
        if SalesHeader."Currency Code" <> '' then
            exit(SalesHeader."Currency Code");
        GLSetup.Get();
        GLSetup.TestField("LCY Code");
        exit(GLSetup."LCY Code");
    end;
}
