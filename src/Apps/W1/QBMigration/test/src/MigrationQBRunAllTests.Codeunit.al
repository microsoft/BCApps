codeunit 139531 "MigrationQB RunAllTests"
{
    trigger OnRun();

    var
        MigrationQBAccountTableTest: Codeunit "MigrationQB Account Tests";
        MigrationQBOTests: Codeunit "MigrationQBO Tests";
        MigrationQBTelemetryTests: Codeunit "MigrationQB Telemetry Tests";
    begin
        MigrationQBAccountTableTest.Run();
        MigrationQBOTests.Run();
        MigrationQBTelemetryTests.Run();
    end;
}