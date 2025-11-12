// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

using Microsoft.Integration.Dataverse;
using Microsoft.Integration.SyncEngine;
using Microsoft.Sales.Document;
using System.Environment.Configuration;
using System.Threading;
using System.Utilities;

codeunit 5355 "CRM Notes Synch Job"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    begin
        UpdateOrders(Rec.GetLastLogEntryNo());
    end;

    var
        CRMProductName: Codeunit "CRM Product Name";

        ConnectionNotEnabledErr: Label 'The %1 connection is not enabled.', Comment = '%1 = CRM product name';
        OrderNotesUpdatedMsg: Label 'The notes on coupled sales orders have been synchronized.';

    local procedure UpdateOrders(JobLogEntryNo: Integer)
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        ConnectionName: Text;
    begin
        CRMConnectionSetup.Get();
        if not CRMConnectionSetup."Is Enabled" then
            Error(ConnectionNotEnabledErr, CRMProductName.FULL());

        ConnectionName := Format(CreateGuid());
        CRMConnectionSetup.RegisterConnectionWithName(ConnectionName);
        SetDefaultTableConnection(
          TABLECONNECTIONTYPE::CRM, CRMConnectionSetup.GetDefaultCRMConnection(ConnectionName));

        UpdateSalesOrderNotes(JobLogEntryNo);

        CRMConnectionSetup.UnregisterConnectionWithName(ConnectionName);
    end;

    local procedure UpdateSalesOrderNotes(JobLogEntryNo: Integer)
    var
        CRMAnnotationCoupling: Record "CRM Annotation Coupling";
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationTableSynch: Codeunit "Integration Table Synch.";
        SynchActionType: Option "None",Insert,Modify,ForceModify,IgnoreUnchanged,Fail,Skip,Delete;
        InsertCounter: Integer;
        ModifyCounter: Integer;
        CreatedAfterDateTime: DateTime;
        ModifiedAfterDateTime: DateTime;
    begin
        IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::Dataverse);
        IntegrationTableMapping.SetRange("Table ID", DATABASE::"Sales Header");
        IntegrationTableMapping.SetRange("Integration Table ID", Database::"CRM Salesorder");
        if IntegrationTableMapping.FindFirst() then
            IntegrationTableSynch.BeginIntegrationSynchJob(TABLECONNECTIONTYPE::CRM, IntegrationTableMapping, DATABASE::"Sales Header")
        else
            IntegrationTableSynch.BeginIntegrationSynchJobLoging(TABLECONNECTIONTYPE::CRM, CODEUNIT::"CRM Notes Synch Job", JobLogEntryNo, DATABASE::"Sales Header");

        CRMAnnotationCoupling.SetCurrentKey("CRM Created On");
        if CRMAnnotationCoupling.FindLast() then
            CreatedAfterDateTime := CRMAnnotationCoupling."CRM Created On";
        CRMAnnotationCoupling.SetCurrentKey("CRM Modified On");
        if CRMAnnotationCoupling.FindLast() then
            ModifiedAfterDateTime := CRMAnnotationCoupling."CRM Modified On";

        InsertCounter := CreateAnnotationsForCreatedNotes();
        InsertCounter += CreateNotesForCreatedAnnotations(CreatedAfterDateTime);
        ModifyCounter += ModifyNotesForModifiedAnnotations(ModifiedAfterDateTime);

        IntegrationTableSynch.UpdateSynchJobCounters(SynchActionType::Insert, InsertCounter);
        IntegrationTableSynch.UpdateSynchJobCounters(SynchActionType::Modify, ModifyCounter);
        IntegrationTableSynch.EndIntegrationSynchJobWithMsg(GetOrderNotesUpdateFinalMessage());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Queue Entry", 'OnFindingIfJobNeedsToBeRun', '', false, false)]
    local procedure OnFindingIfJobNeedsToBeRun(var Sender: Record "Job Queue Entry"; var Result: Boolean)
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMAnnotationBuffer: Record "CRM Annotation Buffer";
    begin
        if Result then
            exit;

        if Sender."Object Type to Run" <> Sender."Object Type to Run"::Codeunit then
            exit;

        if Sender."Object ID to Run" <> CODEUNIT::"CRM Notes Synch Job" then
            exit;

        if not CRMConnectionSetup.Get() then
            exit;

        if not CRMConnectionSetup."Is Enabled" then
            exit;

        CRMAnnotationBuffer.SetRange("Related Table ID", DATABASE::"Sales Header");
        if not CRMAnnotationBuffer.IsEmpty() then
            Result := true;
    end;

    local procedure CreateCRMAnnotation(CRMSalesorder: Record "CRM Salesorder"; RecordLinkRecId: RecordID)
    var
        CRMAnnotation: Record "CRM Annotation";
        RecordLink: Record "Record Link";
        CRMAnnotationCoupling: Record "CRM Annotation Coupling";
        RecordLinkManagement: Codeunit "Record Link Management";
        OutStream: OutStream;
        AnnotationText: Text;
    begin
        RecordLink.Get(RecordLinkRecId);
        RecordLink.CalcFields(Note);
        AnnotationText := RecordLinkManagement.ReadNote(RecordLink);

        CRMAnnotation.AnnotationId := CreateGuid();
        CRMAnnotation.ObjectTypeCode := CRMAnnotation.ObjectTypeCode::salesorder;
        CRMAnnotation.ObjectId := CRMSalesorder.SalesOrderId;
        CRMAnnotation.IsDocument := false;
        CRMAnnotation.FileSize := 0;
        CRMAnnotation.Subject := RecordLink.Description;
        CRMAnnotation.NoteText.CreateOutStream(OutStream, TEXTENCODING::UTF16);
        OutStream.Write(AnnotationText);
        CRMAnnotation.Insert();

        CRMAnnotation.Get(CRMAnnotation.AnnotationId);
        CRMAnnotationCoupling.CoupleRecordLinkToCRMAnnotation(RecordLink, CRMAnnotation);
    end;

    procedure GetOrderNotesUpdateFinalMessage(): Text
    begin
        exit(OrderNotesUpdatedMsg);
    end;

    local procedure FindCoupledCRMSalesOrder(var CRMSalesorder: Record "CRM Salesorder"; SalesHeader: Record "Sales Header"): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        if not CRMIntegrationManagement.IsCRMIntegrationEnabled() then
            exit(false);

        if not CRMIntegrationRecord.FindIDFromRecordID(SalesHeader.RecordId, CRMSalesorder.SalesOrderId) then
            exit(false);

        if not CRMSalesorder.Find() then
            exit(false);

        exit(true);
    end;

    [Scope('OnPrem')]
    procedure CreateAnnotationsForCreatedNotes() CreatedAnnotations: Integer
    var
        CRMAnnotationBuffer: Record "CRM Annotation Buffer";
        TempCRMAnnotationBuffer: Record "CRM Annotation Buffer" temporary;
    begin
        CRMAnnotationBuffer.SetRange("Related Table ID", DATABASE::"Sales Header");
        if not CRMAnnotationBuffer.FindSet() then
            exit;

        repeat
            TempCRMAnnotationBuffer.TransferFields(CRMAnnotationBuffer);
            TempCRMAnnotationBuffer.Insert();
        until CRMAnnotationBuffer.Next() = 0;

        if TempCRMAnnotationBuffer.FindSet() then
            repeat
                CreatedAnnotations += ProcessCRMAnnotationBufferEntry(TempCRMAnnotationBuffer);
            until TempCRMAnnotationBuffer.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure CreateNotesForCreatedAnnotations(CreatedAfterDateTime: DateTime) CreatedNotes: Integer
    var
        CRMAnnotation: Record "CRM Annotation";
    begin
        CRMAnnotation.SetRange(ObjectTypeCode, CRMAnnotation.ObjectTypeCode::salesorder);
        if CreatedAfterDateTime <> 0DT then
            CRMAnnotation.SetFilter(CreatedOn, StrSubstNo('>%1', CreatedAfterDateTime));
        if CRMAnnotation.FindSet() then
            repeat
                CreatedNotes += CreateAndCoupleNote(CRMAnnotation);
            until CRMAnnotation.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure ModifyNotesForModifiedAnnotations(ModifiedAfterDateTime: DateTime) ModifiedNotes: Integer
    var
        CRMAnnotation: Record "CRM Annotation";
    begin
        CRMAnnotation.SetRange(ObjectTypeCode, CRMAnnotation.ObjectTypeCode::salesorder);
        if ModifiedAfterDateTime <> 0DT then
            CRMAnnotation.SetFilter(ModifiedOn, StrSubstNo('>%1', ModifiedAfterDateTime));
        if CRMAnnotation.FindSet() then
            repeat
                ModifiedNotes += ModifyNote(CRMAnnotation);
            until CRMAnnotation.Next() = 0;
    end;

    local procedure CreateAndCoupleNote(CRMAnnotation: Record "CRM Annotation"): Integer
    var
        RecordLink: Record "Record Link";
        SalesHeader: Record "Sales Header";
        CRMAnnotationCoupling: Record "CRM Annotation Coupling";
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMSalesOrderToSalesOrder: Codeunit "CRM Sales Order to Sales Order";
        SalesHeaderRecordID: RecordID;
    begin
        if not CRMIntegrationRecord.FindRecordIDFromID(CRMAnnotation.ObjectId, DATABASE::"Sales Header", SalesHeaderRecordID) then
            exit(0);

        if not SalesHeader.Get(SalesHeaderRecordID) then
            exit(0);

        if SalesHeader."Document Type" <> SalesHeader."Document Type"::Order then
            exit(0);

        if CRMAnnotationCoupling.FindByCRMId(CRMAnnotation.AnnotationId) then
            exit(0);

        CRMSalesOrderToSalesOrder.CreateNote(SalesHeader, CRMAnnotation, RecordLink);
        CRMAnnotationCoupling.CoupleRecordLinkToCRMAnnotation(RecordLink, CRMAnnotation);
        exit(1);
    end;

    local procedure ModifyNote(CRMAnnotation: Record "CRM Annotation"): Integer
    var
        RecordLink: Record "Record Link";
        CRMAnnotationCoupling: Record "CRM Annotation Coupling";
        CRMIntegrationRecord: Record "CRM Integration Record";
        RecordLinkManagement: Codeunit "Record Link Management";
        SalesHeaderRecordID: RecordID;
        InStream: InStream;
        AnnotationText: Text;
    begin
        if not CRMIntegrationRecord.FindRecordIDFromID(CRMAnnotation.ObjectId, DATABASE::"Sales Header", SalesHeaderRecordID) then
            exit(0);

        if not CRMAnnotationCoupling.FindByCRMId(CRMAnnotation.AnnotationId) then
            exit(0);

        if not RecordLink.Get(CRMAnnotationCoupling."Record Link Record ID") then
            exit(0);

        CRMAnnotation.NoteText.CreateInStream(InStream, TEXTENCODING::UTF16);
        if InStream.EOS then begin
            CRMAnnotation.CalcFields(NoteText);
            CRMAnnotation.NoteText.CreateInStream(InStream, TEXTENCODING::UTF16);
        end;
        InStream.Read(AnnotationText);
        AnnotationText := CRMAnnotationCoupling.ExtractNoteText(AnnotationText);
        if AnnotationText <> RecordLinkManagement.ReadNote(RecordLink) then begin
            RecordLinkManagement.WriteNote(RecordLink, AnnotationText);
            RecordLink.Modify(true);
            CRMAnnotationCoupling."CRM Modified On" := CRMAnnotation.ModifiedOn;
            CRMAnnotationCoupling."Last Synch. DateTime" := CurrentDateTime;
            CRMAnnotationCoupling.Modify();
            exit(1);
        end;

        exit(0);
    end;

    local procedure ProcessCRMAnnotationBufferEntry(var TempCRMAnnotationBuffer: Record "CRM Annotation Buffer" temporary): Integer
    var
        CRMSalesorder: Record "CRM Salesorder";
        SalesHeader: Record "Sales Header";
        RecordLink: Record "Record Link";
    begin
        if TempCRMAnnotationBuffer."Related Table ID" <> DATABASE::"Sales Header" then
            exit(0);

        if not SalesHeader.Get(TempCRMAnnotationBuffer."Related Record ID") then begin
            DeleteCRMAnnotationBufferEntry(TempCRMAnnotationBuffer);
            exit(0);
        end;

        if SalesHeader."Document Type" <> SalesHeader."Document Type"::Order then
            exit(0);

        if not FindCoupledCRMSalesOrder(CRMSalesorder, SalesHeader) then begin
            DeleteCRMAnnotationBufferEntry(TempCRMAnnotationBuffer);
            exit(0);
        end;

        if TempCRMAnnotationBuffer."Change Type" <> TempCRMAnnotationBuffer."Change Type"::Created then begin
            DeleteCRMAnnotationBufferEntry(TempCRMAnnotationBuffer);
            exit(0);
        end;

        if not RecordLink.Get(TempCRMAnnotationBuffer."Record ID") then begin
            DeleteCRMAnnotationBufferEntry(TempCRMAnnotationBuffer);
            exit(0);
        end;

        CreateCRMAnnotation(CRMSalesorder, TempCRMAnnotationBuffer."Record ID");
        DeleteCRMAnnotationBufferEntry(TempCRMAnnotationBuffer);
        exit(1);
    end;

    local procedure DeleteCRMAnnotationBufferEntry(var TempCRMAnnotationBuffer: Record "CRM Annotation Buffer" temporary)
    var
        CRMAnnotationBuffer: Record "CRM Annotation Buffer";
    begin
        if CRMAnnotationBuffer.Get(TempCRMAnnotationBuffer.ID) then
            CRMAnnotationBuffer.Delete();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Record Link", 'OnAfterInsertEvent', '', false, false)]
    local procedure CreateCRMAnnotationBufferOnAfterInsertRecordLink(var Rec: Record "Record Link"; RunTrigger: Boolean)
    var
        SalesHeader: Record "Sales Header";
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMAnnotationBuffer: Record "CRM Annotation Buffer";
        DestinationCRMID: Guid;
    begin
        if Rec.IsTemporary() then
            exit;

        if not RunTrigger then
            exit;

        if Rec.Type <> Rec.Type::Note then
            exit;

        if not SalesHeader.Get(Rec."Record ID") then
            exit;

        if not (SalesHeader."Document Type" = SalesHeader."Document Type"::Order) then
            exit;

        if not CRMConnectionSetup.Get() then
            exit;

        if not CRMConnectionSetup."Is Enabled" then
            exit;

        // we only synch notes that are made on sales orders that are coupled to CRM Salesorder
        if not CRMIntegrationRecord.FindIDFromRecordID(SalesHeader.RecordId, DestinationCRMID) then
            exit;

        CreateCRMAnnotationBufferEntry(Rec, DATABASE::"Sales Header", CRMAnnotationBuffer."Change Type"::Created);
    end;

    local procedure CreateCRMAnnotationBufferEntry(RecordLink: Record "Record Link"; RelatedTableID: Integer; ChangeType: Option)
    var
        CRMAnnotationBuffer: Record "CRM Annotation Buffer";
    begin
        CRMAnnotationBuffer."Record ID" := RecordLink.RecordId;
        CRMAnnotationBuffer."Related Record ID" := RecordLink."Record ID";
        CRMAnnotationBuffer."Related Table ID" := RelatedTableID;
        CRMAnnotationBuffer."Change Type" := ChangeType;
        CRMAnnotationBuffer."Change DateTime" := CurrentDateTime;
        CRMAnnotationBuffer.Insert(true);
    end;
}

