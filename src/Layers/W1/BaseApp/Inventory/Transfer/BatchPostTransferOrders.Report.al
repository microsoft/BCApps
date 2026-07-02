// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Transfer;

using System.Utilities;

report 5707 "Batch Post Transfer Orders"
{
    ApplicationArea = All;
    Caption = 'Batch Post Transfer Orders';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Transfer Header"; "Transfer Header")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", Status, "Direct Transfer", "Transfer-from Code", "Transfer-to Code";
            RequestFilterHeading = 'Transfer Order';

            trigger OnPostDataItem()
            begin
                RunPostBatchTransferOrder("Transfer Header");
                CurrReport.Break();
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(Content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(TransferOption; TransferOrderPost)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Transfer option';
                        ToolTip = 'Specifies the posting option of the Transfer Orders. Direct Transfer will always be posted. To prefent this use the filtering.';
                    }
                }
            }
        }
    }

    var
        TransferOrderPost: Enum "Transfer Order Post";

    [ErrorBehavior(ErrorBehavior::Collect)]
    internal procedure RunPostBatchTransferOrder(var TransferHeader: Record "Transfer Header")
    var
        ErrorContextElement: Codeunit "Error Context Element";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        ErrorMessageManagement: Codeunit "Error Message Management";
        TransferOrderPostYesNo: Codeunit "TransferOrder-Post (Yes/No)";
        IsHandled: Boolean;
        AdditionalInfoLbl: Label 'Batch post Transfer Order record';
    begin
        IsHandled := false;
        OnCodeOnBeforePostTransferOrder(TransferHeader, TransferOrderPost, IsHandled);
        if IsHandled then
            exit;

        ErrorMessageManagement.Activate(ErrorMessageHandler);
        ErrorMessageManagement.PushContext(ErrorContextElement, TransferHeader, 0, AdditionalInfoLbl);

        TransferOrderPostYesNo.SetParameters(true, TransferOrderPost);
        if TransferHeader.FindSet() then
            repeat
                if not TransferOrderPostYesNo.Run(TransferHeader) then
                    ErrorMessageManagement.LogErrorMessage(0, GetLastErrorText(), TransferHeader, 0, '');
            until TransferHeader.Next() = 0;

        OnRunPostBatchTransferOrderOnAfterPost(TransferHeader, TransferOrderPost, ErrorMessageHandler);

        if ErrorMessageHandler.HasErrors() then
            ErrorMessageHandler.NotifyAboutErrors();

        ClearCollectedErrors();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforePostTransferOrder(var TransferHeader: Record "Transfer Header"; var TransferOrderPost: Enum "Transfer Order Post"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunPostBatchTransferOrderOnAfterPost(var TransferHeader: Record "Transfer Header"; var TransferOrderPost: Enum "Transfer Order Post"; var ErrorMessageHandler: Codeunit "Error Message Handler")
    begin
    end;
}
