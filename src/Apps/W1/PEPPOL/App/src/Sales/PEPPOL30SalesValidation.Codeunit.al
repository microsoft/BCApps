// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

using Microsoft.Sales.Document;

codeunit 37216 "PEPPOL30 Sales Validation" implements "PEPPOL30 Validation"
{
    TableNo = "Sales Header";
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
        ValidateDocument(Rec);
        ValidateDocumentLines(Rec);
    end;

    #region Interface Methods
    /// <summary>
    /// Validates a sales document header against PEPPOL 3.0 requirements.
    /// Validates mandatory fields, formats, and business rules at the document level.
    /// </summary>
    /// <param name="RecordVariant">The sales header record to validate.</param>
    procedure ValidateDocument(RecordVariant: Variant)
    var
        PEPPOL30SalesValidationImpl: Codeunit "PEPPOL30 Sales Validation Impl";
    begin
        PEPPOL30SalesValidationImpl.CheckSalesDocument(RecordVariant);
    end;

    /// <summary>
    /// Validates all sales document lines associated with a sales header against PEPPOL 3.0 requirements.
    /// Iterates through all lines and performs line-level validation Validates.
    /// </summary>
    /// <param name="RecordVariant">The sales header record whose lines should be validated.</param>
    procedure ValidateDocumentLines(RecordVariant: Variant)
    var
        PEPPOL30SalesValidationImpl: Codeunit "PEPPOL30 Sales Validation Impl";
    begin
        PEPPOL30SalesValidationImpl.CheckSalesDocumentLines(RecordVariant);
    end;

    /// <summary>
    /// Validates a single sales document line against PEPPOL 3.0 requirements.
    /// Performs validation Validates on individual line fields and business rules.
    /// </summary>
    /// <param name="RecordVariant">The sales line record to validate.</param>
    procedure ValidateDocumentLine(RecordVariant: Variant)
    var
        PEPPOL30SalesValidationImpl: Codeunit "PEPPOL30 Sales Validation Impl";
    begin
        PEPPOL30SalesValidationImpl.CheckSalesDocumentLine(RecordVariant);
    end;

    /// <summary>
    /// Validates a posted sales document against PEPPOL 3.0 requirements.
    /// Validates the posted document for compliance before export or transmission.
    /// </summary>
    /// <param name="RecordVariant">The posted sales document record to validate.</param>
    procedure ValidatePostedDocument(RecordVariant: Variant)
    var
        PEPPOL30SalesValidationImpl: Codeunit "PEPPOL30 Sales Validation Impl";
    begin
        PEPPOL30SalesValidationImpl.CheckPostedDocument(RecordVariant);
    end;

    /// <summary>
    /// Validates the sales line
    /// </summary>
    /// <param name="RecordVariant"></param>
    /// <returns></returns>
    procedure ValidateLineTypeAndDescription(RecordVariant: Variant): Boolean
    var
        PEPPOL30SalesValidationImpl: Codeunit "PEPPOL30 Sales Validation Impl";
    begin
        exit(PEPPOL30SalesValidationImpl.CheckSalesLineTypeAndDescription(RecordVariant));
    end;
    #endregion Interface Methods

    #region Non-Interface Methods
    /// <summary>
    /// Validates that the currency code is a valid 3-character ISO currency code.
    /// </summary>
    /// <param name="CurrencyCode">The currency code to validate.</param>
    procedure CheckCurrencyCode(CurrencyCode: Code[10])
    var
        PEPPOL30SalesValidationImpl: Codeunit "PEPPOL30 Sales Validation Impl";
    begin
        PEPPOL30SalesValidationImpl.CheckCurrencyCode(CurrencyCode);
    end;

    /// <summary>
    /// Validates that the country/region code has a valid 2-character ISO code.
    /// </summary>
    /// <param name="CountryRegionCode">The country/region code to validate.</param>
    procedure CheckCountryRegionCode(CountryRegionCode: Code[10])
    var
        PEPPOL30SalesValidationImpl: Codeunit "PEPPOL30 Sales Validation Impl";
    begin
        PEPPOL30SalesValidationImpl.CheckCountryRegionCode(CountryRegionCode);
    end;

    /// <summary>
    /// Validates the ship-to address fields on a sales header.
    /// </summary>
    /// <param name="SalesHeader">The sales header record to validate.</param>
    procedure CheckShipToAddress(SalesHeader: Record "Sales Header")
    var
        PEPPOL30SalesValidationImpl: Codeunit "PEPPOL30 Sales Validation Impl";
    begin
        PEPPOL30SalesValidationImpl.CheckShipToAddress(SalesHeader);
    end;

    /// <summary>
    /// Validates the tax category for a sales line.
    /// </summary>
    /// <param name="SalesLine">The sales line record to validate.</param>
    procedure CheckTaxCategory(SalesLine: Record "Sales Line")
    var
        PEPPOL30SalesValidationImpl: Codeunit "PEPPOL30 Sales Validation Impl";
    begin
        PEPPOL30SalesValidationImpl.CheckTaxCategory(SalesLine);
    end;

    /// <summary>
    /// Ensures the VAT percentage is zero for tax categories that require it.
    /// </summary>
    /// <param name="VatPercent">The VAT percentage to check.</param>
    /// <param name="TaxCategoryCode">The tax category code for error reporting.</param>
    procedure EnsureZeroRate(VatPercent: Decimal; TaxCategoryCode: Code[10])
    var
        PEPPOL30SalesValidationImpl: Codeunit "PEPPOL30 Sales Validation Impl";
    begin
        PEPPOL30SalesValidationImpl.EnsureZeroRate(VatPercent, TaxCategoryCode);
    end;

    /// <summary>
    /// Ensures the VAT percentage is positive for tax categories that require it.
    /// </summary>
    /// <param name="VatPercent">The VAT percentage to check.</param>
    /// <param name="TaxCategoryCode">The tax category code for error reporting.</param>
    procedure EnsurePositiveRate(VatPercent: Decimal; TaxCategoryCode: Code[10])
    var
        PEPPOL30SalesValidationImpl: Codeunit "PEPPOL30 Sales Validation Impl";
    begin
        PEPPOL30SalesValidationImpl.EnsurePositiveRate(VatPercent, TaxCategoryCode);
    end;

    /// <summary>
    /// Ensures only a single outside scope VAT breakdown exists for PEPPOL compliance.
    /// </summary>
    /// <param name="SalesLine">The sales line record to check.</param>
    procedure EnsureSingleOutsideScopeVATBreakdown(SalesLine: Record "Sales Line")
    var
        PEPPOL30SalesValidationImpl: Codeunit "PEPPOL30 Sales Validation Impl";
    begin
        PEPPOL30SalesValidationImpl.EnsureSingleOutsideScopeVATBreakdown(SalesLine);
    end;
    #endregion Non-Interface Methods
}
