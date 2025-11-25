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
            InitValue = 1033; // en-US
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
            CalcFormula = lookup("Windows Language".Name where("Language ID" = field("Language ID")));
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
    }

    trigger OnInsert()
    begin
        UpdateIndentation();
        UpdateGroup();
    end;

    trigger OnModify()
    begin
        UpdateIndentation();
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

    local procedure UpdateGroup()
    var
        ExistingGroup: Record "Test Input Group";
        DefaultGroup: Record "Test Input Group";
        AllGroupsWithSameName: Record "Test Input Group";
    begin
        // Only update parent groups if this record doesn't already have a parent
        if Rec."Parent Group Code" <> '' then
            exit;

        // Find if there's already a group with the same Group Name
        ExistingGroup.SetRange("Group Name", Rec."Group Name");
        ExistingGroup.SetFilter(Code, '<>%1', Rec.Code);

        if not ExistingGroup.FindFirst() then
            exit; // No existing group with same name, nothing to do

        // Check if current record is default language - it should become parent of all
        if Rec."Language ID" = GetDefaultLanguageID() then begin
            // This is default language, make it the parent of all others with same Group Name
            AllGroupsWithSameName.SetRange("Group Name", Rec."Group Name");
            AllGroupsWithSameName.SetFilter(Code, '<>%1', Rec.Code);
            if AllGroupsWithSameName.FindSet(true) then
                repeat
                    AllGroupsWithSameName."Parent Group Code" := Rec.Code;
                    AllGroupsWithSameName.Modify(true);
                until AllGroupsWithSameName.Next() = 0;
        end else begin
            // This is not default language, find the default language group and make it the parent
            DefaultGroup.SetRange("Group Name", Rec."Group Name");
            DefaultGroup.SetRange("Language ID", GetDefaultLanguageID());
            if DefaultGroup.FindFirst() then
                Validate(Rec."Parent Group Code", DefaultGroup.Code)
            else begin
                // No default language version exists yet, use the first existing group that has no parent as parent
                ExistingGroup.SetRange("Group Name", Rec."Group Name");
                ExistingGroup.SetFilter(Code, '<>%1', Rec.Code);
                ExistingGroup.SetRange("Parent Group Code", '');
                if ExistingGroup.FindFirst() then
                    Validate(Rec."Parent Group Code", ExistingGroup.Code);
            end;
        end;
    end;

    procedure GetTestInputGroupLanguages(var LanguageVersions: Record "Test Input Group"): Boolean
    begin
        LanguageVersions.Reset();
        LanguageVersions.SetRange("Group Name", Rec."Group Name");
        exit(LanguageVersions.FindSet());
    end;

    local procedure GetDefaultLanguageID(): Integer
    begin
        exit(1033); // en-US
    end;

    var
        ALTestSuffixTxt: Label '-00000', Locked = true;
        ImportedAutomaticallyTxt: Label 'Imported from tool';
}