// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;
using System.Environment.Configuration;
using System.Reflection;

codeunit 9657 "Report Management Helper"
{
    trigger OnRun()
    begin
        myInt := 1;
    end;

    var
        myInt: Integer;

    procedure IsProcessingOnly(ReportID: Integer): Boolean
    var
        ReportMetadata: Record "Report Metadata";
        status: Boolean;
    begin
        status := false;
        if (ReportMetadata.Get(ReportID)) then
            status := (ReportMetadata.ProcessingOnly = true);
        exit(status);
    end;

    procedure SelectedLayoutType(ReportId: Integer): ReportLayoutType
    var
        ReportMetadata: Record "Report Metadata";
        ReportSelection: Record "Tenant Report Layout Selection";
        ReportLayoutList: Record "Report Layout List";
        AllObj: Record "AllObj";
        LayoutType: Option;
        LayoutName: Text[250];
        AppId: Guid;
    begin
        if ReportId = 0 then
            exit(ReportLayoutType::RDLC);

        if not ReportSelection.Get(ReportId, ReportSelection.CurrentCompany()) then begin
            if not ReportSelection.Get(ReportId) then
                if ReportMetadata.Get(ReportId) then begin
                    LayoutName := ReportMetadata."DefaultLayoutName";
                    if LayoutName = '' then begin
                        LayoutType := ReportMetadata.DefaultLayout;
                        exit(ConvertLayoutType(LayoutType));
                    end else
                        if AllObj.Get(AllObj."Object Type"::Report, ReportId) then
                            AppId := AllObj."App Runtime Package ID";
                end;
        end else
            AppId := ReportSelection."App ID";

        if (ReportLayoutList.Get(ReportId, LayoutName, AppId)) then
            LayoutType := ReportLayoutList."Layout Format";

        exit(ConvertLayoutType(LayoutType));
    end;

    internal procedure GetReportAppId(ReportId: Integer): Guid
    var
        AllObj: Record AllObj;
    begin
        if (AllObj.Get(ReportId)) then
            exit(AllObj."App Package ID");
    end;

    local procedure ConvertLayoutType(LayoutType: Option RDLC,Word,Excel,Custom): ReportLayoutType
    begin
        case LayoutType of
            LayoutType::RDLC:
                exit(ReportLayoutType::RDLC);
            LayoutType::Word:
                exit(ReportLayoutType::Word);
            LayoutType::Excel:
                exit(ReportLayoutType::Excel);
            LayoutType::Custom:
                exit(ReportLayoutType::Custom);
        end;
    end;
}
