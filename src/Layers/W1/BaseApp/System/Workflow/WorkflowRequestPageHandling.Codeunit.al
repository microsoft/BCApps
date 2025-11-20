namespace System.Automation;

using Microsoft.EServices.EDocument;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Requisition;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;

codeunit 1522 "Workflow Request Page Handling"
{

    trigger OnRun()
    begin
    end;

    var
        PurchaseDocumentCodeTxt: Label 'PURCHDOC', Locked = true;
        PurchaseDocumentDescTxt: Label 'Purchase Document';
        SalesDocumentCodeTxt: Label 'SALESDOC', Locked = true;
        SalesDocumentDescTxt: Label 'Sales Document';
        IncomingDocumentCodeTxt: Label 'INCOMINGDOC', Locked = true;
        IncomingDocumentDescTxt: Label 'Incoming Document';

    procedure CreateEntitiesAndFields()
    begin
        InsertRequestPageEntities();
        InsertRequestPageFields();
    end;

    procedure AssignEntitiesToWorkflowEvents()
    begin
        AssignEntityToWorkflowEvent(DATABASE::"Purchase Header", PurchaseDocumentCodeTxt);
        AssignEntityToWorkflowEvent(DATABASE::"Sales Header", SalesDocumentCodeTxt);
        AssignEntityToWorkflowEvent(DATABASE::"Incoming Document Attachment", IncomingDocumentCodeTxt);
        AssignEntityToWorkflowEvent(DATABASE::"Incoming Document", IncomingDocumentCodeTxt);

        OnAfterAssignEntitiesToWorkflowEvents();
    end;

    local procedure InsertRequestPageEntities()
    begin
        InsertReqPageEntity(
          PurchaseDocumentCodeTxt, PurchaseDocumentDescTxt, DATABASE::"Purchase Header", DATABASE::"Purchase Line");
        InsertReqPageEntity(
          SalesDocumentCodeTxt, SalesDocumentDescTxt, DATABASE::"Sales Header", DATABASE::"Sales Line");
        InsertReqPageEntity(
          IncomingDocumentCodeTxt, IncomingDocumentDescTxt, DATABASE::"Incoming Document Attachment", DATABASE::"Incoming Document");
        InsertReqPageEntity(
          IncomingDocumentCodeTxt, IncomingDocumentDescTxt, DATABASE::"Incoming Document", DATABASE::"Incoming Document Attachment");

        OnAfterInsertRequestPageEntities();
    end;

    procedure InsertReqPageEntity(Name: Code[20]; Description: Text[100]; TableId: Integer; RelatedTableId: Integer)
    begin
        if not FindReqPageEntity(Name, TableId, RelatedTableId) then
            CreateReqPageEntity(Name, Description, TableId, RelatedTableId);
    end;

    local procedure FindReqPageEntity(Name: Code[20]; TableId: Integer; RelatedTableId: Integer): Boolean
    var
        DynamicRequestPageEntity: Record "Dynamic Request Page Entity";
    begin
        DynamicRequestPageEntity.SetRange(Name, Name);
        DynamicRequestPageEntity.SetRange("Table ID", TableId);
        DynamicRequestPageEntity.SetRange("Related Table ID", RelatedTableId);
        exit(DynamicRequestPageEntity.FindFirst());
    end;

    local procedure CreateReqPageEntity(Name: Code[20]; Description: Text[100]; TableId: Integer; RelatedTableId: Integer)
    var
        DynamicRequestPageEntity: Record "Dynamic Request Page Entity";
    begin
        DynamicRequestPageEntity.Init();
        DynamicRequestPageEntity.Name := Name;
        DynamicRequestPageEntity.Description := Description;
        DynamicRequestPageEntity.Validate("Table ID", TableId);
        DynamicRequestPageEntity.Validate("Related Table ID", RelatedTableId);
        DynamicRequestPageEntity.Insert(true);
    end;

    local procedure InsertRequestPageFields()
    begin
        InsertIncomingDocumentReqPageFields();

        InsertPurchaseHeaderReqPageFields();
        InsertPurchaseLineReqPageFields();

        InsertSalesHeaderReqPageFields();
        InsertSalesLineReqPageFields();

        InsertCustomerReqPageFields();
        InsertVendorReqPageFields();

        InsertItemReqPageFields();
        InsertGeneralJournalBatchReqPageFields();
        InsertGeneralJournalLineReqPageFields();

        InsertRequisitionWkshBatchReqPageFields();

        InsertApprovalEntryReqPageFields();

        OnAfterInsertRequestPageFields();
    end;

    local procedure InsertIncomingDocumentReqPageFields()
    var
        IncomingDocument: Record "Incoming Document";
    begin
        InsertDynReqPageField(DATABASE::"Incoming Document", IncomingDocument.FieldNo("Created By User ID"));
        InsertDynReqPageField(DATABASE::"Incoming Document", IncomingDocument.FieldNo(Posted));
        InsertDynReqPageField(DATABASE::"Incoming Document", IncomingDocument.FieldNo(Status));
    end;

    local procedure InsertPurchaseHeaderReqPageFields()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        InsertDynReqPageField(DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor No."));
        InsertDynReqPageField(DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Payment Terms Code"));
        InsertDynReqPageField(DATABASE::"Purchase Header", PurchaseHeader.FieldNo(Amount));
        InsertDynReqPageField(DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Currency Code"));
    end;

    local procedure InsertPurchaseLineReqPageFields()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        InsertDynReqPageField(DATABASE::"Purchase Line", PurchaseLine.FieldNo(Type));
        InsertDynReqPageField(DATABASE::"Purchase Line", PurchaseLine.FieldNo("No."));
        InsertDynReqPageField(DATABASE::"Purchase Line", PurchaseLine.FieldNo(Quantity));
        InsertDynReqPageField(DATABASE::"Purchase Line", PurchaseLine.FieldNo("Direct Unit Cost"));
    end;

    local procedure InsertSalesHeaderReqPageFields()
    var
        SalesHeader: Record "Sales Header";
    begin
        InsertDynReqPageField(DATABASE::"Sales Header", SalesHeader.FieldNo("Sell-to Customer No."));
        InsertDynReqPageField(DATABASE::"Sales Header", SalesHeader.FieldNo("Payment Terms Code"));
        InsertDynReqPageField(DATABASE::"Sales Header", SalesHeader.FieldNo(Amount));
        InsertDynReqPageField(DATABASE::"Sales Header", SalesHeader.FieldNo("Currency Code"));
    end;

    local procedure InsertSalesLineReqPageFields()
    var
        SalesLine: Record "Sales Line";
    begin
        InsertDynReqPageField(DATABASE::"Sales Line", SalesLine.FieldNo(Type));
        InsertDynReqPageField(DATABASE::"Sales Line", SalesLine.FieldNo("No."));
        InsertDynReqPageField(DATABASE::"Sales Line", SalesLine.FieldNo(Quantity));
        InsertDynReqPageField(DATABASE::"Sales Line", SalesLine.FieldNo("Unit Cost"));
    end;

    local procedure InsertCustomerReqPageFields()
    var
        Customer: Record Customer;
    begin
        InsertDynReqPageField(DATABASE::Customer, Customer.FieldNo("No."));
        InsertDynReqPageField(DATABASE::Customer, Customer.FieldNo(Blocked));
        InsertDynReqPageField(DATABASE::Customer, Customer.FieldNo("Credit Limit (LCY)"));
        InsertDynReqPageField(DATABASE::Customer, Customer.FieldNo("Payment Method Code"));
        InsertDynReqPageField(DATABASE::Customer, Customer.FieldNo("Gen. Bus. Posting Group"));
        InsertDynReqPageField(DATABASE::Customer, Customer.FieldNo("Customer Posting Group"));
    end;

    local procedure InsertItemReqPageFields()
    var
        Item: Record Item;
    begin
        InsertDynReqPageField(DATABASE::Item, Item.FieldNo("No."));
        InsertDynReqPageField(DATABASE::Item, Item.FieldNo("Item Category Code"));
        InsertDynReqPageField(DATABASE::Item, Item.FieldNo("Unit Price"));
    end;

    local procedure InsertGeneralJournalBatchReqPageFields()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        InsertDynReqPageField(DATABASE::"Gen. Journal Batch", GenJournalBatch.FieldNo(Name));
        InsertDynReqPageField(DATABASE::"Gen. Journal Batch", GenJournalBatch.FieldNo("Template Type"));
        InsertDynReqPageField(DATABASE::"Gen. Journal Batch", GenJournalBatch.FieldNo(Recurring));
    end;

    local procedure InsertGeneralJournalLineReqPageFields()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        InsertDynReqPageField(DATABASE::"Gen. Journal Line", GenJournalLine.FieldNo("Document Type"));
        InsertDynReqPageField(DATABASE::"Gen. Journal Line", GenJournalLine.FieldNo("Account Type"));
        InsertDynReqPageField(DATABASE::"Gen. Journal Line", GenJournalLine.FieldNo("Account No."));
        InsertDynReqPageField(DATABASE::"Gen. Journal Line", GenJournalLine.FieldNo(Amount));
    end;

    local procedure InsertRequisitionWkshBatchReqPageFields()
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        InsertDynReqPageField(Database::"Requisition Wksh. Name", RequisitionWkshName.FieldNo(Name));
        InsertDynReqPageField(Database::"Requisition Wksh. Name", RequisitionWkshName.FieldNo("Template Type"));
        InsertDynReqPageField(Database::"Requisition Wksh. Name", RequisitionWkshName.FieldNo(Recurring));
    end;

    local procedure InsertApprovalEntryReqPageFields()
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        InsertDynReqPageField(DATABASE::"Approval Entry", ApprovalEntry.FieldNo("Pending Approvals"));
    end;

    procedure InsertDynReqPageField(TableId: Integer; FieldId: Integer)
    var
        DynamicRequestPageField: Record "Dynamic Request Page Field";
    begin
        if not DynamicRequestPageField.Get(TableId, FieldId) then
            CreateReqPageField(TableId, FieldId);
    end;

    local procedure CreateReqPageField(TableId: Integer; FieldId: Integer)
    var
        DynamicRequestPageField: Record "Dynamic Request Page Field";
    begin
        DynamicRequestPageField.Init();
        DynamicRequestPageField.Validate("Table ID", TableId);
        DynamicRequestPageField.Validate("Field ID", FieldId);
        DynamicRequestPageField.Insert();
    end;

    procedure AssignEntityToWorkflowEvent(TableID: Integer; DynamicReqPageEntityName: Code[20])
    var
        WorkflowEvent: Record "Workflow Event";
    begin
        WorkflowEvent.SetRange("Table ID", TableID);
        WorkflowEvent.SetFilter("Dynamic Req. Page Entity Name", '<>%1', DynamicReqPageEntityName);
        if not WorkflowEvent.IsEmpty() then
            WorkflowEvent.ModifyAll("Dynamic Req. Page Entity Name", DynamicReqPageEntityName);
    end;

    local procedure InsertVendorReqPageFields()
    var
        Vendor: Record Vendor;
    begin
        InsertDynReqPageField(DATABASE::Vendor, Vendor.FieldNo("No."));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignEntitiesToWorkflowEvents()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertRequestPageEntities()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertRequestPageFields()
    begin
    end;
}

