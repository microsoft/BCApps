// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.Projects.Resources.Resource;

codeunit 46936 "BC14 Resource Migrator" implements "BC14 Migrator"
{
    TableNo = "BC14 Resource";

    trigger OnRun()
    begin
        MigrateResource(Rec);
    end;

    var
        MigratorNameLbl: Label 'Resource Migrator';

    procedure GetDisplayName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure RegisterReplicationMappings(CompanyName: Text)
    var
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        BC14MigrationSetup.InsertPerCompanyMapping(CompanyName, Database::Resource, Database::"BC14 Resource");
    end;

    procedure IsEnabled(): Boolean
    var
        BC14Resource: Record "BC14 Resource";
    begin
        exit(not BC14Resource.IsEmpty());
    end;

    procedure Migrate(): Boolean
    var
        BC14Resource: Record "BC14 Resource";
        MigrationLoop: Codeunit "BC14 Migration Loop";
        SourceVariant: Variant;
    begin
        SourceVariant := BC14Resource;
        exit(MigrationLoop.RunRecordLoop(
            MigratorNameLbl, SourceVariant, 0,
            Codeunit::"BC14 Resource Migrator"));
    end;

    procedure GetRemainingPercentage(): Integer
    var
        BC14Resource: Record "BC14 Resource";
        Resource: Record Resource;
        TotalCount: Integer;
    begin
        TotalCount := BC14Resource.Count();
        if TotalCount = 0 then
            exit(0);
        exit(Round((TotalCount - Resource.Count()) / TotalCount * 100, 1));
    end;

    internal procedure MigrateResource(BC14Resource: Record "BC14 Resource")
    var
        Resource: Record Resource;
        IsNew: Boolean;
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnMigrateResource(BC14Resource, IsMigrated);
        if IsMigrated then
            exit;

        IsNew := not Resource.Get(BC14Resource."No.");
        if IsNew then begin
            Resource.Init();
            Resource."No." := BC14Resource."No.";
            Resource.Insert(true);
        end;

        // Validate Base Unit of Measure -- triggers Resource Unit of Measure auto-creation,
        // which requires the Resource record to already exist (mirrors the Item migrator pattern).
        if BC14Resource."Base Unit of Measure" <> '' then
            Resource.Validate("Base Unit of Measure", BC14Resource."Base Unit of Measure");

        Resource.Type := Enum::"Resource Type".FromInteger(BC14Resource.Type);
        Resource.Name := BC14Resource.Name;
        Resource."Name 2" := BC14Resource."Name 2";
        Resource."Search Name" := BC14Resource."Search Name";
        Resource."Resource Group No." := BC14Resource."Resource Group No.";
        Resource."Direct Unit Cost" := BC14Resource."Direct Unit Cost";
        Resource."Indirect Cost %" := BC14Resource."Indirect Cost %";
        Resource."Unit Cost" := BC14Resource."Unit Cost";
        Resource."Unit Price" := BC14Resource."Unit Price";
        Resource."Gen. Prod. Posting Group" := BC14Resource."Gen. Prod. Posting Group";
        Resource."VAT Prod. Posting Group" := BC14Resource."VAT Prod. Posting Group";
        Resource.Blocked := BC14Resource.Blocked;
        Resource."Privacy Blocked" := BC14Resource."Privacy Blocked";
        Resource."Last Date Modified" := BC14Resource."Last Date Modified";

        OnTransferResourceCustomFields(BC14Resource, Resource);

        Resource.Modify(true);

        OnAfterMigrateResource(BC14Resource, Resource);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigrateResource(BC14Resource: Record "BC14 Resource"; var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigrateResource(BC14Resource: Record "BC14 Resource"; var Resource: Record Resource)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferResourceCustomFields(BC14Resource: Record "BC14 Resource"; var Resource: Record Resource)
    begin
    end;
}
