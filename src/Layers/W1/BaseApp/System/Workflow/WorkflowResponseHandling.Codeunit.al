namespace System.Automation;

using Microsoft.EServices.EDocument;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.FixedAssets.Journal;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Requisition;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Posting;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.Posting;
using System.Environment.Configuration;
using System.Threading;

codeunit 1521 "Workflow Response Handling"
{
    Permissions = TableData "Sales Header" = rm,
                  TableData "Purchase Header" = rm,
                  TableData "Notification Entry" = rimd,
                  tabledata "Workflow Response" = r;

    trigger OnRun()
    begin
    end;

    var
#pragma warning disable AA0470
        NotSupportedResponseErr: Label 'Response %1 is not supported in the workflow.';
        CreateNotifEntryTxt: Label 'Create a notification for %1.', Comment = 'Create a notification for NAVUser.';
        CreatePmtLineAsyncTxt: Label 'Create a payment journal line in the background for journal template %1 and journal batch %2.', Comment = 'Create a payment journal line in the background for journal template GENERAL and journal batch DEFAULT.';
        CreatePmtLineTxt: Label 'Create a payment journal line for journal template %1 and journal batch %2.', Comment = 'Create a payment journal line for journal template GENERAL and journal batch DEFAULT.';
#pragma warning restore AA0470
        DoNothingTxt: Label 'Do nothing.';
#pragma warning disable AA0470
        CreateApprovalRequestsTxt: Label 'Create an approval request for the record using approver type %1 and %2.', Comment = 'Create an approval request for the record using approver type Approver and approver limit type Direct Approver.';
#pragma warning restore AA0470
        CreateApprovalWorkflowGroupTxt: Label 'workflow user group code %1', Comment = '%1 = Workflow user group code';
        CreateApprovalApprovalLimitTxt: Label 'approver limit type %1', Comment = '%1 = Approval limit type';
        GetApprovalCommentTxt: Label 'Open Approval Comments page.';
        OpenDocumentTxt: Label 'Reopen the document.';
        ReleaseDocumentTxt: Label 'Release the document.';
        SendApprReqForApprovalTxt: Label 'Send approval request for the record and create a notification.';
        ApproveAllApprReqTxt: Label 'Approve the approval request for the record.';
        RejectAllApprReqTxt: Label 'Reject the approval request for the record and create a notification.';
        CancelAllAppReqTxt: Label 'Cancel the approval request for the record and create a notification.';
        PostDocumentTxt: Label 'Post the sales or purchase document.';
        BackgroundDocumentPostTxt: Label 'Post the sales or purchase document in the background.';
        BackgroundOCRReceiveIncomingDocTxt: Label 'Receive the incoming document from OCR in the background.';
        BackgroundOCRSendIncomingDocTxt: Label 'Send the incoming document to OCR in the background.';
        CheckCustomerCreditLimitTxt: Label 'Check if the customer credit limit is exceeded.';
        CheckGeneralJournalBatchBalanceTxt: Label 'Check if the general journal batch is balanced.';
        CreateApproveApprovalRequestAutomaticallyTxt: Label 'Create and approve an approval request automatically.';
        SetStatusToPendingApprovalTxt: Label 'Set document status to Pending Approval.';
        UserIDTok: Label '<User>';
        TemplateTok: Label '<Template>';
        GenJnlBatchTok: Label '<Batch>';
#pragma warning disable AA0470
        UnsupportedRecordTypeErr: Label 'Record type %1 is not supported by this workflow response.', Comment = 'Record type Customer is not supported by this workflow response.';
#pragma warning restore AA0470
        CreateOverdueNotifTxt: Label 'Create notification for overdue approval requests.';
#pragma warning disable AA0470
        ResponseAlreadyExistErr: Label 'A response with description %1 already exists.';
#pragma warning restore AA0470
        ApproverTypeTok: Label '<Approver Type>';
        ApproverLimitTypeTok: Label '<Approver Limit Type>';
        WorkflowUserGroupTok: Label '<Workflow User Group Code>';
        ShowMessageTxt: Label 'Show message "%1".', Comment = '%1 = The message to be shown';
        ShowMessagePlaceholderMsg: Label '%1', Locked = true;
        MessageTok: Label '<Message>';
        RestrictRecordUsageTxt: Label 'Add record restriction.';
        AllowRecordUsageTxt: Label 'Remove record restriction.';
#pragma warning disable AA0470
        RestrictUsageDetailsTxt: Label 'The restriction was imposed by the %1 workflow, %2.', Comment = 'The restriction was imposed by the PIW workflow, Purchase Invoice Workflow.';
#pragma warning restore AA0470
        MarkReadyForOCRTxt: Label 'Mark the incoming document ready for OCR.';
        SendToOCRTxt: Label 'Send the incoming document to OCR.';
        ReceiveFromOCRTxt: Label 'Receive the incoming document from OCR.';
        CreateDocFromIncomingDocTxt: Label 'Create a purchase document from an incoming document.';
        CreateReleasedDocFromIncomingDocTxt: Label 'Create a released purchase document from an incoming document.';
        CreateJournalFromIncomingDocTxt: Label 'Create journal line from incoming document.';
#pragma warning disable AA0470
        RevertRecordValueTxt: Label 'Revert the value of the %1 field on the record and save the change.', Comment = 'Revert the value of the Credit Limit (LCY) field on the record and save the change.';
#pragma warning restore AA0470
        RevertRecordFieldValueTok: Label '<Field>';
        ApplyNewValuesTxt: Label 'Apply the new values.';
        DiscardNewValuesTxt: Label 'Discard the new values.';
        EnableJobQueueEntryResponseDescTxt: Label 'Enable the job queue entry.';
        // Telemetry strings
        WorkflowResponseStartTelemetryTxt: Label 'Workflow response: Start Scope', Locked = true;
        WorkflowResponseEndTelemetryTxt: Label 'Workflow response: End Scope', Locked = true;
        WorkflowResponseNotFoundTelemetryTxt: Label 'Workflow response not found', Locked = true;

    procedure CreateResponsesLibrary()
    begin
        AddResponseToLibrary(DoNothingCode(), 0, DoNothingTxt, 'GROUP 0');
        AddResponseToLibrary(CreateNotificationEntryCode(), 0, CreateNotifEntryTxt, 'GROUP 3');
        AddResponseToLibrary(ReleaseDocumentCode(), 0, ReleaseDocumentTxt, 'GROUP 0');
        AddResponseToLibrary(OpenDocumentCode(), 0, OpenDocumentTxt, 'GROUP 0');
        AddResponseToLibrary(SetStatusToPendingApprovalCode(), 0, SetStatusToPendingApprovalTxt, 'GROUP 0');
        AddResponseToLibrary(GetApprovalCommentCode(), 0, GetApprovalCommentTxt, 'GROUP 0');
        AddResponseToLibrary(CreateApprovalRequestsCode(), 0, CreateApprovalRequestsTxt, 'GROUP 5');
        AddResponseToLibrary(SendApprovalRequestForApprovalCode(), 0, SendApprReqForApprovalTxt, 'GROUP 2');
        AddResponseToLibrary(ApproveAllApprovalRequestsCode(), 0, ApproveAllApprReqTxt, 'GROUP 0');
        AddResponseToLibrary(RejectAllApprovalRequestsCode(), 0, RejectAllApprReqTxt, 'GROUP 2');
        AddResponseToLibrary(CancelAllApprovalRequestsCode(), 0, CancelAllAppReqTxt, 'GROUP 2');
        AddResponseToLibrary(PostDocumentCode(), 0, PostDocumentTxt, 'GROUP 0');
        AddResponseToLibrary(PostDocumentAsyncCode(), 0, BackgroundDocumentPostTxt, 'GROUP 0');

        AddResponseToLibrary(CreatePmtLineForPostedPurchaseDocAsyncCode(), Database::"Purch. Inv. Header", CreatePmtLineAsyncTxt, 'GROUP 1');
        AddResponseToLibrary(CreatePmtLineForPostedPurchaseDocCode(), Database::"Purch. Inv. Header", CreatePmtLineTxt, 'GROUP 1');

        AddResponseToLibrary(CreateOverdueNotificationCode(), 0, CreateOverdueNotifTxt, 'GROUP 2');
        AddResponseToLibrary(CheckCustomerCreditLimitCode(), 0, CheckCustomerCreditLimitTxt, 'GROUP 0');
        AddResponseToLibrary(CheckGeneralJournalBatchBalanceCode(), 0, CheckGeneralJournalBatchBalanceTxt, 'GROUP 0');
        AddResponseToLibrary(CreateAndApproveApprovalRequestAutomaticallyCode(), 0, CreateApproveApprovalRequestAutomaticallyTxt, 'GROUP 0');
        AddResponseToLibrary(ShowMessageCode(), 0, ShowMessageTxt, 'GROUP 4');
        AddResponseToLibrary(RestrictRecordUsageCode(), 0, RestrictRecordUsageTxt, 'GROUP 0');
        AddResponseToLibrary(AllowRecordUsageCode(), 0, AllowRecordUsageTxt, 'GROUP 0');

        AddResponseToLibrary(GetMarkReadyForOCRCode(), 0, MarkReadyForOCRTxt, 'GROUP 0');
        AddResponseToLibrary(GetSendToOCRCode(), 0, SendToOCRTxt, 'GROUP 0');
        AddResponseToLibrary(GetReceiveFromOCRCode(), 0, ReceiveFromOCRTxt, 'GROUP 0');
        AddResponseToLibrary(GetSendToOCRAsyncCode(), 0, BackgroundOCRSendIncomingDocTxt, 'GROUP 0');
        AddResponseToLibrary(GetReceiveFromOCRAsyncCode(), 0, BackgroundOCRReceiveIncomingDocTxt, 'GROUP 0');
        AddResponseToLibrary(GetSendToOCRCode(), 0, SendToOCRTxt, 'GROUP 0');
        AddResponseToLibrary(GetCreateDocFromIncomingDocCode(), 0, CreateDocFromIncomingDocTxt, 'GROUP 0');
        AddResponseToLibrary(GetCreateReleasedDocFromIncomingDocCode(), 0, CreateReleasedDocFromIncomingDocTxt, 'GROUP 0');
        AddResponseToLibrary(GetCreateJournalFromIncomingDocCode(), 0, CreateJournalFromIncomingDocTxt, 'GROUP 0');

        AddResponseToLibrary(RevertValueForFieldCode(), 0, RevertRecordValueTxt, 'GROUP 6');
        AddResponseToLibrary(ApplyNewValuesCode(), 0, ApplyNewValuesTxt, 'GROUP 7');
        AddResponseToLibrary(DiscardNewValuesCode(), 0, DiscardNewValuesTxt, 'GROUP 0');

        AddResponseToLibrary(GetApproveOverReceiptCode(), 0, 'Approve Over-Receipt', 'GROUP 0');

        AddResponseToLibrary(EnableJobQueueEntryCode(), Database::"Job Queue Entry", EnableJobQueueEntryResponseDescTxt, 'GROUP 0');

        OnAddWorkflowResponsesToLibrary();
    end;

    local procedure AddResponsePredecessors(ResponseFunctionName: Code[128])
    var
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
    begin
        case ResponseFunctionName of
            SetStatusToPendingApprovalCode():
                begin
                    AddResponsePredecessor(
                        SetStatusToPendingApprovalCode(), WorkflowEventHandling.RunWorkflowOnSendPurchaseDocForApprovalCode());
                    AddResponsePredecessor(
                        SetStatusToPendingApprovalCode(), WorkflowEventHandling.RunWorkflowOnSendSalesDocForApprovalCode());
                    AddResponsePredecessor(
                        SetStatusToPendingApprovalCode(), WorkflowEventHandling.RunWorkflowOnSendIncomingDocForApprovalCode());
                    AddResponsePredecessor(
                        SetStatusToPendingApprovalCode(), WorkflowEventHandling.RunWorkflowOnCustomerCreditLimitExceededCode());
                    AddResponsePredecessor(
                        SetStatusToPendingApprovalCode(), WorkflowEventHandling.RunWorkflowOnCustomerCreditLimitNotExceededCode());
                    AddResponsePredecessor(
                SetStatusToPendingApprovalCode(), WorkflowEventHandling.RunWorkflowOnSendJobQueueEntryForApprovalCode());
                end;
            CreateApprovalRequestsCode():
                begin
                    AddResponsePredecessor(
                        CreateApprovalRequestsCode(), WorkflowEventHandling.RunWorkflowOnSendPurchaseDocForApprovalCode());
                    AddResponsePredecessor(
                        CreateApprovalRequestsCode(), WorkflowEventHandling.RunWorkflowOnSendSalesDocForApprovalCode());
                    AddResponsePredecessor(
                        CreateApprovalRequestsCode(), WorkflowEventHandling.RunWorkflowOnCustomerCreditLimitExceededCode());
                    AddResponsePredecessor(
                        CreateApprovalRequestsCode(), WorkflowEventHandling.RunWorkflowOnCustomerCreditLimitNotExceededCode());
                    AddResponsePredecessor(
                        CreateApprovalRequestsCode(), WorkflowEventHandling.RunWorkflowOnSendIncomingDocForApprovalCode());
                    AddResponsePredecessor(
                        CreateApprovalRequestsCode(), WorkflowEventHandling.RunWorkflowOnSendCustomerForApprovalCode());
                    AddResponsePredecessor(
                        CreateApprovalRequestsCode(), WorkflowEventHandling.RunWorkflowOnCustomerChangedCode());
                    AddResponsePredecessor(
                        CreateApprovalRequestsCode(), WorkflowEventHandling.RunWorkflowOnSendVendorForApprovalCode());
                    AddResponsePredecessor(
                        CreateApprovalRequestsCode(), WorkflowEventHandling.RunWorkflowOnVendorChangedCode());
                    AddResponsePredecessor(
                        CreateApprovalRequestsCode(), WorkflowEventHandling.RunWorkflowOnSendItemForApprovalCode());
                    AddResponsePredecessor(
                        CreateApprovalRequestsCode(), WorkflowEventHandling.RunWorkflowOnItemChangedCode());
                    AddResponsePredecessor(
                        CreateApprovalRequestsCode(), WorkflowEventHandling.RunWorkflowOnSendGeneralJournalLineForApprovalCode());
                    AddResponsePredecessor(
                        CreateApprovalRequestsCode(), WorkflowEventHandling.RunWorkflowOnSendGeneralJournalBatchForApprovalCode());
                    AddResponsePredecessor(
                        CreateApprovalRequestsCode(), WorkflowEventHandling.RunWorkflowOnGeneralJournalBatchBalancedCode());
                    AddResponsePredecessor(
                        CreateApprovalRequestsCode(), WorkflowEventHandling.RunWorkflowOnSendRequisitionWkshBatchForApprovalCode());
                    AddResponsePredecessor(
                CreateApprovalRequestsCode(), WorkflowEventHandling.RunWorkflowOnSendJobQueueEntryForApprovalCode());
                end;
            SendApprovalRequestForApprovalCode():
                begin
                    AddResponsePredecessor(
                        SendApprovalRequestForApprovalCode(), WorkflowEventHandling.RunWorkflowOnSendPurchaseDocForApprovalCode());
                    AddResponsePredecessor(
                        SendApprovalRequestForApprovalCode(), WorkflowEventHandling.RunWorkflowOnSendSalesDocForApprovalCode());
                    AddResponsePredecessor(
                        SendApprovalRequestForApprovalCode(), WorkflowEventHandling.RunWorkflowOnCustomerCreditLimitExceededCode());
                    AddResponsePredecessor(
                        SendApprovalRequestForApprovalCode(), WorkflowEventHandling.RunWorkflowOnCustomerCreditLimitNotExceededCode());
                    AddResponsePredecessor(
                        SendApprovalRequestForApprovalCode(), WorkflowEventHandling.RunWorkflowOnSendIncomingDocForApprovalCode());
                    AddResponsePredecessor(
                        SendApprovalRequestForApprovalCode(), WorkflowEventHandling.RunWorkflowOnSendCustomerForApprovalCode());
                    AddResponsePredecessor(
                        SendApprovalRequestForApprovalCode(), WorkflowEventHandling.RunWorkflowOnCustomerChangedCode());
                    AddResponsePredecessor(
                        SendApprovalRequestForApprovalCode(), WorkflowEventHandling.RunWorkflowOnSendVendorForApprovalCode());
                    AddResponsePredecessor(
                        SendApprovalRequestForApprovalCode(), WorkflowEventHandling.RunWorkflowOnVendorChangedCode());
                    AddResponsePredecessor(
                        SendApprovalRequestForApprovalCode(), WorkflowEventHandling.RunWorkflowOnSendItemForApprovalCode());
                    AddResponsePredecessor(
                        SendApprovalRequestForApprovalCode(), WorkflowEventHandling.RunWorkflowOnItemChangedCode());
                    AddResponsePredecessor(
                        SendApprovalRequestForApprovalCode(), WorkflowEventHandling.RunWorkflowOnSendGeneralJournalLineForApprovalCode());
                    AddResponsePredecessor(
                        SendApprovalRequestForApprovalCode(), WorkflowEventHandling.RunWorkflowOnSendGeneralJournalBatchForApprovalCode());
                    AddResponsePredecessor(
                        SendApprovalRequestForApprovalCode(), WorkflowEventHandling.RunWorkflowOnGeneralJournalBatchBalancedCode());
                    AddResponsePredecessor(
                        SendApprovalRequestForApprovalCode(), WorkflowEventHandling.RunWorkflowOnSendRequisitionWkshBatchForApprovalCode());
                    AddResponsePredecessor(
                        SendApprovalRequestForApprovalCode(), WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode());
                    AddResponsePredecessor(
                        SendApprovalRequestForApprovalCode(), WorkflowEventHandling.RunWorkflowOnDelegateApprovalRequestCode());
                    AddResponsePredecessor(
                SendApprovalRequestForApprovalCode(), WorkflowEventHandling.RunWorkflowOnSendJobQueueEntryForApprovalCode());
                end;
            ReleaseDocumentCode():
                begin
                    AddResponsePredecessor(ReleaseDocumentCode(), WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode());
                    AddResponsePredecessor(ReleaseDocumentCode(), WorkflowEventHandling.RunWorkflowOnCustomerCreditLimitNotExceededCode());
                end;
            RejectAllApprovalRequestsCode():
                AddResponsePredecessor(RejectAllApprovalRequestsCode(), WorkflowEventHandling.RunWorkflowOnRejectApprovalRequestCode());
            OpenDocumentCode():
                begin
                    AddResponsePredecessor(OpenDocumentCode(), WorkflowEventHandling.RunWorkflowOnRejectApprovalRequestCode());
                    AddResponsePredecessor(OpenDocumentCode(), WorkflowEventHandling.RunWorkflowOnCancelPurchaseApprovalRequestCode());
                    AddResponsePredecessor(OpenDocumentCode(), WorkflowEventHandling.RunWorkflowOnCancelSalesApprovalRequestCode());
                    AddResponsePredecessor(OpenDocumentCode(), WorkflowEventHandling.RunWorkflowOnCancelIncomingDocApprovalRequestCode());
                    AddResponsePredecessor(OpenDocumentCode(), WorkflowEventHandling.RunWorkflowOnCancelCustomerApprovalRequestCode());
                    AddResponsePredecessor(OpenDocumentCode(), WorkflowEventHandling.RunWorkflowOnCancelVendorApprovalRequestCode());
                    AddResponsePredecessor(OpenDocumentCode(), WorkflowEventHandling.RunWorkflowOnCancelItemApprovalRequestCode());
                    AddResponsePredecessor(OpenDocumentCode(), WorkflowEventHandling.RunWorkflowOnCancelGeneralJournalLineApprovalRequestCode());
                    AddResponsePredecessor(OpenDocumentCode(), WorkflowEventHandling.RunWorkflowOnCancelGeneralJournalBatchApprovalRequestCode());
                    AddResponsePredecessor(OpenDocumentCode(), WorkflowEventHandling.RunWorkflowOnCancelRequisitionWkshBatchApprovalRequestCode());
                end;
            CancelAllApprovalRequestsCode():
                begin
                    AddResponsePredecessor(
                        CancelAllApprovalRequestsCode(), WorkflowEventHandling.RunWorkflowOnCancelPurchaseApprovalRequestCode());
                    AddResponsePredecessor(
                        CancelAllApprovalRequestsCode(), WorkflowEventHandling.RunWorkflowOnCancelSalesApprovalRequestCode());
                    AddResponsePredecessor(
                        CancelAllApprovalRequestsCode(), WorkflowEventHandling.RunWorkflowOnCancelIncomingDocApprovalRequestCode());
                    AddResponsePredecessor(
                        CancelAllApprovalRequestsCode(), WorkflowEventHandling.RunWorkflowOnCancelCustomerApprovalRequestCode());
                    AddResponsePredecessor(
                        CancelAllApprovalRequestsCode(), WorkflowEventHandling.RunWorkflowOnCancelVendorApprovalRequestCode());
                    AddResponsePredecessor(
                        CancelAllApprovalRequestsCode(), WorkflowEventHandling.RunWorkflowOnCancelItemApprovalRequestCode());
                    AddResponsePredecessor(
                        CancelAllApprovalRequestsCode(), WorkflowEventHandling.RunWorkflowOnCancelGeneralJournalLineApprovalRequestCode());
                    AddResponsePredecessor(
                        CancelAllApprovalRequestsCode(), WorkflowEventHandling.RunWorkflowOnCancelGeneralJournalBatchApprovalRequestCode());
                    AddResponsePredecessor(
                        CancelAllApprovalRequestsCode(), WorkflowEventHandling.RunWorkflowOnCancelRequisitionWkshBatchApprovalRequestCode());
                    AddResponsePredecessor(
                CancelAllApprovalRequestsCode(), WorkflowEventHandling.RunWorkflowOnCancelJobQueueEntryApprovalRequestCode());
                end;
            RevertValueForFieldCode():
                begin
                    AddResponsePredecessor(
                        RevertValueForFieldCode(), WorkflowEventHandling.RunWorkflowOnCustomerChangedCode());
                    AddResponsePredecessor(
                        RevertValueForFieldCode(), WorkflowEventHandling.RunWorkflowOnVendorChangedCode());
                    AddResponsePredecessor(
                        RevertValueForFieldCode(), WorkflowEventHandling.RunWorkflowOnItemChangedCode());
                end;
            ApplyNewValuesCode():
                AddResponsePredecessor(
                    ApplyNewValuesCode(), WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode());
            DiscardNewValuesCode():
                AddResponsePredecessor(
                    DiscardNewValuesCode(), WorkflowEventHandling.RunWorkflowOnRejectApprovalRequestCode());
            GetMarkReadyForOCRCode():
                AddResponsePredecessor(
                    GetMarkReadyForOCRCode(), WorkflowEventHandling.RunWorkflowOnBinaryFileAttachedCode());
            CreateOverdueNotificationCode():
                AddResponsePredecessor(
                    CreateOverdueNotificationCode(), WorkflowEventHandling.RunWorkflowOnSendOverdueNotificationsCode());
            PostDocumentAsyncCode():
                AddResponsePredecessor(
                    PostDocumentAsyncCode(), WorkflowEventHandling.RunWorkflowOnAfterReleasePurchaseDocCode());
            PostDocumentCode():
                AddResponsePredecessor(
                    PostDocumentCode(), WorkflowEventHandling.RunWorkflowOnAfterReleasePurchaseDocCode());
            CreatePmtLineForPostedPurchaseDocAsyncCode():
                AddResponsePredecessor(
                  CreatePmtLineForPostedPurchaseDocAsyncCode(), WorkflowEventHandling.RunWorkflowOnAfterPostPurchaseDocCode());
            CreatePmtLineForPostedPurchaseDocCode():
                AddResponsePredecessor(
                    CreatePmtLineForPostedPurchaseDocCode(), WorkflowEventHandling.RunWorkflowOnAfterPostPurchaseDocCode());
            CheckGeneralJournalBatchBalanceCode():
                AddResponsePredecessor(
                    CheckGeneralJournalBatchBalanceCode(),
                    WorkflowEventHandling.RunWorkflowOnSendGeneralJournalBatchForApprovalCode());
            CheckCustomerCreditLimitCode():
                AddResponsePredecessor(
                    CheckCustomerCreditLimitCode(), WorkflowEventHandling.RunWorkflowOnSendSalesDocForApprovalCode());
            CreateAndApproveApprovalRequestAutomaticallyCode():
                AddResponsePredecessor(
                    CreateAndApproveApprovalRequestAutomaticallyCode(),
                    WorkflowEventHandling.RunWorkflowOnCustomerCreditLimitNotExceededCode());
            GetReceiveFromOCRCode():
                AddResponsePredecessor(GetReceiveFromOCRCode(), WorkflowEventHandling.RunWorkflowOnAfterSendToOCRIncomingDocCode());
            GetReceiveFromOCRAsyncCode():
                AddResponsePredecessor(GetReceiveFromOCRAsyncCode(), WorkflowEventHandling.RunWorkflowOnAfterSendToOCRIncomingDocCode());
            GetSendToOCRCode():
                AddResponsePredecessor(GetSendToOCRCode(), WorkflowEventHandling.RunWorkflowOnAfterReadyForOCRIncomingDocCode());
            GetSendToOCRAsyncCode():
                AddResponsePredecessor(GetSendToOCRAsyncCode(), WorkflowEventHandling.RunWorkflowOnAfterReadyForOCRIncomingDocCode());
            GetApproveOverReceiptCode():
                AddResponsePredecessor(GetApproveOverReceiptCode(), WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode());
            EnableJobQueueEntryCode():
                AddResponsePredecessor(EnableJobQueueEntryCode(), WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode());
        end;
        OnAddWorkflowResponsePredecessorsToLibrary(ResponseFunctionName);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddWorkflowResponsesToLibrary()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddWorkflowResponsePredecessorsToLibrary(ResponseFunctionName: Code[128])
    begin
    end;

    [Scope('OnPrem')]
    procedure ExecuteResponse(var Variant: Variant; ResponseWorkflowStepInstance: Record "Workflow Step Instance"; xVariant: Variant)
    var
        WorkflowResponse: Record "Workflow Response";
        WorkflowChangeRecMgt: Codeunit "Workflow Change Rec Mgt.";
        WorkflowManagement: Codeunit "Workflow Management";
        ResponseExecuted: Boolean;
        TelemetryDimensions: Dictionary of [Text, Text];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeExecuteResponse(Variant, ResponseWorkflowStepInstance, xVariant, IsHandled);
        if IsHandled then
            exit;

        WorkflowManagement.GetTelemetryDimensions(ResponseWorkflowStepInstance."Function Name", ResponseWorkflowStepInstance.ToString(), TelemetryDimensions);

        if not WorkflowResponse.Get(ResponseWorkflowStepInstance."Function Name") then begin
            Session.LogMessage('0000DYO', WorkflowResponseNotFoundTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, TelemetryDimensions);
            exit;
        end;

        Session.LogMessage('0000DYP', WorkflowResponseStartTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, TelemetryDimensions);

        case WorkflowResponse."Function Name" of
            DoNothingCode():
                DoNothing();
            CreateNotificationEntryCode():
                CreateNotificationEntry(ResponseWorkflowStepInstance, xVariant);
            ReleaseDocumentCode():
                ReleaseDocument(Variant);
            OpenDocumentCode():
                OpenDocument(Variant);
            SetStatusToPendingApprovalCode():
                SetStatusToPendingApproval(Variant);
            GetApprovalCommentCode():
                GetApprovalComment(Variant, ResponseWorkflowStepInstance.ID);
            CreateApprovalRequestsCode():
                CreateApprovalRequests(Variant, ResponseWorkflowStepInstance);
            SendApprovalRequestForApprovalCode():
                SendApprovalRequestForApproval(Variant, ResponseWorkflowStepInstance);
            ApproveAllApprovalRequestsCode():
                ApproveAllApprovalRequests(Variant, ResponseWorkflowStepInstance);
            RejectAllApprovalRequestsCode():
                RejectAllApprovalRequests(Variant, ResponseWorkflowStepInstance);
            CancelAllApprovalRequestsCode():
                CancelAllApprovalRequests(Variant, ResponseWorkflowStepInstance);
            PostDocumentCode():
                PostDocument(Variant);
            PostDocumentAsyncCode():
                PostDocumentAsync(Variant);
            CreatePmtLineForPostedPurchaseDocAsyncCode():
                CreatePmtLineForPostedPurchaseDocAsync(ResponseWorkflowStepInstance);
            CreatePmtLineForPostedPurchaseDocCode():
                CreatePmtLineForPostedPurchaseDoc(ResponseWorkflowStepInstance);
            CreateOverdueNotificationCode():
                CreateOverdueNotifications(ResponseWorkflowStepInstance);
            CheckCustomerCreditLimitCode():
                CheckCustomerCreditLimit(Variant);
            CheckGeneralJournalBatchBalanceCode():
                CheckGeneralJournalBatchBalance(Variant);
            CreateAndApproveApprovalRequestAutomaticallyCode():
                CreateAndApproveApprovalRequestAutomatically(Variant, ResponseWorkflowStepInstance);
            ShowMessageCode():
                ShowMessage(ResponseWorkflowStepInstance);
            RestrictRecordUsageCode():
                RestrictRecordUsage(Variant, ResponseWorkflowStepInstance);
            AllowRecordUsageCode():
                AllowRecordUsage(Variant);
            GetMarkReadyForOCRCode():
                MarkReadyForOCR(Variant);
            GetSendToOCRCode():
                SendToOCR(Variant);
            GetSendToOCRAsyncCode():
                SendToOCRAsync(Variant);
            GetReceiveFromOCRCode():
                ReceiveFromOCR(Variant);
            GetReceiveFromOCRAsyncCode():
                ReceiveFromOCRAsync(Variant);
            GetCreateDocFromIncomingDocCode():
                CreateDocFromIncomingDoc(Variant);
            GetCreateReleasedDocFromIncomingDocCode():
                CreateReleasedDocFromIncomingDoc(Variant);
            GetCreateJournalFromIncomingDocCode():
                CreateJournalFromIncomingDoc(Variant);
            RevertValueForFieldCode():
                WorkflowChangeRecMgt.RevertValueForField(Variant, xVariant, ResponseWorkflowStepInstance);
            ApplyNewValuesCode():
                WorkflowChangeRecMgt.ApplyNewValues(Variant, ResponseWorkflowStepInstance);
            DiscardNewValuesCode():
                WorkflowChangeRecMgt.DiscardNewValues(Variant, ResponseWorkflowStepInstance);
            GetApproveOverReceiptCode():
                ApproveOverReceipt(Variant);
            EnableJobQueueEntryCode():
                EnableJobQueueEntry(variant);
            else begin
                OnExecuteWorkflowResponse(ResponseExecuted, Variant, xVariant, ResponseWorkflowStepInstance);
                if not ResponseExecuted then
                    Error(NotSupportedResponseErr, WorkflowResponse."Function Name");
            end;
        end;

        Session.LogMessage('0000DYQ', WorkflowResponseEndTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, TelemetryDimensions);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnExecuteWorkflowResponse(var ResponseExecuted: Boolean; var Variant: Variant; xVariant: Variant; ResponseWorkflowStepInstance: Record "Workflow Step Instance")
    begin
    end;

    procedure DoNothingCode(): Code[128]
    begin
        exit('DONOTHING');
    end;

    procedure CreateNotificationEntryCode(): Code[128]
    begin
        exit('CREATENOTIFICATIONENTRY');
    end;

    procedure ReleaseDocumentCode(): Code[128]
    begin
        exit('RELEASEDOCUMENT');
    end;

    procedure OpenDocumentCode(): Code[128]
    begin
        exit('OPENDOCUMENT');
    end;

    procedure SetStatusToPendingApprovalCode(): Code[128]
    begin
        exit('SETSTATUSTOPENDINGAPPROVAL');
    end;

    procedure GetApprovalCommentCode(): Code[128]
    begin
        exit('GETAPPROVALCOMMENT');
    end;

    procedure CreateApprovalRequestsCode(): Code[128]
    begin
        exit('CREATEAPPROVALREQUESTS');
    end;

    procedure SendApprovalRequestForApprovalCode(): Code[128]
    begin
        exit('SENDAPPROVALREQUESTFORAPPROVAL');
    end;

    procedure ApproveAllApprovalRequestsCode(): Code[128]
    begin
        exit('APPROVEALLAPPROVALREQUESTS');
    end;

    procedure RejectAllApprovalRequestsCode(): Code[128]
    begin
        exit('REJECTALLAPPROVALREQUESTS');
    end;

    procedure CancelAllApprovalRequestsCode(): Code[128]
    begin
        exit('CANCELALLAPPROVALREQUESTS');
    end;

    procedure PostDocumentAsyncCode(): Code[128]
    begin
        exit('BACKGROUNDPOSTAPPROVEDPURCHASEDOC');
    end;

    procedure PostDocumentCode(): Code[128]
    begin
        exit('POSTDOCUMENT');
    end;

    procedure CreatePmtLineForPostedPurchaseDocAsyncCode(): Code[128]
    begin
        exit('BACKGROUNDCREATEPMTLINEFORPOSTEDDOCUMENT');
    end;

    procedure CreatePmtLineForPostedPurchaseDocCode(): Code[128]
    begin
        exit('CREATEPMTLINEFORPOSTEDDOCUMENT');
    end;

    procedure CreateOverdueNotificationCode(): Code[128]
    begin
        exit('CREATEOVERDUENOTIFICATIONS');
    end;

    procedure CheckCustomerCreditLimitCode(): Code[128]
    begin
        exit('CHECKCUSTOMERCREDITLIMIT');
    end;

    procedure CheckGeneralJournalBatchBalanceCode(): Code[128]
    begin
        exit('CHECKGENERALJOURNALBATCHBALANCE');
    end;

    procedure CreateAndApproveApprovalRequestAutomaticallyCode(): Code[128]
    begin
        exit('CREATEANDAPPROVEAPPROVALREQUESTAUTOMATICALLY');
    end;

    procedure ShowMessageCode(): Code[128]
    begin
        exit('SHOWMESSAGE');
    end;

    procedure RestrictRecordUsageCode(): Code[128]
    begin
        exit('RESTRICTRECORDUSAGE');
    end;

    procedure AllowRecordUsageCode(): Code[128]
    begin
        exit('ALLOWRECORDUSAGE');
    end;

    procedure GetMarkReadyForOCRCode(): Code[128]
    begin
        exit('MARKREADYFOROCR');
    end;

    procedure GetSendToOCRAsyncCode(): Code[128]
    begin
        exit('BACKGROUNDSENDTOOCR');
    end;

    procedure GetSendToOCRCode(): Code[128]
    begin
        exit('SENDTOOCR');
    end;

    procedure GetReceiveFromOCRAsyncCode(): Code[128]
    begin
        exit('BACKGROUNDRECEIVEFROMOCR');
    end;

    procedure GetReceiveFromOCRCode(): Code[128]
    begin
        exit('RECEIVEFROMOCR');
    end;

    procedure GetCreateDocFromIncomingDocCode(): Code[128]
    begin
        exit('CREATEDOCFROMINCOMINGDOC');
    end;

    procedure GetCreateReleasedDocFromIncomingDocCode(): Code[128]
    begin
        exit('CREATERELEASEDDOCFROMINCOMINGDOC');
    end;

    procedure GetCreateJournalFromIncomingDocCode(): Code[128]
    begin
        exit('CREATEJOURNALFROMINCOMINGDOC');
    end;

    procedure RevertValueForFieldCode(): Code[128]
    begin
        exit('REVERTVALUEFORFIELD');
    end;

    procedure ApplyNewValuesCode(): Code[128]
    begin
        exit('APPLYNEWVALUES');
    end;

    procedure DiscardNewValuesCode(): Code[128]
    begin
        exit('DISCARDNEWVALUES');
    end;

    procedure EnableJobQueueEntryCode(): Code[128]
    begin
        exit(UpperCase('EnableJobQueueEntry'))
    end;

    local procedure DoNothing()
    begin
    end;

    local procedure CreateNotificationEntry(WorkflowStepInstance: Record "Workflow Step Instance"; var Variant: Variant)
    var
        ApprovalEntry: Record "Approval Entry";
        WorkflowStepArgument: Record "Workflow Step Argument";
        NotificationEntry: Record "Notification Entry";
        RecRef: RecordRef;
        IsHandled: Boolean;
    begin
        RecRef.GetTable(Variant);
        case RecRef.Number of
            Database::"Approval Entry":
                begin
                    ApprovalEntry := Variant;
                    IsHandled := false;
                    OnBeforeCreateNotificationEntry(WorkflowStepInstance, ApprovalEntry, IsHandled);
                    if IsHandled then
                        exit;
                end;
            else begin
                ApprovalEntry.SetRange("Record ID to Approve", RecRef.RecordId);
                if ApprovalEntry.FindFirst() then begin
                    Variant := ApprovalEntry;
                    CreateNotificationEntry(WorkflowStepInstance, Variant);
                    exit;
                end;
            end;
        end;

        if WorkflowStepArgument.Get(WorkflowStepInstance.Argument) then
            NotificationEntry.CreateNotificationEntry(WorkflowStepArgument."Notification Entry Type", WorkflowStepArgument.GetNotificationUserID(Variant), Variant, WorkflowStepArgument."Link Target Page", WorkflowStepArgument."Custom Link", CopyStr(UserId(), 1, 50));
    end;

    local procedure ReleaseDocument(var Variant: Variant)
    var
        ApprovalEntry: Record "Approval Entry";
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
        ReleasePurchaseDocument: Codeunit "Release Purchase Document";
        ReleaseSalesDocument: Codeunit "Release Sales Document";
        ReleaseIncomingDocument: Codeunit "Release Incoming Document";
        RecRef: RecordRef;
        TargetRecRef: RecordRef;
        Handled: Boolean;
    begin
        OnBeforeReleaseDocument(Variant);
        RecRef.GetTable(Variant);

        case RecRef.Number of
            Database::"Approval Entry":
                begin
                    ApprovalEntry := Variant;
                    TargetRecRef.Get(ApprovalEntry."Record ID to Approve");
                    Variant := TargetRecRef;
                    ReleaseDocument(Variant);
                end;
            Database::"Workflow Webhook Entry":
                begin
                    WorkflowWebhookEntry := Variant;
                    TargetRecRef.Get(WorkflowWebhookEntry."Record ID");
                    Variant := TargetRecRef;
                    ReleaseDocument(Variant);
                end;
            Database::"Purchase Header":
                ReleasePurchaseDocument.PerformManualCheckAndRelease(Variant);
            Database::"Sales Header":
                ReleaseSalesDocument.PerformManualCheckAndRelease(Variant);
            Database::"Incoming Document":
                ReleaseIncomingDocument.PerformManualRelease(Variant);
            else begin
                OnReleaseDocument(RecRef, Handled);
                if not Handled then
                    Error(UnsupportedRecordTypeErr, RecRef.Caption);
            end;
        end;
    end;

    local procedure OpenDocument(var Variant: Variant)
    var
        ApprovalEntry: Record "Approval Entry";
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
        ReleasePurchaseDocument: Codeunit "Release Purchase Document";
        ReleaseSalesDocument: Codeunit "Release Sales Document";
        ReleaseIncomingDocument: Codeunit "Release Incoming Document";
        RecRef: RecordRef;
        TargetRecRef: RecordRef;
        Handled: Boolean;
    begin
        RecRef.GetTable(Variant);

        case RecRef.Number of
            Database::"Approval Entry":
                begin
                    ApprovalEntry := Variant;
                    TargetRecRef.Get(ApprovalEntry."Record ID to Approve");
                    Variant := TargetRecRef;
                    OpenDocument(Variant);
                end;
            Database::"Workflow Webhook Entry":
                begin
                    WorkflowWebhookEntry := Variant;
                    TargetRecRef.Get(WorkflowWebhookEntry."Record ID");
                    Variant := TargetRecRef;
                    OpenDocument(Variant);
                end;
            Database::"Purchase Header":
                ReleasePurchaseDocument.Reopen(Variant);
            Database::"Sales Header":
                ReleaseSalesDocument.Reopen(Variant);
            Database::"Incoming Document":
                ReleaseIncomingDocument.Reopen(Variant);
            else begin
                OnOpenDocument(RecRef, Handled);
                if not Handled then
                    Error(UnsupportedRecordTypeErr, RecRef.Caption);
            end;
        end;
    end;

    procedure SetStatusToPendingApproval(var Variant: Variant)
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        ApprovalsMgmt.SetStatusToPendingApproval(Variant);
    end;

    local procedure GetApprovalComment(Variant: Variant; WorkflowStepInstanceID: Guid)
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        ApprovalsMgmt.GetApprovalCommentForWorkflowStepInstanceID(Variant, WorkflowStepInstanceID);
    end;

    local procedure CreateApprovalRequests(Variant: Variant; WorkflowStepInstance: Record "Workflow Step Instance")
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Variant);
        ApprovalsMgmt.CreateApprovalRequests(RecRef, WorkflowStepInstance);
    end;

    local procedure BuildTheCreateApprovalReqDescription(WorkflowResponse: Record "Workflow Response"; WorkflowStepArgument: Record "Workflow Step Argument"): Text[250]
    var
        ApproverLimitDesc: Text;
        WorkflowUserGroupDesc: Text;
    begin
        ApproverLimitDesc := StrSubstNo(CreateApprovalApprovalLimitTxt,
            GetTokenValue(ApproverLimitTypeTok, Format(WorkflowStepArgument."Approver Limit Type")));
        WorkflowUserGroupDesc := StrSubstNo(CreateApprovalWorkflowGroupTxt,
            GetTokenValue(WorkflowUserGroupTok, Format(WorkflowStepArgument."Workflow User Group Code")));

        if GetTokenValue(ApproverTypeTok, Format(WorkflowStepArgument."Approver Type")) = ApproverTypeTok then
            exit(CopyStr(StrSubstNo(WorkflowResponse.Description, ApproverTypeTok,
                  StrSubstNo('%1/%2', ApproverLimitDesc, WorkflowUserGroupDesc)), 1, 250));

        if WorkflowStepArgument."Approver Type" <> WorkflowStepArgument."Approver Type"::"Workflow User Group" then
            exit(CopyStr(StrSubstNo(WorkflowResponse.Description,
                  GetTokenValue(ApproverTypeTok, Format(WorkflowStepArgument."Approver Type")),
                  ApproverLimitDesc), 1, 250));

        exit(CopyStr(StrSubstNo(WorkflowResponse.Description,
              GetTokenValue(ApproverTypeTok, Format(WorkflowStepArgument."Approver Type")),
              WorkflowUserGroupDesc), 1, 250));
    end;

    local procedure SendApprovalRequestForApproval(Variant: Variant; WorkflowStepInstance: Record "Workflow Step Instance")
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Variant);

        case RecRef.Number of
            Database::"Approval Entry":
                ApprovalsMgmt.SendApprovalRequestFromApprovalEntry(Variant, WorkflowStepInstance);
            else
                ApprovalsMgmt.SendApprovalRequestFromRecord(RecRef, WorkflowStepInstance);
        end;
    end;

    local procedure ApproveAllApprovalRequests(Variant: Variant; WorkflowStepInstance: Record "Workflow Step Instance")
    var
        ApprovalEntry: Record "Approval Entry";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Variant);

        case RecRef.Number of
            Database::"Approval Entry":
                begin
                    ApprovalEntry := Variant;
                    RecRef.Get(ApprovalEntry."Record ID to Approve");
                    ApproveAllApprovalRequests(RecRef, WorkflowStepInstance);
                end;
            else
                ApprovalsMgmt.ApproveApprovalRequestsForRecord(RecRef, WorkflowStepInstance);
        end;
    end;

    local procedure RejectAllApprovalRequests(Variant: Variant; WorkflowStepInstance: Record "Workflow Step Instance")
    var
        ApprovalEntry: Record "Approval Entry";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Variant);

        case RecRef.Number of
            Database::"Approval Entry":
                begin
                    ApprovalEntry := Variant;
                    RecRef.Get(ApprovalEntry."Record ID to Approve");
                    RejectAllApprovalRequests(RecRef, WorkflowStepInstance);
                end;
            else
                ApprovalsMgmt.RejectApprovalRequestsForRecord(RecRef, WorkflowStepInstance);
        end;
    end;

    local procedure CancelAllApprovalRequests(Variant: Variant; WorkflowStepInstance: Record "Workflow Step Instance")
    var
        ApprovalEntry: Record "Approval Entry";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Variant);

        case RecRef.Number of
            Database::"Approval Entry":
                begin
                    ApprovalEntry := Variant;
                    RecRef.Get(ApprovalEntry."Record ID to Approve");
                    CancelAllApprovalRequests(RecRef, WorkflowStepInstance);
                end;
            else
                ApprovalsMgmt.CancelApprovalRequestsForRecord(RecRef, WorkflowStepInstance);
        end;
    end;

    local procedure PostDocumentAsync(Variant: Variant)
    var
        JobQueueEntry: Record "Job Queue Entry";
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Variant);

        case RecRef.Number of
            Database::"Purchase Header":
                begin
                    PurchaseHeader := Variant;
                    PurchaseHeader.TestField(Status, PurchaseHeader.Status::Released);
                    JobQueueEntry.ScheduleJobQueueEntry(CODEUNIT::"Purchase Post via Job Queue", PurchaseHeader.RecordId);
                end;
            Database::"Sales Header":
                begin
                    SalesHeader := Variant;
                    SalesHeader.TestField(Status, SalesHeader.Status::Released);
                    JobQueueEntry.ScheduleJobQueueEntry(CODEUNIT::"Sales Post via Job Queue", SalesHeader.RecordId);
                end;
            else
                Error(UnsupportedRecordTypeErr, RecRef.Caption);
        end;
    end;

    local procedure PostDocument(Variant: Variant)
    var
        RecRef: RecordRef;
        IsHandled: Boolean;
    begin
        RecRef.GetTable(Variant);

        case RecRef.Number of
            Database::"Purchase Header":
                CODEUNIT.Run(CODEUNIT::"Purch.-Post", Variant);
            Database::"Sales Header":
                CODEUNIT.Run(CODEUNIT::"Sales-Post", Variant);
            else begin
                IsHandled := false;
                OnPostDocumentOnCaseElse(RecRef, IsHandled);
                if not IsHandled then
                    Error(UnsupportedRecordTypeErr, RecRef.Caption);
            end;
        end;
    end;

    local procedure CreatePmtLineForPostedPurchaseDocAsync(WorkflowStepInstance: Record "Workflow Step Instance")
    var
        JobQueueEntry: Record "Job Queue Entry";
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        if WorkflowStepArgument.Get(WorkflowStepInstance.Argument) then
            JobQueueEntry.ScheduleJobQueueEntry(CODEUNIT::"Workflow Create Payment Line", WorkflowStepArgument.RecordId);
    end;

    local procedure CreatePmtLineForPostedPurchaseDoc(WorkflowStepInstance: Record "Workflow Step Instance")
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
        WorkflowCreatePaymentLine: Codeunit "Workflow Create Payment Line";
    begin
        if WorkflowStepArgument.Get(WorkflowStepInstance.Argument) then
            WorkflowCreatePaymentLine.CreatePmtLine(WorkflowStepArgument);
    end;

    local procedure CheckCustomerCreditLimit(Variant: Variant)
    var
        SalesHeader: Record "Sales Header";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Variant);

        case RecRef.Number of
            Database::"Sales Header":
                begin
                    SalesHeader := Variant;
                    SalesHeader.CheckAvailableCreditLimit();
                end;
        end;
    end;

    local procedure CheckGeneralJournalBatchBalance(Variant: Variant)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Variant);

        case RecRef.Number of
            Database::"Gen. Journal Batch":
                begin
                    GenJournalBatch := Variant;
                    GenJournalBatch.CheckBalance();
                end;
        end;
    end;

    local procedure CreateAndApproveApprovalRequestAutomatically(Variant: Variant; WorkflowStepInstance: Record "Workflow Step Instance")
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Variant);

        case RecRef.Number of
            Database::"Sales Header":
                ApprovalsMgmt.CreateAndAutomaticallyApproveRequest(RecRef, WorkflowStepInstance);
            Database::Customer:
                ApprovalsMgmt.CreateAndAutomaticallyApproveRequest(RecRef, WorkflowStepInstance);
        end;
    end;

    local procedure ShowMessage(WorkflowStepInstance: Record "Workflow Step Instance")
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
        SuppressMessage: Boolean;
    begin
        WorkflowStepArgument.Get(WorkflowStepInstance.Argument);

        SuppressMessage := false;
        OnShowMessageOnBeforeShowMessage(WorkflowStepArgument, SuppressMessage);
        if not SuppressMessage then
            Message(StrSubstNo(ShowMessagePlaceholderMsg, WorkflowStepArgument.Message));
    end;

    local procedure RestrictRecordUsage(Variant: Variant; WorkflowStepInstance: Record "Workflow Step Instance")
    var
        Workflow: Record Workflow;
        RecordRestrictionMgt: Codeunit "Record Restriction Mgt.";
    begin
        Workflow.Get(WorkflowStepInstance."Workflow Code");
        RecordRestrictionMgt.RestrictRecordUsage(Variant, StrSubstNo(RestrictUsageDetailsTxt, Workflow.Code, Workflow.Description));
    end;

    local procedure AllowRecordUsage(Variant: Variant)
    var
        ApprovalEntry: Record "Approval Entry";
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
        GenJournalBatch: Record "Gen. Journal Batch";
        ItemJournalBatch: Record "Item Journal Batch";
        FAJournalBatch: Record "FA Journal Batch";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RecordRestrictionMgt: Codeunit "Record Restriction Mgt.";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Variant);

        case RecRef.Number of
            Database::"Approval Entry":
                begin
                    RecordRestrictionMgt.AllowRecordUsage(Variant);
                    RecRef.SetTable(ApprovalEntry);
                    RecRef.Get(ApprovalEntry."Record ID to Approve");
                    AllowRecordUsage(RecRef);
                end;
            Database::"Workflow Webhook Entry":
                begin
                    RecRef.SetTable(WorkflowWebhookEntry);
                    RecRef.Get(WorkflowWebhookEntry."Record ID");
                    AllowRecordUsage(RecRef);
                end;
            Database::"Gen. Journal Batch":
                begin
                    RecRef.SetTable(GenJournalBatch);
                    RecordRestrictionMgt.AllowGenJournalBatchUsage(GenJournalBatch);
                end;
            Database::"Item Journal Batch":
                begin
                    RecRef.SetTable(ItemJournalBatch);
                    RecordRestrictionMgt.AllowItemJournalBatchUsage(ItemJournalBatch);
                end;
            Database::"FA Journal Batch":
                begin
                    RecRef.SetTable(FAJournalBatch);
                    RecordRestrictionMgt.AllowFAJournalBatchUsage(FAJournalBatch);
                end;
            Database::"Requisition Wksh. Name":
                begin
                    RecRef.SetTable(RequisitionWkshName);
                    RecordRestrictionMgt.AllowRequisitionWkshUsage(RequisitionWkshName);
                end;
            else
                AllowRecordUsageDefault(Variant);
        end;

        OnAfterAllowRecordUsage(Variant, RecRef);
    end;

    local procedure AllowRecordUsageDefault(Variant: Variant)
    var
        RecordRestrictionMgt: Codeunit "Record Restriction Mgt.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAllowRecordUsageDefault(Variant, IsHandled);
        if IsHandled then
            exit;

        RecordRestrictionMgt.AllowRecordUsage(Variant);
    end;

    local procedure EnableJobQueueEntry(variant: variant)
    var
        ApprovalEntry: Record "Approval Entry";
        JobQueueEntry: Record "Job Queue Entry";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(variant);

        case RecRef.Number of
            Database::"Approval Entry":
                begin
                    ApprovalEntry := variant;
                    JobQueueEntry.Get(ApprovalEntry."Record ID to Approve");
                end;
            Database::"Job Queue Entry":
                JobQueueEntry := variant;
        end;
        JobQueueEntry.SetStatus(JobQueueEntry.Status::Ready);
    end;


    procedure AddResponseToLibrary(FunctionName: Code[128]; TableID: Integer; Description: Text[250]; ResponseOptionGroup: Code[20])
    var
        WorkflowResponse: Record "Workflow Response";
        SystemInitialization: Codeunit "System Initialization";
    begin
        OnBeforeAddResponseToLibrary(FunctionName, Description);

        if WorkflowResponse.Get(FunctionName) then
            exit;

        WorkflowResponse.SetRange(Description, Description);
        if not WorkflowResponse.IsEmpty() then begin
            if SystemInitialization.IsInProgress() or (GetExecutionContext() <> ExecutionContext::Normal) then
                exit;
            Error(ResponseAlreadyExistErr, Description);
        end;

        WorkflowResponse.Init();
        WorkflowResponse."Function Name" := FunctionName;
        WorkflowResponse."Table ID" := TableID;
        WorkflowResponse.Description := Description;
        WorkflowResponse."Response Option Group" := ResponseOptionGroup;
        WorkflowResponse.Insert();

        AddResponsePredecessors(WorkflowResponse."Function Name");
    end;

    procedure AddResponsePredecessor(FunctionName: Code[128]; PredecessorFunctionName: Code[128])
    var
        WFEventResponseCombination: Record "WF Event/Response Combination";
    begin
        WFEventResponseCombination.Init();
        WFEventResponseCombination.Type := WFEventResponseCombination.Type::Response;
        WFEventResponseCombination."Function Name" := FunctionName;
        WFEventResponseCombination."Predecessor Type" := WFEventResponseCombination."Predecessor Type"::"Event";
        WFEventResponseCombination."Predecessor Function Name" := PredecessorFunctionName;
        if WFEventResponseCombination.Insert() then;
    end;

    procedure GetDescription(WorkflowStepArgument: Record "Workflow Step Argument") Result: Text[250]
    var
        WorkflowResponse: Record "Workflow Response";
    begin
        if not WorkflowResponse.Get(WorkflowStepArgument."Response Function Name") then
            exit('');
        case WorkflowResponse."Function Name" of
            CreateNotificationEntryCode():
                exit(CopyStr(StrSubstNo(WorkflowResponse.Description,
                      GetTokenValue(UserIDTok, WorkflowStepArgument.GetNotificationUserName())), 1, 250));
            ShowMessageCode():
                exit(CopyStr(StrSubstNo(WorkflowResponse.Description,
                      GetTokenValue(MessageTok, WorkflowStepArgument.Message)), 1, 250));
            CreatePmtLineForPostedPurchaseDocAsyncCode(),
          CreatePmtLineForPostedPurchaseDocCode():
                exit(CopyStr(StrSubstNo(WorkflowResponse.Description,
                      GetTokenValue(TemplateTok, WorkflowStepArgument."General Journal Template Name"),
                      GetTokenValue(GenJnlBatchTok, WorkflowStepArgument."General Journal Batch Name")), 1, 250));
            CreateApprovalRequestsCode():
                exit(BuildTheCreateApprovalReqDescription(WorkflowResponse, WorkflowStepArgument));
            SendApprovalRequestForApprovalCode(),
          RejectAllApprovalRequestsCode(),
          CancelAllApprovalRequestsCode(),
          CreateOverdueNotificationCode():
                exit(CopyStr(StrSubstNo(WorkflowResponse.Description), 1, 250));
            RevertValueForFieldCode():
                begin
                    WorkflowStepArgument.CalcFields("Field Caption");
                    exit(CopyStr(StrSubstNo(WorkflowResponse.Description,
                          GetTokenValue(RevertRecordFieldValueTok, WorkflowStepArgument."Field Caption")), 1, 250));
                end;
            else
                Result := GetWorkflowResponseDescription(WorkflowResponse, WorkflowStepArgument);
        end;

        OnAfterGetDescription(WorkflowStepArgument, WorkflowResponse, Result);
    end;

    local procedure GetWorkflowResponseDescription(var WorkflowResponse: Record "Workflow Response"; var WorkflowStepArgument: Record "Workflow Step Argument") WorkflowDescirption: Text[250]
    begin
        WorkflowDescirption := WorkflowResponse.Description;
        OnAfterGetWorkflowResponseDescription(WorkflowResponse, WorkflowStepArgument, WorkflowDescirption);
    end;

    local procedure GetTokenValue(TokenValue: Text; FieldValue: Text): Text
    begin
        if FieldValue <> '' then
            exit(FieldValue);

        exit(TokenValue);
    end;

    procedure IsArgumentMandatory(ResponseFunctionName: Code[128]): Boolean
    var
        ArgumentMandatory: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsArgumentMandatory(ResponseFunctionName, ArgumentMandatory, IsHandled);
        if IsHandled then
            exit(ArgumentMandatory);
        if ResponseFunctionName in
           [CreateNotificationEntryCode(), CreatePmtLineForPostedPurchaseDocAsyncCode(), CreateApprovalRequestsCode(),
            CreatePmtLineForPostedPurchaseDocCode()]
        then
            exit(true);

        ArgumentMandatory := false;
        OnCheckIsArgumentMandatory(ResponseFunctionName, ArgumentMandatory);
        exit(ArgumentMandatory);
    end;

    procedure HasRequiredArguments(WorkflowStep: Record "Workflow Step"): Boolean
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
        HasRequiredArgument: Boolean;
    begin
        if not IsArgumentMandatory(WorkflowStep."Function Name") then
            exit(true);

        if not WorkflowStepArgument.Get(WorkflowStep.Argument) then
            exit(false);

        case WorkflowStep."Function Name" of
            CreatePmtLineForPostedPurchaseDocAsyncCode(),
          CreatePmtLineForPostedPurchaseDocCode():
                if (WorkflowStepArgument."General Journal Template Name" = '') or
                   (WorkflowStepArgument."General Journal Batch Name" = '')
                then
                    exit(false);
            CreateApprovalRequestsCode():
                case WorkflowStepArgument."Approver Type" of
                    WorkflowStepArgument."Approver Type"::"Workflow User Group":
                        if WorkflowStepArgument."Workflow User Group Code" = '' then
                            exit(false);
                    else
                        if WorkflowStepArgument."Approver Limit Type" = WorkflowStepArgument."Approver Limit Type"::"Specific Approver" then
                            if WorkflowStepArgument."Approver User ID" = '' then
                                exit(false);
                end;
            CreateNotificationEntryCode():
                if (WorkflowStepArgument."Notification User ID" = '') and not WorkflowStepArgument."Notify Sender" then
                    exit(false);
        end;

        HasRequiredArgument := true;
        OnCheckHasRequiredArguments(WorkflowStep, WorkflowStepArgument, HasRequiredArgument);
        exit(HasRequiredArgument);
    end;

    local procedure CreateOverdueNotifications(WorkflowStepInstance: Record "Workflow Step Instance")
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
        NotificationManagement: Codeunit "Notification Management";
    begin
        if WorkflowStepArgument.Get(WorkflowStepInstance.Argument) then
            NotificationManagement.CreateOverdueNotifications(WorkflowStepArgument);
    end;

    local procedure MarkReadyForOCR(Variant: Variant)
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        IncomingDocument: Record "Incoming Document";
    begin
        IncomingDocumentAttachment := Variant;
        IncomingDocument.Get(IncomingDocumentAttachment."Incoming Document Entry No.");
        IncomingDocument.SendToJobQueue(false);
    end;

    local procedure SendToOCRAsync(Variant: Variant)
    var
        JobQueueEntry: Record "Job Queue Entry";
        IncomingDocument: Record "Incoming Document";
    begin
        IncomingDocument := Variant;
        IncomingDocument.TestField(Status, IncomingDocument.Status::Released);
        IncomingDocument.TestField("OCR Status", IncomingDocument."OCR Status"::Ready);
        JobQueueEntry.ScheduleJobQueueEntry(CODEUNIT::"OCR Inc. Doc. via Job Queue", IncomingDocument.RecordId);
    end;

    local procedure SendToOCR(Variant: Variant)
    var
        IncomingDocument: Record "Incoming Document";
    begin
        IncomingDocument := Variant;
        IncomingDocument.SendToOCR(false);
    end;

    local procedure ReceiveFromOCRAsync(Variant: Variant)
    var
        IncomingDocument: Record "Incoming Document";
        OCRIncDocViaJobQueue: Codeunit "OCR Inc. Doc. via Job Queue";
    begin
        IncomingDocument := Variant;
        IncomingDocument.TestField(Status, IncomingDocument.Status::Released);
        IncomingDocument.TestField("OCR Status", IncomingDocument."OCR Status"::Sent);
        OCRIncDocViaJobQueue.EnqueueIncomingDoc(IncomingDocument);
    end;

    local procedure ReceiveFromOCR(Variant: Variant)
    var
        IncomingDocument: Record "Incoming Document";
    begin
        IncomingDocument := Variant;
        IncomingDocument.RetrieveFromOCR(false);
    end;

    local procedure CreateDocFromIncomingDoc(Variant: Variant)
    var
        IncomingDocument: Record "Incoming Document";
    begin
        IncomingDocument := Variant;
        IncomingDocument.TryCreateDocumentWithDataExchange();
    end;

    local procedure CreateReleasedDocFromIncomingDoc(Variant: Variant)
    var
        IncomingDocument: Record "Incoming Document";
    begin
        IncomingDocument := Variant;
        IncomingDocument.CreateReleasedDocumentWithDataExchange();
    end;

    local procedure CreateJournalFromIncomingDoc(Variant: Variant)
    var
        IncomingDocument: Record "Incoming Document";
    begin
        IncomingDocument := Variant;
        IncomingDocument.TryCreateGeneralJournalLineWithDataExchange();
    end;

    local procedure ApproveOverReceipt(var VariantRecord: Variant)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ApprovalEntry: Record "Approval Entry";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(VariantRecord);

        case RecRef.Number of
            Database::"Approval Entry":
                begin
                    ApprovalEntry := VariantRecord;
                    RecRef := ApprovalEntry."Record ID to Approve".GetRecord();
                    RecRef.SetTable(PurchaseHeader);
                end;
            Database::"Purchase Header":
                PurchaseHeader := VariantRecord;
        end;
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("Over-Receipt Approval Status", PurchaseLine."Over-Receipt Approval Status"::Pending);
        if not PurchaseLine.IsEmpty() then
            PurchaseLine.ModifyAll("Over-Receipt Approval Status", PurchaseLine."Over-Receipt Approval Status"::Approved);
    end;

    procedure GetApproveOverReceiptCode(): Text[128]
    begin
        exit('APPROVEOVERRECEIPT');
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetWorkflowResponseDescription(var WorkflowResponse: Record "Workflow Response"; var WorkflowStepArgument: Record "Workflow Step Argument"; var WorkflowDescription: Text[250])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAllowRecordUsage(Variant: Variant; var RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetDescription(WorkflowStepArgument: Record "Workflow Step Argument"; WorkflowResponse: Record "Workflow Response"; var Result: Text[250])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddResponseToLibrary(FunctionName: Code[128]; Description: Text[250])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAllowRecordUsageDefault(var Variant: Variant; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateNotificationEntry(WorkflowStepInstance: Record "Workflow Step Instance"; ApprovalEntry: Record "Approval Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeExecuteResponse(var Variant: Variant; ResponseWorkflowStepInstance: Record "Workflow Step Instance"; xVariant: Variant; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsArgumentMandatory(ResponseFunctionName: Code[128]; var ArgumentMandatory: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReleaseDocument(var Variant: Variant)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOpenDocument(RecRef: RecordRef; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDocumentOnCaseElse(RecRef: RecordRef; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReleaseDocument(RecRef: RecordRef; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckIsArgumentMandatory(ResponseFunctionName: Code[128]; var ArgumentMandatory: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckHasRequiredArguments(WorkflowStep: Record "Workflow Step"; WorkflowStepArgument: Record "Workflow Step Argument"; var HasRequiredArgument: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowMessageOnBeforeShowMessage(WorkflowStepArgument: Record "Workflow Step Argument"; var SuppressMessage: Boolean);
    begin
    end;
}

