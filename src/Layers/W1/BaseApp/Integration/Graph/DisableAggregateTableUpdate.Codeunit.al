// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Graph;

using Microsoft.Sales.Document;
using Microsoft.Integration.Entity;

codeunit 5532 "Disable Aggregate Table Update"
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin

    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Disable Aggregate Table Update", 'OnGetAggregateTablesUpdateEnabled', '', false, false)]
    local procedure GetAggregateTablesUpdateEnabled(var UpdatesDisabled: Boolean; AggregateTableID: Integer; TableSystemId: Guid)
    begin
        if UpdatesDisabled then
            exit;

        if DisableAllRecords then begin
            UpdatesDisabled := true;
            exit;
        end;

        if AggregateTableIDDisabled <> AggregateTableID then
            exit;

        if TableSystemId = TableSystemIDDisabled then
            UpdatesDisabled := true;
    end;

    procedure SetAggregateTableIDDisabled(NewAggregateTableIDDisabled: Integer)
    begin
        AggregateTableIDDisabled := NewAggregateTableIDDisabled;
    end;

    procedure SetTableSystemIDDisabled(NewTableSystemIDDisabled: Guid)
    begin
        TableSystemIDDisabled := NewTableSystemIDDisabled;
    end;

    procedure SetDisableAllRecords(NewDisableAllRecords: Boolean)
    begin
        DisableAllRecords := NewDisableAllRecords;
    end;

    procedure GetAggregateTableIDFromSalesHeader(var SalesHeader: Record "Sales Header"): Integer
    begin
        case SalesHeader."Document Type" of
            SalesHeader."Document Type"::Invoice:
                exit(Database::"Sales Invoice Entity Aggregate");
            SalesHeader."Document Type"::Order:
                exit(Database::"Sales Order Entity Buffer");
            SalesHeader."Document Type"::Quote:
                exit(Database::"Sales Quote Entity Buffer");
            SalesHeader."Document Type"::"Credit Memo":
                exit(Database::"Sales Cr. Memo Entity Buffer");
            else
                exit(-1);
        end;

    end;

    [IntegrationEvent(false, false)]
    internal procedure OnGetAggregateTablesUpdateEnabled(var UpdatesDisabled: Boolean; AggregateTableID: Integer; TableSystemId: Guid)
    begin
    end;

    var
        AggregateTableIDDisabled: Integer;
        TableSystemIDDisabled: Guid;
        DisableAllRecords: Boolean;
}