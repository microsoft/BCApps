// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Graph;

using Microsoft.Foundation.UOM;
using Microsoft.HumanResources.Employee;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Projects.TimeSheet;
using System.Utilities;

table 5510 "Employee Time Reg Buffer"
{
    Caption = 'Employee Time Reg Buffer';
    ReplicateData = false;
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(2; "Line No"; Integer)
        {
            Caption = 'Line No';
            DataClassification = SystemMetadata;
        }
        field(3; Date; Date)
        {
            Caption = 'Date';
            DataClassification = SystemMetadata;
            NotBlank = true;
        }
        field(6; "Job No."; Code[20])
        {
            DataClassification = SystemMetadata;
            TableRelation = "Job";
        }
        field(7; "Job Task No."; Code[20])
        {
            DataClassification = SystemMetadata;
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));
        }
        field(9; "Cause of Absence Code"; Code[10])
        {
            DataClassification = SystemMetadata;
        }
        field(15; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DataClassification = SystemMetadata;
            NotBlank = true;
        }
        field(20; Status; Enum "Employee Time Reg. Status")
        {
            Caption = 'Status';
            DataClassification = SystemMetadata;
        }
        field(21; "Employee No"; Code[20])
        {
            Caption = 'Employee No';
            DataClassification = SystemMetadata;
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            DataClassification = SystemMetadata;
        }
        field(5407; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            DataClassification = SystemMetadata;
            TableRelation = "Unit of Measure";
            ValidateTableRelation = false;
        }
        field(7999; "Employee Id"; Guid)
        {
            Caption = 'Employee Id';
            DataClassification = SystemMetadata;
            NotBlank = true;

            trigger OnValidate()
            var
                Employee: Record Employee;
                Resource: Record Resource;
            begin
                if not Employee.GetBySystemId(Rec."Employee Id") then
                    Error(CouldNotFindEmployeeErr);

                GraphMgtTimeRegistration.InitUserSetup();
                if not Resource.Get(Employee."Resource No.") then begin
                    GraphMgtTimeRegistration.CreateResourceToUseTimeSheet(Resource);
                    Employee.Validate("Resource No.", Resource."No.");
                    Employee.Modify();
                end else
                    GraphMgtTimeRegistration.ModifyResourceToUseTimeSheet(Resource);
            end;
        }
        field(8000; Id; Guid)
        {
            Caption = 'Id';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(8001; "Last Modified Date Time"; DateTime)
        {
            Caption = 'Last Modified Date Time';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(9032; "Unit of Measure Id"; Guid)
        {
            Caption = 'Unit of Measure Id';
            DataClassification = SystemMetadata;
        }
        field(8002; "Job Id"; Guid)
        {
            Caption = 'Project Id';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; Id)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        if not IsTemporary then
            Error(RecordMustBeTemporaryErr);
    end;

    var
        GraphMgtTimeRegistration: Codeunit "Graph Mgt - Time Registration";
        CouldNotFindEmployeeErr: Label 'The employee cannot be found.', Locked = true;
        RecordMustBeTemporaryErr: Label 'Employee Time Reg Buffer must be used as a temporary record.', Locked = true;
        FiltersMustBeSpecifiedErr: Label 'A filter must be specified. The filter could be for the date, employeeId or id.', Locked = true;
        DateFilterIsInvalidErr: Label 'The date filter is invalid. The date filter must be a valid range with maximum %1 days.', Locked = true;
        EmployeeFilterOneEmployeeOnlyErr: Label 'You can only search for one employee using the employee filter.';

    [Scope('Cloud')]
    procedure PropagateInsert()
    var
        Employee: Record Employee;
        TimeSheetLine: Record "Time Sheet Line";
        TimeSheetDetail: Record "Time Sheet Detail";
        Resource: Record Resource;
        UnitOfMeasure: Record "Unit of Measure";
        TimeSheetHeaderNo: Code[20];
    begin
        if not IsTemporary then
            Error(RecordMustBeTemporaryErr);

        Employee.Get("Employee No");

        TimeSheetHeaderNo := GraphMgtTimeRegistration.GetTimeSheetHeader(Employee."Resource No.", CalcDate('<-CW>', Date));

        GraphMgtTimeRegistration.GetTimeSheetLineWithEmptyDate(TimeSheetLine, TimeSheetHeaderNo, Date);

        GraphMgtTimeRegistration.AddTimeSheetDetailWithDimensionSetAndJob(TimeSheetDetail, TimeSheetLine, Date, Quantity, "Dimension Set ID", "Job Id");

        TimeSheetDetail.Validate("Job Task No.", "Job Task No.");

        TransferFields(TimeSheetDetail, true);
        Id := TimeSheetDetail.SystemId;

        "Employee No" := Employee."No.";
        "Employee Id" := Employee.SystemId;
        if Resource.Get(Employee."Resource No.") then
            "Unit of Measure Code" := Resource."Base Unit of Measure";
        if UnitOfMeasure.Get(Resource."Base Unit of Measure") then
            "Unit of Measure Id" := UnitOfMeasure.SystemId;
    end;

    [Scope('Cloud')]
    procedure PropagateModify()
    var
        TimeSheetDetail: Record "Time Sheet Detail";
        RecordModified: Boolean;
    begin
        if Quantity <> xRec.Quantity then begin
            TimeSheetDetail.GetBySystemId(Rec.Id);
            TimeSheetDetail.Validate(Quantity, Quantity);
            RecordModified := true;
        end;
        if "Dimension Set ID" <> xRec."Dimension Set ID" then begin
            if not RecordModified then begin
                TimeSheetDetail.GetBySystemId(Id);
                TimeSheetDetail.FindFirst();
                RecordModified := true;
            end;
            TimeSheetDetail.Validate("Dimension Set ID", "Dimension Set ID");
        end;
        if "Job Id" <> xRec."Job Id" then begin
            if not RecordModified then begin
                TimeSheetDetail.GetBySystemId(Id);
                RecordModified := true;
            end;
            TimeSheetDetail.Validate("Job Id", "Job Id");
            TimeSheetDetail.Validate("Job No.", "Job No.");
        end;
        if RecordModified then begin
            TimeSheetDetail.Modify(true);
            TransferFields(TimeSheetDetail);
            Id := TimeSheetDetail.SystemId;

        end;
    end;

    [Scope('Cloud')]
    procedure PropagateDelete()
    var
        TimeSheetDetail: Record "Time Sheet Detail";
    begin
        TimeSheetDetail.GetBySystemId(Id);
        TimeSheetDetail.Delete(true);
    end;

    [Scope('Cloud')]
    procedure LoadRecords(IdFilter: Text; DateFilter: Text; EmployeeIdFilter: Text)
    var
        Employee: Record Employee;
        Calendar: Record Date;
        FirstDate: Date;
        LastDate: Date;
    begin
        if IdFilter <> '' then begin
            LoadRecordFromId(IdFilter);
            exit;
        end;

        if EmployeeIdFilter <> '' then begin
            Employee.SetFilter(SystemId, EmployeeIdFilter);
            if Employee.Count > 1 then
                Error(EmployeeFilterOneEmployeeOnlyErr);
            LoadRecordsFromEmployee(EmployeeIdFilter);
            exit;
        end;

        if DateFilter <> '' then begin
            Calendar.SetRange("Period Type", Calendar."Period Type"::Date);
            Calendar.SetFilter("Period Start", DateFilter);
            if Calendar.FindFirst() then begin
                FirstDate := Calendar."Period Start";
                Calendar.FindLast();
                LastDate := Calendar."Period Start";
            end else
                Error(DateFilterIsInvalidErr, MaxDateFilterRange());
            if LastDate - FirstDate > MaxDateFilterRange() then
                Error(DateFilterIsInvalidErr, MaxDateFilterRange());
            LoadRecordsFromTSDetails(DateFilter);
            exit;
        end;

        Error(FiltersMustBeSpecifiedErr);
    end;

    [Scope('OnPrem')]
    procedure LoadRecordFromId(IdFilter: Text)
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        TimeSheetDetail: Record "Time Sheet Detail";
        Employee: Record Employee;
        Resource: Record Resource;
        UnitOfMeasure: Record "Unit of Measure";
    begin
        TimeSheetDetail.SetFilter(SystemId, IdFilter);
        if not TimeSheetDetail.FindFirst() then
            exit;

        TimeSheetLine.Get(TimeSheetDetail."Time Sheet No.", TimeSheetDetail."Time Sheet Line No.");
        if TimeSheetLine.Type <> TimeSheetLine.Type::Resource then
            exit;

        TimeSheetHeader.Get(TimeSheetDetail."Time Sheet No.");
        Employee.SetRange("Resource No.", TimeSheetHeader."Resource No.");
        if not Employee.FindFirst() or not Resource.Get(TimeSheetHeader."Resource No.") then
            exit;

        TransferFields(TimeSheetDetail, true);
        Id := TimeSheetDetail.SystemId;

        "Line No" := TimeSheetDetail."Time Sheet Line No.";
        "Employee No" := Employee."No.";
        "Employee Id" := Employee.SystemId;
        if UnitOfMeasure.Get(Resource."Base Unit of Measure") then begin
            "Unit of Measure Code" := UnitOfMeasure.Code;
            "Unit of Measure Id" := UnitOfMeasure.SystemId;
        end;

        Insert(true);
    end;

    [Scope('OnPrem')]
    procedure LoadRecordsFromEmployee(EmployeeIdFilter: Text)
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        TimeSheetDetail: Record "Time Sheet Detail";
        Employee: Record Employee;
        Resource: Record Resource;
        UnitOfMeasure: Record "Unit of Measure";
        UnitOfMeasureFound: Boolean;
    begin
        Employee.SetFilter(SystemId, EmployeeIdFilter);
        if not Employee.FindFirst() then
            exit;

        if not Resource.Get(Employee."Resource No.") then
            exit;

        TimeSheetHeader.SetRange("Resource No.", Resource."No.");
        if not TimeSheetHeader.FindSet() then
            exit;

        if UnitOfMeasure.Get(Resource."Base Unit of Measure") then
            UnitOfMeasureFound := true;

        repeat
            TimeSheetLine.SetRange("Time Sheet No.", TimeSheetHeader."No.");
            TimeSheetLine.SetRange(Type, TimeSheetLine.Type::Resource);
            if TimeSheetLine.FindSet() then
                repeat
                    TimeSheetDetail.SetRange("Time Sheet No.", TimeSheetHeader."No.");
                    TimeSheetDetail.SetRange("Time Sheet Line No.", TimeSheetLine."Line No.");
                    if TimeSheetDetail.FindSet() then
                        repeat
                            TransferFields(TimeSheetDetail, true);
                            Id := TimeSheetDetail.SystemId;
                            "Line No" := TimeSheetDetail."Time Sheet Line No.";
                            "Employee No" := Employee."No.";
                            "Employee Id" := Employee.SystemId;
                            if UnitOfMeasureFound then begin
                                "Unit of Measure Id" := UnitOfMeasure.SystemId;
                                "Unit of Measure Code" := UnitOfMeasure.Code;
                            end;
                            Insert(true);
                        until TimeSheetDetail.Next() = 0;
                until TimeSheetLine.Next() = 0;
        until TimeSheetHeader.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure LoadRecordsFromTSDetails(DateFilter: Text)
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        TimeSheetDetail: Record "Time Sheet Detail";
        Employee: Record Employee;
        Resource: Record Resource;
        UnitOfMeasure: Record "Unit of Measure";
        PrevTimeSheetHeaderNo: Code[20];
        HeaderFound: Boolean;
        PrevResourceNo: Code[20];
        ResourceFound: Boolean;
        UnitOfMeasureFound: Boolean;
    begin
        TimeSheetDetail.SetFilter(Date, DateFilter);
        if not TimeSheetDetail.FindSet() then
            exit;

        PrevResourceNo := '';
        PrevTimeSheetHeaderNo := '';
        repeat
            TimeSheetLine.Get(TimeSheetDetail."Time Sheet No.", TimeSheetDetail."Time Sheet Line No.");
            if TimeSheetLine.Type = TimeSheetLine.Type::Resource then begin
                HeaderFound := false;
                if PrevTimeSheetHeaderNo = TimeSheetDetail."Time Sheet No." then
                    HeaderFound := true
                else
                    if TimeSheetHeader.Get(TimeSheetDetail."Time Sheet No.") then begin
                        PrevTimeSheetHeaderNo := TimeSheetHeader."No.";
                        HeaderFound := true;
                    end;

                if HeaderFound then begin
                    ResourceFound := false;
                    Employee.SetRange("Resource No.", TimeSheetHeader."Resource No.");
                    if PrevResourceNo = TimeSheetHeader."Resource No." then
                        ResourceFound := true
                    else
                        if Employee.FindFirst() and Resource.Get(TimeSheetHeader."Resource No.") then begin
                            PrevResourceNo := TimeSheetHeader."Resource No.";
                            ResourceFound := true;
                            UnitOfMeasureFound := false;
                            if UnitOfMeasure.Get(Resource."Base Unit of Measure") then
                                UnitOfMeasureFound := true;
                        end;
                    if ResourceFound then begin
                        TransferFields(TimeSheetDetail, true);
                        Id := TimeSheetDetail.SystemId;

                        "Line No" := TimeSheetDetail."Time Sheet Line No.";
                        "Employee No" := Employee."No.";
                        "Employee Id" := Employee.SystemId;
                        if UnitOfMeasureFound then begin
                            "Unit of Measure Code" := UnitOfMeasure.Code;
                            "Unit of Measure Id" := UnitOfMeasure.SystemId;
                        end;
                        Insert(true);
                    end;
                end;
            end;
        until TimeSheetDetail.Next() = 0;
    end;

    local procedure MaxDateFilterRange(): Integer
    begin
        exit(70);
    end;
}

