// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Registration;

using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;

codeunit 200 "Alt. Cust. VAT. Reg. Facade"
{
    Access = Public;

    var
        AltCustVATRegOrchestrator: Codeunit "Alt. Cust. VAT Reg. Orchest.";

    procedure UpdateSetupOnShipToCountryChangeInSalesHeader(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header")
    begin
        AltCustVATRegOrchestrator.GetAltCustVATRegDocImpl().UpdateSetupOnShipToCountryChangeInSalesHeader(SalesHeader, xSalesHeader);
    end;

    procedure UpdateSetupOnVATCountryChangeInSalesHeader(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header")
    begin
        AltCustVATRegOrchestrator.GetAltCustVATRegDocImpl().UpdateSetupOnVATCountryChangeInSalesHeader(SalesHeader, xSalesHeader);
    end;

    procedure UpdateSetupOnBillToCustomerChangeInSalesHeader(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; BillToCustomer: Record Customer)
    begin
        AltCustVATRegOrchestrator.GetAltCustVATRegDocImpl().UpdateSetupOnBillToCustomerChangeInSalesHeader(SalesHeader, xSalesHeader, BillToCustomer);
    end;

    procedure CopyFromCustomer(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header")
    begin
        AltCustVATRegOrchestrator.GetAltCustVATRegDocImpl().CopyFromCustomer(SalesHeader, xSalesHeader);
    end;

    procedure Init(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header")
    begin
        AltCustVATRegOrchestrator.GetAltCustVATRegDocImpl().Init(SalesHeader, xSalesHeader);
    end;

    procedure GetAlternativeCustVATReg(var AltCustVATReg: Record "Alt. Cust. VAT Reg."; CustNo: Code[20]; CountryCode: Code[10]): Boolean
    begin
        AltCustVATReg.SetRange("Customer No.", CustNo);
        AltCustVATReg.SetRange("VAT Country/Region Code", CountryCode);
        exit(AltCustVATReg.FindFirst());
    end;

    procedure UpdateVATRegNoInCustFromSalesHeader(SalesHeader: Record "Sales Header"; Customer: Record Customer) ShouldUpdate: Boolean
    var
        IsHandled: Boolean;
    begin
        OnBeforeUpdateVATRegNoInCustFromSalesHeader(SalesHeader, Customer, ShouldUpdate, IsHandled);
        if IsHandled then
            exit(ShouldUpdate);
        exit((Customer."VAT Registration No." = '') and (not SalesHeader."Alt. VAT Registration No."));
    end;

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

    procedure HandleCountryChangeInShipToAddress(ShipToAddress: Record "Ship-to Address")
    begin
        AltCustVATRegOrchestrator.GetShipToAlCustVATRegImpl().HandleCountryChangeInShipToAddress(ShipToAddress);
    end;

    procedure CheckAltCustVATRegConsistent(AltCustVATReg: Record "Alt. Cust. VAT Reg.")
    begin
        AltCustVATRegOrchestrator.GetAltCustVATRegConsistencyImpl().CheckAltCustVATRegConsistent(AltCustVATReg);
    end;

    procedure CheckCustomerConsistency(Customer: Record Customer)
    begin
        AltCustVATRegOrchestrator.GetAltCustVATRegConsistencyImpl().CheckCustomerConsistency(Customer);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateVATRegNoInCustFromSalesHeader(var SalesHeader: Record "Sales Header"; Customer: Record Customer; var ShouldUpdate: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVATDataIsChangedOnShipToCodeValidation(var SalesHeader: Record "Sales Header"; var xSalesHeader: Record "Sales Header"; var Changed: Boolean; var IsHandled: Boolean)
    begin
    end;
}