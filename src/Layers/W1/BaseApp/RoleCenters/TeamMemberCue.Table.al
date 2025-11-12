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
#if not CLEANSCHEMA29
        field(2; "Open Time Sheets"; Integer)
        {
            CalcFormula = count("Time Sheet Header" where("Open Exists" = filter(= true),
                                                           "Owner User ID" = field("User ID Filter")));
            Caption = 'Time Sheets In progress';
            FieldClass = FlowField;
            AllowInCustomizations = Never;
            ObsoleteReason = 'For performance reasons, replaced by value calculated in CountTimeSheetsInStatus procedure.';
#if not CLEAN26
            ObsoleteState = Pending;
            ObsoleteTag = '26.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '29.0';
#endif
        }
#endif
#if not CLEANSCHEMA29
        field(3; "Submitted Time Sheets"; Integer)
        {
            CalcFormula = count("Time Sheet Header" where("Submitted Exists" = filter(= true),
                                                           "Owner User ID" = field("User ID Filter")));
            Caption = 'Submitted Time Sheets';
            FieldClass = FlowField;
            AllowInCustomizations = Never;
            ObsoleteReason = 'For performance reasons, replaced by value calculated in CountTimeSheetsInStatus procedure.';
#if not CLEAN26
            ObsoleteState = Pending;
            ObsoleteTag = '26.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '29.0';
#endif
        }
#endif
#if not CLEANSCHEMA29
        field(4; "Rejected Time Sheets"; Integer)
        {
            CalcFormula = count("Time Sheet Header" where("Rejected Exists" = filter(= true),
                                                           "Owner User ID" = field("User ID Filter")));
            Caption = 'Rejected Time Sheets';
            FieldClass = FlowField;
            AllowInCustomizations = Never;
            ObsoleteReason = 'For performance reasons, replaced by value calculated in CountTimeSheetsInStatus procedure.';
#if not CLEAN26
            ObsoleteState = Pending;
            ObsoleteTag = '26.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '29.0';
#endif
        }
#endif
#if not CLEANSCHEMA29
        field(5; "Approved Time Sheets"; Integer)
        {
            CalcFormula = count("Time Sheet Header" where("Approved Exists" = filter(= true),
                                                           "Owner User ID" = field("User ID Filter")));
            Caption = 'Approved Time Sheets';
            FieldClass = FlowField;
            AllowInCustomizations = Never;
            ObsoleteReason = 'For performance reasons, replaced by value calculated in CountTimeSheetsInStatus procedure.';
#if not CLEAN26
            ObsoleteState = Pending;
            ObsoleteTag = '26.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '29.0';
#endif
        }
#endif
#if not CLEANSCHEMA29
        field(7; "Time Sheets to Approve"; Integer)
        {
            CalcFormula = count("Time Sheet Header" where("Approver User ID" = field("Approve ID Filter"),
                                                           "Submitted Exists" = const(true)));
            Caption = 'Time Sheets to Approve';
            FieldClass = FlowField;
            AllowInCustomizations = Never;
            ObsoleteReason = 'For performance reasons, replaced by value calculated in CountTimeSheetsInStatus procedure.';
#if not CLEAN26
            ObsoleteState = Pending;
            ObsoleteTag = '26.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '29.0';
#endif
        }
#endif
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

