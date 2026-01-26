#if not CLEANSCHEMA25 
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Finance.AutomaticAccounts;

using System.Telemetry;

table 11203 "Automatic Acc. Header"
{
    Caption = 'Automatic Acc. Header';
    ObsoleteReason = 'Moved to Automatic Account Codes app.';
    ObsoleteState = Removed;
    ObsoleteTag = '25.0';
    DataClassification = CustomerContent;
    ReplicateData = false;

    fields
    {
        field(1; "No."; Code[10])
        {
            Caption = 'No.';
            NotBlank = true;
        }
        field(2; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(3; Balance; Decimal)
        {
            CalcFormula = sum("Automatic Acc. Line"."Allocation %" where("Automatic Acc. No." = field("No.")));
            Caption = 'Balance';
            FieldClass = FlowField;
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


    trigger OnDelete()
    begin
        AutoAccountLine.SetRange("Automatic Acc. No.", "No.");
        AutoAccountLine.DeleteAll(true);
    end;

    trigger OnInsert()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        FeatureTelemetry.LogUptake('0001P9A', AccTok, Enum::"Feature Uptake Status"::"Set up");
    end;

    var
        AutoAccountLine: Record "Automatic Acc. Line";
        AccTok: Label 'SE Automatic Account', Locked = true;
}

 
#endif
