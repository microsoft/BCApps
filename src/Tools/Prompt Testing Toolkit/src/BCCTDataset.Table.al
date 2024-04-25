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
        field(2; "Input Count"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("BCCT Dataset Line" where("Dataset Name" = field("Dataset Name")));
        }

        // field(4; "Dataset Type"; Option)
        // {
        //     DataClassification = CustomerContent;
        //     OptionMembers = Accuracy,"Harms Mitigation",Custom;
        // }
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
        fieldgroup(DropDown; "Dataset Name", "Input Count")
        {
        }
    }

    trigger OnDelete()
    var
        PTFDatasetPrompts: Record "BCCT Dataset Line";
    begin
        PTFDatasetPrompts.SetRange("Dataset Name", "Dataset Name");
        PTFDatasetPrompts.DeleteAll();
    end;

}