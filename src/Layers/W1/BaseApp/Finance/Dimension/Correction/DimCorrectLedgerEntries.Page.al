// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension.Correction;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Ledger;
using System.Automation;
using System.Security.User;
using System.Utilities;

page 2583 "Dim. Correct Ledger Entries"
{
    PageType = ListPart;
    SourceTable = "G/L Entry";
    SourceTableTemporary = true;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';

                    trigger OnDrillDown()
                    var
                        GLEntry: Record "G/L Entry";
                    begin
                        if GLEntry.Get(Rec."Entry No.") then
                            Page.Run(0, GLEntry);
                    end;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the Document Type that the entry belongs to.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the entry''s Document No.';
                }
                field("G/L Account No."; Rec."G/L Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the account that the entry has been posted to.';
                }
                field("G/L Account Name"; Rec."G/L Account Name")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    Editable = false;
                    ToolTip = 'Specifies the name of the account that the entry has been posted to.';
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the entry.';
                }
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = Jobs;
                    Editable = false;
                    ToolTip = 'Specifies the number of the related project.';
                    Visible = false;
                }
                field("Global Dimension 1 Code"; Rec."Global Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = false;
                }
                field("Global Dimension 2 Code"; Rec."Global Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = false;
                }
                field("IC Partner Code"; Rec."IC Partner Code")
                {
                    ApplicationArea = Intercompany;
                    Editable = false;
                    ToolTip = 'Specifies the code of the intercompany partner that the transaction is related to if the entry was created from an intercompany transaction.';
                    Visible = false;
                }
                field("Gen. Posting Type"; Rec."Gen. Posting Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the type of transaction.';
                }
                field("Gen. Bus. Posting Group"; Rec."Gen. Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the vendor''s or customer''s trade type to link transactions made for this business partner with the appropriate ledger account according to the general posting setup.';
                }
                field("Gen. Prod. Posting Group"; Rec."Gen. Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the item''s product type to link transactions made for this item with the appropriate ledger account according to the general posting setup.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the quantity that was posted on the entry.';
                    Visible = false;
                }
                field("Additional-Currency Amount"; Rec."Additional-Currency Amount")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies the general ledger entry that is posted if you post in an additional reporting currency.';
                    Visible = false;
                }
                field("VAT Amount"; Rec."VAT Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount of VAT that is included in the total amount.';
                    Visible = false;
                }
                field("Bal. Account Type"; Rec."Bal. Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the type of account that a balancing entry is posted to, such as BANK for a cash account.';
                }
                field("Bal. Account No."; Rec."Bal. Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the ledger, customer, vendor, or bank account that the balancing entry is posted to, such as a cash account for cash purchases.';
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation(Rec."User ID");
                    end;
                }
                field("Source Code"; Rec."Source Code")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies the source code that specifies where the entry was created.';
                    Visible = false;
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies the reason code, a supplementary source code that enables you to trace the entry.';
                    Visible = false;
                }
                field(Reversed; Rec.Reversed)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies if the entry has been part of a reverse transaction (correction) made by the Reverse function.';
                    Visible = false;
                }
                field("Reversed by Entry No."; Rec."Reversed by Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the correcting entry. If the field Specifies a number, the entry cannot be reversed again.';
                    Visible = false;
                }
                field("Reversed Entry No."; Rec."Reversed Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the original entry that was undone by the reverse transaction.';
                    Visible = false;
                }
                field("FA Entry Type"; Rec."FA Entry Type")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    ToolTip = 'Specifies the number of the fixed asset entry.';
                    Visible = false;
                }
                field("FA Entry No."; Rec."FA Entry No.")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    ToolTip = 'Specifies the number of the fixed asset entry.';
                    Visible = false;
                }
                field("Dimension Set ID"; Rec."Dimension Set ID")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies a reference to a combination of dimension values. The actual values are stored in the Dimension Set Entry table.';
                    Visible = false;
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the entry''s external document number, such as a vendor''s invoice number.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(AddByTransaction)
            {
                ApplicationArea = All;
                Caption = 'Add Related Entries';
                Image = AddAction;
                ToolTip = 'Find and add all entries that are related to the selected entry.';

                trigger OnAction()
                var
                    GLEntry: Record "G/L Entry";
                    DimCorrectSelectionCriteria: Record "Dim Correct Selection Criteria";
                    GLEntryRecordRef: RecordRef;
                begin
                    VerifyCanChangePart();
                    if Rec."Transaction No." = 0 then
                        Error(NoRelatedEntriesErr);

                    GLEntry.SetRange("Transaction No.", Rec."Transaction No.");

                    if not (GLEntry.Count() > 1) then
                        Error(NoRelatedEntriesErr);

                    GLEntryRecordRef.GetTable(GLEntry);
                    DimensionCorrectionMgt.InsertNewDimCorrectSelectionCriteria(GLEntryRecordRef, DimCorrectSelectionCriteria."Filter Type"::"Related Entries", DimCorrectSelectionCriteria, DimensionCorrectionEntryNo);
                    DimensionCorrectionMgt.ReloadDimensionChangesTable(DimensionCorrectionEntryNo);
                    Commit();

                    LoadRecordsForSelection(DimCorrectSelectionCriteria);

                    CurrPage.Update(false);
                end;
            }

            action(AddByFilter)
            {
                ApplicationArea = All;
                Caption = 'Add by Filter';
                Image = FilterLines;
                ToolTip = 'Add new entries to the correction by using filters.';

                trigger OnAction()
                var
                    DimCorrectSelectionCriteria: Record "Dim Correct Selection Criteria";
                    DummyGLEntry: Record "G/L Entry";
                    RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
                    TempBlob: Codeunit "Temp Blob";
                    GLEntryRecordRef: RecordRef;
                    RequestFilterPageBuilder: FilterPageBuilder;
                    TempBlobOutStream: OutStream;
                    RequestPageView: Text;
                begin
                    VerifyCanChangePart();
                    RequestPageParametersHelper.BuildDynamicRequestPage(RequestFilterPageBuilder, SelectLedgerEntriesToCorrectLbl, Database::"G/L Entry");

                    if not RequestFilterPageBuilder.RunModal() then
                        exit;

                    RequestPageView := RequestPageParametersHelper.GetViewFromDynamicRequestPage(RequestFilterPageBuilder, SelectLedgerEntriesToCorrectLbl, Database::"G/L Entry");
                    GLEntryRecordRef.Open(Database::"G/L Entry");

                    TempBlob.CreateOutStream(TempBlobOutStream);
                    TempBlobOutStream.WriteText(RequestPageView);
                    RequestPageParametersHelper.ConvertParametersToFilters(GLEntryRecordRef, TempBlob);
                    if GLEntryRecordRef.GetView() = DummyGLEntry.GetView() then
                        Error(ViewWasNotModifiedErr);

                    DimensionCorrectionMgt.InsertNewDimCorrectSelectionCriteria(GLEntryRecordRef, DimCorrectSelectionCriteria."Filter Type"::"Custom Filter", DimCorrectSelectionCriteria, DimensionCorrectionEntryNo);
                    DimensionCorrectionMgt.ReloadDimensionChangesTable(DimensionCorrectionEntryNo);
                    Commit();

                    LoadRecordsForSelection(DimCorrectSelectionCriteria);
                    CurrPage.Update(false);
                end;
            }

            action(SelectManually)
            {
                ApplicationArea = All;
                Caption = 'Select Manually';
                Image = PickLines;
                ToolTip = 'Select entries to correct manually.';

                trigger OnAction()
                var
                    GLEntry: Record "G/L Entry";
                    DimCorrectSelectionCriteria: Record "Dim Correct Selection Criteria";
                    GeneralLedgerEntries: Page "General Ledger Entries";
                    GLEntryRecordRef: RecordRef;
                begin
                    VerifyCanChangePart();
                    GeneralLedgerEntries.LookupMode(true);
                    if GeneralLedgerEntries.RunModal() = Action::LookupOK then begin
                        GeneralLedgerEntries.SetSelectionFilter(GLEntry);
                        GLEntry.SetLoadFields("Entry No.");
                        GLEntry.SetCurrentKey("Entry No.");
                        GLEntry.Ascending(true);
                        GLEntry.FindFirst();

                        if GLEntry.Count() > 1000 then
                            Error(TooManyGLEntriesSelectedErr);

                        DimensionCorrectionMgt.TransferSelectionFilterToRecordRef(GLEntry, GLEntryRecordRef);
                        DimensionCorrectionMgt.InsertNewDimCorrectSelectionCriteria(GLEntryRecordRef, DimCorrectSelectionCriteria."Filter Type"::Manual, DimCorrectSelectionCriteria, DimensionCorrectionEntryNo);
                        DimensionCorrectionMgt.ReloadDimensionChangesTable(DimensionCorrectionEntryNo);

                        Commit();
                        LoadRecordsForSelection(DimCorrectSelectionCriteria);
                        CurrPage.Update(false);
                    end;
                end;
            }

            action(AddByDimension)
            {
                ApplicationArea = All;
                Caption = 'Add by Dimension';
                Image = MapDimensions;
                ToolTip = 'Select entries to correct based on dimension values.';

                trigger OnAction()
                var
                    TempDimensionSetEntry: Record "Dimension Set Entry" temporary;
                    DimCorrectSelectionCriteria: Record "Dim Correct Selection Criteria";
                    GLEntry: Record "G/L Entry";
                    FindbyDimension: Page "Dim Corr Find by Dimension";
                    GLEntryRecordRef: RecordRef;
                    DimensionSetIDFieldRef: FieldRef;
                    SelectionFilterText: Text;
                begin
                    VerifyCanChangePart();
                    FindbyDimension.LookupMode(true);
                    if FindbyDimension.RunModal() <> Action::LookupOK then
                        exit;

                    FindbyDimension.GetRecords(TempDimensionSetEntry);
                    GLEntryRecordRef.Open(Database::"G/L Entry");
                    DimensionSetIDFieldRef := GLEntryRecordRef.Field(GLEntry.FieldNo("Dimension Set ID"));
                    SelectionFilterText := DimensionCorrectionMgt.GetSelectedDimensionSetIDsFilter(TempDimensionSetEntry);
                    if SelectionFilterText = '' then
                        exit;
                    DimensionSetIDFieldRef.SetFilter(SelectionFilterText);
                    DimensionCorrectionMgt.InsertNewDimCorrectSelectionCriteria(GLEntryRecordRef, DimCorrectSelectionCriteria."Filter Type"::"By Dimension", DimCorrectSelectionCriteria, DimensionCorrectionEntryNo);
                    DimensionCorrectionMgt.ReloadDimensionChangesTable(DimensionCorrectionEntryNo);

                    Commit();
                    LoadRecordsForSelection(DimCorrectSelectionCriteria);
                    CurrPage.Update(false);
                end;
            }

            action(ExcludeEntries)
            {
                ApplicationArea = All;
                Caption = 'Remove entries';
                Image = RemoveLine;
                ToolTip = 'Exclude selected entries from the dimension correction.';

                trigger OnAction()
                var
                    DimCorrectSelectionCriteria: Record "Dim Correct Selection Criteria";
                    TempGLEntry: Record "G/L Entry" temporary;
                    GLEntryRecordRef: RecordRef;
                begin
                    VerifyCanChangePart();
                    TempGLEntry.Copy(Rec);
                    CurrPage.SetSelectionFilter(Rec);
                    if Rec.Count() > 5000 then
                        Error(TooManyExcludedEntriesErr);
                    DimensionCorrectionMgt.TransferSelectionFilterToRecordRef(Rec, GLEntryRecordRef);
                    DimensionCorrectionMgt.InsertNewDimCorrectSelectionCriteria(GLEntryRecordRef, DimCorrectSelectionCriteria."Filter Type"::Excluded, DimCorrectSelectionCriteria, DimensionCorrectionEntryNo);
                    DimensionCorrectionMgt.ReloadDimensionChangesTable(DimensionCorrectionEntryNo);
                    Commit();

                    Rec.DeleteAll();
                    Rec.Copy(TempGLEntry);
                    CurrPage.Update(false);
                end;
            }

            action(ManageSelectionCriteria)
            {
                ApplicationArea = All;
                Caption = 'Manage Selection Criteria';
                Image = History;
                ToolTip = 'See criteria that was used to select the entries for correction. This page will allow you to undo some steps.';

                trigger OnAction()
                var
                    DimCorrectSelectionCriteria: Record "Dim Correct Selection Criteria";
                    DimCorrectSelectionCriteriaPage: Page "Dim Correct Selection Criteria";
                    DeletedEntries: List of [Guid];
                    DeletedEntrySystemId: Guid;
                begin
                    VerifyCanChangePart();
                    DimCorrectSelectionCriteria.SetRange("Dimension Correction Entry No.", DimensionCorrectionEntryNo);
                    DimCorrectSelectionCriteriaPage.SetTableView(DimCorrectSelectionCriteria);
                    DimCorrectSelectionCriteriaPage.RunModal();

                    DimCorrectSelectionCriteriaPage.GetEntriesToDelete(DeletedEntries);
                    if DeletedEntries.Count() = 0 then
                        exit;

                    foreach DeletedEntrySystemId in DeletedEntries do
                        if DimCorrectSelectionCriteria.GetBySystemId(DeletedEntrySystemId) then
                            DimCorrectSelectionCriteria.Delete();

                    DimensionCorrectionMgt.ReloadDimensionChangesTable(DimensionCorrectionEntryNo);
                    Commit();

                    DeselectAll();
                    LoadRecords();
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    begin
        if DimensionCorrectionEntryNo <= 0 then
            exit(false);

        if PreviewDisabled then begin
            if Which = '+' then
                SendFindLastNotSupportedNotification();

            // If filters have chaned load everythig again
            if PreviousView <> Rec.GetView() then
                RecordsLoaded := false;
        end;

        if not RecordsLoaded then begin
            LoadRecords();
            RecordsLoaded := true;
            if Rec.FindFirst() then;
        end;

        if PreviewDisabled then
            PreviousView := Rec.GetView();

        exit(Rec.Find(Which));
    end;

    local procedure LoadRecords(): Boolean
    var
        OriginalView: Text;
    begin
        Rec.DeleteAll();
        UpdateRecordCount(0);
        OriginalView := Rec.GetView();
        LoadPage();

        Rec.SetView(OriginalView);
    end;

    local procedure SendFindLastNotSupportedNotification()
    var
        FindLastNotSupportedOnLargeReconciliationNotification: Notification;
    begin
        FindLastNotSupportedOnLargeReconciliationNotification.Id := GetFindLastNotificationIsNotSupported();
        if FindLastNotSupportedOnLargeReconciliationNotification.Recall() then;

        FindLastNotSupportedOnLargeReconciliationNotification.Message := FindLastNotSupportedTooManyEntriesLbl;
        FindLastNotSupportedOnLargeReconciliationNotification.Scope := NotificationScope::LocalScope;
        FindLastNotSupportedOnLargeReconciliationNotification.Send();
    end;

    local procedure LoadPage()
    var
        DimCorrectSelectionCriteria: Record "Dim Correct Selection Criteria";
        ExcludedEntriesDimCorrectSelectionCriteria: Record "Dim Correct Selection Criteria";
        ExcluedEntriesExist: Boolean;
    begin
        DimCorrectSelectionCriteria.SetRange("Dimension Correction Entry No.", DimensionCorrectionEntryNo);
        DimCorrectSelectionCriteria.SetFilter("Filter Type", '<>%1', DimCorrectSelectionCriteria."Filter Type"::Excluded);
        if not DimCorrectSelectionCriteria.FindSet() then
            exit;

        ExcludedEntriesDimCorrectSelectionCriteria.SetRange("Dimension Correction Entry No.", DimensionCorrectionEntryNo);
        ExcludedEntriesDimCorrectSelectionCriteria.SetRange("Filter Type", DimCorrectSelectionCriteria."Filter Type"::Excluded);
        ExcluedEntriesExist := not ExcludedEntriesDimCorrectSelectionCriteria.IsEmpty();

        repeat
            LoadRecordsForSelection(DimCorrectSelectionCriteria, ExcludedEntriesDimCorrectSelectionCriteria, ExcluedEntriesExist);
        until DimCorrectSelectionCriteria.Next() = 0;
    end;

    local procedure DeselectAll()
    begin
        Rec.Reset();
        Rec.DeleteALl();
        PreviewDisabled := false;
        Clear(Rec);
        Clear(RecordCount);
        Clear(RecordsLoaded);
        Clear(PreviousView);
    end;

    local procedure LoadRecordsForSelection(var DimCorrectSelectionCriteria: Record "Dim Correct Selection Criteria")
    var
        ExcludedEntriesDimCorrectSelectionCriteria: Record "Dim Correct Selection Criteria";
        ExcluedEntriesExist: Boolean;
    begin
        if RecordCount > DimensionCorrectionMgt.GetPreviewGLEntriesLimit() then
            exit;

        ExcludedEntriesDimCorrectSelectionCriteria.SetRange("Filter Type", DimCorrectSelectionCriteria."Filter Type"::Excluded);
        ExcluedEntriesExist := not ExcludedEntriesDimCorrectSelectionCriteria.IsEmpty();
        LoadRecordsForSelection(DimCorrectSelectionCriteria, ExcludedEntriesDimCorrectSelectionCriteria, ExcluedEntriesExist);
        if Rec.FindFirst() then;
    end;

    local procedure LoadRecordsForSelection(var DimCorrectSelectionCriteria: Record "Dim Correct Selection Criteria"; var ExcludedEntriesDimCorrectSelectionCriteria: Record "Dim Correct Selection Criteria"; ExcluedEntriesExist: Boolean)
    var
        GLEntry: Record "G/L Entry";
        InsertEntry: Boolean;
        SelectionFilter: Text;
    begin
        if RecordCount > DimensionCorrectionMgt.GetPreviewGLEntriesLimit() then
            exit;

        DimCorrectSelectionCriteria.GetSelectionFilter(SelectionFilter);
        GLEntry.FilterGroup(4);
        GLEntry.SetView(Rec.GetView());
        GLEntry.FilterGroup(0);
        GLEntry.SetView(SelectionFilter);
        if GLEntry.FindSet() then
            repeat
                InsertEntry := not ExcluedEntriesExist;

                if not InsertEntry then
                    InsertEntry := not DimensionCorrectionMgt.IsEntryExclued(GLEntry, ExcludedEntriesDimCorrectSelectionCriteria);

                if InsertEntry then
                    InsertEntry := not Rec.GET(GLEntry."Entry No.");

                if InsertEntry then begin
                    Rec.TransferFields(GLEntry, true);
                    Rec.Insert();
                    UpdateRecordCount(RecordCount + 1);

                    if RecordCount > DimensionCorrectionMgt.GetPreviewGLEntriesLimit() then begin
                        PreviewDisabled := true;
                        Session.LogMessage('0000EHL', StrSubstNo(LargeCorrectionTelemetryLbl, DimensionCorrectionEntryNo), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DimensionCorrectionTok);
                        exit;
                    end;
                end;
            until GLEntry.Next() = 0;
    end;

    procedure SetDimensionCorrectionEntryNo(NewDimensionCorrectionEntryNo: Integer)
    begin
        if NewDimensionCorrectionEntryNo <> DimensionCorrectionEntryNo then begin
            DimensionCorrectionEntryNo := NewDimensionCorrectionEntryNo;
            DeselectAll();
        end;
    end;

    local procedure UpdateRecordCount(NewRecordCount: Integer)
    begin
        RecordCount := NewRecordCount;

        if not PreviewDisabled then
            PreviewDisabled := RecordCount > DimensionCorrectionMgt.GetPreviewGLEntriesLimit();
    end;

    local procedure GetFindLastNotificationIsNotSupported(): Guid
    begin
        exit('b00322cc-7367-42ef-b0cc-708f1a347f48');
    end;

    local procedure VerifyCanChangePart()
    begin
        DimensionCorrectionMgt.VerifyCanModifyDraftEntry(DimensionCorrectionEntryNo);
    end;

    var
        DimensionCorrectionMgt: Codeunit "Dimension Correction Mgt";
        DimensionCorrectionEntryNo: Integer;
        RecordCount: Integer;
        RecordsLoaded: Boolean;
        PreviewDisabled: Boolean;
        PreviousView: Text;
        SelectLedgerEntriesToCorrectLbl: Label 'Ledger Entries';
        NoRelatedEntriesErr: Label 'No entries are related to the selected ledger entry.';
        FindLastNotSupportedTooManyEntriesLbl: Label 'There are more entries than the list can show. Filter the list to find fewer entries.';
        LargeCorrectionTelemetryLbl: Label 'Large dimension correction created. Dimension Correction Entry No. %1.', Locked = true, Comment = '%1 Dimension Correction Entry No.';
        DimensionCorrectionTok: Label 'DimensionCorrection';
        TooManyGLEntriesSelectedErr: Label 'You have selected too many G/L entries. Use filters to reduce the number of entries.';
        ViewWasNotModifiedErr: Label 'You have not entered any selection criteria.';
        TooManyExcludedEntriesErr: Label 'You have excluded too many entries. Consider updating the filter or other selection criteria.';
}
