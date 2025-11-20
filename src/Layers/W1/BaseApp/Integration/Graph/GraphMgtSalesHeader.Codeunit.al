// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Graph;

using Microsoft.Integration.Entity;
using Microsoft.API.Upgrade;

codeunit 5474 "Graph Mgt - Sales Header"
{
    // // This Graph Mgt code unit is used to generate id fields for all
    // // sales docs other than invoice and order. If special logic is required
    // // for any of these sales docs, create a seperate code unit.


    trigger OnRun()
    begin
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
        SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate";
        APIDataUpgrade: Codeunit "API Data Upgrade";
        RecordCount: Integer;
    begin
        if SalesInvoiceEntityAggregate.FindSet() then begin
            repeat
                SalesInvoiceEntityAggregate.UpdateReferencedRecordIds();
                SalesInvoiceEntityAggregate.Modify(false);
                if WithCommit then
                    APIDataUpgrade.CountRecordsAndCommit(RecordCount);
            until SalesInvoiceEntityAggregate.Next() = 0;

            if WithCommit then
                Commit();
        end;
    end;
}

