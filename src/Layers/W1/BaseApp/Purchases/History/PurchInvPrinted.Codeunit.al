// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

codeunit 319 "Purch. Inv.-Printed"
{
    Permissions = TableData "Purch. Inv. Header" = rimd;
    TableNo = "Purch. Inv. Header";

    trigger OnRun()
    begin
        OnBeforeOnRun(Rec, SuppressCommit);
        Rec.Find();
        Rec."No. Printed" := Rec."No. Printed" + 1;
        OnBeforeModify(Rec);
        Rec.Modify();
        if not SuppressCommit then
            Commit();
    end;

    var
        SuppressCommit: Boolean;

    procedure SetSuppressCommit(NewSuppressCommit: Boolean)
    begin
        SuppressCommit := NewSuppressCommit;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModify(var PurchInvHeader: Record "Purch. Inv. Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var PurchInvHeader: Record "Purch. Inv. Header"; var SuppressCommit: Boolean)
    begin
    end;
}

