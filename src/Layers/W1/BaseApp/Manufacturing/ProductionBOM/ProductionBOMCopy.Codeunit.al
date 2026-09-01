// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.ProductionBOM;

codeunit 99000768 "Production BOM-Copy"
{
    TableNo = "Production BOM Header";

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

    procedure CopyBOM(FromProductionBOMNo: Code[20]; FromVersionCode: Code[20]; ProductionBOMHeader: Record "Production BOM Header"; ToVersionCode: Code[20])
    var
        ProductionBOMVersion: Record "Production BOM Version";
        FromProductionBOMLine: Record "Production BOM Line";
        ToProductionBOMLine: Record "Production BOM Line";
        FromProductionBOMCommentLine: Record "Production BOM Comment Line";
        ToProductionBOMCommentLine: Record "Production BOM Comment Line";
        SkipBOMDeletion: Boolean;
        LineNo: Integer;
    begin
        if (ProductionBOMHeader."No." = FromProductionBOMNo) and
           (FromVersionCode = ToVersionCode)
        then
            Error(Text000, ProductionBOMHeader.TableCaption());

        if ToVersionCode = '' then begin
            if ProductionBOMHeader.Status = ProductionBOMHeader.Status::Certified then
                Error(
                  Text001,
                  ProductionBOMHeader.FieldCaption(Status),
                  ProductionBOMHeader.TableCaption(),
                  ProductionBOMHeader."No.",
                  ProductionBOMHeader.Status);
        end else begin
            ProductionBOMVersion.Get(
              ProductionBOMHeader."No.", ToVersionCode);
            if ProductionBOMVersion.Status = ProductionBOMVersion.Status::Certified then
                Error(
                  Text002,
                  ProductionBOMVersion.FieldCaption(Status),
                  ProductionBOMVersion.TableCaption(),
                  ProductionBOMVersion."Production BOM No.",
                  ProductionBOMVersion."Version Code",
                  ProductionBOMVersion.Status);
        end;

        LineNo := 0;
        SkipBOMDeletion := false;
        OnBeforeCopyBOM(ProductionBOMHeader, FromProductionBOMNo, FromVersionCode, ToVersionCode, SkipBOMDeletion, LineNo);
        if not SkipBOMDeletion then begin
            ToProductionBOMLine.SetRange("Production BOM No.", ProductionBOMHeader."No.");
            ToProductionBOMLine.SetRange("Version Code", ToVersionCode);
            ToProductionBOMLine.DeleteAll();

            ToProductionBOMCommentLine.SetRange("Production BOM No.", ProductionBOMHeader."No.");
            ToProductionBOMCommentLine.SetRange("Version Code", ToVersionCode);
            ToProductionBOMCommentLine.DeleteAll();
        end;

        FromProductionBOMLine.SetRange("Production BOM No.", FromProductionBOMNo);
        FromProductionBOMLine.SetRange("Version Code", FromVersionCode);
        if FromProductionBOMLine.FindSet() then
            repeat
                ToProductionBOMLine := FromProductionBOMLine;
                ToProductionBOMLine."Production BOM No." := ProductionBOMHeader."No.";
                ToProductionBOMLine."Version Code" := ToVersionCode;
                if SkipBOMDeletion then
                    ToProductionBOMLine."Line No." := LineNo;
                OnBeforeInsertProdBOMComponent(ToProductionBOMLine, FromProductionBOMLine);
                ToProductionBOMLine.Insert();
                OnAfterInsertProdBOMComponent(ToProductionBOMLine, FromProductionBOMLine, ProductionBOMHeader, SkipBOMDeletion, LineNo);
            until FromProductionBOMLine.Next() = 0;

        if SkipBOMDeletion then
            exit;

        FromProductionBOMCommentLine.SetRange("Production BOM No.", FromProductionBOMNo);
        FromProductionBOMCommentLine.SetRange("Version Code", FromVersionCode);
        if FromProductionBOMCommentLine.FindSet() then
            repeat
                ToProductionBOMCommentLine := FromProductionBOMCommentLine;
                ToProductionBOMCommentLine."Production BOM No." := ProductionBOMHeader."No.";
                ToProductionBOMCommentLine."Version Code" := ToVersionCode;
                ToProductionBOMCommentLine.Insert();
            until FromProductionBOMCommentLine.Next() = 0;

        OnAfterCopyBOM(FromProductionBOMNo, ProductionBOMHeader, FromVersionCode, ToVersionCode);
    end;

    procedure CopyFromVersion(var ToProductionBOMVersion: Record "Production BOM Version")
    var
        ProductionBOMHeader: Record "Production BOM Header";
        FromProductionBOMVersion: Record "Production BOM Version";
    begin
        FromProductionBOMVersion := ToProductionBOMVersion;

        ProductionBOMHeader.Init();
        ProductionBOMHeader."No." := ToProductionBOMVersion."Production BOM No.";

        ToProductionBOMVersion.SetFilter("Version Code", '<>%1', ToProductionBOMVersion."Version Code");
        if Page.RunModal(0, ToProductionBOMVersion) = Action::LookupOK then begin
            if FromProductionBOMVersion.Status = FromProductionBOMVersion.Status::Certified then
                Error(
                  Text002,
                  FromProductionBOMVersion.FieldCaption(Status),
                  FromProductionBOMVersion.TableCaption(),
                  FromProductionBOMVersion."Production BOM No.",
                  FromProductionBOMVersion."Version Code",
                  FromProductionBOMVersion.Status);
            CopyBOM(ProductionBOMHeader."No.", ToProductionBOMVersion."Version Code", ProductionBOMHeader, FromProductionBOMVersion."Version Code");
        end;
        ToProductionBOMVersion.SetRange("Version Code");

        ToProductionBOMVersion := FromProductionBOMVersion;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyBOM(BOMHeaderNo: Code[20]; var CurrentBOMHeader: Record "Production BOM Header"; FromVersionCode: Code[20]; ToVersionCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyBOM(var ProdBOMHeader: Record "Production BOM Header"; BOMHeaderNo: Code[20]; FromVersionCode: Code[20]; ToVersionCode: Code[20]; var SkipBOMDeletion: Boolean; var LineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertProdBOMComponent(var ToProductionBOMLine: Record "Production BOM Line"; var FromProductionBOMLine: Record "Production BOM Line"; var ProductionBOMHeader: Record "Production BOM Header"; var SkipBOMDeletion: Boolean; var LineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertProdBOMComponent(var ToProductionBOMLine: Record "Production BOM Line"; var FromProductionBOMLine: Record "Production BOM Line")
    begin
    end;
}

