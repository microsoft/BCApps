// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

codeunit 5905 "Service-Printed"
{
    TableNo = "Service Header";

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

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModify(var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var ServiceHeader: Record "Service Header"; var SuppressCommit: Boolean)
    begin
    end;
}

