// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

table 1831 "Bus. Unit In Cons. Process"
{
    Caption = 'Business Unit in Consolidation Process';
    ReplicateData = false;
    Extensible = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Consolidation Process Id"; Integer)
        {
            TableRelation = "Consolidation Process";
            DataClassification = SystemMetadata;
        }
        field(2; "Business Unit Code"; Code[20])
        {
            TableRelation = "Business Unit";
            DataClassification = CustomerContent;
        }
        field(3; "Default Data Import Method"; Option)
        {
            OptionCaption = 'Database,API';
            OptionMembers = Database,API;
            FieldClass = FlowField;
            CalcFormula = lookup("Business Unit"."Default Data Import Method" where(Code = field("Business Unit Code")));
        }
        field(4; "Status"; Option)
        {
            OptionCaption = 'Not started,Importing data,Consolidating,Finished,Error';
            OptionMembers = NotStarted,ImportingData,Consolidating,Finished,Error;
            DataClassification = SystemMetadata;
        }
        field(5; "Average Exchange Rate"; Decimal)
        {
            AutoFormatType = 0;
            DataClassification = CustomerContent;
        }
        field(6; "Closing Exchange Rate"; Decimal)
        {
            AutoFormatType = 0;
            DataClassification = CustomerContent;
        }
        field(7; "Last Closing Exchange Rate"; Decimal)
        {
            AutoFormatType = 0;
            DataClassification = CustomerContent;
        }
        field(8; "Currency Exchange Rate Table"; Option)
        {
            DataClassification = CustomerContent;
            OptionMembers = "Local","Business Unit";
            OptionCaption = 'Local,Business Unit';
        }
        field(9; "Starting Date"; Date)
        {
            FieldClass = FlowField;
            CalcFormula = lookup("Consolidation Process"."Starting Date" where(Id = field("Consolidation Process Id")));
        }
        field(10; "Ending Date"; Date)
        {
            FieldClass = FlowField;
            CalcFormula = lookup("Consolidation Process"."Ending Date" where(Id = field("Consolidation Process Id")));
        }
        field(11; "Currency Code"; Code[10])
        {
            DataClassification = CustomerContent;
        }
    }
    keys
    {
        key(Key1; "Consolidation Process Id", "Business Unit Code")
        {
            Clustered = true;
        }
    }
}
