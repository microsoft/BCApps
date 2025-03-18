// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

/// <summary>
/// This table stores the database activity monitor setup.
/// </summary>
table 6281 "Database Act. Monitor Setup"
{
    Access = Internal;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            DataClassification = SystemMetadata;
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
        }
        field(2; "Monitor Active"; Boolean)
        {
            DataClassification = SystemMetadata;
        }
        field(3; "Log All Tables"; Boolean)
        {
            DataClassification = SystemMetadata;
            Caption = 'Log all tables';
            InitValue = true;
        }
        field(4; "Logging Context"; Enum "Database Act. Monitor Context")
        {
            DataClassification = SystemMetadata;
            Caption = 'Logging Context';
            InitValue = 0;
        }
        field(5; "Logging Period"; Enum "Database Act. Monitor Period")
        {
            DataClassification = SystemMetadata;
            Caption = 'Logging Period';
            InitValue = 0;
        }
        field(10; "Emit telemetry"; Boolean)
        {
            DataClassification = SystemMetadata;
            Caption = 'Emit activity to telemetry';
            InitValue = true;
        }
        field(20; "Log Delete"; Boolean)
        {
            DataClassification = SystemMetadata;
            Caption = 'Log Delete';
            InitValue = true;
        }
        field(21; "Log Insert"; Boolean)
        {
            DataClassification = SystemMetadata;
            Caption = 'Log Insert';
            InitValue = true;
        }
        field(22; "Log Modify"; Boolean)
        {
            DataClassification = SystemMetadata;
            Caption = 'Log Modify';
            InitValue = true;
        }
        field(23; "Log Rename"; Boolean)
        {
            DataClassification = SystemMetadata;
            Caption = 'Log Ranme';
            InitValue = true;
        }
        field(100; "Number Of Activities"; Integer)
        {
            DataClassification = SystemMetadata;
            Access = Internal;
            Editable = false;
        }
    }

    // TODO: Some validations?

    keys
    {
        key(PrimaryKey; "Primary Key")
        {
            Clustered = true;
        }
    }
}