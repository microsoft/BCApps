interface "PEPPOL Tax Info Provider"
{
    procedure GetAllowanceChargeInfo(
        VATAmtLine: Record "VAT Amount Line";
        SalesHeader: Record "Sales Header";
        var ChargeIndicator: Text;
        var AllowanceChargeReasonCode: Text;
        var AllowanceChargeListID: Text;
        var AllowanceChargeReason: Text;
        var Amount: Text;
        var AllowanceChargeCurrencyID: Text;
        var TaxCategoryID: Text;
        var TaxCategorySchemeID: Text;
        var Percent: Text;
        var AllowanceChargeTaxSchemeID: Text);

    procedure GetAllowanceChargeInfoBIS(
        VATAmtLine: Record "VAT Amount Line";
        SalesHeader: Record "Sales Header";
        var ChargeIndicator: Text;
        var AllowanceChargeReasonCode: Text;
        var AllowanceChargeListID: Text;
        var AllowanceChargeReason: Text;
        var Amount: Text;
        var AllowanceChargeCurrencyID: Text;
        var TaxCategoryID: Text;
        var TaxCategorySchemeID: Text;
        var Percent: Text;
        var AllowanceChargeTaxSchemeID: Text);

    procedure GetTaxExchangeRateInfo(
        SalesHeader: Record "Sales Header";
        var SourceCurrencyCode: Text;
        var SourceCurrencyCodeListID: Text;
        var TargetCurrencyCode: Text;
        var TargetCurrencyCodeListID: Text;
        var CalculationRate: Text;
        var MathematicOperatorCode: Text;
        var Date: Text);

    procedure GetTaxTotalInfo(
        SalesHeader: Record "Sales Header";
        var VATAmtLine: Record "VAT Amount Line";
        var TaxAmount: Text;
        var TaxTotalCurrencyID: Text);

    procedure GetTaxSubtotalInfo(
        VATAmtLine: Record "VAT Amount Line";
        SalesHeader: Record "Sales Header";
        var TaxableAmount: Text;
        var TaxAmountCurrencyID: Text;
        var SubtotalTaxAmount: Text;
        var TaxSubtotalCurrencyID: Text;
        var TransactionCurrencyTaxAmount: Text;
        var TransCurrTaxAmtCurrencyID: Text;
        var TaxTotalTaxCategoryID: Text;
        var schemeID: Text;
        var TaxCategoryPercent: Text;
        var TaxTotalTaxSchemeID: Text);

    procedure GetTaxTotalInfoLCY(
        SalesHeader: Record "Sales Header";
        var TaxAmount: Text;
        var TaxCurrencyID: Text;
        var TaxTotalCurrencyID: Text);

    procedure GetTotals(
        SalesLine: Record "Sales Line";
        var VATAmtLine: Record "VAT Amount Line");

    procedure GetTaxCategories(
        SalesLine: Record "Sales Line";
        var VATProductPostingGroupCategory: Record "VAT Product Posting Group");

    procedure GetTaxExemptionReason(
        var VATProductPostingGroupCategory: Record "VAT Product Posting Group";
        var TaxExemptionReasonTxt: Text;
        TaxCategoryID: Text);

    procedure IsZeroVatCategory(TaxCategory: Code[10]): Boolean;
    procedure IsStandardVATCategory(TaxCategory: Code[10]): Boolean;
    procedure IsOutsideScopeVATCategory(TaxCategory: Code[10]): Boolean;
}
