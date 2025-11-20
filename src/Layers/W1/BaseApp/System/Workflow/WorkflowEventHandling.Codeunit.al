namespace System.Automation;

using Microsoft.EServices.EDocument;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Preview;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Requisition;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Posting;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using System.Environment.Configuration;
using System.Threading;

codeunit 1520 "Workflow Event Handling"
{

    trigger OnRun()
    begin
    end;

    var
        WorkflowManagement: Codeunit "Workflow Management";

        IncDocReleasedEventDescTxt: Label 'An incoming document is released.';
        CreateDocFromIncDocSuccessfulEventDescTxt: Label 'Creating a document from an incoming document is successful.';
        CreateDocFromIncDocFailsEventDescTxt: Label 'Creating a document from an incoming document fails.';
        IncDocCreatedEventDescTxt: Label 'An incoming document is created.';
        IncDocIsReadyForOCREventDescTxt: Label 'An incoming document is ready for OCR.';
        IncDocIsSentForOCREventDescTxt: Label 'An incoming document is sent for OCR.';
        IncDocIsReceivedFromOCREventDescTxt: Label 'An incoming document is received from OCR.';
        IncDocIsReceivedFromDocExchEventDescTxt: Label 'An incoming document is received from document exchange.';
        IncDocSendForApprovalEventDescTxt: Label 'Approval of a incoming document is requested.';
        IncDocApprReqCancelledEventDescTxt: Label 'An approval request for an incoming document is canceled.';
        PurchDocSendForApprovalEventDescTxt: Label 'Approval of a purchase document is requested.';
        PurchDocApprReqCancelledEventDescTxt: Label 'An approval request for a purchase document is canceled.';
        PurchInvPostEventDescTxt: Label 'A purchase invoice is posted.';
        PurchDocReleasedEventDescTxt: Label 'A purchase document is released.';
        PurchInvPmtCreatedEventDescTxt: Label 'A general journal line is created.';
        ApprReqApprovedEventDescTxt: Label 'An approval request is approved.';
        ApprReqRejectedEventDescTxt: Label 'An approval request is rejected.';
        ApprReqDelegatedEventDescTxt: Label 'An approval request is delegated.';
        SalesDocSendForApprovalEventDescTxt: Label 'Approval of a sales document is requested.';
        SalesDocApprReqCancelledEventDescTxt: Label 'An approval request for a sales document is canceled.';
        SalesDocReleasedEventDescTxt: Label 'A sales document is released.';
#pragma warning disable AA0470
        EventAlreadyExistErr: Label 'An event with description %1 already exists.';
#pragma warning restore AA0470
        SendOverdueNotifTxt: Label 'The overdue approval notifications batch job will be run.';
        CustomerCreditLimitExceededTxt: Label 'A customer credit limit is exceeded.';
        CustomerCreditLimitNotExceededTxt: Label 'A customer credit limit is not exceeded.';
        CustomerSendForApprovalEventDescTxt: Label 'Approval of a customer is requested.';
        VendorSendForApprovalEventDescTxt: Label 'Approval of a vendor is requested.';
        ItemSendForApprovalEventDescTxt: Label 'Approval of an item is requested.';
        CustomerApprovalRequestCancelEventDescTxt: Label 'An approval request for a customer is canceled.';
        VendorApprovalRequestCancelEventDescTxt: Label 'An approval request for a vendor is canceled.';
        ItemApprovalRequestCancelEventDescTxt: Label 'An approval request for an item is canceled.';
        GeneralJournalBatchSendForApprovalEventDescTxt: Label 'Approval of a general journal batch is requested.';
        GeneralJournalBatchApprovalRequestCancelEventDescTxt: Label 'An approval request for a general journal batch is canceled.';
        GeneralJournalLineSendForApprovalEventDescTxt: Label 'Approval of a general journal line is requested.';
        GeneralJournalLineApprovalRequestCancelEventDescTxt: Label 'An approval request for a general journal line is canceled.';
        GeneralJournalBatchBalancedEventDescTxt: Label 'A general journal batch is balanced.';
        GeneralJournalBatchNotBalancedEventDescTxt: Label 'A general journal batch is not balanced.';
        ImageOrPDFIsAttachedToAnIncomingDocEventDescTxt: Label 'An image or pdf is attached to a new incoming document for OCR.';
        CustChangedTxt: Label 'A customer record is changed.';
        VendChangedTxt: Label 'A vendor record is changed.';
        ItemChangedTxt: Label 'An item record is changed.';
        CreateGenJnlLineFromIncDocSuccessfulEventDescTxt: Label 'The creation of a general journal line from the incoming document was successful.';
        CreateGenJnlLineFromIncDocFailsEventDescTxt: Label 'The creation of a general journal line from the incoming document failed.';
        JobQueueEntryApprovalEventDescTxt: Label 'Approval of a job queue entry is requested.';
        JobQueueEntryApprReqCancelledEventDescTxt: Label 'Approval of a job queue entry is cancelled.';
        RequisitionWkshBatchSendForApprovalEventDescTxt: Label 'An Approval request of a requisition worksheet batch is created.';
        RequisitionWkshBatchApprovalRequestCancelEventDescTxt: Label 'An approval request for a requisition worksheet batch is canceled.';

    procedure CreateEventsLibrary()
    begin
        AddEventToLibrary(
          RunWorkflowOnAfterInsertIncomingDocumentCode(), DATABASE::"Incoming Document", IncDocCreatedEventDescTxt, 0, false);
        AddEventToLibrary(
          RunWorkflowOnAfterReleaseIncomingDocCode(), DATABASE::"Incoming Document", IncDocReleasedEventDescTxt, 0, false);
        AddEventToLibrary(
          RunWorkflowOnAfterCreateDocFromIncomingDocSuccessCode(),
          DATABASE::"Incoming Document", CreateDocFromIncDocSuccessfulEventDescTxt, 0, false);
        AddEventToLibrary(
          RunWorkflowOnAfterCreateDocFromIncomingDocFailCode(), DATABASE::"Incoming Document", CreateDocFromIncDocFailsEventDescTxt, 0, false);
        AddEventToLibrary(
          RunWorkflowOnAfterReadyForOCRIncomingDocCode(), DATABASE::"Incoming Document", IncDocIsReadyForOCREventDescTxt, 0, false);
        AddEventToLibrary(
          RunWorkflowOnAfterSendToOCRIncomingDocCode(), DATABASE::"Incoming Document", IncDocIsSentForOCREventDescTxt, 0, false);
        AddEventToLibrary(
          RunWorkflowOnAfterReceiveFromOCRIncomingDocCode(), DATABASE::"Incoming Document", IncDocIsReceivedFromOCREventDescTxt, 0, false);
        AddEventToLibrary(
          RunWorkflowOnAfterReceiveFromDocExchIncomingDocCode(),
          DATABASE::"Incoming Document", IncDocIsReceivedFromDocExchEventDescTxt, 0, false);

        AddEventToLibrary(
          RunWorkflowOnSendPurchaseDocForApprovalCode(), DATABASE::"Purchase Header", PurchDocSendForApprovalEventDescTxt, 0, false);
        AddEventToLibrary(
          RunWorkflowOnSendIncomingDocForApprovalCode(), DATABASE::"Incoming Document", IncDocSendForApprovalEventDescTxt, 0, false);
        AddEventToLibrary(
          RunWorkflowOnCancelIncomingDocApprovalRequestCode(), DATABASE::"Incoming Document", IncDocApprReqCancelledEventDescTxt, 0, false);

        AddEventToLibrary(RunWorkflowOnCancelPurchaseApprovalRequestCode(), DATABASE::"Purchase Header",
          PurchDocApprReqCancelledEventDescTxt, 0, false);

        AddEventToLibrary(RunWorkflowOnAfterReleasePurchaseDocCode(), DATABASE::"Purchase Header",
          PurchDocReleasedEventDescTxt, 0, false);
        AddEventToLibrary(RunWorkflowOnAfterPostPurchaseDocCode(), DATABASE::"Purch. Inv. Header",
          PurchInvPostEventDescTxt, 0, false);

        AddEventToLibrary(RunWorkflowOnSendSalesDocForApprovalCode(), DATABASE::"Sales Header",
          SalesDocSendForApprovalEventDescTxt, 0, false);
        AddEventToLibrary(RunWorkflowOnCancelSalesApprovalRequestCode(), DATABASE::"Sales Header",
          SalesDocApprReqCancelledEventDescTxt, 0, false);
        AddEventToLibrary(RunWorkflowOnAfterReleaseSalesDocCode(), DATABASE::"Sales Header",
          SalesDocReleasedEventDescTxt, 0, false);

        AddEventToLibrary(RunWorkflowOnAfterInsertGeneralJournalLineCode(), DATABASE::"Gen. Journal Line",
          PurchInvPmtCreatedEventDescTxt, 0, false);

        AddEventToLibrary(RunWorkflowOnApproveApprovalRequestCode(), DATABASE::"Approval Entry", ApprReqApprovedEventDescTxt, 0, false);
        AddEventToLibrary(RunWorkflowOnRejectApprovalRequestCode(), DATABASE::"Approval Entry", ApprReqRejectedEventDescTxt, 0, false);
        AddEventToLibrary(RunWorkflowOnDelegateApprovalRequestCode(), DATABASE::"Approval Entry", ApprReqDelegatedEventDescTxt, 0, false);

        AddEventToLibrary(RunWorkflowOnSendOverdueNotificationsCode(), DATABASE::"Approval Entry", SendOverdueNotifTxt, 0, false);

        AddEventToLibrary(RunWorkflowOnCustomerCreditLimitExceededCode(), DATABASE::"Sales Header",
          CustomerCreditLimitExceededTxt, 0, false);
        AddEventToLibrary(RunWorkflowOnCustomerCreditLimitNotExceededCode(), DATABASE::"Sales Header",
          CustomerCreditLimitNotExceededTxt, 0, false);

        AddEventToLibrary(RunWorkflowOnSendCustomerForApprovalCode(), DATABASE::Customer,
          CustomerSendForApprovalEventDescTxt, 0, false);
        AddEventToLibrary(RunWorkflowOnCancelCustomerApprovalRequestCode(), DATABASE::Customer,
          CustomerApprovalRequestCancelEventDescTxt, 0, false);

        AddEventToLibrary(RunWorkflowOnSendVendorForApprovalCode(), DATABASE::Vendor,
          VendorSendForApprovalEventDescTxt, 0, false);
        AddEventToLibrary(RunWorkflowOnCancelVendorApprovalRequestCode(), DATABASE::Vendor,
          VendorApprovalRequestCancelEventDescTxt, 0, false);

        AddEventToLibrary(RunWorkflowOnSendItemForApprovalCode(), DATABASE::Item,
          ItemSendForApprovalEventDescTxt, 0, false);
        AddEventToLibrary(RunWorkflowOnCancelItemApprovalRequestCode(), DATABASE::Item,
          ItemApprovalRequestCancelEventDescTxt, 0, false);

        AddEventToLibrary(RunWorkflowOnSendGeneralJournalBatchForApprovalCode(), DATABASE::"Gen. Journal Batch",
          GeneralJournalBatchSendForApprovalEventDescTxt, 0, false);
        AddEventToLibrary(RunWorkflowOnCancelGeneralJournalBatchApprovalRequestCode(), DATABASE::"Gen. Journal Batch",
          GeneralJournalBatchApprovalRequestCancelEventDescTxt, 0, false);

        AddEventToLibrary(RunWorkflowOnSendGeneralJournalLineForApprovalCode(), DATABASE::"Gen. Journal Line",
          GeneralJournalLineSendForApprovalEventDescTxt, 0, false);
        AddEventToLibrary(RunWorkflowOnCancelGeneralJournalLineApprovalRequestCode(), DATABASE::"Gen. Journal Line",
          GeneralJournalLineApprovalRequestCancelEventDescTxt, 0, false);

        AddEventToLibrary(RunWorkflowOnGeneralJournalBatchBalancedCode(), DATABASE::"Gen. Journal Batch",
          GeneralJournalBatchBalancedEventDescTxt, 0, false);

        AddEventToLibrary(RunWorkflowOnGeneralJournalBatchNotBalancedCode(), DATABASE::"Gen. Journal Batch",
          GeneralJournalBatchNotBalancedEventDescTxt, 0, false);

        AddEventToLibrary(RunWorkflowOnSendRequisitionWkshBatchForApprovalCode(), Database::"Requisition Wksh. Name",
          RequisitionWkshBatchSendForApprovalEventDescTxt, 0, false);
        AddEventToLibrary(RunWorkflowOnCancelRequisitionWkshBatchApprovalRequestCode(), Database::"Requisition Wksh. Name",
          RequisitionWkshBatchApprovalRequestCancelEventDescTxt, 0, false);

        AddEventToLibrary(
          RunWorkflowOnBinaryFileAttachedCode(),
          DATABASE::"Incoming Document Attachment", ImageOrPDFIsAttachedToAnIncomingDocEventDescTxt, 0, false);

        AddEventToLibrary(RunWorkflowOnCustomerChangedCode(), DATABASE::Customer, CustChangedTxt, 0, true);
        AddEventToLibrary(RunWorkflowOnVendorChangedCode(), DATABASE::Vendor, VendChangedTxt, 0, true);
        AddEventToLibrary(RunWorkflowOnItemChangedCode(), DATABASE::Item, ItemChangedTxt, 0, true);

        AddEventToLibrary(
          RunWorkflowOnAfterCreateGenJnlLineFromIncomingDocSuccessCode(), DATABASE::"Incoming Document",
          CreateGenJnlLineFromIncDocSuccessfulEventDescTxt, 0, false);
        AddEventToLibrary(
          RunWorkflowOnAfterCreateGenJnlLineFromIncomingDocFailCode(), DATABASE::"Incoming Document",
          CreateGenJnlLineFromIncDocFailsEventDescTxt, 0, false);

        AddEventToLibrary(RunWorkflowOnSendJobQueueEntryForApprovalCode(), Database::"Job Queue Entry", JobQueueEntryApprovalEventDescTxt, 0, false);
        AddEventToLibrary(RunWorkflowOnCancelJobQueueEntryApprovalRequestCode(), Database::"Job Queue Entry", JobQueueEntryApprReqCancelledEventDescTxt, 0, false);

        OnAddWorkflowEventsToLibrary();
        OnAddWorkflowTableRelationsToLibrary();
    end;

    local procedure AddEventPredecessors(EventFunctionName: Code[128])
    begin
        case EventFunctionName of
            RunWorkflowOnAfterPostPurchaseDocCode():
                AddEventPredecessor(RunWorkflowOnAfterPostPurchaseDocCode(), RunWorkflowOnAfterReleasePurchaseDocCode());
            RunWorkflowOnCancelIncomingDocApprovalRequestCode():
                AddEventPredecessor(RunWorkflowOnCancelIncomingDocApprovalRequestCode(), RunWorkflowOnSendIncomingDocForApprovalCode());
            RunWorkflowOnCancelPurchaseApprovalRequestCode():
                AddEventPredecessor(RunWorkflowOnCancelPurchaseApprovalRequestCode(), RunWorkflowOnSendPurchaseDocForApprovalCode());
            RunWorkflowOnCancelSalesApprovalRequestCode():
                AddEventPredecessor(RunWorkflowOnCancelSalesApprovalRequestCode(), RunWorkflowOnSendSalesDocForApprovalCode());
            RunWorkflowOnCancelCustomerApprovalRequestCode():
                AddEventPredecessor(RunWorkflowOnCancelCustomerApprovalRequestCode(), RunWorkflowOnSendCustomerForApprovalCode());
            RunWorkflowOnCancelVendorApprovalRequestCode():
                AddEventPredecessor(RunWorkflowOnCancelVendorApprovalRequestCode(), RunWorkflowOnSendVendorForApprovalCode());
            RunWorkflowOnCancelItemApprovalRequestCode():
                AddEventPredecessor(RunWorkflowOnCancelItemApprovalRequestCode(), RunWorkflowOnSendItemForApprovalCode());
            RunWorkflowOnCancelGeneralJournalBatchApprovalRequestCode():
                AddEventPredecessor(RunWorkflowOnCancelGeneralJournalBatchApprovalRequestCode(),
                  RunWorkflowOnSendGeneralJournalBatchForApprovalCode());
            RunWorkflowOnCancelGeneralJournalLineApprovalRequestCode():
                AddEventPredecessor(RunWorkflowOnCancelGeneralJournalLineApprovalRequestCode(),
                  RunWorkflowOnSendGeneralJournalLineForApprovalCode());
            RunWorkflowOnCancelRequisitionWkshBatchApprovalRequestCode():
                AddEventPredecessor(RunWorkflowOnCancelRequisitionWkshBatchApprovalRequestCode(),
                  RunWorkflowOnSendRequisitionWkshBatchForApprovalCode());
            RunWorkflowOnCustomerCreditLimitExceededCode():
                AddEventPredecessor(RunWorkflowOnCustomerCreditLimitExceededCode(), RunWorkflowOnSendSalesDocForApprovalCode());
            RunWorkflowOnCustomerCreditLimitNotExceededCode():
                AddEventPredecessor(RunWorkflowOnCustomerCreditLimitNotExceededCode(), RunWorkflowOnSendSalesDocForApprovalCode());
            RunWorkflowOnApproveApprovalRequestCode():
                begin
                    AddEventPredecessor(RunWorkflowOnApproveApprovalRequestCode(), RunWorkflowOnSendIncomingDocForApprovalCode());
                    AddEventPredecessor(RunWorkflowOnApproveApprovalRequestCode(), RunWorkflowOnSendPurchaseDocForApprovalCode());
                    AddEventPredecessor(RunWorkflowOnApproveApprovalRequestCode(), RunWorkflowOnSendSalesDocForApprovalCode());
                    AddEventPredecessor(RunWorkflowOnApproveApprovalRequestCode(), RunWorkflowOnSendCustomerForApprovalCode());
                    AddEventPredecessor(RunWorkflowOnApproveApprovalRequestCode(), RunWorkflowOnSendVendorForApprovalCode());
                    AddEventPredecessor(RunWorkflowOnApproveApprovalRequestCode(), RunWorkflowOnSendItemForApprovalCode());
                    AddEventPredecessor(RunWorkflowOnApproveApprovalRequestCode(), RunWorkflowOnSendGeneralJournalBatchForApprovalCode());
                    AddEventPredecessor(RunWorkflowOnApproveApprovalRequestCode(), RunWorkflowOnGeneralJournalBatchBalancedCode());
                    AddEventPredecessor(RunWorkflowOnApproveApprovalRequestCode(), RunWorkflowOnSendGeneralJournalLineForApprovalCode());
                    AddEventPredecessor(RunWorkflowOnApproveApprovalRequestCode(), RunWorkflowOnSendRequisitionWkshBatchForApprovalCode());
                    AddEventPredecessor(RunWorkflowOnApproveApprovalRequestCode(), RunWorkflowOnCustomerChangedCode());
                    AddEventPredecessor(RunWorkflowOnApproveApprovalRequestCode(), RunWorkflowOnVendorChangedCode());
                    AddEventPredecessor(RunWorkflowOnApproveApprovalRequestCode(), RunWorkflowOnItemChangedCode());
                    AddEventPredecessor(RunWorkflowOnApproveApprovalRequestCode(), RunWorkflowOnSendJobQueueEntryForApprovalCode());
                end;
            RunWorkflowOnRejectApprovalRequestCode():
                begin
                    AddEventPredecessor(RunWorkflowOnRejectApprovalRequestCode(), RunWorkflowOnSendIncomingDocForApprovalCode());
                    AddEventPredecessor(RunWorkflowOnRejectApprovalRequestCode(), RunWorkflowOnSendPurchaseDocForApprovalCode());
                    AddEventPredecessor(RunWorkflowOnRejectApprovalRequestCode(), RunWorkflowOnSendSalesDocForApprovalCode());
                    AddEventPredecessor(RunWorkflowOnRejectApprovalRequestCode(), RunWorkflowOnSendCustomerForApprovalCode());
                    AddEventPredecessor(RunWorkflowOnRejectApprovalRequestCode(), RunWorkflowOnSendVendorForApprovalCode());
                    AddEventPredecessor(RunWorkflowOnRejectApprovalRequestCode(), RunWorkflowOnSendItemForApprovalCode());
                    AddEventPredecessor(RunWorkflowOnRejectApprovalRequestCode(), RunWorkflowOnSendGeneralJournalBatchForApprovalCode());
                    AddEventPredecessor(RunWorkflowOnRejectApprovalRequestCode(), RunWorkflowOnGeneralJournalBatchBalancedCode());
                    AddEventPredecessor(RunWorkflowOnRejectApprovalRequestCode(), RunWorkflowOnSendGeneralJournalLineForApprovalCode());
                    AddEventPredecessor(RunWorkflowOnRejectApprovalRequestCode(), RunWorkflowOnSendRequisitionWkshBatchForApprovalCode());
                    AddEventPredecessor(RunWorkflowOnRejectApprovalRequestCode(), RunWorkflowOnCustomerChangedCode());
                    AddEventPredecessor(RunWorkflowOnRejectApprovalRequestCode(), RunWorkflowOnVendorChangedCode());
                    AddEventPredecessor(RunWorkflowOnRejectApprovalRequestCode(), RunWorkflowOnItemChangedCode());
                    AddEventPredecessor(RunWorkflowOnRejectApprovalRequestCode(), RunWorkflowOnSendJobQueueEntryForApprovalCode());
                end;
            RunWorkflowOnDelegateApprovalRequestCode():
                begin
                    AddEventPredecessor(RunWorkflowOnDelegateApprovalRequestCode(), RunWorkflowOnSendIncomingDocForApprovalCode());
                    AddEventPredecessor(RunWorkflowOnDelegateApprovalRequestCode(), RunWorkflowOnSendPurchaseDocForApprovalCode());
                    AddEventPredecessor(RunWorkflowOnDelegateApprovalRequestCode(), RunWorkflowOnSendSalesDocForApprovalCode());
                    AddEventPredecessor(RunWorkflowOnDelegateApprovalRequestCode(), RunWorkflowOnSendCustomerForApprovalCode());
                    AddEventPredecessor(RunWorkflowOnDelegateApprovalRequestCode(), RunWorkflowOnSendVendorForApprovalCode());
                    AddEventPredecessor(RunWorkflowOnDelegateApprovalRequestCode(), RunWorkflowOnSendItemForApprovalCode());
                    AddEventPredecessor(RunWorkflowOnDelegateApprovalRequestCode(), RunWorkflowOnSendGeneralJournalBatchForApprovalCode());
                    AddEventPredecessor(RunWorkflowOnDelegateApprovalRequestCode(), RunWorkflowOnGeneralJournalBatchBalancedCode());
                    AddEventPredecessor(RunWorkflowOnDelegateApprovalRequestCode(), RunWorkflowOnSendGeneralJournalLineForApprovalCode());
                    AddEventPredecessor(RunWorkflowOnDelegateApprovalRequestCode(), RunWorkflowOnSendRequisitionWkshBatchForApprovalCode());
                    AddEventPredecessor(RunWorkflowOnDelegateApprovalRequestCode(), RunWorkflowOnCustomerChangedCode());
                    AddEventPredecessor(RunWorkflowOnDelegateApprovalRequestCode(), RunWorkflowOnVendorChangedCode());
                    AddEventPredecessor(RunWorkflowOnDelegateApprovalRequestCode(), RunWorkflowOnItemChangedCode());
                    AddEventPredecessor(RunWorkflowOnDelegateApprovalRequestCode(), RunWorkflowOnSendJobQueueEntryForApprovalCode());
                end;
            RunWorkflowOnGeneralJournalBatchBalancedCode():
                AddEventPredecessor(RunWorkflowOnGeneralJournalBatchBalancedCode(), RunWorkflowOnSendGeneralJournalBatchForApprovalCode());
            RunWorkflowOnGeneralJournalBatchNotBalancedCode():
                AddEventPredecessor(RunWorkflowOnGeneralJournalBatchNotBalancedCode(), RunWorkflowOnSendGeneralJournalBatchForApprovalCode());
            RunWorkflowOnCancelJobQueueEntryApprovalRequestCode():
                AddEventPredecessor(RunWorkflowOnCancelJobQueueEntryApprovalRequestCode(), RunWorkflowOnSendJobQueueEntryForApprovalCode());
        end;

        OnAddWorkflowEventPredecessorsToLibrary(EventFunctionName);
    end;

    procedure AddEventToLibrary(FunctionName: Code[128]; TableID: Integer; Description: Text[250]; RequestPageID: Integer; UsedForRecordChange: Boolean)
    var
        WorkflowEvent: Record "Workflow Event";
        SystemInitialization: Codeunit "System Initialization";
    begin
        OnBeforeAddEventToLibrary(FunctionName, Description);

        if WorkflowEvent.Get(FunctionName) then
            exit;

        WorkflowEvent.SetRange(Description, Description);
        if not WorkflowEvent.IsEmpty() then begin
            if SystemInitialization.IsInProgress() or (GetExecutionContext() <> ExecutionContext::Normal) then
                exit;
            Error(EventAlreadyExistErr, Description);
        end;

        WorkflowEvent.Init();
        WorkflowEvent."Function Name" := FunctionName;
        WorkflowEvent."Table ID" := TableID;
        WorkflowEvent.Description := Description;
        WorkflowEvent."Request Page ID" := RequestPageID;
        WorkflowEvent."Used for Record Change" := UsedForRecordChange;
        WorkflowEvent.Insert();

        AddEventPredecessors(WorkflowEvent."Function Name");
    end;

    procedure AddEventPredecessor(FunctionName: Code[128]; PredecessorFunctionName: Code[128])
    var
        WFEventResponseCombination: Record "WF Event/Response Combination";
    begin
        WFEventResponseCombination.Init();
        WFEventResponseCombination.Type := WFEventResponseCombination.Type::"Event";
        WFEventResponseCombination."Function Name" := FunctionName;
        WFEventResponseCombination."Predecessor Type" := WFEventResponseCombination."Predecessor Type"::"Event";
        WFEventResponseCombination."Predecessor Function Name" := PredecessorFunctionName;
        if WFEventResponseCombination.Insert() then;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddWorkflowEventsToLibrary()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddWorkflowEventPredecessorsToLibrary(EventFunctionName: Code[128])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddWorkflowTableRelationsToLibrary()
    begin
    end;

    procedure RunWorkflowOnAfterInsertIncomingDocumentCode(): Code[128]
    begin
        exit('RUNWORKFLOWONAFTERINSERTINCOMINGDOCUMENT');
    end;

    procedure RunWorkflowOnAfterReleaseIncomingDocCode(): Code[128]
    begin
        exit('RUNWORKFLOWONAFTERRELEASEINCOMINGDOC');
    end;

    procedure RunWorkflowOnAfterCreateDocFromIncomingDocSuccessCode(): Code[128]
    begin
        exit('RUNWORKFLOWONAFTERCREATEDOCFROMINCOMINGDOCSUCCESS');
    end;

    procedure RunWorkflowOnAfterCreateDocFromIncomingDocFailCode(): Code[128]
    begin
        exit('RUNWORKFLOWONAFTERCREATEDOCFROMINCOMINGDOCFAIL');
    end;

    procedure RunWorkflowOnAfterReadyForOCRIncomingDocCode(): Code[128]
    begin
        exit('RUNWORKFLOWONAFTERREADYFOROCRINCOMINGDOC');
    end;

    procedure RunWorkflowOnAfterSendToOCRIncomingDocCode(): Code[128]
    begin
        exit('RUNWORKFLOWONAFTERSENDTOOCRINCOMINGDOC');
    end;

    procedure RunWorkflowOnAfterReceiveFromOCRIncomingDocCode(): Code[128]
    begin
        exit('RUNWORKFLOWONAFTERRECEIVEFROMOCRINCOMINGDOC');
    end;

    procedure RunWorkflowOnAfterReceiveFromDocExchIncomingDocCode(): Code[128]
    begin
        exit('RUNWORKFLOWONAFTERRECEIVEFROMDOCEXCHINCOMINGDOC');
    end;

    procedure RunWorkflowOnSendPurchaseDocForApprovalCode(): Code[128]
    begin
        exit('RUNWORKFLOWONSENDPURCHASEDOCFORAPPROVAL');
    end;

    procedure RunWorkflowOnSendIncomingDocForApprovalCode(): Code[128]
    begin
        exit('RUNWORKFLOWONSENDINCOMINGDOCFORAPPROVAL');
    end;

    procedure RunWorkflowOnCancelIncomingDocApprovalRequestCode(): Code[128]
    begin
        exit('RUNWORKFLOWONCANCELINCOMINGDOCAPPROVALREQUEST');
    end;

    procedure RunWorkflowOnCancelPurchaseApprovalRequestCode(): Code[128]
    begin
        exit('RUNWORKFLOWONCANCELPURCHASEAPPROVALREQUEST');
    end;

    procedure RunWorkflowOnAfterReleasePurchaseDocCode(): Code[128]
    begin
        exit('RUNWORKFLOWONAFTERRELEASEPURCHASEDOC');
    end;

    procedure RunWorkflowOnSendSalesDocForApprovalCode(): Code[128]
    begin
        exit('RUNWORKFLOWONSENDSALESDOCFORAPPROVAL');
    end;

    procedure RunWorkflowOnCancelSalesApprovalRequestCode(): Code[128]
    begin
        exit('RUNWORKFLOWONCANCELSALESAPPROVALREQUEST');
    end;

    procedure RunWorkflowOnAfterReleaseSalesDocCode(): Code[128]
    begin
        exit('RUNWORKFLOWONAFTERRELEASESALESDOC');
    end;

    procedure RunWorkflowOnAfterPostPurchaseDocCode(): Code[128]
    begin
        exit('RUNWORKFLOWONAFTERPOSTPURCHASEDOC');
    end;

    procedure RunWorkflowOnAfterInsertGeneralJournalLineCode(): Code[128]
    begin
        exit('RUNWORKFLOWONAFTERINSERTGENERALJOURNALLINE');
    end;

    procedure RunWorkflowOnApproveApprovalRequestCode(): Code[128]
    begin
        exit('RUNWORKFLOWONAPPROVEAPPROVALREQUEST');
    end;

    procedure RunWorkflowOnDelegateApprovalRequestCode(): Code[128]
    begin
        exit('RUNWORKFLOWONDELEGATEAPPROVALREQUEST');
    end;

    procedure RunWorkflowOnRejectApprovalRequestCode(): Code[128]
    begin
        exit('RUNWORKFLOWONREJECTAPPROVALREQUEST');
    end;

    procedure RunWorkflowOnSendOverdueNotificationsCode(): Code[128]
    begin
        exit('RUNWORKFLOWONSENDOVERDUENOTIFICATIONS');
    end;

    procedure RunWorkflowOnCustomerCreditLimitExceededCode(): Code[128]
    begin
        exit('RUNWORKFLOWONCUSTOMERCREDITLIMITEXCEEDED');
    end;

    procedure RunWorkflowOnCustomerCreditLimitNotExceededCode(): Code[128]
    begin
        exit('RUNWORKFLOWONCUSTOMERCREDITLIMITNOTEXCEEDED');
    end;

    procedure RunWorkflowOnSendCustomerForApprovalCode(): Code[128]
    begin
        exit('RUNWORKFLOWONSENDCUSTOMERFORAPPROVAL');
    end;

    procedure RunWorkflowOnSendVendorForApprovalCode(): Code[128]
    begin
        exit('RUNWORKFLOWONSENDVENDORFORAPPROVAL');
    end;

    procedure RunWorkflowOnSendItemForApprovalCode(): Code[128]
    begin
        exit('RUNWORKFLOWONSENDITEMFORAPPROVAL');
    end;

    procedure RunWorkflowOnCancelCustomerApprovalRequestCode(): Code[128]
    begin
        exit('RUNWORKFLOWONCANCELCUSTOMERAPPROVALREQUEST');
    end;

    procedure RunWorkflowOnCancelVendorApprovalRequestCode(): Code[128]
    begin
        exit('RUNWORKFLOWONCANCELVENDORAPPROVALREQUEST');
    end;

    procedure RunWorkflowOnCancelItemApprovalRequestCode(): Code[128]
    begin
        exit('RUNWORKFLOWONCANCELITEMAPPROVALREQUEST');
    end;

    procedure RunWorkflowOnSendGeneralJournalBatchForApprovalCode(): Code[128]
    begin
        exit('RUNWORKFLOWONSENDGENERALJOURNALBATCHFORAPPROVAL');
    end;

    procedure RunWorkflowOnCancelGeneralJournalBatchApprovalRequestCode(): Code[128]
    begin
        exit('RUNWORKFLOWONCANCELGENERALJOURNALBATCHAPPROVALREQUEST');
    end;

    procedure RunWorkflowOnSendGeneralJournalLineForApprovalCode(): Code[128]
    begin
        exit('RUNWORKFLOWONSENDGENERALJOURNALLINEFORAPPROVAL');
    end;

    procedure RunWorkflowOnCancelGeneralJournalLineApprovalRequestCode(): Code[128]
    begin
        exit('RUNWORKFLOWONCANCELGENERALJOURNALLINEAPPROVALREQUEST');
    end;

    procedure RunWorkflowOnGeneralJournalBatchBalancedCode(): Code[128]
    begin
        exit('RUNWORKFLOWONGENERALJOURNALBATCHBALANCED');
    end;

    procedure RunWorkflowOnGeneralJournalBatchNotBalancedCode(): Code[128]
    begin
        exit('RUNWORKFLOWONGENERALJOURNALBATCHNOTBALANCED');
    end;

    procedure RunWorkflowOnSendRequisitionWkshBatchForApprovalCode(): Code[128]
    begin
        exit('RUNWORKFLOWONSENDREQUISITIONWORKSHEETBATCHFORAPPROVAL');
    end;

    procedure RunWorkflowOnCancelRequisitionWkshBatchApprovalRequestCode(): Code[128]
    begin
        exit('RUNWORKFLOWONCANCELAREQUISITIONWORKSHEETBATCHAPPROVALREQUEST');
    end;

    procedure RunWorkflowOnBinaryFileAttachedCode(): Code[128]
    begin
        exit('RUNWORKFLOWONBINARYFILEATTACHED');
    end;

    procedure RunWorkflowOnCustomerChangedCode(): Code[128]
    begin
        exit('RUNWORKFLOWONCUSTOMERCHANGEDCODE');
    end;

    procedure RunWorkflowOnVendorChangedCode(): Code[128]
    begin
        exit('RUNWORKFLOWONVENDORCHANGEDCODE');
    end;

    procedure RunWorkflowOnItemChangedCode(): Code[128]
    begin
        exit('RUNWORKFLOWONITEMCHANGEDCODE');
    end;

    procedure RunWorkflowOnAfterCreateGenJnlLineFromIncomingDocSuccessCode(): Code[128]
    begin
        exit('RUNWORKFLOWONAFTERCREATEGENJNLLINEFROMINCOMINGDOCSUCCESSCODE');
    end;

    procedure RunWorkflowOnAfterCreateGenJnlLineFromIncomingDocFailCode(): Code[128]
    begin
        exit('RUNWORKFLOWONAFTERCREATEGENJNLLINEFROMINCOMINGDOFAILCODE');
    end;

    procedure RunWorkflowOnSendJobQueueEntryForApprovalCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnSendJobQueueEntryForApproval'));
    end;

    procedure RunWorkflowOnCancelJobQueueEntryApprovalRequestCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnCancelJobQueueEntryApprovalRequest'));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Incoming Document", 'OnAfterInsertEvent', '', false, false)]
    procedure RunWorkflowOnAfterInsertIncomingDocument(var Rec: Record "Incoming Document"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        WorkflowManagement.HandleEvent(RunWorkflowOnAfterInsertIncomingDocumentCode(), Rec);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnSendPurchaseDocForApproval', '', false, false)]
    procedure RunWorkflowOnSendPurchaseDocForApproval(var PurchaseHeader: Record "Purchase Header")
    begin
        OnBeforeRunWorkflowOnSendPurchaseDocForApproval(PurchaseHeader);
        WorkflowManagement.HandleEvent(RunWorkflowOnSendPurchaseDocForApprovalCode(), PurchaseHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnCancelPurchaseApprovalRequest', '', false, false)]
    procedure RunWorkflowOnCancelPurchaseApprovalRequest(var PurchaseHeader: Record "Purchase Header")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnCancelPurchaseApprovalRequestCode(), PurchaseHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnSendIncomingDocForApproval', '', false, false)]
    procedure RunWorkflowOnSendIncomingDocForApproval(var IncomingDocument: Record "Incoming Document")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnSendIncomingDocForApprovalCode(), IncomingDocument);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnCancelIncomingDocApprovalRequest', '', false, false)]
    procedure RunWorkflowOnCancelIncomingDocApprovalRequest(var IncomingDocument: Record "Incoming Document")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnCancelIncomingDocApprovalRequestCode(), IncomingDocument);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Purchase Document", 'OnAfterReleasePurchaseDoc', '', false, false)]
    procedure RunWorkflowOnAfterReleasePurchaseDoc(var PurchaseHeader: Record "Purchase Header"; PreviewMode: Boolean)
    begin
        if not PreviewMode then
            WorkflowManagement.HandleEvent(RunWorkflowOnAfterReleasePurchaseDocCode(), PurchaseHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnSendSalesDocForApproval', '', false, false)]
    procedure RunWorkflowOnSendSalesDocForApproval(var SalesHeader: Record "Sales Header")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnSendSalesDocForApprovalCode(), SalesHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnCancelSalesApprovalRequest', '', false, false)]
    procedure RunWorkflowOnCancelSalesApprovalRequest(var SalesHeader: Record "Sales Header")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnCancelSalesApprovalRequestCode(), SalesHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Sales Document", 'OnAfterReleaseSalesDoc', '', false, false)]
    procedure RunWorkflowOnAfterReleaseSalesDoc(var SalesHeader: Record "Sales Header"; PreviewMode: Boolean)
    begin
        if not PreviewMode then
            WorkflowManagement.HandleEvent(RunWorkflowOnAfterReleaseSalesDocCode(), SalesHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Incoming Document", 'OnAfterReleaseIncomingDoc', '', false, false)]
    procedure RunWorkflowOnAfterReleaseIncomingDoc(var IncomingDocument: Record "Incoming Document")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnAfterReleaseIncomingDocCode(), IncomingDocument);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Incoming Document", 'OnAfterCreateDocFromIncomingDocSuccess', '', false, false)]
    procedure RunWorkflowOnAfterCreateDocFromIncomingDocSuccess(var IncomingDocument: Record "Incoming Document")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnAfterCreateDocFromIncomingDocSuccessCode(), IncomingDocument);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Incoming Document", 'OnAfterCreateDocFromIncomingDocFail', '', false, false)]
    procedure RunWorkflowOnAfterCreateDocFromIncomingDocFail(var IncomingDocument: Record "Incoming Document")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnAfterCreateDocFromIncomingDocFailCode(), IncomingDocument);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Send Incoming Document to OCR", 'OnAfterIncomingDocReadyForOCR', '', false, false)]
    procedure RunWorkflowOnAfterIncomingDocReadyForOCR(var IncomingDocument: Record "Incoming Document")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnAfterReadyForOCRIncomingDocCode(), IncomingDocument);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Send Incoming Document to OCR", 'OnAfterIncomingDocSentToOCR', '', false, false)]
    procedure RunWorkflowOnAfterIncomingDocSentToOCR(var IncomingDocument: Record "Incoming Document")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnAfterSendToOCRIncomingDocCode(), IncomingDocument);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Send Incoming Document to OCR", 'OnAfterIncomingDocReceivedFromOCR', '', false, false)]
    procedure RunWorkflowOnAfterIncomingDocReceivedFromOCR(var IncomingDocument: Record "Incoming Document")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnAfterReceiveFromOCRIncomingDocCode(), IncomingDocument);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Doc. Exch. Service Mgt.", 'OnAfterIncomingDocReceivedFromDocExch', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnAfterIncomingDocReceivedFromDocExch(var IncomingDocument: Record "Incoming Document")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnAfterReceiveFromDocExchIncomingDocCode(), IncomingDocument);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterPostPurchaseDoc', '', false, false)]
    procedure RunWorkflowOnAfterPostPurchaseDoc(var PurchaseHeader: Record "Purchase Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PurchRcpHdrNo: Code[20]; RetShptHdrNo: Code[20]; PurchInvHdrNo: Code[20]; PurchCrMemoHdrNo: Code[20])
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        case PurchaseHeader."Document Type" of
            PurchaseHeader."Document Type"::Order, PurchaseHeader."Document Type"::Invoice:
                if PurchInvHeader.Get(PurchInvHdrNo) then
                    WorkflowManagement.HandleEvent(RunWorkflowOnAfterPostPurchaseDocCode(), PurchInvHeader);
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterInsertEvent', '', false, false)]
    procedure RunWorkflowOnAfterInsertGeneralJournalLine(var Rec: Record "Gen. Journal Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        WorkflowManagement.HandleEvent(RunWorkflowOnAfterInsertGeneralJournalLineCode(), Rec);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnApproveApprovalRequest', '', false, false)]
    procedure RunWorkflowOnApproveApprovalRequest(var ApprovalEntry: Record "Approval Entry")
    begin
        OnBeforeRunWorkflowOnApproveApprovalRequest(ApprovalEntry);

        WorkflowManagement.HandleEventOnKnownWorkflowInstance(RunWorkflowOnApproveApprovalRequestCode(),
          ApprovalEntry, ApprovalEntry."Workflow Step Instance ID");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnDelegateApprovalRequest', '', false, false)]
    procedure RunWorkflowOnDelegateApprovalRequest(var ApprovalEntry: Record "Approval Entry")
    begin
        WorkflowManagement.HandleEventOnKnownWorkflowInstance(RunWorkflowOnDelegateApprovalRequestCode(),
          ApprovalEntry, ApprovalEntry."Workflow Step Instance ID");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnRejectApprovalRequest', '', false, false)]
    procedure RunWorkflowOnRejectApprovalRequest(var ApprovalEntry: Record "Approval Entry")
    begin
        WorkflowManagement.HandleEventOnKnownWorkflowInstance(RunWorkflowOnRejectApprovalRequestCode(),
          ApprovalEntry, ApprovalEntry."Workflow Step Instance ID");
    end;

    [EventSubscriber(ObjectType::Report, Report::"Send Overdue Appr. Notif.", 'OnSendOverdueNotifications', '', false, false)]
    procedure RunWorkflowOnSendOverdueNotifications()
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        ApprovalEntry.SetFilter(Status, '%1|%2', ApprovalEntry.Status::Created, ApprovalEntry.Status::Open);
        ApprovalEntry.SetFilter("Due Date", '<%1', Today);
        if not ApprovalEntry.FindSet() then
            ApprovalEntry.Init();

        WorkflowManagement.HandleEvent(RunWorkflowOnSendOverdueNotificationsCode(), ApprovalEntry);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnCustomerCreditLimitExceeded', '', false, false)]
    procedure RunWorkflowOnCustomerCreditLimitExceeded(var Sender: Record "Sales Header")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnCustomerCreditLimitExceededCode(), Sender);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnCustomerCreditLimitNotExceeded', '', false, false)]
    procedure RunWorkflowOnCustomerCreditLimitNotExceeded(var Sender: Record "Sales Header")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnCustomerCreditLimitNotExceededCode(), Sender);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnSendCustomerForApproval', '', false, false)]
    procedure RunWorkflowOnSendCustomerForApproval(Customer: Record Customer)
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnSendCustomerForApprovalCode(), Customer);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnSendVendorForApproval', '', false, false)]
    procedure RunWorkflowOnSendVendorForApproval(Vendor: Record Vendor)
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnSendVendorForApprovalCode(), Vendor);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnSendItemForApproval', '', false, false)]
    procedure RunWorkflowOnSendItemForApproval(Item: Record Item)
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnSendItemForApprovalCode(), Item);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnCancelCustomerApprovalRequest', '', false, false)]
    procedure RunWorkflowOnCancelCustomerApprovalRequest(Customer: Record Customer)
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnCancelCustomerApprovalRequestCode(), Customer);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnCancelVendorApprovalRequest', '', false, false)]
    procedure RunWorkflowOnCancelVendorApprovalRequest(Vendor: Record Vendor)
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnCancelVendorApprovalRequestCode(), Vendor);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnCancelItemApprovalRequest', '', false, false)]
    procedure RunWorkflowOnCancelItemApprovalRequest(Item: Record Item)
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnCancelItemApprovalRequestCode(), Item);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnSendGeneralJournalBatchForApproval', '', false, false)]
    procedure RunWorkflowOnSendGeneralJournalBatchForApproval(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnSendGeneralJournalBatchForApprovalCode(), GenJournalBatch);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnCancelGeneralJournalBatchApprovalRequest', '', false, false)]
    procedure RunWorkflowOnCancelGeneralJournalBatchApprovalRequest(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnCancelGeneralJournalBatchApprovalRequestCode(), GenJournalBatch);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnSendGeneralJournalLineForApproval', '', false, false)]
    procedure RunWorkflowOnSendGeneralJournalLineForApproval(var GenJournalLine: Record "Gen. Journal Line")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnSendGeneralJournalLineForApprovalCode(), GenJournalLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnCancelGeneralJournalLineApprovalRequest', '', false, false)]
    procedure RunWorkflowOnCancelGeneralJournalLineApprovalRequest(var GenJournalLine: Record "Gen. Journal Line")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnCancelGeneralJournalLineApprovalRequestCode(), GenJournalLine);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Batch", 'OnGeneralJournalBatchBalanced', '', false, false)]
    procedure RunWorkflowOnGeneralJournalBatchBalanced(var Sender: Record "Gen. Journal Batch")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnGeneralJournalBatchBalancedCode(), Sender);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Batch", 'OnGeneralJournalBatchNotBalanced', '', false, false)]
    procedure RunWorkflowOnGeneralJournalBatchNotBalanced(var Sender: Record "Gen. Journal Batch")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnGeneralJournalBatchNotBalancedCode(), Sender);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnSendRequisitionWkshBatchForApproval', '', false, false)]
    procedure RunWorkflowOnSendRequisitionWkshBatchForApproval(var RequisitionWkshName: Record "Requisition Wksh. Name")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnSendRequisitionWkshBatchForApprovalCode(), RequisitionWkshName);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnCancelRequisitionWkshBatchApprovalRequest', '', false, false)]
    procedure RunWorkflowOnCancelRequisitionWkshBatchApprovalRequest(var RequisitionWkshName: Record "Requisition Wksh. Name")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnCancelRequisitionWkshBatchApprovalRequestCode(), RequisitionWkshName);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Incoming Document Attachment", 'OnAttachBinaryFile', '', false, false)]
    [Scope('OnPrem')]
    procedure RunWorkflowOnBinaryFileAttached(var Sender: Record "Incoming Document Attachment")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnBinaryFileAttachedCode(), Sender);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Customer", 'OnAfterModifyEvent', '', false, false)]
    procedure RunWorkflowOnCustomerChanged(var Rec: Record Customer; var xRec: Record Customer; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        if Format(xRec) <> Format(Rec) then
            WorkflowManagement.HandleEventWithxRec(RunWorkflowOnCustomerChangedCode(), Rec, xRec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Customer", 'OnAfterRenameEvent', '', false, false)]
    local procedure RunWorkflowOnCustomerRenamed(var Rec: Record Customer; var xRec: Record Customer; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        if Format(xRec) <> Format(Rec) then
            WorkflowManagement.HandleEventWithxRec(RunWorkflowOnCustomerChangedCode(), Rec, xRec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Vendor", 'OnAfterModifyEvent', '', false, false)]
    procedure RunWorkflowOnVendorChanged(var Rec: Record Vendor; var xRec: Record Vendor; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        if Format(xRec) <> Format(Rec) then
            WorkflowManagement.HandleEventWithxRec(RunWorkflowOnVendorChangedCode(), Rec, xRec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Vendor", 'OnAfterRenameEvent', '', false, false)]
    local procedure RunWorkflowOnVendorRenamed(var Rec: Record Vendor; var xRec: Record Vendor; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        if Format(xRec) <> Format(Rec) then
            WorkflowManagement.HandleEventWithxRec(RunWorkflowOnVendorChangedCode(), Rec, xRec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item", 'OnAfterModifyEvent', '', false, false)]
    procedure RunWorkflowOnItemChanged(var Rec: Record Item; var xRec: Record Item; RunTrigger: Boolean)
    var
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
    begin
        if Rec.IsTemporary() then
            exit;

        if GenJnlPostPreview.IsActive() then
            exit;

        if Format(xRec) <> Format(Rec) then
            WorkflowManagement.HandleEventWithxRec(RunWorkflowOnItemChangedCode(), Rec, xRec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item", 'OnAfterRenameEvent', '', false, false)]
    local procedure RunWorkflowOnItemRenamed(var Rec: Record Item; var xRec: Record Item; RunTrigger: Boolean)
    var
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
    begin
        if Rec.IsTemporary() then
            exit;

        if GenJnlPostPreview.IsActive() then
            exit;

        if Format(xRec) <> Format(Rec) then
            WorkflowManagement.HandleEventWithxRec(RunWorkflowOnItemChangedCode(), Rec, xRec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Incoming Document", 'OnAfterCreateGenJnlLineFromIncomingDocSuccess', '', false, false)]
    procedure RunWorkflowOnAfterCreateGenJnlLineFromIncomingDocSuccess(var IncomingDocument: Record "Incoming Document")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnAfterCreateGenJnlLineFromIncomingDocSuccessCode(), IncomingDocument);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Incoming Document", 'OnAfterCreateGenJnlLineFromIncomingDocFail', '', false, false)]
    procedure RunWorkflowOnAfterCreateGenJnlLineFromIncomingDocFail(var IncomingDocument: Record "Incoming Document")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnAfterCreateGenJnlLineFromIncomingDocFailCode(), IncomingDocument);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddEventToLibrary(FunctionName: Code[128]; Description: Text[250])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunWorkflowOnSendPurchaseDocForApproval(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnSendJobQueueEntryForApproval', '', true, true)]
    local procedure RunWorkflowOnOnSendJobQueueEntryForApproval(var JobQueueEntry: Record "Job Queue Entry")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnSendJobQueueEntryForApprovalCode(), JobQueueEntry);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnCancelJobQueueEntryApprovalRequest', '', true, true)]
    local procedure RunWorkflowOnCancelJobQueueEntryApprovalRequest(var JobQueueEntry: Record "Job Queue Entry")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnCancelJobQueueEntryApprovalRequestCode(), JobQueueEntry);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunWorkflowOnApproveApprovalRequest(var ApprovalEntry: Record "Approval Entry")
    begin
    end;

}

