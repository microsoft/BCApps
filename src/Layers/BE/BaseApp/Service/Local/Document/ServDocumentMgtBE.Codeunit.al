// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Sales.Customer;

codeunit 11350 "Serv. Document Mgt. BE"
{
    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnAfterCopyCustomerFields', '', false, false)]
    local procedure ServiceHeaderOnAfterCopyCustomerFields(var ServiceHeader: Record "Service Header"; Customer: Record Customer)
    begin
        ServiceHeader."Enterprise No." := Customer."Enterprise No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnAfterCopyBillToCustomerFields', '', false, false)]
    local procedure ServiceHeaderOnAfterCopyBillToCustomerFields(var ServiceHeader: Record "Service Header"; Customer: Record Customer)
    begin
        ServiceHeader."Enterprise No." := Customer."Enterprise No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnAfterCopyToGenJnlLine', '', false, false)]
    local procedure ServiceHeaderOnAfterCopyToGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; ServiceHeader: Record "Service Header")
    begin
        GenJournalLine."Enterprise No." := ServiceHeader."Enterprise No.";
    end;
}
