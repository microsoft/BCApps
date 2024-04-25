// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;
table 149031 "BCCT Dataset"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Dataset Name"; Code[50])
        {
            DataClassification = CustomerContent;
            trigger OnLookup()
            var
                BCTTDatasetLineRec: Record "BCCT Dataset Line";
                BCTTDatasetLinePage: Page "BCCT Dataset Line";
            begin
                BCTTDatasetLineRec.SetFilter("Dataset Name", Rec."Dataset Name");
                BCTTDatasetLinePage.SetDatasetName(Rec."Dataset Name");
                BCTTDatasetLinePage.SetRecord(BCTTDatasetLineRec);
                BCTTDatasetLinePage.Run();
            end;
        }
        field(2; "Line Count"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("BCCT Dataset Line" where("Dataset Name" = field("Dataset Name")));
        }
    }

    keys
    {
        key(Key1; "Dataset Name")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Dataset Name", "Line Count")
        {
        }
    }

    trigger OnDelete()
    var
        BCCTDatasetLines: Record "BCCT Dataset Line";
    begin
        BCCTDatasetLines.SetRange("Dataset Name", "Dataset Name");
        BCCTDatasetLines.DeleteAll();
    end;

}