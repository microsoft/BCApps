// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

/// <summary>
/// The interface for running database activity monitor.
/// </summary>
codeunit 6281 "Database Activity Monitor"
{
    Access = Public;
    SingleInstance = true;

    var
        DatabaseActivityMonitorImpl: Codeunit "Database Activity Monitor Impl";

    /// <summary>
    /// Starts monitoring database activities.
    /// </summary>
    procedure Start()
    begin
        DatabaseActivityMonitorImpl.Start();
    end;

    /// <summary>
    /// Stops monitoring database activities.
    /// </summary>
    procedure Stop()
    begin
        DatabaseActivityMonitorImpl.Stop();
    end;

    /// <summary>
    /// Checks if the database activity monitor is active.
    /// </summary>
    /// <returns>True if the monitor is active, false otherwise.</returns>
    procedure IsMonitorActive(): Boolean
    begin
        exit(DatabaseActivityMonitorImpl.IsMonitorActive());
    end;

    /// <summary>
    /// Checks if the database activity is initialized with data.
    /// </summary>
    /// <returns>True if data exists for the recording, false otherwise.</returns>
    procedure IsInitialized(): Boolean
    begin
        exit(DatabaseActivityMonitorImpl.IsInitialized());
    end;

    /// <summary>
    /// Clears the log of database activities.
    /// </summary>
    procedure ClearLog()
    begin
        DatabaseActivityMonitorImpl.ClearLog();
    end;

    /// <summary>
    /// Checks if monitoring table.
    /// </summary>
    /// <returns>True if the monitor is active, false otherwise.</returns>
    procedure IsMonitoringTable(TableId: Integer): Boolean
    begin
        exit(DatabaseActivityMonitorImpl.IsMonitoringTable(TableId));
    end;
}