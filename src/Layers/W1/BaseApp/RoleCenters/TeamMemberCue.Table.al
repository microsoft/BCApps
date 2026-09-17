// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.RoleCenters;

using Microsoft.Projects.TimeSheet;

table 9042 "Team Member Cue"
{
    Caption = 'Team Member Cue';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
        }
        field(9; "New Time Sheets"; Integer)
        {
            CalcFormula = count("Time Sheet Header" where("Lines Exist" = filter(= false),
                                                           "Owner User ID" = field("User ID Filter")));
            Caption = 'New Time Sheets';
            FieldClass = FlowField;
        }
        field(28; "User ID Filter"; Code[50])
        {
            Caption = 'User ID Filter';
            FieldClass = FlowFilter;
        }
        field(29; "Approve ID Filter"; Code[50])
        {
            Caption = 'Approve ID Filter';
            FieldClass = FlowFilter;
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    internal procedure Initialize()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;

    internal procedure SetDefaultFilters(var ShowTimeSheetsToApprove: Boolean)
    var
        TimeSheetHeader: Record "Time Sheet Header";
    begin
        TimeSheetHeader.SetRange("Approver User ID", UserId());
        if not TimeSheetHeader.IsEmpty() then begin
            Rec.SetRange("Approve ID Filter", UserId());
            Rec.SetRange("User ID Filter", UserId());
            ShowTimeSheetsToApprove := true;
        end else begin
            Rec.SetRange("User ID Filter", UserId());
            ShowTimeSheetsToApprove := false;
        end;
    end;

    internal procedure CountTimeSheetsInStatus(UserFilterOption: Option Owner,Approver; TimeSheetStatus: Enum "Time Sheet Status") CalculatedCount: Integer
    var
        TimeSheetLineStatusCount: Query "Time Sheet Line Status Count";
    begin
        case UserFilterOption of
            UserFilterOption::Owner:
                TimeSheetLineStatusCount.SetFilter(Filter_Owner_User, Rec.GetFilter("User ID Filter"));
            UserFilterOption::Approver:
                TimeSheetLineStatusCount.SetFilter(Filter_Approver_User, Rec.GetFilter("Approve ID Filter"));
        end;
        case TimeSheetStatus of
            TimeSheetStatus::Open:
                TimeSheetLineStatusCount.SetRange(Filter_Status, "Time Sheet Status"::Open);
            TimeSheetStatus::Submitted:
                TimeSheetLineStatusCount.SetRange(Filter_Status, "Time Sheet Status"::Submitted);
            TimeSheetStatus::Rejected:
                TimeSheetLineStatusCount.SetRange(Filter_Status, "Time Sheet Status"::Rejected);
            TimeSheetStatus::Approved:
                TimeSheetLineStatusCount.SetRange(Filter_Status, "Time Sheet Status"::Approved);
        end;

        TimeSheetLineStatusCount.Open();
        while TimeSheetLineStatusCount.Read() do
            CalculatedCount += 1
    end;

    internal procedure DrillDownToTimeSheetList(UserFilterOption: Option Owner,Approver; TimeSheetStatus: Enum "Time Sheet Status")
    var
        TimeSheetHeader: Record "Time Sheet Header";
    begin
        case UserFilterOption of
            UserFilterOption::Owner:
                TimeSheetHeader.SetFilter("Owner User ID", Rec.GetFilter("User ID Filter"));
            UserFilterOption::Approver:
                TimeSheetHeader.SetFilter("Approver User ID", Rec.GetFilter("Approve ID Filter"));
        end;
        case TimeSheetStatus of
            TimeSheetStatus::Open:
                TimeSheetHeader.SetRange("Open Exists", true);
            TimeSheetStatus::Submitted:
                TimeSheetHeader.SetRange("Submitted Exists", true);
            TimeSheetStatus::Rejected:
                TimeSheetHeader.SetRange("Rejected Exists", true);
            TimeSheetStatus::Approved:
                TimeSheetHeader.SetRange("Approved Exists", true);
        end;

        case UserFilterOption of
            UserFilterOption::Owner:
                Page.Run(Page::"Time Sheet List", TimeSheetHeader);
            UserFilterOption::Approver:
                Page.Run(Page::"Manager Time Sheet List", TimeSheetHeader);
        end;
    end;
}

