// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Foundation.NoSeries;
using Microsoft.Sales.History;
using System.Telemetry;

table 15000300 "Recurring Group"
{
    Caption = 'Recurring Group';
    LookupPageID = "Recurring Group Overview";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(3; "Date formula"; DateFormula)
        {
            Caption = 'Date formula';
        }
        field(4; "Create only the latest"; Boolean)
        {
            Caption = 'Create only the latest';
        }
        field(5; "Starting date"; Date)
        {
            Caption = 'Starting date';
        }
        field(6; "Closing date"; Date)
        {
            Caption = 'Closing date';
        }
        field(10; "Ordre No. Series"; Code[20])
        {
            Caption = 'Ordre No. Series';
            TableRelation = "No. Series";
        }
        field(11; "Posting No. Series"; Code[20])
        {
            Caption = 'Posting No. Series';
            TableRelation = "No. Series";
        }
        field(20; "Update Document Date"; Option)
        {
            Caption = 'Update Document Date';
            OptionCaption = 'Posting Date,Processing Date';
            OptionMembers = "Posting Date","Processing Date";
        }
        field(22; "Document Date Formula"; Code[10])
        {
            Caption = 'Document Date Formula';
        }
        field(24; "Delivery Date Formula"; Code[10])
        {
            Caption = 'Delivery Date Formula';
        }
        field(25; "Update Price"; Option)
        {
            Caption = 'Update Price';
            OptionCaption = 'Fixed,Recalculate,Reset';
            OptionMembers = "Fixed",Recalculate,Reset;
        }
        field(26; "Update Number"; Option)
        {
            Caption = 'Update Number';
            OptionCaption = 'Constant,Reduce';
            OptionMembers = Constant,Reduce;
        }
        field(27; "Reset Delivery"; Boolean)
        {
            Caption = 'Reset Delivery';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        FeatureTelemetry.LogUptake('1000HV1', NORecurringOrderTok, Enum::"Feature Uptake Status"::"Set up");
    end;

    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        NORecurringOrderTok: Label 'NO Recurring Order', Locked = true;
}

