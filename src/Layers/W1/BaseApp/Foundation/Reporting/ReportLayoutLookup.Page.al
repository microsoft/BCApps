// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

using System.Reflection;

page 9651 "Report Layout Lookup"
{
    Caption = 'Insert Built-in Layout for a Report';
    PageType = StandardDialog;

    layout
    {
        area(content)
        {
            group(Control6)
            {
                ShowCaption = false;
            }
            field(ReportID; ReportID)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Report ID';
                Enabled = ShowReportID;
                TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Report));
                ToolTip = 'Specifies the ID of the report.';

                trigger OnValidate()
                begin
                    if not AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Report, ReportID) then
                        Error(ReportNotFoundErr, ReportID);
                end;
            }
            field(ReportName; AllObjWithCaption."Object Caption")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Report Name';
                Enabled = false;
                ToolTip = 'Specifies the name of the report.';
            }
            field(AddWord; AddWord)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Insert Word Layout';
                ToolTip = 'Specifies if you want to create a new RDLC report layout type. If there is a built-in RDLC report layout for the report, then the new custom layout will be based on the built-in layout.';
            }
            field(AddRDLC; AddRDLC)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Insert RDLC Layout';
                ToolTip = 'Specifies if you want to create a new RDLC report layout type. If there is a built-in RDLC report layout for the report, then the new custom layout will be based on the built-in layout.';
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        ShowReportID := ReportID = 0;
        if ReportID <> 0 then
            if AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Report, ReportID) then;
    end;

    var
        AllObjWithCaption: Record AllObjWithCaption;
        ReportID: Integer;
        AddWord: Boolean;
        AddRDLC: Boolean;
#pragma warning disable AA0470
        ReportNotFoundErr: Label 'Report %1 does not exist.';
#pragma warning restore AA0470
        ShowReportID: Boolean;

    procedure SetReportID(NewReportID: Integer)
    begin
        ReportID := NewReportID;
    end;

    procedure SelectedReportID(): Integer
    begin
        exit(ReportID);
    end;

    procedure SelectedAddWordLayot(): Boolean
    begin
        exit(AddWord);
    end;

    procedure SelectedAddRdlcLayot(): Boolean
    begin
        exit(AddRDLC);
    end;

    procedure InitCustomTypeLayouts() LayoutCreated: Boolean;
    begin
        OnInitCustomTypeLayouts(ReportID, LayoutCreated);
    end;

    [IntegrationEvent(true, false)]
    procedure OnInitCustomTypeLayouts(ReportID: Integer; var LayoutCreated: Boolean)
    begin
    end;
}
