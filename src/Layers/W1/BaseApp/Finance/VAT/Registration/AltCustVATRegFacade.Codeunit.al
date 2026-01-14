// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Registration;

using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;

/// <summary>
/// Facade for alternative customer VAT registration functionality in sales documents.
/// Provides simplified interface for VAT registration management across different shipping scenarios and country changes.
/// </summary>
codeunit 200 "Alt. Cust. VAT. Reg. Facade"
{
    Access = Public;

    var
        AltCustVATRegOrchestrator: Codeunit "Alt. Cust. VAT Reg. Orchest.";

    /// <summary>
    /// Updates VAT setup when ship-to country/region changes in sales header.
    /// </summary>
    /// <param name="SalesHeader">Sales header being modified</param>
    /// <param name="xSalesHeader">Original sales header before changes</param>
    procedure UpdateSetupOnShipToCountryChangeInSalesHeader(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header")
    begin
        AltCustVATRegOrchestrator.GetAltCustVATRegDocImpl().UpdateSetupOnShipToCountryChangeInSalesHeader(SalesHeader, xSalesHeader);
    end;

    /// <summary>
    /// Updates VAT setup when VAT country/region changes in sales header.
    /// </summary>
    /// <param name="SalesHeader">Sales header being modified</param>
    /// <param name="xSalesHeader">Original sales header before changes</param>
    procedure UpdateSetupOnVATCountryChangeInSalesHeader(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header")
    begin
        AltCustVATRegOrchestrator.GetAltCustVATRegDocImpl().UpdateSetupOnVATCountryChangeInSalesHeader(SalesHeader, xSalesHeader);
    end;

    /// <summary>
    /// Updates VAT setup when bill-to customer changes in sales header.
    /// </summary>
    /// <param name="SalesHeader">Sales header being modified</param>
    /// <param name="xSalesHeader">Original sales header before changes</param>
    /// <param name="BillToCustomer">New bill-to customer record</param>
    procedure UpdateSetupOnBillToCustomerChangeInSalesHeader(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; BillToCustomer: Record Customer)
    begin
        AltCustVATRegOrchestrator.GetAltCustVATRegDocImpl().UpdateSetupOnBillToCustomerChangeInSalesHeader(SalesHeader, xSalesHeader, BillToCustomer);
    end;

    /// <summary>
    /// Copies alternative VAT registration settings from customer to sales header.
    /// </summary>
    /// <param name="SalesHeader">Sales header to update with customer VAT settings</param>
    /// <param name="xSalesHeader">Original sales header before changes</param>
    procedure CopyFromCustomer(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header")
    begin
        AltCustVATRegOrchestrator.GetAltCustVATRegDocImpl().CopyFromCustomer(SalesHeader, xSalesHeader);
    end;

    /// <summary>
    /// Initializes alternative VAT registration setup for sales header.
    /// </summary>
    /// <param name="SalesHeader">Sales header to initialize with VAT registration settings</param>
    /// <param name="xSalesHeader">Original sales header before changes</param>
    procedure Init(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header")
    begin
        AltCustVATRegOrchestrator.GetAltCustVATRegDocImpl().Init(SalesHeader, xSalesHeader);
    end;

    /// <summary>
    /// Retrieves alternative customer VAT registration record for specified customer and country.
    /// </summary>
    /// <param name="AltCustVATReg">Alternative customer VAT registration record to populate</param>
    /// <param name="CustNo">Customer number to search for</param>
    /// <param name="CountryCode">Country/region code for VAT registration</param>
    /// <returns>True if alternative VAT registration record found</returns>
    procedure GetAlternativeCustVATReg(var AltCustVATReg: Record "Alt. Cust. VAT Reg."; CustNo: Code[20]; CountryCode: Code[10]): Boolean
    begin
        AltCustVATReg.SetRange("Customer No.", CustNo);
        AltCustVATReg.SetRange("VAT Country/Region Code", CountryCode);
        exit(AltCustVATReg.FindFirst());
    end;

    /// <summary>
    /// Determines whether customer VAT registration number should be updated from sales header.
    /// </summary>
    /// <param name="SalesHeader">Sales header containing VAT registration information</param>
    /// <param name="Customer">Customer record to potentially update</param>
    /// <returns>True if customer VAT registration should be updated</returns>
    procedure UpdateVATRegNoInCustFromSalesHeader(SalesHeader: Record "Sales Header"; Customer: Record Customer) ShouldUpdate: Boolean
    var
        IsHandled: Boolean;
    begin
        OnBeforeUpdateVATRegNoInCustFromSalesHeader(SalesHeader, Customer, ShouldUpdate, IsHandled);
        if IsHandled then
            exit(ShouldUpdate);
        exit((Customer."VAT Registration No." = '') and (not SalesHeader."Alt. VAT Registration No."));
    end;

    /// <summary>
    /// Determines whether VAT data has changed during ship-to code validation.
    /// </summary>
    /// <param name="SalesHeader">Current sales header</param>
    /// <param name="xSalesHeader">Original sales header before changes</param>
    /// <returns>True if VAT-related data has changed</returns>
    procedure VATDataIsChangedOnShipToCodeValidation(SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header") Changed: Boolean
    var
        IsHandled: Boolean;
    begin
        OnBeforeVATDataIsChangedOnShipToCodeValidation(SalesHeader, xSalesHeader, Changed, IsHandled);
        if IsHandled then
            exit(Changed);
        if SalesHeader."Alt. Gen. Bus Posting Group" or SalesHeader."Alt. VAT Bus Posting Group" or
           xSalesHeader."Alt. Gen. Bus Posting Group" or xSalesHeader."Alt. VAT Bus Posting Group"
        then
            exit(false);
        exit(xSalesHeader."VAT Country/Region Code" <> SalesHeader."VAT Country/Region Code");
    end;

    /// <summary>
    /// Handles country/region change events in ship-to address records.
    /// </summary>
    /// <param name="ShipToAddress">Ship-to address record with country/region change</param>
    procedure HandleCountryChangeInShipToAddress(ShipToAddress: Record "Ship-to Address")
    begin
        AltCustVATRegOrchestrator.GetShipToAlCustVATRegImpl().HandleCountryChangeInShipToAddress(ShipToAddress);
    end;

    /// <summary>
    /// Validates consistency of alternative customer VAT registration setup.
    /// </summary>
    /// <param name="AltCustVATReg">Alternative customer VAT registration record to validate</param>
    procedure CheckAltCustVATRegConsistent(AltCustVATReg: Record "Alt. Cust. VAT Reg.")
    begin
        AltCustVATRegOrchestrator.GetAltCustVATRegConsistencyImpl().CheckAltCustVATRegConsistent(AltCustVATReg);
    end;

    /// <summary>
    /// Validates consistency of customer VAT registration setup across all alternative registrations.
    /// </summary>
    /// <param name="Customer">Customer record to validate for VAT registration consistency</param>
    procedure CheckCustomerConsistency(Customer: Record Customer)
    begin
        AltCustVATRegOrchestrator.GetAltCustVATRegConsistencyImpl().CheckCustomerConsistency(Customer);
    end;

    /// <summary>
    /// Integration event raised before determining whether to update customer VAT registration number from sales header.
    /// </summary>
    /// <param name="SalesHeader">Sales header containing VAT registration information</param>
    /// <param name="Customer">Customer record to potentially update</param>
    /// <param name="ShouldUpdate">Set to true if customer VAT registration should be updated</param>
    /// <param name="IsHandled">Set to true to skip standard logic</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateVATRegNoInCustFromSalesHeader(var SalesHeader: Record "Sales Header"; Customer: Record Customer; var ShouldUpdate: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before determining whether VAT data has changed during ship-to code validation.
    /// </summary>
    /// <param name="SalesHeader">Current sales header</param>
    /// <param name="xSalesHeader">Original sales header before changes</param>
    /// <param name="Changed">Set to true if VAT data has changed</param>
    /// <param name="IsHandled">Set to true to skip standard logic</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeVATDataIsChangedOnShipToCodeValidation(var SalesHeader: Record "Sales Header"; var xSalesHeader: Record "Sales Header"; var Changed: Boolean; var IsHandled: Boolean)
    begin
    end;
}