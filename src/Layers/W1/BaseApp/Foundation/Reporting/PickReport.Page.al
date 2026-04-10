// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

using System.Environment;
using System.Environment.Configuration;
using System.Reflection;

page 1561 "Pick Report"
{
    Caption = 'Pick Report';
    PageType = StandardDialog;

    layout
    {
        area(content)
        {
            group(Settings)
            {
                Caption = 'Settings';
                field(Name; ObjectOptions."Parameter Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Name';
                    NotBlank = true;
                    ToolTip = 'Specifies the name of the new report settings entry.';
                }
                field("Report Name"; ReportName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Report Name';
                    Editable = false;
                }
                field("Report ID"; ObjectOptions."Object ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Report ID';
                    NotBlank = true;
                    TableRelation = "Report Metadata".ID;
                    ToolTip = 'Specifies the ID of the report that uses the settings.';

                    trigger OnValidate()
                    begin
                        UpdateNameFromId(true);
                    end;
                }
                field("Company Name"; ObjectOptions."Company Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Company Name';
                    TableRelation = Company.Name;
                    ToolTip = 'Specifies the company to which the report settings belong.';
                }
                field("Shared with All Users"; ObjectOptions."Public Visible")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Shared with All Users';
                    ToolTip = 'Specifies whether the report settings are available to all users or only the user assigned to the settings.';

                    trigger OnValidate()
                    begin
                        if ObjectOptions."Public Visible" then
                            ObjectOptions."User Name" := '';
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        ObjectOptions."Object Type" := ObjectOptions."Object Type"::Report;
        ObjectOptions."Company Name" := CompanyName;
        ObjectOptions."User Name" := UserId;
        ObjectOptions."Created By" := UserId;
        UpdateNameFromId(false);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::Cancel then
            exit(true);

        if ObjectOptions."Parameter Name" = '' then
            Error(ParameterNameIsEmptyErr);

        exit(true);
    end;

    var
        ObjectOptions: Record "Object Options";
        ParameterNameIsEmptyErr: Label 'Please enter the name.';
        ReportName: Text;
        UnknownReportErr: Label 'Unknown report with ID %1', Comment = '%1 Report object ID (number)';

    procedure GetObjectOptions(var ObjectOptionsToReturn: Record "Object Options")
    begin
        ObjectOptionsToReturn := ObjectOptions;
    end;

    procedure SetReportObjectId(reportObjectId: Integer)
    begin
        ObjectOptions."Object ID" := reportObjectId;
    end;

    local procedure UpdateNameFromId(ThrowError: Boolean)
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        if AllObjWithCaption.Get(ObjectOptions."Object Type"::Report, ObjectOptions."Object ID") then begin
            ReportName := AllObjWithCaption."Object Name";
            exit;
        end;

        ReportName := Format(UnknownReportErr, ObjectOptions."Object ID");

        if ThrowError then
            Error(ReportName);
    end;
}

