// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Archive;

using Microsoft.Service.Comment;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Setup;
using System.Utilities;

codeunit 6041 "Service Document Archive Mgmt."
{
    Permissions = tabledata "Service Header Archive" = ri,
                  tabledata "Service Item Line Archive" = ri,
                  tabledata "Service Line Archive" = ri,
                  tabledata "Service Comment Line Archive" = ri,
                  tabledata "Service Order Allocat. Archive" = ri;

    trigger OnRun()
    begin
    end;

    var
        ServiceDocumentArchivedMsg: Label 'Document %1 has been archived.', Comment = '%1 = Document No.';
        RestoreDocumentConfirmationQst: Label 'Do you want to restore %1 %2 Version %3?', Comment = '%1 = Document Type %2 = No. %3 = Version No.';
        ServiceDocumentRestoredMsg: Label '%1 %2 has been restored.', Comment = '%1 = Document Type %2 = No.';
        ServiceDocumentRestoredTxt: Label 'Document restored from Version %1.', Comment = '%1 = Version No.';
        ServiceDocumentRestoreNotPossibleErr: Label '%1 %2 has been partly posted.\Restore not possible.', Comment = '%1 = Document Type %2 = No.';
        ServiceDocumentArchiveConfirmationQst: Label 'Archive %1 no.: %2?', Comment = '%1 = Document Type %2 = No.';
        ServiceDocumentDoNotExistErr: Label 'Unposted %1 %2 does not exist anymore.\It is not possible to restore the %1.', Comment = '%1 = Document Type %2 = No.';

    procedure AutoArchiveServiceDocument(var ServiceHeader: Record "Service Header")
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAutoArchiveServiceDocument(ServiceHeader, IsHandled);
        if IsHandled then
            exit;

        ServiceMgtSetup.LoadFields("Archive Quotes", ServiceMgtSetup."Archive Orders");
        ServiceMgtSetup.Get();

        case ServiceHeader."Document Type" of
            ServiceHeader."Document Type"::Quote:
                case ServiceMgtSetup."Archive Quotes" of
                    ServiceMgtSetup."Archive Quotes"::Always:
                        ArchServiceDocumentNoConfirm(ServiceHeader);
                    ServiceMgtSetup."Archive Quotes"::Question:
                        ArchiveServiceDocument(ServiceHeader);
                end;
            ServiceHeader."Document Type"::Order:
                if ServiceMgtSetup."Archive Orders" then
                    ArchServiceDocumentNoConfirm(ServiceHeader);
        end;

        OnAfterAutoArchiveServiceDocument(ServiceHeader);
    end;

    procedure ArchServiceDocumentNoConfirm(var ServiceHeader: Record "Service Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeArchServiceDocumentNoConfirm(ServiceHeader, IsHandled);
        if IsHandled then
            exit;

        StoreServiceDocument(ServiceHeader, false);
    end;

    procedure ArchiveServiceDocument(var ServiceHeader: Record "Service Header")
    var
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeArchiveServiceDocument(ServiceHeader, IsHandled);
        if IsHandled then
            exit;

        if ConfirmManagement.GetResponseOrDefault(
             StrSubstNo(ServiceDocumentArchiveConfirmationQst, ServiceHeader."Document Type", ServiceHeader."No."), true)
        then begin
            StoreServiceDocument(ServiceHeader, false);
            if GuiAllowed() then
                Message(ServiceDocumentArchivedMsg, ServiceHeader."No.");
        end;
    end;

    local procedure StoreServiceDocument(var ServiceHeader: Record "Service Header"; InteractionExist: Boolean)
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceOrderAllocation: Record "Service Order Allocation";
        ServiceLine: Record "Service Line";
        ServiceHeaderArchive: Record "Service Header Archive";
        ServiceItemLineArchive: Record "Service Item Line Archive";
        ServiceOrderAllocatArchive: Record "Service Order Allocat. Archive";
        ServiceLineArchive: Record "Service Line Archive";
        RecordLinkManagement: Codeunit "Record Link Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeStoreServiceDocument(ServiceHeader, IsHandled);
        if IsHandled then
            exit;

        ServiceHeaderArchive.Init();
        ServiceHeader.CalcFields("Work Description");
        ServiceHeaderArchive.TransferFields(ServiceHeader);
        ServiceHeaderArchive."Archived By" := CopyStr(UserId(), 1, MaxStrLen(ServiceHeaderArchive."Archived By"));
        ServiceHeaderArchive."Date Archived" := Today();
        ServiceHeaderArchive."Time Archived" := Time();
        ServiceHeaderArchive."Version No." :=
            GetNextVersionNo(
                DATABASE::"Service Header", ServiceHeader."Document Type", ServiceHeader."No.", ServiceHeader."Doc. No. Occurrence");
        ServiceHeaderArchive."Interaction Exist" := InteractionExist;
        ServiceHeader.CalcFields("No. of Unallocated Items");
        ServiceHeaderArchive."No. of Unallocated Items" := ServiceHeader."No. of Unallocated Items";
        RecordLinkManagement.CopyLinks(ServiceHeader, ServiceHeaderArchive);
        OnBeforeServiceHeaderArchiveInsert(ServiceHeaderArchive, ServiceHeader);
        ServiceHeaderArchive.Insert();
        OnAfterServiceHeaderArchiveInsert(ServiceHeaderArchive, ServiceHeader);

        StoreServiceDocumentComments(
            ServiceHeader."Document Type", ServiceHeader."No.", ServiceHeader."Doc. No. Occurrence", ServiceHeaderArchive."Version No.");

        ServiceItemLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceItemLine.SetRange("Document No.", ServiceHeader."No.");
        if ServiceItemLine.FindSet() then
            repeat
                ServiceItemLineArchive.Init();
                ServiceItemLineArchive.TransferFields(ServiceItemLine);
                ServiceItemLineArchive."Doc. No. Occurrence" := ServiceHeader."Doc. No. Occurrence";
                ServiceItemLineArchive."Version No." := ServiceHeaderArchive."Version No.";
                RecordLinkManagement.CopyLinks(ServiceItemLine, ServiceItemLineArchive);
                OnBeforeServiceItemLineArchiveInsert(ServiceItemLineArchive, ServiceItemLine);
                ServiceItemLineArchive.Insert();
            until ServiceItemLine.Next() = 0;

        ServiceOrderAllocation.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceOrderAllocation.SetRange("Document No.", ServiceHeader."No.");
        if ServiceOrderAllocation.FindSet() then
            repeat
                ServiceOrderAllocatArchive.Init();
                ServiceOrderAllocatArchive.TransferFields(ServiceOrderAllocation);
                ServiceOrderAllocatArchive."Doc. No. Occurrence" := ServiceHeader."Doc. No. Occurrence";
                ServiceOrderAllocatArchive."Version No." := ServiceHeaderArchive."Version No.";
                RecordLinkManagement.CopyLinks(ServiceOrderAllocation, ServiceOrderAllocatArchive);
                ServiceOrderAllocatArchive.Insert();
            until ServiceOrderAllocation.Next() = 0;

        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.SetAutoCalcFields("Service Item Line Description");
        if ServiceLine.FindSet() then
            repeat
                ServiceLineArchive.Init();
                ServiceLineArchive.TransferFields(ServiceLine);
                ServiceLineArchive."Service Item Line Description" := ServiceLine."Service Item Line Description";
                ServiceLineArchive."Doc. No. Occurrence" := ServiceHeader."Doc. No. Occurrence";
                ServiceLineArchive."Version No." := ServiceHeaderArchive."Version No.";
                RecordLinkManagement.CopyLinks(ServiceLine, ServiceLineArchive);
                OnBeforeServiceLineArchiveInsert(ServiceLineArchive, ServiceLine);
                ServiceLineArchive.Insert();

                OnAfterStoreServiceLineArchive(ServiceHeader, ServiceLine, ServiceHeaderArchive, ServiceLineArchive);
            until ServiceLine.Next() = 0;

        OnAfterStoreServiceDocument(ServiceHeader, ServiceHeaderArchive);
    end;

    procedure RestoreServiceDocument(var ServiceHeaderArchive: Record "Service Header Archive")
    var
        ServiceHeader: Record "Service Header";
        ServiceShipmentHeader: Record "Service Shipment Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ConfirmManagement: Codeunit "Confirm Management";
        RecordLinkManagement: Codeunit "Record Link Management";
        ReleaseServiceDocument: Codeunit "Release Service Document";
        RestoreDocument: Boolean;
        IsHandled: Boolean;
        DoCheck, SkipDeletingLinks, ShowMessage : Boolean;
    begin
        OnBeforeRestoreServiceDocument(ServiceHeaderArchive, IsHandled);
        if IsHandled then
            exit;

        if not ServiceHeader.Get(ServiceHeaderArchive."Document Type", ServiceHeaderArchive."No.") then
            Error(ServiceDocumentDoNotExistErr, ServiceHeaderArchive."Document Type", ServiceHeaderArchive."No.");

        ServiceHeader.TestField("Release Status", ServiceHeader."Release Status"::Open);

        DoCheck := true;
        RestoreDocument := false;
        OnBeforeCheckIfDocumentIsPartiallyPosted(ServiceHeaderArchive, DoCheck, RestoreDocument);

        if (ServiceHeader."Document Type" = ServiceHeader."Document Type"::Order) and DoCheck then begin
            ServiceShipmentHeader.SetCurrentKey("Order No.");
            ServiceShipmentHeader.SetRange("Order No.", ServiceHeader."No.");
            if not ServiceShipmentHeader.IsEmpty() then
                Error(ServiceDocumentRestoreNotPossibleErr, ServiceHeader."Document Type", ServiceHeader."No.");

            ServiceInvoiceHeader.SetCurrentKey("Order No.");
            ServiceInvoiceHeader.SetRange("Order No.", ServiceHeader."No.");
            if not ServiceInvoiceHeader.IsEmpty() then
                Error(ServiceDocumentRestoreNotPossibleErr, ServiceHeader."Document Type", ServiceHeader."No.");
        end;

        if not RestoreDocument then
            if ConfirmManagement.GetResponseOrDefault(
                 StrSubstNo(
                   RestoreDocumentConfirmationQst, ServiceHeaderArchive."Document Type",
                   ServiceHeaderArchive."No.", ServiceHeaderArchive."Version No."), true)
            then
                RestoreDocument := true;

        if RestoreDocument then begin
            ServiceHeader.TestField("Doc. No. Occurrence", ServiceHeaderArchive."Doc. No. Occurrence");
            SkipDeletingLinks := false;
            OnRestoreDocumentOnBeforeDeleteServiceHeader(ServiceHeader, SkipDeletingLinks);
            if not SkipDeletingLinks then
                ServiceHeader.DeleteLinks();
            ServiceHeader.Delete(true);
            OnRestoreDocumentOnAfterDeleteServiceHeader(ServiceHeader);

            ServiceHeader.Init();
            ServiceHeader.SetHideValidationDialog(true);
            ServiceHeader."Document Type" := ServiceHeaderArchive."Document Type";
            ServiceHeader."No." := ServiceHeaderArchive."No.";
            OnBeforeServiceHeaderInsert(ServiceHeader, ServiceHeaderArchive);
            ServiceHeader.Insert(true);
            OnRestoreServiceDocumentOnAfterServiceHeaderInsert(ServiceHeader, ServiceHeaderArchive);
            ServiceHeaderArchive.CalcFields("Work Description");
            ServiceHeader.TransferFields(ServiceHeaderArchive);
            ServiceHeader.Status := ServiceHeader.Status::Pending;
            OnRestoreServiceDocumentOnBeforeServiceHeaderValidateFields(ServiceHeader, ServiceHeaderArchive);
            if ServiceHeaderArchive."Contact No." <> '' then
                ServiceHeader.Validate("Contact No.", ServiceHeaderArchive."Contact No.")
            else
                ServiceHeader.Validate("Customer No.", ServiceHeaderArchive."Customer No.");
            if ServiceHeaderArchive."Bill-to Contact No." <> '' then
                ServiceHeader.Validate("Bill-to Contact No.", ServiceHeaderArchive."Bill-to Contact No.")
            else
                ServiceHeader.Validate("Bill-to Customer No.", ServiceHeaderArchive."Bill-to Customer No.");
            ServiceHeader.Validate("Salesperson Code", ServiceHeaderArchive."Salesperson Code");
            ServiceHeader.Validate("Payment Terms Code", ServiceHeaderArchive."Payment Terms Code");
            ServiceHeader.Validate("Payment Discount %", ServiceHeaderArchive."Payment Discount %");
            ServiceHeader."Shortcut Dimension 1 Code" := ServiceHeaderArchive."Shortcut Dimension 1 Code";
            ServiceHeader."Shortcut Dimension 2 Code" := ServiceHeaderArchive."Shortcut Dimension 2 Code";
            ServiceHeader."Dimension Set ID" := ServiceHeaderArchive."Dimension Set ID";
            RecordLinkManagement.CopyLinks(ServiceHeaderArchive, ServiceHeader);
            OnAfterTransferFromArchToServiceHeader(ServiceHeader, ServiceHeaderArchive);
            ServiceHeader.Modify(true);
            RestoreServiceLines(ServiceHeaderArchive, ServiceHeader);
            ServiceHeader.Status := ServiceHeader.Status::Finished;
            ReleaseServiceDocument.Reopen(ServiceHeader);
            ShowMessage := GuiAllowed();
            OnAfterRestoreServiceDocument(ServiceHeader, ServiceHeaderArchive, ShowMessage);

            if ShowMessage then
                Message(ServiceDocumentRestoredMsg, ServiceHeader."Document Type", ServiceHeader."No.");
        end;
    end;

    local procedure RestoreServiceLines(var ServiceHeaderArchive: Record "Service Header Archive"; ServiceHeader: Record "Service Header")
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceOrderAllocation: Record "Service Order Allocation";
        ServiceItemLineArchive: Record "Service Item Line Archive";
        ServiceOrderAllocatArchive: Record "Service Order Allocat. Archive";
        ServiceLine: Record "Service Line";
        ServiceLineArchive: Record "Service Line Archive";
        RecordLinkManagement: Codeunit "Record Link Management";
        ShouldValidateQuantity: Boolean;
    begin
        RestoreServiceLineComments(ServiceHeaderArchive, ServiceHeader);

        ServiceOrderAllocatArchive.SetRange("Document Type", ServiceHeaderArchive."Document Type");
        ServiceOrderAllocatArchive.SetRange("Document No.", ServiceHeaderArchive."No.");
        ServiceOrderAllocatArchive.SetRange("Doc. No. Occurrence", ServiceHeaderArchive."Doc. No. Occurrence");
        ServiceOrderAllocatArchive.SetRange("Version No.", ServiceHeaderArchive."Version No.");
        if ServiceOrderAllocatArchive.FindSet() then
            repeat
                ServiceOrderAllocation.Init();
                ServiceOrderAllocation.TransferFields(ServiceOrderAllocatArchive);
                ServiceOrderAllocation.Insert(true);
                RecordLinkManagement.CopyLinks(ServiceOrderAllocatArchive, ServiceOrderAllocation);
            until ServiceOrderAllocatArchive.Next() = 0;

        ServiceItemLineArchive.SetRange("Document Type", ServiceHeaderArchive."Document Type");
        ServiceItemLineArchive.SetRange("Document No.", ServiceHeaderArchive."No.");
        ServiceItemLineArchive.SetRange("Doc. No. Occurrence", ServiceHeaderArchive."Doc. No. Occurrence");
        ServiceItemLineArchive.SetRange("Version No.", ServiceHeaderArchive."Version No.");
        OnRestoreServiceLinesOnAfterServiceItemLineArchiveSetFilters(ServiceItemLineArchive, ServiceHeaderArchive, ServiceHeader);
        if ServiceItemLineArchive.FindSet() then
            repeat
                ServiceItemLine.Init();
                ServiceItemLine.TransferFields(ServiceItemLineArchive);
                OnRestoreServiceLinesOnBeforeServiceItemLineInsert(ServiceItemLine, ServiceItemLineArchive);
                ServiceItemLine.Insert(true);
                OnRestoreServiceLinesOnAfterServiceItemLineInsert(ServiceItemLine, ServiceItemLineArchive);
                if ServiceItemLine."Service Item No." <> '' then begin
                    ServiceItemLine.Validate("Service Item No.");
                    if ServiceItemLineArchive."Variant Code" <> '' then
                        ServiceItemLine.Validate("Variant Code", ServiceItemLineArchive."Variant Code");
                    ServiceItemLine.Validate(Description, ServiceItemLineArchive.Description);
                end;
                ServiceItemLine."Shortcut Dimension 1 Code" := ServiceItemLineArchive."Shortcut Dimension 1 Code";
                ServiceItemLine."Shortcut Dimension 2 Code" := ServiceItemLineArchive."Shortcut Dimension 2 Code";
                ServiceItemLine."Dimension Set ID" := ServiceItemLineArchive."Dimension Set ID";
                RecordLinkManagement.CopyLinks(ServiceItemLineArchive, ServiceItemLine);
                OnAfterTransferFromArchToServiceItemLine(ServiceItemLine, ServiceItemLineArchive);
                ServiceItemLine.Modify(true);
                OnAfterRestoreServiceItemLine(ServiceHeader, ServiceItemLine, ServiceHeaderArchive, ServiceItemLineArchive);
            until ServiceItemLineArchive.Next() = 0;

        ServiceLineArchive.SetRange("Document Type", ServiceHeaderArchive."Document Type");
        ServiceLineArchive.SetRange("Document No.", ServiceHeaderArchive."No.");
        ServiceLineArchive.SetRange("Doc. No. Occurrence", ServiceHeaderArchive."Doc. No. Occurrence");
        ServiceLineArchive.SetRange("Version No.", ServiceHeaderArchive."Version No.");
        OnRestoreServiceLinesOnAfterServiceLineArchiveSetFilters(ServiceLineArchive, ServiceHeaderArchive, ServiceHeader);
        if ServiceLineArchive.FindSet() then
            repeat
                ServiceLine.Init();
                ServiceLine.TransferFields(ServiceLineArchive);
                OnRestoreServiceLinesOnBeforeServiceLineInsert(ServiceLine, ServiceLineArchive);
                ServiceLine.Insert(true);
                OnRestoreServiceLinesOnAfterServiceLineInsert(ServiceLine, ServiceLineArchive);
                if ServiceLine."Service Item No." <> '' then begin
                    ServiceLine.Validate("Service Item No.");
                    if ServiceLineArchive."Variant Code" <> '' then
                        ServiceLine.Validate("Variant Code", ServiceLineArchive."Variant Code");
                    ServiceLine.Validate(Description, ServiceLineArchive.Description);
                end;
                ShouldValidateQuantity := ServiceLine.Quantity <> 0;
                OnRestoreServiceLinesOnAfterCalcShouldValidateQuantity(ServiceLine, ServiceLineArchive, ShouldValidateQuantity);
                if ShouldValidateQuantity then
                    ServiceLine.Validate(Quantity, ServiceLineArchive.Quantity);
                OnRestoreServiceLinesOnAfterValidateQuantity(ServiceLine, ServiceLineArchive);
                ServiceLine.Validate("Unit Price", ServiceLineArchive."Unit Price");
                ServiceLine.Validate("Unit Cost (LCY)", ServiceLineArchive."Unit Cost (LCY)");
                ServiceLine.Validate("Line Discount %", ServiceLineArchive."Line Discount %");
                if ServiceLineArchive."Inv. Discount Amount" <> 0 then
                    ServiceLine.Validate("Inv. Discount Amount", ServiceLineArchive."Inv. Discount Amount");
                if ServiceLine.Amount <> ServiceLineArchive.Amount then
                    ServiceLine.Validate(Amount, ServiceLineArchive.Amount);

                ServiceLine."Shortcut Dimension 1 Code" := ServiceLineArchive."Shortcut Dimension 1 Code";
                ServiceLine."Shortcut Dimension 2 Code" := ServiceLineArchive."Shortcut Dimension 2 Code";
                ServiceLine."Dimension Set ID" := ServiceLineArchive."Dimension Set ID";
                RecordLinkManagement.CopyLinks(ServiceLineArchive, ServiceLine);
                OnAfterTransferFromArchToServiceLine(ServiceLine, ServiceLineArchive);
                ServiceLine.Modify(true);
                OnAfterRestoreServiceLine(ServiceHeader, ServiceLine, ServiceHeaderArchive, ServiceLineArchive);
            until ServiceLineArchive.Next() = 0;

        OnAfterRestoreServiceLines(ServiceHeader, ServiceItemLine, ServiceHeaderArchive, ServiceItemLineArchive);
    end;

    local procedure RestoreServiceLineComments(ServiceHeaderArchive: Record "Service Header Archive"; ServiceHeader: Record "Service Header")
    var
        ServiceCommentLineArchive: Record "Service Comment Line Archive";
        ServiceCommentLine: Record "Service Comment Line";
        NextLine: Integer;
    begin
        ServiceCommentLineArchive.SetRange("Table Subtype", ServiceHeaderArchive."Document Type");
        ServiceCommentLineArchive.SetRange("No.", ServiceHeaderArchive."No.");
        ServiceCommentLineArchive.SetRange("Doc. No. Occurrence", ServiceHeaderArchive."Doc. No. Occurrence");
        ServiceCommentLineArchive.SetRange("Version No.", ServiceHeaderArchive."Version No.");
        if ServiceCommentLineArchive.FindSet() then
            repeat
                ServiceCommentLine.Init();
                ServiceCommentLine.TransferFields(ServiceCommentLineArchive);
                ServiceCommentLine.Insert();
            until ServiceCommentLineArchive.Next() = 0;

        ServiceCommentLine.SetRange("Table Subtype", ServiceHeader."Document Type");
        ServiceCommentLine.SetRange("No.", ServiceHeader."No.");
        ServiceCommentLine.SetRange("Table Line No.", 0);
        if ServiceCommentLine.FindLast() then
            NextLine := ServiceCommentLine."Line No.";
        NextLine += 10000;
        ServiceCommentLine.Init();
        ServiceCommentLine."Table Subtype" := ServiceHeader."Document Type";
        ServiceCommentLine."No." := ServiceHeader."No.";
        ServiceCommentLine."Table Line No." := 0;
        ServiceCommentLine."Table Name" := ServiceCommentLine."Table Name"::"Service Header";
        ServiceCommentLine."Line No." := NextLine;
        ServiceCommentLine.Date := WorkDate();
        ServiceCommentLine.Comment := StrSubstNo(ServiceDocumentRestoredTxt, Format(ServiceHeaderArchive."Version No."));
        OnRestoreServiceLineCommentsOnBeforeInsertServiceCommentLine(ServiceCommentLine);
        ServiceCommentLine.Insert();
    end;

    local procedure GetNextVersionNo(TableId: Integer; ServiceDocumentType: Enum "Service Document Type"; DocNo: Code[20]; DocNoOccurrence: Integer) VersionNo: Integer
    var
        ServiceHeaderArchive: Record "Service Header Archive";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetNextVersionNo(TableId, ServiceDocumentType, DocNo, DocNoOccurrence, VersionNo, IsHandled);
        if IsHandled then
            exit(VersionNo);

        case TableId of
            DATABASE::"Service Header":
                begin
                    ServiceHeaderArchive.LockTable();
                    ServiceHeaderArchive.SetLoadFields("Document Type", "No.", "Doc. No. Occurrence", "Version No.");
                    ServiceHeaderArchive.SetRange("Document Type", ServiceDocumentType);
                    ServiceHeaderArchive.SetRange("No.", DocNo);
                    ServiceHeaderArchive.SetRange("Doc. No. Occurrence", DocNoOccurrence);
                    if ServiceHeaderArchive.FindLast() then
                        exit(ServiceHeaderArchive."Version No." + 1);

                    exit(1);
                end;
            else begin
                OnGetNextVersionNo(TableId, ServiceDocumentType, DocNo, DocNoOccurrence, VersionNo);
                exit(VersionNo)
            end;
        end;
    end;

    local procedure StoreServiceDocumentComments(DocumentType: Enum "Service Comment Table Subtype"; DocumentNo: Code[20]; DocNoOccurrence: Integer; VersionNo: Integer)
    var
        ServiceCommentLine: Record "Service Comment Line";
        ServiceCommentLineArchive: Record "Service Comment Line Archive";
    begin
        ServiceCommentLine.SetRange("Table Subtype", DocumentType);
        ServiceCommentLine.SetRange("No.", DocumentNo);
        if ServiceCommentLine.FindSet() then
            repeat
                ServiceCommentLineArchive.Init();
                ServiceCommentLineArchive.TransferFields(ServiceCommentLine);
                ServiceCommentLineArchive."Doc. No. Occurrence" := DocNoOccurrence;
                ServiceCommentLineArchive."Version No." := VersionNo;
                OnStoreServiceDocumentCommentsOnBeforeServiceCommentLineArchInsert(ServiceCommentLineArchive, ServiceCommentLine);
                ServiceCommentLineArchive.Insert();
            until ServiceCommentLine.Next() = 0;
    end;

    internal procedure GetNextOccurrenceNo(TableId: Integer; ServiceDocumentType: Enum "Service Document Type"; DocNo: Code[20]) OccurenceNo: Integer
    var
        ServiceHeaderArchive: Record "Service Header Archive";
    begin
        case TableId of
            DATABASE::"Service Header":
                begin
                    ServiceHeaderArchive.LockTable();
                    ServiceHeaderArchive.LoadFields("Document Type", "No.", "Doc. No. Occurrence");
                    ServiceHeaderArchive.SetRange("Document Type", ServiceDocumentType);
                    ServiceHeaderArchive.SetRange("No.", DocNo);
                    if ServiceHeaderArchive.FindLast() then
                        exit(ServiceHeaderArchive."Doc. No. Occurrence" + 1);

                    exit(1);
                end;
            else begin
                OnGetNextOccurrenceNo(TableId, ServiceDocumentType, DocNo, OccurenceNo);
                exit(OccurenceNo)
            end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterStoreServiceLineArchive(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; var ServiceHeaderArchive: Record "Service Header Archive"; var ServiceLineArchive: Record "Service Line Archive")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterStoreServiceDocument(var ServiceHeader: Record "Service Header"; var ServiceHeaderArchive: Record "Service Header Archive")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterServiceHeaderArchiveInsert(var ServiceHeaderArchive: Record "Service Header Archive"; ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnStoreServiceDocumentCommentsOnBeforeServiceCommentLineArchInsert(var ServiceCommentLineArchive: Record "Service Comment Line Archive"; ServiceCommentLine: Record "Service Comment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAutoArchiveServiceDocument(var ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeArchServiceDocumentNoConfirm(var ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeArchiveServiceDocument(var ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAutoArchiveServiceDocument(var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeStoreServiceDocument(var ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceHeaderArchiveInsert(var ServiceHeaderArchive: Record "Service Header Archive"; ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceItemLineArchiveInsert(var ServiceItemLineArchive: Record "Service Item Line Archive"; ServiceItemLine: Record "Service Item Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceLineArchiveInsert(var ServiceLineArchive: Record "Service Line Archive"; ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetNextVersionNo(TableId: Integer; ServiceDocumentType: Enum "Service Document Type"; DocNo: Code[20]; DocNoOccurrence: Integer; var VersionNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetNextVersionNo(TableId: Integer; ServiceDocumentType: Enum "Service Document Type"; DocNo: Code[20]; DocNoOccurrence: Integer; var VersionNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetNextOccurrenceNo(TableId: Integer; ServiceDocumentType: Enum "Service Document Type"; DocNo: Code[20]; var OccurenceNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRestoreServiceDocument(var ServiceHeaderArchive: Record "Service Header Archive"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckIfDocumentIsPartiallyPosted(var ServiceHeaderArchive: Record "Service Header Archive"; var DoCheck: Boolean; var RestoreDocumentWithoutConfirmation: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRestoreDocumentOnBeforeDeleteServiceHeader(var ServiceHeader: Record "Service Header"; var SkipDeletingLinks: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRestoreDocumentOnAfterDeleteServiceHeader(var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceHeaderInsert(var ServiceHeader: Record "Service Header"; ServiceHeaderArchive: Record "Service Header Archive");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRestoreServiceDocumentOnAfterServiceHeaderInsert(var ServiceHeader: Record "Service Header"; var ServiceHeaderArchive: Record "Service Header Archive");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRestoreServiceDocumentOnBeforeServiceHeaderValidateFields(var ServiceHeader: Record "Service Header"; ServiceHeaderArchive: Record "Service Header Archive");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromArchToServiceHeader(var ServiceHeader: Record "Service Header"; var ServiceHeaderArchive: Record "Service Header Archive")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRestoreServiceDocument(var ServiceHeader: Record "Service Header"; var ServiceHeaderArchive: Record "Service Header Archive"; var ShowMessage: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRestoreServiceLinesOnAfterServiceItemLineArchiveSetFilters(var ServiceItemLineArchive: Record "Service Item Line Archive"; var ServiceHeaderArchive: Record "Service Header Archive"; ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRestoreServiceLinesOnAfterServiceLineArchiveSetFilters(var ServiceLineArchive: Record "Service Line Archive"; var ServiceHeaderArchive: Record "Service Header Archive"; ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRestoreServiceLinesOnBeforeServiceItemLineInsert(var ServiceItemLine: Record "Service Item Line"; var ServiceItemLineArchive: Record "Service Item Line Archive")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRestoreServiceLinesOnBeforeServiceLineInsert(var ServiceLine: Record "Service Line"; var ServiceLineArchive: Record "Service Line Archive")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRestoreServiceLinesOnAfterServiceItemLineInsert(var ServiceItemLine: Record "Service Item Line"; var ServiceItemLineArchive: Record "Service Item Line Archive")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRestoreServiceLinesOnAfterServiceLineInsert(var ServiceLine: Record "Service Line"; var ServiceLineArchive: Record "Service Line Archive")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromArchToServiceItemLine(var ServiceItemLine: Record "Service Item Line"; var ServiceItemLineArchive: Record "Service Item Line Archive")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromArchToServiceLine(var ServiceLine: Record "Service Line"; var ServiceLineArchive: Record "Service Line Archive")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRestoreServiceItemLine(var ServiceHeader: Record "Service Header"; var ServiceItemLine: Record "Service Item Line"; var ServiceHeaderArchive: Record "Service Header Archive"; var ServiceItemLineArchive: Record "Service Item Line Archive")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRestoreServiceLine(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; var ServiceHeaderArchive: Record "Service Header Archive"; var ServiceLineArchive: Record "Service Line Archive")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRestoreServiceLines(var ServiceHeader: Record "Service Header"; var ServiceItemLine: Record "Service Item Line"; var ServiceHeaderArchive: Record "Service Header Archive"; var ServiceItemLineArchive: Record "Service Item Line Archive")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRestoreServiceLineCommentsOnBeforeInsertServiceCommentLine(var ServiceCommentLine: Record "Service Comment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRestoreServiceLinesOnAfterCalcShouldValidateQuantity(var ServiceLine: Record "Service Line"; var ServiceLineArchive: Record "Service Line Archive"; var ShouldValidateQuantity: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRestoreServiceLinesOnAfterValidateQuantity(var ServiceLine: Record "Service Line"; var ServiceLineArchive: Record "Service Line Archive")
    begin
    end;
}