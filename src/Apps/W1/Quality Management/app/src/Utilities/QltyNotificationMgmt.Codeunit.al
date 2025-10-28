// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Utilities;

using Microsoft.Inventory.Item;
using Microsoft.QualityManagement.Dispositions;
using Microsoft.QualityManagement.Document;
using Microsoft.Utilities;
using Microsoft.Warehouse.Activity;
using System.Reflection;

/// <summary>
/// This codeunit helps with notification management.
/// </summary>
codeunit 20437 "Qlty. Notification Mgmt."
{
    Access = Internal;

    var
        AssignToSelfLbl: Label 'Assign to myself';
        OpenTheDocumentLbl: Label 'Open the document';
        HandleNotificationActionAssignToSelfTok: Label 'HandleNotificationActionAssignToSelf', Locked = true;
        HandleOpenDocumentTok: Label 'HandleOpenDocument', Locked = true;
        IgnoreLbl: Label 'Ignore';
        HandleNotificationActionIgnoreTok: Label 'HandleNotificationActionIgnore', Locked = true;
        NotificationDataTestRecordIdTok: Label 'TestRecordId', Locked = true;
        NotificationDataRelatedRecordIdTok: Label 'RelatedRecordId', Locked = true;
        YouHaveAlteredDoYouWantToAutoAssignQst: Label 'You have altered test %1, would you like to assign it to yourself?', Comment = '%1=the test number';
        DocumentCreatedAMsg: Label 'A %1 %2 has been created for test %3. Do you want to open it?', Comment = '%1=the document type, %2=the document no %3=the test';
        DocumentCreatedAnMsg: Label 'An %1 %2 has been created for test %3. Do you want to open it?', Comment = '%1=the document type, %2=the document no %3=the test';
        DocumentNotAbleToBeCreatedAMsg: Label 'A %1 could not be created for test %2 for %3 %6 of %4. %5 Please make sure there is sufficient inventory available. Please verify that the test has sufficient details for the item, variant, lot, and serial. Make sure to define the quantity to move.', Comment = '%1=the document type, %2=the test, %3=the quantity, %4=the source details, %5=additional message details, %6=uom';
        DocumentNotAbleToBeCreatedAnMsg: Label 'An %1 could not be created for test %2 for %3 %6 of %4. %5 Please make sure there is sufficient inventory available. Please verify that the test has sufficient details for the item, variant, lot, and serial. Make sure to define the quantity to move.', Comment = '%1=the document type, %2=the test, %3=the quantity, %4=the source details, %5=additional message details, %6=uom';
        ChangeTrackingEntryCreatedMsg: Label 'The Quality Inspection Test %1,%2 created a journal entry to update the tracking information for %5 %6 of item %3 to%4%7.', Comment = '%1=test no., %2=retest no., %3=item and source tracking, %4=new item tracking,%5=quantity, %6=base UOM,%7=optional location';
        ChangeTrackingEntryPostedMsg: Label 'The Quality Inspection Test %1,%2 updated the tracking information for %5 %6 of item %3 to%4%7.', Comment = '%1=test no., %2=retest no., %3=item and source tracking, %4=new item tracking,%5=quantity, %6=base UOM, %7=optional location';
        ChangeTrackingFailMsg: Label 'Unable to update tracking information to%1%2. Check batch setup on the Quality Management Setup page.', Comment = '%1=new item tracking information,%2=optional location';
        ExpDateMsg: Label ' Expiration Date: %1', Comment = '%1=expiration date';
        InLocationMsg: Label ' in location %1', Comment = '%1=the location';
        MoveEntryCreatedMsg: Label 'The Quality Inspection Test %1,%2 created a %10 to move %3 %12 of item %4 from %5 %6 to %7 %8 in %11 %9.', Comment = '%1=test no., %2=retest no., %3=quantity, %4=source item and tracking details, %5=from location, %6=from bin,%7=to location,%8=to bin, %9=the batch or document, %10=the type of journal, %11=the type of the document or batch, %12=uom';
        MoveEntryPostedMsg: Label 'The Quality Inspection Test %1,%2 moved %3 %9 of item %4 from %5 %6 to %7 %8.', Comment = '%1=test no., %2=retest no., %3=quantity, %4=source item and tracking details, %5=from location, %6=from bin,%7=to location,%8=to bin, %9=uom';
        TypeJournalEntryLbl: Label 'journal entry';
        TypeWorksheetEntryLbl: Label 'worksheet entry';
        TypeMovementDocumentLbl: Label 'movement document';
        TypeJournalEntryDocumentLbl: Label 'document';
        TypeJournalEntryBatchLbl: Label 'batch';
        LocationLbl: Label 'Location: %1', Comment = '%1= the location';
        BinLbl: Label ' Bin: %1', Comment = '%1= the bin';
        NegativeEntriesCreatedMsg: Label 'The Quality Inspection Test %1,%2 created negative adjustment entries in batch %5 to reduce %3 in %6 by %4 %7.', Comment = '%1=test no., %2=retest no., %3=source item and tracking details, %4=quantity, %5=the batch name, %6=location and bin details., %7 = uom';
        MoveEntriesPostedMsg: Label 'The Quality Inspection Test %1,%2 reduced inventory of %3 in %5 by %4 %6.', Comment = '%1=test no., %2=retest no., %3=source item and tracking details, %4=quantity, %5=location and bin details., %6=uom';
        BlockedStateChangedLbl: Label 'Test %1 changed %2 %3 on item %4 to %5.', Comment = '%1=the test number, %2=the type, %3, %3= the type,%4 = the item,%5=the blocked state';
        BlockedLbl: Label 'blocked';
        UnBlockedLbl: Label 'un-blocked';
        OpenTheInfoCardLbl: Label 'Open the %1 No. Information.', Comment = '%1 =the info type.';
        VariantTok: Label ':%1', Comment = '%1=variant';
        LotTok: Label ' Lot: %1', Comment = '%1=lot no.';
        SerialTok: Label ' Serial: %1', Comment = '%1=serial no.';
        PackageTok: Label ' Package: %1', Comment = '%1=package no.';
        LotMsg: Label ' Lot: %1', Comment = '%1=lot no.';
        SerialMsg: Label ' Serial: %1', Comment = '%1=serial no.';
        PackageMsg: Label ' Package: %1', Comment = '%1=package no.';
        OriginTok: Label 'origin', Locked = true;

    /// <summary>
    /// Call this to create a notification if you want to assign to yourself.
    /// </summary>
    /// <param name="QltyInspectionTestHeader"></param>
    procedure NotifyDoYouWantToAssignToYourself(QltyInspectionTestHeader: Record "Qlty. Inspection Test Header")
    var
        AssignToSelfNotification: Notification;
        AvailableOptions: Dictionary of [Text, Text];
    begin
        AvailableOptions.Add(AssignToSelfLbl, HandleNotificationActionAssignToSelfTok);
        AvailableOptions.Add(IgnoreLbl, HandleNotificationActionIgnoreTok);
        AssignToSelfNotification.Id := QltyInspectionTestHeader.SystemId;
        AssignToSelfNotification.SetData(NotificationDataTestRecordIdTok, Format(QltyInspectionTestHeader.RecordId()));
        CreateActionNotification(AssignToSelfNotification, StrSubstNo(YouHaveAlteredDoYouWantToAutoAssignQst, QltyInspectionTestHeader."No."), AvailableOptions);
    end;

    /// <summary>
    /// Creates a notification that a document has been created.
    /// </summary>
    /// <param name="QltyInspectionTestHeader"></param>
    /// <param name="TempInstructionQltyDispositionBuffer"></param>
    /// <param name="DocumentType">Used to display in the action.</param>
    /// <param name="DocumentNo"></param>
    /// <param name="RelatedDocumentVariant">a variant referring to the document</param>
    internal procedure NotifyDocumentCreated(
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        DocumentType: Text;
        DocumentNo: Text;
        RelatedDocumentVariant: Variant)
    var
        DataTypeManagement: Codeunit "Data Type Management";
        DocumentCreatedNotification: Notification;
        RelatedDocument: RecordId;
        OptionalRelatedDocumentRecordRef: RecordRef;
        Source: Text;
        CurrentMessage: Text;
        AvailableOptions: Dictionary of [Text, Text];
    begin
        Source := GetSourceSummaryText(QltyInspectionTestHeader);

        if DataTypeManagement.GetRecordRef(RelatedDocumentVariant, OptionalRelatedDocumentRecordRef) then
            RelatedDocument := OptionalRelatedDocumentRecordRef.RecordId();

        if (DocumentType <> '') and (DocumentType[1] in ['A', 'E', 'I', 'O', 'U']) then
            CurrentMessage := StrSubstNo(
                DocumentCreatedAnMsg,
                DocumentType,
                DocumentNo,
                QltyInspectionTestHeader."No.")
        else
            CurrentMessage := StrSubstNo(
                DocumentCreatedAMsg,
                DocumentType,
                DocumentNo,
                QltyInspectionTestHeader."No.");

        AvailableOptions.Add(OpenTheDocumentLbl, HandleOpenDocumentTok);

        DocumentCreatedNotification.SetData(NotificationDataTestRecordIdTok, Format(QltyInspectionTestHeader.RecordId()));

        DocumentCreatedNotification.SetData(NotificationDataRelatedRecordIdTok, Format(RelatedDocument));

        CreateActionNotification(DocumentCreatedNotification, CurrentMessage, AvailableOptions);
    end;

    /// <summary>
    /// Creates a notification that a document was not able to be created.
    /// </summary>
    /// <param name="QltyInspectionTestHeader"></param>
    /// <param name="TempInstructionQltyDispositionBuffer"></param>
    /// <param name="DocumentType">Used to display in the action.</param>
    procedure NotifyDocumentCreationFailed(var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; DocumentType: Text)
    var
        DummyVariant: Variant;
    begin
        NotifyDocumentCreationFailed(QltyInspectionTestHeader, TempInstructionQltyDispositionBuffer, DocumentType, '', DummyVariant);
    end;

    /// <summary>
    /// Creates a notification that the document creation has failed.
    /// </summary>
    /// <param name="QltyInspectionTestHeader"></param>
    /// <param name="TempInstructionQltyDispositionBuffer"></param>
    /// <param name="DocumentType"></param>
    /// <param name="OptionalAdditionalMessageContext"></param>
    /// <param name="OptionalRelatedDocumentVariant"></param>
    procedure NotifyDocumentCreationFailed(var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; DocumentType: Text; OptionalAdditionalMessageContext: Text; OptionalRelatedDocumentVariant: Variant)
    var
        Item: Record Item;
        DataTypeManagement: Codeunit "Data Type Management";
        DocumentCreationFailedNotification: Notification;
        OptionalRelatedDocumentRecordRef: RecordRef;
        RelatedDocument: RecordId;
        CurrentMessage: Text;
        AvailableOptions: Dictionary of [Text, Text];
    begin
        if QltyInspectionTestHeader."Source Item No." <> '' then
            if Item.Get(QltyInspectionTestHeader."Source Item No.") then;

        if (DocumentType <> '') and (DocumentType[1] in ['A', 'E', 'I', 'O', 'U', 'a', 'e', 'i', 'o', 'u']) then
            CurrentMessage := StrSubstNo(
                DocumentNotAbleToBeCreatedAnMsg,
                DocumentType,
                QltyInspectionTestHeader."No.",
                TempInstructionQltyDispositionBuffer."Qty. To Handle (Base)",
                GetSourceSummaryText(QltyInspectionTestHeader),
                OptionalAdditionalMessageContext,
                Item."Base Unit of Measure")
        else
            CurrentMessage := StrSubstNo(
                DocumentNotAbleToBeCreatedAMsg,
                DocumentType,
                QltyInspectionTestHeader."No.",
                TempInstructionQltyDispositionBuffer."Qty. To Handle (Base)",
                GetSourceSummaryText(QltyInspectionTestHeader),
                OptionalAdditionalMessageContext,
                Item."Base Unit of Measure");

        if OptionalRelatedDocumentVariant.IsRecord() or OptionalRelatedDocumentVariant.IsRecordRef() or OptionalRelatedDocumentVariant.IsRecordId() then
            if DataTypeManagement.GetRecordRef(OptionalRelatedDocumentVariant, OptionalRelatedDocumentRecordRef) then begin
                RelatedDocument := OptionalRelatedDocumentRecordRef.RecordId();
                DocumentCreationFailedNotification.SetData(NotificationDataRelatedRecordIdTok, Format(RelatedDocument));
                AvailableOptions.Add(OpenTheDocumentLbl, HandleOpenDocumentTok);
            end;

        CreateActionNotification(DocumentCreationFailedNotification, CurrentMessage, AvailableOptions);
    end;

    /// <summary>
    /// Creates a notification that an item tracking change occurred.
    /// </summary>
    /// <param name="QltyInspectionTestHeader"></param>
    /// <param name="TempInstructionQltyDispositionBuffer"></param>
    /// <param name="LineCreated"></param>
    /// <param name="Success"></param>
    /// <param name="ChangedBaseQuantity"></param>
    /// <param name="DocumentOrBatchName"></param>
    procedure NotifyItemTrackingChanged(QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; LineCreated: Boolean; Success: Boolean; ChangedBaseQuantity: Decimal; DocumentOrBatchName: Text; OptionalSourceExpirationDate: Date)
    var
        Item: Record Item;
        Source: Text;
        New: Text;
        CurrentMessage: Text;
        OptionalLocation: Text;
    begin
        New := GetTargetSummaryText(TempInstructionQltyDispositionBuffer);
        if LineCreated then begin
            if Item.Get(QltyInspectionTestHeader."Source Item No.") then;

            Source := GetSourceSummaryText(QltyInspectionTestHeader);
            if (OptionalSourceExpirationDate <> 0D) and (OptionalSourceExpirationDate <> TempInstructionQltyDispositionBuffer."New Expiration Date") then
                Source := Source + StrSubstNo(ExpDateMsg, OptionalSourceExpirationDate);

            if TempInstructionQltyDispositionBuffer.GetFromLocationCode() <> '' then
                OptionalLocation := StrSubstNo(InLocationMsg, TempInstructionQltyDispositionBuffer.GetFromLocationCode());

            if (TempInstructionQltyDispositionBuffer."Entry Behavior" = TempInstructionQltyDispositionBuffer."Entry Behavior"::Post) and Success then
                CurrentMessage := StrSubstNo(ChangeTrackingEntryPostedMsg, QltyInspectionTestHeader."No.", QltyInspectionTestHeader."Retest No.", Source, New, ChangedBaseQuantity, Item."Base Unit of Measure", OptionalLocation)
            else
                CurrentMessage := StrSubstNo(ChangeTrackingEntryCreatedMsg, QltyInspectionTestHeader."No.", QltyInspectionTestHeader."Retest No.", Source, New, ChangedBaseQuantity, Item."Base Unit of Measure", OptionalLocation);
        end else
            CurrentMessage := StrSubstNo(ChangeTrackingFailMsg, New, OptionalLocation);

        CreateNotification(CurrentMessage);
    end;

    /// <summary>
    /// Creates a notification that a movement has occurred.
    /// </summary>
    /// <param name="QltyInspectionTestHeader"></param>
    /// <param name="TempInstructionQltyDispositionBuffer"></param>
    /// <param name="DocumentOrBatchName"></param>   
    procedure NotifyMovementOccurred(QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; DocumentOrBatchName: Text)
    var
        Item: Record Item;
        Source: Text;
        CurrentMessage: Text;
        TypeOfJournal: Text;
        TypeOfEntity: Text;
    begin
        if QltyInspectionTestHeader."Source Item No." <> '' then
            if Item.Get(QltyInspectionTestHeader."Source Item No.") then;

        Source := GetSourceSummaryText(QltyInspectionTestHeader);
        case TempInstructionQltyDispositionBuffer."Disposition Action" of
            TempInstructionQltyDispositionBuffer."Disposition Action"::"Move with Internal Movement":
                begin
                    TypeOfJournal := TypeMovementDocumentLbl;
                    TypeOfEntity := TypeJournalEntryDocumentLbl;
                end;
            TempInstructionQltyDispositionBuffer."Disposition Action"::"Move with Movement Worksheet":
                begin
                    TypeOfJournal := TypeWorksheetEntryLbl;
                    TypeOfEntity := TypeJournalEntryDocumentLbl;
                end;
            else begin
                TypeOfJournal := TypeJournalEntryLbl;
                TypeOfEntity := TypeJournalEntryBatchLbl;
            end;
        end;
        if TempInstructionQltyDispositionBuffer."Entry Behavior" = TempInstructionQltyDispositionBuffer."Entry Behavior"::Post then
            CurrentMessage := StrSubstNo(
                MoveEntryPostedMsg,
                QltyInspectionTestHeader."No.",
                QltyInspectionTestHeader."Retest No.",
                TempInstructionQltyDispositionBuffer."Qty. To Handle (Base)",
                Source,
                TempInstructionQltyDispositionBuffer."Location Filter",
                TempInstructionQltyDispositionBuffer."Bin Filter",
                TempInstructionQltyDispositionBuffer."New Location Code",
                TempInstructionQltyDispositionBuffer."New Bin Code",
                Item."Base Unit of Measure")
        else
            CurrentMessage := StrSubstNo(MoveEntryCreatedMsg,
                QltyInspectionTestHeader."No.",
                QltyInspectionTestHeader."Retest No.",
                TempInstructionQltyDispositionBuffer."Qty. To Handle (Base)",
                Source,
                TempInstructionQltyDispositionBuffer."Location Filter",
                TempInstructionQltyDispositionBuffer."Bin Filter",
                TempInstructionQltyDispositionBuffer."New Location Code",
                TempInstructionQltyDispositionBuffer."New Bin Code",
                DocumentOrBatchName,
                TypeOfJournal,
                TypeOfEntity,
                Item."Base Unit of Measure");

        CreateNotification(CurrentMessage);
    end;

    /// <summary>
    /// Creates a notification that a negative adjustment occurred.
    /// </summary>
    /// <param name="QltyInspectionTestHeader"></param>
    /// <param name="TempInstructionQltyDispositionBuffer"></param>
    /// <param name="DocumentOrBatchName"></param>
    internal procedure NotifyNegativeAdjustmentOccurred(QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; DocumentOrBatchName: Text)
    var
        Item: Record Item;
        Source: Text;
        CurrentMessage: Text;
        LocationAndBinDetails: Text;
    begin
        Source := GetSourceSummaryText(QltyInspectionTestHeader);
        if QltyInspectionTestHeader."Source Item No." <> '' then
            if Item.Get(QltyInspectionTestHeader."Source Item No.") then;

        if TempInstructionQltyDispositionBuffer."Location Filter" <> '' then
            LocationAndBinDetails += StrSubstNo(LocationLbl, TempInstructionQltyDispositionBuffer."Location Filter");

        if TempInstructionQltyDispositionBuffer."Bin Filter" <> '' then
            LocationAndBinDetails += StrSubstNo(BinLbl, TempInstructionQltyDispositionBuffer."Bin Filter");

        if TempInstructionQltyDispositionBuffer."Entry Behavior" = TempInstructionQltyDispositionBuffer."Entry Behavior"::Post then
            CurrentMessage := StrSubstNo(
                MoveEntriesPostedMsg,
                QltyInspectionTestHeader."No.",
                QltyInspectionTestHeader."Retest No.",
                Source,
                Abs(TempInstructionQltyDispositionBuffer."Qty. To Handle (Base)"),
                LocationAndBinDetails,
                Item."Base Unit of Measure")
        else
            CurrentMessage := StrSubstNo(
                NegativeEntriesCreatedMsg,
                QltyInspectionTestHeader."No.",
                QltyInspectionTestHeader."Retest No.",
                Source,
                Abs(TempInstructionQltyDispositionBuffer."Qty. To Handle (Base)"),
                DocumentOrBatchName,
                LocationAndBinDetails,
                Item."Base Unit of Measure");

        CreateNotification(CurrentMessage);
    end;

    /// <summary>
    /// Creates a notification with no action with a local scope.
    /// </summary>
    /// <param name="CurrentMessage">The notification message to display.</param>
    internal procedure Notify(CurrentMessage: Text)
    begin
        CreateNotification(CurrentMessage);
    end;

    /// <summary>
    /// procedure name *must* mah tcHandleOpenDocumentTok 
    /// This is the event handle for the 'open the document' 
    /// </summary>
    /// <param name="NotificationToShow">The notification that triggered the action.</param>
    internal procedure HandleOpenDocument(NotificationToShow: Notification)
    var
        TempWarehouseActivityHeader: Record "Warehouse Activity Header" temporary;
        DataTypeManagement: Codeunit "Data Type Management";
        PageManagement: Codeunit "Page Management";
        DocumentSubTypeFieldRef: FieldRef;
        RecordRef: RecordRef;
        RelatedRecordId: RecordId;
        RecordIdData: Text;
        RecordRefVariant: Variant;
        CurrentPage: Integer;
        ActivityType: Integer;
    begin
        RecordIdData := NotificationToShow.GetData(NotificationDataRelatedRecordIdTok);
        if Evaluate(RelatedRecordId, RecordIdData) then
            if DataTypeManagement.GetRecordRef(RelatedRecordId, RecordRef) then begin
                RecordRefVariant := RecordRef;

                if RecordRef.Number() = Database::"Warehouse Activity Header" then begin
                    DocumentSubTypeFieldRef := RecordRef.Field(TempWarehouseActivityHeader.FieldNo(TempWarehouseActivityHeader.Type));
                    ActivityType := DocumentSubTypeFieldRef.Value();
                    case ActivityType of
                        TempWarehouseActivityHeader.Type::"Invt. Movement".AsInteger():
                            CurrentPage := Page::"Inventory Movement";
                        TempWarehouseActivityHeader.Type::Movement.AsInteger():
                            CurrentPage := Page::"Warehouse Movement";
                        TempWarehouseActivityHeader.Type::"Put-away".AsInteger():
                            CurrentPage := Page::"Warehouse Put-away";
                    end;
                end else
                    CurrentPage := PageManagement.GetPageID(RecordRef);

                Page.RunModal(CurrentPage, RecordRefVariant);
            end;
    end;

    /// <summary>
    /// procedure name *must* match tcHandleNotificationActionAssignToSelf 
    /// </summary>
    /// <param name="NotificationToShow">The notification that triggered the action.</param>
    internal procedure HandleNotificationActionAssignToSelf(NotificationToShow: Notification)
    var
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        TestRecordId: RecordId;
        RecordIdData: Text;
    begin
        RecordIdData := NotificationToShow.GetData(NotificationDataTestRecordIdTok);
        if Evaluate(TestRecordId, RecordIdData) then
            if QltyInspectionTestHeader.Get(TestRecordId) then begin
                QltyInspectionTestHeader.AssignToSelf();
#pragma warning disable AA0214
                if QltyInspectionTestHeader.Modify() then;
#pragma warning restore AA0214
            end;
    end;

    /// <summary>
    /// procedure name *must* mah tcHandleNotificationActionIgnoreTok 
    /// </summary>
    /// <param name="NotificationToShow">The notification that triggered the action.</param>
    internal procedure HandleNotificationActionIgnore(NotificationToShow: Notification)
    var
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        TestRecordId: RecordId;
        RecordIdData: Text;
    begin
        RecordIdData := NotificationToShow.GetData(NotificationDataTestRecordIdTok);
        if Evaluate(TestRecordId, RecordIdData) then
            if QltyInspectionTestHeader.Get(TestRecordId) then
                QltyInspectionTestHeader.SetPreventAutoAssignment(true);
    end;

    /// <summary>
    /// Creates a notification that the tracking state has changed.
    /// </summary>
    /// <param name="QltyInspectionTestHeader"></param>
    /// <param name="InformationType">The lot no information card, or serial no information card, or package no information card.</param>
    /// <param name="Type">The label for Lot or Serial or Package</param>
    /// <param name="ItemTrackingDetail">The content for Lot or Serial or Package</param>
    /// <param name="BlockedState"></param>
    procedure NotifyItemTrackingBlockStateChanged(
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        InformationType: RecordId;
        Type: Text;
        ItemTrackingDetail: Text;
        BlockedState: Boolean)
    var
        ItemTrackingBlockedStateChangedNotification: Notification;
        CurrentMessage: Text;
        AvailableOptions: Dictionary of [Text, Text];
        BlockOrUnblock: Text;
    begin
        if BlockedState then
            BlockOrUnblock := BlockedLbl
        else
            BlockOrUnblock := UnBlockedLbl;
        CurrentMessage := StrSubstNo(
            BlockedStateChangedLbl,
            QltyInspectionTestHeader."No.",
            Type,
            ItemTrackingDetail,
            QltyInspectionTestHeader."Source Item No.",
            BlockOrUnblock);

        AvailableOptions.Add(StrSubstNo(OpenTheInfoCardLbl, Type), HandleOpenDocumentTok);

        ItemTrackingBlockedStateChangedNotification.SetData(NotificationDataTestRecordIdTok, Format(QltyInspectionTestHeader.RecordId()));

        ItemTrackingBlockedStateChangedNotification.SetData(NotificationDataRelatedRecordIdTok, Format(InformationType));

        CreateActionNotification(ItemTrackingBlockedStateChangedNotification, CurrentMessage, AvailableOptions);
    end;

    /// <summary>
    /// Creates a notification with a user available action within the local scope.
    /// </summary>
    /// <param name="NotificationToShow">A notification object to use that may have additional data points set. Note that origin is already used.</param>
    /// <param name="CurrentMessage">The notification message to display.</param>
    /// <param name="AvailableOptions">A dictionary of action labels and callbacks</param>
    local procedure CreateActionNotification(var NotificationToShow: Notification; CurrentMessage: Text; AvailableOptions: Dictionary of [Text, Text])
    var
        ActionMessage: Text;
        ActionProcedureCallback: Text;
        Handled: Boolean;
    begin
        OnBeforeCreateActionNotification(NotificationToShow, CurrentMessage, AvailableOptions, Handled);
        if Handled then
            exit;

        NotificationToShow.Message(CurrentMessage);
        foreach ActionMessage in AvailableOptions.Keys do
            if AvailableOptions.Get(ActionMessage, ActionProcedureCallback) then
                NotificationToShow.AddAction(ActionMessage, Codeunit::"Qlty. Notification Mgmt.", ActionProcedureCallback);

        NotificationToShow.Scope := NotificationScope::LocalScope;
        NotificationToShow.SetData(OriginTok, CurrentMessage);
        NotificationToShow.Send();
    end;

    /// <summary>
    /// Creates a notification with no action with a local scope.
    /// </summary>
    /// <param name="CurrentMessage">The notification message to display.</param>
    local procedure CreateNotification(CurrentMessage: Text)
    var
        NotificationToCreate: Notification;
    begin
        NotificationToCreate.Message(CurrentMessage);
        NotificationToCreate.Scope := NotificationScope::LocalScope;
        NotificationToCreate.SetData(OriginTok, CurrentMessage);
        if GuiAllowed() then
            NotificationToCreate.Send();
    end;

    /// <summary>
    /// Used to help build a consistent 'source' tracking details.
    /// </summary>
    /// <param name="QltyInspectionTestHeader"></param>
    /// <returns></returns>   
    procedure GetSourceSummaryText(var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"): Text
    var
        TextBuilder: TextBuilder;
    begin
        if QltyInspectionTestHeader."Source Item No." = '' then
            if QltyInspectionTestHeader."Source Document No." <> '' then
                TextBuilder.Append(QltyInspectionTestHeader."Source Document No.")
            else
                TextBuilder.Append(QltyInspectionTestHeader."Source Custom 1")
        else begin
            TextBuilder.Append(QltyInspectionTestHeader."Source Item No.");
            if QltyInspectionTestHeader."Source Variant Code" <> '' then
                TextBuilder.Append(StrSubstNo(VariantTok, QltyInspectionTestHeader."Source Variant Code"));
            if QltyInspectionTestHeader."Source Lot No." <> '' then
                TextBuilder.Append(StrSubstNo(LotTok, QltyInspectionTestHeader."Source Lot No."));
            if QltyInspectionTestHeader."Source Serial No." <> '' then
                TextBuilder.Append(StrSubstNo(SerialTok, QltyInspectionTestHeader."Source Serial No."));
            if QltyInspectionTestHeader."Source Package No." <> '' then
                TextBuilder.Append(StrSubstNo(PackageTok, QltyInspectionTestHeader."Source Package No."));
        end;
        exit(TextBuilder.ToText());
    end;

    /// <summary>
    /// Helps build a consistent partial message for target/destination/to tracking details.
    /// </summary>
    /// <param name="TempInstructionQltyDispositionBuffer"></param>
    /// <returns></returns>
    local procedure GetTargetSummaryText(var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary): Text
    var
        TextBuilder: TextBuilder;
    begin
        if TempInstructionQltyDispositionBuffer."New Lot No." <> '' then
            TextBuilder.Append(StrSubstNo(LotMsg, TempInstructionQltyDispositionBuffer."New Lot No."));
        if TempInstructionQltyDispositionBuffer."New Serial No." <> '' then
            TextBuilder.Append(StrSubstNo(SerialMsg, TempInstructionQltyDispositionBuffer."New Serial No."));
        if TempInstructionQltyDispositionBuffer."New Package No." <> '' then
            TextBuilder.Append(StrSubstNo(PackageMsg, TempInstructionQltyDispositionBuffer."New Package No."));
        if TempInstructionQltyDispositionBuffer."New Expiration Date" <> 0D then
            TextBuilder.Append(StrSubstNo(ExpDateMsg, Format(TempInstructionQltyDispositionBuffer."New Expiration Date")));

        exit(TextBuilder.ToText());
    end;

    /// <summary>
    /// Use this to supplment, extend, or replace base action handling.
    /// </summary>
    /// <param name="NotificationToShow"></param>
    /// <param name="CurrentMessage"></param>
    /// <param name="Options"></param>
    /// <param name="Handled"></param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateActionNotification(var NotificationToShow: Notification; var CurrentMessage: Text; var AvailableOptions: Dictionary of [Text, Text]; var Handled: Boolean)
    begin
    end;
}
