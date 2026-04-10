namespace System.Integration;

page 1797 "Data Migration Error"
{
    Caption = 'Data Migration Errors';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Data Migration Error";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Error Message"; Rec."Error Message")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the error message that relates to the data migration.';

                    trigger OnDrillDown()
                    begin
                        if StagingTableRecIdSpecified then
                            EditRecord();
                    end;
                }
                field(LastRecordUnderProcessing; Rec."Last Record Under Processing")
                {
                    Caption = 'Last Processed Record';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the last record that was processed before the error occurred.';
                }
                field(StackTrace; StackTraceTxt)
                {
                    Caption = 'Error Stack Trace';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the stack trace that relates to the error.';
                    trigger OnDrillDown()
                    begin
                        Message(StackTraceTxt);
                    end;
                }
                field(ErrorDismissed; Rec."Error Dismissed")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the error has been dismissed.';
                }
            }
        }
    }

    actions
    {
        area(Creation)
        {
            action(SkipSelection)
            {
                ApplicationArea = All;
                Caption = 'Skip Selections';
                Enabled = StagingTableRecIdSpecified;
                Image = Delete;
                ToolTip = 'Exclude the selected errors from the migration.';

                trigger OnAction()
                var
                    DataMigrationError: Record "Data Migration Error";
                begin
                    CheckAtLeastOneSelected();
                    if not Confirm(SkipSelectionConfirmQst, false) then
                        exit;
                    CurrPage.SetSelectionFilter(DataMigrationError);
                    DataMigrationError.FindSet();
                    repeat
                        DataMigrationError.Ignore();
                    until DataMigrationError.Next() = 0;
                    CurrPage.Update(false);
                end;
            }
            action(Edit)
            {
                ApplicationArea = All;
                Caption = 'Edit Record';
                Enabled = StagingTableRecIdSpecified;
                Image = Edit;
                ToolTip = 'Edit the record that caused the error.';

                trigger OnAction()
                begin
                    EditRecord();
                end;
            }
            action(Migrate)
            {
                ApplicationArea = All;
                Caption = 'Migrate';
                Enabled = StagingTableRecIdSpecified;
                Image = Refresh;
                ToolTip = 'Migrate the selected errors.';

                trigger OnAction()
                var
                    DataMigrationError: Record "Data Migration Error";
                begin
                    CheckAtLeastOneSelected();
                    CurrPage.SetSelectionFilter(DataMigrationError);
                    StartMigration(DataMigrationError);
                end;
            }
            action(BulkFixErrors)
            {
                ApplicationArea = All;
                Caption = 'Bulk-Fix Errors';
                Enabled = BulkFixErrorsButtonEnabled;
                Image = List;
                ToolTip = 'Open a list of all entities that contained an error. You can fix some or all of the errors and migrate the updated data.';

                trigger OnAction()
                var
                    DataMigrationFacade: Codeunit "Data Migration Facade";
                    DataMigrationOverview: Page "Data Migration Overview";
                begin
                    DataMigrationFacade.OnBatchEditFromErrorView(Rec."Migration Type", Rec."Destination Table ID");

                    if not Confirm(StrSubstNo(MigrateEntitiesAgainQst, DataMigrationOverview.Caption), true) then
                        exit;

                    StartMigration(Rec);
                end;
            }
            action(DismissError)
            {
                ApplicationArea = All;
                Caption = 'Dismiss Error';
                Enabled = StagingTableRecIdSpecified;
                Image = Delete;
                ToolTip = 'Mark the error as fixed.';

                trigger OnAction()
                begin
                    Rec."Error Dismissed" := true;
                    Rec.Modify();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(SkipSelection_Promoted; SkipSelection)
                {
                }
                actionref(Edit_Promoted; Edit)
                {
                }
                actionref(Migrate_Promoted; Migrate)
                {
                }
                actionref(BulkFixErrors_Promoted; BulkFixErrors)
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        DataMigrationFacade: Codeunit "Data Migration Facade";
        StagingTableRecId: RecordID;
        DummyRecordId: RecordID;
    begin
        StagingTableRecId := Rec."Source Staging Table Record ID";
        StagingTableRecIdSpecified := StagingTableRecId <> DummyRecordId;

        DataMigrationFacade.OnInitDataMigrationError(Rec."Migration Type", BulkFixErrorsButtonEnabled);
        StackTraceTxt := Rec.GetFullExceptionMessage();
    end;

    trigger OnAfterGetRecord()
    begin
        StackTraceTxt := Rec.GetFullExceptionMessage();
    end;

    trigger OnOpenPage()
    var
        Notification: Notification;
    begin
        Notification.Message := SkipEditNotificationMsg;
        Notification.Send();
    end;

    var
        MultipleRecordsSelectedErr: Label 'You can view the content of one record at a time.';
        MigrationStartedMsg: Label 'The selected records are scheduled for data migration. To check the status of the migration, go to the %1 page.', Comment = '%1 = Caption for the page Data Migration Overview';
        NoSelectionsMadeErr: Label 'No records have been selected.';
        StagingTableRecIdSpecified: Boolean;
        SkipSelectionConfirmQst: Label 'The selected errors will be deleted and the corresponding entities will not be migrated. Do you want to continue?';
        ExtensionNotInstalledErr: Label 'Sorry, but it looks like someone uninstalled the data migration extension you are trying to use. When that happens, we remove all data that was not fully migrated.';
        SkipEditNotificationMsg: Label 'Skip errors, or edit the entity to fix them, and then migrate again.';
        MigrateEntitiesAgainQst: Label 'Do you want to migrate the updated entities?\\If you do, remember to refresh the %1 page so you can follow the progress.', Comment = '%1 = caption of the Data Migration Overview page';
        BulkFixErrorsButtonEnabled: Boolean;
        StackTraceTxt: Text;

    local procedure CheckAtLeastOneSelected()
    var
        DataMigrationError: Record "Data Migration Error";
    begin
        CurrPage.SetSelectionFilter(DataMigrationError);
        if DataMigrationError.Count = 0 then
            Error(NoSelectionsMadeErr);
    end;

    local procedure EditRecord()
    var
        DataMigrationError: Record "Data Migration Error";
        DataMigrationStatus: Record "Data Migration Status";
        RecordRef: RecordRef;
    begin
        CheckAtLeastOneSelected();
        CurrPage.SetSelectionFilter(DataMigrationError);
        if DataMigrationError.Count > 1 then
            Error(MultipleRecordsSelectedErr);

        DataMigrationError.FindFirst();
        DataMigrationStatus.SetRange("Migration Type", DataMigrationError."Migration Type");
        DataMigrationStatus.SetRange("Destination Table ID", DataMigrationError."Destination Table ID");
        DataMigrationStatus.FindFirst();

        if not RecordRef.Get(DataMigrationError."Source Staging Table Record ID") then
            Error(ExtensionNotInstalledErr);

        OpenStagingTablePage(DataMigrationStatus."Source Staging Table ID", RecordRef);
    end;

    local procedure OpenStagingTablePage(PageId: Integer; StagingTableRecord: Variant)
    begin
        PAGE.RunModal(PageId, StagingTableRecord);
    end;

    local procedure StartMigration(var DataMigrationError: Record "Data Migration Error")
    var
        DataMigrationFacade: Codeunit "Data Migration Facade";
        DataMigrationOverview: Page "Data Migration Overview";
    begin
        DataMigrationError.ModifyAll("Scheduled For Retry", true, true);

        DataMigrationFacade.StartMigration(Rec."Migration Type", true);

        Message(MigrationStartedMsg, DataMigrationOverview.Caption);
        CurrPage.Close();
    end;
}

