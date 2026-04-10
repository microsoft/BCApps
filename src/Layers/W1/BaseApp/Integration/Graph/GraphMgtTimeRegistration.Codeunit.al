// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Graph;

using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Projects.TimeSheet;
using System.Reflection;
using System.Security.User;

codeunit 5513 "Graph Mgt - Time Registration"
{

    trigger OnRun()
    begin
    end;

    [Scope('OnPrem')]
    procedure InitUserSetup()
    var
        UserSetup: Record "User Setup";
    begin
        if not UserSetup.Get(UserId) then begin
            UserSetup.Validate("User ID", UserId);
            UserSetup.Validate("Time Sheet Admin.", true);
            UserSetup.Insert(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure ModifyResourceToUseTimeSheet(var Resource: Record Resource)
    begin
        if SetResourceFieldsToUseTimeSheet(Resource) then
            Resource.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateResourceToUseTimeSheet(var Resource: Record Resource)
    var
        TempFieldSet: Record "Field" temporary;
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        ResourceRecRef: RecordRef;
    begin
        Clear(Resource);
        Resource.Insert(true);

        ResourceRecRef.GetTable(Resource);
        GraphMgtGeneralTools.ProcessNewRecordFromAPI(ResourceRecRef, TempFieldSet, CreateDateTime(Resource."Last Date Modified", 0T));
        ResourceRecRef.SetTable(Resource);

        ModifyResourceToUseTimeSheet(Resource);
    end;

    [Scope('OnPrem')]
    procedure GetTimeSheetHeader(ResouceNo: Code[20]; StartingDate: Date): Code[20]
    var
        TimeSheetHeader: Record "Time Sheet Header";
    begin
        TimeSheetHeader.Reset();
        TimeSheetHeader.SetRange("Starting Date", StartingDate);
        TimeSheetHeader.SetRange("Resource No.", ResouceNo);
        if not TimeSheetHeader.FindFirst() then begin
            CreateTimeSheetHeader(StartingDate, ResouceNo);
            TimeSheetHeader.FindFirst();
        end;

        exit(TimeSheetHeader."No.");
    end;

    [Scope('OnPrem')]
    procedure GetTimeSheetLineWithEmptyDate(var TimeSheetLine: Record "Time Sheet Line"; TimeSheetHeaderNo: Code[20]; TimeSheetDetailDate: Date)
    var
        TimeSheetDetail: Record "Time Sheet Detail";
        TimeSheetLineNo: Integer;
    begin
        TimeSheetLine.Reset();
        TimeSheetLine.SetRange(Type, TimeSheetDetail.Type::Resource);
        TimeSheetLine.SetRange(Status, TimeSheetLine.Status::Open);
        TimeSheetLine.SetRange("Time Sheet No.", TimeSheetHeaderNo);
        if TimeSheetLine.FindSet() then
            repeat
                if not TimeSheetDetail.Get(TimeSheetHeaderNo, TimeSheetLine."Line No.", TimeSheetDetailDate) then
                    exit;
            until TimeSheetLine.Next() = 0;

        TimeSheetLine.Reset();
        TimeSheetLine.SetRange("Time Sheet No.", TimeSheetHeaderNo);
        if TimeSheetLine.FindLast() then
            TimeSheetLineNo := TimeSheetLine."Line No." + 10000
        else
            TimeSheetLineNo := 10000;

        CreateTimeSheetLine(TimeSheetHeaderNo, TimeSheetLineNo);
        TimeSheetLine.Get(TimeSheetHeaderNo, TimeSheetLineNo);
    end;

    [Scope('OnPrem')]
    procedure AddTimeSheetDetail(var TimeSheetDetail: Record "Time Sheet Detail"; TimeSheetLine: Record "Time Sheet Line"; Date: Date; Quantity: Decimal)
    begin
        Clear(TimeSheetDetail);
        TimeSheetDetail.CopyFromTimeSheetLine(TimeSheetLine);
        TimeSheetDetail.Date := Date;
        TimeSheetDetail.Quantity := Quantity;
        TimeSheetDetail.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure AddTimeSheetDetailWithDimensionSetAndJob(var TimeSheetDetail: Record "Time Sheet Detail"; TimeSheetLine: Record "Time Sheet Line"; Date: Date; Quantity: Decimal; DimensionSetID: Integer; JobID: Guid)
    var
        Job: Record Job;
    begin
        Clear(TimeSheetDetail);
        TimeSheetDetail.CopyFromTimeSheetLine(TimeSheetLine);
        TimeSheetDetail.Date := Date;
        TimeSheetDetail.Quantity := Quantity;
        TimeSheetDetail."Dimension Set ID" := DimensionSetID;

        if Job.GetBySystemId(JobID) then begin
            TimeSheetDetail."Job Id" := Job.SystemId;
            TimeSheetDetail."Job No." := Job."No.";
        end;

        TimeSheetDetail.Insert(true);
    end;

    local procedure SetResourceFieldsToUseTimeSheet(var Resource: Record Resource): Boolean
    begin
        if Resource."Use Time Sheet" and
           (Resource."Time Sheet Approver User ID" <> '') and
           (Resource."Time Sheet Owner User ID" <> '')
        then
            exit(false);

        if not Resource."Use Time Sheet" then
            Resource.Validate("Use Time Sheet", true);
        if Resource."Time Sheet Approver User ID" = '' then
            Resource.Validate("Time Sheet Approver User ID", UserId);
        if Resource."Time Sheet Owner User ID" = '' then
            Resource.Validate("Time Sheet Owner User ID", UserId);

        exit(true);
    end;

    local procedure CreateTimeSheetHeader(StartingDate: Date; ResourceNumber: Code[20])
    var
        CreateTimeSheets: Report "Create Time Sheets";
    begin
        CreateTimeSheets.InitParameters(StartingDate, 1, ResourceNumber, false, true);
        CreateTimeSheets.UseRequestPage(false);
        CreateTimeSheets.Run();
    end;

    local procedure CreateTimeSheetLine(TimeSheetHeaderNo: Code[20]; TimeSheetLineNo: Integer)
    var
        TimeSheetLine: Record "Time Sheet Line";
    begin
        TimeSheetLine."Time Sheet No." := TimeSheetHeaderNo;
        TimeSheetLine."Line No." := TimeSheetLineNo;
        TimeSheetLine.Type := TimeSheetLine.Type::Resource;
        TimeSheetLine.Insert(true);
    end;
}

