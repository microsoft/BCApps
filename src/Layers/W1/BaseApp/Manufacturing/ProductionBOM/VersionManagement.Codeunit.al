// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.ProductionBOM;

using Microsoft.Manufacturing.Routing;

codeunit 99000756 VersionManagement
{
    Permissions = TableData "Production BOM Header" = r;

    trigger OnRun()
    begin
    end;

    procedure GetBOMVersion(BOMHeaderNo: Code[20]; Date: Date; OnlyCertified: Boolean) VersionCode: Code[20]
    var
        ProductionBOMVersion: Record "Production BOM Version";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetBOMVersion(BOMHeaderNo, Date, OnlyCertified, VersionCode, IsHandled);
        if IsHandled then
            exit(VersionCode);

        ProductionBOMVersion.SetCurrentKey("Production BOM No.", "Starting Date");
        ProductionBOMVersion.SetRange("Production BOM No.", BOMHeaderNo);
        ProductionBOMVersion.SetFilter("Starting Date", '%1|..%2', 0D, Date);
        if OnlyCertified then
            ProductionBOMVersion.SetRange(Status, ProductionBOMVersion.Status::Certified)
        else
            ProductionBOMVersion.SetFilter(Status, '<>%1', ProductionBOMVersion.Status::Closed);
        ProductionBOMVersion.SetLoadFields("Version Code");
        OnGetBOMVersionOnBeforeProdBOMVersionFindLast(ProductionBOMVersion, BOMHeaderNo, Date, OnlyCertified);
        if not ProductionBOMVersion.FindLast() then
            exit('');

        exit(ProductionBOMVersion."Version Code");
    end;

    procedure GetBOMUnitOfMeasure(BOMHeaderNo: Code[20]; VersionCode: Code[20]) UoMCode: Code[10]
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMVersion: Record "Production BOM Version";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetBOMUnitOfMeasure(BOMHeaderNo, VersionCode, UoMCode, IsHandled);
        if IsHandled then
            exit(UoMCode);

        if BOMHeaderNo = '' then
            exit('');

        if VersionCode = '' then begin
            ProductionBOMHeader.SetLoadFields("Unit of Measure Code");
            ProductionBOMHeader.Get(BOMHeaderNo);
            exit(ProductionBOMHeader."Unit of Measure Code");
        end;

        ProductionBOMVersion.SetLoadFields("Unit of Measure Code");
        ProductionBOMVersion.Get(BOMHeaderNo, VersionCode);
        exit(ProductionBOMVersion."Unit of Measure Code");
    end;

    procedure GetRtngVersion(RoutingNo: Code[20]; Date: Date; OnlyCertified: Boolean) VersionCode: Code[20]
    var
        RoutingVersion: Record "Routing Version";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetRtngVersion(RoutingNo, Date, OnlyCertified, VersionCode, IsHandled);
        if IsHandled then
            exit(VersionCode);

        RoutingVersion.SetCurrentKey("Routing No.", "Starting Date");
        RoutingVersion.SetRange("Routing No.", RoutingNo);
        RoutingVersion.SetFilter("Starting Date", '%1|..%2', 0D, Date);
        if OnlyCertified then
            RoutingVersion.SetRange(Status, RoutingVersion.Status::Certified)
        else
            RoutingVersion.SetFilter(Status, '<>%1', RoutingVersion.Status::Closed);
        RoutingVersion.SetLoadFields("Version Code");

        if not RoutingVersion.FindLast() then
            exit('');

        exit(RoutingVersion."Version Code");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetBOMVersion(BOMHeaderNo: Code[20]; Date: Date; OnlyCertified: Boolean; var VersionCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetBOMUnitOfMeasure(BOMHeaderNo: Code[20]; VersionCode: Code[20]; var UoMCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetRtngVersion(RoutingNo: Code[20]; Date: Date; OnlyCertified: Boolean; var VersionCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetBOMVersionOnBeforeProdBOMVersionFindLast(var ProductionBOMVersion: Record "Production BOM Version"; BOMHeaderNo: Code[20]; Date: Date; OnlyCertified: Boolean)
    begin
    end;
}

