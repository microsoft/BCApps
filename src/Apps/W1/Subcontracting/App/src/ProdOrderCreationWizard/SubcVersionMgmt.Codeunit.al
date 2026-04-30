// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;

codeunit 99001553 "Subc. Version Mgmt."
{
    var
        VersionManagement: Codeunit VersionManagement;

    procedure ShowBOMVersionSelection(ProductionBOMNo: Code[20]; var SelectedVersion: Code[20]): Boolean
    var
        ProductionBOMVersion: Record "Production BOM Version";
        ProdBOMVersionList: Page "Prod. BOM Version List";
    begin
        if ProductionBOMNo = '' then
            exit(false);

        ProductionBOMVersion.SetRange("Production BOM No.", ProductionBOMNo);
        ProductionBOMVersion.SetRange(Status, "BOM Status"::Certified);
        ProdBOMVersionList.SetTableView(ProductionBOMVersion);
        ProdBOMVersionList.LookupMode(true);

        if ProdBOMVersionList.RunModal() = Action::LookupOK then begin
            ProdBOMVersionList.GetRecord(ProductionBOMVersion);
            SelectedVersion := ProductionBOMVersion."Version Code";
            exit(true);
        end;

        exit(false);
    end;

    procedure ShowRoutingVersionSelection(RoutingNo: Code[20]; var SelectedVersion: Code[20]): Boolean
    var
        RoutingVersion: Record "Routing Version";
        RoutingVersionList: Page "Routing Version List";
    begin
        if RoutingNo = '' then
            exit(false);

        RoutingVersion.SetRange("Routing No.", RoutingNo);
        RoutingVersion.SetRange(Status, "Routing Status"::Certified);
        RoutingVersionList.SetTableView(RoutingVersion);
        RoutingVersionList.LookupMode(true);

        if RoutingVersionList.RunModal() = Action::LookupOK then begin
            RoutingVersionList.GetRecord(RoutingVersion);
            SelectedVersion := RoutingVersion."Version Code";
            exit(true);
        end;

        exit(false);
    end;

    procedure GetDefaultBOMVersion(ProductionBOMNo: Code[20]): Code[20]
    begin
        exit(VersionManagement.GetBOMVersion(ProductionBOMNo, WorkDate(), true));
    end;

    procedure GetDefaultRoutingVersion(RoutingNo: Code[20]): Code[20]
    begin
        exit(VersionManagement.GetRtngVersion(RoutingNo, WorkDate(), true));
    end;

    procedure ShowBOMSelection(var SelectedBOMNo: Code[20]): Boolean
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMList: Page "Production BOM List";
    begin
        ProductionBOMHeader.SetRange(Status, "BOM Status"::Certified);
        ProductionBOMList.SetTableView(ProductionBOMHeader);
        ProductionBOMList.LookupMode(true);

        if ProductionBOMList.RunModal() = Action::LookupOK then begin
            ProductionBOMList.GetRecord(ProductionBOMHeader);
            SelectedBOMNo := ProductionBOMHeader."No.";
            exit(true);
        end;

        exit(false);
    end;

    procedure ShowRoutingSelection(var SelectedRoutingNo: Code[20]): Boolean
    var
        RoutingHeader: Record "Routing Header";
        RoutingList: Page "Routing List";
    begin
        RoutingHeader.SetRange(Status, "Routing Status"::Certified);
        RoutingList.SetTableView(RoutingHeader);
        RoutingList.LookupMode(true);
        if RoutingList.RunModal() = Action::LookupOK then begin
            RoutingList.GetRecord(RoutingHeader);
            SelectedRoutingNo := RoutingHeader."No.";
            exit(true);
        end;

        exit(false);
    end;

    procedure CheckRoutingExists(RoutingNo: Code[20]; RoutingVersionCode: Code[20]): Boolean
    var
        RoutingHeader: Record "Routing Header";
        RoutingVersion: Record "Routing Version";
    begin
        if RoutingVersionCode <> '' then begin
            RoutingVersion.SetLoadFields(SystemId);
            exit(RoutingVersion.Get(RoutingNo, RoutingVersionCode));
        end;

        RoutingHeader.SetLoadFields(SystemId);
        exit(RoutingHeader.Get(RoutingNo));
    end;

    procedure TestRoutingCertified(RoutingNo: Code[20]; RoutingVersionCode: Code[20])
    var
        RoutingHeader: Record "Routing Header";
        RoutingVersion: Record "Routing Version";
    begin
        if RoutingNo = '' then
            exit;

        RoutingVersion.SetLoadFields(Status);
        if RoutingVersion.Get(RoutingNo, RoutingVersionCode) then
            RoutingVersion.TestField(Status, "Routing Status"::Certified);

        RoutingHeader.SetLoadFields(Status);
        if RoutingHeader.Get(RoutingNo) then
            RoutingHeader.TestField(Status, "Routing Status"::Certified);
    end;

    procedure CheckBOMExists(ProductionBOMNo: Code[20]; BOMVersionCode: Code[20]): Boolean
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMVersion: Record "Production BOM Version";
    begin
        if BOMVersionCode <> '' then begin
            ProductionBOMVersion.SetLoadFields(SystemId);
            exit(ProductionBOMVersion.Get(ProductionBOMNo, BOMVersionCode));
        end;

        ProductionBOMHeader.SetLoadFields(SystemId);
        exit(ProductionBOMHeader.Get(ProductionBOMNo));
    end;

    procedure TestBOMCertified(ProductionBOMNo: Code[20]; BOMVersionCode: Code[20])
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMVersion: Record "Production BOM Version";
    begin
        if ProductionBOMNo = '' then
            exit;

        ProductionBOMVersion.SetLoadFields(Status);
        if ProductionBOMVersion.Get(ProductionBOMNo, BOMVersionCode) then
            ProductionBOMVersion.TestField(Status, "BOM Status"::Certified);

        ProductionBOMHeader.SetLoadFields(Status);
        if ProductionBOMHeader.Get(ProductionBOMNo) then
            ProductionBOMHeader.TestField(Status, "BOM Status"::Certified);
    end;

    procedure GetBOMVersionNoSeries(ProductionBOMNo: Code[20]): Code[20]
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        ProductionBOMHeader.SetLoadFields("Version Nos.");
        ProductionBOMHeader.Get(ProductionBOMNo);
        ProductionBOMHeader.TestField("Version Nos.");
        exit(ProductionBOMHeader."Version Nos.");
    end;

    procedure GetRoutingVersionNoSeries(RoutingNo: Code[20]): Code[20]
    var
        RoutingHeader: Record "Routing Header";
    begin
        RoutingHeader.SetLoadFields("Version Nos.");
        RoutingHeader.Get(RoutingNo);
        RoutingHeader.TestField("Version Nos.");
        exit(RoutingHeader."Version Nos.");
    end;
}