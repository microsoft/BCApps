// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Sales.Customer;
using Microsoft.Service.Contract;
using Microsoft.Service.Document;

codeunit 28002 "Serv. Post Code Check"
{
    var
        PostCodeCheck: Codeunit "Post Code Check";

    // Codeunit "ServContractManagement"
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"ServContractManagement", 'OnCreateServHeaderOnAfterCopyFromCustomer', '', false, false)]
    local procedure ServContractManagement(var ServiceHeader: Record "Service Header"; Customer: Record Customer)
    begin
        PostCodeCheck.CopyAddressIDRecord(
            DATABASE::Customer, Customer.GetPosition(), 0,
            DATABASE::"Service Header", ServiceHeader.GetPosition(), 3);
    end;

    // Table "Service Header"
    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnBeforeValidateEvent', 'Address', false, false)]
    local procedure ServiceHeaderAddress(var Rec: Record "Service Header"; CurrFieldNo: Integer)
    begin
        PostCodeCheck.VerifyAddress(
            CurrFieldNo, DATABASE::"Service Header", Rec.GetPosition(), 0,
            Rec.Name, Rec."Name 2", Rec."Contact Name", Rec.Address, Rec."Address 2",
            Rec.City, Rec."Post Code", Rec.County, Rec."Country/Region Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnBeforeValidateEvent', 'Address 2', false, false)]
    local procedure ServiceHeaderAddress2(var Rec: Record "Service Header"; CurrFieldNo: Integer)
    begin
        PostCodeCheck.VerifyAddress(
            CurrFieldNo, DATABASE::"Service Header", Rec.GetPosition(), 0,
            Rec.Name, Rec."Name 2", Rec."Contact Name", Rec.Address, Rec."Address 2",
            Rec.City, Rec."Post Code", Rec.County, Rec."Country/Region Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnBeforeValidateEvent', 'Bill-to Address', false, false)]
    local procedure ServiceHeaderBillToAddress(var Rec: Record "Service Header"; CurrFieldNo: Integer)
    begin
        PostCodeCheck.VerifyAddress(
            CurrFieldNo, DATABASE::"Service Header", Rec.GetPosition(), 1,
            Rec."Bill-to Name", Rec."Bill-to Name 2", Rec."Bill-to Contact",
            Rec."Bill-to Address", Rec."Bill-to Address 2", Rec."Bill-to City",
            Rec."Bill-to Post Code", Rec."Bill-to County", Rec."Bill-to Country/Region Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnBeforeValidateEvent', 'Bill-to Address 2', false, false)]
    local procedure ServiceHeaderBillToAddress2(var Rec: Record "Service Header"; CurrFieldNo: Integer)
    begin
        PostCodeCheck.VerifyAddress(
            CurrFieldNo, DATABASE::"Service Header", Rec.GetPosition(), 1,
            Rec."Bill-to Name", Rec."Bill-to Name 2", Rec."Bill-to Contact",
            Rec."Bill-to Address", Rec."Bill-to Address 2", Rec."Bill-to City",
            Rec."Bill-to Post Code", Rec."Bill-to County", Rec."Bill-to Country/Region Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnBeforeValidateEvent', 'Ship-to Address', false, false)]
    local procedure ServiceHeaderShipToAddress(var Rec: Record "Service Header"; CurrFieldNo: Integer)
    begin
        PostCodeCheck.VerifyAddress(
            CurrFieldNo, DATABASE::"Service Header", Rec.GetPosition(), 2,
            Rec."Ship-to Name", Rec."Ship-to Name 2", Rec."Ship-to Contact",
            Rec."Ship-to Address", Rec."Ship-to Address 2", Rec."Ship-to City",
            Rec."Ship-to Post Code", Rec."Ship-to County", Rec."Ship-to Country/Region Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnBeforeValidateEvent', 'Ship-to Address 2', false, false)]
    local procedure ServiceHeaderShipToAddress2(var Rec: Record "Service Header"; CurrFieldNo: Integer)
    begin
        PostCodeCheck.VerifyAddress(
            CurrFieldNo, DATABASE::"Service Header", Rec.GetPosition(), 2,
            Rec."Ship-to Name", Rec."Ship-to Name 2", Rec."Ship-to Contact",
            Rec."Ship-to Address", Rec."Ship-to Address 2", Rec."Ship-to City",
            Rec."Ship-to Post Code", Rec."Ship-to County", Rec."Ship-to Country/Region Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnBeforeValidateCity', '', false, false)]
    local procedure ServiceHeaderOnBeforeValidateCity(var ServiceHeader: Record "Service Header"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
        PostCodeCheck.VerifyCity(
            CurrentFieldNo, DATABASE::"Service Header", ServiceHeader.GetPosition(), 0,
            ServiceHeader.Name, ServiceHeader."Name 2", ServiceHeader."Contact Name",
            ServiceHeader.Address, ServiceHeader."Address 2", ServiceHeader.City,
            ServiceHeader."Post Code", ServiceHeader.County, ServiceHeader."Country/Region Code");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnBeforeValidatePostCode', '', false, false)]
    local procedure ServiceHeaderOnBeforeValidatePostCode(var ServiceHeader: Record "Service Header"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
        PostCodeCheck.VerifyPostCode(
            CurrentFieldNo, DATABASE::"Service Header", ServiceHeader.GetPosition(), 0,
            ServiceHeader.Name, ServiceHeader."Name 2", ServiceHeader."Contact Name",
            ServiceHeader.Address, ServiceHeader."Address 2", ServiceHeader.City,
            ServiceHeader."Post Code", ServiceHeader.County, ServiceHeader."Country/Region Code");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnBeforeValidateBillToCity', '', false, false)]
    local procedure ServiceHeaderOnBeforeValidateBillToCity(var ServiceHeader: Record "Service Header"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
        PostCodeCheck.VerifyCity(
            CurrentFieldNo, DATABASE::"Service Header", ServiceHeader.GetPosition(), 1,
            ServiceHeader."Bill-to Name", ServiceHeader."Bill-to Name 2", ServiceHeader."Bill-to Contact",
            ServiceHeader."Bill-to Address", ServiceHeader."Bill-to Address 2", ServiceHeader."Bill-to City",
            ServiceHeader."Bill-to Post Code", ServiceHeader."Bill-to County", ServiceHeader."Bill-to Country/Region Code");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnBeforeValidateBillToPostCode', '', false, false)]
    local procedure ServiceHeaderOnBeforeValidateBillToPostCode(var ServiceHeader: Record "Service Header"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
        PostCodeCheck.VerifyPostCode(
            CurrentFieldNo, DATABASE::"Service Header", ServiceHeader.GetPosition(), 1,
            ServiceHeader."Bill-to Name", ServiceHeader."Bill-to Name 2", ServiceHeader."Bill-to Contact",
            ServiceHeader."Bill-to Address", ServiceHeader."Bill-to Address 2", ServiceHeader."Bill-to City",
            ServiceHeader."Bill-to Post Code", ServiceHeader."Bill-to County", ServiceHeader."Bill-to Country/Region Code");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnBeforeValidateShipToCity', '', false, false)]
    local procedure ServiceHeaderOnBeforeValidateShipToCity(var ServiceHeader: Record "Service Header"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
        PostCodeCheck.VerifyCity(
            CurrentFieldNo, DATABASE::"Service Header", ServiceHeader.GetPosition(), 2,
            ServiceHeader."Ship-to Name", ServiceHeader."Ship-to Name 2", ServiceHeader."Ship-to Contact",
            ServiceHeader."Ship-to Address", ServiceHeader."Ship-to Address 2", ServiceHeader."Ship-to City",
            ServiceHeader."Ship-to Post Code", ServiceHeader."Ship-to County", ServiceHeader."Ship-to Country/Region Code");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnBeforeValidateShipToPostCode', '', false, false)]
    local procedure ServiceHeaderOnBeforeValidateShipToPostCode(var ServiceHeader: Record "Service Header"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
        PostCodeCheck.VerifyPostCode(
            CurrentFieldNo, DATABASE::"Service Header", ServiceHeader.GetPosition(), 2,
            ServiceHeader."Ship-to Name", ServiceHeader."Ship-to Name 2", ServiceHeader."Ship-to Contact",
            ServiceHeader."Ship-to Address", ServiceHeader."Ship-to Address 2", ServiceHeader."Ship-to City",
            ServiceHeader."Ship-to Post Code", ServiceHeader."Ship-to County", ServiceHeader."Ship-to Country/Region Code");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnAfterCopyShipToCustomerAddressFieldsFromShipToAddr', '', false, false)]
    local procedure ServiceHeaderOnAfterCopyShipToCustomerAddressFieldsFromShipToAddr(var ServiceHeader: Record "Service Header"; ShipToAddress: Record "Ship-to Address")
    begin
        PostCodeCheck.CopyAddressIDRecord(
            DATABASE::"Ship-to Address", ShipToAddress.GetPosition(), 0, DATABASE::"Service Header", ServiceHeader.GetPosition(), 2);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnAfterCopyShipToCustomerAddressFieldsFromCustomer', '', false, false)]
    local procedure ServiceHeaderOnAfterCopyShipToCustomerAddressFieldsFromCustomer(var ServiceHeader: Record "Service Header"; SellToCustomer: Record Customer)
    begin
        PostCodeCheck.CopyAddressIDRecord(
            DATABASE::Customer, SellToCustomer.GetPosition(), 0, DATABASE::"Service Header", ServiceHeader.GetPosition(), 2);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnAfterCopyBillToCustomerFields', '', false, false)]
    local procedure ServiceHeaderOnAfterCopyBillToCustomerFields(var ServiceHeader: Record "Service Header"; Customer: Record Customer)
    begin
        PostCodeCheck.CopyAddressIDRecord(
            DATABASE::Customer, Customer.GetPosition(), 0, DATABASE::"Service Header", ServiceHeader.GetPosition(), 1);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnAfterDeleteEvent', '', false, false)]
    local procedure ServiceHeaderOnAfterDeleteEvent(var Rec: Record "Service Header")
    begin
        if Rec.IsTemporary() then
            exit;

        PostCodeCheck.DeleteAddressIDRecords(DATABASE::"Service Header", Rec.GetPosition(), 0);
    end;
}
