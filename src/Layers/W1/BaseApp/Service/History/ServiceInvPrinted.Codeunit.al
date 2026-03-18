// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.History;

codeunit 5902 "Service Inv.-Printed"
{
    Permissions = TableData "Service Invoice Header" = rimd;
    TableNo = "Service Invoice Header";

    trigger OnRun()
    var
        SuppressCommit: Boolean;
    begin
        OnBeforeOnRun(Rec, SuppressCommit);
        Rec.Find();
        Rec."No. Printed" := Rec."No. Printed" + 1;
        OnBeforeModify(Rec);
        Rec.Modify();
        if not SuppressCommit then
            Commit();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModify(var ServiceInvoiceHeader: Record "Service Invoice Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var ServiceInvoiceHeader: Record "Service Invoice Header"; var SuppressCommit: Boolean)
    begin
    end;
}

