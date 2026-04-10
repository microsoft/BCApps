// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Routing;

codeunit 99000753 "Routing Line-Copy Lines"
{

    trigger OnRun()
    begin
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'The %1 cannot be copied to itself.';
        Text001: Label '%1 on %2 %3 must not be %4';
        Text002: Label '%1 on %2 %3 %4 must not be %5';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure CopyRouting(FromRoutingNo: Code[20]; FromVersionCode: Code[20]; var RoutingHeader: Record "Routing Header"; ToVersionCode: Code[20])
    var
        RoutingVersion: Record "Routing Version";
        FromRoutingLine: Record "Routing Line";
        ToRoutingLine: Record "Routing Line";
        FromRoutingTool: Record "Routing Tool";
        ToRoutingTool: Record "Routing Tool";
        FromRoutingPersonnel: Record "Routing Personnel";
        ToRoutingPersonnel: Record "Routing Personnel";
        FromRoutingQualityMeasure: Record "Routing Quality Measure";
        ToRoutingQualityMeasure: Record "Routing Quality Measure";
        FromRoutingCommentLine: Record "Routing Comment Line";
        ToRoutingCommentLine: Record "Routing Comment Line";
    begin
        if (FromRoutingNo = RoutingHeader."No.") and (FromVersionCode = ToVersionCode) then
            Error(Text000, RoutingHeader.TableCaption());

        if ToVersionCode = '' then begin
            if RoutingHeader.Status = RoutingHeader.Status::Certified then
                Error(
                  Text001,
                  RoutingHeader.FieldCaption(Status),
                  RoutingHeader.TableCaption(),
                  RoutingHeader."No.",
                  RoutingHeader.Status);
        end else begin
            RoutingVersion.Get(RoutingHeader."No.", ToVersionCode);
            if RoutingVersion.Status = RoutingVersion.Status::Certified then
                Error(
                  Text002,
                  RoutingVersion.FieldCaption(Status),
                  RoutingVersion.TableCaption(),
                  RoutingVersion."Routing No.",
                  RoutingVersion."Version Code",
                  RoutingVersion.Status);
        end;

        ToRoutingLine.SetRange("Routing No.", RoutingHeader."No.");
        ToRoutingLine.SetRange("Version Code", ToVersionCode);
        ToRoutingLine.DeleteAll(true);

        OnAfterDeleteRouting(RoutingHeader, ToVersionCode);

        FromRoutingLine.SetRange("Routing No.", FromRoutingNo);
        FromRoutingLine.SetRange("Version Code", FromVersionCode);
        if FromRoutingLine.FindSet() then
            repeat
                ToRoutingLine := FromRoutingLine;
                ToRoutingLine."Routing No." := RoutingHeader."No.";
                ToRoutingLine."Version Code" := ToVersionCode;
                ToRoutingLine.Insert();
                OnCopyRountingOnAfterRoutingLineInsert(ToRoutingLine, FromRoutingLine);
            until FromRoutingLine.Next() = 0;

        FromRoutingTool.SetRange("Routing No.", FromRoutingNo);
        FromRoutingTool.SetRange("Version Code", FromVersionCode);
        if FromRoutingTool.Find('-') then
            repeat
                ToRoutingTool := FromRoutingTool;
                ToRoutingTool."Routing No." := RoutingHeader."No.";
                ToRoutingTool."Version Code" := ToVersionCode;
                ToRoutingTool.Insert();
            until FromRoutingTool.Next() = 0;

        FromRoutingPersonnel.SetRange("Routing No.", FromRoutingNo);
        FromRoutingPersonnel.SetRange("Version Code", FromVersionCode);
        if FromRoutingPersonnel.FindSet() then
            repeat
                ToRoutingPersonnel := FromRoutingPersonnel;
                ToRoutingPersonnel."Routing No." := RoutingHeader."No.";
                ToRoutingPersonnel."Version Code" := ToVersionCode;
                ToRoutingPersonnel.Insert();
            until FromRoutingPersonnel.Next() = 0;

        FromRoutingQualityMeasure.SetRange("Routing No.", FromRoutingNo);
        FromRoutingQualityMeasure.SetRange("Version Code", FromVersionCode);
        if FromRoutingQualityMeasure.FindSet() then
            repeat
                ToRoutingQualityMeasure := FromRoutingQualityMeasure;
                ToRoutingQualityMeasure."Routing No." := RoutingHeader."No.";
                ToRoutingQualityMeasure."Version Code" := ToVersionCode;
                ToRoutingQualityMeasure.Insert();
            until FromRoutingQualityMeasure.Next() = 0;

        FromRoutingCommentLine.SetRange("Routing No.", FromRoutingNo);
        FromRoutingCommentLine.SetRange("Version Code", FromVersionCode);
        if FromRoutingCommentLine.FindSet() then
            repeat
                ToRoutingCommentLine := FromRoutingCommentLine;
                ToRoutingCommentLine."Routing No." := RoutingHeader."No.";
                ToRoutingCommentLine."Version Code" := ToVersionCode;
                ToRoutingCommentLine.Insert();
            until FromRoutingCommentLine.Next() = 0;

        OnAfterCopyRouting(RoutingHeader, FromRoutingNo, FromVersionCode, ToVersionCode);
    end;

    procedure SelectCopyFromVersionList(var ToRoutingVersion: Record "Routing Version")
    var
        RoutingHeader: Record "Routing Header";
        FromRoutingVersion: Record "Routing Version";
    begin
        FromRoutingVersion := ToRoutingVersion;

        RoutingHeader."No." := ToRoutingVersion."Routing No.";

        ToRoutingVersion.SetFilter("Version Code", '<>%1', ToRoutingVersion."Version Code");
        if Page.RunModal(0, ToRoutingVersion) = Action::LookupOK then begin
            if FromRoutingVersion.Status = FromRoutingVersion.Status::Certified then
                Error(
                  Text002,
                  FromRoutingVersion.FieldCaption(Status),
                  FromRoutingVersion.TableCaption(),
                  FromRoutingVersion."Routing No.",
                  FromRoutingVersion."Version Code",
                  FromRoutingVersion.Status);
            CopyRouting(RoutingHeader."No.", ToRoutingVersion."Version Code", RoutingHeader, FromRoutingVersion."Version Code");
        end;
        ToRoutingVersion.SetRange("Version Code");

        ToRoutingVersion := FromRoutingVersion;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyRouting(var RoutingHeader: Record "Routing Header"; FromRoutingHeaderNo: Code[20]; FromVersionCode: Code[20]; ToVersionCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteRouting(var RoutingHeader: Record "Routing Header"; ToVersionCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyRountingOnAfterRoutingLineInsert(var RoutingLineTo: Record "Routing Line"; var RoutingLineFrom: Record "Routing Line")
    begin
    end;
}

