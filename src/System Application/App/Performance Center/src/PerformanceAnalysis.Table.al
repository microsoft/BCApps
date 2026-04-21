// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

using System.Security.AccessControl;

/// <summary>
/// A single Performance Analysis request. Anchors the profiler schedule, the filtered
/// profiles, the AI conclusion, and the chat history.
/// </summary>
table 8403 "Performance Analysis"
{
    Access = Public;
    DataClassification = SystemMetadata;
    Caption = 'Performance Analysis';
    LookupPageId = "Perf. Analysis List";
    DrillDownPageId = "Perf. Analysis List";

    fields
    {
        field(1; "Id"; Guid)
        {
            Caption = 'Id';
        }
        field(2; "Title"; Text[250])
        {
            Caption = 'Title';
        }
        field(3; "Requested By"; Guid)
        {
            Caption = 'Requested By';
            TableRelation = User."User Security ID";
        }
        field(4; "Requested By User Name"; Text[132])
        {
            Caption = 'Requested By (User Name)';
            FieldClass = FlowField;
            CalcFormula = lookup(User."User Name" where("User Security ID" = field("Requested By")));
            Editable = false;
        }
        field(5; "Requested At"; DateTime)
        {
            Caption = 'Requested At';
        }
        field(10; "Scenario Activity Type"; Enum "Perf. Profile Activity Type")
        {
            Caption = 'Scenario';
        }
        field(11; "Trigger Kind"; Enum "Perf. Analysis Trigger")
        {
            Caption = 'Trigger Kind';
        }
        field(12; "Trigger Object Type"; Option)
        {
            Caption = 'Trigger Object Type';
            OptionMembers = " ",TableData,Table,Report,Codeunit,XMLport,MenuSuite,Page,Query,System,FieldNumber;
            OptionCaption = ' ,TableData,Table,Report,Codeunit,XMLport,MenuSuite,Page,Query,System,FieldNumber';
        }
        field(13; "Trigger Object Id"; Integer)
        {
            Caption = 'Trigger Object Id';
        }
        field(14; "Trigger Object Name"; Text[250])
        {
            Caption = 'Trigger Object Name';
        }
        field(15; "Trigger Action Name"; Text[250])
        {
            Caption = 'Trigger Action or Field';
        }
        field(20; "Frequency"; Enum "Perf. Analysis Frequency")
        {
            Caption = 'Frequency';
        }
        field(21; "Observed Duration (ms)"; Integer)
        {
            Caption = 'Observed Duration (ms)';
            MinValue = 0;
        }
        field(22; "Expected Duration (ms)"; Integer)
        {
            Caption = 'Expected Duration (ms)';
            MinValue = 0;
        }
        field(30; "Target User"; Guid)
        {
            Caption = 'Target User';
            TableRelation = User."User Security ID";
        }
        field(31; "Target User Name"; Text[132])
        {
            Caption = 'Target User Name';
            FieldClass = FlowField;
            CalcFormula = lookup(User."User Name" where("User Security ID" = field("Target User")));
            Editable = false;
        }
        field(40; "Monitoring Starts At"; DateTime)
        {
            Caption = 'Monitoring Starts At';
        }
        field(41; "Monitoring Ends At"; DateTime)
        {
            Caption = 'Monitoring Ends At';
        }
        field(42; "Profile Threshold (ms)"; Integer)
        {
            Caption = 'Profile Threshold (ms)';
        }
        field(50; "Notes"; Text[2048])
        {
            Caption = 'Notes';
        }
        field(60; "State"; Enum "Perf. Analysis State")
        {
            Caption = 'State';
            Editable = false;
        }
        field(61; "Related Schedule Id"; Guid)
        {
            Caption = 'Related Schedule Id';
            Editable = false;
        }
        field(62; "Profiles Captured"; Integer)
        {
            Caption = 'Profiles Captured';
            Editable = false;
        }
        field(63; "Profiles Relevant"; Integer)
        {
            Caption = 'Profiles Flagged Relevant';
            Editable = false;
        }
        field(70; "Conclusion"; Blob)
        {
            Caption = 'Conclusion';
        }
        field(71; "Ai Model"; Text[100])
        {
            Caption = 'AI Model';
            Editable = false;
        }
        field(80; "Created At"; DateTime)
        {
            Caption = 'Created At';
            Editable = false;
        }
        field(81; "Modified At"; DateTime)
        {
            Caption = 'Modified At';
            Editable = false;
        }
        field(90; "Last Error"; Text[2048])
        {
            Caption = 'Last Error';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Id") { Clustered = true; }
        key(User; "Requested By", "Requested At") { }
        key(State; "State", "Requested At") { }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Title", "Requested By User Name", "State") { }
        fieldgroup(Brick; "Title", "Requested By User Name", "State", "Requested At") { }
    }

    trigger OnInsert()
    begin
        if IsNullGuid(Rec."Id") then
            Rec."Id" := CreateGuid();
        if Rec."Requested At" = 0DT then
            Rec."Requested At" := CurrentDateTime();
        if IsNullGuid(Rec."Requested By") then
            Rec."Requested By" := UserSecurityId();
        Rec."Created At" := CurrentDateTime();
        Rec."Modified At" := Rec."Created At";
    end;

    trigger OnModify()
    begin
        Rec."Modified At" := CurrentDateTime();
    end;

    trigger OnDelete()
    var
        AnalysisLine: Record "Performance Analysis Line";
    begin
        AnalysisLine.SetRange("Analysis Id", Rec."Id");
        if not AnalysisLine.IsEmpty() then
            AnalysisLine.DeleteAll();
    end;

    /// <summary>
    /// Convenience accessor for the conclusion Blob as text.
    /// </summary>
    procedure GetConclusion() Result: Text
    var
        InStream: InStream;
    begin
        Rec.CalcFields(Conclusion);
        if not Rec.Conclusion.HasValue() then
            exit('');
        Rec.Conclusion.CreateInStream(InStream, TextEncoding::UTF8);
        InStream.ReadText(Result);
    end;

    /// <summary>
    /// Convenience setter for the conclusion Blob.
    /// </summary>
    procedure SetConclusion(NewText: Text)
    var
        OutStream: OutStream;
    begin
        Clear(Rec.Conclusion);
        Rec.Conclusion.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(NewText);
    end;
}
