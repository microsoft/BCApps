// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

table 130454 "Test Input Group"
{
    DataClassification = CustomerContent;
    ReplicateData = false;

    fields
    {
        field(1; "Code"; Code[100])
        {
            DataClassification = CustomerContent;
            TableRelation = "AL Test Suite".Name;
            Caption = 'Code';
            ToolTip = 'Specifies the code for the test input group.';
        }
        field(10; Description; Text[2048])
        {
            DataClassification = CustomerContent;
            Caption = 'Description';
            ToolTip = 'Specifies the description of the test input group.';
        }
        field(20; Sensitive; Boolean)
        {
            Caption = 'Sensitive';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies if the test input is sensitive and should not be shown directly off the page.';
            trigger OnValidate()
            var
                TestInput: Record "Test Input";
            begin
                TestInput.SetRange("Test Input Group Code", Rec."Code");
                TestInput.ModifyAll(Sensitive, Rec.Sensitive);
            end;
        }
        field(50; "No. of Entries"; Integer)
        {
            Caption = 'No. of Entries';
            FieldClass = FlowField;
            CalcFormula = count("Test Input" where("Test Input Group Code" = field(Code)));
            ToolTip = 'Specifies the number of entries in the dataset.';
        }
    }
    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    trigger OnDelete()
    var
        TestInput: Record "Test Input";
    begin
        TestInput.SetRange("Test Input Group Code", Rec."Code");
        TestInput.ReadIsolation := IsolationLevel::ReadCommitted;
        if TestInput.IsEmpty() then
            exit;

        TestInput.DeleteAll(true);
    end;

    internal procedure CreateUniqueGroupForALTest(ALTestSuite: Record "AL Test Suite")
    var
        ExistingTestInputGroup: Record "Test Input Group";
    begin
        ExistingTestInputGroup.ReadIsolation := IsolationLevel::ReadCommitted;
        ExistingTestInputGroup.SetFilter("Code", ALTestSuite.Name + '-*');

        if not ExistingTestInputGroup.FindLast() then
            ExistingTestInputGroup.Code := ALTestSuite.Name + ALTestSuffixTxt;

        Rec.Code := IncStr(ExistingTestInputGroup.Code);
        Rec.Description := ImportedAutomaticallyTxt;
        Rec.Insert(true);
    end;

    var
        ALTestSuffixTxt: Label '-00000', Locked = true;
        ImportedAutomaticallyTxt: Label 'Imported from tool';
}