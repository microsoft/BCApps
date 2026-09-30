#pragma warning disable AA0247
codeunit 1915 "MigrationQB Dashboard Mgt"
{
    var
        HelperFunctions: Codeunit "MigrationQB Helper Functions";
        CloudMigrationLbl: Label 'CloudMigration', Locked = true;
        QBOLbl: Label 'QuickBooks Online', Locked = true;

    procedure InitMigrationStatus(TotalItemNb: Integer; TotalCustomerNb: Integer; TotalVendorNb: Integer; TotalChartOfAccountNb: Integer);
    var
        DataMigrationStatusFacade: Codeunit "Data Migration Status Facade";
    begin
        DataMigrationStatusFacade.InitStatusLine(CopyStr(HelperFunctions.GetMigrationTypeTxt(), 1, 10), Database::Item, TotalItemNb, Database::"MigrationQB Item", Codeunit::"MigrationQB Item Migrator");
        DataMigrationStatusFacade.InitStatusLine(CopyStr(HelperFunctions.GetMigrationTypeTxt(), 1, 10), Database::Customer, TotalCustomerNb, Database::"MigrationQB Customer", Codeunit::"MigrationQB Customer Migrator");
        DataMigrationStatusFacade.InitStatusLine(CopyStr(HelperFunctions.GetMigrationTypeTxt(), 1, 10), Database::Vendor, TotalVendorNb, Database::"MigrationQB Vendor", Codeunit::"MigrationQB Vendor Migrator");
        DataMigrationStatusFacade.InitStatusLine(CopyStr(HelperFunctions.GetMigrationTypeTxt(), 1, 10), Database::"G/L Account", TotalChartOfAccountNb, Database::"MigrationQB Account", Codeunit::"MigrationQB Account Migrator");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Data Migration Mgt.", 'OnAfterMigrationFinished', '', true, true)]
    local procedure OnAfterMigrationFinishedSubscriber(var DataMigrationStatus: Record "Data Migration Status"; WasAborted: Boolean; StartTime: DateTime; Retry: Boolean)
    begin
        if DataMigrationStatus."Migration Type" <> HelperFunctions.GetMigrationTypeTxt() then
            exit;

        if WasAborted or Retry then
            exit;

        SendCompletedMigrationTelemetry(CurrentDateTime());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Data Migration Facade", 'OnMigrationCompleted', '', false, false)]
    local procedure OnAllStepsCompletedSubscriber(DataMigrationStatus: Record "Data Migration Status")
    begin
        if not (DataMigrationStatus."Migration Type" = HelperFunctions.GetMigrationTypeTxt()) then
            exit;

        HelperFunctions.CleanupStagingTables();
        HelperFunctions.CleanupIsolatedStorage();
    end;

    procedure GetCompletedMigrationDateTime(var MigrationDateTime: DateTime): Boolean
    var
        DataMigrationStatus: Record "Data Migration Status";
    begin
        DataMigrationStatus.SetRange("Migration Type", HelperFunctions.GetMigrationTypeTxt());
        if not DataMigrationStatus.FindSet() then
            exit(false);

        repeat
            if DataMigrationStatus.Status <> DataMigrationStatus.Status::Completed then
                exit(false);
            if DataMigrationStatus.SystemModifiedAt > MigrationDateTime then
                MigrationDateTime := DataMigrationStatus.SystemModifiedAt;
        until DataMigrationStatus.Next() = 0;

        exit(true);
    end;

    procedure SendCompletedMigrationTelemetry(MigrationDateTime: DateTime)
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        TelemetryDimensions: Dictionary of [Text, Text];
    begin
        FeatureTelemetry.LogUptake('0000JMQ', 'Cloud Migration', Enum::"Feature Uptake Status"::Used);

        TelemetryDimensions.Add('Category', CloudMigrationLbl);
        TelemetryDimensions.Add('NumberOfCompanies', Format(1, 0, 9));
        TelemetryDimensions.Add('TotalMigrationSize', Format(0, 0, 9));
        TelemetryDimensions.Add('TotalOnPremSize', Format(0, 0, 9));
        TelemetryDimensions.Add('Product', QBOLbl);
        TelemetryDimensions.Add('MigrationDateTime', Format(MigrationDateTime, 0, 9));
        FeatureTelemetry.LogUsage('0000JMR', 'Cloud Migration', 'Tenant was cloud migrated', TelemetryDimensions);
    end;
}
