// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Security.User;

using System.Environment;
using System.Security.AccessControl;
using System.Utilities;

/// <summary>
/// Shows detailed user information, such as unique identifiers, information about permission sets etc.
/// </summary>
page 774 "User Details"
{
    AboutText = 'View detailed information about users, including unique identifiers, permission sets, and login activity. Search and filter the list to find specific users.';
    AboutTitle = 'About the users detailed view';
    ApplicationArea = Basic, Suite;
    Caption = 'Users (Detailed View)';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "User Details";
    SourceTableTemporary = true;

    layout
    {
        area(Content)
        {
            repeater(UserDetailsRepeater)
            {
                field("User Name"; Rec."User Name")
                {
                    ToolTip = 'Specifies the user''s name.';
                }
                field("Full Name"; Rec."Full Name")
                {
                    ToolTip = 'Specifies the full name of the user.';
                }
                field(State; Rec.State)
                {
                    Caption = 'Status';
                    ToolTip = 'Specifies whether the user can access companies in the current environment.';
                }
                field("Contact Email"; Rec."Contact Email")
                {
                    ExtendedDatatype = EMail;
                    ToolTip = 'Specifies the user''s email address.';
                }
                field("User Security ID"; Rec."User Security ID")
                {
                    ToolTip = 'Specifies an ID that uniquely identifies the user.';
                }
                field("Telemetry User ID"; Rec."Telemetry User ID")
                {
                    ToolTip = 'Specifies a telemetry ID which can be used for troubleshooting purposes.';
                }
                field("Authentication Email"; Rec."Authentication Email")
                {
                    ExtendedDatatype = EMail;
                    ToolTip = 'Specifies the Microsoft account that this user signs into Microsoft 365 or SharePoint Online with.';
                    Visible = IsSaaS;
                }
                field("Authentication Object ID"; Rec."Authentication Object ID")
                {
                    ToolTip = 'Specifies ID assigned to the user in Microsoft Entra.';
                    Visible = IsSaaS;
                }
                field("Last Login Date"; Rec."Last Login Date")
                {
                    Caption = 'Last Login Date';
                    ToolTip = 'Specifies the date and time when the user last logged in.';
                }
                field("Inactive Days"; InactiveDays)
                {
                    Caption = 'Inactive (days)';
                    ToolTip = 'Specifies the number of days since the user last logged in.';
                }
                field(SystemCreatedAt; Rec."User System Created At")
                {
                    Caption = 'Created On';
                    ToolTip = 'Specifies the date and time when the user record was created.';
                }
                field(CreatedBy; CreatedByUser."User Name")
                {
                    Caption = 'Created By';
                    ToolTip = 'Specifies the user who created the user record.';
                }
                field(SystemModifiedAt; Rec."User System Modified At")
                {
                    Caption = 'Modified On';
                    ToolTip = 'Specifies the date and time when the user record was last modified.';
                }
                field(ModifiedBy; ModifiedByUser."User Name")
                {
                    Caption = 'Modified By';
                    ToolTip = 'Specifies the user who last modified the user record.';
                }
                // Can be added with "Personalize"
                field("Has SUPER permission set"; Rec."Has SUPER permission set")
                {
                    ToolTip = 'Specifies if the SUPER permission set is assigned to the user.';
                    Visible = false;
                }
            }
        }
    }

    views
    {
        view(ActiveUsers)
        {
            Caption = 'Active users';
            Filters = where(State = const(Enabled));
        }
        view(SuperUsers)
        {
            Caption = 'Users with SUPER permission set';
            Filters = where("Has SUPER permission set" = const(true));
        }
        view(Inactive7Days)
        {
            Caption = 'Inactive 7+ days';
            Filters = where("Inactive Days Date Filter" = const("7 Days"));
        }
        view(Inactive30Days)
        {
            Caption = 'Inactive 30+ days';
            Filters = where("Inactive Days Date Filter" = const("30 Days"));
        }
        view(Inactive90Days)
        {
            Caption = 'Inactive 90+ days';
            Filters = where("Inactive Days Date Filter" = const("90 Days"));
        }
    }

    trigger OnOpenPage()
    var
        EnvironmentInformation: Codeunit "Environment Information";
        UserDetails: Codeunit "User Details";
    begin
        IsSaaS := EnvironmentInformation.IsSaaS();
        UserDetails.Get(Rec);
    end;

    trigger OnFindRecord(Which: Text): Boolean
    var
        UserDetails: Record "User Details";
    begin
        if Rec.GetFilter("Inactive Days Date Filter") <> '' then
            if Evaluate(UserDetails."Inactive Days Date Filter", Rec.GetFilter("Inactive Days Date Filter")) then
                ApplyInactiveDaysFilter(UserDetails."Inactive Days Date Filter")
            else
                ApplyInactiveDaysFilter(UserDetails."Inactive Days Date Filter"::Blank)
        else
            ApplyInactiveDaysFilter(UserDetails."Inactive Days Date Filter"::Blank);

        exit(Rec.Find(Which));
    end;

    trigger OnAfterGetRecord()
    var
        Math: Codeunit Math;
    begin
        Rec.CalcFields("User System Created By", "User System Modified By");
        Clear(CreatedByUser);
        Clear(ModifiedByUser);
        if CreatedByUser.Get(Rec."User System Created By") then;
        if ModifiedByUser.Get(Rec."User System Modified By") then;
        InactiveDays := 0;
        if Rec."Last Login Date".Date <> 0D then
            InactiveDays := Math.Floor(Today() - Rec."Last Login Date".Date);
    end;

    var
        CreatedByUser: Record User;
        ModifiedByUser: Record User;
        InactiveDays: Integer;

    protected var
        IsSaaS: Boolean;

    local procedure ApplyInactiveDaysFilter(DateFilter: Enum "User Detail Date Filter")
    var
        OriginalFilterGroup: Integer;
    begin
        OriginalFilterGroup := Rec.FilterGroup();
        Rec.FilterGroup(100);
        Rec.SetRange("Last Login Date");

        case DateFilter of
            DateFilter::"7 Days":
                Rec.SetFilter("Last Login Date", '<=%1', CreateDateTime(CalcDate('<-7D>', Today()), 235959T));
            DateFilter::"30 Days":
                Rec.SetFilter("Last Login Date", '<=%1', CreateDateTime(CalcDate('<-30D>', Today()), 235959T));
            DateFilter::"90 Days":
                Rec.SetFilter("Last Login Date", '<=%1', CreateDateTime(CalcDate('<-90D>', Today()), 235959T));
            DateFilter::Blank:
                ;
            else
                OnInactiveDaysFilterCaseElse(DateFilter, Rec);
        end;

        Rec.FilterGroup(OriginalFilterGroup);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInactiveDaysFilterCaseElse(DateFilter: Enum "User Detail Date Filter"; var Rec: Record "User Details")
    begin
    end;
}