// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CashFlow.Forecast;

using Microsoft.Service.Document;
using Microsoft.CashFlow.Setup;

codeunit 891 "Serv. Cash Flow Management"
{
    var
        SourceDataDoesNotExistErr: Label 'Source data does not exist for %1: %2.', Comment = '%1 - G/L Account, %2 - account number';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Cash Flow Management", 'OnShowSourceLocalSourceTypeCase', '', false, false)]
    local procedure OnShowSourceLocalSourceTypeCase(SourceType: Enum "Cash Flow Source Type"; SourceNo: Code[20]; var IsHandled: Boolean)
    begin
        if SourceType = SourceType::"Service Orders" then begin
            ShowServiceOrder(SourceNo);
            IsHandled := true;
        end;
    end;

    local procedure ShowServiceOrder(SourceNo: Code[20])
    var
        ServiceHeader: Record "Service Header";
        ServiceOrder: Page "Service Order";
        SourceType: Enum "Cash Flow Source Type";
    begin
        ServiceHeader.SetRange("Document Type", ServiceHeader."Document Type"::Order);
        ServiceHeader.SetRange("No.", SourceNo);
        if not ServiceHeader.FindFirst() then
            Error(SourceDataDoesNotExistErr, SourceType::"Service Orders", SourceNo);
        ServiceOrder.SetTableView(ServiceHeader);
        ServiceOrder.Run();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Cash Flow Management", 'OnAfterCreateCashFlowAccounts', '', false, false)]
    local procedure OnAfterCreateCashFlowAccounts(var sender: Codeunit "Cash Flow Management")
    begin
        sender.CreateCashFlowAccount("Cash Flow Source Type"::"Service Orders", '');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Cash Flow Management", 'OnBeforeInsertOnCreateCashFlowSetup', '', false, false)]
    local procedure OnBeforeInsertOnCreateCashFlowSetup(var CashFlowSetup: Record "Cash Flow Setup"; sender: Codeunit "Cash Flow Management")
    begin
        CashFlowSetup.Validate("Service CF Account No.", sender.GetNoFromSourceType("Cash Flow Source Type"::"Service Orders".AsInteger()));
    end;
}
