// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Sales.Customer;
using Microsoft.Service.Contract;

codeunit 11412 "Serv. Document Mgt. NL"
{
    [EventSubscriber(ObjectType::Table, Database::"Service Contract Header", 'OnAfterValidateEvent', 'Bill-to Customer No.', false, false)]
    local procedure ServiceContractHeaderOnAfterValidateEventBilltoCustomerNo(var Rec: Record "Service Contract Header")
    var
        Customer: Record Customer;
    begin
        Customer.Get(Rec."Bill-to Customer No.");
        Rec."Transaction Mode Code" := Customer."Transaction Mode Code";
        Rec."Bank Account Code" := Customer."Preferred Bank Account Code";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnAfterCopyBillToCustomerFields', '', false, false)]
    local procedure OnAfterCopyBillToCustomerFields(var ServiceHeader: Record "Service Header"; Customer: Record Customer)
    begin
        ServiceHeader."Transaction Mode Code" := Customer."Transaction Mode Code";
        ServiceHeader."Bank Account Code" := Customer."Preferred Bank Account Code";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnAfterCopyToGenJnlLinePayment', '', false, false)]
    local procedure OnAfterCopyToGenJnlLinePayment(var GenJournalLine: Record "Gen. Journal Line"; ServiceHeader: Record "Service Header")
    begin
        GenJournalLine."Transaction Mode Code" := ServiceHeader."Transaction Mode Code";
        GenJournalLine."Recipient Bank Account" := ServiceHeader."Bank Account Code";
    end;

}