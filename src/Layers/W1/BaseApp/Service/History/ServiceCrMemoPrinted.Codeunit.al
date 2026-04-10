// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.History;

codeunit 5904 "Service Cr. Memo-Printed"
{
    Permissions = TableData "Service Cr.Memo Header" = rimd;
    TableNo = "Service Cr.Memo Header";

    trigger OnRun()
    begin
        OnBeforeRun(Rec, SuppressCommit);
        Rec.Find();
        Rec."No. Printed" := Rec."No. Printed" + 1;
        OnBeforeModify(Rec);
        Rec.Modify();
        if not SuppressCommit then
            Commit();
    end;

    var
        SuppressCommit: Boolean;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModify(var ServiceCrMemoHeader: Record "Service Cr.Memo Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRun(var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; var SuppressCommit: Boolean)
    begin
    end;
}

