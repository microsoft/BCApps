// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SpendRequest;

using System.Utilities;

codeunit 6840 "Submit Spend Request"
{
    TableNo = "Spend Request";

    trigger OnRun()
    begin
        Submit(Rec);
    end;

    var
        HasExpensesErr: Label 'A spend request with posted expenses cannot be reopened.';
        ClosedRequestErr: Label 'A closed spend request cannot be reopened.';
        CloseSpendRequestQst: Label 'Do you want to close spend request %1?', Comment = '%1 is the spend request no.';
        PendingApprovalErr: Label 'The approval process must be cancelled or completed to reopen this document.';

    /// <summary>
    /// Sets the status of the spend request to Submitted.
    /// </summary>
    /// <param name="SpendRequest">The spend request to Submit.</param>
    procedure Submit(var SpendRequest: Record "Spend Request")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSubmit(SpendRequest, IsHandled);
        if IsHandled then
            exit;

        if SpendRequest.Status = SpendRequest.Status::Submitted then
            exit;
        SpendRequest.TestField(Status, SpendRequest.Status::Open);
        SpendRequest.Status := SpendRequest.Status::Submitted;
        SpendRequest.Modify();

        OnAfterSubmit(SpendRequest);
    end;

    /// <summary>
    /// Sets the status of the spend request back to Open so it can be edited again.
    /// </summary>
    /// <param name="SpendRequest">The spend request to reopen.</param>
    procedure Reopen(var SpendRequest: Record "Spend Request")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeReopen(SpendRequest, IsHandled);
        if IsHandled then
            exit;

        if SpendRequest.Status = SpendRequest.Status::Open then
            exit;

        if SpendRequest.Status = SpendRequest.Status::Closed then
            Error(ClosedRequestErr);

        SpendRequest.CalcFields("Total Spent Amount (LCY)");
        if SpendRequest."Total Spent Amount (LCY)" <> 0 then
            Error(HasExpensesErr);

        SpendRequest.Status := SpendRequest.Status::Open;
        SpendRequest.Modify();

        OnAfterReopen(SpendRequest);
    end;

    /// <summary>
    /// Sets the status of the spend request to Closed so it cannot be used anymore.
    /// </summary>
    /// <param name="SpendRequest">The spend request to close.</param>
    procedure Close(var SpendRequest: Record "Spend Request")
    var
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeClose(SpendRequest, IsHandled);
        if IsHandled then
            exit;

        if SpendRequest.Status = SpendRequest.Status::Closed then
            exit;

        if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(CloseSpendRequestQst, SpendRequest."No."), true) then
            exit;

        SpendRequest.Status := SpendRequest.Status::Closed;
        SpendRequest.Modify();

        OnAfterClose(SpendRequest);
    end;

    /// <summary>
    /// Performs a manual Submit of the spend request triggered from the UI.
    /// </summary>
    /// <param name="SpendRequest">The spend request to Submit.</param>
    procedure PerformManualSubmit(var SpendRequest: Record "Spend Request")
    begin
        Codeunit.Run(Codeunit::"Submit Spend Request", SpendRequest);
    end;

    /// <summary>
    /// Performs a manual reopen of the spend request triggered from the UI.
    /// </summary>
    /// <param name="SpendRequest">The spend request to reopen.</param>
    procedure PerformManualReopen(var SpendRequest: Record "Spend Request")
    begin
        if SpendRequest.Status = SpendRequest.Status::"Pending Approval" then
            Error(PendingApprovalErr);

        Reopen(SpendRequest);
    end;

    /// <summary>
    /// Performs a manual close of the spend request triggered from the UI.
    /// </summary>
    /// <param name="SpendRequest">The spend request to close.</param>
    procedure PerformManualClose(var SpendRequest: Record "Spend Request")
    begin
        Close(SpendRequest);
    end;

    /// <summary>
    /// Integration event raised before releasing the spend request.
    /// </summary>
    /// <param name="SpendRequest">The spend request being Submitted.</param>
    /// <param name="IsHandled">Set to true to skip the standard Submit logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSubmit(var SpendRequest: Record "Spend Request"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised after releasing the spend request.
    /// </summary>
    /// <param name="SpendRequest">The spend request that was Submitted.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterSubmit(var SpendRequest: Record "Spend Request")
    begin
    end;

    /// <summary>
    /// Integration event raised before reopening the spend request.
    /// </summary>
    /// <param name="SpendRequest">The spend request being reopened.</param>
    /// <param name="IsHandled">Set to true to skip the standard reopen logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeReopen(var SpendRequest: Record "Spend Request"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised after reopening the spend request.
    /// </summary>
    /// <param name="SpendRequest">The spend request that was reopened.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterReopen(var SpendRequest: Record "Spend Request")
    begin
    end;

    /// <summary>
    /// Integration event raised before closing the spend request.
    /// </summary>
    /// <param name="SpendRequest">The spend request being closed.</param>
    /// <param name="IsHandled">Set to true to skip the standard close logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeClose(var SpendRequest: Record "Spend Request"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised after closing the spend request.
    /// </summary>
    /// <param name="SpendRequest">The spend request that was closed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterClose(var SpendRequest: Record "Spend Request")
    begin
    end;
}
