// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance;

using System.Utilities;

codeunit 31118 "EET Management CZL"
{
    Permissions = tabledata "EET Entry CZL" = rimd,
                  tabledata "EET Service Setup CZL" = r;

    var
        TempErrorMessage: Record "Error Message" temporary;
        WarningsTxt: Label 'Warnings...';

    procedure IsEETEnabled() EETEnabled: Boolean
    var
        EETServiceSetupCZL: Record "EET Service Setup CZL";
    begin
        EETEnabled := EETServiceSetupCZL.Get() and EETServiceSetupCZL.Enabled;
        OnAfterIsEETEnabled(EETEnabled);
    end;

    procedure TrySendEntryToService(EETEntryNo: Integer)
    var
        EETEntryCZL: Record "EET Entry CZL";
    begin
        if not EETEntryCZL.Get(EETEntryNo) then
            exit;

        TrySendEntryToService(EETEntryCZL);
    end;

    procedure TrySendEntryToService(EETEntryCZL: Record "EET Entry CZL")
    begin
        if EETEntryCZL.Status = EETEntryCZL.Status::Created then
            EETEntryCZL.ChangeStatus(EETEntryCZL."Status"::"Send Pending");
        if EETEntryCZL."Sales Regime" = EETEntryCZL."Sales Regime"::Regular then
            SendEntryToService(EETEntryCZL, false);
    end;

    internal procedure SendEntryToService(EETEntryCZL: Record "EET Entry CZL"; VerificationMode: Boolean)
    begin
        EETEntryCZL.TestField("Entry No.");
        TempErrorMessage.ClearLog();
        if not VerificationMode then
            SendEntryToRegister(EETEntryCZL)
        else
            SendEntryToVerification(EETEntryCZL);
    end;

    local procedure SendEntryToRegister(EETEntryCZL: Record "EET Entry CZL")
    var
        EETServiceManagementCZL: Codeunit "EET Service Management CZL";
        NewDescription: Text;
    begin
        if EETEntryCZL."Status" in [EETEntryCZL."Status"::Sent,
                                    EETEntryCZL."Status"::Success,
                                    EETEntryCZL."Status"::"Success with Warnings"]
        then
            EETEntryCZL.FieldError("Status");

        PrepareEntryToSend(EETEntryCZL);
        EETEntryCZL.ChangeStatus(EETEntryCZL."Status"::Sent);
        if EETServiceManagementCZL.Send(EETEntryCZL) then begin
            EETEntryCZL."Acknowledgement Code" := EETServiceManagementCZL.GetPOKControlCode();
            EETEntryCZL."Status" := EETEntryCZL."Status"::Success;
            if EETServiceManagementCZL.HasWarnings() then begin
                EETEntryCZL."Status" := EETEntryCZL."Status"::"Success with Warnings";
                NewDescription := WarningsTxt;
            end;
        end else begin
            EETEntryCZL."Status" := EETEntryCZL."Status"::Failure;
            EETEntryCZL."Failed Send Attempts" += 1;
            NewDescription := EETServiceManagementCZL.GetResponseText();
        end;

        EETServiceManagementCZL.CopyErrorMessageToTemp(TempErrorMessage);
        EETEntryCZL.ChangeStatus(EETEntryCZL."Status", NewDescription, TempErrorMessage,
            EETServiceManagementCZL.GetHttpRequestMessage(), EETServiceManagementCZL.GetHttpResponseMessage());
        if (EETEntryCZL."Status" = EETEntryCZL."Status"::Failure) and EETServiceManagementCZL.IsRetryableFailure() then
            UpdateSendRetryState(EETEntryCZL);
    end;

    local procedure UpdateSendRetryState(var EETEntryCZL: Record "EET Entry CZL")
    var
        EETServiceSetupCZL: Record "EET Service Setup CZL";
        RetryDescriptionTxt: Label 'Repeated attempt to send the entry (retry %1 of %2).', Comment = '%1 = number of the retry, %2 = maximum number of retries';
    begin
        if not EETServiceSetupCZL.Get() then
            EETServiceSetupCZL.Init();
        if EETEntryCZL."Failed Send Attempts" > EETServiceSetupCZL."Maximum Send Retries" then
            exit;

        EETEntryCZL.ChangeStatus(
            EETEntryCZL."Status"::"Send Pending",
            StrSubstNo(RetryDescriptionTxt, EETEntryCZL."Failed Send Attempts", EETServiceSetupCZL."Maximum Send Retries"));
    end;

    local procedure SendEntryToVerification(EETEntryCZL: Record "EET Entry CZL")
    var
        EETServiceManagementCZL: Codeunit "EET Service Management CZL";
        NewDescription: Text;
    begin
        if EETEntryCZL."Status" in [EETEntryCZL."Status"::Sent,
                                    EETEntryCZL."Status"::"Sent to Verification",
                                    EETEntryCZL."Status"::Success,
                                    EETEntryCZL."Status"::"Success with Warnings"]
        then
            EETEntryCZL.FieldError("Status");

        PrepareEntryToSend(EETEntryCZL);
        EETEntryCZL.ChangeStatus(EETEntryCZL."Status"::"Sent to Verification");

        EETServiceManagementCZL.SetVerificationMode(true);
        if EETServiceManagementCZL.Send(EETEntryCZL) then begin
            EETEntryCZL."Status" := EETEntryCZL."Status"::Verified;
            if EETServiceManagementCZL.HasWarnings() then begin
                EETEntryCZL."Status" := EETEntryCZL."Status"::"Verified with Warnings";
                NewDescription := WarningsTxt;
            end;
        end else begin
            EETEntryCZL."Status" := EETEntryCZL."Status"::Failure;
            NewDescription := EETServiceManagementCZL.GetResponseText();
        end;

        EETServiceManagementCZL.CopyErrorMessageToTemp(TempErrorMessage);
        EETEntryCZL.ChangeStatus(EETEntryCZL."Status", NewDescription, TempErrorMessage,
            EETServiceManagementCZL.GetHttpRequestMessage(), EETServiceManagementCZL.GetHttpResponseMessage());
    end;

    local procedure PrepareEntryToSend(var EETEntryCZL: Record "EET Entry CZL")
    begin
        EETEntryCZL."Message UUID" := CreateUUID();
        EETEntryCZL.Modify();
    end;

    procedure CreateUUID(): Text[36]
    begin
        exit(CopyStr(DelChr(LowerCase(Format(CreateGuid())), '=', '{}'), 1, 36));
    end;

    procedure CreateCancelEETEntry(EETEntryCZL: Record "EET Entry CZL"): Integer
    var
        CancelEETEntryNo: Integer;
        IsHandled: Boolean;
    begin
        OnBeforeCreateCancelEETEntry(EETEntryCZL, CancelEETEntryNo, IsHandled);
        if IsHandled then
            exit(CancelEETEntryNo);

        EETEntryCZL.ReverseAmounts();
        exit(CreateSimpleEETEntry(EETEntryCZL));
    end;

    procedure CreateSimpleEETEntry(SourceEETEntryCZL: Record "EET Entry CZL"): Integer
    var
        EETEntryCZL: Record "EET Entry CZL";
    begin
        EETEntryCZL.Init();
        EETEntryCZL.CopyFromEETEntry(SourceEETEntryCZL);
        EETEntryCZL."Receipt Serial No." := '';
        EETEntryCZL."Simple Registration" := true;
        OnCreateSimpleEETEntryOnBeforeInsertEETEntry(EETEntryCZL);
        EETEntryCZL.Insert(true);
        exit(EETEntryCZL."Entry No.");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsEETEnabled(var EETEnabled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateCancelEETEntry(EETEntryCZL: Record "EET Entry CZL"; var CancelEETEntryNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSimpleEETEntryOnBeforeInsertEETEntry(var EETEntryCZL: Record "EET Entry CZL")
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnIsRetryableFailure(CommunicationFailed: Boolean; ResponseContentErrorCode: Text; GlobalHttpResponseMessage: HttpResponseMessage; var RetryableFailure: Boolean)
    begin
    end;
}
