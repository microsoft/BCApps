// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Graph;

using Microsoft.Purchases.Vendor;
using Microsoft.API.Upgrade;

codeunit 5472 "Graph Mgt - Vendor"
{

    trigger OnRun()
    begin
    end;

    procedure PostalAddressToJSON(var Vendor: Record Vendor) JSON: Text
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
    begin
        GraphMgtComplexTypes.GetPostalAddressJSON(Vendor.Address, Vendor."Address 2", Vendor.City, Vendor.County, Vendor."Country/Region Code", Vendor."Post Code", JSON);
    end;

    procedure UpdatePostalAddress(PostalAddressJSON: Text; var Vendor: Record Vendor)
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
        RecRef: RecordRef;
    begin
        if PostalAddressJSON = '' then
            exit;

        RecRef.GetTable(Vendor);
        GraphMgtComplexTypes.ApplyPostalAddressFromJSON(PostalAddressJSON, RecRef,
          Vendor.FieldNo(Address), Vendor.FieldNo("Address 2"), Vendor.FieldNo(City), Vendor.FieldNo(County), Vendor.FieldNo("Country/Region Code"), Vendor.FieldNo("Post Code"));
        RecRef.SetTable(Vendor);
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
        Vendor: Record Vendor;
        APIDataUpgrade: Codeunit "API Data Upgrade";
        RecordCount: Integer;
    begin
        if not Vendor.FindSet(true) then
            exit;

        repeat
            Vendor.UpdateReferencedIds();
            Vendor.Modify(false);
            if WithCommit then
                APIDataUpgrade.CountRecordsAndCommit(RecordCount);
        until Vendor.Next() = 0;

        if WithCommit then
            Commit();
    end;

}

