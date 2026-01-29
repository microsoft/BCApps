// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

using System.Globalization;

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
        field(2; "Parent Group Code"; Code[100])
        {
            DataClassification = CustomerContent;
            TableRelation = "Test Input Group".Code;
            Caption = 'Parent Group Code';
            ToolTip = 'Specifies the parent group for other versions of the test input group.';

            trigger OnValidate()
            begin
                UpdateIndentation();
                ValidateGroups();
            end;
        }
        field(3; Indentation; Integer)
        {
            Caption = 'Indentation';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the indentation for the tree view.';
        }
        field(5; "Language ID"; Integer)
        {
            Caption = 'Language ID';
            DataClassification = CustomerContent;
            TableRelation = "Windows Language"."Language ID";
            ToolTip = 'Specifies the language ID for the test input group.';

            trigger OnValidate()
            begin
                ValidateGroups();
            end;
        }
        field(6; "Group Name"; Text[250])
        {
            Caption = 'Group';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the group name for the test input group.';
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
        field(40; "Language Tag"; Text[80])
        {
            Caption = 'Language Tag';
            FieldClass = FlowField;
            CalcFormula = lookup("Windows Language"."Language Tag" where("Language ID" = field("Language ID")));
            ToolTip = 'Specifies the language tag for the test input group.';
            Editable = false;
        }
        field(41; "Language Name"; Text[80])
        {
            Caption = 'Language';
            FieldClass = FlowField;
            CalcFormula = lookup("Windows Language".Name where("Language Tag" = field("Language Tag")));
            ToolTip = 'Specifies the language name for the test input group.';
            Editable = false;
        }
        field(50; "No. of Entries"; Integer)
        {
            Caption = 'No. of Entries';
            FieldClass = FlowField;
            CalcFormula = count("Test Input" where("Test Input Group Code" = field(Code)));
            ToolTip = 'Specifies the number of entries in the dataset.';
        }
        field(51; "No. of Languages"; Integer)
        {
            Caption = 'No. of Languages';
            FieldClass = FlowField;
            CalcFormula = count("Test Input Group" where("Parent Group Code" = field(Code)));
            ToolTip = 'Specifies the number of language versions for this test input group.';
        }
        field(60; "Imported by AppId"; Guid)
        {
            Caption = 'Imported from AppId';
            ToolTip = 'Specifies the AppId from which the test input group was imported.';
            DataClassification = SystemMetadata;
        }
    }
    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
        key(Key2; Indentation, "Group Name", Code)
        {
        }
        key(Key3; "Group Name", "Language ID")
        {
        }
        key(Key4; "Group Name", Indentation, Code)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Group Name", Code, "No. of Languages")
        {
        }
    }

    trigger OnInsert()
    begin
        UpdateGroup();
    end;

    trigger OnModify()
    begin
        UpdateGroup();
    end;

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

    local procedure UpdateIndentation()
    begin
        if Rec."Parent Group Code" = '' then
            Rec.Indentation := 0
        else
            Rec.Indentation := 1;
    end;

    local procedure ValidateGroups()
    begin
        if (Rec."Parent Group Code" = '') and (Rec."Language ID" <> 0) then
            Error(ParentGroupMustHaveNoLanguageErr, Rec."Language ID", Rec.Code, Rec."Group Name");

        if (Rec."Parent Group Code" <> '') and (Rec."Language ID" = 0) then
            Error(LanguageVersionMustHaveLanguageErr, Rec."Parent Group Code", Rec.Code, Rec."Group Name");
    end;

    local procedure UpdateGroup()
    var
        ParentGroup: Record "Test Input Group";
        ParentGroupCode: Code[100];
    begin
        if (Rec."Language ID" = 0) or (Rec."Parent Group Code" <> '') or (Rec."Group Name" = '') then
            exit;

        ParentGroupCode := CopyStr(Rec."Group Name", 1, MaxStrLen(ParentGroup.Code));

        if ParentGroup.Get(ParentGroupCode) then
            Rec."Parent Group Code" := ParentGroup.Code
        else begin
            ParentGroup.Init();
            ParentGroup.Code := ParentGroupCode;
            ParentGroup."Group Name" := Rec."Group Name";
            ParentGroup."Language ID" := 0;
            ParentGroup.Insert(false);

            Rec."Parent Group Code" := ParentGroup.Code;
        end;

        UpdateIndentation();
        ValidateGroups();
    end;

    procedure GetTestInputGroupLanguages(TestInputCode: Code[100]; var LanguageVersions: Record "Test Input Group"): Boolean
    begin
        LanguageVersions.Reset();
        LanguageVersions.SetRange("Parent Group Code", TestInputCode);
        exit(LanguageVersions.FindSet());
    end;

    var
        ALTestSuffixTxt: Label '-00000', Locked = true;
        ImportedAutomaticallyTxt: Label 'Imported from tool';
        ParentGroupMustHaveNoLanguageErr: Label 'Parent groups must have no language set (Language ID = 0). Current Language ID: %1, Code: %2, Group Name: %3', Comment = '%1 = Language ID, %2 = Code, %3 = Group Name';
        LanguageVersionMustHaveLanguageErr: Label 'Language versions must have a Language ID set. Parent Group Code: %1, Code: %2, Group Name: %3', Comment = '%1 = Parent Group Code, %2 = Code, %3 = Group Name';
}