// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Graph;

using Microsoft.HumanResources.Employee;

codeunit 5483 "Graph Mgt - Employee"
{

    trigger OnRun()
    begin
    end;

    procedure ProcessComplexTypes(var Employee: Record Employee; PostalAddressJSON: Text)
    begin
        UpdatePostalAddress(PostalAddressJSON, Employee);
    end;

    procedure PostalAddressToJSON(Employee: Record Employee) JSON: Text
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
    begin
        GraphMgtComplexTypes.GetPostalAddressJSON(Employee.Address, Employee."Address 2", Employee.City, Employee.County, Employee."Country/Region Code", Employee."Post Code", JSON);
    end;

    local procedure UpdatePostalAddress(PostalAddressJSON: Text; var Employee: Record Employee)
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
        RecRef: RecordRef;
    begin
        if PostalAddressJSON = '' then
            exit;

        RecRef.GetTable(Employee);
        GraphMgtComplexTypes.ApplyPostalAddressFromJSON(PostalAddressJSON, RecRef,
          Employee.FieldNo(Address), Employee.FieldNo("Address 2"), Employee.FieldNo(City), Employee.FieldNo(County), Employee.FieldNo("Country/Region Code"), Employee.FieldNo("Post Code"));
        RecRef.SetTable(Employee);
    end;
}
