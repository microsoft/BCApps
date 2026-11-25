// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using System.Environment;
using System.Privacy;
using System.Telemetry;
using System.Utilities;

page 10058 "Transmission IRIS"
{
    PageType = Card;
    InsertAllowed = false;
    Caption = 'IRIS Transmission';
    ApplicationArea = BasicCA, BasicUS;
    SourceTable = "Transmission IRIS";
    Permissions = tabledata "User Params IRIS" = M;

    layout
    {
        area(Content)
        {
            group(General)
            {
                ShowCaption = false;

                field(TestModeIndicator; DestinationText)
                {
                    Caption = 'Destination';
                    Editable = false;
                    ToolTip = 'Specifies whether submissions are sent to the IRS Test (ATS) or Production environment.';

                    trigger OnDrillDown()
                    begin
                        if KeyVaultClientIRIS.TestMode() then
                            Message(TestModeMsg)
                        else
                            Message(ProductionModeMsg);
                    end;
                }
                field(SubmissionEndpointURL; SubmissionEndpointURL)
                {
                    Caption = 'Submission Endpoint URL';
                    Editable = false;
                    Visible = false;
                    ToolTip = 'Specifies the current API endpoint URL used to submit data to the IRS.';
                }
                field("Period No."; Rec."Period No.")
                {
                }
                field(Status; Rec.Status)
                {
                    StyleExpr = StatusStyle;

                    trigger OnValidate()
                    begin
                        SetStatusStyle();
                        SetActionsVisibility();
                    end;
                }
                field("Receipt ID"; Rec."Receipt ID")
                {
                    Editable = false;
                }
                group(ErrorInfo)
                {
                    ShowCaption = false;
                    Visible = ErrorInfoVisible;

                    field("Error Information"; ErrorInfoCaption)
                    {
                        ShowCaption = false;
                        Editable = false;
                        StyleExpr = 'Attention';

                        trigger OnDrillDown()
                        begin
                            ProcessTransmission.ShowErrorInformation(Rec."Document ID", '', '');
                        end;
                    }
                }
            }
            part(IRS1099Documents; "Transmission IRIS Subform")
            {
                SubPageLink = "IRIS Transmission Document ID" = field("Document ID");
                UpdatePropagation = Both;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RemoveTransmissionAndResetDocuments)
            {
                Caption = 'Remove Transmission and Reset Documents';
                Image = ResetStatus;
                ToolTip = 'Remove this transmission and its local history in a sandbox. Keep document contents and PDFs, clear filing state, and open non-abandoned documents. This does not cancel IRS/ATS submissions.';
                Visible = SandboxRemovalVisible;

                trigger OnAction()
                begin
                    if ProcessTransmission.RemoveSandboxTransmission(Rec, false) then
                        CurrPage.Close();
                end;
            }
            action(RemoveTransmissionAndDocuments)
            {
                Caption = 'Remove Transmission and Documents';
                Image = Delete;
                ToolTip = 'Remove this transmission, its local history, and its associated documents and PDFs in a sandbox. This does not cancel IRS/ATS submissions.';
                Visible = SandboxRemovalVisible;

                trigger OnAction()
                begin
                    if ProcessTransmission.RemoveSandboxTransmission(Rec, true) then
                        CurrPage.Close();
                end;
            }
            action(UpdateTransmission)
            {
                Caption = 'Update Transmission';
                Image = Recalculate;
                ToolTip = 'Recalculate the amounts of the related 1099 form documents and create new documents if necessary. Use this action if the amounts on the 1099 forms have been updated or new 1099 form documents have been created after the transmission was generated.';

                trigger OnAction()
                begin
                    ProcessTransmission.Update(Rec);
                end;
            }
            action(SendOriginal)
            {
                Caption = 'Send';
                Image = SendElectronicDocument;
                ToolTip = 'Send the transmission to the IRS.';
                Visible = SendOriginalActionVisible;

                trigger OnAction()
                var
                    UserParams: Record "User Params IRIS";
                    CustomerConsentMgt: Codeunit "Customer Consent Mgt.";
                    ProcessDialog: Dialog;
                begin
                    if not ConfirmSendTransmission("Transmission Type IRIS"::O) then
                        exit;

                    UserParams.GetRecord();
                    if not UserParams."Privacy Consent Given" then begin
                        Commit();
                        if not CustomerConsentMgt.ConfirmCustomConsent(SendOrigTransmConsentTxt) then
                            exit;

                        UserParams."Privacy Consent Given" := true;
                        UserParams.Modify();
                    end;

                    ProcessDialog.Open(SendingTransmissionMsg);
                    ProcessTransmission.SendOriginal(Rec);
                    ProcessDialog.Close();
                end;
            }
            action(SendReplacement)
            {
                Caption = 'Send Replacement';
                Image = SendElectronicDocument;
                ToolTip = 'Send the replacement transmission to the IRS. Use this action when the previously sent transmission was rejected or partially accepted.';
                Visible = SendReplacementActionVisible;

                trigger OnAction()
                var
                    ProcessDialog: Dialog;
                begin
                    if not ConfirmSendTransmission("Transmission Type IRIS"::R) then
                        exit;

                    ProcessDialog.Open(SendingReplacementMsg);
                    ProcessTransmission.SendReplacement(Rec);
                    ProcessDialog.Close();
                end;
            }
            action(SendCorrection)
            {
                Caption = 'Send Correction';
                Image = SendElectronicDocument;
                ToolTip = 'Send the correction transmission to the IRS. Only lines marked with the "Needs Correction" flag will be sent. Use this action when the previously sent form had incorrect vendor name, TIN, or payment amounts.';
                Visible = SendCorrectionActionVisible;

                trigger OnAction()
                var
                    ProcessDialog: Dialog;
                begin
                    if not ConfirmSendTransmission("Transmission Type IRIS"::C) then
                        exit;

                    ProcessDialog.Open(SendingCorrectionMsg);
                    ProcessTransmission.SendCorrection(Rec, false);
                    ProcessDialog.Close();
                end;
            }
            action(SendCorrectionToZero)
            {
                Caption = 'Send Zero Amounts Correction';
                Image = SendElectronicDocument;
                ToolTip = 'Send the correction transmission with zero amounts to the IRS. Only lines marked with the "Needs Correction" flag will be sent. Use this action when the previously sent form should not have been filed for the vendor.';
                Visible = SendCorrectionActionVisible;

                trigger OnAction()
                var
                    ProcessDialog: Dialog;
                begin
                    if not ConfirmSendTransmission("Transmission Type IRIS"::C) then
                        exit;

                    ProcessDialog.Open(SendingCorrectionMsg);
                    ProcessTransmission.SendCorrection(Rec, true);
                    ProcessDialog.Close();
                end;
            }
            group(TwoStepCorrection)
            {
                Caption = 'Two-Step Correction';

                action(Step1CorrectionToZero)
                {
                    Caption = 'Step 1: Send Zero Amounts Correction';
                    Image = SendElectronicDocument;
                    ToolTip = 'Send the correction transmission with zero amounts to the IRS. *All* lines, except opened and abandoned, will be sent.';
                    Visible = SendCorrectionActionVisible;

                    trigger OnAction()
                    var
                        ProcessDialog: Dialog;
                    begin
                        if not ConfirmSendTransmission("Transmission Type IRIS"::C) then
                            exit;

                        ProcessDialog.Open(SendingCorrectionMsg);

                        ProcessTransmission.SendTwoStepZeroCorrection(Rec);

                        ProcessDialog.Close();

                        Message(FirstStepCompletedMsg);
                    end;
                }
                action(Step2SendCorrectedOriginal)
                {
                    Caption = 'Step 2: Send Corrected';
                    Image = SendElectronicDocument;
                    ToolTip = 'Send the transmission with the corrected form types to the IRS as an original transmission. *All* lines, except opened and abandoned, will be sent.';
                    Visible = SendCorrectionActionVisible;

                    trigger OnAction()
                    var
                        ProcessDialog: Dialog;
                    begin
                        if not ConfirmSendTransmission("Transmission Type IRIS"::O) then
                            exit;

                        ProcessDialog.Open(SendingTransmissionMsg);
                        ProcessTransmission.SendOriginal(Rec);
                        ProcessDialog.Close();
                    end;
                }
                action(TwoStepCorrectionHelp)
                {
                    Caption = 'Help';
                    Image = Help;
                    ToolTip = 'Learn more about the two-step correction process.';
                    Visible = SendCorrectionActionVisible;

                    trigger OnAction()
                    begin
                        Message(TwoStepCorrectionHelpMsg);
                    end;
                }
            }
            action(RequestTransmissionStatusByRID)
            {
                Caption = 'Request Status';
                Image = Status;
                ToolTip = 'Request the status of the transmission from the IRS using Receipt ID. Use this action if the transmission was sent and the status was not updated or when the status is Processing. This action requires a Receipt ID to be assigned to the transmission.';

                trigger OnAction()
                var
                    TransmissionLog: Record "Transmission Log IRIS";
                    ProcessDialog: Dialog;
                    UniqueTransmissionId: Text[100];
                begin
                    if Rec."Receipt ID" = '' then
                        Error(ReceiptIDNotAssignedErr);

                    ProcessDialog.Open(RequestingStatusMsg);

                    if TransmissionLog.FindLastRecByReceiptID(Rec."Receipt ID") then
                        UniqueTransmissionId := TransmissionLog."Unique Transmission ID"
                    else begin
                        TransmissionLog.Reset();
                        TransmissionLog.SetRange("Transmission Document ID", Rec."Document ID");
                        if TransmissionLog.FindLast() then
                            UniqueTransmissionId := TransmissionLog."Unique Transmission ID";
                    end;

                    ProcessTransmission.RequestAcknowledgementAndUpdateTransmission(Rec, Rec."Receipt ID", UniqueTransmissionId);

                    Sleep(500);
                    ProcessDialog.Close();
                end;
            }
            action(RequestTransmissionStatusByUTID)
            {
                Caption = 'Request Status by UTID';
                Image = Status;
                ToolTip = 'Request the status of the transmission from the IRS using Unique Transmission ID. Use this action when the Receipt ID is not available, for example, when a pre-receipt validation error (such as XML Schema Validation Error) was returned and the Receipt ID was not saved to the transmission record.';

                trigger OnAction()
                var
                    TransmissionLog: Record "Transmission Log IRIS";
                    ProcessDialog: Dialog;
                    UniqueTransmissionId: Text[100];
                begin
                    ProcessDialog.Open(RequestingStatusMsg);

                    TransmissionLog.SetRange("Transmission Document ID", Rec."Document ID");
                    if not TransmissionLog.FindLast() then
                        Error(UTIDNotFoundErr);
                    UniqueTransmissionId := TransmissionLog."Unique Transmission ID";

                    ProcessTransmission.RequestAcknowledgementAndUpdateTransmission(Rec, '', UniqueTransmissionId);

                    Sleep(500);
                    ProcessDialog.Close();
                end;
            }
            action(TransmissionHistory)
            {
                Caption = 'Transmission History';
                Image = Log;
                ToolTip = 'Show IRIS transmissions history.';
                RunObject = Page "Transmission Logs IRIS";
                RunPageLink = "Period No." = field("Period No.");
            }
            action(AssignReceiptIDManually)
            {
                Caption = 'Assign Receipt ID';
                Image = DocumentEdit;
                ToolTip = 'Assign the Receipt ID to the transmission manually. If the the Receipt ID was not received for some reason (e.g., the session times out or is terminated) or it is accidentally lost or deleted, request the Receipt ID from the IRIS help desk. You will be required to identify yourself and provide the unique transmission ID which can be found on Transmission History page.';

                trigger OnAction()
                var
                    TransmissionUpdate: Page "Transmission IRIS Update";
                begin
                    if not ConfirmMgt.GetResponseOrDefault(ConfirmAssignReceiptIDQst, false) then
                        exit;

                    if Rec."Receipt ID" <> '' then
                        if not ConfirmMgt.GetResponseOrDefault(OverwriteReceiptIDQst, false) then
                            exit;

                    TransmissionUpdate.LookupMode(true);
                    TransmissionUpdate.SetRec(Rec);
                    TransmissionUpdate.RunModal();
                end;
            }
            action(ClearTokens)
            {
                Caption = 'Clear OAuth Tokens';
                ToolTip = 'Remove all OAuth tokens from the user storage. Use this action if you receive the error 401 Unauthorized when trying to send the transmission.';
                Image = Delete;
                Visible = false;

                trigger OnAction()
                var
                    OAuthClient: Codeunit "OAuth Client IRIS";
                begin
                    OAuthClient.ClearTokens();
                    Message(TokensRemovedMsg);
                end;
            }
            action(ShowCorrectionActions)
            {
                Caption = 'Show Correction Actions';
                ToolTip = 'Force show correction actions regardless of the transmission status. Use this action for troubleshooting when the correction actions are hidden but should be available.';
                Image = AddAction;
                Visible = false;

                trigger OnAction()
                begin
                    if not ConfirmMgt.GetResponseOrDefault(ShowCorrectionActionsQst, false) then
                        exit;

                    FeatureTelemetry.LogUsage('0000RNZ', Helper.GetIRISFeatureName(), ForceCorrectionActionsEventTxt);
                    ForceCorrectionActionsVisible := true;
                    SetActionsVisibility();
                end;
            }
        }
        area(Promoted)
        {
            actionref(SendOriginal_Promoted; SendOriginal)
            {
            }
            actionref(SendReplacement_Promoted; SendReplacement)
            {
            }
            actionref(SendCorrection_Promoted; SendCorrection)
            {
            }
            actionref(SendCorrectionToZero_Promoted; SendCorrectionToZero)
            {
            }
            actionref(TransmissionLog_Promoted; TransmissionHistory)
            {
            }
            actionref(RequestTransmissionStatus_Promoted; RequestTransmissionStatusByRID)
            {
            }
        }
    }

    trigger OnOpenPage()
    begin
        SetDestinationFields();
    end;

    trigger OnAfterGetRecord()
    begin
        SetErrorInfoField();
        SetStatusStyle();
        SetActionsVisibility();
    end;

    var
        ProcessTransmission: Codeunit "Process Transmission IRIS";
        ConfirmMgt: Codeunit "Confirm Management";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        Helper: Codeunit "Helper IRIS";
        KeyVaultClientIRIS: Codeunit "Key Vault Client IRIS";
        EnvironmentInformation: Codeunit "Environment Information";
        StatusStyle: Text;
        ErrorInfoCaption: Text;
        DestinationText: Text;
        SubmissionEndpointURL: Text;
        ErrorInfoVisible: Boolean;
        SendOriginalActionVisible: Boolean;
        SendReplacementActionVisible: Boolean;
        SendCorrectionActionVisible: Boolean;
        ForceCorrectionActionsVisible: Boolean;
        SandboxRemovalVisible: Boolean;
        SendTransmissionQst: Label 'Send the transmission for tax year %1 to IRS %2?\\%3', Comment = '%1 - tax year, %2 - destination (Test or Production), %3 - destination explanation';
        SendReplacementTransmissionQst: Label 'Send the replacement transmission for tax year %1 to IRS %2?\\%3', Comment = '%1 - tax year, %2 - destination (Test or Production), %3 - destination explanation';
        SendCorrectionTransmissionQst: Label 'Send the correction transmission for tax year %1 to IRS %2?\\%3', Comment = '%1 - tax year, %2 - destination (Test or Production), %3 - destination explanation';
        SendingTransmissionMsg: Label 'Sending transmission to the IRS...';
        SendingReplacementMsg: Label 'Sending replacement transmission to the IRS...';
        SendingCorrectionMsg: Label 'Sending correction transmission to the IRS...';
        RequestingStatusMsg: Label 'Requesting transmission status...';
        TokensRemovedMsg: Label 'The IRIS auth tokens were removed from the user storage.';
        ShowCorrectionActionsQst: Label 'The standard correction conditions are not met. Do you want to force show the correction actions for troubleshooting purposes?';
        ForceCorrectionActionsEventTxt: Label 'ForceCorrectionActionsEnabled', Locked = true;
        TwoStepCorrectionHelpMsg: Label 'Use the two-step correction process if incorrect form type was previously filed, e.g., 1099-MISC instead of 1099-NEC. \\Step 1: Submit zero amounts correction. \Step 2.1: After the transmission is accepted, use the action Update Transmission to add the corrected 1099 form documents. \Step 2.2: Send the updated transmission to the IRS.';
        FirstStepCompletedMsg: Label 'The correction transmission with zero amounts was sent to the IRS. After the transmission is accepted, use the action Update Transmission to add the corrected 1099 form documents and then send the updated transmission to the IRS.';
        ConfirmAssignReceiptIDQst: Label 'Are you sure you want to assign the Receipt ID to the transmission manually?';
        OverwriteReceiptIDQst: Label 'The transmission already has a Receipt ID. Do you want to overwrite it?';
        SendOrigTransmConsentTxt: Label 'By choosing this action, you consent to use third party systems. These systems may have their own terms of use, license, pricing and privacy, and they may not meet the same compliance and security standards as Microsoft Dynamics 365 Business Central. Your privacy is important to us.';
        ReceiptIDNotAssignedErr: Label 'The Receipt ID is not assigned to the transmission.\\ Possible reasons:\- Pre-receipt validation error (e.g., XML Schema Validation Error) - use Request Status by UTID action.\- Receipt ID was lost or not received - contact IRIS help desk, provide them Unique Transmission ID from Transmission History, then use Assign Receipt ID action to set it and Request Status action to update the status.';
        UTIDNotFoundErr: Label 'Unable to get Unique Transmission Id from the transmission history, because it does not have any records for the current transmission.';
        TestModeMsg: Label 'Data is sent to the IRIS Assurance Testing System (ATS) for testing, not as a production filing.';
        ProductionModeMsg: Label 'Data is sent to IRS Production as a live submission.';
        ErrorInfoCaptionTxt: Label 'Show %1 error(s)', Comment = '%1 - number of errors';

    local procedure SetDestinationFields()
    begin
        DestinationText := Helper.GetDestinationName(KeyVaultClientIRIS.TestMode());
        if not KeyVaultClientIRIS.TryGetSubmitEndpointURL(SubmissionEndpointURL) then
            Clear(SubmissionEndpointURL);
    end;

    local procedure ConfirmSendTransmission(TransmissionType: Enum "Transmission Type IRIS"): Boolean
    var
        IsTestDestination: Boolean;
        DestinationName: Text;
        Explanation: Text;
        Question: Text;
    begin
        IsTestDestination := KeyVaultClientIRIS.TestMode();
        DestinationName := Helper.GetDestinationName(IsTestDestination);
        if IsTestDestination then
            Explanation := TestModeMsg
        else
            Explanation := ProductionModeMsg;
        case TransmissionType of
            TransmissionType::O:
                Question := StrSubstNo(SendTransmissionQst, Rec."Period No.", DestinationName, Explanation);
            TransmissionType::R:
                Question := StrSubstNo(SendReplacementTransmissionQst, Rec."Period No.", DestinationName, Explanation);
            TransmissionType::C:
                Question := StrSubstNo(SendCorrectionTransmissionQst, Rec."Period No.", DestinationName, Explanation);
        end;
        exit(ConfirmMgt.GetResponseOrDefault(Question, false));
    end;

    local procedure SetActionsVisibility()
    begin
        SandboxRemovalVisible := EnvironmentInformation.IsSandbox();
        SendOriginalActionVisible := ProcessTransmission.IsSendOriginalAllowed(Rec);
        SendReplacementActionVisible := ProcessTransmission.IsSendReplacementAllowed(Rec);
        SendCorrectionActionVisible := ProcessTransmission.IsSendCorrectionAllowed(Rec) or ForceCorrectionActionsVisible;
    end;

    local procedure SetErrorInfoField()
    var
        ErrorInformation: Record "Error Information IRIS";
        ErrorsCount: Integer;
    begin
        ErrorInformation.SetRange("Transmission Document ID", Rec."Document ID");
        ErrorsCount := ErrorInformation.Count();
        ErrorInfoVisible := ErrorsCount > 0;
        ErrorInfoCaption := StrSubstNo(ErrorInfoCaptionTxt, ErrorsCount);
    end;

    local procedure SetStatusStyle()
    begin
        StatusStyle := '';
        case Rec.Status of
            Enum::"Transmission Status IRIS"::Accepted:
                StatusStyle := 'Favorable';
            Enum::"Transmission Status IRIS"::Rejected,
            Enum::"Transmission Status IRIS"::"Not Found":
                StatusStyle := 'Unfavorable';
            Enum::"Transmission Status IRIS"::"Partially Accepted",
            Enum::"Transmission Status IRIS"::"Accepted with Errors":
                StatusStyle := 'Attention';
        end;
    end;
}