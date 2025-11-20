// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

table 1833 "Consolidation Setup"
{
    Caption = 'Consolidation Setup';
    ReplicateData = false;
    Access = Internal;
    Extensible = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        field(2; MaxAttempts429; Integer)
        {
            Caption = 'Maximum number of retries after receiving HTTP 429 responses';
            DataClassification = SystemMetadata;
            MinValue = 0;
            MaxValue = 10;
        }
        field(3; WaitMsRetries; Integer)
        {
            Caption = 'Wait time in ms between retries';
            DataClassification = SystemMetadata;
            MinValue = 100;
            MaxValue = 10000;
        }
        field(4; PageSize; Integer)
        {
            Caption = 'Page Size';
            DataClassification = SystemMetadata;
            MinValue = 1;
            MaxValue = 1000;
        }
        field(5; MaxAttempts; Integer)
        {
            Caption = 'Maximum number of retries for a consolidation process';
            DataClassification = SystemMetadata;
            MinValue = 0;
            MaxValue = 5;
        }
    }
    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }

    }

    var
        TelemetryCategoryTok: Label 'financial-consolidations', Locked = true;

    internal procedure GetOrCreateWithDefaults()
    begin
        Rec.Reset();
        if Rec.FindFirst() then
            exit;
        Rec.MaxAttempts429 := 5;
        Rec.WaitMsRetries := 1000;
        Rec.PageSize := 500;
        Rec.Insert();
    end;

    internal procedure GetTelemetryCategory(): Text
    begin
        exit(TelemetryCategoryTok);
    end;
}
