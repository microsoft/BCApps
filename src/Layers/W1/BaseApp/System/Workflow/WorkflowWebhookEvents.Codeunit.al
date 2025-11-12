namespace System.Automation;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Requisition;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Upgrade;
using System.Upgrade;

codeunit 1541 "Workflow Webhook Events"
{

    trigger OnRun()
    begin
    end;

    var
        WorkflowWebhookResponseReceivedEventTxt: Label 'A response is received from a subscribed webhook.';

    procedure WorkflowWebhookResponseReceivedEventCode(): Code[128]
    begin
        exit('WORKFLOWWEBHOOKRESPONSERECEIVEDEVENT');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Event Handling", 'OnAddWorkflowEventPredecessorsToLibrary', '', false, false)]
    local procedure AddWorkflowWebhookEventHierarchiesToLibrary(EventFunctionName: Code[128])
    var
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
    begin
        case EventFunctionName of
            WorkflowWebhookResponseReceivedEventCode():
                begin
                    WorkflowEventHandling.AddEventPredecessor(WorkflowWebhookResponseReceivedEventCode(),
                      WorkflowEventHandling.RunWorkflowOnSendCustomerForApprovalCode());
                    WorkflowEventHandling.AddEventPredecessor(WorkflowWebhookResponseReceivedEventCode(),
                      WorkflowEventHandling.RunWorkflowOnSendGeneralJournalBatchForApprovalCode());
                    WorkflowEventHandling.AddEventPredecessor(WorkflowWebhookResponseReceivedEventCode(),
                      WorkflowEventHandling.RunWorkflowOnSendGeneralJournalLineForApprovalCode());
                    WorkflowEventHandling.AddEventPredecessor(WorkflowWebhookResponseReceivedEventCode(),
                      WorkflowEventHandling.RunWorkflowOnSendRequisitionWkshBatchForApprovalCode());
                    WorkflowEventHandling.AddEventPredecessor(WorkflowWebhookResponseReceivedEventCode(),
                      WorkflowEventHandling.RunWorkflowOnSendItemForApprovalCode());
                    WorkflowEventHandling.AddEventPredecessor(WorkflowWebhookResponseReceivedEventCode(),
                      WorkflowEventHandling.RunWorkflowOnSendPurchaseDocForApprovalCode());
                    WorkflowEventHandling.AddEventPredecessor(WorkflowWebhookResponseReceivedEventCode(),
                      WorkflowEventHandling.RunWorkflowOnSendSalesDocForApprovalCode());
                    WorkflowEventHandling.AddEventPredecessor(WorkflowWebhookResponseReceivedEventCode(),
                      WorkflowEventHandling.RunWorkflowOnSendVendorForApprovalCode());
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Event Handling", 'OnAddWorkflowEventsToLibrary', '', false, false)]
    local procedure AddWorkflowWebhookEventsToLibrary()
    var
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
    begin
        WorkflowEventHandling.AddEventToLibrary(WorkflowWebhookResponseReceivedEventCode(), DATABASE::"Workflow Webhook Entry",
          WorkflowWebhookResponseReceivedEventTxt, 0, false);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Event Handling", 'OnAddWorkflowTableRelationsToLibrary', '', false, false)]
    local procedure AddWorkflowWebhookTableRelationsToLibrary()
    var
        DummyCustomer: Record Customer;
        DummyItem: Record Item;
        DummyGenJournalBatch: Record "Gen. Journal Batch";
        DummyGenJournalLine: Record "Gen. Journal Line";
        DummyRequisitionWkshName: Record "Requisition Wksh. Name";
        DummyPurchaseHeader: Record "Purchase Header";
        DummySalesHeader: Record "Sales Header";
        DummyVendor: Record Vendor;
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        WorkflowSetup.InsertTableRelation(DATABASE::Customer, DummyCustomer.FieldNo(SystemId),
          DATABASE::"Workflow Webhook Entry", DummyWorkflowWebhookEntry.FieldNo("Data ID"));
        WorkflowSetup.InsertTableRelation(DATABASE::"Gen. Journal Batch", DummyGenJournalBatch.FieldNo(SystemId),
          DATABASE::"Workflow Webhook Entry", DummyWorkflowWebhookEntry.FieldNo("Data ID"));
        WorkflowSetup.InsertTableRelation(DATABASE::"Gen. Journal Line", DummyGenJournalLine.FieldNo(SystemId),
          DATABASE::"Workflow Webhook Entry", DummyWorkflowWebhookEntry.FieldNo("Data ID"));
        WorkflowSetup.InsertTableRelation(Database::"Requisition Wksh. Name", DummyRequisitionWkshName.FieldNo(SystemId),
          Database::"Workflow Webhook Entry", DummyWorkflowWebhookEntry.FieldNo("Data ID"));
        WorkflowSetup.InsertTableRelation(DATABASE::Item, DummyItem.FieldNo(SystemId),
          DATABASE::"Workflow Webhook Entry", DummyWorkflowWebhookEntry.FieldNo("Data ID"));
        WorkflowSetup.InsertTableRelation(DATABASE::"Purchase Header", DummyPurchaseHeader.FieldNo(SystemId),
          DATABASE::"Workflow Webhook Entry", DummyWorkflowWebhookEntry.FieldNo("Data ID"));
        WorkflowSetup.InsertTableRelation(DATABASE::"Sales Header", DummySalesHeader.FieldNo(SystemId),
          DATABASE::"Workflow Webhook Entry", DummyWorkflowWebhookEntry.FieldNo("Data ID"));
        WorkflowSetup.InsertTableRelation(DATABASE::Vendor, DummyVendor.FieldNo(SystemId),
          DATABASE::"Workflow Webhook Entry", DummyWorkflowWebhookEntry.FieldNo("Data ID"));

        CleanupOldIntegrationIdsTableRelation();
    end;

    procedure CleanupOldIntegrationIdsTableRelation()
    var
        DummyCustomer: Record Customer;
        DummyItem: Record Item;
        DummyGenJournalBatch: Record "Gen. Journal Batch";
        DummyGenJournalLine: Record "Gen. Journal Line";
        DummyRequisitionWkshName: Record "Requisition Wksh. Name";
        DummyPurchaseHeader: Record "Purchase Header";
        DummySalesHeader: Record "Sales Header";
        DummyVendor: Record Vendor;
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        CleanupIntegrationRecordTableRelation(DATABASE::Customer, DummyCustomer.FieldNo(SystemId), 8000, DATABASE::"Workflow Webhook Entry", DummyWorkflowWebhookEntry.FieldNo("Data ID"));
        CleanupIntegrationRecordTableRelation(DATABASE::"Gen. Journal Batch", DummyGenJournalBatch.FieldNo(SystemId), 8000, DATABASE::"Workflow Webhook Entry", DummyWorkflowWebhookEntry.FieldNo("Data ID"));
        CleanupIntegrationRecordTableRelation(DATABASE::"Gen. Journal Line", DummyGenJournalLine.FieldNo(SystemId), 8000, DATABASE::"Workflow Webhook Entry", DummyWorkflowWebhookEntry.FieldNo("Data ID"));
        CleanupIntegrationRecordTableRelation(Database::"Requisition Wksh. Name", DummyRequisitionWkshName.FieldNo(SystemId), 8000, Database::"Workflow Webhook Entry", DummyWorkflowWebhookEntry.FieldNo("Data ID"));
        CleanupIntegrationRecordTableRelation(DATABASE::Item, DummyItem.FieldNo(SystemId), 8000, DATABASE::"Workflow Webhook Entry", DummyWorkflowWebhookEntry.FieldNo("Data ID"));
        CleanupIntegrationRecordTableRelation(DATABASE::"Purchase Header", DummyPurchaseHeader.FieldNo(SystemId), 8000, DATABASE::"Workflow Webhook Entry", DummyWorkflowWebhookEntry.FieldNo("Data ID"));
        CleanupIntegrationRecordTableRelation(DATABASE::"Sales Header", DummySalesHeader.FieldNo(SystemId), 8000, DATABASE::"Workflow Webhook Entry", DummyWorkflowWebhookEntry.FieldNo("Data ID"));
        CleanupIntegrationRecordTableRelation(DATABASE::Vendor, DummyVendor.FieldNo(SystemId), 8000, DATABASE::"Workflow Webhook Entry", DummyWorkflowWebhookEntry.FieldNo("Data ID"));

        if not UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetRemoveOldWorkflowTableRelationshipRecordsTag()) then
            UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetRemoveOldWorkflowTableRelationshipRecordsTag());
    end;

    local procedure CleanupIntegrationRecordTableRelation(TableId: Integer; FieldId: Integer; OldFieldId: Integer; RelatedTableId: Integer; RelatedFieldId: Integer)
    var
        WorkflowTableRelation: Record "Workflow - Table Relation";
        OldWorkflowTableRelation: Record "Workflow - Table Relation";
    begin
        // Only cleanup old if the new field exists
        if not WorkflowTableRelation.Get(TableID, FieldId, RelatedTableId, RelatedFieldId) then
            exit;

        if not OldWorkflowTableRelation.Get(TableId, OldFieldId, RelatedTableId, RelatedFieldId) then
            exit;

        OldWorkflowTableRelation.Delete(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Webhook Management", 'OnCancelWorkflow', '', false, false)]
    local procedure HandleOnCancelWorkflow(WorkflowWebhookEntry: Record "Workflow Webhook Entry")
    var
        WorkflowManagement: Codeunit "Workflow Management";
    begin
        WorkflowManagement.HandleEvent(WorkflowWebhookResponseReceivedEventCode(), WorkflowWebhookEntry);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Webhook Management", 'OnContinueWorkflow', '', false, false)]
    local procedure HandleOnContinueWorkflow(WorkflowWebhookEntry: Record "Workflow Webhook Entry")
    var
        WorkflowManagement: Codeunit "Workflow Management";
    begin
        WorkflowManagement.HandleEvent(WorkflowWebhookResponseReceivedEventCode(), WorkflowWebhookEntry);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Webhook Management", 'OnRejectWorkflow', '', false, false)]
    local procedure HandleOnRejectWorkflow(WorkflowWebhookEntry: Record "Workflow Webhook Entry")
    var
        WorkflowManagement: Codeunit "Workflow Management";
    begin
        WorkflowManagement.HandleEvent(WorkflowWebhookResponseReceivedEventCode(), WorkflowWebhookEntry);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnCancelCustomerApprovalRequest', '', false, false)]
    local procedure HandleOnCancelCustomerApprovalRequest(var Customer: Record Customer)
    var
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // Handles the scenario when a Customer is deleted after it's been sent approval
        WorkflowWebhookManagement.FindAndCancel(Customer.RecordId);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnCancelItemApprovalRequest', '', false, false)]
    local procedure HandleOnCancelItemApprovalRequest(var Item: Record Item)
    var
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // Handles the scenario when an Item is deleted after it's been sent approval
        WorkflowWebhookManagement.FindAndCancel(Item.RecordId);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnCancelGeneralJournalBatchApprovalRequest', '', false, false)]
    local procedure HandleOnCancelGeneralJournalBatchApprovalRequest(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // Handles the scenario when a General Journal Batch is deleted after it's been sent approval
        WorkflowWebhookManagement.FindAndCancel(GenJournalBatch.RecordId, true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnCancelGeneralJournalLineApprovalRequest', '', false, false)]
    local procedure HandleOnCancelGeneralJournalLineApprovalRequest(var GenJournalLine: Record "Gen. Journal Line")
    var
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // Handles the scenario when a General Journal Line is deleted after it's been sent approval
        WorkflowWebhookManagement.FindAndCancel(GenJournalLine.RecordId, true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnCancelRequisitionWkshBatchApprovalRequest', '', false, false)]
    local procedure HandleOnCancelRequisitionWkshBatchApprovalRequest(var RequisitionWkshName: Record "Requisition Wksh. Name")
    var
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // Handles the scenario when a Requisition Worksheet Batch is deleted after it's been sent approval
        WorkflowWebhookManagement.FindAndCancel(RequisitionWkshName.RecordId(), true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnCancelVendorApprovalRequest', '', false, false)]
    local procedure HandleOnCancelVendorApprovalRequest(var Vendor: Record Vendor)
    var
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // Handles the scenario when a Vendor is deleted after it's been sent approval
        WorkflowWebhookManagement.FindAndCancel(Vendor.RecordId);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnDeleteRecordInApprovalRequest', '', false, false)]
    local procedure HandleOnDeleteRecordInApprovalRequest(RecordIDToApprove: RecordID)
    var
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        WorkflowWebhookManagement.DeleteWorkflowWebhookEntries(RecordIDToApprove);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnRenameRecordInApprovalRequest', '', false, false)]
    local procedure HandleOnRenameRecordInApprovalRequest(OldRecordId: RecordID; NewRecordId: RecordID)
    var
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        WorkflowWebhookManagement.RenameRecord(OldRecordId, NewRecordId);
    end;
}

