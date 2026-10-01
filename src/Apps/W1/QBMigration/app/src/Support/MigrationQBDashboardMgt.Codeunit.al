#pragma warning disable AA0247
codeunit 1915 "MigrationQB Dashboard Mgt"
{
    var
        HelperFunctions: Codeunit "MigrationQB Helper Functions";
        CloudMigrationTok: Label 'CloudMigration', Locked = true;
        QBOTok: Label 'QuickBooks Online', Locked = true;
        MigrationFinishedTelemetryTok: Label 'QuickBooks migration finished.', Locked = true;

    procedure InitMigrationStatus(TotalItemNb: Integer; TotalCustomerNb: Integer; TotalVendorNb: Integer; TotalChartOfAccountNb: Integer);
    var
        DataMigrationStatusFacade: Codeunit "Data Migration Status Facade";
    begin
        DataMigrationStatusFacade.InitStatusLine(CopyStr(HelperFunctions.GetMigrationTypeTxt(), 1, 10), Database::Item, TotalItemNb, Database::"MigrationQB Item", Codeunit::"MigrationQB Item Migrator");
        DataMigrationStatusFacade.InitStatusLine(CopyStr(HelperFunctions.GetMigrationTypeTxt(), 1, 10), Database::Customer, TotalCustomerNb, Database::"MigrationQB Customer", Codeunit::"MigrationQB Customer Migrator");
        DataMigrationStatusFacade.InitStatusLine(CopyStr(HelperFunctions.GetMigrationTypeTxt(), 1, 10), Database::Vendor, TotalVendorNb, Database::"MigrationQB Vendor", Codeunit::"MigrationQB Vendor Migrator");
        DataMigrationStatusFacade.InitStatusLine(CopyStr(HelperFunctions.GetMigrationTypeTxt(), 1, 10), Database::"G/L Account", TotalChartOfAccountNb, Database::"MigrationQB Account", Codeunit::"MigrationQB Account Migrator");
    end;

    internal procedure SendMigrationFinishedTelemetry(WasAborted: Boolean; Retry: Boolean; MigrationDateTime: DateTime)
    var
        TelemetryDimensions: Dictionary of [Text, Text];
    begin
        if WasAborted or Retry then begin
            TelemetryDimensions.Add('Category', CloudMigrationTok);
            TelemetryDimensions.Add('Product', QBOTok);
            TelemetryDimensions.Add('WasAborted', Format(WasAborted, 0, 9));
            TelemetryDimensions.Add('Retry', Format(Retry, 0, 9));
            Session.LogMessage('0000NQS', MigrationFinishedTelemetryTok, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, TelemetryDimensions);
            exit;
        end;

        SendCompletedMigrationTelemetry(MigrationDateTime);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Data Migration Facade", 'OnMigrationCompleted', '', false, false)]
    local procedure OnAllStepsCompletedSubscriber(DataMigrationStatus: Record "Data Migration Status")
    begin
        if not (DataMigrationStatus."Migration Type" = HelperFunctions.GetMigrationTypeTxt()) then
            exit;

        HelperFunctions.CleanupStagingTables();
        HelperFunctions.CleanupIsolatedStorage();
    end;

    internal procedure GetCompletedMigrationDateTime(var MigrationDateTime: DateTime): Boolean
    var
        DataMigrationStatus: Record "Data Migration Status";
    begin
        DataMigrationStatus.SetRange("Migration Type", HelperFunctions.GetMigrationTypeTxt());
        DataMigrationStatus.SetRange(Status, DataMigrationStatus.Status::Completed);
        DataMigrationStatus.SetCurrentKey("Migration Type", Status, SystemModifiedAt);
        if not DataMigrationStatus.FindLast() then
            exit(false);

        MigrationDateTime := DataMigrationStatus.SystemModifiedAt;
        exit(true);
    end;

    internal procedure SendCompletedMigrationTelemetry(MigrationDateTime: DateTime)
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        TelemetryDimensions: Dictionary of [Text, Text];
    begin
        FeatureTelemetry.LogUptake('0000JMS', 'Cloud Migration', Enum::"Feature Uptake Status"::Discovered);
        FeatureTelemetry.LogUptake('0000JMU', 'Cloud Migration', Enum::"Feature Uptake Status"::"Set up");
        FeatureTelemetry.LogUptake('0000JMQ', 'Cloud Migration', Enum::"Feature Uptake Status"::Used);

        TelemetryDimensions.Add('Category', CloudMigrationTok);
        TelemetryDimensions.Add('NumberOfCompanies', Format(1, 0, 9));
        TelemetryDimensions.Add('TotalMigrationSize', Format(0, 0, 9));
        TelemetryDimensions.Add('TotalOnPremSize', Format(0, 0, 9));
        TelemetryDimensions.Add('Product', QBOTok);
        TelemetryDimensions.Add('MigrationDateTime', Format(MigrationDateTime, 0, 9));
        FeatureTelemetry.LogUsage('0000JMR', 'Cloud Migration', 'Tenant was cloud migrated', TelemetryDimensions);
    end;
}
