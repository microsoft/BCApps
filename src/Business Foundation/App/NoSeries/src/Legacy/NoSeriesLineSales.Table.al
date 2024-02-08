// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

table 12145 "No. Series Line Sales"
{
    Caption = 'No. Series Line Sales';
#if not CLEAN24
    DrillDownPageId = "No. Series Lines Sales";
    LookupPageId = "No. Series Lines Sales";
#endif
    DataClassification = CustomerContent;
    MovedFrom = '437dbf0e-84ff-417a-965d-ed2bb9650972';
    ObsoleteReason = 'Merged into No. Series Line table.';
#if CLEAN24
    ObsoleteState = Removed;
    ObsoleteTag = '27.0';
#else
    ObsoleteState = Pending;
    ObsoleteTag = '24.0';
#endif
    InherentEntitlements = rX;
    InherentPermissions = rX;

    fields
    {
        field(1; "Series Code"; Code[20])
        {
            Caption = 'Series Code';
            NotBlank = true;
            TableRelation = "No. Series";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
        }
        field(4; "Starting No."; Code[20])
        {
            Caption = 'Starting No.';

#if not CLEAN24
#pragma warning disable AL0432
            trigger OnValidate()
            var
                NoSeriesManagement: Codeunit NoSeriesManagement;
            begin
                NoSeriesManagement.UpdateNoSeriesLineSales(Rec, "Starting No.", CopyStr(FieldCaption("Starting No."), 1, 30));
            end;
#pragma warning restore AL0432
#endif
        }
        field(5; "Ending No."; Code[20])
        {
            Caption = 'Ending No.';

            trigger OnValidate()
#if not CLEAN24
            var
                NoSeriesManagement: Codeunit NoSeriesManagement;
#endif
            begin
                if "Ending No." = '' then
                    "Warning No." := '';
#if not CLEAN24
#pragma warning disable AL0432
                NoSeriesManagement.UpdateNoSeriesLineSales(Rec, "Ending No.", CopyStr(FieldCaption("Ending No."), 1, 30));
#pragma warning restore AL0432
#endif
                Validate(Open);
            end;
        }
        field(6; "Warning No."; Code[20])
        {
            Caption = 'Warning No.';

            trigger OnValidate()
#if not CLEAN24
            var
                NoSeriesManagement: Codeunit NoSeriesManagement;
#endif
            begin
                TestField("Ending No.");
#if not CLEAN24
#pragma warning disable AL0432
                NoSeriesManagement.UpdateNoSeriesLineSales(Rec, "Warning No.", CopyStr(FieldCaption("Warning No."), 1, 30));
#pragma warning restore AL0432
#endif
            end;
        }
        field(7; "Increment-by No."; Integer)
        {
            Caption = 'Increment-by No.';
            InitValue = 1;
            MinValue = 1;
        }
        field(8; "Last No. Used"; Code[20])
        {
            Caption = 'Last No. Used';

            trigger OnValidate()
#if not CLEAN24
            var
                NoSeriesManagement: Codeunit NoSeriesManagement;
#endif
            begin
#if not CLEAN24
#pragma warning disable AL0432
                NoSeriesManagement.UpdateNoSeriesLineSales(Rec, "Last No. Used", CopyStr(FieldCaption("Last No. Used"), 1, 30));
#pragma warning restore AL0432
#endif
                Validate(Open);
            end;
        }
        field(9; Open; Boolean)
        {
            Caption = 'Open';
            Editable = false;
            InitValue = true;

            trigger OnValidate()
            begin
                Open := ("Ending No." = '') or ("Ending No." <> "Last No. Used");
            end;
        }
        field(10; "Last Date Used"; Date)
        {
            Caption = 'Last Date Used';
        }
    }

    keys
    {
        key(Key1; "Series Code", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Series Code", "Starting Date", "Starting No.")
        {
        }
        key(Key3; "Starting No.")
        {
        }
    }
}
