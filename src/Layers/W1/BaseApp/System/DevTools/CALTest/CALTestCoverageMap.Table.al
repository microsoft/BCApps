namespace System.TestTools.TestRunner;

using System.Reflection;

table 130406 "CAL Test Coverage Map"
{
    Caption = 'CAL Test Coverage Map';
    DrillDownPageID = "CAL Test Coverage Map";
    LookupPageID = "CAL Test Coverage Map";
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Test Codeunit ID"; Integer)
        {
            Caption = 'Test Codeunit ID';
        }
        field(2; "Object Type"; Option)
        {
            Caption = 'Object Type';
            OptionCaption = ',Table,,Report,,Codeunit,XMLport,MenuSuite,Page,Query';
            OptionMembers = ,"Table",,"Report",,"Codeunit","XMLport",MenuSuite,"Page","Query";
        }
        field(3; "Object ID"; Integer)
        {
            Caption = 'Object ID';
        }
        field(4; "Object Name"; Text[250])
        {
            CalcFormula = lookup(Object.Name where(Type = field("Object Type"),
                                                    ID = field("Object ID")));
            Caption = 'Object Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; "Hit by Test Codeunits"; Integer)
        {
            CalcFormula = count("CAL Test Coverage Map" where("Object Type" = field("Object Type"),
                                                               "Object ID" = field("Object ID")));
            Caption = 'Hit by Test Codeunits';
            FieldClass = FlowField;
        }
        field(6; "Test Codeunit Name"; Text[250])
        {
            CalcFormula = lookup(Object.Name where(Type = const(Codeunit),
                                                    ID = field("Test Codeunit ID")));
            Caption = 'Test Codeunit Name';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Test Codeunit ID", "Object Type", "Object ID")
        {
            Clustered = true;
        }
        key(Key2; "Object Type", "Object ID")
        {
        }
    }

    fieldgroups
    {
    }

    procedure Show()
    begin
        PAGE.RunModal(PAGE::"CAL Test Coverage Map", Rec);
    end;

    procedure ShowHitObjects(TestCodeunitID: Integer)
    var
        CALTestCoverageMap: Record "CAL Test Coverage Map";
    begin
        CALTestCoverageMap.SetRange("Test Codeunit ID", TestCodeunitID);
        CALTestCoverageMap.Show();
    end;

    procedure ShowTestCodeunits()
    var
        CALTestCoverageMap: Record "CAL Test Coverage Map";
    begin
        CALTestCoverageMap.SetRange("Object Type", "Object Type");
        CALTestCoverageMap.SetRange("Object ID", "Object ID");
        CALTestCoverageMap.Show();
    end;
}

