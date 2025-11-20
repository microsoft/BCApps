// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Graph;

using Microsoft.Sales.Customer;
using Microsoft.API.Upgrade;

codeunit 5471 "Graph Mgt - Customer"
{

    trigger OnRun()
    begin
    end;

    procedure PostalAddressToJSON(var Customer: Record Customer) JSON: Text
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
    begin
        GraphMgtComplexTypes.GetPostalAddressJSON(Customer.Address, Customer."Address 2", Customer.City, Customer.County, Customer."Country/Region Code", Customer."Post Code", JSON);
    end;

    procedure UpdatePostalAddress(PostalAddressJSON: Text; var Customer: Record Customer)
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
        RecRef: RecordRef;
    begin
        if PostalAddressJSON = '' then
            exit;

        RecRef.GetTable(Customer);
        GraphMgtComplexTypes.ApplyPostalAddressFromJSON(PostalAddressJSON, RecRef,
          Customer.FieldNo(Address), Customer.FieldNo("Address 2"), Customer.FieldNo(City), Customer.FieldNo(County), Customer.FieldNo("Country/Region Code"), Customer.FieldNo("Post Code"));
        RecRef.SetTable(Customer);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Graph Mgt - General Tools", 'ApiSetup', '', false, false)]
    local procedure HandleApiSetup()
    begin
        UpdateIds();
    end;

    procedure UpdateIds()
    begin
        UpdateIds(false);
    end;

    procedure UpdateIds(WithCommit: Boolean)
    var
        Customer: Record Customer;
        APIDataUpgrade: Codeunit "API Data Upgrade";
        RecordCount: Integer;
    begin
        if not Customer.FindSet(true) then
            exit;

        repeat
            Customer.UpdateReferencedIds();
            Customer.Modify(false);
            if WithCommit then
                APIDataUpgrade.CountRecordsAndCommit(RecordCount);
        until Customer.Next() = 0;

        if WithCommit then
            Commit();
    end;
}

