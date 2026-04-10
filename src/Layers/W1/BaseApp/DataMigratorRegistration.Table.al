// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Integration;

table 1800 "Data Migrator Registration"
{
    Caption = 'Data Migrator Registration';
    DrillDownPageID = "Data Migrators";
    LookupPageID = "Data Migrators";
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Integer)
        {
            Caption = 'No.';
        }
        field(2; Description; Text[250])
        {
            Caption = 'Description';
            NotBlank = true;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure RegisterDataMigrator(DataMigratorNo: Integer; DataMigratorDescription: Text[250]): Boolean
    begin
        Init();
        "No." := DataMigratorNo;
        Description := DataMigratorDescription;
        exit(Insert());
    end;

    [IntegrationEvent(true, false)]
    [Scope('OnPrem')]
    procedure OnRegisterDataMigrator()
    begin
        // Event which makes all data migrators register themselves in this table.
    end;

    [IntegrationEvent(true, false)]
    [Scope('OnPrem')]
    procedure OnHasSettings(var HasSettings: Boolean)
    begin
        // Event which tells whether the data migrator has a settings page.
    end;

    [IntegrationEvent(true, false)]
    [Scope('OnPrem')]
    procedure OnOpenSettings(var Handled: Boolean)
    begin
        // Event which opens the settings page for the data migrator.
    end;

    [IntegrationEvent(true, false)]
    [Scope('OnPrem')]
    procedure OnValidateSettings()
    begin
        // Event which validates the settings.
    end;

    [IntegrationEvent(true, false)]
    [Scope('OnPrem')]
    procedure OnGetInstructions(var Instructions: Text; var Handled: Boolean)
    begin
        // Event which makes all registered data migrators publish their instructions.
    end;

    [IntegrationEvent(true, false)]
    [Scope('OnPrem')]
    procedure OnHasTemplate(var HasTemplate: Boolean)
    begin
        // Event which tells whether the data migrator has a template available for download.
    end;

    [IntegrationEvent(true, false)]
    [Scope('OnPrem')]
    procedure OnDownloadTemplate(var Handled: Boolean)
    begin
        // Event which invokes the download of the template.
    end;

    [IntegrationEvent(true, false)]
    [Scope('OnPrem')]
    procedure OnDataImport(var Handled: Boolean)
    begin
        // Event which makes all registered data migrators import data.
    end;

    [IntegrationEvent(true, false)]
    [Scope('OnPrem')]
    procedure OnSelectDataToApply(var DataMigrationEntity: Record "Data Migration Entity"; var Handled: Boolean)
    begin
        // Event which makes all registered data migrators populate the Data Migration Entities table, which allows the user to choose which imported data should be applied.
    end;

    [IntegrationEvent(true, false)]
    [Scope('OnPrem')]
    procedure OnHasAdvancedApply(var HasAdvancedApply: Boolean)
    begin
        // Event which tells whether the data migrator has an advanced apply page.
    end;

    [IntegrationEvent(true, false)]
    [Scope('OnPrem')]
    procedure OnOpenAdvancedApply(var DataMigrationEntity: Record "Data Migration Entity"; var Handled: Boolean)
    begin
        // Event which opens the advanced apply page for the data migrator.
    end;

    [IntegrationEvent(true, false)]
    [Scope('OnPrem')]
    procedure OnApplySelectedData(var DataMigrationEntity: Record "Data Migration Entity"; var Handled: Boolean)
    begin
        // Event which makes all registered data migrators apply the data, which is selected in the Data Migration Entities table.
    end;

    [IntegrationEvent(true, false)]
    [Scope('OnPrem')]
    procedure OnPostingGroupSetup(var PostingSetup: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    [Scope('OnPrem')]
    procedure OnGLPostingSetup(ListOfAccounts: array[11] of Code[20])
    begin
    end;

    [IntegrationEvent(true, false)]
    [Scope('OnPrem')]
    procedure OnCustomerVendorPostingSetup(ListOfAccounts: array[4] of Code[20])
    begin
    end;

    [IntegrationEvent(true, false)]
    [Scope('OnPrem')]
    procedure OnHasErrors(var HasErrors: Boolean)
    begin
        // Event which tells whether the data migrator had import errors
    end;

    [IntegrationEvent(true, false)]
    [Scope('OnPrem')]
    procedure OnShowErrors(var Handled: Boolean)
    begin
        // Event which opens the error handling page for the data migrator.
    end;

    [IntegrationEvent(true, false)]
    [Scope('OnPrem')]
    procedure OnShowDuplicateContactsText(var ShowDuplicateContactText: Boolean)
    begin
        // Event which shows or hides message on the last page of the wizard to run Duplicate Contact Tool or not.
    end;

    [IntegrationEvent(true, false)]
    [Scope('OnPrem')]
    procedure OnShowPostingOptions(var ShowPostingOptions: Boolean)
    begin
        // Event which shows or hides posting options (post yes/no and date) on the entity seleciton page-
    end;

    [IntegrationEvent(true, false)]
    [Scope('OnPrem')]
    procedure OnShowBalance(var ShowBalance: Boolean)
    begin
        // Event which shows or hides balance columns in the entity selection page.
    end;

    [IntegrationEvent(true, false)]
    [Scope('OnPrem')]
    procedure OnShowThatsItMessage(var Message: Text)
    begin
        // Event which shows specific data migrator text at the last page
    end;

    [IntegrationEvent(true, false)]
    [Scope('OnPrem')]
    procedure OnEnableTogglingDataMigrationOverviewPage(var EnableTogglingOverviewPage: Boolean)
    begin
        // Event which determines if the option to launch the overview page will be shown to the user at the end.
    end;

    [IntegrationEvent(true, false)]
    [Scope('OnPrem')]
    procedure OnHideSelected(var HideSelectedCheckBoxes: Boolean)
    begin
        // Event which shows or hides selected checkboxes in the entity selection page.
    end;
}

