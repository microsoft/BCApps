// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Task;

using System.Reflection;
using System.Security.AccessControl;
using System.Utilities;

table 1170 "User Task"
{
    Caption = 'User Task';
    DataCaptionFields = Title;
    DataClassification = CustomerContent;

    fields
    {
        field(1; ID; Integer)
        {
            AutoIncrement = true;
            Caption = 'ID';
            Editable = false;
        }
        field(2; Title; Text[250])
        {
            Caption = 'Subject';
        }
        field(3; "Created By"; Guid)
        {
            Caption = 'Created By';
            DataClassification = EndUserPseudonymousIdentifiers;
            Editable = false;
            TableRelation = User."User Security ID" where("License Type" = const("Full User"));
        }
        field(4; "Created DateTime"; DateTime)
        {
            Caption = 'Created Date';
            Editable = false;
        }
        field(5; "Assigned To"; Guid)
        {
            Caption = 'Assigned To';
            TableRelation = User."User Security ID" where("License Type" = const("Full User"));

            trigger OnValidate()
            var
                UserTaskOccurencies: Record "User Task";
            begin
                if not IsNullGuid("Assigned To") then begin
                    Clear("User Task Group Assigned To");

                    if "Parent ID" <> 0 then begin
                        UserTaskOccurencies.SetRange("Parent ID", "Parent ID");
                        UserTaskOccurencies.SetFilter(ID, '<>%1', ID);
                        if UserTaskOccurencies.FindSet(true) then
                            repeat
                                UserTaskOccurencies."Assigned To" := "Assigned To";
                                UserTaskOccurencies."User Task Group Assigned To" := '';
                                UserTaskOccurencies.Modify(true);
                            until UserTaskOccurencies.Next() = 0;
                    end;
                end;
            end;
        }
        field(7; "Completed By"; Guid)
        {
            Caption = 'Completed By';
            DataClassification = EndUserPseudonymousIdentifiers;
            TableRelation = User."User Security ID" where("License Type" = const("Full User"));

            trigger OnValidate()
            begin
                if not IsNullGuid("Completed By") then begin
                    "Percent Complete" := 100;
                    if "Completed DateTime" = 0DT then
                        "Completed DateTime" := CurrentDateTime;
                    if "Start DateTime" = 0DT then
                        "Start DateTime" := CurrentDateTime;
                end else begin
                    "Completed DateTime" := 0DT;
                    "Percent Complete" := 0;
                end;
            end;
        }
        field(8; "Completed DateTime"; DateTime)
        {
            Caption = 'Completed Date';

            trigger OnValidate()
            begin
                if "Completed DateTime" <> 0DT then begin
                    "Percent Complete" := 100;
                    if IsNullGuid("Completed By") then
                        "Completed By" := UserSecurityId();
                    if "Start DateTime" = 0DT then
                        "Start DateTime" := CurrentDateTime;
                end else begin
                    Clear("Completed By");
                    "Percent Complete" := 0;
                end;
            end;
        }
        field(9; "Due DateTime"; DateTime)
        {
            Caption = 'Due Date';
        }
        field(10; "Percent Complete"; Integer)
        {
            Caption = '% Complete';
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            begin
                if "Percent Complete" = 100 then begin
                    "Completed By" := UserSecurityId();
                    "Completed DateTime" := CurrentDateTime;
                end else begin
                    Clear("Completed By");
                    Clear("Completed DateTime");
                end;

                if "Percent Complete" = 0 then
                    "Start DateTime" := 0DT
                else
                    if "Start DateTime" = 0DT then
                        "Start DateTime" := CurrentDateTime;
            end;
        }
        field(11; "Start DateTime"; DateTime)
        {
            Caption = 'Start Date';
        }
        field(12; Priority; Option)
        {
            Caption = 'Priority';
            OptionCaption = ',Low,Normal,High';
            OptionMembers = ,Low,Normal,High;
        }
        field(13; Description; BLOB)
        {
            Caption = 'Description';
            SubType = Memo;
        }
        field(14; "Created By User Name"; Code[50])
        {
            CalcFormula = lookup(User."User Name" where("User Security ID" = field("Created By")));
            Caption = 'User Created By';
            Editable = false;
            FieldClass = FlowField;
        }
        field(15; "Assigned To User Name"; Code[50])
        {
            CalcFormula = lookup(User."User Name" where("User Security ID" = field("Assigned To")));
            Caption = 'User Assigned To';
            Editable = false;
            FieldClass = FlowField;
        }
        field(16; "Completed By User Name"; Code[50])
        {
            CalcFormula = lookup(User."User Name" where("User Security ID" = field("Completed By")));
            Caption = 'User Completed By';
            Editable = false;
            FieldClass = FlowField;
        }
        field(17; "Object Type"; Option)
        {
            Caption = 'Link Task To';
            OptionCaption = ',,,Report,,,,,Page';
            OptionMembers = ,,,"Report",,,,,"Page";
        }
        field(18; "Object ID"; Integer)
        {
            Caption = 'Object ID';
            TableRelation = AllObj."Object ID" where("Object Type" = field("Object Type"));
        }
        field(19; "Parent ID"; Integer)
        {
            Caption = 'Parent ID';
        }
        field(20; "User Task Group Assigned To"; Code[20])
        {
            Caption = 'User Task Group Assigned To';
            DataClassification = CustomerContent;
            TableRelation = "User Task Group".Code;

            trigger OnValidate()
            var
                UserTaskOccurencies: Record "User Task";
            begin
                if "User Task Group Assigned To" <> '' then begin
                    Clear("Assigned To");
                    Clear("Assigned To User Name");
                end;

                if "Parent ID" <> 0 then begin
                    UserTaskOccurencies.SetRange("Parent ID", "Parent ID");
                    UserTaskOccurencies.SetFilter(ID, '<>%1', ID);
                    if UserTaskOccurencies.FindSet(true) then
                        repeat
                            Clear(UserTaskOccurencies."Assigned To");
                            Clear(UserTaskOccurencies."Assigned To User Name");
                            UserTaskOccurencies."User Task Group Assigned To" := "User Task Group Assigned To";
                            UserTaskOccurencies.Modify(true);
                        until UserTaskOccurencies.Next() = 0;
                end;
            end;
        }
        field(21; ShouldShowPendingTasks; Boolean)
        {
            Caption = 'ShouldShowPendingTasks';
            Editable = false;
            FieldClass = FlowFilter;
        }
    }

    keys
    {
        key(Key1; ID)
        {
            Clustered = true;
        }
        key(Key2; "Assigned To", "User Task Group Assigned To", "Percent Complete", "Due DateTime")
        {
        }
        key(Key3; "User Task Group Assigned To")
        {
            IncludedFields = "Percent Complete", "Due DateTime", "Assigned To";
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        DummyUserTask: Record "User Task";
    begin
        if ("Percent Complete" > 0) and ("Percent Complete" < 100) then
            if not Confirm(ConfirmDeleteQst) then
                Error('');

        if "Parent ID" > 0 then
            if Confirm(ConfirmDeleteAllOccurrencesQst) then begin
                DummyUserTask.CopyFilters(Rec);
                Reset();
                SetRange("Parent ID", "Parent ID");
                DeleteAll();
                CopyFilters(DummyUserTask);
            end
    end;

    trigger OnInsert()
    begin
        Validate("Created DateTime", CurrentDateTime);
        "Created By" := UserSecurityId();
        if IsNullGuid("Assigned To") and ("User Task Group Assigned To" = '') then
            "Assigned To" := UserSecurityId();
    end;

    var
        ConfirmDeleteQst: Label 'This task is started but not complete, delete anyway?';
        ConfirmDeleteAllOccurrencesQst: Label 'Delete all occurrences of this task?';

    procedure CreateRecurrence(RecurringStartDate: Date; Recurrence: DateFormula; Occurrences: Integer)
    var
        UserTaskTemp: Record "User Task";
        Counter: Integer;
        TempDueDate: Date;
    begin
        Validate("Parent ID", ID);
        Validate("Due DateTime", CreateDateTime(RecurringStartDate, 000000T));
        Modify(true);

        Counter := 0;
        TempDueDate := RecurringStartDate;
        while Counter < Occurrences - 1 do begin
            Clear(UserTaskTemp);
            UserTaskTemp.Validate(Title, Title);
            UserTaskTemp.SetDescription(GetDescription());
            UserTaskTemp."Created By" := UserSecurityId();
            UserTaskTemp.Validate("Created DateTime", CurrentDateTime);
            UserTaskTemp.Validate("Assigned To", "Assigned To");
            UserTaskTemp.Validate("User Task Group Assigned To", "User Task Group Assigned To");
            UserTaskTemp.Validate(Priority, Priority);
            UserTaskTemp.Validate("Object Type", "Object Type");
            UserTaskTemp.Validate("Object ID", "Object ID");
            UserTaskTemp.Validate("Parent ID", ID);
            TempDueDate := CalcDate(Recurrence, TempDueDate);
            UserTaskTemp.Validate("Due DateTime", CreateDateTime(TempDueDate, 000000T));
            OnCreateRecurrenceOnBeforeInsert(UserTaskTemp, Rec, Counter, RecurringStartDate, Recurrence);
            UserTaskTemp.Insert(true);
            Counter := Counter + 1;
        end
    end;

    procedure SetCompleted()
    begin
        OnBeforeSetCompleted(Rec);

        "Percent Complete" := 100;
        "Completed By" := UserSecurityId();
        "Completed DateTime" := CurrentDateTime;

        if "Start DateTime" = 0DT then
            "Start DateTime" := CurrentDateTime;

        OnAfterSetCompleted(Rec);
    end;

    procedure SetStyle(): Text
    begin
        if "Percent Complete" <> 100 then
            if ("Due DateTime" <> 0DT) and ("Due DateTime" <= CurrentDateTime) then
                exit('Unfavorable');
        exit('');
    end;

    procedure GetDescription(): Text
    var
        TempBlob: Codeunit "Temp Blob";
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        TempBlob.FromRecord(Rec, FieldNo(Description));
        TempBlob.CreateInStream(InStream, TEXTENCODING::UTF8);
        exit(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator()));
    end;

    procedure SetDescription(StreamText: Text)
    var
        OutStream: OutStream;
    begin
        Clear(Description);
        Description.CreateOutStream(OutStream, TEXTENCODING::UTF8);
        OutStream.Write(StreamText);
        if Modify(true) then;
    end;

    procedure IsCompleted(): Boolean
    begin
        exit("Percent Complete" = 100);
    end;

    procedure RunReportOrPageLink()
    var
        AllObjWithCaption: Record AllObjWithCaption;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunReportOrPageLink(Rec, IsHandled);
        if IsHandled then
            exit;

        if ("Object Type" = 0) or ("Object ID" = 0) then
            exit;
        if "Object Type" = AllObjWithCaption."Object Type"::Page then
            PAGE.Run("Object ID")
        else
            REPORT.Run("Object ID");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunReportOrPageLink(var UserTask: Record "User Task"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateRecurrenceOnBeforeInsert(var UserTask: Record "User Task"; fromUserTask: Record "User Task"; Counter: Integer; RecurringStartDate: Date; Recurrence: DateFormula)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetCompleted(var UserTask: Record "User Task")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetCompleted(var UserTask: Record "User Task")
    begin
    end;
}

