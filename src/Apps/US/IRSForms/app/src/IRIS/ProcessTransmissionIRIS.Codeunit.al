// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Purchases.Vendor;
using System.Environment;
using System.Telemetry;
using System.Utilities;

codeunit 10056 "Process Transmission IRIS"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        Helper: Codeunit "Helper IRIS";
        OAuthClient: Codeunit "OAuth Client IRIS";
        ProcessResponse: Codeunit "Process Response IRIS";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        EnvironmentInformation: Codeunit "Environment Information";
        ConfirmMgt: Codeunit "Confirm Management";
        Supplemental: Codeunit "IRS 1099 Supplemental";
        RequestStatusEventTxt: Label 'RequestStatus', Locked = true;
        RequestAcknowledgEventTxt: Label 'RequestAcknowledgment', Locked = true;
        FormDocsUpdateStartedEventTxt: Label 'FormDocsUpdateStarted', Locked = true;
        FormDocsUpdateCompletedEventTxt: Label 'FormDocsUpdateCompleted', Locked = true;
        ReceiptIDUpdatedEventTxt: Label 'ReceiptIDUpdated', Locked = true;
        SubmissionEventTok: Label 'SubmitTransmission', Locked = true;
        SubmissionStartedLbl: Label '%1 submission started.', Locked = true, Comment = '%1 = submission type';
        SubmissionReceiptConfirmedLbl: Label 'IRIS confirmed receipt of the submission.', Locked = true;
        SubmissionFailedErr: Label 'IRIS rejected the submission request.', Locked = true;
        SubmissionUnconfirmedErr: Label 'The submission request did not confirm receipt by IRIS.', Locked = true;
        SubmissionUnconfirmedMsg: Label 'IRIS did not confirm receipt of the submission. It may have been received. Use Request Status by UTID before sending again.';
        SubmissionReceiptMissingErr: Label 'The submission response did not contain a receipt ID.', Locked = true;
        CorrectionHistoryTok: Label 'CheckCorrectionHistory', Locked = true;
        MissingCorrectionHistoryErr: Label 'Previous IRS filing details required for a correction are missing.', Locked = true;
        AcknowledgmentIdentityTok: Label 'CheckAcknowledgmentIdentity', Locked = true;
        MissingAcknowledgmentAttemptErr: Label 'The acknowledgment transmission attempt could not be found in local history.', Locked = true;
        AcknowledgmentIdentityTelemetryErr: Label 'The acknowledgment does not match the requested transmission attempt.', Locked = true;
        IRSValidationTok: Label 'IRSValidation', Locked = true;
        XmlSchemaValidationTelemetryErr: Label 'IRS XML schema validation failed.', Locked = true;
        IRSValidationTelemetryErr: Label 'IRS returned validation errors.', Locked = true;
        StatusTransitionLbl: Label 'IRIS transmission status changed.', Locked = true;
        CorrectionsAppliedTok: Label 'CorrectionsApplied', Locked = true;
        TransmCanOnlyBeSentInSaaSErr: Label 'The transmission can only be sent electronically in the SaaS environment.';
        TransmHasOpenedOrAbandonedDocsQst: Label 'The transmission contains open or abandoned 1099 form documents that will not be sent to the IRS.\Do you want to continue?';
        TransmissionNotSentErr: Label 'The transmission has no confirmed IRS status that allows replacement or correction. If it may already have been sent, use Request Status by UTID before sending again.';
        TransmissionIsProcessingErr: Label 'The IRS is still processing the transmission. Do not send it again while it is processing. Use Request Status to get the updated status.';
        TransmissionAcceptedErr: Label 'The transmission has been accepted and can only be corrected.';
        TransmissionAcceptedWithErrorsErr: Label 'The transmission has been accepted with errors and can only be corrected.';
        TransmissionPartiallyAcceptedErr: Label 'The transmission has been partially accepted and can only be replaced or corrected.';
        TransmissionRejectedErr: Label 'The transmission has been rejected. Use Send Replacement for rejected original returns or Send Correction for rejected corrections.';
        NoLinesMarkedForCorrectionErr: Label 'Select Needs Correction for at least one form document to send a correction.';
        NewDocCorrectionErr: Label '1099 form document %1 for vendor %2, form %3, period %4 has no recorded IRIS submission to correct. Clear Needs Correction for this document. Only forms that have never been submitted should be sent as original returns. If this document may already have been submitted, use Request Status by UTID before sending again.', Comment = '%1 = document ID, %2 = vendor number, %3 = form number, %4 = reporting period';
        MissingCorrectionDetailsErr: Label '1099 form document %1 for vendor %2, form %3, period %4 is missing previous IRS filing details required for a correction. Use Request Status to retrieve the IRS acknowledgment. The document cannot be corrected in Business Central while these details are missing. Do not submit this document as a new original return.', Comment = '%1 = document ID, %2 = vendor number, %3 = form number, %4 = reporting period';
        TransmissionDocUpToDateErr: Label 'The transmission document is already up-to-date.';
        FormDocsAddedMsg: Label '• Added %1 existing released form documents to the transmission.\', Comment = '%1 - number of added form documents';
        FormLinesUpdatedMsg: Label '• The amounts of the selected IRS 1099 form document lines were updated.\';
        FormDocsCreatedMsg: Label '• The new IRS 1099 form documents were created for the selected lines.\';
        NoFormLinesSelectedMsg: Label 'No IRS 1099 form document lines were selected for updating amounts or creating new IRS 1099 form documents.';
        SendOriginalWhenNotFoundQst: Label 'Sending this transmission as an original may duplicate returns already received by the IRS. Use Request Status by UTID before sending again. If the IRIS help desk provides a receipt ID, use Assign Receipt ID, then Request Status to check the transmission. Assigning a receipt ID does not restore missing local submission history.\\Do you want to continue?';
        UnexpectedStatusUserErr: Label 'IRIS returned an unrecognized status: "%1". Use the Request Status action to get the updated status. If the issue persists, open a Business Central support request.', Comment = '%1 - status text returned by IRIS';
        UnexpectedStatusErr: Label 'Unexpected status: %1', Comment = '%1 - status text returned by IRIS';
        UnableToParseResponseErr: Label 'Could not parse the response from IRIS.', Locked = true;
        UnableToParseResponseUserErr: Label 'Could not read the transmission status from the IRIS response. Try Request Status again. If a matching entry exists in Transmission History, use Download Acknowledgment Content to inspect the response.';
        CannotUpdateRejectedTransmissionErr: Label 'A rejected transmission cannot be updated. Review the IRS errors before sending a replacement or retrying a rejected correction.';
        RemovedParentErr: Label 'Document %1 has supplemental lines linked to form box %2. Recalculation would remove the document line for that form box. Remove the linked lines in Supplemental Lines before recalculating.', Comment = '%1 = document ID, %2 = form box';
        DocCannotBeRemovedFromTransmErr: Label 'Document %1 cannot be reopened and removed from the transmission because it has submission or correction information, or a recorded send attempt. Check its IRS status before taking further action. If an accepted form should not have been filed, use Send Zero Amounts Correction.', Comment = '%1 = document ID';
        AmbiguousSourceErr: Label 'More than one document with a status other than Abandoned exists for period %1, vendor %2, form %3. Select the source document before creating replacement lines.', Comment = '%1 = period, %2 = vendor, %3 = form';
        AbandonedSourceErr: Label 'Document %1 has status Abandoned and cannot be used to create replacement lines.', Comment = '%1 = document ID';
        AcknowledgmentAttemptNotFoundErr: Label 'The transmission attempt %1 could not be found. Open Transmission History and check the unique transmission ID before requesting its status again.', Comment = '%1 = unique transmission ID';
        AcknowledgmentIdentityMismatchErr: Label 'The acknowledgment does not match the requested transmission attempt. Check its unique transmission ID and receipt ID in Transmission History.';
        HistoricalAcknowledgmentMsg: Label 'The acknowledgment was saved in Transmission History for an earlier attempt. The current transmission and documents were not changed. Use Request Status by UTID to check the latest attempt.';
        ManualReceiptStatusMsg: Label 'The transmission status was updated using the manually assigned receipt. No matching local submission history was found, so document statuses and correction references were not updated. This transmission cannot be replaced or corrected in Business Central. Do not resend these documents as original returns.';
        NoReplaceableSubmissionsErr: Label 'No rejected original or replacement submission with matching local history is available to replace. Rejected corrections must be sent again as corrections. Check Transmission History before sending.';
        ManualReceiptPreValidationMsg: Label 'IRIS reported a pre-receipt validation failure for the manually assigned receipt. The transmission and documents were not updated. Check the receipt with the IRIS help desk before sending again.';
        ManualReceiptHistoryMissingErr: Label 'The manually assigned receipt has no matching local submission history. This transmission cannot be replaced or corrected in Business Central. Do not submit these documents again as original returns.';
        DependentEligibilityChangesQst: Label 'The selected updates also change Include in 1099 on these unselected lines:%1\\Their amounts and minimum reportable amounts will not change. Do you want to apply these dependent changes?', Comment = '%1 = list of affected document lines';
        DependentEligibilityChangeTxt: Label '\Document %1, form box %2: %3 -> %4', Comment = '%1 = document ID, %2 = form box, %3 = current Include in 1099, %4 = new Include in 1099';
        SandboxRemovalOnlyErr: Label 'Transmissions can only be removed with this action in a sandbox in the current company.';
        SandboxRemovalConflictErr: Label 'Document %1 belongs to another transmission or reporting year. The transmission was not removed.', Comment = '%1 = document ID';
        SandboxRemovalChangedErr: Label 'The transmission or its associated documents or history changed. Open the transmission again and retry the removal.';
        TransmissionChangedErr: Label 'The transmission changed or no longer exists. Open the transmission again and retry the action.';
        ResetSandboxTransmissionQst: Label 'Remove transmission %1 for tax year %2 and reset %3 documents, keeping their contents? This removes %4 local history attempts and all errors for this transmission. Non-abandoned documents become Open; abandoned documents remain Abandoned. This is local sandbox cleanup only and does not cancel IRS/ATS submissions. Continue?', Comment = '%1 = transmission ID, %2 = tax year, %3 = document count, %4 = history attempt count';
        DeleteSandboxTransmissionQst: Label 'Remove transmission %1 for tax year %2 and delete %3 documents and their contents? This removes %4 local history attempts and all errors for this transmission. This is local sandbox cleanup only and does not cancel IRS/ATS submissions. Continue?', Comment = '%1 = transmission ID, %2 = tax year, %3 = document count, %4 = history attempt count';

    #region Transmission Validation
    procedure CheckOriginal(var Transmission: Record "Transmission IRIS")
    begin
        CheckManualReceiptHistory(Transmission);
        case Transmission.Status of
            Enum::"Transmission Status IRIS"::Rejected:
                Error(TransmissionRejectedErr);
            Enum::"Transmission Status IRIS"::Processing:
                Error(TransmissionIsProcessingErr);
            Enum::"Transmission Status IRIS"::"Partially Accepted":
                Error(TransmissionPartiallyAcceptedErr);
            Enum::"Transmission Status IRIS"::"Accepted with Errors":
                Error(TransmissionAcceptedWithErrorsErr);
            Enum::"Transmission Status IRIS"::"Not Found":
                if not ConfirmMgt.GetResponseOrDefault(SendOriginalWhenNotFoundQst, false) then
                    Error('');
        end;

        CheckTransmHasOpenedOrAbandonedDocs(Transmission);
    end;

    procedure CheckReplacement(var Transmission: Record "Transmission IRIS")
    var
        TransmHasRejectedSubmissions: Boolean;
    begin
        CheckManualReceiptHistory(Transmission);
        // if some submissions were rejected and then other submissions were corrected and accepted, it should be possible to replace the transmission
        TransmHasRejectedSubmissions := TransmissionHasRejectedSubmissions(Transmission);

        case Transmission.Status of
            Enum::"Transmission Status IRIS"::None:
                Error(TransmissionNotSentErr);
            Enum::"Transmission Status IRIS"::Accepted:
                if not TransmHasRejectedSubmissions then
                    Error(TransmissionAcceptedErr);
            Enum::"Transmission Status IRIS"::Processing:
                Error(TransmissionIsProcessingErr);
            Enum::"Transmission Status IRIS"::"Accepted with Errors":
                if not TransmHasRejectedSubmissions then
                    Error(TransmissionAcceptedWithErrorsErr);
            Enum::"Transmission Status IRIS"::"Not Found":
                // if Receipt ID is empty, user must request it from IRIS help desk and request transmission status
                // if Receipt ID was not found by help desk, count it as a new transmission
                Error(TransmissionNotSentErr);
        end;

        if not IsSendReplacementAllowed(Transmission) then
            Error(NoReplaceableSubmissionsErr);
        CheckTransmHasOpenedOrAbandonedDocs(Transmission);
    end;

    procedure CheckCorrection(var Transmission: Record "Transmission IRIS")
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
    begin
        CheckManualReceiptHistory(Transmission);
        case Transmission.Status of
            Enum::"Transmission Status IRIS"::None:
                Error(TransmissionNotSentErr);
            Enum::"Transmission Status IRIS"::Processing:
                Error(TransmissionIsProcessingErr);
            Enum::"Transmission Status IRIS"::"Not Found":
                // if Receipt ID is empty, user must request it from IRIS help desk and request transmission status
                // if Receipt ID was not found by help desk, count it as a new transmission
                Error(TransmissionNotSentErr);
        end;

        CheckTransmHasOpenedOrAbandonedDocs(Transmission);       // check all linked form documents, however only marked Needs Correction will be sent

        IRS1099FormDocHeader.SetRange("IRIS Transmission Document ID", Transmission."Document ID");
        IRS1099FormDocHeader.SetFilter(Status, GetFormDocToSendStatusFilter());
        IRS1099FormDocHeader.SetRange("IRIS Needs Correction", true);
        if not IRS1099FormDocHeader.FindSet() then
            Error(NoLinesMarkedForCorrectionErr);
        repeat
            CheckDocumentCanBeCorrected(IRS1099FormDocHeader);
        until IRS1099FormDocHeader.Next() = 0;
    end;

    local procedure CheckDocumentCanBeCorrected(DocHeader: Record "IRS 1099 Form Doc. Header")
    var
        TransmissionLogLine: Record "Transmission Log Line IRIS";
    begin
        if DocHeader."IRIS Submission Status" = DocHeader."IRIS Submission Status"::None then begin
            TransmissionLogLine.SetRange("IRS 1099 Form Document ID", DocHeader.ID);
            if TransmissionLogLine.IsEmpty() then
                Error(NewDocCorrectionErr, DocHeader.ID, DocHeader."Vendor No.", DocHeader."Form No.", DocHeader."Period No.");
        end;

        if (DocHeader."IRIS Submission Status" = DocHeader."IRIS Submission Status"::None) or
           (DocHeader."IRIS Submission ID" = '') or (DocHeader."IRIS Record ID" = '')
        then begin
            FeatureTelemetry.LogError('', Helper.GetIRISFeatureName(), CorrectionHistoryTok, MissingCorrectionHistoryErr);
            Error(MissingCorrectionDetailsErr, DocHeader.ID, DocHeader."Vendor No.", DocHeader."Form No.", DocHeader."Period No.");
        end;
    end;

    procedure IsSendOriginalAllowed(var Transmission: Record "Transmission IRIS"): Boolean
    begin
        if HasUnrecordedManualReceipt(Transmission) then
            exit(false);
        exit((Transmission.Status = Enum::"Transmission Status IRIS"::None) or
            ((Transmission.Status = Enum::"Transmission Status IRIS"::Rejected) and (Transmission."Receipt ID" = '')));
    end;

    procedure IsSendReplacementAllowed(var Transmission: Record "Transmission IRIS"): Boolean
    var
        PrevSendIsCorrection: Boolean;
        TransmHasRejectedSubmissions: Boolean;
    begin
        if HasUnrecordedManualReceipt(Transmission) then
            exit(false);
        TransmHasRejectedSubmissions := TransmissionHasRejectedSubmissions(Transmission);
        PrevSendIsCorrection := (Transmission."Last Type" = Enum::"Transmission Type IRIS"::"C");

        exit(TransmHasRejectedSubmissions and
            (Transmission.Status in [Transmission.Status::Rejected, Transmission.Status::"Partially Accepted",
                Transmission.Status::Accepted, Transmission.Status::"Accepted with Errors"]) and
            not ((Transmission.Status = Transmission.Status::Rejected) and PrevSendIsCorrection));
    end;

    procedure IsSendCorrectionAllowed(var Transmission: Record "Transmission IRIS"): Boolean
    var
        PrevSendIsCorrection: Boolean;
    begin
        if HasUnrecordedManualReceipt(Transmission) then
            exit(false);
        PrevSendIsCorrection := (Transmission."Last Type" = Enum::"Transmission Type IRIS"::"C");

        exit((Transmission.Status = Enum::"Transmission Status IRIS"::Accepted) or
            (Transmission.Status = Enum::"Transmission Status IRIS"::"Accepted with Errors") or
            (Transmission.Status = Enum::"Transmission Status IRIS"::"Partially Accepted") or
            ((Transmission.Status = Enum::"Transmission Status IRIS"::Rejected) and PrevSendIsCorrection));
    end;

    local procedure CheckManualReceiptHistory(Transmission: Record "Transmission IRIS")
    begin
        if HasUnrecordedManualReceipt(Transmission) then
            Error(ManualReceiptHistoryMissingErr);
    end;

    local procedure HasUnrecordedManualReceipt(Transmission: Record "Transmission IRIS"): Boolean
    var
        TransmissionLog: Record "Transmission Log IRIS";
    begin
        if not Transmission."Receipt ID Assigned Manually" then
            exit(false);
        TransmissionLog.SetRange("Transmission Document ID", Transmission."Document ID");
        TransmissionLog.SetRange("Receipt ID", Transmission."Receipt ID");
        exit(TransmissionLog.IsEmpty());
    end;

    local procedure CheckTransmHasOpenedOrAbandonedDocs(var Transmission: Record "Transmission IRIS")
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
    begin
        // opened and abandoned form documents will not be sent
        IRS1099FormDocHeader.SetRange("IRIS Transmission Document ID", Transmission."Document ID");
        IRS1099FormDocHeader.SetFilter(Status, '%1|%2', Enum::"IRS 1099 Form Doc. Status"::Open, Enum::"IRS 1099 Form Doc. Status"::Abandoned);
        if not IRS1099FormDocHeader.IsEmpty() then
            if not ConfirmMgt.GetResponseOrDefault(TransmHasOpenedOrAbandonedDocsQst, false) then
                Error('');
    end;

    local procedure TransmissionHasRejectedSubmissions(Transmission: Record "Transmission IRIS"): Boolean
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
    begin
        IRS1099FormDocHeader.SetRange("IRIS Transmission Document ID", Transmission."Document ID");
        IRS1099FormDocHeader.SetFilter(Status, GetFormDocToSendStatusFilter());
        if IRS1099FormDocHeader.FindSet() then
            repeat
                if IsDocumentEligibleForReplacement(Transmission, IRS1099FormDocHeader) then
                    exit(true);
            until IRS1099FormDocHeader.Next() = 0;
        exit(false);
    end;

    internal procedure IsDocumentEligibleForReplacement(Transmission: Record "Transmission IRIS"; DocHeader: Record "IRS 1099 Form Doc. Header"): Boolean
    var
        TransmissionLog: Record "Transmission Log IRIS";
        TransmissionLogLine: Record "Transmission Log Line IRIS";
        ReceiptID: Text[100];
    begin
        if DocHeader."IRIS Transmission Document ID" <> Transmission."Document ID" then
            exit(false);
        ReceiptID := DocHeader."IRIS Last Receipt ID";
        if Transmission.Status = Transmission.Status::Rejected then
            ReceiptID := Transmission."Receipt ID"
        else
            if DocHeader."IRIS Submission Status" <> DocHeader."IRIS Submission Status"::Rejected then
                exit(false);
        if ReceiptID = '' then
            exit(false);
        TransmissionLog.SetRange("Transmission Document ID", Transmission."Document ID");
        TransmissionLog.SetRange("Receipt ID", ReceiptID);
        if not TransmissionLog.FindLast() then
            exit(false);
        if not (TransmissionLog."Transmission Type" in [TransmissionLog."Transmission Type"::O, TransmissionLog."Transmission Type"::R]) then
            exit(false);
        TransmissionLogLine.SetRange("Transmission Log ID", TransmissionLog."Line ID");
        TransmissionLogLine.SetRange("IRS 1099 Form Document ID", DocHeader.ID);
        TransmissionLogLine.SetRange("Submission ID", DocHeader."IRIS Submission ID");
        TransmissionLogLine.SetRange("Record ID", DocHeader."IRIS Record ID");
        exit(not TransmissionLogLine.IsEmpty());
    end;

    procedure GetFormDocToSendStatusFilter() StatusFilter: Text
    var
        FormDocStatus: Enum "IRS 1099 Form Doc. Status";
        FormDocStatusInt: Integer;
        TB: TextBuilder;
    begin
        foreach FormDocStatusInt in Enum::"IRS 1099 Form Doc. Status".Ordinals() do begin
            FormDocStatus := Enum::"IRS 1099 Form Doc. Status".FromInteger(FormDocStatusInt);
            if not (FormDocStatus in [Enum::"IRS 1099 Form Doc. Status"::Open, Enum::"IRS 1099 Form Doc. Status"::Abandoned]) then
                TB.Append(StrSubstNo('%1|', Format(FormDocStatus)));
        end;

        StatusFilter := '';
        if TB.Length() <> 0 then
            StatusFilter := TB.ToText(1, TB.Length() - 1);
    end;

    #endregion

    #region Sending
    procedure SendOriginal(var Transmission: Record "Transmission IRIS")
    var
        IRSFormsFacade: Codeunit "IRS Forms Facade";
        TransmissionType: Enum "Transmission Type IRIS";
        CorrectionToZeroMode: Boolean;
    begin
        // This function can only be used to send original transmission.

        // Transmission can be sent as Original when current Status is:
        // - None (sent for the first time)
        // - Accepted (can only be send as Original in the 2-step correction process)
        // - Not Found (in case Receipt ID was not returned and IRS help desk confirms that the transmission was not received)

        if not EnvironmentInformation.IsSaaS() then
            Error(TransmCanOnlyBeSentInSaaSErr);

        IRSFormsFacade.CheckOriginalTransmission(Transmission);
        IRSFormsFacade.CheckDataToReport(Transmission);

        TransmissionType := Enum::"Transmission Type IRIS"::"O";
        CorrectionToZeroMode := false;
        FeatureTelemetry.LogUsage('', Helper.GetIRISFeatureName(), StrSubstNo(SubmissionStartedLbl, 'Original'));
        SubmitTransmissionAndProcessResponse(Transmission, TransmissionType, CorrectionToZeroMode);
    end;

    procedure SendReplacement(var Transmission: Record "Transmission IRIS")
    var
        IRSFormsFacade: Codeunit "IRS Forms Facade";
        TransmissionType: Enum "Transmission Type IRIS";
        CorrectionToZeroMode: Boolean;
    begin
        // This function can only be used to send replacement transmission.

        // Transmission can be sent as Replacement when current Status is:
        // - Rejected (rejected transmission can only be replaced)
        // - Partially Accepted (can be replaced or corrected)

        if not EnvironmentInformation.IsSaaS() then
            Error(TransmCanOnlyBeSentInSaaSErr);

        IRSFormsFacade.CheckReplacementTransmission(Transmission);
        IRSFormsFacade.CheckDataToReport(Transmission);

        TransmissionType := Enum::"Transmission Type IRIS"::"R";
        CorrectionToZeroMode := false;
        FeatureTelemetry.LogUsage('', Helper.GetIRISFeatureName(), StrSubstNo(SubmissionStartedLbl, 'Replacement'));
        SubmitTransmissionAndProcessResponse(Transmission, TransmissionType, CorrectionToZeroMode);
    end;

    procedure SendCorrection(var Transmission: Record "Transmission IRIS"; CorrectionToZeroMode: Boolean)
    var
        TempAddedCorrectionDocHeader: Record "IRS 1099 Form Doc. Header" temporary;
        RestoreSelectionOnFailure: Boolean;
    begin
        SendCorrectionAndProcessResponse(Transmission, CorrectionToZeroMode, TempAddedCorrectionDocHeader, RestoreSelectionOnFailure);
    end;

    local procedure SendCorrectionAndProcessResponse(var Transmission: Record "Transmission IRIS"; CorrectionToZeroMode: Boolean; var TempAddedCorrectionDocHeader: Record "IRS 1099 Form Doc. Header" temporary; var RestoreSelectionOnFailure: Boolean): Boolean
    var
        IRSFormsFacade: Codeunit "IRS Forms Facade";
        TransmissionType: Enum "Transmission Type IRIS";
    begin
        // This function can only be used to send correction transmissions.

        // Transmission can be sent as Correction when current Status is:
        // - Accepted (can only be corrected)
        // - Accepted with Errors (can only be corrected)
        // - Partially Accepted (can be replaced or corrected)
        // - Rejected (if previously sent correction was rejected, it must be corrected until accepted)

        if not EnvironmentInformation.IsSaaS() then
            Error(TransmCanOnlyBeSentInSaaSErr);

        IRSFormsFacade.CheckCorrectionTransmission(Transmission);
        IRSFormsFacade.CheckDataToReport(Transmission);

        TransmissionType := Enum::"Transmission Type IRIS"::"C";
        if CorrectionToZeroMode then
            FeatureTelemetry.LogUsage('', Helper.GetIRISFeatureName(), StrSubstNo(SubmissionStartedLbl, 'Zero correction'))
        else
            FeatureTelemetry.LogUsage('', Helper.GetIRISFeatureName(), StrSubstNo(SubmissionStartedLbl, 'Correction'));
        exit(SubmitTransmissionAndProcessResponse(Transmission, TransmissionType, CorrectionToZeroMode, TempAddedCorrectionDocHeader, RestoreSelectionOnFailure));
    end;

    procedure SendTwoStepZeroCorrection(var Transmission: Record "Transmission IRIS")
    begin
        SendTwoStepZeroCorrectionAndProcessResponse(Transmission);
    end;

    internal procedure SendTwoStepZeroCorrectionAndProcessResponse(var Transmission: Record "Transmission IRIS"): Boolean
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        TempAddedCorrectionDocHeader: Record "IRS 1099 Form Doc. Header" temporary;
        RestoreSelectionOnFailure: Boolean;
    begin
        DocHeader.SetRange("IRIS Transmission Document ID", Transmission."Document ID");
        DocHeader.SetFilter(Status, GetFormDocToSendStatusFilter());
        DocHeader.SetRange("IRIS Needs Correction", false);
        if DocHeader.FindSet() then
            repeat
                TempAddedCorrectionDocHeader := DocHeader;
                TempAddedCorrectionDocHeader.Insert();
            until DocHeader.Next() = 0;
        DocHeader.SetRange("IRIS Needs Correction");
        DocHeader.ModifyAll("IRIS Needs Correction", true);
        FeatureTelemetry.LogUsage('', Helper.GetIRISFeatureName(), StrSubstNo(SubmissionStartedLbl, 'Two-step zero correction'));
        if not SendCorrectionAndProcessResponse(Transmission, true, TempAddedCorrectionDocHeader, RestoreSelectionOnFailure) then begin
            if RestoreSelectionOnFailure then
                if TempAddedCorrectionDocHeader.FindSet() then
                    repeat
                        DocHeader.Get(TempAddedCorrectionDocHeader.ID);
                        DocHeader."IRIS Needs Correction" := false;
                        DocHeader.Modify();
                    until TempAddedCorrectionDocHeader.Next() = 0;
            exit(false);
        end;
        exit(true);
    end;

    local procedure SubmitTransmissionAndProcessResponse(var Transmission: Record "Transmission IRIS"; TransmissionType: Enum "Transmission Type IRIS"; CorrectionToZeroMode: Boolean)
    var
        TempAddedCorrectionDocHeader: Record "IRS 1099 Form Doc. Header" temporary;
        RestoreSelectionOnFailure: Boolean;
    begin
        SubmitTransmissionAndProcessResponse(Transmission, TransmissionType, CorrectionToZeroMode, TempAddedCorrectionDocHeader, RestoreSelectionOnFailure);
    end;

    local procedure SubmitTransmissionAndProcessResponse(var Transmission: Record "Transmission IRIS"; TransmissionType: Enum "Transmission Type IRIS"; CorrectionToZeroMode: Boolean; var TempAddedCorrectionDocHeader: Record "IRS 1099 Form Doc. Header" temporary; var RestoreSelectionOnFailure: Boolean): Boolean
    var
        TempIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header" temporary;
        TransmissionLog: Record "Transmission Log IRIS";
        IRSFormsFacade: Codeunit "IRS Forms Facade";
        TransmissionContentBlob: Codeunit "Temp Blob";
        ResponseContentBlob: Codeunit "Temp Blob";
        UniqueTransmissionId: Text[100];
        ReceiptID: Text[100];
        HttpStatusCode: Integer;
        CustomDimensions: Dictionary of [Text, Text];
        PreReceiptValidationFailed: Boolean;
    begin
        RestoreSelectionOnFailure := false;
        IRSFormsFacade.CreateTransmissionXmlContent(Transmission, TransmissionType, CorrectionToZeroMode, UniqueTransmissionId, TempIRS1099FormDocHeader, TransmissionContentBlob);
        OAuthClient.SubmitTransmission(TransmissionContentBlob, ResponseContentBlob, HttpStatusCode);
        CreateTransmissionLog(
            TransmissionLog, Transmission, TransmissionType, CorrectionToZeroMode, UniqueTransmissionId,
            HttpStatusCode, TempIRS1099FormDocHeader, TransmissionContentBlob, ResponseContentBlob, TempAddedCorrectionDocHeader);
        if HttpStatusCode <> 200 then begin
            RestoreSelectionOnFailure := (HttpStatusCode in [400 .. 499]) and (HttpStatusCode <> 408);
            if RestoreSelectionOnFailure then
                FeatureTelemetry.LogError('', Helper.GetIRISFeatureName(), SubmissionEventTok, SubmissionFailedErr)
            else begin
                FeatureTelemetry.LogError('', Helper.GetIRISFeatureName(), SubmissionEventTok, SubmissionUnconfirmedErr);
                SetSubmissionInProgress(Transmission, TransmissionType, TempIRS1099FormDocHeader, '');
                Commit();
                Message(SubmissionUnconfirmedMsg);
            end;
            exit(false);   // the error is shown inside SubmitTransmission
        end;

        if ProcessResponse.GetReceiptID(ResponseContentBlob, ReceiptID) then begin
            UpdateTransmissionLog(TransmissionLog, ReceiptID);
            UpdateReceiptID(Transmission, TransmissionType, TempIRS1099FormDocHeader, ReceiptID);
            CustomDimensions.Add('TransmissionType', Helper.GetTransmissionTypeName(TransmissionType));
            CustomDimensions.Add('CorrectionToZeroMode', Format(CorrectionToZeroMode, 0, 9));
            FeatureTelemetry.LogUsage('', Helper.GetIRISFeatureName(), SubmissionReceiptConfirmedLbl, CustomDimensions);
        end else
            FeatureTelemetry.LogError('', Helper.GetIRISFeatureName(), SubmissionEventTok, SubmissionReceiptMissingErr);
        SetSubmissionInProgress(Transmission, TransmissionType, TempIRS1099FormDocHeader, ReceiptID);

        Commit();       // save transmission log record before requesting the status
        Sleep(3000);    // wait for IRIS to process the transmission

        RequestAcknowledgementAndUpdateTransmission(Transmission, ReceiptID, UniqueTransmissionId, PreReceiptValidationFailed);
        exit(not PreReceiptValidationFailed);
    end;

    #endregion

    #region Status Requests
    procedure RequestStatus(ReceiptID: Text[100]; UniqueTransmissionId: Text[100]; var TransmissionStatus: Text)
    var
        TransmissionLog: Record "Transmission Log IRIS";
        IRSFormsFacade: Codeunit "IRS Forms Facade";
        GetStatusRequestContentBlob: Codeunit "Temp Blob";
        AcknowledgContentBlob: Codeunit "Temp Blob";
        UTIDFromResponse: Text[100];
        HttpStatusCode: Integer;
        DummySubmissionsStatus: Dictionary of [Text, Text];
    begin
        if ReceiptID <> '' then
            IRSFormsFacade.CreateGetStatusRequestXmlContent(Enum::"Search Param Type IRIS"::RID, ReceiptID, GetStatusRequestContentBlob)
        else
            IRSFormsFacade.CreateGetStatusRequestXmlContent(Enum::"Search Param Type IRIS"::UTID, UniqueTransmissionId, GetStatusRequestContentBlob);

        OAuthClient.RequestTransmStatusOrAcknowledgement(GetStatusRequestContentBlob, AcknowledgContentBlob, HttpStatusCode);

        if not TransmissionLog.FindRecordByUTID(UniqueTransmissionId) then
            if TransmissionLog.FindLastRecByReceiptID(ReceiptID) then;

        if not IsNullGuid(TransmissionLog.SystemId) then
            UpdateTransmissionLog(TransmissionLog, AcknowledgContentBlob);

        if HttpStatusCode <> 200 then
            exit;   // the error is shown inside RequestTransmStatusOrAcknowledgement

        if not ProcessResponse.ParseGetStatusXmlResponse(AcknowledgContentBlob, UTIDFromResponse, TransmissionStatus) then begin
            FeatureTelemetry.LogError('0000PSK', Helper.GetIRISFeatureName(), RequestStatusEventTxt, UnableToParseResponseErr, GetLastErrorCallStack());
            Message(UnableToParseResponseUserErr);
            exit;
        end;

        if not IsNullGuid(TransmissionLog.SystemId) then
            UpdateTransmissionLog(TransmissionLog, TransmissionStatus, DummySubmissionsStatus);
        FeatureTelemetry.LogUsage('', Helper.GetIRISFeatureName(), RequestStatusEventTxt);
    end;

    procedure RequestAcknowledgement(ReceiptID: Text[100]; UniqueTransmissionId: Text[100]; var TransmissionStatus: Text; var SubmissionsStatus: Dictionary of [Text, Text]; var TempErrorInfo: Record "Error Information IRIS" temporary)
    var
        TransmissionLog: Record "Transmission Log IRIS";
    begin
        if GetAcknowledgment(ReceiptID, UniqueTransmissionId, TransmissionLog, TransmissionStatus, SubmissionsStatus, TempErrorInfo) then;
    end;

    procedure RequestAcknowledgementAndUpdateTransmission(var Transmission: Record "Transmission IRIS"; ReceiptID: Text[100]; UniqueTransmissionId: Text[100])
    var
        PreReceiptValidationFailed: Boolean;
    begin
        RequestAcknowledgementAndUpdateTransmission(Transmission, ReceiptID, UniqueTransmissionId, PreReceiptValidationFailed);
    end;

    local procedure RequestAcknowledgementAndUpdateTransmission(var Transmission: Record "Transmission IRIS"; ReceiptID: Text[100]; UniqueTransmissionId: Text[100]; var PreReceiptValidationFailed: Boolean)
    var
        TransmissionLog: Record "Transmission Log IRIS";
        LatestTransmissionLog: Record "Transmission Log IRIS";
        TransmissionLogLine: Record "Transmission Log Line IRIS";
        DocHeader: Record "IRS 1099 Form Doc. Header";
        TempDocHeader: Record "IRS 1099 Form Doc. Header" temporary;
        TempErrorInfo: Record "Error Information IRIS" temporary;
        TransmissionStatus: Text;
        SubmissionsStatus: Dictionary of [Text, Text];
    begin
        if not GetAcknowledgment(ReceiptID, UniqueTransmissionId, TransmissionLog, TransmissionStatus, SubmissionsStatus, TempErrorInfo) then
            exit;
        if TransmissionLog."Line ID" = 0 then begin
            if (UniqueTransmissionId = '') and Transmission."Receipt ID Assigned Manually" and
               (ReceiptID = Transmission."Receipt ID")
            then begin
                Transmission.LockTable();
                Transmission.Get(Transmission."Document ID");
                if not Transmission."Receipt ID Assigned Manually" or (ReceiptID <> Transmission."Receipt ID") then
                    Error(TransmissionChangedErr);
                if ProcessResponse.PreReceiptValidationFailed(TempErrorInfo) then begin
                    PreReceiptValidationFailed := true;
                    Message(ManualReceiptPreValidationMsg);
                    exit;
                end;
                UpdateTransmissionStatusOnly(Transmission, TransmissionStatus);
                Message(ManualReceiptStatusMsg);
                exit;
            end;
            FeatureTelemetry.LogError('', Helper.GetIRISFeatureName(), AcknowledgmentIdentityTok, MissingAcknowledgmentAttemptErr);
            Error(AcknowledgmentAttemptNotFoundErr, UniqueTransmissionId);
        end;
        if TransmissionLog."Transmission Document ID" <> Transmission."Document ID" then begin
            FeatureTelemetry.LogError('', Helper.GetIRISFeatureName(), AcknowledgmentIdentityTok, AcknowledgmentIdentityTelemetryErr);
            Error(AcknowledgmentIdentityMismatchErr);
        end;

        Transmission.LockTable();
        Transmission.Get(Transmission."Document ID");
        LatestTransmissionLog.SetCurrentKey("Transmission Document ID", "Line ID");
        LatestTransmissionLog.SetRange("Transmission Document ID", Transmission."Document ID");
        LatestTransmissionLog.FindLast();
        // An older acknowledgment belongs in history, not in the current document state.
        if (LatestTransmissionLog."Line ID" <> TransmissionLog."Line ID") or
           (Transmission."Receipt ID Assigned Manually" and (Transmission."Receipt ID" <> TransmissionLog."Receipt ID"))
        then begin
            Message(HistoricalAcknowledgmentMsg);
            exit;
        end;

        SetTransmissionErrors(Transmission."Document ID", TransmissionLog."Unique Transmission ID", SubmissionsStatus, TempErrorInfo);
        if ProcessResponse.PreReceiptValidationFailed(TempErrorInfo) then begin
            PreReceiptValidationFailed := true;
            RestorePreviousSendState(Transmission, TransmissionLog);
            exit;
        end;

        TransmissionLogLine.SetRange("Transmission Log ID", TransmissionLog."Line ID");
        if TransmissionLogLine.FindSet() then
            repeat
                if DocHeader.Get(TransmissionLogLine."IRS 1099 Form Document ID") then
                    if DocHeader."IRIS Transmission Document ID" = Transmission."Document ID" then begin
                        TempDocHeader := DocHeader;
                        TempDocHeader.Insert();
                    end;
            until TransmissionLogLine.Next() = 0;
        UpdateReceiptID(Transmission, TransmissionLog."Transmission Type", TempDocHeader, ReceiptID);
        UpadateTransmissionStatus(Transmission, TransmissionStatus, SubmissionsStatus, TransmissionLog);
    end;

    local procedure GetAcknowledgment(var ReceiptID: Text[100]; UniqueTransmissionId: Text[100]; var TransmissionLog: Record "Transmission Log IRIS"; var TransmissionStatus: Text; var SubmissionsStatus: Dictionary of [Text, Text]; var TempErrorInfo: Record "Error Information IRIS" temporary): Boolean
    var
        IRSFormsFacade: Codeunit "IRS Forms Facade";
        GetStatusRequestContentBlob: Codeunit "Temp Blob";
        AcknowledgContentBlob: Codeunit "Temp Blob";
        UTIDFromResponse: Text[100];
        ReceiptIDFromResponse: Text[100];
        HttpStatusCode: Integer;
    begin
        if ReceiptID <> '' then
            IRSFormsFacade.CreateAcknowledgmentRequestXmlContent(Enum::"Search Param Type IRIS"::RID, ReceiptID, GetStatusRequestContentBlob)
        else
            IRSFormsFacade.CreateAcknowledgmentRequestXmlContent(Enum::"Search Param Type IRIS"::UTID, UniqueTransmissionId, GetStatusRequestContentBlob);

        OAuthClient.RequestTransmStatusOrAcknowledgement(GetStatusRequestContentBlob, AcknowledgContentBlob, HttpStatusCode);

        Clear(TransmissionLog);
        if UniqueTransmissionId <> '' then begin
            if TransmissionLog.FindRecordByUTID(UniqueTransmissionId) then;
        end else
            if TransmissionLog.FindLastRecByReceiptID(ReceiptID) then;

        if not IsNullGuid(TransmissionLog.SystemId) then
            UpdateTransmissionLog(TransmissionLog, AcknowledgContentBlob);

        if HttpStatusCode <> 200 then
            exit(false);   // the error is shown inside RequestTransmStatusOrAcknowledgement

        if not ProcessResponse.ParseAcknowledgementXmlResponse(AcknowledgContentBlob, UTIDFromResponse, TransmissionStatus, SubmissionsStatus, TempErrorInfo) then begin
            FeatureTelemetry.LogError('0000PSK', Helper.GetIRISFeatureName(), RequestAcknowledgEventTxt, UnableToParseResponseErr, GetLastErrorCallStack());
            Message(UnableToParseResponseUserErr);
            exit(false);
        end;

        if (UniqueTransmissionId <> '') and (UTIDFromResponse <> '') and (UTIDFromResponse <> UniqueTransmissionId) then begin
            FeatureTelemetry.LogError('', Helper.GetIRISFeatureName(), AcknowledgmentIdentityTok, AcknowledgmentIdentityTelemetryErr);
            Error(AcknowledgmentIdentityMismatchErr);
        end;
        ReceiptIDFromResponse := ProcessResponse.GetReceiptIDFromAcknowledgXmlResponse(AcknowledgContentBlob);
        if (ReceiptID <> '') and (ReceiptIDFromResponse <> '') and (ReceiptID <> ReceiptIDFromResponse) then
            Error(AcknowledgmentIdentityMismatchErr);
        if ReceiptID = '' then
            ReceiptID := ReceiptIDFromResponse;
        if not IsNullGuid(TransmissionLog.SystemId) then begin
            if (TransmissionLog."Receipt ID" <> '') and (ReceiptID <> '') and (TransmissionLog."Receipt ID" <> ReceiptID) then begin
                FeatureTelemetry.LogError('', Helper.GetIRISFeatureName(), AcknowledgmentIdentityTok, AcknowledgmentIdentityTelemetryErr);
                Error(AcknowledgmentIdentityMismatchErr);
            end;
            UpdateTransmissionLog(TransmissionLog, ReceiptID);
            UpdateTransmissionLog(TransmissionLog, TransmissionStatus, SubmissionsStatus);
        end;
        FeatureTelemetry.LogUsage('', Helper.GetIRISFeatureName(), RequestAcknowledgEventTxt);
        exit(true);
    end;

    #endregion

    #region Transmission History
    local procedure CreateTransmissionLog(var TransmissionLog: Record "Transmission Log IRIS"; var Transmission: Record "Transmission IRIS"; TransmissionType: Enum "Transmission Type IRIS"; CorrectionToZeroMode: Boolean; UniqueTransmissionId: Text[100]; HttpStatusCode: Integer; var TempIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header" temporary; var TransmissionContentBlob: Codeunit "Temp Blob"; var ResponseContentBlob: Codeunit "Temp Blob"; var TempAddedCorrectionDocHeader: Record "IRS 1099 Form Doc. Header" temporary)
    var
        BlobInStream: InStream;
        OutStream: OutStream;
    begin
        TransmissionLog.Init();
        TransmissionLog."Period No." := Transmission."Period No.";
        TransmissionLog."Transmission Document ID" := Transmission."Document ID";
        TransmissionLog."Transmission Type" := TransmissionType;
        TransmissionLog."Unique Transmission ID" := UniqueTransmissionId;
        TransmissionLog."Transmission Date/Time" := CurrentDateTime();
        TransmissionLog."Response Http Status Code" := HttpStatusCode;
        TransmissionLog."Previous State Recorded" := true;
        TransmissionLog."Previous Receipt ID" := Transmission."Receipt ID";
        TransmissionLog."Previous Original Receipt ID" := Transmission."Original Receipt ID";
        TransmissionLog."Previous Transmission Type" := Transmission."Last Type";
        TransmissionLog."Previous Transmission Status" := Transmission.Status;
        TransmissionLog."Previous Receipt Was Manual" := Transmission."Receipt ID Assigned Manually";
        TransmissionLog.SetTransmissionContextInfo(TransmissionContentBlob, Transmission.GetSchemaSource());
        if EnvironmentInformation.IsSandbox() then
            TransmissionLog."BC Environment" := 'Sandbox'
        else
            TransmissionLog."BC Environment" := 'Production';

        TransmissionContentBlob.CreateInStream(BlobInStream);
        TransmissionLog."Transmission Content".CreateOutStream(OutStream);
        CopyStream(OutStream, BlobInStream);

        ResponseContentBlob.CreateInStream(BlobInStream);
        TransmissionLog."Acceptance Response Content".CreateOutStream(OutStream);
        CopyStream(OutStream, BlobInStream);

        TransmissionLog."Transmission Size" := Helper.GetTransmissionFileSizeText(TransmissionLog);
        TransmissionLog.Insert();

        CreateTransmissionLogLines(TransmissionLog."Line ID", CorrectionToZeroMode, TempIRS1099FormDocHeader, TempAddedCorrectionDocHeader);
    end;

    local procedure CreateTransmissionLogLines(TransmissionLogLineID: Integer; CorrectionToZeroMode: Boolean; var TempIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header" temporary; var TempAddedCorrectionDocHeader: Record "IRS 1099 Form Doc. Header" temporary)
    var
        TransmissionLogLine: Record "Transmission Log Line IRIS";
        Vendor: Record Vendor;
        VendorName: Text[100];
        VendorTIN: Text[30];
    begin
        TempIRS1099FormDocHeader.Reset();
        if not TempIRS1099FormDocHeader.FindSet() then
            exit;

        repeat
            VendorName := '';
            VendorTIN := '';
            if Vendor.Get(TempIRS1099FormDocHeader."Vendor No.") then begin
                VendorName := Vendor.Name;
                VendorTIN := Vendor."Federal ID No.";
            end;

            TransmissionLogLine.InitRecord(TransmissionLogLineID);
            TransmissionLogLine."IRS 1099 Form Document ID" := TempIRS1099FormDocHeader.ID;
            TransmissionLogLine."Vendor No." := TempIRS1099FormDocHeader."Vendor No.";
            TransmissionLogLine."Vendor Name" := VendorName;
            TransmissionLogLine."Vendor Federal ID No." := VendorTIN;
            TransmissionLogLine."Form No." := TempIRS1099FormDocHeader."Form No.";
            TransmissionLogLine."Submission ID" := TempIRS1099FormDocHeader."IRIS Submission ID";
            TransmissionLogLine."Record ID" := TempIRS1099FormDocHeader."IRIS Record ID";
            TransmissionLogLine."Correction to Zeros" := CorrectionToZeroMode;
            TransmissionLogLine."Previous Document Status" := TempIRS1099FormDocHeader.Status;
            TransmissionLogLine."Previous Receipt ID" := TempIRS1099FormDocHeader."IRIS Last Receipt ID";
            TransmissionLogLine."Previous Updated Not Sent" := TempIRS1099FormDocHeader."IRIS Updated Not Sent";
            TransmissionLogLine."Previous Needs Correction" := TempIRS1099FormDocHeader."IRIS Needs Correction";
            if TempAddedCorrectionDocHeader.Get(TempIRS1099FormDocHeader.ID) then
                TransmissionLogLine."Previous Needs Correction" := false;
            TransmissionLogLine.Insert();
        until TempIRS1099FormDocHeader.Next() = 0;
    end;

    local procedure RestorePreviousSendState(var Transmission: Record "Transmission IRIS"; TransmissionLog: Record "Transmission Log IRIS")
    var
        TransmissionLogLine: Record "Transmission Log Line IRIS";
        DocHeader: Record "IRS 1099 Form Doc. Header";
    begin
        if not TransmissionLog."Previous State Recorded" then
            exit;
        Transmission."Receipt ID" := TransmissionLog."Previous Receipt ID";
        Transmission."Original Receipt ID" := TransmissionLog."Previous Original Receipt ID";
        Transmission."Last Type" := TransmissionLog."Previous Transmission Type";
        Transmission.Status := TransmissionLog."Previous Transmission Status";
        Transmission."Receipt ID Assigned Manually" := TransmissionLog."Previous Receipt Was Manual";
        Transmission.Modify(true);
        TransmissionLogLine.SetRange("Transmission Log ID", TransmissionLog."Line ID");
        if TransmissionLogLine.FindSet() then
            repeat
                if DocHeader.Get(TransmissionLogLine."IRS 1099 Form Document ID") then
                    if (DocHeader."IRIS Transmission Document ID" = Transmission."Document ID") and
                       (DocHeader."IRIS Submission ID" = TransmissionLogLine."Submission ID") and
                       (DocHeader."IRIS Record ID" = TransmissionLogLine."Record ID") and
                       (DocHeader.Status <> DocHeader.Status::Abandoned)
                    then begin
                        if DocHeader."IRIS Last Receipt ID" = TransmissionLog."Receipt ID" then
                            DocHeader."IRIS Last Receipt ID" := TransmissionLogLine."Previous Receipt ID";
                        if not DocHeader."IRIS Updated Not Sent" then begin
                            DocHeader.Status := TransmissionLogLine."Previous Document Status";
                            DocHeader."IRIS Updated Not Sent" := TransmissionLogLine."Previous Updated Not Sent";
                            DocHeader."IRIS Needs Correction" := TransmissionLogLine."Previous Needs Correction";
                        end;
                        DocHeader.Modify(true);
                    end;
            until TransmissionLogLine.Next() = 0;
    end;

    local procedure UpdateTransmissionLog(var TransmissionLog: Record "Transmission Log IRIS"; AcknowledgContentBlob: Codeunit "Temp Blob")
    var
        BlobInStream: InStream;
        OutStream: OutStream;
    begin
        AcknowledgContentBlob.CreateInStream(BlobInStream);
        TransmissionLog."Acknowledgement Content".CreateOutStream(OutStream);
        CopyStream(OutStream, BlobInStream);

        TransmissionLog."Acknowledgement Date/Time" := CurrentDateTime();
        TransmissionLog.Modify(true);
    end;

    local procedure UpdateTransmissionLog(var TransmissionLog: Record "Transmission Log IRIS"; StatusText: Text; var SubmissionsStatus: Dictionary of [Text, Text])
    var
        TransmissionLogLine: Record "Transmission Log Line IRIS";
        TransmissionStatus: Enum "Transmission Status IRIS";
        SubmissionStatusText: Text[250];
        StatusChanged: Boolean;
        CustomDimensions: Dictionary of [Text, Text];
    begin
        StatusChanged := TransmissionLog."Transmission Status Text" <> StatusText;
        if Evaluate(TransmissionStatus, StatusText) then
            TransmissionLog.Validate("Transmission Status", TransmissionStatus)
        else
            TransmissionStatus := TransmissionStatus::Unknown;

        TransmissionLog."Transmission Status Text" := CopyStr(StatusText, 1, MaxStrLen(TransmissionLog."Transmission Status Text"));
        TransmissionLog.Modify(true);
        if StatusChanged then begin
            CustomDimensions.Add('TransmissionStatus', Format(TransmissionStatus, 0, 9));
            FeatureTelemetry.LogUsage('', Helper.GetIRISFeatureName(), StatusTransitionLbl, CustomDimensions);
        end;

        TransmissionLogLine.SetRange("Transmission Log ID", TransmissionLog."Line ID");
        if TransmissionLogLine.FindSet() then
            repeat
                SubmissionStatusText := '';
                if SubmissionsStatus.ContainsKey(TransmissionLogLine."Submission ID") then begin
                    SubmissionStatusText := CopyStr(SubmissionsStatus.Get(TransmissionLogLine."Submission ID"), 1, MaxStrLen(TransmissionLogLine."Submission Status Text"));
                    TransmissionLogLine."Submission Status Text" := SubmissionStatusText;
                    TransmissionLogLine.Modify(true);
                end;
            until TransmissionLogLine.Next() = 0;
    end;

    local procedure UpdateTransmissionLog(var TransmissionLog: Record "Transmission Log IRIS"; ReceiptID: Text[100])
    begin
        if ReceiptID = '' then
            exit;

        TransmissionLog."Receipt ID" := ReceiptID;
        TransmissionLog.Modify(true);
    end;

    #endregion

    #region Error Information
    procedure SetTransmissionErrors(TransmissionDocumentID: Integer; UniqueTransmissionId: Text[100]; SubmissionsStatus: Dictionary of [Text, Text]; var TempErrorInfo: Record "Error Information IRIS" temporary)
    var
        ErrorInfo: Record "Error Information IRIS";
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        SubmissionId: Text[20];
        LineID: Integer;
        FormDocID: Integer;
        XmlSchemaErrorLogged: Boolean;
        ValidationErrorLogged: Boolean;
    begin
        // remove previous transmission related errors
        ErrorInfo.SetRange("Transmission Document ID", TransmissionDocumentID);
        ErrorInfo.SetRange("Entity Type", Enum::"Entity Type IRIS"::Transmission);
        ErrorInfo.DeleteAll(true);

        // remove previous submission related errors
        foreach SubmissionId in SubmissionsStatus.Keys() do begin
            ErrorInfo.SetRange("Entity Type", Enum::"Entity Type IRIS"::Submission);
            ErrorInfo.SetRange("Submission ID", SubmissionId);
            ErrorInfo.SetRange("Record ID", '');
            ErrorInfo.DeleteAll(true);
        end;

        TempErrorInfo.Reset();
        if not TempErrorInfo.FindSet() then
            exit;

        // remove previous record related errors
        repeat
            if TempErrorInfo."Entity Type" = Enum::"Entity Type IRIS"::RecordType then begin
                ErrorInfo.SetRange("Entity Type", TempErrorInfo."Entity Type");
                ErrorInfo.SetRange("Submission ID", TempErrorInfo."Submission ID");
                ErrorInfo.SetRange("Record ID", TempErrorInfo."Record ID");
                ErrorInfo.DeleteAll(true);
            end;
        until TempErrorInfo.Next() = 0;
        ErrorInfo.Reset();

        // add new errors
        TempErrorInfo.Reset();
        TempErrorInfo.SetFilter("Error Code", '<>%1', '');
        if TempErrorInfo.FindSet() then
            repeat
                // find related IRS 1099 Form Document
                FormDocID := 0;
                IRS1099FormDocHeader.SetRange("IRIS Transmission Document ID", TransmissionDocumentID);
                IRS1099FormDocHeader.SetRange("IRIS Submission ID", TempErrorInfo."Submission ID");
                IRS1099FormDocHeader.SetRange("IRIS Record ID", TempErrorInfo."Record ID");
                if IRS1099FormDocHeader.FindFirst() then
                    FormDocID := IRS1099FormDocHeader.ID;

                ErrorInfo.LockTable();
                ErrorInfo.InitRecord();     // assign new Line ID
                LineID := ErrorInfo."Line ID";

                ErrorInfo := TempErrorInfo;
                ErrorInfo."Line ID" := LineID;
                ErrorInfo."Transmission Document ID" := TransmissionDocumentID;
                ErrorInfo."Unique Transmission ID" := UniqueTransmissionId;
                ErrorInfo."IRS 1099 Form Doc. ID" := FormDocID;
                ErrorInfo.Insert(true);
                if TempErrorInfo."Error Code" = 'XML Schema Validation Error' then begin
                    if not XmlSchemaErrorLogged then begin
                        FeatureTelemetry.LogError('', Helper.GetIRISFeatureName(), IRSValidationTok, XmlSchemaValidationTelemetryErr);
                        XmlSchemaErrorLogged := true;
                    end;
                end else
                    if not ValidationErrorLogged then begin
                        FeatureTelemetry.LogError('', Helper.GetIRISFeatureName(), IRSValidationTok, IRSValidationTelemetryErr);
                        ValidationErrorLogged := true;
                    end;
            until TempErrorInfo.Next() = 0;
    end;

    procedure FilterErrorInformation(var ErrorInformation: Record "Error Information IRIS"; TransmissionDocumentID: Integer; SubmissionId: Text[20]; RecordId: Text[20])
    begin
        ErrorInformation.Reset();
        ErrorInformation.SetRange("Transmission Document ID", TransmissionDocumentID);
        if SubmissionId <> '' then begin
            ErrorInformation.SetRange("Submission ID", SubmissionId);
            if RecordId <> '' then
                ErrorInformation.SetFilter("Record ID", '%1|%2', RecordId, '');     // also show submission related errors
        end;
    end;

    procedure GetRecordErrorCount(TransmissionDocumentID: Integer; SubmissionId: Text[20]; RecordId: Text[20]): Integer
    var
        ErrorInformation: Record "Error Information IRIS";
    begin
        if (SubmissionId = '') or (RecordId = '') then
            exit(0);

        ErrorInformation.SetRange("Transmission Document ID", TransmissionDocumentID);
        ErrorInformation.SetRange("Entity Type", Enum::"Entity Type IRIS"::RecordType);
        ErrorInformation.SetRange("Submission ID", SubmissionId);
        ErrorInformation.SetRange("Record ID", RecordId);
        exit(ErrorInformation.Count());
    end;

    procedure HasSubmissionLevelErrors(TransmissionDocumentID: Integer; SubmissionId: Text[20]): Boolean
    var
        ErrorInformation: Record "Error Information IRIS";
    begin
        if SubmissionId = '' then
            exit(false);

        ErrorInformation.SetRange("Transmission Document ID", TransmissionDocumentID);
        ErrorInformation.SetRange("Entity Type", Enum::"Entity Type IRIS"::Submission);
        ErrorInformation.SetRange("Submission ID", SubmissionId);
        ErrorInformation.SetRange("Record ID", '');
        exit(not ErrorInformation.IsEmpty());
    end;

    procedure ShowErrorInformation(TransmissionDocumentID: Integer; SubmissionId: Text[20]; RecordId: Text[20])
    var
        ErrorInformation: Record "Error Information IRIS";
        ErrorInfoPage: Page "Error Information IRIS";
    begin
        FilterErrorInformation(ErrorInformation, TransmissionDocumentID, SubmissionId, RecordId);

        ErrorInfoPage.SetTableView(ErrorInformation);
        ErrorInfoPage.Run();
    end;

    #endregion

    #region Transmission Status Updates
    local procedure UpdateReceiptID(var Transmission: Record "Transmission IRIS"; TransmissionType: Enum "Transmission Type IRIS"; var TempIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header" temporary; ReceiptID: Text[100])
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
    begin
        if ReceiptID = '' then
            exit;

        if (Transmission."Receipt ID" <> ReceiptID) or (Transmission."Last Type" <> TransmissionType) then begin
            if TransmissionType = Enum::"Transmission Type IRIS"::"O" then
                Transmission."Original Receipt ID" := ReceiptID;
            Transmission."Last Type" := TransmissionType;
            Transmission."Receipt ID" := ReceiptID;
            Transmission."Receipt ID Assigned Manually" := false;
            Transmission.Modify(true);
            FeatureTelemetry.LogUsage('0000RGZ', Helper.GetIRISFeatureName(), ReceiptIDUpdatedEventTxt);
        end;

        // update Receipt ID in the IRS 1099 Form Documents sent in this transmission
        if TempIRS1099FormDocHeader.FindSet() then
            repeat
                IRS1099FormDocHeader.Get(TempIRS1099FormDocHeader.ID);
                if (IRS1099FormDocHeader.Status <> IRS1099FormDocHeader.Status::Abandoned) and
                   (IRS1099FormDocHeader."IRIS Last Receipt ID" <> ReceiptID)
                then begin
                    IRS1099FormDocHeader."IRIS Last Receipt ID" := ReceiptID;
                    IRS1099FormDocHeader.Modify(true);
                end;
            until TempIRS1099FormDocHeader.Next() = 0;
    end;

    procedure UpadateTransmissionStatus(var Transmission: Record "Transmission IRIS"; TransmStatusText: Text; SubmissionsStatus: Dictionary of [Text, Text])
    var
        TransmissionLog: Record "Transmission Log IRIS";
    begin
        if TransmissionLog.FindLastRecByReceiptID(Transmission."Receipt ID") then;
        UpadateTransmissionStatus(Transmission, TransmStatusText, SubmissionsStatus, TransmissionLog);
    end;

    local procedure UpadateTransmissionStatus(var Transmission: Record "Transmission IRIS"; TransmStatusText: Text; SubmissionsStatus: Dictionary of [Text, Text]; TransmissionLog: Record "Transmission Log IRIS")
    begin
        UpdateTransmissionStatusOnly(Transmission, TransmStatusText);
        if (TransmissionLog."Line ID" = 0) or
           ((TransmissionLog."Receipt ID" <> '') and (TransmissionLog."Receipt ID" = Transmission."Receipt ID"))
        then
            UpdateSubmissionsStatusAndReceiptId(Transmission, SubmissionsStatus, TransmissionLog);
        ProcessCorrectedDocuments(Transmission, SubmissionsStatus, TransmissionLog);
    end;

    local procedure UpdateTransmissionStatusOnly(var Transmission: Record "Transmission IRIS"; TransmStatusText: Text)
    var
        TransmissionStatus: Enum "Transmission Status IRIS";
        CustomDimensions: Dictionary of [Text, Text];
        PrevTransmStatusText: Text;
    begin
        if TransmStatusText = '' then
            exit;

        PrevTransmStatusText := Format(Transmission.Status);

        if not Evaluate(TransmissionStatus, TransmStatusText) then begin
            FeatureTelemetry.LogError('0000PSM', Helper.GetIRISFeatureName(), 'UpadateTransmissionStatus', StrSubstNo(UnexpectedStatusErr, TransmStatusText));
            Message(UnexpectedStatusUserErr, TransmStatusText);
            TransmissionStatus := Enum::"Transmission Status IRIS"::Unknown;
        end;
        Transmission.Validate(Status, TransmissionStatus);
        Transmission.Modify(true);

        CustomDimensions.Add('PreviousTransmissionStatus', PrevTransmStatusText);
        CustomDimensions.Add('NewTransmissionStatus', TransmStatusText);
        FeatureTelemetry.LogUsage('0000RGM', Helper.GetIRISFeatureName(), 'TransmissionStatusUpdated', CustomDimensions);

    end;

    local procedure UpdateSubmissionsStatusAndReceiptId(var Transmission: Record "Transmission IRIS"; SubmissionsStatus: Dictionary of [Text, Text]; TransmissionLog: Record "Transmission Log IRIS")
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        TransmissionLogLine: Record "Transmission Log Line IRIS";
        CurrSubmissionStatus: Enum "Transmission Status IRIS";
        SubmissionStatusText: Text;
    begin
        IRS1099FormDocHeader.SetRange("IRIS Transmission Document ID", Transmission."Document ID");
        IRS1099FormDocHeader.SetRange("IRIS Last Receipt ID", Transmission."Receipt ID");
        IRS1099FormDocHeader.SetFilter(Status, '<>%1', IRS1099FormDocHeader.Status::Abandoned);
        TransmissionLogLine.SetRange("Transmission Log ID", TransmissionLog."Line ID");

        if not IRS1099FormDocHeader.FindSet(true) then
            exit;

        repeat
            if TransmissionLog."Line ID" <> 0 then begin
                TransmissionLogLine.SetRange("IRS 1099 Form Document ID", IRS1099FormDocHeader.ID);
                TransmissionLogLine.SetRange("Submission ID", IRS1099FormDocHeader."IRIS Submission ID");
                TransmissionLogLine.SetRange("Record ID", IRS1099FormDocHeader."IRIS Record ID");
                if TransmissionLogLine.IsEmpty() then
                    continue;
            end;

            if not SubmissionsStatus.Get(IRS1099FormDocHeader."IRIS Submission ID", SubmissionStatusText) then
                continue;

            if SubmissionStatusText = '' then
                continue;

            if not Evaluate(CurrSubmissionStatus, SubmissionStatusText) then begin
                FeatureTelemetry.LogError('0000PSN', Helper.GetIRISFeatureName(), 'UpadateSubmissionsStatus', StrSubstNo(UnexpectedStatusErr, SubmissionStatusText));
                CurrSubmissionStatus := Enum::"Transmission Status IRIS"::Unknown;
            end;

            if CurrSubmissionStatus in [Enum::"Transmission Status IRIS"::Accepted, Enum::"Transmission Status IRIS"::"Partially Accepted", Enum::"Transmission Status IRIS"::"Accepted with Errors"] then begin
                IRS1099FormDocHeader."IRIS Last Accepted Receipt ID" := Transmission."Receipt ID";      // update last accepted receipt ID only if IRS returned accepted status for this submission
                if IRS1099FormDocHeader."IRIS Updated Not Sent" then
                    IRS1099FormDocHeader."IRIS Needs Correction" := true;
            end;
            if (CurrSubmissionStatus = Enum::"Transmission Status IRIS"::Accepted) and
               not IRS1099FormDocHeader."IRIS Updated Not Sent" and
               (IRS1099FormDocHeader.Status <> IRS1099FormDocHeader.Status::Open)
            then
                IRS1099FormDocHeader.Validate(Status, Enum::"IRS 1099 Form Doc. Status"::Submitted);

            IRS1099FormDocHeader.Validate("IRIS Submission Status", CurrSubmissionStatus);
            IRS1099FormDocHeader.Modify(true);

        until IRS1099FormDocHeader.Next() = 0;
    end;

    #endregion

    #region Update Form Documents
    procedure Update(var Transmission: Record "Transmission IRIS")
    var
        TempDocHeader: Record "IRS 1099 Form Doc. Header" temporary;
        TempFormDocLineToUpdate: Record "IRS 1099 Form Doc. Line" temporary;
        TempFormDocLineDetail: Record "IRS 1099 Form Doc. Line Detail" temporary;
        IRS1099FormDocUpdate: Page "IRS 1099 Form Doc. Update";
        AddedDocsCount: Integer;
        FormLinesUpdated: Boolean;
        FormDocsCreated: Boolean;
        UpdateMessage: Text;
    begin
        if Transmission.Status = Enum::"Transmission Status IRIS"::Rejected then
            Error(CannotUpdateRejectedTransmissionErr);

        CollectReleasedFormDocsToAdd(Transmission, TempDocHeader);
        GetIRS1099FormDocsToUpdate(TempFormDocLineToUpdate, TempFormDocLineDetail, Transmission."Period No.");
        if TempFormDocLineToUpdate.IsEmpty() then begin
            AddedDocsCount := ApplySelectedUpdates(Transmission, TempFormDocLineToUpdate, TempFormDocLineDetail,
                TempDocHeader, FormLinesUpdated, FormDocsCreated);
            if AddedDocsCount = 0 then
                Message(TransmissionDocUpToDateErr)
            else
                Message(FormDocsAddedMsg, AddedDocsCount);
            exit;
        end;

        IRS1099FormDocUpdate.SetLines(TempFormDocLineToUpdate);
        IRS1099FormDocUpdate.LookupMode := true;
        if IRS1099FormDocUpdate.RunModal() = Action::LookupOK then begin
            FeatureTelemetry.LogUsage('0000PVN', Helper.GetIRISFeatureName(), FormDocsUpdateStartedEventTxt);

            IRS1099FormDocUpdate.GetSelectedLines(TempFormDocLineToUpdate);

            AddedDocsCount := ApplySelectedUpdates(Transmission, TempFormDocLineToUpdate, TempFormDocLineDetail,
                TempDocHeader, FormLinesUpdated, FormDocsCreated);

            FeatureTelemetry.LogUsage('0000PVN', Helper.GetIRISFeatureName(), FormDocsUpdateCompletedEventTxt);
        end;

        if FormLinesUpdated or FormDocsCreated or (AddedDocsCount > 0) then begin
            if AddedDocsCount > 0 then
                UpdateMessage += StrSubstNo(FormDocsAddedMsg, AddedDocsCount);
            if FormLinesUpdated then
                UpdateMessage += FormLinesUpdatedMsg;
            if FormDocsCreated then
                UpdateMessage += FormDocsCreatedMsg;

            Message(UpdateMessage);
        end else
            Message(NoFormLinesSelectedMsg);
    end;

    [CommitBehavior(CommitBehavior::Error)]
    local procedure ApplySelectedUpdates(var Transmission: Record "Transmission IRIS"; var TempDocLine: Record "IRS 1099 Form Doc. Line" temporary; var TempDetails: Record "IRS 1099 Form Doc. Line Detail" temporary; var TempDocHeaderToAdd: Record "IRS 1099 Form Doc. Header" temporary; var FormLinesUpdated: Boolean; var FormDocsCreated: Boolean) AddedDocsCount: Integer
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        IRS1099FormDocument: Codeunit "IRS 1099 Form Document";
        NewDocumentIDs: List of [Integer];
        ChangedDocumentIDs: List of [Integer];
        DocumentID: Integer;
        DependentEligibilityChanges: Text;
    begin
        LockTransmission(Transmission);
        if Transmission.Status = Transmission.Status::Rejected then
            Error(CannotUpdateRejectedTransmissionErr);

        TempDocLine.Reset();
        TempDocLine.SetRange("Line Action", "IRS 1099 Form Doc. Line Action"::Update);
        if TempDocLine.FindSet() then
            repeat
                if not ChangedDocumentIDs.Contains(TempDocLine."Document ID") then
                    ChangedDocumentIDs.Add(TempDocLine."Document ID");
            until TempDocLine.Next() = 0;
        if not TempDocLine.IsEmpty() then begin
            DocHeader.LockTable();
            foreach DocumentID in ChangedDocumentIDs do begin
                DocHeader.Get(DocumentID);
                MarkDocumentUpdatedNotSent(DocHeader);
            end;
            UpdateIRS1099FormDocLineAmounts(TempDocLine, TempDetails);
            FormLinesUpdated := true;
        end;

        TempDocLine.SetFilter("Line Action", '%1|%2', "IRS 1099 Form Doc. Line Action"::Create, "IRS 1099 Form Doc. Line Action"::Abandon);
        if not TempDocLine.IsEmpty() then begin
            NewDocumentIDs := UpdateIRS1099FormDocuments(TempDocLine, TempDetails, DependentEligibilityChanges);
            FormDocsCreated := true;
        end;
        foreach DocumentID in ChangedDocumentIDs do begin
            DocHeader.Get(DocumentID);
            if DocHeader.Status <> DocHeader.Status::Abandoned then begin
                RecalculateSelectedDocumentEligibility(DocumentID, TempDocLine, DependentEligibilityChanges);
                Supplemental.ValidateSupplementalLines(DocumentID);
                if not DocumentHaveLinesToReport(DocHeader) then begin
                    CheckDocumentCanBeRemovedFromTransmission(DocHeader);
                    DocHeader.Status := DocHeader.Status::Open;
                    DocHeader."IRIS Transmission Document ID" := 0;
                    DocHeader.Modify(true);
                end;
            end;
        end;
        foreach DocumentID in NewDocumentIDs do begin
            DocHeader.Get(DocumentID);
            if DocumentHaveLinesToReport(DocHeader) then begin
                IRS1099FormDocument.Release(DocHeader);
                TempDocHeaderToAdd := DocHeader;
                TempDocHeaderToAdd.Insert();
            end;
        end;
        ConfirmDependentEligibilityChanges(DependentEligibilityChanges);
        AddedDocsCount := AddSelectedFormDocsToTransmission(Transmission, TempDocHeaderToAdd);
    end;

    local procedure ConfirmDependentEligibilityChanges(DependentEligibilityChanges: Text)
    begin
        if DependentEligibilityChanges <> '' then
            if not ConfirmMgt.GetResponseOrDefault(StrSubstNo(DependentEligibilityChangesQst, DependentEligibilityChanges), false) then
                Error('');
    end;

    local procedure MarkDocumentUpdatedNotSent(var DocHeader: Record "IRS 1099 Form Doc. Header")
    begin
        if (DocHeader.Status <> DocHeader.Status::"In Progress") and
           (DocHeader."IRIS Submission Status" = DocHeader."IRIS Submission Status"::None) and
           (DocHeader."IRIS Last Receipt ID" = '') and
           (DocHeader."IRIS Last Accepted Receipt ID" = '') and
           not DocHeader."IRIS Updated Not Sent"
        then
            exit;

        DocHeader."IRIS Updated Not Sent" := true;
        if DocHeader."IRIS Last Accepted Receipt ID" <> '' then
            DocHeader."IRIS Needs Correction" := true;
        DocHeader.Modify(true);
    end;

    local procedure RecalculateSelectedDocumentEligibility(DocumentID: Integer; var TempSelectedDocLine: Record "IRS 1099 Form Doc. Line" temporary; var DependentEligibilityChanges: Text)
    var
        DocLine: Record "IRS 1099 Form Doc. Line";
        TempSelectedLine: Record "IRS 1099 Form Doc. Line" temporary;
        TempUnselectedLine: Record "IRS 1099 Form Doc. Line" temporary;
    begin
        TempSelectedLine.Copy(TempSelectedDocLine, true);
        DocLine.SetRange("Document ID", DocumentID);
        if DocLine.FindSet() then
            repeat
                if not TempSelectedLine.Get(DocLine."Period No.", DocLine."Vendor No.", DocLine."Form No.", DocLine."Document ID", DocLine."Line No.") then begin
                    TempUnselectedLine := DocLine;
                    TempUnselectedLine.Insert();
                end;
            until DocLine.Next() = 0;

        Supplemental.RecalculateIncludeIn1099(DocumentID);
        if TempUnselectedLine.FindSet() then
            repeat
                DocLine.Get(TempUnselectedLine."Period No.", TempUnselectedLine."Vendor No.", TempUnselectedLine."Form No.", TempUnselectedLine."Document ID", TempUnselectedLine."Line No.");
                if DocLine."Include In 1099" <> TempUnselectedLine."Include In 1099" then
                    DependentEligibilityChanges += StrSubstNo(DependentEligibilityChangeTxt, DocumentID, DocLine."Form Box No.",
                        TempUnselectedLine."Include In 1099", DocLine."Include In 1099");
            until TempUnselectedLine.Next() = 0;
    end;

    local procedure CheckDocumentCanBeRemovedFromTransmission(DocHeader: Record "IRS 1099 Form Doc. Header")
    var
        OriginalDocHeader: Record "IRS 1099 Form Doc. Header";
        TransmissionLogLine: Record "Transmission Log Line IRIS";
    begin
        OriginalDocHeader.Get(DocHeader.ID);
        if not (OriginalDocHeader.Status in [OriginalDocHeader.Status::Open, OriginalDocHeader.Status::Released]) or
           (OriginalDocHeader."IRIS Submission Status" <> OriginalDocHeader."IRIS Submission Status"::None) or
           (OriginalDocHeader."IRIS Submission ID" <> '') or
           (OriginalDocHeader."IRIS Record ID" <> '') or
           (OriginalDocHeader."IRIS Last Receipt ID" <> '') or
           (OriginalDocHeader."IRIS Last Accepted Receipt ID" <> '') or
           OriginalDocHeader."Allow Correction" or OriginalDocHeader."IRIS Needs Correction" or
           OriginalDocHeader."IRIS Updated Not Sent" or OriginalDocHeader."IRIS Corrected" or
           OriginalDocHeader."IRIS Corrected to Zeros"
        then
            Error(DocCannotBeRemovedFromTransmErr, OriginalDocHeader.ID);

        TransmissionLogLine.SetRange("IRS 1099 Form Document ID", OriginalDocHeader.ID);
        if not TransmissionLogLine.IsEmpty() then
            Error(DocCannotBeRemovedFromTransmErr, OriginalDocHeader.ID);
    end;

    local procedure IsFormSupported(FormNo: Code[20]): Boolean
    var
        FormTypeIRIS: Enum "Form Type IRIS";
    begin
        exit(Evaluate(FormTypeIRIS, FormNo));
    end;

    local procedure DocumentHaveLinesToReport(var IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header"): Boolean
    var
        IRS1099FormDocLine: Record "IRS 1099 Form Doc. Line";
    begin
        IRS1099FormDocLine.SetRange("Period No.", IRS1099FormDocHeader."Period No.");
        IRS1099FormDocLine.SetRange("Vendor No.", IRS1099FormDocHeader."Vendor No.");
        IRS1099FormDocLine.SetRange("Form No.", IRS1099FormDocHeader."Form No.");
        IRS1099FormDocLine.SetRange("Document ID", IRS1099FormDocHeader.ID);
        IRS1099FormDocLine.SetRange("Include In 1099", true);
        exit(not IRS1099FormDocLine.IsEmpty());
    end;

    procedure AddReleasedFormDocsToTransmission(var Transmission: Record "Transmission IRIS") DocsCount: Integer
    var
        TempDocHeaderToAdd: Record "IRS 1099 Form Doc. Header" temporary;
    begin
        LockTransmission(Transmission);
        CollectReleasedFormDocsToAdd(Transmission, TempDocHeaderToAdd);
        exit(AddSelectedFormDocsToTransmission(Transmission, TempDocHeaderToAdd));
    end;

    local procedure CollectReleasedFormDocsToAdd(Transmission: Record "Transmission IRIS"; var TempDocHeaderToAdd: Record "IRS 1099 Form Doc. Header" temporary)
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        ProcessTransmissionIRISEvents: Codeunit "Process Trans. IRIS Events";
    begin
        DocHeader.SetRange(Status, DocHeader.Status::Released);
        DocHeader.SetRange("Period No.", Transmission."Period No.");
        ProcessTransmissionIRISEvents.RunOnAddReleasedFormDocsToTransmissionOnBeforeIRS1099FormDocHeaderFindSet(DocHeader, Transmission);
        if DocHeader.FindSet() then
            repeat
                if DocumentHaveLinesToReport(DocHeader) and
                   IsFormSupported(DocHeader."Form No.") and
                   (DocHeader."IRIS Transmission Document ID" <> Transmission."Document ID")
                then begin
                    TempDocHeaderToAdd := DocHeader;
                    TempDocHeaderToAdd.Insert();
                end;
            until DocHeader.Next() = 0;
    end;

    [CommitBehavior(CommitBehavior::Error)]
    local procedure AddSelectedFormDocsToTransmission(Transmission: Record "Transmission IRIS"; var TempDocHeaderToAdd: Record "IRS 1099 Form Doc. Header" temporary) DocsCount: Integer
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
    begin
        TempDocHeaderToAdd.Reset();
        if TempDocHeaderToAdd.FindSet() then
            repeat
                DocHeader.Get(TempDocHeaderToAdd.ID);
                if (DocHeader.Status = DocHeader.Status::Released) and DocumentHaveLinesToReport(DocHeader) then begin
                    Supplemental.ValidateSupplementalLines(DocHeader.ID);
                    DocHeader."IRIS Transmission Document ID" := Transmission."Document ID";
                    DocHeader.Modify();
                    DocsCount += 1;
                end;
            until TempDocHeaderToAdd.Next() = 0;
    end;

    local procedure LockTransmission(var Transmission: Record "Transmission IRIS")
    var
        SelectedSystemId: Guid;
    begin
        SelectedSystemId := Transmission.SystemId;
        Transmission.LockTable();
        if not Transmission.Get(Transmission."Document ID") then
            Error(TransmissionChangedErr);
        if Transmission.SystemId <> SelectedSystemId then
            Error(TransmissionChangedErr);
    end;

    procedure GetIRS1099FormDocsToUpdate(var TempFormDocLineToUpdate: Record "IRS 1099 Form Doc. Line" temporary; var TempFormDocLineDetail: Record "IRS 1099 Form Doc. Line Detail" temporary; PeriodNo: Text[4])
    var
        FormDocHeader: Record "IRS 1099 Form Doc. Header";
        FormDocLine: Record "IRS 1099 Form Doc. Line";
        TempFormDocLine: Record "IRS 1099 Form Doc. Line" temporary;
        TempVendFormBoxBuffer: Record "IRS 1099 Vend. Form Box Buffer" temporary;
        TempCalcParameters: Record "IRS 1099 Calc. Params";
        IRSFormsFacade: Codeunit "IRS Forms Facade";
        IRS1099FormDocImpl: Codeunit "IRS 1099 Form Docs Impl.";
        LineNo: Integer;
    begin
        TempFormDocLineToUpdate.Reset();
        TempFormDocLineToUpdate.DeleteAll();

        TempCalcParameters."Period No." := PeriodNo;
        IRSFormsFacade.GetVendorFormBoxAmount(TempVendFormBoxBuffer, TempCalcParameters);

        FormDocLine.SetRange("Period No.", PeriodNo);
        if FormDocLine.FindSet() then
            repeat
                if FormDocHeader.Get(FormDocLine."Document ID") then
                    if FormDocHeader.Status <> Enum::"IRS 1099 Form Doc. Status"::Abandoned then begin
                        TempFormDocLine := FormDocLine;
                        TempFormDocLine.Insert();
                    end;
            until FormDocLine.Next() = 0;

        TempVendFormBoxBuffer.SetRange("Period No.", PeriodNo);
        TempVendFormBoxBuffer.SetRange("Buffer Type", TempVendFormBoxBuffer."Buffer Type"::Amount);
        if TempFormDocLine.FindSet() then
            repeat
                TempVendFormBoxBuffer.SetRange("Vendor No.", TempFormDocLine."Vendor No.");
                TempVendFormBoxBuffer.SetRange("Form No.", TempFormDocLine."Form No.");
                TempVendFormBoxBuffer.SetRange("Form Box No.", TempFormDocLine."Form Box No.");
                if TempVendFormBoxBuffer.FindFirst() then begin
                    TempVendFormBoxBuffer.CalcFields("Minimum Reportable Amount", "Adjustment Amount");
                    if (TempFormDocLine.Amount <> TempVendFormBoxBuffer."Reporting Amount") or
                       (TempFormDocLine."Minimum Reportable Amount" <> TempVendFormBoxBuffer."Minimum Reportable Amount") or
                       (TempFormDocLine."Include In 1099" <> TempVendFormBoxBuffer."Include In 1099")
                    then begin
                        // update
                        TempVendFormBoxBuffer."Document ID" := TempFormDocLine."Document ID";
                        TempVendFormBoxBuffer."Line No" := TempFormDocLine."Line No.";
                        IRS1099FormDocImpl.AddTempFormLineFromBuffer(TempFormDocLineToUpdate, TempFormDocLineDetail, TempVendFormBoxBuffer, "IRS 1099 Form Doc. Line Action"::Update);
                    end;
                    TempVendFormBoxBuffer.Delete();
                end else begin
                    // abandon
                    TempFormDocLineToUpdate := TempFormDocLine;
                    TempFormDocLineToUpdate."Line Action" := "IRS 1099 Form Doc. Line Action"::Abandon;
                    TempFormDocLineToUpdate.Insert();
                end;
            until TempFormDocLine.Next() = 0;

        // create
        TempVendFormBoxBuffer.Reset();
        TempVendFormBoxBuffer.SetRange("Period No.", PeriodNo);
        TempVendFormBoxBuffer.SetRange("Buffer Type", TempVendFormBoxBuffer."Buffer Type"::Amount);
        if TempVendFormBoxBuffer.FindSet() then
            repeat
                LineNo += 1000;
                TempVendFormBoxBuffer."Line No" := LineNo;
                IRS1099FormDocImpl.AddTempFormLineFromBuffer(TempFormDocLineToUpdate, TempFormDocLineDetail, TempVendFormBoxBuffer, "IRS 1099 Form Doc. Line Action"::Create);
            until TempVendFormBoxBuffer.Next() = 0;
    end;

    [CommitBehavior(CommitBehavior::Error)]
    procedure UpdateIRS1099FormDocuments(var TempFormDocLineToUpdate: Record "IRS 1099 Form Doc. Line" temporary; var TempFormDocLineDetail: Record "IRS 1099 Form Doc. Line Detail" temporary) NewIRS1099FormDocHeaderIDs: List of [Integer]
    var
        DependentEligibilityChanges: Text;
    begin
        NewIRS1099FormDocHeaderIDs := UpdateIRS1099FormDocuments(TempFormDocLineToUpdate, TempFormDocLineDetail, DependentEligibilityChanges);
        ConfirmDependentEligibilityChanges(DependentEligibilityChanges);
    end;

    [CommitBehavior(CommitBehavior::Error)]
    local procedure UpdateIRS1099FormDocuments(var TempFormDocLineToUpdate: Record "IRS 1099 Form Doc. Line" temporary; var TempFormDocLineDetail: Record "IRS 1099 Form Doc. Line Detail" temporary; var DependentEligibilityChanges: Text) NewIRS1099FormDocHeaderIDs: List of [Integer]
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        IRS1099FormDocLine: Record "IRS 1099 Form Doc. Line";
        TempFormDocHeaderToCreate: Record "IRS 1099 Form Doc. Header" temporary;
        TempFormDocLineToCreate: Record "IRS 1099 Form Doc. Line" temporary;
        TempFormDocLineToAbandon: Record "IRS 1099 Form Doc. Line" temporary;
        TempOldFormDocLine: Record "IRS 1099 Form Doc. Line" temporary;
        TempCreateDetails: Record "IRS 1099 Form Doc. Line Detail" temporary;
        OldDetails: Record "IRS 1099 Form Doc. Line Detail";
        TempSupplLine: Record "IRS 1099 Doc. Suppl. Line" temporary;
        SupplLine: Record "IRS 1099 Doc. Suppl. Line";
        IRS1099FormDocImpl: Codeunit "IRS 1099 Form Docs Impl.";
        IRS1099FormDocument: Codeunit "IRS 1099 Form Document";
        SourceDocumentIDs: Dictionary of [Integer, Integer];
        DocumentID: Integer;
        LineNo: Integer;
    begin
        if TempFormDocLineToUpdate.IsEmpty() then
            exit;

        LineNo := 0;
        TempFormDocLineToUpdate.SetRange("Line Action", "IRS 1099 Form Doc. Line Action"::Create);
        if TempFormDocLineToUpdate.FindSet() then
            repeat
                TempFormDocLineToCreate := TempFormDocLineToUpdate;
                FindAndValidateSourceDocument(TempFormDocLineToCreate);
                TempFormDocLineToCreate.Insert(true);
                CopyFormLineDetails(TempFormDocLineDetail, TempCreateDetails, TempFormDocLineToUpdate, TempFormDocLineToCreate);
                if TempFormDocLineToCreate."Line No." > LineNo then
                    LineNo := TempFormDocLineToCreate."Line No.";
            until TempFormDocLineToUpdate.Next() = 0;

        TempFormDocLineToUpdate.SetRange("Line Action", "IRS 1099 Form Doc. Line Action"::Abandon);
        if TempFormDocLineToUpdate.FindSet() then
            repeat
                TempFormDocLineToAbandon := TempFormDocLineToUpdate;
                TempFormDocLineToAbandon.Insert(true);
                SupplLine.SetRange("Document ID", TempFormDocLineToAbandon."Document ID");
                SupplLine.SetRange("Parent Form Box No.", TempFormDocLineToAbandon."Form Box No.");
                if not SupplLine.IsEmpty() then
                    Error(RemovedParentErr, TempFormDocLineToAbandon."Document ID", TempFormDocLineToAbandon."Form Box No.");
            until TempFormDocLineToUpdate.Next() = 0;

        IRS1099FormDocHeader.ReadIsolation(IsolationLevel::UpdLock);
        if TempFormDocLineToCreate.FindSet() then
            repeat
                if IRS1099FormDocHeader.Get(TempFormDocLineToCreate."Document ID") then
                    if IRS1099FormDocHeader.Status <> IRS1099FormDocHeader.Status::Abandoned then begin
                        Supplemental.CopySupplLinesToTemp(IRS1099FormDocHeader.ID, TempSupplLine);
                        // keep only lines that were not selected for removal
                        IRS1099FormDocLine.SetRange("Document ID", IRS1099FormDocHeader.ID);
                        if IRS1099FormDocLine.FindSet() then
                            repeat
                                if not TempFormDocLineToAbandon.Get(IRS1099FormDocLine."Period No.", IRS1099FormDocLine."Vendor No.",
                                    IRS1099FormDocLine."Form No.", IRS1099FormDocLine."Document ID", IRS1099FormDocLine."Line No.")
                                then begin
                                    TempOldFormDocLine := IRS1099FormDocLine;
                                    TempOldFormDocLine.Insert(true);
                                end;
                            until IRS1099FormDocLine.Next() = 0;

                        // abandon old document
                        MarkDocumentUpdatedNotSent(IRS1099FormDocHeader);
                        IRS1099FormDocument.Abandon(IRS1099FormDocHeader);
                    end;
            until TempFormDocLineToCreate.Next() = 0;

        // copy old document lines to new document
        if TempOldFormDocLine.FindSet() then
            repeat
                LineNo += 1000;
                TempFormDocLineToCreate := TempOldFormDocLine;
                TempFormDocLineToCreate."Line No." := LineNo;
                TempFormDocLineToCreate.Insert(true);
                CopyFormLineDetails(OldDetails, TempCreateDetails, TempOldFormDocLine, TempFormDocLineToCreate);
            until TempOldFormDocLine.Next() = 0;

        CollectCopiedEligibilityChanges(TempOldFormDocLine, TempFormDocLineToCreate, TempFormDocLineToUpdate, DependentEligibilityChanges);
        CreateTempFormHeadersFromLines(TempFormDocLineToCreate, TempFormDocHeaderToCreate, TempCreateDetails, SourceDocumentIDs);

        NewIRS1099FormDocHeaderIDs := IRS1099FormDocImpl.InsertFormDocsFromTempBuffer(TempFormDocHeaderToCreate, TempFormDocLineToCreate, TempCreateDetails, TempSupplLine, SourceDocumentIDs);
        foreach DocumentID in NewIRS1099FormDocHeaderIDs do begin
            IRS1099FormDocHeader.Get(DocumentID);
            MarkDocumentUpdatedNotSent(IRS1099FormDocHeader);
        end;

        if TempFormDocLineToAbandon.FindSet() then
            repeat
                if IRS1099FormDocHeader.Get(TempFormDocLineToAbandon."Document ID") then begin
                    MarkDocumentUpdatedNotSent(IRS1099FormDocHeader);
                    IRS1099FormDocument.Abandon(IRS1099FormDocHeader);
                end;
            until TempFormDocLineToAbandon.Next() = 0;
    end;

    local procedure CollectCopiedEligibilityChanges(var TempOldDocLine: Record "IRS 1099 Form Doc. Line" temporary; var TempNewDocLine: Record "IRS 1099 Form Doc. Line" temporary; var TempSelectedDocLine: Record "IRS 1099 Form Doc. Line" temporary; var DependentEligibilityChanges: Text)
    var
        TempSelectedLine: Record "IRS 1099 Form Doc. Line" temporary;
        TempWithholdingLine: Record "IRS 1099 Form Doc. Line" temporary;
        IncludeIn1099: Boolean;
    begin
        TempSelectedLine.Copy(TempSelectedDocLine, true);
        TempSelectedLine.Reset();
        TempWithholdingLine.Copy(TempNewDocLine, true);
        TempWithholdingLine.Reset();
        TempWithholdingLine.SetFilter("Form Box No.", '%1|%2', 'NEC-04', 'MISC-04');
        TempWithholdingLine.SetFilter(Amount, '>0');
        TempOldDocLine.Reset();
        if TempOldDocLine.FindSet() then
            repeat
                if TempSelectedLine.Get(TempOldDocLine."Period No.", TempOldDocLine."Vendor No.", TempOldDocLine."Form No.",
                    TempOldDocLine."Document ID", TempOldDocLine."Line No.")
                then
                    if TempSelectedLine."Line Action" = TempSelectedLine."Line Action"::Update then
                        continue;

                TempWithholdingLine.SetRange("Period No.", TempOldDocLine."Period No.");
                TempWithholdingLine.SetRange("Vendor No.", TempOldDocLine."Vendor No.");
                TempWithholdingLine.SetRange("Form No.", TempOldDocLine."Form No.");
                TempWithholdingLine.SetRange("Document ID", TempOldDocLine."Document ID");
                IncludeIn1099 := Supplemental.IsFormBoxAmountReportable(TempOldDocLine."Form No.", TempOldDocLine."Form Box No.",
                    TempOldDocLine.Amount, TempOldDocLine."Minimum Reportable Amount", not TempWithholdingLine.IsEmpty());
                if IncludeIn1099 <> TempOldDocLine."Include In 1099" then
                    DependentEligibilityChanges += StrSubstNo(DependentEligibilityChangeTxt, TempOldDocLine."Document ID",
                        TempOldDocLine."Form Box No.", TempOldDocLine."Include In 1099", IncludeIn1099);
            until TempOldDocLine.Next() = 0;
    end;

    local procedure FindAndValidateSourceDocument(var CandidateDocLine: Record "IRS 1099 Form Doc. Line" temporary)
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
    begin
        if CandidateDocLine."Document ID" <> 0 then begin
            DocHeader.Get(CandidateDocLine."Document ID");
            DocHeader.TestField("Period No.", CandidateDocLine."Period No.");
            DocHeader.TestField("Vendor No.", CandidateDocLine."Vendor No.");
            DocHeader.TestField("Form No.", CandidateDocLine."Form No.");
            if DocHeader.Status = DocHeader.Status::Abandoned then
                Error(AbandonedSourceErr, DocHeader.ID);
            exit;
        end;

        DocHeader.SetRange("Period No.", CandidateDocLine."Period No.");
        DocHeader.SetRange("Vendor No.", CandidateDocLine."Vendor No.");
        DocHeader.SetRange("Form No.", CandidateDocLine."Form No.");
        DocHeader.SetFilter(Status, '<>%1', DocHeader.Status::Abandoned);
        if DocHeader.Count() > 1 then
            Error(AmbiguousSourceErr, CandidateDocLine."Period No.", CandidateDocLine."Vendor No.", CandidateDocLine."Form No.");
        if DocHeader.FindFirst() then
            CandidateDocLine."Document ID" := DocHeader.ID;
    end;

    local procedure CopyFormLineDetails(var SourceDetails: Record "IRS 1099 Form Doc. Line Detail"; var TempTargetDetails: Record "IRS 1099 Form Doc. Line Detail" temporary; SourceDocLine: Record "IRS 1099 Form Doc. Line"; TargetDocLine: Record "IRS 1099 Form Doc. Line")
    begin
        SourceDetails.Reset();
        SourceDetails.SetRange("Document ID", SourceDocLine."Document ID");
        SourceDetails.SetRange("Line No.", SourceDocLine."Line No.");
        if SourceDetails.FindSet() then
            repeat
                TempTargetDetails := SourceDetails;
                TempTargetDetails."Document ID" := TargetDocLine."Document ID";
                TempTargetDetails."Line No." := TargetDocLine."Line No.";
                TempTargetDetails.Insert();
            until SourceDetails.Next() = 0;
    end;

    local procedure UpdateIRS1099FormDocLineAmounts(var TempIRS1099FormDocLine: Record "IRS 1099 Form Doc. Line" temporary; var TempIRS1099FormDocLineDetail: Record "IRS 1099 Form Doc. Line Detail" temporary)
    var
        IRSFormsSetup: Record "IRS Forms Setup";
        IRS1099FormDocLine: Record "IRS 1099 Form Doc. Line";
        IRS1099FormDocLineDetail: Record "IRS 1099 Form Doc. Line Detail";
    begin
        if not TempIRS1099FormDocLine.FindSet() then
            exit;

        IRSFormsSetup.Get();
        repeat
            IRS1099FormDocLine.TransferFields(TempIRS1099FormDocLine);
            IRS1099FormDocLine.Modify(true);

            if IRSFormsSetup."Collect Details For Line" then begin
                IRS1099FormDocLineDetail.SetRange("Document ID", IRS1099FormDocLine."Document ID");
                IRS1099FormDocLineDetail.SetRange("Line No.", IRS1099FormDocLine."Line No.");
                IRS1099FormDocLineDetail.DeleteAll(true);

                TempIRS1099FormDocLineDetail.CopyFilters(IRS1099FormDocLineDetail);
                if TempIRS1099FormDocLineDetail.FindSet() then
                    repeat
                        IRS1099FormDocLineDetail := TempIRS1099FormDocLineDetail;
                        IRS1099FormDocLineDetail.Insert(true);
                    until TempIRS1099FormDocLineDetail.Next() = 0;
            end;
        until TempIRS1099FormDocLine.Next() = 0;
    end;

    local procedure CreateTempFormHeadersFromLines(var TempFormDocLine: Record "IRS 1099 Form Doc. Line" temporary; var TempFormDocHeader: Record "IRS 1099 Form Doc. Header" temporary; var TempDetails: Record "IRS 1099 Form Doc. Line Detail" temporary; var SourceDocumentIDs: Dictionary of [Integer, Integer])
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        TempNewFormDocLine: Record "IRS 1099 Form Doc. Line" temporary;
        TempNewDetails: Record "IRS 1099 Form Doc. Line Detail" temporary;
        DocumentID: Integer;
        SourceDocumentID: Integer;
        LineNo: Integer;
    begin
        if not TempFormDocLine.FindSet() then
            exit;

        DocumentID := 0;
        repeat
            DocumentID += 1;
            TempFormDocHeader.Init();
            TempFormDocHeader.ID := DocumentID;
            TempFormDocHeader."Period No." := TempFormDocLine."Period No.";
            TempFormDocHeader."Vendor No." := TempFormDocLine."Vendor No.";
            TempFormDocHeader."Form No." := TempFormDocLine."Form No.";
            TempFormDocHeader.Insert(true);
            SourceDocumentID := TempFormDocLine."Document ID";
            if SourceDocumentID <> 0 then
                SourceDocumentIDs.Add(DocumentID, SourceDocumentID);

            LineNo := 0;
            TempFormDocLine.SetRange("Vendor No.", TempFormDocLine."Vendor No.");
            TempFormDocLine.SetRange("Form No.", TempFormDocLine."Form No.");
            TempFormDocLine.SetRange("Period No.", TempFormDocLine."Period No.");
            TempFormDocLine.SetRange("Document ID", SourceDocumentID);
            repeat
                LineNo += 1000;
                TempNewFormDocLine := TempFormDocLine;
                TempNewFormDocLine."Document ID" := DocumentID;
                TempNewFormDocLine."Line No." := LineNo;
                TempNewFormDocLine.Insert(true);
                CopyFormLineDetails(TempDetails, TempNewDetails, TempFormDocLine, TempNewFormDocLine);
            until TempFormDocLine.Next() = 0;

            // restore transmission related fields from the original document
            if IRS1099FormDocHeader.Get(SourceDocumentID) then begin
                TempFormDocHeader."IRIS Submission Status" := IRS1099FormDocHeader."IRIS Submission Status";
                TempFormDocHeader."IRIS Submission ID" := IRS1099FormDocHeader."IRIS Submission ID";
                TempFormDocHeader."IRIS Record ID" := IRS1099FormDocHeader."IRIS Record ID";
                TempFormDocHeader."IRIS Last Receipt ID" := IRS1099FormDocHeader."IRIS Last Receipt ID";
                TempFormDocHeader."IRIS Last Accepted Receipt ID" := IRS1099FormDocHeader."IRIS Last Accepted Receipt ID";
                TempFormDocHeader."IRIS Updated Not Sent" := IRS1099FormDocHeader."IRIS Updated Not Sent";
                TempFormDocHeader."IRIS Needs Correction" := IRS1099FormDocHeader."IRIS Needs Correction";
                TempFormDocHeader.Modify(true);
            end;

            TempFormDocLine.SetRange("Vendor No.");
            TempFormDocLine.SetRange("Form No.");
            TempFormDocLine.SetRange("Period No.");
            TempFormDocLine.SetRange("Document ID");
        until TempFormDocLine.Next() = 0;

        TempFormDocLine.Copy(TempNewFormDocLine, true);
        TempDetails.Copy(TempNewDetails, true);
    end;

    #endregion

    #region Document Status Updates
    local procedure ProcessCorrectedDocuments(Transmission: Record "Transmission IRIS"; SubmissionsStatus: Dictionary of [Text, Text]; TransmissionLog: Record "Transmission Log IRIS")
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        TransmissionLogLine: Record "Transmission Log Line IRIS";
        IRS1099FormDocument: Codeunit "IRS 1099 Form Document";
        SubmissionStatus: Enum "Transmission Status IRIS";
        SubmissionStatusText: Text;
        CorrectionsApplied: Boolean;
    begin
        if Transmission."Receipt ID" = '' then
            exit;
        if (TransmissionLog."Line ID" = 0) or (TransmissionLog."Receipt ID" <> Transmission."Receipt ID") then
            exit;
        if (TransmissionLog."Transmission Document ID" <> Transmission."Document ID") or
           (TransmissionLog."Transmission Type" <> Enum::"Transmission Type IRIS"::C)
        then
            exit;
        TransmissionLogLine.SetRange("Transmission Log ID", TransmissionLog."Line ID");
        if not TransmissionLogLine.FindSet() then
            exit;
        IRS1099FormDocHeader.LockTable();
        repeat
            // Only acceptance in this acknowledgment can complete a correction, not an earlier accepted status.
            if not SubmissionsStatus.Get(TransmissionLogLine."Submission ID", SubmissionStatusText) then
                continue;
            if not Evaluate(SubmissionStatus, SubmissionStatusText) then
                continue;
            if SubmissionStatus <> Enum::"Transmission Status IRIS"::Accepted then
                continue;
            if not IRS1099FormDocHeader.Get(TransmissionLogLine."IRS 1099 Form Document ID") then
                continue;
            if not IRS1099FormDocHeader."IRIS Needs Correction" or
               (IRS1099FormDocHeader."IRIS Last Receipt ID" <> Transmission."Receipt ID") or
               IRS1099FormDocHeader."IRIS Updated Not Sent" or
               (IRS1099FormDocHeader.Status = IRS1099FormDocHeader.Status::Open)
            then
                continue;
            IRS1099FormDocHeader."IRIS Corrected" := true;
            IRS1099FormDocHeader."IRIS Needs Correction" := false;
            if TransmissionLogLine."Correction to Zeros" then
                IRS1099FormDocHeader."IRIS Corrected to Zeros" := true;
            IRS1099FormDocHeader.Modify(true);
            CorrectionsApplied := true;
            if TransmissionLogLine."Correction to Zeros" then
                IRS1099FormDocument.Abandon(IRS1099FormDocHeader);
        until TransmissionLogLine.Next() = 0;
        if CorrectionsApplied then
            FeatureTelemetry.LogUsage('', Helper.GetIRISFeatureName(), CorrectionsAppliedTok);
    end;

    local procedure SetSubmissionInProgress(var Transmission: Record "Transmission IRIS"; TransmissionType: Enum "Transmission Type IRIS"; var TempDocHeader: Record "IRS 1099 Form Doc. Header" temporary; ReceiptID: Text[100])
    begin
        SetDocumentsInProgress(TempDocHeader);
        Transmission."Last Type" := TransmissionType;
        Transmission.Status := Transmission.Status::Processing;
        Transmission."Receipt ID Assigned Manually" := false;
        Transmission."Receipt ID" := ReceiptID;
        Transmission.Modify(true);
    end;

    local procedure SetDocumentsInProgress(var TempDocHeader: Record "IRS 1099 Form Doc. Header" temporary)
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
    begin
        TempDocHeader.Reset();
        if TempDocHeader.FindSet() then
            repeat
                IRS1099FormDocHeader.Get(TempDocHeader.ID);
                IRS1099FormDocHeader."IRIS Updated Not Sent" := false;
                if IRS1099FormDocHeader.Status = Enum::"IRS 1099 Form Doc. Status"::Released then
                    IRS1099FormDocHeader.Status := Enum::"IRS 1099 Form Doc. Status"::"In Progress";
                IRS1099FormDocHeader.Modify(true);
            until TempDocHeader.Next() = 0;
    end;

    #endregion

    #region Sandbox Transmission Removal
    internal procedure RemoveSandboxTransmission(var Transmission: Record "Transmission IRIS"; DeleteDocuments: Boolean): Boolean
    var
        TempDocHeader: Record "IRS 1099 Form Doc. Header" temporary;
        Snapshot: Dictionary of [Text, BigInteger];
        Question: Text;
        HistoryCount: Integer;
        SelectedSystemId: Guid;
    begin
        if not EnvironmentInformation.IsSandbox() or
           (Transmission.CurrentCompany() <> CompanyName()) or Transmission.IsTemporary()
        then
            Error(SandboxRemovalOnlyErr);

        SelectedSystemId := Transmission.SystemId;
        if not Transmission.Get(Transmission."Document ID") then
            Error(SandboxRemovalChangedErr);
        if Transmission.SystemId <> SelectedSystemId then
            Error(SandboxRemovalChangedErr);
        CollectSandboxRemovalRecords(Transmission, TempDocHeader, Snapshot, HistoryCount);
        if DeleteDocuments then
            Question := DeleteSandboxTransmissionQst
        else
            Question := ResetSandboxTransmissionQst;
        if not ConfirmMgt.GetResponseOrDefault(
             StrSubstNo(Question, Transmission."Document ID", Transmission."Period No.", TempDocHeader.Count(), HistoryCount), false)
        then
            exit(false);

        ApplySandboxRemoval(Transmission, DeleteDocuments, Snapshot);
        exit(true);
    end;

    local procedure CollectSandboxRemovalRecords(Transmission: Record "Transmission IRIS"; var TempDocHeader: Record "IRS 1099 Form Doc. Header" temporary; var Snapshot: Dictionary of [Text, BigInteger]; var HistoryCount: Integer)
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        TransmissionLog: Record "Transmission Log IRIS";
        TransmissionLogLine: Record "Transmission Log Line IRIS";
        ErrorInformation: Record "Error Information IRIS";
    begin
        Snapshot.Add(Format(Transmission.RecordId()), Transmission.SystemRowVersion);
        DocHeader.SetRange("IRIS Transmission Document ID", Transmission."Document ID");
        if DocHeader.FindSet() then
            repeat
                AddSandboxRemovalDocHeader(Transmission, DocHeader, TempDocHeader, Snapshot);
            until DocHeader.Next() = 0;

        TransmissionLog.SetRange("Transmission Document ID", Transmission."Document ID");
        HistoryCount := TransmissionLog.Count();
        if TransmissionLog.FindSet() then
            repeat
                Snapshot.Add(Format(TransmissionLog.RecordId()), TransmissionLog.SystemRowVersion);
                TransmissionLogLine.SetRange("Transmission Log ID", TransmissionLog."Line ID");
                if TransmissionLogLine.FindSet() then
                    repeat
                        Snapshot.Add(Format(TransmissionLogLine.RecordId()), TransmissionLogLine.SystemRowVersion);
                        if DocHeader.Get(TransmissionLogLine."IRS 1099 Form Document ID") then
                            AddSandboxRemovalDocHeader(Transmission, DocHeader, TempDocHeader, Snapshot);
                    until TransmissionLogLine.Next() = 0;
            until TransmissionLog.Next() = 0;

        ErrorInformation.SetRange("Transmission Document ID", Transmission."Document ID");
        if ErrorInformation.FindSet() then
            repeat
                Snapshot.Add(Format(ErrorInformation.RecordId()), ErrorInformation.SystemRowVersion);
            until ErrorInformation.Next() = 0;
    end;

    local procedure AddSandboxRemovalDocHeader(Transmission: Record "Transmission IRIS"; DocHeader: Record "IRS 1099 Form Doc. Header"; var TempDocHeader: Record "IRS 1099 Form Doc. Header" temporary; var Snapshot: Dictionary of [Text, BigInteger])
    begin
        if (DocHeader."Period No." <> Transmission."Period No.") or
           not (DocHeader."IRIS Transmission Document ID" in [0, Transmission."Document ID"])
        then
            Error(SandboxRemovalConflictErr, DocHeader.ID);
        if TempDocHeader.Get(DocHeader.ID) then
            exit;
        TempDocHeader := DocHeader;
        TempDocHeader.Insert();
        Snapshot.Add(Format(DocHeader.RecordId()), DocHeader.SystemRowVersion);
    end;

    [CommitBehavior(CommitBehavior::Error)]
    local procedure ApplySandboxRemoval(var Transmission: Record "Transmission IRIS"; DeleteDocuments: Boolean; ConfirmedSnapshot: Dictionary of [Text, BigInteger])
    var
        TempDocHeader: Record "IRS 1099 Form Doc. Header" temporary;
        DocHeader: Record "IRS 1099 Form Doc. Header";
        TransmissionLog: Record "Transmission Log IRIS";
        TransmissionLogLine: Record "Transmission Log Line IRIS";
        ErrorInformation: Record "Error Information IRIS";
        CurrentSnapshot: Dictionary of [Text, BigInteger];
        RecordKey: Text;
        HistoryCount: Integer;
    begin
        Transmission.LockTable();
        DocHeader.LockTable();
        TransmissionLog.LockTable();
        TransmissionLogLine.LockTable();
        ErrorInformation.LockTable();
        if not Transmission.Get(Transmission."Document ID") then
            Error(SandboxRemovalChangedErr);
        CollectSandboxRemovalRecords(Transmission, TempDocHeader, CurrentSnapshot, HistoryCount);
        if CurrentSnapshot.Count() <> ConfirmedSnapshot.Count() then
            Error(SandboxRemovalChangedErr);
        foreach RecordKey in ConfirmedSnapshot.Keys() do begin
            if not CurrentSnapshot.ContainsKey(RecordKey) then
                Error(SandboxRemovalChangedErr);
            if CurrentSnapshot.Get(RecordKey) <> ConfirmedSnapshot.Get(RecordKey) then
                Error(SandboxRemovalChangedErr);
        end;

        if TempDocHeader.FindSet() then
            repeat
                DocHeader.Get(TempDocHeader.ID);
                DocHeader."IRIS Transmission Document ID" := 0;
                DocHeader."IRIS Submission ID" := '';
                DocHeader."IRIS Record ID" := '';
                DocHeader."IRIS Last Receipt ID" := '';
                DocHeader."IRIS Last Accepted Receipt ID" := '';
                DocHeader."IRIS Submission Status" := DocHeader."IRIS Submission Status"::None;
                DocHeader."IRIS Needs Correction" := false;
                DocHeader."IRIS Updated Not Sent" := false;
                DocHeader."IRIS Corrected" := false;
                DocHeader."IRIS Corrected to Zeros" := false;
                DocHeader."Allow Correction" := false;
                if DeleteDocuments or (DocHeader.Status <> DocHeader.Status::Abandoned) then
                    DocHeader.Status := DocHeader.Status::Open;
                DocHeader.Modify(true);
                if DeleteDocuments then
                    DocHeader.Delete(true);
            until TempDocHeader.Next() = 0;

        TransmissionLog.SetRange("Transmission Document ID", Transmission."Document ID");
        if TransmissionLog.FindSet() then
            repeat
                TransmissionLogLine.SetRange("Transmission Log ID", TransmissionLog."Line ID");
                TransmissionLogLine.DeleteAll(true);
            until TransmissionLog.Next() = 0;
        TransmissionLog.DeleteAll(true);
        ErrorInformation.SetRange("Transmission Document ID", Transmission."Document ID");
        ErrorInformation.DeleteAll(true);
        Transmission.Status := Transmission.Status::None;
        Transmission.Modify(true);
        Transmission.Delete(true);
    end;

    #endregion
}