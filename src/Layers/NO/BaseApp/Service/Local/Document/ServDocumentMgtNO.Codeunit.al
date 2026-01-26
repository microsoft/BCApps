// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Sales.Customer;

codeunit 10650 "Serv. Document Mgt. NO"
{
    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnUpdateServLineByChangedFieldName', '', false, false)]
    local procedure OnUpdateServLineByChangedFieldName(ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; ChangedFieldNo: Integer)
    begin
        case ChangedFieldNo of
            ServiceLine.FieldNo("Account Code"):
                begin
                    ServiceLine.Validate("Account Code", ServiceHeader."Account Code");
                    ServiceLine.Modify(true);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnAfterInitRecord', '', false, false)]
    local procedure OnAfterInitRecord(var ServiceHeader: Record "Service Header")
    begin
        ServiceHeader."Delivery Date" := ServiceHeader."Posting Date";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnAfterCopyCustomerFields', '', false, false)]
    local procedure OnAfterCopyCustomerFields(var ServiceHeader: Record "Service Header"; Customer: Record Customer)
    begin
        ServiceHeader."Account Code" := Customer."Account Code";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnAfterCopyBillToCustomerFields', '', false, false)]
    local procedure OnAfterCopyBillToCustomerFields(var ServiceHeader: Record "Service Header"; Customer: Record Customer)
    begin
        ServiceHeader.GLN := Customer.GLN;
        ServiceHeader."E-Invoice" := Customer."E-Invoice";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Line", 'OnAfterAssignHeaderValues', '', false, false)]
    local procedure OnAfterAssignHeaderValues(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header")
    begin
        ServiceLine."Account Code" := ServiceHeader."Account Code";
    end;
}

