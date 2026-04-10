namespace System.Telemetry;

using System;

codeunit 9521 "Emit Database Wait Statistics"
{
    Access = Internal;

    trigger OnRun()
    var
        NavSqlConnectionTelemetry: DotNet NavSqlConnectionTelemetry;
    begin
        NavSqlConnectionTelemetry.SendWaitStatisticsSnapshotToTelemetry();
    end;
}