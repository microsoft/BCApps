// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Archive;

/// <summary>
/// Increments the print count for archived sales documents when they are printed.
/// </summary>
codeunit 322 "SalesCount-PrintedArch"
{
    TableNo = "Sales Header Archive";

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

    /// <summary>
    /// Sets whether to suppress the commit operation after incrementing the print count.
    /// </summary>
    /// <param name="NewSuppressCommit">Specifies whether to suppress the commit operation.</param>
    procedure SetSuppressCommit(NewSuppressCommit: Boolean)
    begin
        SuppressCommit := NewSuppressCommit;
    end;

    /// <summary>
    /// Raises an event before modifying the sales header archive record with the updated print count.
    /// </summary>
    /// <param name="SalesHeaderArchive">Specifies the sales header archive record being modified.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeModify(var SalesHeaderArchive: Record "Sales Header Archive")
    begin
    end;

    /// <summary>
    /// Raises an event before running the codeunit to increment the print count, allowing modification of the record or commit behavior.
    /// </summary>
    /// <param name="SalesHeaderArchive">Specifies the sales header archive record whose print count will be incremented.</param>
    /// <param name="SuppressCommit">Set to true to suppress the commit operation after incrementing the count.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var SalesHeaderArchive: Record "Sales Header Archive"; var SuppressCommit: Boolean)
    begin
    end;
}

