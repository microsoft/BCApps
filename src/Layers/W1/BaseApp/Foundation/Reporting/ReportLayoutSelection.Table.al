// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

using System.Environment;
using System.Reflection;

table 9651 "Report Layout Selection"
{
    Caption = 'Report Layout Selection';
    DataPerCompany = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Report ID"; Integer)
        {
            Caption = 'Report ID';
        }
        field(2; "Report Name"; Text[80])
        {
            Caption = 'Report Name';
            Editable = false;
        }
        field(3; "Company Name"; Text[30])
        {
            Caption = 'Company Name';
            TableRelation = Company;
        }
        field(4; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'RDLC,Word,Custom Layout,Excel,External';
            OptionMembers = "RDLC (built-in)","Word (built-in)","Custom Layout","Excel Layout","External Layout";

            trigger OnValidate()
            begin
                TestField("Report ID");
                CalcFields("Report Caption");
                "Report Name" := "Report Caption";
                case Type of
                    Type::"RDLC (built-in)":
                        begin
                            if not HasRdlcLayout("Report ID") then
                                Error(NoRdlcLayoutErr, "Report Name");
                            "Custom Report Layout Code" := '';
                        end;
                    Type::"Word (built-in)":
                        begin
                            if not HasWordLayout("Report ID") then
                                Error(NoWordLayoutErr, "Report Name");
                            "Custom Report Layout Code" := '';
                        end;
                    Type::"Excel Layout":
                        begin
                            if not HasExcelLayout("Report ID") then
                                Error(NoExcelLayoutErr, "Report Name");
                            "Custom Report Layout Code" := '';
                        end;
                    Type::"External Layout":
                        begin
                            if not HasExternalLayout("Report ID") then
                                Error(NoExternalLayoutErr, "Report Name");
                            "Custom Report Layout Code" := '';
                        end;
                end;
            end;
        }
        field(6; "Custom Report Layout Code"; Code[20])
        {
            Caption = 'Custom Report Layout Code';
            TableRelation = "Custom Report Layout" where("Report ID" = field("Report ID"));

            trigger OnValidate()
            begin
                if "Custom Report Layout Code" = '' then
                    Type := GetDefaultType("Report ID")
                else
                    Type := Type::"Custom Layout";
            end;
        }
        field(7; "Report Layout Description"; Text[250])
        {
            CalcFormula = lookup("Custom Report Layout".Description where(Code = field("Custom Report Layout Code")));
            Caption = 'Report Layout Description';
            FieldClass = FlowField;
        }
        field(8; "Report Caption"; Text[80])
        {
            CalcFormula = lookup("Report Metadata".Caption where(ID = field("Report ID")));
            Caption = 'Report Caption';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Report ID", "Company Name")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        TestField("Report ID");
        if "Company Name" = '' then
            "Company Name" := CompanyName;
    end;

    var
        NoRdlcLayoutErr: Label 'Report ''%1'' has no RDLC layout.', Comment = '%1=a report name';
        NoWordLayoutErr: Label 'Report ''%1'' has no Word layout.', Comment = '%1=a report name';
        NoExcelLayoutErr: Label 'Report ''%1'' has no Excel layout.', Comment = '%1=a report name';
        NoExternalLayoutErr: Label 'Report ''%1'' has no External layout.', Comment = '%1=a report name';

    procedure GetDefaultType(ReportID: Integer): Integer
    var
        ReportMetadata: Record "Report Metadata";
    begin
        if not ReportMetadata.Get(ReportID) then
            exit(Type::"RDLC (built-in)");

        case ReportMetadata.DefaultLayout of
            ReportMetadata.DefaultLayout::Word:
                exit(Type::"Word (built-in)");
            ReportMetadata.DefaultLayout::Excel:
                exit(Type::"Excel Layout");
            ReportMetadata.DefaultLayout::RDLC:
                exit(Type::"RDLC (built-in)");
            ReportMetadata.DefaultLayout::Custom:
                exit(Type::"External Layout");
        end;
    end;

#if not CLEAN25
    [Obsolete('Moved to codeunit Report Management Helper', '25.0')]
    procedure IsProcessingOnly(ReportID: Integer): Boolean
    var
        ReportManagementHelper: Codeunit "Report Management Helper";
    begin
        exit(ReportManagementHelper.IsProcessingOnly(ReportID));
    end;
#endif

    internal procedure HasLayoutOfType(ReportID: Integer; LayoutType: ReportLayoutType): Boolean
    begin
        case LayoutType of
            ReportLayoutType::RDLC:
                exit(HasRdlcLayout(ReportID));
            ReportLayoutType::Word:
                exit(HasWordLayout(ReportID));
            ReportLayoutType::Excel:
                exit(HasExcelLayout(ReportID));
            ReportLayoutType::Custom:
                exit(HasExternalLayout(ReportID));
        end;

        exit(false)
    end;

    local procedure HasRdlcLayout(ReportID: Integer): Boolean
    var
        ReportLayoutList: Record "Report Layout List";
    begin
        ReportLayoutList.SetFilter("Report ID", '=%1', ReportID);
        ReportLayoutList.SetFilter("Layout Format", '=%1', ReportLayoutList."Layout Format"::RDLC);
        exit(not ReportLayoutList.IsEmpty());
    end;

    procedure HasWordLayout(ReportID: Integer): Boolean
    var
        ReportLayoutList: Record "Report Layout List";
    begin
        ReportLayoutList.SetFilter("Report ID", '=%1', ReportID);
        ReportLayoutList.SetFilter("Layout Format", '=%1', ReportLayoutList."Layout Format"::Word);
        exit(not ReportLayoutList.IsEmpty());
    end;

    local procedure HasExcelLayout(ReportID: Integer): Boolean
    var
        ReportLayoutList: Record "Report Layout List";
    begin
        ReportLayoutList.SetFilter("Report ID", '=%1', ReportID);
        ReportLayoutList.SetFilter("Layout Format", '=%1', ReportLayoutList."Layout Format"::Excel);
        exit(not ReportLayoutList.IsEmpty());
    end;

    procedure HasExternalLayout(ReportID: Integer): Boolean
    var
        ReportLayoutList: Record "Report Layout List";
    begin
        ReportLayoutList.SetFilter("Report ID", '=%1', ReportID);
        ReportLayoutList.SetFilter("Layout Format", '=%1', ReportLayoutList."Layout Format"::Custom);
        exit(not ReportLayoutList.IsEmpty());
    end;

#if not CLEAN25
    [Obsolete('Obsolete programming model. Replaced by HasExternalLayout', '25.0')]
    procedure HasCustomLayout(ReportID: Integer): Integer
    var
        CustomReportLayout: Record "Custom Report Layout";
    begin
        // Temporarily selected layout for Design-time report execution?
        if GetTempLayoutSelected() <> '' then
            if CustomReportLayout.Get(GetTempLayoutSelected()) then begin
                if CustomReportLayout.Type = CustomReportLayout.Type::RDLC then
                    exit(1);
                exit(2);
            end;

        // Normal selection
        exit(HasNormalCustomLayoutSelection(ReportID));
    end;
#endif

    procedure SelectedBuiltinLayoutType(ReportID: Integer): Integer
    begin
        if not Get(ReportID, CompanyName) then
            exit(0);
        case Type of
            Type::"RDLC (built-in)":
                exit(1);
            Type::"Word (built-in)":
                exit(2);
            Type::"Excel Layout":
                exit(3);
            Type::"External Layout":
                exit(4);
            else
                exit(0);
        end;
    end;

#pragma warning disable AS0072
#if not CLEAN25
    [Obsolete('Obsolete programming model. Replaced by HasExternalLayout', '25.0')]
    local procedure HasNormalCustomLayoutSelection(ReportID: Integer) Result: Integer
    var
        CustomReportLayout: Record "Custom Report Layout";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeHasNormalCustomLayoutSelection(ReportID, Result, IsHandled, Rec);
        if IsHandled then
            exit;

        if not Get(ReportID, CompanyName) then
            exit(0);
        case Type of
            Type::"Custom Layout":
                begin
                    if not CustomReportLayout.Get("Custom Report Layout Code") then
                        exit(0);
                    if CustomReportLayout.Type = CustomReportLayout.Type::RDLC then
                        exit(1);
                    if CustomReportLayout.Type = CustomReportLayout.Type::Word then
                        exit(2);
                end;
            else
                exit(0);
        end;
    end;
#endif
#pragma warning restore AS0072

    procedure GetTempLayoutSelected(): Code[20]
    var
        DesignTimeReportSelection: Codeunit "Design-time Report Selection";
    begin
        exit(DesignTimeReportSelection.GetSelectedCustomLayout());
    end;

    procedure GetTempSelectedLayoutName(): Text[250]
    var
        DesignTimeReportSelection: Codeunit "Design-time Report Selection";
    begin
        exit(DesignTimeReportSelection.GetSelectedLayout());
    end;

    procedure SetTempLayoutSelected(NewTempSelectedLayoutCode: Code[20])
    var
        DesignTimeReportSelection: Codeunit "Design-time Report Selection";
    begin
        DesignTimeReportSelection.SetSelectedCustomLayout(NewTempSelectedLayoutCode);
    end;

    procedure SetTempLayoutSelectedName(NewTempSelectedLayoutName: Text[250]; AppID: Guid)
    var
        DesignTimeReportSelection: Codeunit "Design-time Report Selection";
    begin
        DesignTimeReportSelection.SetSelectedLayout(NewTempSelectedLayoutName, AppID);
    end;

    procedure SetTempLayoutSelectedName(NewTempSelectedLayoutName: Text[250])
    var
        DesignTimeReportSelection: Codeunit "Design-time Report Selection";
    begin
        DesignTimeReportSelection.SetSelectedLayout(NewTempSelectedLayoutName);
    end;

    procedure ClearTempLayoutSelected()
    var
        DesignTimeReportSelection: Codeunit "Design-time Report Selection";
    begin
        DesignTimeReportSelection.SetSelectedCustomLayout('');
        DesignTimeReportSelection.SetSelectedLayout('');
    end;

#pragma warning disable AS0072
#if not CLEAN25
    [Obsolete('Obsolete programming model. Replaced by HasExternalLayout', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeHasNormalCustomLayoutSelection(ReportID: Integer; var Result: Integer; var Handled: Boolean; var ReportLayoutSelectionRec: Record "Report Layout Selection")
    begin
    end;
#endif
#pragma warning restore AS0072
}

