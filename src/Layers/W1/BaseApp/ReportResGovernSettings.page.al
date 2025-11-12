// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Environment.Configuration;

using System.Apps;
using System.Globalization;
using System.Reflection;

page 9882 "Report Res. Govern. Settings"
{
    Caption = 'Report Limits and Settings';
    PageType = List;
    ApplicationArea = All;
    AdditionalSearchTerms = 'Report Timeout, timeout, format region';
    UsageCategory = Administration;
    Permissions = Tabledata "Report Settings Override" = rimd;
    SourceTable = AllObjWithCaption;
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = true;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(ObjID; Rec."Object ID")
                {
                    ApplicationArea = All;
                    Caption = 'Report ID';
                    Tooltip = 'Specifies the Report number.';
                    Editable = false;
                }
                field(ObjName; Rec."Object Name")
                {
                    ApplicationArea = All;
                    Caption = 'Report Name';
                    Tooltip = 'Specifies the Report name.';
                    Editable = false;
                }
                field(ObjCaption; Rec."Object Caption")
                {
                    ApplicationArea = All;
                    Caption = 'Report Caption';
                    Tooltip = 'Specifies the Report caption as shown to the user.';
                    Editable = false;
                }
                field(TimeOut; TempTimeOut)
                {
                    ApplicationArea = All;
                    Caption = 'Report Timeout (Duration)';
                    Tooltip = 'Specifies the timeout duration for the report. The default timeout duration is 6 hours. To use the default, leave it empty.';
                    trigger OnValidate()
                    begin
                        if TempTimeOut > MaxTimeOut then
                            Error(ExceedMaxTimeOutMsg, TempTimeOut);
                        if TempTimeOut < MinTimeOut then
                            Error(ExceedMinTimeOutMsg, TempTimeOut);
                        TempReportSettingsOverride.Timeout := TempTimeOut div 1000;
                        updateOverrideValues();
                    end;
                }
                field(MaxRowsField; TempReportSettingsOverride.MaxRows)
                {
                    Caption = 'Max Rows';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the maximum number of rows that can be included in this report. If exceeded, the report will be canceled.';
                    trigger OnValidate()
                    begin
                        if TempReportSettingsOverride.MaxRows < MinimumRowLimit then
                            Error(ValueTooSmallErrorMsg, MinimumRowLimit);
                        updateOverrideValues();
                    end;
                }
                field(MaxDocumentsField; TempReportSettingsOverride.MaxDocuments)
                {
                    Caption = 'Max Documents';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the maximum number of documents that can be merged for this type of report. This applies only if the report uses Microsoft Word. If exceeded, the report will be canceled.';

                    trigger OnValidate()
                    begin
                        if TempReportSettingsOverride.MaxDocuments < MinimumDocumentLimit then
                            Error(ValueTooSmallErrorMsg, MinimumDocumentLimit);
                        updateOverrideValues();
                    end;
                }
                field(FormatRegion; TempReportSettingsOverride."Format Language Tag")
                {
                    Caption = 'Format Region';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the format region to be used for formatting values with regional dependencies.';
                    TableRelation = "Language Selection"."Language Tag";

                    trigger OnValidate()
                    var
                        WindowsCultures: Record "Windows Language";
                        DotNet_CultureInfo: Codeunit DotNet_CultureInfo;
                    begin

                        if (TempReportSettingsOverride."Format Language Tag" <> '') then begin
                            // The VT is case sensitive so make sure that the string entered by the user follows the casing defined by the
                            // culture info object. Cannot use a lookup with table relation to the Language Tag field as there is an old 
                            // requirement regarding PK membership.
                            DotNet_CultureInfo.GetCultureInfoByName(TempReportSettingsOverride."Format Language Tag");
                            TempReportSettingsOverride."Format Language Tag" := CopyStr(DotNet_CultureInfo.Name(), 1, MaxStrLen(TempReportSettingsOverride."Format Language Tag"));
                            WindowsCultures.SetFilter(WindowsCultures."Language Tag", TempReportSettingsOverride."Format Language Tag");
                            if (WindowsCultures.IsEmpty) then
                                Error(LanguageTagNotFoundErrorMsg, TempReportSettingsOverride."Format Language Tag");
                        end;
                        updateOverrideValues();
                    end;
                }
                field(ApplicationLanguage; TempReportSettingsOverride."Language ID")
                {
                    Caption = 'Language';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the application language to be used for the specified report.';
                    TableRelation = "Language Selection"."Language Id" where(Enabled = const(true));

                    trigger OnValidate()
                    var
                        LanguageSelection: Record "Language Selection";
                    begin

                        if (TempReportSettingsOverride."Language ID" <> 0) then begin
                            LanguageSelection.SetFilter(LanguageSelection."Language ID", format(TempReportSettingsOverride."Language ID"));

                            if (LanguageSelection.IsEmpty) then
                                Error(LanguageIdNotFoundErrorMsg, TempReportSettingsOverride."Language ID");

                            if LanguageSelection.FindFirst() then
                                if (not LanguageSelection.Enabled) then
                                    Error(LanguageNotEnabledErrorMsg, TempReportSettingsOverride."Language ID");
                        end;

                        updateOverrideValues();
                    end;
                }
                field(AppName; TempPublishedApplication.Name)
                {
                    ApplicationArea = All;
                    Caption = 'Application Name';
                    Tooltip = 'Specifies the application or extension that the object belongs to.';
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RunObject)
            {
                ApplicationArea = All;
                Image = Process;
                Caption = 'Run Report';
                ToolTip = 'Run the Report to test the settings.';

                trigger OnAction()
                begin
                    case Rec."Object Type" of
                        Rec."Object Type"::Report:
                            Report.RunModal(Rec."Object ID");
                        else
                            message(NotSupportedTypeMsg, Rec."Object Type");
                    end;
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(RunObject_Promoted; RunObject)
                {
                }
            }
        }
    }
    local procedure updateOverrideValues();
    begin
        ReportSettingsOverride := TempReportSettingsOverride;
        if ReportSettingsOverride.find() then
            if ReportSettingsOverride.delete() then;
        if TempReportSettingsOverride.delete() then;
        if ReportSettingsOverride.find() then begin
            ReportSettingsOverride := TempReportSettingsOverride;
            if ReportSettingsOverride.modify() then;
            if TempReportSettingsOverride.modify() then;
        end else begin
            ReportSettingsOverride := TempReportSettingsOverride;
            if ReportSettingsOverride.insert() then;
            if TempReportSettingsOverride.insert() then;
        end;
    end;

    var

        TempReportSettingsOverride: Record "Report Settings Override" temporary;
        ReportSettingsOverride: Record "Report Settings Override";
        TempPublishedApplication: Record "Published Application" temporary;
        MinimumRowLimit: Integer;
        MinimumDocumentLimit: Integer;
        MinTimeOut: Duration;
        MaxTimeOut: Duration;
        TempTimeOut: Duration;
        NotSupportedTypeMsg: Label 'You cannot run an object of type %1.', Comment = '%1 Other object than Report';
        ExceedMinTimeOutMsg: Label 'The value %1 is lower than the minimum time allowed.', Comment = '%1 value as duration';
        ExceedMaxTimeOutMsg: Label 'The value %1 is higher than the maximum time allowed.', Comment = '%1 value as duration';
        ValueTooSmallErrorMsg: Label 'The value must be greater than or equal to %1.', Comment = '%1 value as duration';
        LanguageTagNotFoundErrorMsg: Label 'The specified format region %1 does not exist.', Comment = '%1 language tag';
        LanguageIdNotFoundErrorMsg: Label 'The specified language %1 does not exist.', Comment = '%1 language id';
        LanguageNotEnabledErrorMsg: Label 'The specified language %1 is not enabled.', Comment = '%1 language id';

    trigger OnOpenPage()
    var
        PublishedApplication: Record "Published Application";
    begin
        Rec.SetRange(Rec."Object Type", Rec."Object Type"::Report);
        MinimumDocumentLimit := 0;
        MinimumRowLimit := 0;
        MinTimeOut := 0;
        MaxTimeOut := 43200000;

        if ReportSettingsOverride.FindSet() then
            repeat
                TempReportSettingsOverride := ReportSettingsOverride;
                if TempReportSettingsOverride.Insert() then;
            until ReportSettingsOverride.Next() = 0;

        if PublishedApplication.FindSet() then
            repeat
                TempPublishedApplication := PublishedApplication;
                if TempPublishedApplication.Insert() then;
            until PublishedApplication.Next() = 0;
    end;

    trigger OnAfterGetRecord()
    begin
        if not TempReportSettingsOverride.Get(Rec."Object ID") then begin
            Clear(TempReportSettingsOverride);
            TempReportSettingsOverride."Object ID" := Rec."Object ID";
        end;
        TempTimeOut := TempReportSettingsOverride.Timeout * 1000; //Convert seconds to milliseconds to support Duration
        if Rec."App Package ID" <> TempPublishedApplication."Package ID" then begin
            TempPublishedApplication.SetRange("Package ID", Rec."App Package ID");
            TempPublishedApplication.SetRange("Tenant Visible", true);
            if not TempPublishedApplication.FindFirst() then
                TempPublishedApplication.Init();
        end;
    end;
}
