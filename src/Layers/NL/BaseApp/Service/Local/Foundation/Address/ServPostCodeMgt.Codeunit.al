// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Address;

using Microsoft.Service.Document;

codeunit 11411 "Serv. Post Code Mgt."
{
    var
        PostCodeManagement: Codeunit "Post Code Management";

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnBeforeValidateEvent', 'Bill-to Address', false, false)]
    local procedure ServiceHeaderOnAfterValidateBillToAddress(var Rec: Record "Service Header")
    begin
        PostCodeManagement.FindStreetName(
            Rec."Bill-to Address", Rec."Bill-to Address 2", Rec."Bill-to Post Code", Rec."Bill-to City",
            Rec."Bill-to Country/Region Code", Rec."Phone No.", Rec."Fax No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnBeforeValidateEvent', 'Ship-to Address', false, false)]
    local procedure ServiceHeaderOnAfterValidateShipToAddress(var Rec: Record "Service Header")
    begin
        PostCodeManagement.FindStreetName(
            Rec."Ship-to Address", Rec."Ship-to Address 2", Rec."Ship-to Post Code", Rec."Ship-to City",
            Rec."Ship-to Country/Region Code", Rec."Ship-to Phone", Rec."Ship-to Fax No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnBeforeValidateEvent', 'Address', false, false)]
    local procedure ServiceHeaderOnAfterValidateAddress(var Rec: Record "Service Header")
    var
        PhoneNo: Text[30];
        FaxNo: Text[30];
    begin
        PostCodeManagement.FindStreetName(
            Rec.Address, Rec."Address 2", Rec."Post Code", Rec.City, Rec."Country/Region Code", PhoneNo, FaxNo);
    end;
}