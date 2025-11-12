namespace System.Automation;

using Microsoft.EServices.EDocument;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Requisition;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using System.Threading;
using System.Xml;

codeunit 1502 "Workflow Setup"
{

    trigger OnRun()
    begin
    end;

    var
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        WorkflowRequestPageHandling: Codeunit "Workflow Request Page Handling";
        BlankDateFormula: DateFormula;
        CustomTemplateToken: Code[3];
        MsTemplateTok: Label 'MS-', Locked = true;
        MsWizardWorkflowTok: Label 'WZ-', Locked = true;
        JobQueueEntryDescTxt: Label 'Auto-created for sending of delegated approval requests. Can be deleted if not used. Will be recreated when the feature is activated.';
        PurchInvWorkflowCodeTxt: Label 'PIW', Locked = true;
        PurchInvWorkflowDescriptionTxt: Label 'Purchase Invoice Workflow';
        IncDocOCRWorkflowCodeTxt: Label 'INCDOC-OCR', Locked = true;
        IncDocOCRWorkflowDescriptionTxt: Label 'Incoming Document OCR Workflow';
        IncDocToGenJnlLineOCRWorkflowCodeTxt: Label 'INCDOC-JNL-OCR', Locked = true;
        IncDocToGenJnlLineOCRWorkflowDescriptionTxt: Label 'Incoming Document to General Journal Line OCR Workflow';
        IncDocExchWorkflowCodeTxt: Label 'INCDOC-DOCEXCH', Locked = true;
        IncDocExchWorkflowDescriptionTxt: Label 'Incoming Document Exchange Workflow';
        IncDocWorkflowCodeTxt: Label 'INCDOC', Locked = true;
        IncDocWorkflowDescTxt: Label 'Incoming Document Workflow';
        IncomingDocumentApprWorkflowCodeTxt: Label 'INCDOCAPW', Locked = true;
        PurchInvoiceApprWorkflowCodeTxt: Label 'PIAPW', Locked = true;
        PurchReturnOrderApprWorkflowCodeTxt: Label 'PROAPW', Locked = true;
        PurchQuoteApprWorkflowCodeTxt: Label 'PQAPW', Locked = true;
        PurchOrderApprWorkflowCodeTxt: Label 'POAPW', Locked = true;
        PurchCreditMemoApprWorkflowCodeTxt: Label 'PCMAPW', Locked = true;
        PurchBlanketOrderApprWorkflowCodeTxt: Label 'BPOAPW', Locked = true;
        IncomingDocumentApprWorkflowDescTxt: Label 'Incoming Document Approval Workflow';
        PurchInvoiceApprWorkflowDescTxt: Label 'Purchase Invoice Approval Workflow';
        PurchReturnOrderApprWorkflowDescTxt: Label 'Purchase Return Order Approval Workflow';
        PurchQuoteApprWorkflowDescTxt: Label 'Purchase Quote Approval Workflow';
        PurchOrderApprWorkflowDescTxt: Label 'Purchase Order Approval Workflow';
        PurchCreditMemoApprWorkflowDescTxt: Label 'Purchase Credit Memo Approval Workflow';
        PurchBlanketOrderApprWorkflowDescTxt: Label 'Blanket Purchase Order Approval Workflow';
        PendingApprovalsCondnTxt: Label '<?xml version="1.0" encoding="utf-8" standalone="yes"?><ReportParameters><DataItems><DataItem name="Approval Entry">%1</DataItem></DataItems></ReportParameters>', Locked = true;
        PurchHeaderTypeCondnTxt: Label '<?xml version="1.0" encoding="utf-8" standalone="yes"?><ReportParameters><DataItems><DataItem name="Purchase Header">%1</DataItem><DataItem name="Purchase Line">%2</DataItem></DataItems></ReportParameters>', Locked = true;
        SalesHeaderTypeCondnTxt: Label '<?xml version="1.0" encoding="utf-8" standalone="yes"?><ReportParameters><DataItems><DataItem name="Sales Header">%1</DataItem><DataItem name="Sales Line">%2</DataItem></DataItems></ReportParameters>', Locked = true;
        IncomingDocumentTypeCondnTxt: Label '<?xml version="1.0" encoding="utf-8" standalone="yes"?><ReportParameters><DataItems><DataItem name="Incoming Document">%1</DataItem><DataItem name="Incoming Document Attachment">%2</DataItem></DataItems></ReportParameters>', Locked = true;
        CustomerTypeCondnTxt: Label '<?xml version="1.0" encoding="utf-8" standalone="yes"?><ReportParameters><DataItems><DataItem name="Customer">%1</DataItem></DataItems></ReportParameters>', Locked = true;
        VendorTypeCondnTxt: Label '<?xml version="1.0" encoding="utf-8" standalone="yes"?><ReportParameters><DataItems><DataItem name="Vendor">%1</DataItem></DataItems></ReportParameters>', Locked = true;
        ItemTypeCondnTxt: Label '<?xml version="1.0" encoding="utf-8" standalone="yes"?><ReportParameters><DataItems><DataItem name="Item">%1</DataItem></DataItems></ReportParameters>', Locked = true;
        GeneralJournalBatchTypeCondnTxt: Label '<?xml version="1.0" encoding="utf-8" standalone="yes"?><ReportParameters><DataItems><DataItem name="Gen. Journal Batch">%1</DataItem></DataItems></ReportParameters>', Locked = true;
        GeneralJournalLineTypeCondnTxt: Label '<?xml version="1.0" encoding="utf-8" standalone="yes"?><ReportParameters><DataItems><DataItem name="Gen. Journal Line">%1</DataItem></DataItems></ReportParameters>', Locked = true;
        InvalidEventCondErr: Label 'No event conditions are specified.';
        OverdueWorkflowCodeTxt: Label 'OVERDUE', Locked = true;
        OverdueWorkflowDescTxt: Label 'Overdue Approval Requests Workflow';
        SalesInvoiceApprWorkflowCodeTxt: Label 'SIAPW', Locked = true;
        SalesReturnOrderApprWorkflowCodeTxt: Label 'SROAPW', Locked = true;
        SalesQuoteApprWorkflowCodeTxt: Label 'SQAPW', Locked = true;
        SalesOrderApprWorkflowCodeTxt: Label 'SOAPW', Locked = true;
        SalesCreditMemoApprWorkflowCodeTxt: Label 'SCMAPW', Locked = true;
        SalesBlanketOrderApprWorkflowCodeTxt: Label 'BSOAPW', Locked = true;
        SalesInvoiceCreditLimitApprWorkflowCodeTxt: Label 'SICLAPW', Locked = true;
        SalesOrderCreditLimitApprWorkflowCodeTxt: Label 'SOCLAPW', Locked = true;
        SalesRetOrderCrLimitApprWorkflowCodeTxt: Label 'SROCLAPW', Locked = true;
        SalesQuoteCrLimitApprWorkflowCodeTxt: Label 'SQCLAPW', Locked = true;
        SalesCrMemoCrLimitApprWorkflowCodeTxt: Label 'SCMCLAPW', Locked = true;
        SalesBlanketOrderCrLimitApprWorkflowCodeTxt: Label 'BSOCLAPW', Locked = true;
        SalesInvoiceApprWorkflowDescTxt: Label 'Sales Invoice Approval Workflow';
        SalesReturnOrderApprWorkflowDescTxt: Label 'Sales Return Order Approval Workflow';
        SalesQuoteApprWorkflowDescTxt: Label 'Sales Quote Approval Workflow';
        SalesOrderApprWorkflowDescTxt: Label 'Sales Order Approval Workflow';
        SalesCreditMemoApprWorkflowDescTxt: Label 'Sales Credit Memo Approval Workflow';
        SalesBlanketOrderApprWorkflowDescTxt: Label 'Blanket Sales Order Approval Workflow';
        SalesInvoiceCreditLimitApprWorkflowDescTxt: Label 'Sales Invoice Credit Limit Approval Workflow';
        SalesOrderCreditLimitApprWorkflowDescTxt: Label 'Sales Order Credit Limit Approval Workflow';
        SalesRetOrderCrLimitApprWorkflowDescTxt: Label 'Sales Return Order Credit Limit Approval Workflow';
        SalesQuoteCrLimitApprWorkflowDescTxt: Label 'Sales Quote Credit Limit Approval Workflow';
        SalesCrMemoCrLimitApprWorkflowDescTxt: Label 'Sales Credit Memo Credit Limit Approval Workflow';
        SalesBlanketOrderCrLimitApprWorkflowDescTxt: Label 'Blanket Sales Order Credit Limit Approval Workflow';
        CustomerApprWorkflowCodeTxt: Label 'CUSTAPW', Locked = true;
        CustomerApprWorkflowDescTxt: Label 'Customer Approval Workflow';
        CustomerCredLmtChangeApprWorkflowCodeTxt: Label 'CCLCAPW', Locked = true;
        CustomerCredLmtChangeApprWorkflowDescTxt: Label 'Customer Credit Limit Change Approval Workflow';
        VendorApprWorkflowCodeTxt: Label 'VENDAPW', Locked = true;
        VendorApprWorkflowDescTxt: Label 'Vendor Approval Workflow';
        ItemApprWorkflowCodeTxt: Label 'ITEMAPW', Locked = true;
        ItemApprWorkflowDescTxt: Label 'Item Approval Workflow';
        ItemUnitPriceChangeApprWorkflowCodeTxt: Label 'IUPCAPW', Locked = true;
        ItemUnitPriceChangeApprWorkflowDescTxt: Label 'Item Unit Price Change Approval Workflow';
        GeneralJournalBatchApprWorkflowCodeTxt: Label 'GJBAPW', Locked = true;
        GeneralJournalBatchApprWorkflowDescTxt: Label 'General Journal Batch Approval Workflow';
        GeneralJournalLineApprWorkflowCodeTxt: Label 'GJLAPW', Locked = true;
        GeneralJournalLineApprWorkflowDescTxt: Label 'General Journal Line Approval Workflow';
        GeneralJournalBatchIsNotBalancedMsg: Label 'The selected general journal batch is not balanced and cannot be sent for approval.', Comment = 'General Journal Batch refers to the name of a record.';
        ApprovalRequestCanceledMsg: Label 'The approval request for the record has been canceled.';
        SendToOCRWorkflowCodeTxt: Label 'INCDOC-OCR', Locked = true;
        CustCredLmtChangeSentForAppTxt: Label 'The customer credit limit change was sent for approval.';
        ItemUnitPriceChangeSentForAppTxt: Label 'The item unit price change was sent for approval.';
        IntegrationCategoryTxt: Label 'INT', Locked = true;
        SalesMktCategoryTxt: Label 'SALES', Locked = true;
        PurchPayCategoryTxt: Label 'PURCH', Locked = true;
        PurchDocCategoryTxt: Label 'PURCHDOC', Locked = true;
        SalesDocCategoryTxt: Label 'SALESDOC', Locked = true;
        AdminCategoryTxt: Label 'ADMIN', Locked = true;
        FinCategoryTxt: Label 'FIN', Locked = true;
        IntegrationCategoryDescTxt: Label 'Integration';
        SalesMktCategoryDescTxt: Label 'Sales and Marketing';
        PurchPayCategoryDescTxt: Label 'Purchases and Payables';
        PurchDocCategoryDescTxt: Label 'Purchase Documents';
        SalesDocCategoryDescTxt: Label 'Sales Documents';
        AdminCategoryDescTxt: Label 'Administration';
        FinCategoryDescTxt: Label 'Finance';
        JobQueueEntryApprWorkflowCodeTxt: Label 'JQEAPW', Locked = true;
        JobQueueEntryApprWorkflowDescTxt: Label 'Job Queue Entry Approval Workflow';
        JobQueueEntryCondnTxt: Label '<?xml version="1.0" encoding="utf-8" standalone="yes"?><ReportParameters><DataItems><DataItem name="Job Queue Entry">%1</DataItem></DataItems></ReportParameters>', Locked = true;
        RequisitionWkshTypeCondnTxt: Label '<?xml version="1.0" encoding="utf-8" standalone="yes"?><ReportParameters><DataItems><DataItem name="Requisition Wksh. Name">%1</DataItem></DataItems></ReportParameters>', Locked = true;
        RequisitionWkshBatchApprWorkflowCodeTxt: Label 'RWBAPW', Locked = true;
        RequisitionWkshBatchApprWorkflowDescTxt: Label 'Requisition Worksheet Batch Approval Workflow';

    procedure InitWorkflow()
    var
        Workflow: Record Workflow;
    begin
        WorkflowEventHandling.CreateEventsLibrary();
        WorkflowRequestPageHandling.CreateEntitiesAndFields();
        WorkflowRequestPageHandling.AssignEntitiesToWorkflowEvents();
        WorkflowResponseHandling.CreateResponsesLibrary();
        InsertWorkflowCategories();
        InsertJobQueueData();

        Workflow.SetRange(Template, true);
        Workflow.SetFilter(Code, '%1', GetWorkflowTemplateToken() + '*');
        if Workflow.IsEmpty() then
            InsertWorkflowTemplates();

        OnAfterInitWorkflowTemplates();
    end;

    local procedure InsertWorkflowTemplates()
    begin
        InsertApprovalsTableRelations();

        InsertIncomingDocumentWorkflowTemplate();
        InsertIncomingDocumentApprovalWorkflowTemplate();
        InsertIncomingDocumentOCRWorkflowTemplate();
        InsertIncomingDocumentToGenJnlLineOCRWorkflowTemplate();
        InsertIncomingDocumentDocExchWorkflowTemplate();

        InsertPurchaseInvoiceWorkflowTemplate();

        InsertPurchaseBlanketOrderApprovalWorkflowTemplate();
        InsertPurchaseCreditMemoApprovalWorkflowTemplate();
        InsertPurchaseInvoiceApprovalWorkflowTemplate();
        InsertPurchaseOrderApprovalWorkflowTemplate();
        InsertPurchaseQuoteApprovalWorkflowTemplate();
        InsertPurchaseReturnOrderApprovalWorkflowTemplate();

        InsertSalesBlanketOrderApprovalWorkflowTemplate();
        InsertSalesCreditMemoApprovalWorkflowTemplate();
        InsertSalesInvoiceApprovalWorkflowTemplate();
        InsertSalesOrderApprovalWorkflowTemplate();
        InsertSalesQuoteApprovalWorkflowTemplate();
        InsertSalesReturnOrderApprovalWorkflowTemplate();

        InsertSalesInvoiceCreditLimitApprovalWorkflowTemplate();
        InsertSalesOrderCreditLimitApprovalWorkflowTemplate();

        InsertOverdueApprovalsWorkflowTemplate();

        InsertCustomerApprovalWorkflowTemplate();
        InsertCustomerCreditLimitChangeApprovalWorkflowTemplate();

        InsertVendorApprovalWorkflowTemplate();

        InsertItemApprovalWorkflowTemplate();
        InsertItemUnitPriceChangeApprovalWorkflowTemplate();

        InsertGeneralJournalBatchApprovalWorkflowTemplate();
        InsertGeneralJournalLineApprovalWorkflowTemplate();

        InsertRequisitionWkshBatchApprovalWorkflowTemplate();

        InsertJobQueueEntryApprovalWorkflowTemplate();

        OnInsertWorkflowTemplates();
    end;

    procedure InsertWorkflowCategories()
    begin
        InsertWorkflowCategory(IntegrationCategoryTxt, IntegrationCategoryDescTxt);
        InsertWorkflowCategory(SalesMktCategoryTxt, SalesMktCategoryDescTxt);
        InsertWorkflowCategory(PurchPayCategoryTxt, PurchPayCategoryDescTxt);
        InsertWorkflowCategory(PurchDocCategoryTxt, PurchDocCategoryDescTxt);
        InsertWorkflowCategory(SalesDocCategoryTxt, SalesDocCategoryDescTxt);
        InsertWorkflowCategory(AdminCategoryTxt, AdminCategoryDescTxt);
        InsertWorkflowCategory(FinCategoryTxt, FinCategoryDescTxt);

        OnAddWorkflowCategoriesToLibrary();
    end;

    [IntegrationEvent(true, false)]
    local procedure OnInsertWorkflowTemplates()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddWorkflowCategoriesToLibrary()
    begin
    end;

    local procedure InsertWorkflow(var Workflow: Record Workflow; WorkflowCode: Code[20]; WorkflowDescription: Text[100]; CategoryCode: Code[20])
    begin
        Workflow.Init();
        Workflow.Code := WorkflowCode;
        Workflow.Description := WorkflowDescription;
        Workflow.Category := CategoryCode;
        Workflow.Enabled := false;
        Workflow.Insert();
    end;

    procedure InsertWorkflowTemplate(var Workflow: Record Workflow; WorkflowCode: Code[17]; WorkflowDescription: Text[100]; CategoryCode: Code[20])
    begin
        Workflow.Init();
        Workflow.Code := GetWorkflowTemplateCode(WorkflowCode);
        Workflow.Description := WorkflowDescription;
        Workflow.Category := CategoryCode;
        Workflow.Enabled := false;
        if Workflow.Insert() then;
    end;

    internal procedure ResetWorkflowTemplates()
    var
        Workflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        Workflow.SetRange(Template, true);
        Workflow.SetFilter(Code, '%1', GetWorkflowTemplateToken() + '*');
        Workflow.DeleteAll();

        WorkflowStep.SetFilter("Workflow Code", '%1', GetWorkflowTemplateToken() + '*');
        if WorkflowStep.FindSet() then begin
            repeat
                WorkflowStepArgument.SetRange(ID, WorkflowStep.Argument);
                WorkflowStepArgument.DeleteAll();
            until WorkflowStep.Next() = 0;
            WorkflowStep.DeleteAll();
        end;

        InitWorkflow();
    end;

    procedure InsertApprovalsTableRelations()
    var
        IncomingDocument: Record "Incoming Document";
        ApprovalEntry: Record "Approval Entry";
        DummyGenJournalLine: Record "Gen. Journal Line";
    begin
        InsertTableRelation(DATABASE::"Purchase Header", 0,
          DATABASE::"Approval Entry", ApprovalEntry.FieldNo("Record ID to Approve"));

        InsertTableRelation(DATABASE::"Sales Header", 0,
          DATABASE::"Approval Entry", ApprovalEntry.FieldNo("Record ID to Approve"));

        InsertTableRelation(DATABASE::Customer, 0,
          DATABASE::"Approval Entry", ApprovalEntry.FieldNo("Record ID to Approve"));
        InsertTableRelation(DATABASE::Vendor, 0,
          DATABASE::"Approval Entry", ApprovalEntry.FieldNo("Record ID to Approve"));
        InsertTableRelation(DATABASE::Item, 0,
          DATABASE::"Approval Entry", ApprovalEntry.FieldNo("Record ID to Approve"));
        InsertTableRelation(DATABASE::"Gen. Journal Line", 0,
          DATABASE::"Approval Entry", ApprovalEntry.FieldNo("Record ID to Approve"));
        InsertTableRelation(DATABASE::"Gen. Journal Batch", 0,
          DATABASE::"Approval Entry", ApprovalEntry.FieldNo("Record ID to Approve"));
        InsertTableRelation(Database::"Requisition Wksh. Name", 0,
          Database::"Approval Entry", ApprovalEntry.FieldNo("Record ID to Approve"));

        InsertTableRelation(
          DATABASE::"Incoming Document", IncomingDocument.FieldNo("Entry No."),
          DATABASE::"Approval Entry", ApprovalEntry.FieldNo("Document No."));
        InsertTableRelation(
          DATABASE::"Approval Entry", ApprovalEntry.FieldNo("Document No."),
          DATABASE::"Incoming Document", IncomingDocument.FieldNo("Entry No."));

        InsertTableRelation(
          DATABASE::"Incoming Document", IncomingDocument.FieldNo("Entry No."), DATABASE::"Gen. Journal Line",
          DummyGenJournalLine.FieldNo("Incoming Document Entry No."));

        InsertTableRelation(Database::"Job Queue Entry", 0,
          Database::"Approval Entry", ApprovalEntry.FieldNo("Record ID to Approve"));

        OnAfterInsertApprovalsTableRelations();
    end;

    local procedure InsertIncomingDocumentWorkflowTemplate()
    var
        Workflow: Record Workflow;
    begin
        InsertWorkflowTemplate(Workflow, IncDocWorkflowCodeTxt, IncDocWorkflowDescTxt, IntegrationCategoryTxt);
        InsertIncomingDocumentWorkflowDetails(Workflow);
        MarkWorkflowAsTemplate(Workflow);
    end;

    local procedure InsertIncomingDocumentWorkflowDetails(var Workflow: Record Workflow)
    var
        IncomingDocument: Record "Incoming Document";
        PurchaseHeader: Record "Purchase Header";
        OnIncomingDocumentCreatedEventID: Integer;
    begin
        InsertTableRelation(DATABASE::"Incoming Document", IncomingDocument.FieldNo("Entry No."),
          DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Incoming Document Entry No."));
        InsertTableRelation(DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Incoming Document Entry No."),
          DATABASE::"Incoming Document", IncomingDocument.FieldNo("Entry No."));

        OnIncomingDocumentCreatedEventID :=
          InsertEntryPointEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnAfterInsertIncomingDocumentCode());
        InsertResponseStep(Workflow, WorkflowResponseHandling.CreateNotificationEntryCode(), OnIncomingDocumentCreatedEventID);
    end;

    local procedure InsertIncomingDocumentOCRWorkflowTemplate()
    var
        Workflow: Record Workflow;
    begin
        InsertWorkflowTemplate(
          Workflow, IncDocOCRWorkflowCodeTxt, IncDocOCRWorkflowDescriptionTxt, IntegrationCategoryTxt);
        InsertIncomingDocumentOCRWorkflowDetails(Workflow);
        MarkWorkflowAsTemplate(Workflow);
    end;

    local procedure InsertIncomingDocumentOCRWorkflowDetails(var Workflow: Record Workflow)
    var
        IncomingDocument: Record "Incoming Document";
        OCRSuccessEventID: Integer;
        CreateDocResponseID: Integer;
        NotifyResponseID: Integer;
        DocSuccessEventID: Integer;
        DocErrorEventID: Integer;
    begin
        OCRSuccessEventID :=
          InsertEntryPointEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnAfterReceiveFromOCRIncomingDocCode());
        InsertEventArgument(
          OCRSuccessEventID, BuildIncomingDocumentOCRTypeConditions(IncomingDocument."OCR Status"::Success));
        CreateDocResponseID :=
          InsertResponseStep(Workflow, WorkflowResponseHandling.GetCreateDocFromIncomingDocCode(), OCRSuccessEventID);

        DocSuccessEventID :=
          InsertEventStep(
            Workflow, WorkflowEventHandling.RunWorkflowOnAfterCreateDocFromIncomingDocSuccessCode(), CreateDocResponseID);
        InsertEventArgument(DocSuccessEventID, BuildIncomingDocumentTypeConditions(IncomingDocument.Status::Created));
        InsertResponseStep(Workflow, WorkflowResponseHandling.DoNothingCode(), DocSuccessEventID);

        DocErrorEventID :=
          InsertEventStep(
            Workflow, WorkflowEventHandling.RunWorkflowOnAfterCreateDocFromIncomingDocFailCode(), CreateDocResponseID);
        InsertEventArgument(DocErrorEventID, BuildIncomingDocumentTypeConditions(IncomingDocument.Status::Failed));
        NotifyResponseID := InsertResponseStep(Workflow, WorkflowResponseHandling.CreateNotificationEntryCode(), DocErrorEventID);

        InsertNotificationArgument(NotifyResponseID, false, '', PAGE::"Incoming Document", '');
    end;

    local procedure InsertIncomingDocumentToGenJnlLineOCRWorkflowTemplate()
    var
        Workflow: Record Workflow;
    begin
        InsertWorkflowTemplate(
          Workflow, IncDocToGenJnlLineOCRWorkflowCodeTxt, IncDocToGenJnlLineOCRWorkflowDescriptionTxt, IntegrationCategoryTxt);
        InsertIncomingDocumentToGenJnlLineOCRWorkflowDetails(Workflow);
        MarkWorkflowAsTemplate(Workflow);
    end;

    local procedure InsertIncomingDocumentToGenJnlLineOCRWorkflowDetails(var Workflow: Record Workflow)
    var
        IncomingDocument: Record "Incoming Document";
        OCRSuccessForGenJnlLineEventID: Integer;
        CreateDocForGenJnlLineResponseID: Integer;
        GenJnlLineSuccessEventID: Integer;
        GenJnlLineFailEventID: Integer;
        CreateGenJnlLineFailResponseID: Integer;
    begin
        OCRSuccessForGenJnlLineEventID :=
          InsertEntryPointEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnAfterReceiveFromOCRIncomingDocCode());
        InsertEventArgument(
          OCRSuccessForGenJnlLineEventID, BuildIncomingDocumentOCRTypeConditions(IncomingDocument."OCR Status"::Success));
        CreateDocForGenJnlLineResponseID :=
          InsertResponseStep(Workflow, WorkflowResponseHandling.GetCreateJournalFromIncomingDocCode(), OCRSuccessForGenJnlLineEventID);

        GenJnlLineSuccessEventID :=
          InsertEventStep(
            Workflow, WorkflowEventHandling.RunWorkflowOnAfterCreateGenJnlLineFromIncomingDocSuccessCode(),
            CreateDocForGenJnlLineResponseID);
        InsertResponseStep(Workflow, WorkflowResponseHandling.DoNothingCode(), GenJnlLineSuccessEventID);

        GenJnlLineFailEventID :=
          InsertEventStep(
            Workflow, WorkflowEventHandling.RunWorkflowOnAfterCreateGenJnlLineFromIncomingDocFailCode(), CreateDocForGenJnlLineResponseID);
        CreateGenJnlLineFailResponseID :=
          InsertResponseStep(Workflow, WorkflowResponseHandling.CreateNotificationEntryCode(), GenJnlLineFailEventID);

        InsertNotificationArgument(CreateGenJnlLineFailResponseID, false, '', PAGE::"Incoming Document", '');
    end;

    local procedure InsertIncomingDocumentDocExchWorkflowTemplate()
    var
        Workflow: Record Workflow;
    begin
        InsertWorkflowTemplate(Workflow, IncDocExchWorkflowCodeTxt, IncDocExchWorkflowDescriptionTxt, IntegrationCategoryTxt);
        InsertIncomingDocumentDocExchWorkflowDetails(Workflow);
        MarkWorkflowAsTemplate(Workflow);
    end;

    local procedure InsertIncomingDocumentDocExchWorkflowDetails(var Workflow: Record Workflow)
    var
        IncomingDocument: Record "Incoming Document";
        IncDocCreatedEventID: Integer;
        DocReleasedEventID: Integer;
        DocSuccessEventID: Integer;
        DocErrorEventID: Integer;
        ReleaseDocResponseID: Integer;
        CreateDocResponseID: Integer;
        NotifyResponseID: Integer;
    begin
        IncDocCreatedEventID :=
          InsertEntryPointEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnAfterReceiveFromDocExchIncomingDocCode());
        InsertEventArgument(IncDocCreatedEventID, BuildIncomingDocumentTypeConditions(IncomingDocument.Status::New));
        ReleaseDocResponseID := InsertResponseStep(Workflow, WorkflowResponseHandling.ReleaseDocumentCode(), IncDocCreatedEventID);

        DocReleasedEventID :=
          InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnAfterReleaseIncomingDocCode(), ReleaseDocResponseID);
        InsertEventArgument(DocReleasedEventID, BuildIncomingDocumentTypeConditions(IncomingDocument.Status::Released));
        CreateDocResponseID :=
          InsertResponseStep(Workflow, WorkflowResponseHandling.GetCreateDocFromIncomingDocCode(), DocReleasedEventID);

        DocSuccessEventID :=
          InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnAfterCreateDocFromIncomingDocSuccessCode(), CreateDocResponseID);
        InsertEventArgument(DocSuccessEventID, BuildIncomingDocumentTypeConditions(IncomingDocument.Status::Created));
        InsertResponseStep(Workflow, WorkflowResponseHandling.DoNothingCode(), DocSuccessEventID);

        DocErrorEventID :=
          InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnAfterCreateDocFromIncomingDocFailCode(), CreateDocResponseID);
        InsertEventArgument(DocErrorEventID, BuildIncomingDocumentTypeConditions(IncomingDocument.Status::Failed));
        NotifyResponseID := InsertResponseStep(Workflow, WorkflowResponseHandling.CreateNotificationEntryCode(), DocErrorEventID);

        InsertNotificationArgument(NotifyResponseID, false, '', PAGE::"Incoming Document", '');
    end;

    local procedure InsertPurchaseInvoiceWorkflowTemplate()
    var
        Workflow: Record Workflow;
    begin
        InsertWorkflowTemplate(Workflow, PurchInvWorkflowCodeTxt, PurchInvWorkflowDescriptionTxt, PurchDocCategoryTxt);
        InsertPurchaseInvoiceWorkflowDetails(Workflow);
        MarkWorkflowAsTemplate(Workflow);
    end;

    local procedure InsertPurchaseInvoiceWorkflowDetails(var Workflow: Record Workflow)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        GenJournalLine: Record "Gen. Journal Line";
        DocReleasedEventID: Integer;
        PostedEventID: Integer;
        JournalLineCreatedEventID: Integer;
        PostDocAsyncResponseID: Integer;
        CreatePmtLineResponseID: Integer;
        NotifyResponseID: Integer;
    begin
        InsertTableRelation(DATABASE::"Purchase Header", PurchaseHeader.FieldNo("No."),
          DATABASE::"Purch. Inv. Header", PurchInvHeader.FieldNo("Pre-Assigned No."));
        InsertTableRelation(DATABASE::"Purch. Inv. Header", PurchaseHeader.FieldNo("No."),
          DATABASE::"Gen. Journal Line", GenJournalLine.FieldNo("Applies-to Doc. No."));

        DocReleasedEventID := InsertEntryPointEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnAfterReleasePurchaseDocCode());
        InsertEventArgument(
            DocReleasedEventID,
            BuildPurchHeaderTypeConditionsText("Purchase Document Type"::Invoice, "Purchase Document Status"::Released));

        PostDocAsyncResponseID := InsertResponseStep(Workflow, WorkflowResponseHandling.PostDocumentAsyncCode(), DocReleasedEventID);

        PostedEventID :=
          InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnAfterPostPurchaseDocCode(), PostDocAsyncResponseID);
        CreatePmtLineResponseID := InsertResponseStep(Workflow, WorkflowResponseHandling.CreatePmtLineForPostedPurchaseDocAsyncCode(),
            PostedEventID);
        InsertPmtLineCreationArgument(CreatePmtLineResponseID, '', '');

        JournalLineCreatedEventID := InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnAfterInsertGeneralJournalLineCode(),
            CreatePmtLineResponseID);

        GenJournalLine.SetRange("Document Type", GenJournalLine."Document Type"::Payment);
        InsertEventArgument(JournalLineCreatedEventID, BuildGeneralJournalLineTypeConditions(GenJournalLine));

        NotifyResponseID := InsertResponseStep(Workflow, WorkflowResponseHandling.CreateNotificationEntryCode(), JournalLineCreatedEventID);
        InsertNotificationArgument(NotifyResponseID, false, '', PAGE::"Payment Journal", '');
    end;

    procedure InsertIncomingDocumentApprovalWorkflowTemplate()
    var
        Workflow: Record Workflow;
    begin
        InsertWorkflowTemplate(Workflow, IncomingDocumentApprWorkflowCodeTxt, IncomingDocumentApprWorkflowDescTxt, IntegrationCategoryTxt);
        InsertIncomingDocumentApprovalWorkflowDetails(Workflow);
        MarkWorkflowAsTemplate(Workflow);
    end;

    local procedure InsertIncomingDocumentApprovalWorkflowDetails(var Workflow: Record Workflow)
    var
        IncomingDocument: Record "Incoming Document";
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        InitWorkflowStepArgument(
            WorkflowStepArgument, WorkflowStepArgument."Approver Type"::"Workflow User Group",
            WorkflowStepArgument."Approver Limit Type"::"Direct Approver", 0, '', BlankDateFormula, true);

        InsertDocApprovalWorkflowSteps(
          Workflow,
          BuildIncomingDocumentTypeConditions(IncomingDocument.Status::New),
          WorkflowEventHandling.RunWorkflowOnSendIncomingDocForApprovalCode(),
          BuildIncomingDocumentTypeConditions(IncomingDocument.Status::"Pending Approval"),
          WorkflowEventHandling.RunWorkflowOnCancelIncomingDocApprovalRequestCode(),
          WorkflowStepArgument, true);
    end;

    local procedure InsertPurchaseInvoiceApprovalWorkflowTemplate()
    var
        Workflow: Record Workflow;
    begin
        InsertWorkflowTemplate(Workflow, PurchInvoiceApprWorkflowCodeTxt, PurchInvoiceApprWorkflowDescTxt, PurchDocCategoryTxt);
        InsertPurchaseInvoiceApprovalWorkflowDetails(Workflow);
        MarkWorkflowAsTemplate(Workflow);
    end;

    local procedure InsertPurchaseInvoiceApprovalWorkflowDetails(var Workflow: Record Workflow)
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        InitWorkflowStepArgument(
            WorkflowStepArgument, WorkflowStepArgument."Approver Type"::"Salesperson/Purchaser",
            WorkflowStepArgument."Approver Limit Type"::"Direct Approver", 0, '', BlankDateFormula, true);

        InsertDocApprovalWorkflowSteps(
            Workflow,
            BuildPurchHeaderTypeConditionsText("Purchase Document Type"::Invoice, "Purchase Document Status"::Open),
            WorkflowEventHandling.RunWorkflowOnSendPurchaseDocForApprovalCode(),
            BuildPurchHeaderTypeConditionsText("Purchase Document Type"::Invoice, "Purchase Document Status"::"Pending Approval"),
            WorkflowEventHandling.RunWorkflowOnCancelPurchaseApprovalRequestCode(),
            WorkflowStepArgument, true);
    end;

    local procedure InsertPurchaseBlanketOrderApprovalWorkflowTemplate()
    var
        Workflow: Record Workflow;
    begin
        InsertWorkflowTemplate(Workflow, PurchBlanketOrderApprWorkflowCodeTxt, PurchBlanketOrderApprWorkflowDescTxt, PurchDocCategoryTxt);
        InsertPurchaseBlanketOrderApprovalWorkflowDetails(Workflow);
        MarkWorkflowAsTemplate(Workflow);
    end;

    local procedure InsertPurchaseBlanketOrderApprovalWorkflowDetails(var Workflow: Record Workflow)
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        InitWorkflowStepArgument(
            WorkflowStepArgument, WorkflowStepArgument."Approver Type"::"Workflow User Group",
            WorkflowStepArgument."Approver Limit Type"::"Direct Approver", 0, '', BlankDateFormula, true);

        InsertDocApprovalWorkflowSteps(
            Workflow,
            BuildPurchHeaderTypeConditionsText("Purchase Document Type"::"Blanket Order", "Purchase Document Status"::Open),
            WorkflowEventHandling.RunWorkflowOnSendPurchaseDocForApprovalCode(),
            BuildPurchHeaderTypeConditionsText("Purchase Document Type"::"Blanket Order", "Purchase Document Status"::"Pending Approval"),
            WorkflowEventHandling.RunWorkflowOnCancelPurchaseApprovalRequestCode(),
            WorkflowStepArgument, true);
    end;

    local procedure InsertPurchaseCreditMemoApprovalWorkflowTemplate()
    var
        Workflow: Record Workflow;
    begin
        InsertWorkflowTemplate(Workflow, PurchCreditMemoApprWorkflowCodeTxt, PurchCreditMemoApprWorkflowDescTxt, PurchDocCategoryTxt);
        InsertPurchaseCreditMemoApprovalWorkflowDetails(Workflow);
        MarkWorkflowAsTemplate(Workflow);
    end;

    local procedure InsertPurchaseCreditMemoApprovalWorkflowDetails(var Workflow: Record Workflow)
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        InitWorkflowStepArgument(
            WorkflowStepArgument, WorkflowStepArgument."Approver Type"::"Salesperson/Purchaser",
            WorkflowStepArgument."Approver Limit Type"::"Direct Approver", 0, '', BlankDateFormula, true);

        InsertDocApprovalWorkflowSteps(
            Workflow,
            BuildPurchHeaderTypeConditionsText("Purchase Document Type"::"Credit Memo", "Purchase Document Status"::Open),
            WorkflowEventHandling.RunWorkflowOnSendPurchaseDocForApprovalCode(),
            BuildPurchHeaderTypeConditionsText("Purchase Document Type"::"Credit Memo", "Purchase Document Status"::"Pending Approval"),
            WorkflowEventHandling.RunWorkflowOnCancelPurchaseApprovalRequestCode(),
            WorkflowStepArgument, true);
    end;

    local procedure InsertPurchaseOrderApprovalWorkflowTemplate()
    var
        Workflow: Record Workflow;
    begin
        InsertWorkflowTemplate(Workflow, PurchOrderApprWorkflowCodeTxt, PurchOrderApprWorkflowDescTxt, PurchDocCategoryTxt);
        InsertPurchaseOrderApprovalWorkflowDetails(Workflow);
        MarkWorkflowAsTemplate(Workflow);
    end;

    local procedure InsertPurchaseOrderApprovalWorkflowDetails(var Workflow: Record Workflow)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        InsertTableRelation(DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Document Type"),
          DATABASE::"Purchase Line", PurchaseLine.FieldNo("Document Type"));
        InsertTableRelation(DATABASE::"Purchase Header", PurchaseHeader.FieldNo("No."),
          DATABASE::"Purchase Line", PurchaseLine.FieldNo("Document No."));

        InitWorkflowStepArgument(
            WorkflowStepArgument, WorkflowStepArgument."Approver Type"::Approver,
            WorkflowStepArgument."Approver Limit Type"::"Approver Chain", 0, '', BlankDateFormula, true);

        InsertDocApprovalWorkflowSteps(
            Workflow,
            BuildPurchHeaderTypeConditionsText("Purchase Document Type"::Order, "Purchase Document Status"::Open),
            WorkflowEventHandling.RunWorkflowOnSendPurchaseDocForApprovalCode(),
            BuildPurchHeaderTypeConditionsText("Purchase Document Type"::Order, "Purchase Document Status"::"Pending Approval"),
            WorkflowEventHandling.RunWorkflowOnCancelPurchaseApprovalRequestCode(),
            WorkflowStepArgument, true);
    end;

    local procedure InsertPurchaseQuoteApprovalWorkflowTemplate()
    var
        Workflow: Record Workflow;
    begin
        InsertWorkflowTemplate(Workflow, PurchQuoteApprWorkflowCodeTxt, PurchQuoteApprWorkflowDescTxt, PurchDocCategoryTxt);
        InsertPurchaseQuoteApprovalWorkflowDetails(Workflow);
        MarkWorkflowAsTemplate(Workflow);
    end;

    local procedure InsertPurchaseQuoteApprovalWorkflowDetails(var Workflow: Record Workflow)
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        InitWorkflowStepArgument(
            WorkflowStepArgument, WorkflowStepArgument."Approver Type"::Approver,
            WorkflowStepArgument."Approver Limit Type"::"Approver Chain", 0, '', BlankDateFormula, true);

        InsertDocApprovalWorkflowSteps(
            Workflow,
            BuildPurchHeaderTypeConditionsText("Purchase Document Type"::Quote, "Purchase Document Status"::Open),
            WorkflowEventHandling.RunWorkflowOnSendPurchaseDocForApprovalCode(),
            BuildPurchHeaderTypeConditionsText("Purchase Document Type"::Quote, "Purchase Document Status"::"Pending Approval"),
            WorkflowEventHandling.RunWorkflowOnCancelPurchaseApprovalRequestCode(),
            WorkflowStepArgument, true);
    end;

    local procedure InsertPurchaseReturnOrderApprovalWorkflowTemplate()
    var
        Workflow: Record Workflow;
    begin
        InsertWorkflowTemplate(Workflow, PurchReturnOrderApprWorkflowCodeTxt, PurchReturnOrderApprWorkflowDescTxt, PurchDocCategoryTxt);
        InsertPurchaseReturnOrderApprovalWorkflowDetails(Workflow);
        MarkWorkflowAsTemplate(Workflow);
    end;

    local procedure InsertPurchaseReturnOrderApprovalWorkflowDetails(var Workflow: Record Workflow)
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        InitWorkflowStepArgument(
            WorkflowStepArgument, WorkflowStepArgument."Approver Type"::"Salesperson/Purchaser",
            WorkflowStepArgument."Approver Limit Type"::"Direct Approver", 0, '', BlankDateFormula, true);

        InsertDocApprovalWorkflowSteps(
            Workflow,
            BuildPurchHeaderTypeConditionsText("Purchase Document Type"::"Return Order", "Purchase Document Status"::Open),
            WorkflowEventHandling.RunWorkflowOnSendPurchaseDocForApprovalCode(),
            BuildPurchHeaderTypeConditionsText("Purchase Document Type"::"Return Order", "Purchase Document Status"::"Pending Approval"),
            WorkflowEventHandling.RunWorkflowOnCancelPurchaseApprovalRequestCode(),
            WorkflowStepArgument, true);
    end;

    local procedure InsertSalesInvoiceApprovalWorkflowTemplate()
    var
        Workflow: Record Workflow;
    begin
        InsertWorkflowTemplate(Workflow, SalesInvoiceApprWorkflowCodeTxt, SalesInvoiceApprWorkflowDescTxt, SalesDocCategoryTxt);
        InsertSalesInvoiceApprovalWorkflowDetails(Workflow);
        MarkWorkflowAsTemplate(Workflow);
    end;

    local procedure InsertSalesInvoiceApprovalWorkflowDetails(var Workflow: Record Workflow)
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        InitWorkflowStepArgument(
            WorkflowStepArgument, WorkflowStepArgument."Approver Type"::"Salesperson/Purchaser",
            WorkflowStepArgument."Approver Limit Type"::"Direct Approver", 0, '', BlankDateFormula, true);

        InsertDocApprovalWorkflowSteps(Workflow,
            BuildSalesHeaderTypeConditionsText(Enum::"Sales Document Type"::Invoice, Enum::"Sales Document Status"::Open),
            WorkflowEventHandling.RunWorkflowOnSendSalesDocForApprovalCode(),
            BuildSalesHeaderTypeConditionsText(Enum::"Sales Document Type"::Invoice, Enum::"Sales Document Status"::"Pending Approval"),
            WorkflowEventHandling.RunWorkflowOnCancelSalesApprovalRequestCode(),
            WorkflowStepArgument, true);
    end;

    local procedure InsertSalesBlanketOrderApprovalWorkflowTemplate()
    var
        Workflow: Record Workflow;
    begin
        InsertWorkflowTemplate(Workflow, SalesBlanketOrderApprWorkflowCodeTxt, SalesBlanketOrderApprWorkflowDescTxt, SalesDocCategoryTxt);
        InsertSalesBlanketOrderApprovalWorkflowDetails(Workflow);
        MarkWorkflowAsTemplate(Workflow);
    end;

    local procedure InsertSalesBlanketOrderApprovalWorkflowDetails(var Workflow: Record Workflow)
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        InitWorkflowStepArgument(
            WorkflowStepArgument, WorkflowStepArgument."Approver Type"::"Workflow User Group",
            WorkflowStepArgument."Approver Limit Type"::"Direct Approver", 0, '', BlankDateFormula, true);

        InsertDocApprovalWorkflowSteps(
            Workflow,
            BuildSalesHeaderTypeConditionsText(Enum::"Sales Document Type"::"Blanket Order", Enum::"Sales Document Status"::Open),
            WorkflowEventHandling.RunWorkflowOnSendSalesDocForApprovalCode(),
            BuildSalesHeaderTypeConditionsText(Enum::"Sales Document Type"::"Blanket Order", Enum::"Sales Document Status"::"Pending Approval"),
            WorkflowEventHandling.RunWorkflowOnCancelSalesApprovalRequestCode(),
            WorkflowStepArgument, true);
    end;

    local procedure InsertSalesCreditMemoApprovalWorkflowTemplate()
    var
        Workflow: Record Workflow;
    begin
        InsertWorkflowTemplate(Workflow, SalesCreditMemoApprWorkflowCodeTxt, SalesCreditMemoApprWorkflowDescTxt, SalesDocCategoryTxt);
        InsertSalesCreditMemoApprovalWorkflowDetails(Workflow);
        MarkWorkflowAsTemplate(Workflow);
    end;

    local procedure InsertSalesCreditMemoApprovalWorkflowDetails(var Workflow: Record Workflow)
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        InitWorkflowStepArgument(
            WorkflowStepArgument, WorkflowStepArgument."Approver Type"::"Salesperson/Purchaser",
            WorkflowStepArgument."Approver Limit Type"::"Direct Approver", 0, '', BlankDateFormula, true);

        InsertDocApprovalWorkflowSteps(
            Workflow,
            BuildSalesHeaderTypeConditionsText(Enum::"Sales Document Type"::"Credit Memo", Enum::"Sales Document Status"::Open),
            WorkflowEventHandling.RunWorkflowOnSendSalesDocForApprovalCode(),
            BuildSalesHeaderTypeConditionsText(Enum::"Sales Document Type"::"Credit Memo", Enum::"Sales Document Status"::"Pending Approval"),
            WorkflowEventHandling.RunWorkflowOnCancelSalesApprovalRequestCode(),
            WorkflowStepArgument, true);
    end;

    local procedure InsertSalesOrderApprovalWorkflowTemplate()
    var
        Workflow: Record Workflow;
    begin
        InsertWorkflowTemplate(Workflow, SalesOrderApprWorkflowCodeTxt, SalesOrderApprWorkflowDescTxt, SalesDocCategoryTxt);
        InsertSalesOrderApprovalWorkflowDetails(Workflow);
        MarkWorkflowAsTemplate(Workflow);
    end;

    local procedure InsertSalesOrderApprovalWorkflowDetails(var Workflow: Record Workflow)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        InsertTableRelation(DATABASE::"Sales Header", SalesHeader.FieldNo("Document Type"),
          DATABASE::"Sales Line", SalesLine.FieldNo("Document Type"));
        InsertTableRelation(DATABASE::"Sales Header", SalesHeader.FieldNo("No."),
          DATABASE::"Sales Line", SalesLine.FieldNo("Document No."));

        InitWorkflowStepArgument(
            WorkflowStepArgument, WorkflowStepArgument."Approver Type"::"Salesperson/Purchaser",
            WorkflowStepArgument."Approver Limit Type"::"Approver Chain", 0, '', BlankDateFormula, true);

        InsertDocApprovalWorkflowSteps(
            Workflow,
            BuildSalesHeaderTypeConditionsText(Enum::"Sales Document Type"::Order, Enum::"Sales Document Status"::Open),
            WorkflowEventHandling.RunWorkflowOnSendSalesDocForApprovalCode(),
            BuildSalesHeaderTypeConditionsText(Enum::"Sales Document Type"::Order, Enum::"Sales Document Status"::"Pending Approval"),
            WorkflowEventHandling.RunWorkflowOnCancelSalesApprovalRequestCode(),
            WorkflowStepArgument, true);
    end;

    local procedure InsertSalesQuoteApprovalWorkflowTemplate()
    var
        Workflow: Record Workflow;
    begin
        InsertWorkflowTemplate(Workflow, SalesQuoteApprWorkflowCodeTxt, SalesQuoteApprWorkflowDescTxt, SalesDocCategoryTxt);
        InsertSalesQuoteApprovalWorkflowDetails(Workflow);
        MarkWorkflowAsTemplate(Workflow);
    end;

    local procedure InsertSalesQuoteApprovalWorkflowDetails(var Workflow: Record Workflow)
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        InitWorkflowStepArgument(
            WorkflowStepArgument, WorkflowStepArgument."Approver Type"::"Salesperson/Purchaser",
            WorkflowStepArgument."Approver Limit Type"::"Direct Approver", 0, '', BlankDateFormula, true);

        InsertDocApprovalWorkflowSteps(
            Workflow,
            BuildSalesHeaderTypeConditionsText(Enum::"Sales Document Type"::Quote, Enum::"Sales Document Status"::Open),
            WorkflowEventHandling.RunWorkflowOnSendSalesDocForApprovalCode(),
            BuildSalesHeaderTypeConditionsText(Enum::"Sales Document Type"::Quote, Enum::"Sales Document Status"::"Pending Approval"),
            WorkflowEventHandling.RunWorkflowOnCancelSalesApprovalRequestCode(),
            WorkflowStepArgument, true);
    end;

    local procedure InsertSalesReturnOrderApprovalWorkflowTemplate()
    var
        Workflow: Record Workflow;
    begin
        InsertWorkflowTemplate(Workflow, SalesReturnOrderApprWorkflowCodeTxt, SalesReturnOrderApprWorkflowDescTxt, SalesDocCategoryTxt);
        InsertSalesReturnOrderApprovalWorkflowDetails(Workflow);
        MarkWorkflowAsTemplate(Workflow);
    end;

    local procedure InsertSalesReturnOrderApprovalWorkflowDetails(var Workflow: Record Workflow)
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        InitWorkflowStepArgument(
            WorkflowStepArgument, WorkflowStepArgument."Approver Type"::"Salesperson/Purchaser",
            WorkflowStepArgument."Approver Limit Type"::"Direct Approver", 0, '', BlankDateFormula, true);

        InsertDocApprovalWorkflowSteps(
            Workflow,
            BuildSalesHeaderTypeConditionsText(Enum::"Sales Document Type"::"Return Order", Enum::"Sales Document Status"::Open),
            WorkflowEventHandling.RunWorkflowOnSendSalesDocForApprovalCode(),
            BuildSalesHeaderTypeConditionsText(Enum::"Sales Document Type"::"Return Order", Enum::"Sales Document Status"::"Pending Approval"),
            WorkflowEventHandling.RunWorkflowOnCancelSalesApprovalRequestCode(),
            WorkflowStepArgument, true);
    end;

    local procedure InsertSalesInvoiceCreditLimitApprovalWorkflowTemplate()
    var
        Workflow: Record Workflow;
    begin
        InsertWorkflowTemplate(Workflow, SalesInvoiceCreditLimitApprWorkflowCodeTxt,
          SalesInvoiceCreditLimitApprWorkflowDescTxt, SalesDocCategoryTxt);
        InsertSalesInvoiceCreditLimitApprovalWorkflowDetails(Workflow);
        MarkWorkflowAsTemplate(Workflow);
    end;

    local procedure InsertSalesInvoiceCreditLimitApprovalWorkflowDetails(var Workflow: Record Workflow)
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        InitWorkflowStepArgument(
            WorkflowStepArgument, WorkflowStepArgument."Approver Type"::"Salesperson/Purchaser",
            WorkflowStepArgument."Approver Limit Type"::"Direct Approver", 0, '', BlankDateFormula, true);

        InsertSalesDocWithCreditLimitApprovalWorkflowSteps(
            Workflow,
            BuildSalesHeaderTypeConditionsText(Enum::"Sales Document Type"::Invoice, Enum::"Sales Document Status"::Open),
            BuildSalesHeaderTypeConditionsText(Enum::"Sales Document Type"::Invoice, Enum::"Sales Document Status"::"Pending Approval"),
            WorkflowStepArgument, true);
    end;

    local procedure InsertSalesOrderCreditLimitApprovalWorkflowTemplate()
    var
        Workflow: Record Workflow;
    begin
        InsertWorkflowTemplate(Workflow, SalesOrderCreditLimitApprWorkflowCodeTxt,
          SalesOrderCreditLimitApprWorkflowDescTxt, SalesDocCategoryTxt);
        InsertSalesOrderCreditLimitApprovalWorkflowDetails(Workflow);
        MarkWorkflowAsTemplate(Workflow);
    end;

    local procedure InsertSalesOrderCreditLimitApprovalWorkflowDetails(var Workflow: Record Workflow)
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        InitWorkflowStepArgument(
            WorkflowStepArgument, WorkflowStepArgument."Approver Type"::"Salesperson/Purchaser",
            WorkflowStepArgument."Approver Limit Type"::"Approver Chain", 0, '', BlankDateFormula, true);

        InsertSalesDocWithCreditLimitApprovalWorkflowSteps(
            Workflow,
            BuildSalesHeaderTypeConditionsText(Enum::"Sales Document Type"::Order, Enum::"Sales Document Status"::Open),
            BuildSalesHeaderTypeConditionsText(Enum::"Sales Document Type"::Order, Enum::"Sales Document Status"::"Pending Approval"),
            WorkflowStepArgument, true);
    end;

    local procedure InsertSalesDocWithCreditLimitApprovalWorkflowSteps(Workflow: Record Workflow; DocSentForApprovalConditionString: Text; DocCanceledConditionString: Text; WorkflowStepArgument: Record "Workflow Step Argument"; ShowConfirmationMessage: Boolean)
    var
        SentForApprovalEventID: Integer;
        CheckCustomerCreditLimitResponseID: Integer;
        CustomerCreditLimitExceededEventID: Integer;
        CustomerCreditLimitNotExceededEventID: Integer;
        SetStatusToPendingApprovalResponseID: Integer;
        CreateApprovalRequestResponseID: Integer;
        SendApprovalRequestResponseID: Integer;
        OnAllRequestsApprovedEventID: Integer;
        OnRequestApprovedEventID: Integer;
        SendApprovalRequestResponseID2: Integer;
        OnRequestRejectedEventID: Integer;
        RejectAllApprovalsResponseID: Integer;
        OnRequestCanceledEventID: Integer;
        CancelAllApprovalsResponseID: Integer;
        OnRequestDelegatedEventID: Integer;
        SentApprovalRequestResponseID3: Integer;
        SetStatusToPendingApprovalResponseID2: Integer;
        CreateAndApproveApprovalRequestResponseID: Integer;
        OpenDocumentResponseID: Integer;
        ShowMessageResponseID: Integer;
        RestrictRecordUsageResponseID: Integer;
        AllowRecordUsageResponseID: Integer;
    begin
        SentForApprovalEventID := InsertEntryPointEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnSendSalesDocForApprovalCode());
        InsertEventArgument(SentForApprovalEventID, DocSentForApprovalConditionString);

        CheckCustomerCreditLimitResponseID := InsertResponseStep(Workflow, WorkflowResponseHandling.CheckCustomerCreditLimitCode(),
            SentForApprovalEventID);

        CustomerCreditLimitExceededEventID := InsertEventStep(Workflow,
            WorkflowEventHandling.RunWorkflowOnCustomerCreditLimitExceededCode(), CheckCustomerCreditLimitResponseID);

        RestrictRecordUsageResponseID :=
          InsertResponseStep(Workflow, WorkflowResponseHandling.RestrictRecordUsageCode(), CustomerCreditLimitExceededEventID);

        SetStatusToPendingApprovalResponseID := InsertResponseStep(Workflow, WorkflowResponseHandling.SetStatusToPendingApprovalCode(),
            RestrictRecordUsageResponseID);
        CreateApprovalRequestResponseID := InsertResponseStep(Workflow, WorkflowResponseHandling.CreateApprovalRequestsCode(),
            SetStatusToPendingApprovalResponseID);
        InsertApprovalArgument(CreateApprovalRequestResponseID,
          WorkflowStepArgument."Approver Type", WorkflowStepArgument."Approver Limit Type",
          WorkflowStepArgument."Workflow User Group Code", WorkflowStepArgument."Approver User ID",
          WorkflowStepArgument."Due Date Formula", ShowConfirmationMessage);
        SendApprovalRequestResponseID := InsertResponseStep(Workflow, WorkflowResponseHandling.SendApprovalRequestForApprovalCode(),
            CreateApprovalRequestResponseID);

        InsertNotificationArgument(SendApprovalRequestResponseID, false, '', 0, '');

        OnAllRequestsApprovedEventID := InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode(),
            SendApprovalRequestResponseID);
        InsertEventArgument(OnAllRequestsApprovedEventID, BuildNoPendingApprovalsConditions());
        AllowRecordUsageResponseID :=
          InsertResponseStep(Workflow, WorkflowResponseHandling.AllowRecordUsageCode(), OnAllRequestsApprovedEventID);
        InsertResponseStep(Workflow, WorkflowResponseHandling.ReleaseDocumentCode(), AllowRecordUsageResponseID);

        OnRequestApprovedEventID := InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode(),
            SendApprovalRequestResponseID);
        InsertEventArgument(OnRequestApprovedEventID, BuildPendingApprovalsConditions());
        SendApprovalRequestResponseID2 := InsertResponseStep(Workflow, WorkflowResponseHandling.SendApprovalRequestForApprovalCode(),
            OnRequestApprovedEventID);

        SetNextStep(Workflow, SendApprovalRequestResponseID2, SendApprovalRequestResponseID);

        OnRequestRejectedEventID := InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnRejectApprovalRequestCode(),
            SendApprovalRequestResponseID);
        RejectAllApprovalsResponseID := InsertResponseStep(Workflow, WorkflowResponseHandling.RejectAllApprovalRequestsCode(),
            OnRequestRejectedEventID);
        InsertNotificationArgument(RejectAllApprovalsResponseID, true, '', WorkflowStepArgument."Link Target Page", '');
        InsertResponseStep(Workflow, WorkflowResponseHandling.OpenDocumentCode(), RejectAllApprovalsResponseID);

        OnRequestCanceledEventID := InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnCancelSalesApprovalRequestCode(),
            SendApprovalRequestResponseID);
        InsertEventArgument(OnRequestCanceledEventID, DocCanceledConditionString);
        CancelAllApprovalsResponseID := InsertResponseStep(Workflow, WorkflowResponseHandling.CancelAllApprovalRequestsCode(),
            OnRequestCanceledEventID);
        InsertNotificationArgument(CancelAllApprovalsResponseID, false, '', WorkflowStepArgument."Link Target Page", '');
        AllowRecordUsageResponseID :=
          InsertResponseStep(Workflow, WorkflowResponseHandling.AllowRecordUsageCode(), CancelAllApprovalsResponseID);
        OpenDocumentResponseID := InsertResponseStep(Workflow, WorkflowResponseHandling.OpenDocumentCode(), AllowRecordUsageResponseID);
        ShowMessageResponseID := InsertResponseStep(Workflow, WorkflowResponseHandling.ShowMessageCode(), OpenDocumentResponseID);
        InsertMessageArgument(ShowMessageResponseID, ApprovalRequestCanceledMsg);

        OnRequestDelegatedEventID := InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnDelegateApprovalRequestCode(),
            SendApprovalRequestResponseID);
        SentApprovalRequestResponseID3 := InsertResponseStep(Workflow, WorkflowResponseHandling.SendApprovalRequestForApprovalCode(),
            OnRequestDelegatedEventID);

        SetNextStep(Workflow, SentApprovalRequestResponseID3, SendApprovalRequestResponseID);

        CustomerCreditLimitNotExceededEventID := InsertEventStep(Workflow,
            WorkflowEventHandling.RunWorkflowOnCustomerCreditLimitNotExceededCode(), CheckCustomerCreditLimitResponseID);

        SetStatusToPendingApprovalResponseID2 := InsertResponseStep(Workflow, WorkflowResponseHandling.SetStatusToPendingApprovalCode(),
            CustomerCreditLimitNotExceededEventID);

        CreateAndApproveApprovalRequestResponseID := InsertResponseStep(Workflow,
            WorkflowResponseHandling.CreateAndApproveApprovalRequestAutomaticallyCode(), SetStatusToPendingApprovalResponseID2);
        InsertResponseStep(Workflow, WorkflowResponseHandling.ReleaseDocumentCode(),
          CreateAndApproveApprovalRequestResponseID);
    end;

    local procedure InsertOverdueApprovalsWorkflowTemplate()
    var
        Workflow: Record Workflow;
    begin
        InsertWorkflowTemplate(Workflow, OverdueWorkflowCodeTxt, OverdueWorkflowDescTxt, AdminCategoryTxt);
        InsertOverdueApprovalsWorkflowDetails(Workflow);
        MarkWorkflowAsTemplate(Workflow);
    end;

    procedure InsertOverdueApprovalsWorkflow(): Code[20]
    var
        Workflow: Record Workflow;
    begin
        InsertWorkflow(Workflow, GetWorkflowCode(OverdueWorkflowCodeTxt), OverdueWorkflowDescTxt, AdminCategoryTxt);
        InsertOverdueApprovalsWorkflowDetails(Workflow);
        exit(Workflow.Code);
    end;

    local procedure InsertOverdueApprovalsWorkflowDetails(var Workflow: Record Workflow)
    var
        OnSendOverdueNotificationsEventID: Integer;
    begin
        OnSendOverdueNotificationsEventID :=
          InsertEntryPointEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnSendOverdueNotificationsCode());
        InsertResponseStep(Workflow, WorkflowResponseHandling.CreateOverdueNotificationCode(), OnSendOverdueNotificationsEventID);
    end;

    local procedure InsertCustomerApprovalWorkflowTemplate()
    var
        Workflow: Record Workflow;
    begin
        InsertWorkflowTemplate(Workflow, CustomerApprWorkflowCodeTxt, CustomerApprWorkflowDescTxt, SalesMktCategoryTxt);
        InsertCustomerApprovalWorkflowDetails(Workflow);
        MarkWorkflowAsTemplate(Workflow);
    end;

    procedure InsertCustomerApprovalWorkflow()
    var
        Workflow: Record Workflow;
    begin
        InsertWorkflow(Workflow, GetWorkflowCode(CustomerApprWorkflowCodeTxt), CustomerApprWorkflowDescTxt, SalesMktCategoryTxt);
        InsertCustomerApprovalWorkflowDetails(Workflow);
    end;

    local procedure InsertCustomerApprovalWorkflowDetails(var Workflow: Record Workflow)
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        InitWorkflowStepArgument(
            WorkflowStepArgument, WorkflowStepArgument."Approver Type"::Approver,
            WorkflowStepArgument."Approver Limit Type"::"Direct Approver",
            0, '', BlankDateFormula, true);

        InsertRecApprovalWorkflowSteps(Workflow, BuildCustomerTypeConditions(),
          WorkflowEventHandling.RunWorkflowOnSendCustomerForApprovalCode(),
          WorkflowResponseHandling.CreateApprovalRequestsCode(),
          WorkflowResponseHandling.SendApprovalRequestForApprovalCode(),
          WorkflowEventHandling.RunWorkflowOnCancelCustomerApprovalRequestCode(),
          WorkflowStepArgument,
          true, true);
    end;

    local procedure InsertVendorApprovalWorkflowTemplate()
    var
        Workflow: Record Workflow;
    begin
        InsertWorkflowTemplate(Workflow, VendorApprWorkflowCodeTxt, VendorApprWorkflowDescTxt, PurchPayCategoryTxt);
        InsertVendorApprovalWorkflowDetails(Workflow);
        MarkWorkflowAsTemplate(Workflow);
    end;

    procedure InsertVendorApprovalWorkflow()
    var
        Workflow: Record Workflow;
    begin
        InsertWorkflow(Workflow, GetWorkflowCode(VendorApprWorkflowCodeTxt), VendorApprWorkflowDescTxt, PurchPayCategoryTxt);
        InsertVendorApprovalWorkflowDetails(Workflow);
    end;

    local procedure InsertVendorApprovalWorkflowDetails(var Workflow: Record Workflow)
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        InitWorkflowStepArgument(
            WorkflowStepArgument, WorkflowStepArgument."Approver Type"::Approver,
            WorkflowStepArgument."Approver Limit Type"::"Direct Approver",
            0, '', BlankDateFormula, true);

        InsertRecApprovalWorkflowSteps(Workflow, BuildVendorTypeConditions(),
          WorkflowEventHandling.RunWorkflowOnSendVendorForApprovalCode(),
          WorkflowResponseHandling.CreateApprovalRequestsCode(),
          WorkflowResponseHandling.SendApprovalRequestForApprovalCode(),
          WorkflowEventHandling.RunWorkflowOnCancelVendorApprovalRequestCode(),
          WorkflowStepArgument,
          true, true);
    end;

    local procedure InsertItemApprovalWorkflowTemplate()
    var
        Workflow: Record Workflow;
    begin
        InsertWorkflowTemplate(Workflow, ItemApprWorkflowCodeTxt, ItemApprWorkflowDescTxt, SalesMktCategoryTxt);
        InsertItemApprovalWorkflowDetails(Workflow);
        MarkWorkflowAsTemplate(Workflow);
    end;

    procedure InsertItemApprovalWorkflow()
    var
        Workflow: Record Workflow;
    begin
        InsertWorkflow(Workflow, GetWorkflowCode(ItemApprWorkflowCodeTxt), ItemApprWorkflowDescTxt, SalesMktCategoryTxt);
        InsertItemApprovalWorkflowDetails(Workflow);
    end;

    local procedure InsertItemApprovalWorkflowDetails(var Workflow: Record Workflow)
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        InitWorkflowStepArgument(
            WorkflowStepArgument, WorkflowStepArgument."Approver Type"::Approver,
            WorkflowStepArgument."Approver Limit Type"::"Direct Approver",
            0, '', BlankDateFormula, true);

        InsertRecApprovalWorkflowSteps(Workflow, BuildItemTypeConditions(),
          WorkflowEventHandling.RunWorkflowOnSendItemForApprovalCode(),
          WorkflowResponseHandling.CreateApprovalRequestsCode(),
          WorkflowResponseHandling.SendApprovalRequestForApprovalCode(),
          WorkflowEventHandling.RunWorkflowOnCancelItemApprovalRequestCode(),
          WorkflowStepArgument,
          true, true);
    end;

    local procedure InsertCustomerCreditLimitChangeApprovalWorkflowTemplate()
    var
        Workflow: Record Workflow;
    begin
        InsertWorkflowTemplate(Workflow, CustomerCredLmtChangeApprWorkflowCodeTxt,
          CustomerCredLmtChangeApprWorkflowDescTxt, SalesMktCategoryTxt);
        InsertCustomerCreditLimitChangeApprovalWorkflowDetails(Workflow);
        MarkWorkflowAsTemplate(Workflow);
    end;

    local procedure InsertCustomerCreditLimitChangeApprovalWorkflowDetails(var Workflow: Record Workflow)
    var
        Customer: Record Customer;
        WorkflowRule: Record "Workflow Rule";
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        InitWorkflowStepArgument(
            WorkflowStepArgument, WorkflowStepArgument."Approver Type"::"Workflow User Group",
            WorkflowStepArgument."Approver Limit Type"::"Direct Approver",
            0, '', BlankDateFormula, false);

        InsertRecChangedApprovalWorkflowSteps(Workflow, WorkflowRule.Operator::Increased,
          WorkflowEventHandling.RunWorkflowOnCustomerChangedCode(),
          WorkflowResponseHandling.CreateApprovalRequestsCode(),
          WorkflowResponseHandling.SendApprovalRequestForApprovalCode(),
          WorkflowStepArgument, DATABASE::Customer, Customer.FieldNo("Credit Limit (LCY)"),
          CustCredLmtChangeSentForAppTxt);
    end;

    local procedure InsertItemUnitPriceChangeApprovalWorkflowTemplate()
    var
        Workflow: Record Workflow;
    begin
        InsertWorkflowTemplate(Workflow, ItemUnitPriceChangeApprWorkflowCodeTxt,
          ItemUnitPriceChangeApprWorkflowDescTxt, SalesMktCategoryTxt);
        InsertItemUnitPriceChangeApprovalWorkflowDetails(Workflow);
        MarkWorkflowAsTemplate(Workflow);
    end;

    local procedure InsertItemUnitPriceChangeApprovalWorkflowDetails(var Workflow: Record Workflow)
    var
        Item: Record Item;
        WorkflowRule: Record "Workflow Rule";
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        InitWorkflowStepArgument(
            WorkflowStepArgument, WorkflowStepArgument."Approver Type"::"Workflow User Group",
            WorkflowStepArgument."Approver Limit Type"::"Direct Approver",
            0, '', BlankDateFormula, false);

        InsertRecChangedApprovalWorkflowSteps(Workflow, WorkflowRule.Operator::Increased,
          WorkflowEventHandling.RunWorkflowOnItemChangedCode(),
          WorkflowResponseHandling.CreateApprovalRequestsCode(),
          WorkflowResponseHandling.SendApprovalRequestForApprovalCode(),
          WorkflowStepArgument, DATABASE::Item, Item.FieldNo("Unit Price"),
          ItemUnitPriceChangeSentForAppTxt);
    end;

    local procedure InsertGeneralJournalBatchApprovalWorkflowTemplate()
    var
        Workflow: Record Workflow;
    begin
        InsertWorkflowTemplate(Workflow, GeneralJournalBatchApprWorkflowCodeTxt,
          GeneralJournalBatchApprWorkflowDescTxt, FinCategoryTxt);
        InsertGeneralJournalBatchApprovalWorkflowDetails(Workflow);
        MarkWorkflowAsTemplate(Workflow);
    end;

    local procedure InsertGeneralJournalBatchApprovalWorkflowDetails(var Workflow: Record Workflow)
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        InitWorkflowStepArgument(
            WorkflowStepArgument, WorkflowStepArgument."Approver Type"::Approver,
            WorkflowStepArgument."Approver Limit Type"::"Direct Approver",
            0, '', BlankDateFormula, true);

        InsertGenJnlBatchApprovalWorkflowSteps(Workflow, BuildGeneralJournalBatchTypeConditions(),
          WorkflowEventHandling.RunWorkflowOnSendGeneralJournalBatchForApprovalCode(),
          WorkflowResponseHandling.CreateApprovalRequestsCode(),
          WorkflowResponseHandling.SendApprovalRequestForApprovalCode(),
          WorkflowEventHandling.RunWorkflowOnCancelGeneralJournalBatchApprovalRequestCode(),
          WorkflowStepArgument, true);
    end;

    local procedure InsertGeneralJournalLineApprovalWorkflowTemplate()
    var
        Workflow: Record Workflow;
    begin
        InsertWorkflowTemplate(Workflow, GeneralJournalLineApprWorkflowCodeTxt,
          GeneralJournalLineApprWorkflowDescTxt, FinCategoryTxt);
        InsertGeneralJournalLineApprovalWorkflowDetails(Workflow);
        MarkWorkflowAsTemplate(Workflow);
    end;

    local procedure InsertGeneralJournalLineApprovalWorkflowDetails(var Workflow: Record Workflow)
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        InitWorkflowStepArgument(
            WorkflowStepArgument, WorkflowStepArgument."Approver Type"::Approver,
            WorkflowStepArgument."Approver Limit Type"::"Direct Approver",
            0, '', BlankDateFormula, false);

        GenJournalLine.Init();
        InsertRecApprovalWorkflowSteps(Workflow, BuildGeneralJournalLineTypeConditions(GenJournalLine),
          WorkflowEventHandling.RunWorkflowOnSendGeneralJournalLineForApprovalCode(),
          WorkflowResponseHandling.CreateApprovalRequestsCode(),
          WorkflowResponseHandling.SendApprovalRequestForApprovalCode(),
          WorkflowEventHandling.RunWorkflowOnCancelGeneralJournalLineApprovalRequestCode(),
          WorkflowStepArgument,
          false, false);
    end;

    local procedure InsertRequisitionWkshBatchApprovalWorkflowTemplate()
    var
        Workflow: Record Workflow;
    begin
        InsertWorkflowTemplate(Workflow, RequisitionWkshBatchApprWorkflowCodeTxt, RequisitionWkshBatchApprWorkflowDescTxt, PurchPayCategoryTxt);
        InsertRequisitionWkshBatchApprovalWorkflowDetails(Workflow);
        MarkWorkflowAsTemplate(Workflow);
    end;

    local procedure InsertRequisitionWkshBatchApprovalWorkflowDetails(var Workflow: Record Workflow)
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        InitWorkflowStepArgument(
            WorkflowStepArgument, WorkflowStepArgument."Approver Type"::Approver,
            WorkflowStepArgument."Approver Limit Type"::"Direct Approver",
            0, '', BlankDateFormula, true);

        InsertRequisitionWkshBatchApprovalWorkflowSteps(Workflow, BuildRequisitionWkshBatchTypeConditions(),
            WorkflowEventHandling.RunWorkflowOnSendRequisitionWkshBatchForApprovalCode(),
            WorkflowResponseHandling.CreateApprovalRequestsCode(),
            WorkflowResponseHandling.SendApprovalRequestForApprovalCode(),
            WorkflowEventHandling.RunWorkflowOnCancelRequisitionWkshBatchApprovalRequestCode(),
            WorkflowStepArgument, true);
    end;

    local procedure InsertJobQueueEntryApprovalWorkflowTemplate()
    var
        Workflow: Record Workflow;
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        WorkflowSetup.InsertWorkflowTemplate(Workflow, JobQueueEntryApprWorkflowCodeTxt, JobQueueEntryApprWorkflowDescTxt, AdminCategoryTxt);
        InsertJobQueueEntryApprovalWorkflowDetails(Workflow);
        WorkflowSetup.MarkWorkflowAsTemplate(Workflow);
    end;

    procedure JobQueueEntryWorkflowCode(): Code[17]
    begin
        exit(JobQueueEntryApprWorkflowCodeTxt);
    end;

    procedure IncomingDocumentWorkflowCode(): Code[17]
    begin
        exit(IncDocWorkflowCodeTxt);
    end;

    procedure IncomingDocumentApprovalWorkflowCode(): Code[17]
    begin
        exit(IncomingDocumentApprWorkflowCodeTxt);
    end;

    procedure IncomingDocumentOCRWorkflowCode(): Code[17]
    begin
        exit(IncDocOCRWorkflowCodeTxt);
    end;

    procedure IncomingDocumentToGenJnlLineOCRWorkflowCode(): Code[17]
    begin
        exit(IncDocToGenJnlLineOCRWorkflowCodeTxt);
    end;

    procedure PurchaseInvoiceWorkflowCode(): Code[17]
    begin
        exit(PurchInvWorkflowCodeTxt);
    end;

    procedure PurchaseInvoiceApprovalWorkflowCode(): Code[17]
    begin
        exit(PurchInvoiceApprWorkflowCodeTxt);
    end;

    procedure PurchaseBlanketOrderApprovalWorkflowCode(): Code[17]
    begin
        exit(PurchBlanketOrderApprWorkflowCodeTxt);
    end;

    procedure PurchaseCreditMemoApprovalWorkflowCode(): Code[17]
    begin
        exit(PurchCreditMemoApprWorkflowCodeTxt);
    end;

    procedure PurchaseQuoteApprovalWorkflowCode(): Code[17]
    begin
        exit(PurchQuoteApprWorkflowCodeTxt);
    end;

    procedure PurchaseOrderApprovalWorkflowCode(): Code[17]
    begin
        exit(PurchOrderApprWorkflowCodeTxt);
    end;

    procedure PurchaseReturnOrderApprovalWorkflowCode(): Code[17]
    begin
        exit(PurchReturnOrderApprWorkflowCodeTxt);
    end;

    procedure SalesInvoiceApprovalWorkflowCode(): Code[17]
    begin
        exit(SalesInvoiceApprWorkflowCodeTxt);
    end;

    procedure SalesBlanketOrderApprovalWorkflowCode(): Code[17]
    begin
        exit(SalesBlanketOrderApprWorkflowCodeTxt);
    end;

    procedure SalesCreditMemoApprovalWorkflowCode(): Code[17]
    begin
        exit(SalesCreditMemoApprWorkflowCodeTxt);
    end;

    procedure SalesQuoteApprovalWorkflowCode(): Code[17]
    begin
        exit(SalesQuoteApprWorkflowCodeTxt);
    end;

    procedure SalesOrderApprovalWorkflowCode(): Code[17]
    begin
        exit(SalesOrderApprWorkflowCodeTxt);
    end;

    procedure SalesReturnOrderApprovalWorkflowCode(): Code[17]
    begin
        exit(SalesReturnOrderApprWorkflowCodeTxt);
    end;

    procedure OverdueNotificationsWorkflowCode(): Code[17]
    begin
        exit(OverdueWorkflowCodeTxt);
    end;

    procedure SalesInvoiceCreditLimitApprovalWorkflowCode(): Code[17]
    begin
        exit(SalesInvoiceCreditLimitApprWorkflowCodeTxt);
    end;

    procedure SalesOrderCreditLimitApprovalWorkflowCode(): Code[17]
    begin
        exit(SalesOrderCreditLimitApprWorkflowCodeTxt);
    end;

    procedure CustomerWorkflowCode(): Code[17]
    begin
        exit(CustomerApprWorkflowCodeTxt);
    end;

    procedure CustomerCreditLimitChangeApprovalWorkflowCode(): Code[17]
    begin
        exit(CustomerCredLmtChangeApprWorkflowCodeTxt);
    end;

    procedure VendorWorkflowCode(): Code[17]
    begin
        exit(VendorApprWorkflowCodeTxt);
    end;

    procedure ItemWorkflowCode(): Code[17]
    begin
        exit(ItemApprWorkflowCodeTxt);
    end;

    procedure ItemUnitPriceChangeApprovalWorkflowCode(): Code[17]
    begin
        exit(ItemUnitPriceChangeApprWorkflowCodeTxt);
    end;

    procedure GeneralJournalBatchApprovalWorkflowCode(): Code[17]
    begin
        exit(GeneralJournalBatchApprWorkflowCodeTxt);
    end;

    procedure GeneralJournalLineApprovalWorkflowCode(): Code[17]
    begin
        exit(GeneralJournalLineApprWorkflowCodeTxt);
    end;

    procedure RequisitionWkshBatchApprovalWorkflowCode(): Code[17]
    begin
        exit(RequisitionWkshBatchApprWorkflowCodeTxt);
    end;

    procedure SendToOCRWorkflowCode(): Code[17]
    begin
        exit(SendToOCRWorkflowCodeTxt);
    end;

    procedure InsertDocApprovalWorkflowSteps(Workflow: Record Workflow; DocSendForApprovalConditionString: Text; DocSendForApprovalEventCode: Code[128]; DocCanceledConditionString: Text; DocCanceledEventCode: Code[128]; WorkflowStepArgument: Record "Workflow Step Argument"; ShowConfirmationMessage: Boolean)
    var
        SentForApprovalEventID: Integer;
        SetStatusToPendingApprovalResponseID: Integer;
        CreateApprovalRequestResponseID: Integer;
        SendApprovalRequestResponseID: Integer;
        OnAllRequestsApprovedEventID: Integer;
        OnRequestApprovedEventID: Integer;
        SendApprovalRequestResponseID2: Integer;
        OnRequestRejectedEventID: Integer;
        RejectAllApprovalsResponseID: Integer;
        OnRequestCanceledEventID: Integer;
        CancelAllApprovalsResponseID: Integer;
        OnRequestDelegatedEventID: Integer;
        SentApprovalRequestResponseID3: Integer;
        RestrictRecordUsageResponseID: Integer;
        AllowRecordUsageResponseID: Integer;
        OpenDocumentResponceID: Integer;
        ShowMessageResponseID: Integer;
    begin
        SentForApprovalEventID := InsertEntryPointEventStep(Workflow, DocSendForApprovalEventCode);
        InsertEventArgument(SentForApprovalEventID, DocSendForApprovalConditionString);

        RestrictRecordUsageResponseID := InsertResponseStep(Workflow, WorkflowResponseHandling.RestrictRecordUsageCode(),
            SentForApprovalEventID);
        SetStatusToPendingApprovalResponseID := InsertResponseStep(Workflow, WorkflowResponseHandling.SetStatusToPendingApprovalCode(),
            RestrictRecordUsageResponseID);
        CreateApprovalRequestResponseID := InsertResponseStep(Workflow, WorkflowResponseHandling.CreateApprovalRequestsCode(),
            SetStatusToPendingApprovalResponseID);
        InsertApprovalArgument(CreateApprovalRequestResponseID,
          WorkflowStepArgument."Approver Type", WorkflowStepArgument."Approver Limit Type",
          WorkflowStepArgument."Workflow User Group Code", WorkflowStepArgument."Approver User ID",
          WorkflowStepArgument."Due Date Formula", ShowConfirmationMessage);
        SendApprovalRequestResponseID := InsertResponseStep(Workflow, WorkflowResponseHandling.SendApprovalRequestForApprovalCode(),
            CreateApprovalRequestResponseID);
        InsertNotificationArgument(SendApprovalRequestResponseID, false, '', 0, '');

        OnAllRequestsApprovedEventID := InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode(),
            SendApprovalRequestResponseID);
        InsertEventArgument(OnAllRequestsApprovedEventID, BuildNoPendingApprovalsConditions());
        AllowRecordUsageResponseID :=
          InsertResponseStep(Workflow, WorkflowResponseHandling.AllowRecordUsageCode(), OnAllRequestsApprovedEventID);
        InsertResponseStep(Workflow, WorkflowResponseHandling.ReleaseDocumentCode(), AllowRecordUsageResponseID);

        OnRequestApprovedEventID := InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode(),
            SendApprovalRequestResponseID);
        InsertEventArgument(OnRequestApprovedEventID, BuildPendingApprovalsConditions());
        SendApprovalRequestResponseID2 := InsertResponseStep(Workflow, WorkflowResponseHandling.SendApprovalRequestForApprovalCode(),
            OnRequestApprovedEventID);

        SetNextStep(Workflow, SendApprovalRequestResponseID2, SendApprovalRequestResponseID);

        OnRequestRejectedEventID := InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnRejectApprovalRequestCode(),
            SendApprovalRequestResponseID);
        RejectAllApprovalsResponseID := InsertResponseStep(Workflow, WorkflowResponseHandling.RejectAllApprovalRequestsCode(),
            OnRequestRejectedEventID);
        InsertNotificationArgument(RejectAllApprovalsResponseID, true, '', WorkflowStepArgument."Link Target Page", '');
        InsertResponseStep(Workflow, WorkflowResponseHandling.OpenDocumentCode(), RejectAllApprovalsResponseID);

        OnRequestCanceledEventID := InsertEventStep(Workflow, DocCanceledEventCode,
            SendApprovalRequestResponseID);
        InsertEventArgument(OnRequestCanceledEventID, DocCanceledConditionString);
        CancelAllApprovalsResponseID := InsertResponseStep(Workflow, WorkflowResponseHandling.CancelAllApprovalRequestsCode(),
            OnRequestCanceledEventID);
        InsertNotificationArgument(CancelAllApprovalsResponseID, false, '', WorkflowStepArgument."Link Target Page", '');
        AllowRecordUsageResponseID :=
          InsertResponseStep(Workflow, WorkflowResponseHandling.AllowRecordUsageCode(), CancelAllApprovalsResponseID);
        OpenDocumentResponceID := InsertResponseStep(Workflow, WorkflowResponseHandling.OpenDocumentCode(), AllowRecordUsageResponseID);
        ShowMessageResponseID := InsertResponseStep(Workflow, WorkflowResponseHandling.ShowMessageCode(), OpenDocumentResponceID);
        InsertMessageArgument(ShowMessageResponseID, ApprovalRequestCanceledMsg);

        OnRequestDelegatedEventID := InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnDelegateApprovalRequestCode(),
            SendApprovalRequestResponseID);
        SentApprovalRequestResponseID3 := InsertResponseStep(Workflow, WorkflowResponseHandling.SendApprovalRequestForApprovalCode(),
            OnRequestDelegatedEventID);

        SetNextStep(Workflow, SentApprovalRequestResponseID3, SendApprovalRequestResponseID);
    end;

    procedure InsertRecApprovalWorkflowSteps(Workflow: Record Workflow; ConditionString: Text; RecSendForApprovalEventCode: Code[128]; RecCreateApprovalRequestsCode: Code[128]; RecSendApprovalRequestForApprovalCode: Code[128]; RecCanceledEventCode: Code[128]; WorkflowStepArgument: Record "Workflow Step Argument"; ShowConfirmationMessage: Boolean; RemoveRestrictionOnCancel: Boolean)
    var
        SentForApprovalEventID: Integer;
        CreateApprovalRequestResponseID: Integer;
        SendApprovalRequestResponseID: Integer;
        OnAllRequestsApprovedEventID: Integer;
        OnRequestApprovedEventID: Integer;
        SendApprovalRequestResponseID2: Integer;
        OnRequestRejectedEventID: Integer;
        RejectAllApprovalsResponseID: Integer;
        OnRequestCanceledEventID: Integer;
        CancelAllApprovalsResponseID: Integer;
        OnRequestDelegatedEventID: Integer;
        SentApprovalRequestResponseID3: Integer;
        RestrictUsageResponseID: Integer;
        AllowRecordUsageResponseID: Integer;
        ShowMessageResponseID: Integer;
        TempResponseResponseID: Integer;
    begin
        SentForApprovalEventID := InsertEntryPointEventStep(Workflow, RecSendForApprovalEventCode);
        InsertEventArgument(SentForApprovalEventID, ConditionString);

        RestrictUsageResponseID := InsertResponseStep(Workflow, WorkflowResponseHandling.RestrictRecordUsageCode(),
            SentForApprovalEventID);
        CreateApprovalRequestResponseID := InsertResponseStep(Workflow, RecCreateApprovalRequestsCode,
            RestrictUsageResponseID);
        InsertApprovalArgument(CreateApprovalRequestResponseID,
          WorkflowStepArgument."Approver Type", WorkflowStepArgument."Approver Limit Type",
          WorkflowStepArgument."Workflow User Group Code", WorkflowStepArgument."Approver User ID",
          WorkflowStepArgument."Due Date Formula", ShowConfirmationMessage);
        SendApprovalRequestResponseID := InsertResponseStep(Workflow, RecSendApprovalRequestForApprovalCode,
            CreateApprovalRequestResponseID);
        InsertNotificationArgument(SendApprovalRequestResponseID, false, '', 0, '');

        OnAllRequestsApprovedEventID := InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode(),
            SendApprovalRequestResponseID);
        InsertEventArgument(OnAllRequestsApprovedEventID, BuildNoPendingApprovalsConditions());
        InsertResponseStep(Workflow, WorkflowResponseHandling.AllowRecordUsageCode(), OnAllRequestsApprovedEventID);

        OnRequestApprovedEventID := InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode(),
            SendApprovalRequestResponseID);
        InsertEventArgument(OnRequestApprovedEventID, BuildPendingApprovalsConditions());
        SendApprovalRequestResponseID2 := InsertResponseStep(Workflow, WorkflowResponseHandling.SendApprovalRequestForApprovalCode(),
            OnRequestApprovedEventID);

        SetNextStep(Workflow, SendApprovalRequestResponseID2, SendApprovalRequestResponseID);

        OnRequestRejectedEventID := InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnRejectApprovalRequestCode(),
            SendApprovalRequestResponseID);
        RejectAllApprovalsResponseID := InsertResponseStep(Workflow, WorkflowResponseHandling.RejectAllApprovalRequestsCode(),
            OnRequestRejectedEventID);
        InsertNotificationArgument(RejectAllApprovalsResponseID, true, '', WorkflowStepArgument."Link Target Page", '');

        OnRequestCanceledEventID := InsertEventStep(Workflow, RecCanceledEventCode, SendApprovalRequestResponseID);
        CancelAllApprovalsResponseID := InsertResponseStep(Workflow, WorkflowResponseHandling.CancelAllApprovalRequestsCode(),
            OnRequestCanceledEventID);
        InsertNotificationArgument(CancelAllApprovalsResponseID, false, '', WorkflowStepArgument."Link Target Page", '');

        TempResponseResponseID := CancelAllApprovalsResponseID;
        if RemoveRestrictionOnCancel then begin
            AllowRecordUsageResponseID :=
              InsertResponseStep(Workflow, WorkflowResponseHandling.AllowRecordUsageCode(), CancelAllApprovalsResponseID);
            TempResponseResponseID := AllowRecordUsageResponseID;
        end;
        if ShowConfirmationMessage then begin
            ShowMessageResponseID := InsertResponseStep(Workflow, WorkflowResponseHandling.ShowMessageCode(), TempResponseResponseID);
            InsertMessageArgument(ShowMessageResponseID, ApprovalRequestCanceledMsg);
        end;

        OnRequestDelegatedEventID := InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnDelegateApprovalRequestCode(),
            SendApprovalRequestResponseID);
        SentApprovalRequestResponseID3 := InsertResponseStep(Workflow, WorkflowResponseHandling.SendApprovalRequestForApprovalCode(),
            OnRequestDelegatedEventID);

        SetNextStep(Workflow, SentApprovalRequestResponseID3, SendApprovalRequestResponseID);
    end;

    procedure InsertRecChangedApprovalWorkflowSteps(Workflow: Record Workflow; RuleOperator: Option; RecChangedEventCode: Code[128]; RecCreateApprovalRequestsCode: Code[128]; RecSendApprovalRequestForApprovalCode: Code[128]; var WorkflowStepArgument: Record "Workflow Step Argument"; TableNo: Integer; FieldNo: Integer; RecordChangeApprovalMsg: Text)
    var
        CustomerChangedEventID: Integer;
        RevertFieldResponseID: Integer;
        CreateApprovalRequestResponseID: Integer;
        SendApprovalRequestResponseID: Integer;
        OnAllRequestsApprovedEventID: Integer;
        OnRequestApprovedEventID: Integer;
        SendApprovalRequestResponseID2: Integer;
        OnRequestRejectedEventID: Integer;
        RejectAllApprovalsResponseID: Integer;
        DiscardNewValuesResponseID: Integer;
        OnRequestDelegatedEventID: Integer;
        SentApprovalRequestResponseID3: Integer;
        ShowMessageResponseID: Integer;
        ApplyNewValuesResponseID: Integer;
    begin
        CustomerChangedEventID := InsertEntryPointEventStep(Workflow, RecChangedEventCode);
        InsertEventRule(CustomerChangedEventID, FieldNo, RuleOperator);

        RevertFieldResponseID := InsertResponseStep(Workflow, WorkflowResponseHandling.RevertValueForFieldCode(),
            CustomerChangedEventID);
        InsertChangeRecValueArgument(RevertFieldResponseID, TableNo, FieldNo);
        CreateApprovalRequestResponseID := InsertResponseStep(Workflow, RecCreateApprovalRequestsCode,
            RevertFieldResponseID);
        InsertApprovalArgument(
            CreateApprovalRequestResponseID, WorkflowStepArgument."Approver Type",
            WorkflowStepArgument."Approver Limit Type", WorkflowStepArgument."Workflow User Group Code",
            WorkflowStepArgument."Approver User ID", WorkflowStepArgument."Due Date Formula", false);
        SendApprovalRequestResponseID := InsertResponseStep(Workflow, RecSendApprovalRequestForApprovalCode,
            CreateApprovalRequestResponseID);
        InsertNotificationArgument(SendApprovalRequestResponseID, false, '', 0, '');
        ShowMessageResponseID := InsertResponseStep(Workflow, WorkflowResponseHandling.ShowMessageCode(),
            SendApprovalRequestResponseID);
        InsertMessageArgument(ShowMessageResponseID, CopyStr(RecordChangeApprovalMsg, 1, 250));

        OnAllRequestsApprovedEventID := InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode(),
            ShowMessageResponseID);
        InsertEventArgument(OnAllRequestsApprovedEventID, BuildNoPendingApprovalsConditions());
        ApplyNewValuesResponseID := InsertResponseStep(Workflow, WorkflowResponseHandling.ApplyNewValuesCode(),
            OnAllRequestsApprovedEventID);
        InsertChangeRecValueArgument(ApplyNewValuesResponseID, TableNo, FieldNo);

        OnRequestApprovedEventID := InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode(),
            ShowMessageResponseID);
        InsertEventArgument(OnRequestApprovedEventID, BuildPendingApprovalsConditions());
        SendApprovalRequestResponseID2 := InsertResponseStep(Workflow, WorkflowResponseHandling.SendApprovalRequestForApprovalCode(),
            OnRequestApprovedEventID);

        SetNextStep(Workflow, SendApprovalRequestResponseID2, ShowMessageResponseID);

        OnRequestRejectedEventID := InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnRejectApprovalRequestCode(),
            ShowMessageResponseID);
        DiscardNewValuesResponseID := InsertResponseStep(Workflow, WorkflowResponseHandling.DiscardNewValuesCode(),
            OnRequestRejectedEventID);
        RejectAllApprovalsResponseID := InsertResponseStep(Workflow, WorkflowResponseHandling.RejectAllApprovalRequestsCode(),
            DiscardNewValuesResponseID);
        InsertNotificationArgument(RejectAllApprovalsResponseID, true, '', WorkflowStepArgument."Link Target Page", '');

        OnRequestDelegatedEventID := InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnDelegateApprovalRequestCode(),
            ShowMessageResponseID);
        SentApprovalRequestResponseID3 := InsertResponseStep(Workflow, WorkflowResponseHandling.SendApprovalRequestForApprovalCode(),
            OnRequestDelegatedEventID);

        SetNextStep(Workflow, SentApprovalRequestResponseID3, ShowMessageResponseID);
    end;

    procedure InsertGenJnlBatchApprovalWorkflowSteps(Workflow: Record Workflow; ConditionString: Text; RecSendForApprovalEventCode: Code[128]; RecCreateApprovalRequestsCode: Code[128]; RecSendApprovalRequestForApprovalCode: Code[128]; RecCanceledEventCode: Code[128]; WorkflowStepArgument: Record "Workflow Step Argument"; ShowConfirmationMessage: Boolean)
    var
        SentForApprovalEventID: Integer;
        CheckBatchBalanceResponseID: Integer;
        OnBatchIsBalancedEventID: Integer;
        OnBatchIsNotBalancedEventID: Integer;
        CreateApprovalRequestResponseID: Integer;
        SendApprovalRequestResponseID: Integer;
        OnAllRequestsApprovedEventID: Integer;
        OnRequestApprovedEventID: Integer;
        SendApprovalRequestResponseID2: Integer;
        OnRequestRejectedEventID: Integer;
        RejectAllApprovalsResponseID: Integer;
        OnRequestCanceledEventID: Integer;
        CancelAllApprovalsResponseID: Integer;
        OnRequestDelegatedEventID: Integer;
        SentApprovalRequestResponseID3: Integer;
        ShowMessageResponseID: Integer;
        RestrictUsageResponseID: Integer;
    begin
        SentForApprovalEventID := InsertEntryPointEventStep(Workflow, RecSendForApprovalEventCode);
        InsertEventArgument(SentForApprovalEventID, ConditionString);

        CheckBatchBalanceResponseID := InsertResponseStep(Workflow, WorkflowResponseHandling.CheckGeneralJournalBatchBalanceCode(),
            SentForApprovalEventID);

        OnBatchIsBalancedEventID := InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnGeneralJournalBatchBalancedCode(),
            CheckBatchBalanceResponseID);

        RestrictUsageResponseID := InsertResponseStep(Workflow, WorkflowResponseHandling.RestrictRecordUsageCode(),
            OnBatchIsBalancedEventID);
        CreateApprovalRequestResponseID := InsertResponseStep(Workflow, RecCreateApprovalRequestsCode,
            RestrictUsageResponseID);
        InsertApprovalArgument(CreateApprovalRequestResponseID,
          WorkflowStepArgument."Approver Type", WorkflowStepArgument."Approver Limit Type",
          WorkflowStepArgument."Workflow User Group Code", WorkflowStepArgument."Approver User ID",
          WorkflowStepArgument."Due Date Formula", ShowConfirmationMessage);
        SendApprovalRequestResponseID := InsertResponseStep(Workflow, RecSendApprovalRequestForApprovalCode,
            CreateApprovalRequestResponseID);
        InsertNotificationArgument(SendApprovalRequestResponseID, false, '', 0, '');

        OnAllRequestsApprovedEventID := InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode(),
            SendApprovalRequestResponseID);
        InsertEventArgument(OnAllRequestsApprovedEventID, BuildNoPendingApprovalsConditions());
        InsertResponseStep(Workflow, WorkflowResponseHandling.AllowRecordUsageCode(), OnAllRequestsApprovedEventID);

        OnRequestApprovedEventID := InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode(),
            SendApprovalRequestResponseID);
        InsertEventArgument(OnRequestApprovedEventID, BuildPendingApprovalsConditions());
        SendApprovalRequestResponseID2 := InsertResponseStep(Workflow, WorkflowResponseHandling.SendApprovalRequestForApprovalCode(),
            OnRequestApprovedEventID);

        SetNextStep(Workflow, SendApprovalRequestResponseID2, SendApprovalRequestResponseID);

        OnRequestRejectedEventID := InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnRejectApprovalRequestCode(),
            SendApprovalRequestResponseID);
        RejectAllApprovalsResponseID := InsertResponseStep(Workflow, WorkflowResponseHandling.RejectAllApprovalRequestsCode(),
            OnRequestRejectedEventID);
        InsertNotificationArgument(RejectAllApprovalsResponseID, true, '', WorkflowStepArgument."Link Target Page", '');

        OnRequestCanceledEventID := InsertEventStep(Workflow, RecCanceledEventCode, SendApprovalRequestResponseID);
        CancelAllApprovalsResponseID := InsertResponseStep(Workflow, WorkflowResponseHandling.CancelAllApprovalRequestsCode(),
            OnRequestCanceledEventID);
        InsertNotificationArgument(CancelAllApprovalsResponseID, false, '', WorkflowStepArgument."Link Target Page", '');
        ShowMessageResponseID := InsertResponseStep(Workflow, WorkflowResponseHandling.ShowMessageCode(), CancelAllApprovalsResponseID);
        InsertMessageArgument(ShowMessageResponseID, ApprovalRequestCanceledMsg);

        OnRequestDelegatedEventID := InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnDelegateApprovalRequestCode(),
            SendApprovalRequestResponseID);
        SentApprovalRequestResponseID3 := InsertResponseStep(Workflow, WorkflowResponseHandling.SendApprovalRequestForApprovalCode(),
            OnRequestDelegatedEventID);

        SetNextStep(Workflow, SentApprovalRequestResponseID3, SendApprovalRequestResponseID);

        OnBatchIsNotBalancedEventID := InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnGeneralJournalBatchNotBalancedCode(),
            CheckBatchBalanceResponseID);

        ShowMessageResponseID := InsertResponseStep(Workflow, WorkflowResponseHandling.ShowMessageCode(), OnBatchIsNotBalancedEventID);
        InsertMessageArgument(ShowMessageResponseID, GeneralJournalBatchIsNotBalancedMsg);
    end;

    procedure InsertGenJnlLineApprovalWorkflowSteps(var Workflow: Record Workflow; EventConditions: Text; ApproverType: Enum "Workflow Approver Type"; LimitType: Enum "Workflow Approver Limit Type"; WorkflowUserGroupCode: Code[20]; SpecificApprover: Code[50]; DueDateFormula: DateFormula)
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        InitWorkflowStepArgument(WorkflowStepArgument, ApproverType, LimitType, 0, WorkflowUserGroupCode, DueDateFormula, true);
        WorkflowStepArgument."Approver User ID" := SpecificApprover;

        InsertRecApprovalWorkflowSteps(Workflow, EventConditions,
          WorkflowEventHandling.RunWorkflowOnSendGeneralJournalLineForApprovalCode(),
          WorkflowResponseHandling.CreateApprovalRequestsCode(),
          WorkflowResponseHandling.SendApprovalRequestForApprovalCode(),
          WorkflowEventHandling.RunWorkflowOnCancelGeneralJournalLineApprovalRequestCode(),
          WorkflowStepArgument,
          false, false);
    end;

    procedure InsertRequisitionWkshBatchApprovalWorkflowSteps(Workflow: Record Workflow; ConditionString: Text; RecSendForApprovalEventCode: Code[128]; RecCreateApprovalRequestsCode: Code[128]; RecSendApprovalRequestForApprovalCode: Code[128]; RecCanceledEventCode: Code[128]; WorkflowStepArgument: Record "Workflow Step Argument"; ShowConfirmationMessage: Boolean)
    var
        SentForApprovalEventID: Integer;
        CreateApprovalRequestResponseID: Integer;
        SendApprovalRequestResponseID: Integer;
        OnAllRequestsApprovedEventID: Integer;
        OnRequestApprovedEventID: Integer;
        SendApprovalRequestResponseID2: Integer;
        OnRequestRejectedEventID: Integer;
        RejectAllApprovalsResponseID: Integer;
        OnRequestCanceledEventID: Integer;
        CancelAllApprovalsResponseID: Integer;
        OnRequestDelegatedEventID: Integer;
        SentApprovalRequestResponseID3: Integer;
        ShowMessageResponseID: Integer;
        RestrictUsageResponseID: Integer;
    begin
        SentForApprovalEventID := InsertEntryPointEventStep(Workflow, RecSendForApprovalEventCode);
        InsertEventArgument(SentForApprovalEventID, ConditionString);

        RestrictUsageResponseID := InsertResponseStep(Workflow, WorkflowResponseHandling.RestrictRecordUsageCode(),
            SentForApprovalEventID);
        CreateApprovalRequestResponseID := InsertResponseStep(Workflow, RecCreateApprovalRequestsCode,
            RestrictUsageResponseID);
        InsertApprovalArgument(CreateApprovalRequestResponseID,
          WorkflowStepArgument."Approver Type", WorkflowStepArgument."Approver Limit Type",
          WorkflowStepArgument."Workflow User Group Code", WorkflowStepArgument."Approver User ID",
          WorkflowStepArgument."Due Date Formula", ShowConfirmationMessage);
        SendApprovalRequestResponseID := InsertResponseStep(Workflow, RecSendApprovalRequestForApprovalCode,
            CreateApprovalRequestResponseID);
        InsertNotificationArgument(SendApprovalRequestResponseID, false, '', 0, '');

        OnAllRequestsApprovedEventID := InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode(),
            SendApprovalRequestResponseID);
        InsertEventArgument(OnAllRequestsApprovedEventID, BuildNoPendingApprovalsConditions());
        InsertResponseStep(Workflow, WorkflowResponseHandling.AllowRecordUsageCode(), OnAllRequestsApprovedEventID);

        OnRequestApprovedEventID := InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode(),
            SendApprovalRequestResponseID);
        InsertEventArgument(OnRequestApprovedEventID, BuildPendingApprovalsConditions());
        SendApprovalRequestResponseID2 := InsertResponseStep(Workflow, WorkflowResponseHandling.SendApprovalRequestForApprovalCode(),
            OnRequestApprovedEventID);

        SetNextStep(Workflow, SendApprovalRequestResponseID2, SendApprovalRequestResponseID);

        OnRequestRejectedEventID := InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnRejectApprovalRequestCode(),
            SendApprovalRequestResponseID);
        RejectAllApprovalsResponseID := InsertResponseStep(Workflow, WorkflowResponseHandling.RejectAllApprovalRequestsCode(),
            OnRequestRejectedEventID);
        InsertNotificationArgument(RejectAllApprovalsResponseID, true, '', WorkflowStepArgument."Link Target Page", '');

        OnRequestCanceledEventID := InsertEventStep(Workflow, RecCanceledEventCode, SendApprovalRequestResponseID);
        CancelAllApprovalsResponseID := InsertResponseStep(Workflow, WorkflowResponseHandling.CancelAllApprovalRequestsCode(),
            OnRequestCanceledEventID);
        InsertNotificationArgument(CancelAllApprovalsResponseID, false, '', WorkflowStepArgument."Link Target Page", '');
        ShowMessageResponseID := InsertResponseStep(Workflow, WorkflowResponseHandling.ShowMessageCode(), CancelAllApprovalsResponseID);
        InsertMessageArgument(ShowMessageResponseID, ApprovalRequestCanceledMsg);

        OnRequestDelegatedEventID := InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnDelegateApprovalRequestCode(),
            SendApprovalRequestResponseID);
        SentApprovalRequestResponseID3 := InsertResponseStep(Workflow, WorkflowResponseHandling.SendApprovalRequestForApprovalCode(),
            OnRequestDelegatedEventID);

        SetNextStep(Workflow, SentApprovalRequestResponseID3, SendApprovalRequestResponseID);
    end;

    procedure InsertPurchaseDocumentApprovalWorkflowSteps(var Workflow: Record Workflow; DocumentType: Enum "Purchase Document Type"; ApproverType: Enum "Workflow Approver Type"; LimitType: Enum "Workflow Approver Limit Type"; WorkflowUserGroupCode: Code[20]; DueDateFormula: DateFormula)
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        case DocumentType of
            "Purchase Document Type"::Order:
                InsertWorkflow(
                    Workflow, GetWorkflowCode(PurchOrderApprWorkflowCodeTxt),
                    PurchOrderApprWorkflowDescTxt, PurchDocCategoryTxt);
            "Purchase Document Type"::Invoice:
                InsertWorkflow(
                    Workflow, GetWorkflowCode(PurchInvoiceApprWorkflowCodeTxt),
                    PurchInvoiceApprWorkflowDescTxt, PurchDocCategoryTxt);
            "Purchase Document Type"::"Return Order":
                InsertWorkflow(
                    Workflow, GetWorkflowCode(PurchReturnOrderApprWorkflowCodeTxt),
                    PurchReturnOrderApprWorkflowDescTxt, PurchDocCategoryTxt);
            "Purchase Document Type"::"Credit Memo":
                InsertWorkflow(
                    Workflow, GetWorkflowCode(PurchCreditMemoApprWorkflowCodeTxt),
                    PurchCreditMemoApprWorkflowDescTxt, PurchDocCategoryTxt);
            "Purchase Document Type"::Quote:
                InsertWorkflow(
                    Workflow, GetWorkflowCode(PurchQuoteApprWorkflowCodeTxt),
                    PurchQuoteApprWorkflowDescTxt, PurchDocCategoryTxt);
            "Purchase Document Type"::"Blanket Order":
                InsertWorkflow(
                    Workflow, GetWorkflowCode(PurchBlanketOrderApprWorkflowCodeTxt),
                    PurchBlanketOrderApprWorkflowDescTxt, PurchDocCategoryTxt);
        end;

        InitWorkflowStepArgument(WorkflowStepArgument, ApproverType, LimitType, 0, WorkflowUserGroupCode, DueDateFormula, true);

        InsertDocApprovalWorkflowSteps(
            Workflow, BuildPurchHeaderTypeConditionsText(DocumentType, "Purchase Document Status"::Open),
            WorkflowEventHandling.RunWorkflowOnSendPurchaseDocForApprovalCode(),
            BuildPurchHeaderTypeConditionsText(DocumentType, "Purchase Document Status"::"Pending Approval"),
            WorkflowEventHandling.RunWorkflowOnCancelPurchaseApprovalRequestCode(),
            WorkflowStepArgument, true);
    end;

    procedure InsertSalesDocumentApprovalWorkflowSteps(var Workflow: Record Workflow; DocumentType: Enum "Sales Document Type"; ApproverType: Enum "Workflow Approver Type"; LimitType: Enum "Workflow Approver Limit Type"; WorkflowUserGroupCode: Code[20]; DueDateFormula: DateFormula)
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        case DocumentType of
            Enum::"Sales Document Type"::Order:
                InsertWorkflow(
                    Workflow, GetWorkflowCode(SalesOrderApprWorkflowCodeTxt),
                    SalesOrderApprWorkflowDescTxt, SalesDocCategoryTxt);
            Enum::"Sales Document Type"::Invoice:
                InsertWorkflow(
                    Workflow, GetWorkflowCode(SalesInvoiceApprWorkflowCodeTxt),
                    SalesInvoiceApprWorkflowDescTxt, SalesDocCategoryTxt);
            Enum::"Sales Document Type"::"Return Order":
                InsertWorkflow(
                    Workflow, GetWorkflowCode(SalesReturnOrderApprWorkflowCodeTxt),
                    SalesReturnOrderApprWorkflowDescTxt, SalesDocCategoryTxt);
            Enum::"Sales Document Type"::"Credit Memo":
                InsertWorkflow(
                    Workflow, GetWorkflowCode(SalesCreditMemoApprWorkflowCodeTxt),
                    SalesCreditMemoApprWorkflowDescTxt, SalesDocCategoryTxt);
            Enum::"Sales Document Type"::Quote:
                InsertWorkflow(
                    Workflow, GetWorkflowCode(SalesQuoteApprWorkflowCodeTxt),
                    SalesQuoteApprWorkflowDescTxt, SalesDocCategoryTxt);
            Enum::"Sales Document Type"::"Blanket Order":
                InsertWorkflow(
                    Workflow, GetWorkflowCode(SalesBlanketOrderApprWorkflowCodeTxt),
                    SalesBlanketOrderApprWorkflowDescTxt, SalesDocCategoryTxt);
        end;

        InitWorkflowStepArgument(WorkflowStepArgument, ApproverType, LimitType, 0, WorkflowUserGroupCode, DueDateFormula, true);

        InsertDocApprovalWorkflowSteps(
            Workflow,
            BuildSalesHeaderTypeConditionsText(DocumentType, Enum::"Sales Document Status"::Open),
            WorkflowEventHandling.RunWorkflowOnSendSalesDocForApprovalCode(),
            BuildSalesHeaderTypeConditionsText(DocumentType, Enum::"Sales Document Status"::"Pending Approval"),
            WorkflowEventHandling.RunWorkflowOnCancelSalesApprovalRequestCode(),
            WorkflowStepArgument, true);
    end;


    procedure InsertSalesDocumentCreditLimitApprovalWorkflowSteps(var Workflow: Record Workflow; DocumentType: Enum "Sales Document Type"; ApproverType: Enum "Workflow Approver Type"; LimitType: Enum "Workflow Approver Limit Type"; WorkflowUserGroupCode: Code[20]; DueDateFormula: DateFormula)
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        case DocumentType of
            Enum::"Sales Document Type"::Order:
                InsertWorkflow(Workflow, GetWorkflowCode(SalesOrderCreditLimitApprWorkflowCodeTxt),
                  SalesOrderCreditLimitApprWorkflowDescTxt, SalesDocCategoryTxt);
            Enum::"Sales Document Type"::Invoice:
                InsertWorkflow(Workflow, GetWorkflowCode(SalesInvoiceCreditLimitApprWorkflowCodeTxt),
                  SalesInvoiceCreditLimitApprWorkflowDescTxt, SalesDocCategoryTxt);
            Enum::"Sales Document Type"::"Return Order":
                InsertWorkflow(Workflow, GetWorkflowCode(SalesRetOrderCrLimitApprWorkflowCodeTxt),
                  SalesRetOrderCrLimitApprWorkflowDescTxt, SalesDocCategoryTxt);
            Enum::"Sales Document Type"::"Credit Memo":
                InsertWorkflow(Workflow, GetWorkflowCode(SalesCrMemoCrLimitApprWorkflowCodeTxt),
                  SalesCrMemoCrLimitApprWorkflowDescTxt, SalesDocCategoryTxt);
            Enum::"Sales Document Type"::Quote:
                InsertWorkflow(Workflow, GetWorkflowCode(SalesQuoteCrLimitApprWorkflowCodeTxt),
                  SalesQuoteCrLimitApprWorkflowDescTxt, SalesDocCategoryTxt);
            Enum::"Sales Document Type"::"Blanket Order":
                InsertWorkflow(Workflow, GetWorkflowCode(SalesBlanketOrderCrLimitApprWorkflowCodeTxt),
                  SalesBlanketOrderCrLimitApprWorkflowDescTxt, SalesDocCategoryTxt);
        end;

        InitWorkflowStepArgument(WorkflowStepArgument, ApproverType, LimitType, 0, WorkflowUserGroupCode, DueDateFormula, true);

        InsertSalesDocWithCreditLimitApprovalWorkflowSteps(Workflow,
          BuildSalesHeaderTypeConditionsText(DocumentType, Enum::"Sales Document Status"::Open),
          BuildSalesHeaderTypeConditionsText(DocumentType, Enum::"Sales Document Status"::"Pending Approval"), WorkflowStepArgument, true);
    end;

    local procedure InsertJobQueueEntryApprovalWorkflowDetails(var Workflow: Record Workflow)
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        WorkflowSetup.InitWorkflowStepArgument(
            WorkflowStepArgument, WorkflowStepArgument."Approver Type"::Approver,
            WorkflowStepArgument."Approver Limit Type"::"Direct Approver",
            0, '', BlankDateFormula, true);

        InsertJobQueueEntryApprovalWorkflowSteps(Workflow, BuildJobQueueEntryConditions(),
          WorkflowEventHandling.RunWorkflowOnSendJobQueueEntryForApprovalCode(),
          WorkflowResponseHandling.CreateApprovalRequestsCode(),
          WorkflowResponseHandling.SendApprovalRequestForApprovalCode(),
          WorkflowEventHandling.RunWorkflowOnCancelJobQueueEntryApprovalRequestCode(),
          WorkflowStepArgument,
          true, true);
    end;

    local procedure BuildJobQueueEntryConditions(): Text
    var
        JobQueueEntry: Record "Job Queue Entry";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        exit(StrSubstNo(JobQueueEntryCondnTxt, WorkflowSetup.Encode(JobQueueEntry.GetView(false))));
    end;

    local procedure InsertJobQueueEntryApprovalWorkflowSteps(Workflow: Record Workflow; ConditionString: Text; RecSendForApprovalEventCode: Code[128]; RecCreateApprovalRequestsCode: Code[128]; RecSendApprovalRequestForApprovalCode: Code[128]; RecCanceledEventCode: Code[128]; WorkflowStepArgument: Record "Workflow Step Argument"; ShowConfirmationMessage: Boolean; RemoveRestrictionOnCancel: Boolean)
    var
        SentForApprovalEventID: Integer;
        CreateApprovalRequestResponseID: Integer;
        SendApprovalRequestResponseID: Integer;
        OnAllRequestsApprovedEventID: Integer;
        OnRequestApprovedEventID: Integer;
        SendApprovalRequestResponseID2: Integer;
        OnRequestRejectedEventID: Integer;
        RejectAllApprovalsResponseID: Integer;
        OnRequestCanceledEventID: Integer;
        CancelAllApprovalsResponseID: Integer;
        OnRequestDelegatedEventID: Integer;
        SentApprovalRequestResponseID3: Integer;
        RestrictUsageResponseID: Integer;
        AllowRecordUsageResponseID: Integer;
        ShowMessageResponseID: Integer;
        TempResponseResponseID: Integer;
        AllowRecordUsageID: Integer;
    begin
        SentForApprovalEventID := InsertEntryPointEventStep(Workflow, RecSendForApprovalEventCode);
        InsertEventArgument(SentForApprovalEventID, ConditionString);

        RestrictUsageResponseID := InsertResponseStep(Workflow, WorkflowResponseHandling.RestrictRecordUsageCode(),
            SentForApprovalEventID);
        CreateApprovalRequestResponseID := InsertResponseStep(Workflow, RecCreateApprovalRequestsCode,
            RestrictUsageResponseID);
        InsertApprovalArgument(CreateApprovalRequestResponseID,
          WorkflowStepArgument."Approver Type", WorkflowStepArgument."Approver Limit Type",
          WorkflowStepArgument."Workflow User Group Code", WorkflowStepArgument."Approver User ID",
          WorkflowStepArgument."Due Date Formula", ShowConfirmationMessage);
        SendApprovalRequestResponseID := InsertResponseStep(Workflow, RecSendApprovalRequestForApprovalCode,
            CreateApprovalRequestResponseID);
        InsertNotificationArgument(SendApprovalRequestResponseID, false, '', 0, '');

        OnAllRequestsApprovedEventID := InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode(),
            SendApprovalRequestResponseID);
        InsertEventArgument(OnAllRequestsApprovedEventID, BuildNoPendingApprovalsConditions());
        AllowRecordUsageID := InsertResponseStep(Workflow, WorkflowResponseHandling.AllowRecordUsageCode(), OnAllRequestsApprovedEventID);
        InsertResponseStep(Workflow, WorkflowResponseHandling.EnableJobQueueEntryCode(), AllowRecordUsageID);

        OnRequestApprovedEventID := InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode(),
            SendApprovalRequestResponseID);
        InsertEventArgument(OnRequestApprovedEventID, BuildPendingApprovalsConditions());
        SendApprovalRequestResponseID2 := InsertResponseStep(Workflow, WorkflowResponseHandling.SendApprovalRequestForApprovalCode(),
            OnRequestApprovedEventID);

        SetNextStep(Workflow, SendApprovalRequestResponseID2, SendApprovalRequestResponseID);

        OnRequestRejectedEventID := InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnRejectApprovalRequestCode(),
            SendApprovalRequestResponseID);
        RejectAllApprovalsResponseID := InsertResponseStep(Workflow, WorkflowResponseHandling.RejectAllApprovalRequestsCode(),
            OnRequestRejectedEventID);
        InsertNotificationArgument(RejectAllApprovalsResponseID, true, '', WorkflowStepArgument."Link Target Page", '');

        OnRequestCanceledEventID := InsertEventStep(Workflow, RecCanceledEventCode, SendApprovalRequestResponseID);
        CancelAllApprovalsResponseID := InsertResponseStep(Workflow, WorkflowResponseHandling.CancelAllApprovalRequestsCode(),
            OnRequestCanceledEventID);
        InsertNotificationArgument(CancelAllApprovalsResponseID, false, '', WorkflowStepArgument."Link Target Page", '');

        TempResponseResponseID := CancelAllApprovalsResponseID;
        if RemoveRestrictionOnCancel then begin
            AllowRecordUsageResponseID :=
              InsertResponseStep(Workflow, WorkflowResponseHandling.AllowRecordUsageCode(), CancelAllApprovalsResponseID);
            TempResponseResponseID := AllowRecordUsageResponseID;
        end;
        if ShowConfirmationMessage then begin
            ShowMessageResponseID := InsertResponseStep(Workflow, WorkflowResponseHandling.ShowMessageCode(), TempResponseResponseID);
            InsertMessageArgument(ShowMessageResponseID, ApprovalRequestCanceledMsg);
        end;

        OnRequestDelegatedEventID := InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnDelegateApprovalRequestCode(),
            SendApprovalRequestResponseID);
        SentApprovalRequestResponseID3 := InsertResponseStep(Workflow, WorkflowResponseHandling.SendApprovalRequestForApprovalCode(),
            OnRequestDelegatedEventID);

        SetNextStep(Workflow, SentApprovalRequestResponseID3, SendApprovalRequestResponseID);
    end;

    procedure InsertEntryPointEventStep(Workflow: Record Workflow; FunctionName: Code[128]): Integer
    var
        WorkflowStep: Record "Workflow Step";
    begin
        InsertStep(WorkflowStep, Workflow.Code, WorkflowStep.Type::"Event", FunctionName);
        WorkflowStep.Validate("Entry Point", true);
        WorkflowStep.Modify(true);
        exit(WorkflowStep.ID);
    end;

    procedure InsertEventStep(Workflow: Record Workflow; FunctionName: Code[128]; PreviousStepID: Integer): Integer
    var
        WorkflowStep: Record "Workflow Step";
    begin
        InsertStep(WorkflowStep, Workflow.Code, WorkflowStep.Type::"Event", FunctionName);
        WorkflowStep."Sequence No." := GetSequenceNumber(Workflow, PreviousStepID);
        WorkflowStep.Validate("Previous Workflow Step ID", PreviousStepID);
        WorkflowStep.Modify(true);
        exit(WorkflowStep.ID);
    end;

    procedure InsertResponseStep(Workflow: Record Workflow; FunctionName: Code[128]; PreviousStepID: Integer): Integer
    var
        WorkflowStep: Record "Workflow Step";
    begin
        InsertStep(WorkflowStep, Workflow.Code, WorkflowStep.Type::Response, FunctionName);
        WorkflowStep."Sequence No." := GetSequenceNumber(Workflow, PreviousStepID);
        WorkflowStep.Validate("Previous Workflow Step ID", PreviousStepID);
        WorkflowStep.Modify(true);
        exit(WorkflowStep.ID);
    end;

    procedure InsertStep(var WorkflowStep: Record "Workflow Step"; WorkflowCode: Code[20]; StepType: Option; FunctionName: Code[128])
    begin
        WorkflowStep.Validate("Workflow Code", WorkflowCode);
        WorkflowStep.Validate(Type, StepType);
        WorkflowStep.Validate("Function Name", FunctionName);
        WorkflowStep.Insert(true);
    end;

    procedure MarkWorkflowAsTemplate(var Workflow: Record Workflow)
    begin
        Workflow.Validate(Template, true);
        Workflow.Modify(true);
    end;

    procedure GetSequenceNumber(Workflow: Record Workflow; PreviousStepID: Integer): Integer
    var
        WorkflowStep: Record "Workflow Step";
    begin
        WorkflowStep.SetRange("Workflow Code", Workflow.Code);
        WorkflowStep.SetRange("Previous Workflow Step ID", PreviousStepID);
        if WorkflowStep.FindLast() then
            exit(WorkflowStep."Sequence No." + 1);
    end;

    procedure SetNextStep(Workflow: Record Workflow; WorkflowStepID: Integer; NextStepID: Integer)
    var
        WorkflowStep: Record "Workflow Step";
    begin
        WorkflowStep.Get(Workflow.Code, WorkflowStepID);
        WorkflowStep.Validate("Next Workflow Step ID", NextStepID);
        WorkflowStep.Modify(true);
    end;

    procedure InsertTableRelation(TableId: Integer; FieldId: Integer; RelatedTableId: Integer; RelatedFieldId: Integer)
    var
        WorkflowTableRelation: Record "Workflow - Table Relation";
    begin
        if WorkflowTableRelation.Get(TableId, FieldId, RelatedTableId, RelatedFieldId) then
            exit;
        WorkflowTableRelation.Init();
        WorkflowTableRelation."Table ID" := TableId;
        WorkflowTableRelation."Field ID" := FieldId;
        WorkflowTableRelation."Related Table ID" := RelatedTableId;
        WorkflowTableRelation."Related Field ID" := RelatedFieldId;
        WorkflowTableRelation.Insert();
    end;

    procedure InsertWorkflowCategory("Code": Code[20]; Description: Text[100])
    var
        WorkflowCategory: Record "Workflow Category";
    begin
        if WorkflowCategory.Get(Code) then
            exit;
        WorkflowCategory.Init();
        WorkflowCategory.Code := Code;
        WorkflowCategory.Description := Description;
        WorkflowCategory.Insert();
    end;

    procedure InsertEventArgument(WorkflowStepID: Integer; EventConditions: Text)
    var
        WorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        if EventConditions = '' then
            Error(InvalidEventCondErr);

        WorkflowStepArgument.Type := WorkflowStepArgument.Type::"Event";
        WorkflowStepArgument.Insert(true);
        WorkflowStepArgument.SetEventFilters(EventConditions);

        WorkflowStep.SetRange(ID, WorkflowStepID);
        WorkflowStep.FindFirst();
        WorkflowStep.Argument := WorkflowStepArgument.ID;
        WorkflowStep.Modify(true);
    end;

    procedure InsertEventRule(WorkflowStepID: Integer; FieldNo: Integer; Operator: Option)
    var
        WorkflowStep: Record "Workflow Step";
        WorkflowRule: Record "Workflow Rule";
        WorkflowEvent: Record "Workflow Event";
    begin
        WorkflowStep.SetRange(ID, WorkflowStepID);
        WorkflowStep.FindFirst();

        WorkflowRule.Init();
        WorkflowRule."Workflow Code" := WorkflowStep."Workflow Code";
        WorkflowRule."Workflow Step ID" := WorkflowStep.ID;
        WorkflowRule.Operator := Operator;

        if WorkflowEvent.Get(WorkflowStep."Function Name") then
            WorkflowRule."Table ID" := WorkflowEvent."Table ID";
        WorkflowRule."Field No." := FieldNo;
        WorkflowRule.Insert(true);
    end;

    procedure InsertNotificationArgument(WorkflowStepID: Integer; NotifySender: Boolean; NotifUserID: Code[50]; LinkTargetPage: Integer; CustomLink: Text[250])
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        InsertStepArgument(WorkflowStepArgument, WorkflowStepID);

        WorkflowStepArgument."Notification User ID" := NotifUserID;
        WorkflowStepArgument.Validate("Notify Sender", NotifySender);
        WorkflowStepArgument."Link Target Page" := LinkTargetPage;
        WorkflowStepArgument."Custom Link" := CustomLink;
        WorkflowStepArgument.Modify(true);
    end;

    procedure InsertPmtLineCreationArgument(WorkflowStepID: Integer; GenJnlTemplateName: Code[10]; GenJnlBatchName: Code[10])
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        InsertStepArgument(WorkflowStepArgument, WorkflowStepID);

        WorkflowStepArgument."General Journal Template Name" := GenJnlTemplateName;
        WorkflowStepArgument."General Journal Batch Name" := GenJnlBatchName;
        WorkflowStepArgument.Modify(true);
    end;

    procedure InsertApprovalArgument(WorkflowStepID: Integer; ApproverType: Enum "Workflow Approver Type"; ApproverLimitType: Enum "Workflow Approver Limit Type"; WorkflowUserGroupCode: Code[20]; ApproverId: Code[50]; DueDateFormula: DateFormula; ShowConfirmationMessage: Boolean)
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        InsertStepArgument(WorkflowStepArgument, WorkflowStepID);

        WorkflowStepArgument."Approver Type" := ApproverType;
        WorkflowStepArgument."Approver Limit Type" := ApproverLimitType;
        WorkflowStepArgument."Workflow User Group Code" := WorkflowUserGroupCode;
        WorkflowStepArgument."Approver User ID" := ApproverId;
        WorkflowStepArgument."Due Date Formula" := DueDateFormula;
        WorkflowStepArgument."Show Confirmation Message" := ShowConfirmationMessage;
        WorkflowStepArgument.Modify(true);
    end;

    procedure InsertMessageArgument(WorkflowStepID: Integer; Message: Text[250])
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        InsertStepArgument(WorkflowStepArgument, WorkflowStepID);

        WorkflowStepArgument.Message := Message;
        WorkflowStepArgument.Modify(true);
    end;

    local procedure InsertChangeRecValueArgument(WorkflowStepID: Integer; TableNo: Integer; FieldNo: Integer)
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        InsertStepArgument(WorkflowStepArgument, WorkflowStepID);

        WorkflowStepArgument."Table No." := TableNo;
        WorkflowStepArgument."Field No." := FieldNo;
        WorkflowStepArgument.Modify(true);
    end;

    procedure InsertStepArgument(var WorkflowStepArgument: Record "Workflow Step Argument"; WorkflowStepID: Integer)
    var
        WorkflowStep: Record "Workflow Step";
    begin
        WorkflowStep.SetRange(ID, WorkflowStepID);
        WorkflowStep.FindFirst();

        if WorkflowStepArgument.Get(WorkflowStep.Argument) then
            exit;

        WorkflowStepArgument.Type := WorkflowStepArgument.Type::Response;
        WorkflowStepArgument.Validate("Response Function Name", WorkflowStep."Function Name");
        WorkflowStepArgument.Insert(true);

        WorkflowStep.Argument := WorkflowStepArgument.ID;
        WorkflowStep.Modify(true);
    end;

    local procedure GetWorkflowCode(WorkflowCode: Text): Code[20]
    var
        Workflow: Record Workflow;
    begin
        exit(CopyStr(Format(Workflow.Count + 1) + '-' + WorkflowCode, 1, MaxStrLen(Workflow.Code)));
    end;

    procedure GetWorkflowTemplateCode(WorkflowCode: Code[17]): Code[20]
    begin
        exit(GetWorkflowTemplateToken() + WorkflowCode);
    end;

    procedure GetWorkflowTemplateToken(): Code[3]
    begin
        if CustomTemplateToken <> '' then
            exit(CustomTemplateToken);

        exit(MsTemplateTok);
    end;

    procedure GetWorkflowWizardCode(WorkflowCode: Code[17]): Code[20]
    begin
        exit(MsWizardWorkflowTok + WorkflowCode);
    end;

    procedure GetWorkflowWizardToken(): Code[3]
    begin
        exit(MsWizardWorkflowTok);
    end;

    procedure SetTemplateForWorkflowStep(Workflow: Record Workflow; FunctionName: Code[128])
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
        WorkflowStep: Record "Workflow Step";
    begin
        WorkflowStep.SetRange("Workflow Code", Workflow.Code);
        WorkflowStep.SetRange("Function Name", FunctionName);
        if WorkflowStep.FindSet() then
            repeat
                if not WorkflowStepArgument.Get(WorkflowStep.Argument) then
                    InsertNotificationArgument(WorkflowStep.ID, false, '', 0, '');
            until WorkflowStep.Next() = 0;
    end;

    procedure SetCustomTemplateToken(NewCustomTemplateToken: Code[3])
    begin
        CustomTemplateToken := NewCustomTemplateToken;
    end;

    procedure InitWorkflowStepArgument(var WorkflowStepArgument: Record "Workflow Step Argument"; ApproverType: Enum "Workflow Approver Type"; ApproverLimitType: Enum "Workflow Approver Limit Type"; ApprovalEntriesPage: Integer; WorkflowUserGroupCode: Code[20]; DueDateFormula: DateFormula; ShowConfirmationMessage: Boolean)
    begin
        WorkflowStepArgument.Init();
        WorkflowStepArgument.Type := WorkflowStepArgument.Type::Response;
        WorkflowStepArgument."Approver Type" := ApproverType;
        WorkflowStepArgument."Approver Limit Type" := ApproverLimitType;
        WorkflowStepArgument."Workflow User Group Code" := WorkflowUserGroupCode;
        WorkflowStepArgument."Due Date Formula" := DueDateFormula;
        WorkflowStepArgument."Link Target Page" := ApprovalEntriesPage;
        WorkflowStepArgument."Show Confirmation Message" := ShowConfirmationMessage;
    end;

    procedure BuildNoPendingApprovalsConditions(): Text
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        ApprovalEntry.SetRange("Pending Approvals", 0);
        exit(StrSubstNo(PendingApprovalsCondnTxt, Encode(ApprovalEntry.GetView(false))));
    end;

    procedure BuildPendingApprovalsConditions(): Text
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        ApprovalEntry.SetFilter("Pending Approvals", '>%1', 0);
        exit(StrSubstNo(PendingApprovalsCondnTxt, Encode(ApprovalEntry.GetView(false))));
    end;

    procedure BuildIncomingDocumentTypeConditions(Status: Option): Text
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
    begin
        IncomingDocument.SetRange(Status, Status);
        exit(
          StrSubstNo(
            IncomingDocumentTypeCondnTxt, Encode(IncomingDocument.GetView(false)), Encode(IncomingDocumentAttachment.GetView(false))));
    end;

    procedure BuildIncomingDocumentOCRTypeConditions(OCRStatus: Option): Text
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
    begin
        IncomingDocument.SetRange("OCR Status", OCRStatus);
        exit(
          StrSubstNo(
            IncomingDocumentTypeCondnTxt, Encode(IncomingDocument.GetView(false)), Encode(IncomingDocumentAttachment.GetView(false))));
    end;

    procedure BuildPurchHeaderTypeConditionsText(DocumentType: Enum "Purchase Document Type"; Status: Enum "Purchase Document Status"): Text
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseHeader.SetRange("Document Type", DocumentType);
        PurchaseHeader.SetRange(Status, Status);
        exit(StrSubstNo(PurchHeaderTypeCondnTxt, Encode(PurchaseHeader.GetView(false)), Encode(PurchaseLine.GetView(false))));
    end;

    procedure BuildSalesHeaderTypeConditionsText(DocumentType: Enum "Sales Document Type"; Status: Enum "Sales Document Status"): Text
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        SalesHeader.SetRange("Document Type", DocumentType);
        SalesHeader.SetRange(Status, Status);
        exit(StrSubstNo(SalesHeaderTypeCondnTxt, Encode(SalesHeader.GetView(false)), Encode(SalesLine.GetView(false))));
    end;

    procedure BuildCustomerTypeConditions(): Text
    var
        Customer: Record Customer;
    begin
        exit(StrSubstNo(CustomerTypeCondnTxt, Encode(Customer.GetView(false))));
    end;

    procedure BuildVendorTypeConditions(): Text
    var
        Vendor: Record Vendor;
    begin
        exit(StrSubstNo(VendorTypeCondnTxt, Encode(Vendor.GetView(false))));
    end;

    procedure BuildItemTypeConditions(): Text
    var
        Item: Record Item;
    begin
        exit(StrSubstNo(ItemTypeCondnTxt, Encode(Item.GetView(false))));
    end;

    local procedure BuildGeneralJournalBatchTypeConditions(): Text
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        exit(BuildGeneralJournalBatchTypeConditionsFromRec(GenJournalBatch));
    end;

    procedure BuildGeneralJournalBatchTypeConditionsFromRec(var GenJournalBatch: Record "Gen. Journal Batch"): Text
    begin
        exit(StrSubstNo(GeneralJournalBatchTypeCondnTxt, Encode(GenJournalBatch.GetView(false))));
    end;

    procedure BuildGeneralJournalLineTypeConditions(var GenJournalLine: Record "Gen. Journal Line"): Text
    begin
        exit(StrSubstNo(GeneralJournalLineTypeCondnTxt, Encode(GenJournalLine.GetView(false))));
    end;

    local procedure BuildRequisitionWkshBatchTypeConditions(): Text
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        exit(BuildRequisitionWkshNameTypeConditionsFromRec(RequisitionWkshName));
    end;

    procedure BuildRequisitionWkshNameTypeConditionsFromRec(var RequisitionWkshName: Record "Requisition Wksh. Name"): Text
    begin
        exit(StrSubstNo(RequisitionWkshTypeCondnTxt, Encode(RequisitionWkshName.GetView(false))));
    end;

    local procedure InsertJobQueueData()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if TASKSCHEDULER.CanCreateTask() then
            CreateJobQueueEntry(
              JobQueueEntry."Object Type to Run"::Report,
              REPORT::"Delegate Approval Requests",
              CopyStr(JobQueueEntryDescTxt, 1, MaxStrLen(JobQueueEntry.Description)),
              CurrentDateTime,
              1440);
    end;

    procedure CreateJobQueueEntry(ObjectTypeToRun: Option; ObjectIdToRun: Integer; JobQueueEntryDescription: Text[250]; NotBefore: DateTime; NoOfMinutesBetweenRuns: Integer)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object Type to Run", ObjectTypeToRun);
        JobQueueEntry.SetRange("Object ID to Run", ObjectIdToRun);
        JobQueueEntry.SetRange("Recurring Job", true);
        if not JobQueueEntry.IsEmpty() then
            exit;

        JobQueueEntry.InitRecurringJob(NoOfMinutesBetweenRuns);
        JobQueueEntry."Earliest Start Date/Time" := NotBefore;
        JobQueueEntry."Object Type to Run" := ObjectTypeToRun;
        JobQueueEntry."Object ID to Run" := ObjectIdToRun;
        JobQueueEntry."Report Output Type" := JobQueueEntry."Report Output Type"::"None (Processing only)";
        JobQueueEntry."Maximum No. of Attempts to Run" := 3;
        JobQueueEntry.Description := JobQueueEntryDescription;
        CODEUNIT.Run(CODEUNIT::"Job Queue - Enqueue", JobQueueEntry);
    end;

    procedure Encode(Text: Text): Text
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
    begin
        exit(XMLDOMManagement.XMLEscape(Text));
    end;

    procedure GetGeneralJournalBatchIsNotBalancedMsg() Message: Text[250]
    begin
        Message := GeneralJournalBatchIsNotBalancedMsg;
    end;

    [InternalEvent(false, false)]
    internal procedure OnAllowEditOfWorkflowTemplates(var Allow: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitWorkflowTemplates()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertApprovalsTableRelations()
    begin
    end;
}

