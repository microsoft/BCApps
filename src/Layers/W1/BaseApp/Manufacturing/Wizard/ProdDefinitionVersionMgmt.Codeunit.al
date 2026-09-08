// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Wizard;

using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;

codeunit 99001015 "Prod. Definition Version Mgmt."
{
    var
        VersionManagement: Codeunit VersionManagement;

    /// <summary>
    /// Opens a lookup page for certified Production BOM versions and returns the selected version code.
    /// </summary>
    /// <param name="ProductionBOMNo">The production BOM number to filter versions for.</param>
    /// <param name="SelectedVersion">Returns the version code selected by the user.</param>
    /// <returns>True if the user selected a version; false if cancelled or no BOM number provided.</returns>
    internal procedure ShowBOMVersionSelection(ProductionBOMNo: Code[20]; var SelectedVersion: Code[20]): Boolean
    var
        ProductionBOMVersion: Record "Production BOM Version";
        ProductionBOMVersions: Page "Prod. BOM Version List";
    begin
        if ProductionBOMNo = '' then
            exit(false);

        ProductionBOMVersion.SetRange("Production BOM No.", ProductionBOMNo);
        ProductionBOMVersion.SetRange(Status, "BOM Status"::Certified);
        ProductionBOMVersions.SetTableView(ProductionBOMVersion);
        ProductionBOMVersions.LookupMode(true);

        if ProductionBOMVersions.RunModal() = Action::LookupOK then begin
            ProductionBOMVersions.GetRecord(ProductionBOMVersion);
            SelectedVersion := ProductionBOMVersion."Version Code";
            exit(true);
        end;

        exit(false);
    end;

    /// <summary>
    /// Opens a lookup page for certified routing versions and returns the selected version code.
    /// </summary>
    /// <param name="RoutingNo">The routing number to filter versions for.</param>
    /// <param name="SelectedVersion">Returns the version code selected by the user.</param>
    /// <returns>True if the user selected a version; false if cancelled or no routing number provided.</returns>
    internal procedure ShowRoutingVersionSelection(RoutingNo: Code[20]; var SelectedVersion: Code[20]): Boolean
    var
        RoutingVersion: Record "Routing Version";
        RoutingVersions: Page "Routing Version List";
    begin
        if RoutingNo = '' then
            exit(false);

        RoutingVersion.SetRange("Routing No.", RoutingNo);
        RoutingVersion.SetRange(Status, "Routing Status"::Certified);
        RoutingVersions.SetTableView(RoutingVersion);
        RoutingVersions.LookupMode(true);

        if RoutingVersions.RunModal() = Action::LookupOK then begin
            RoutingVersions.GetRecord(RoutingVersion);
            SelectedVersion := RoutingVersion."Version Code";
            exit(true);
        end;

        exit(false);
    end;

    /// <summary>
    /// Returns the default active BOM version code for a given production BOM as of the work date.
    /// </summary>
    /// <param name="ProductionBOMNo">The production BOM number to retrieve the default version for.</param>
    /// <returns>The default version code, or empty if none exists.</returns>
    internal procedure GetDefaultBOMVersion(ProductionBOMNo: Code[20]): Code[20]
    begin
        exit(VersionManagement.GetBOMVersion(ProductionBOMNo, WorkDate(), true));
    end;

    /// <summary>
    /// Returns the default active routing version code for a given routing as of the work date.
    /// </summary>
    /// <param name="RoutingNo">The routing number to retrieve the default version for.</param>
    /// <returns>The default version code, or empty if none exists.</returns>
    internal procedure GetDefaultRoutingVersion(RoutingNo: Code[20]): Code[20]
    begin
        exit(VersionManagement.GetRtngVersion(RoutingNo, WorkDate(), true));
    end;

    /// <summary>
    /// Opens a lookup page for certified production BOMs and returns the selected BOM number.
    /// </summary>
    /// <param name="SelectedBOMNo">Returns the BOM number selected by the user.</param>
    /// <returns>True if the user selected a BOM; false if cancelled.</returns>
    internal procedure ShowBOMSelection(var SelectedBOMNo: Code[20]): Boolean
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

    /// <summary>
    /// Opens a lookup page for certified routings and returns the selected routing number.
    /// </summary>
    /// <param name="SelectedRoutingNo">Returns the routing number selected by the user.</param>
    /// <returns>True if the user selected a routing; false if cancelled.</returns>
    internal procedure ShowRoutingSelection(var SelectedRoutingNo: Code[20]): Boolean
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

    /// <summary>
    /// Checks whether a routing (or a specific routing version) exists in the database.
    /// </summary>
    /// <param name="RoutingNo">The routing number to check.</param>
    /// <param name="RoutingVersionCode">The version code to check. If empty, checks the base routing header.</param>
    /// <returns>True if the routing or routing version record exists; otherwise false.</returns>
    internal procedure CheckRoutingExists(RoutingNo: Code[20]; RoutingVersionCode: Code[20]): Boolean
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

    /// <summary>
    /// Validates that the specified routing (or routing version) has Certified status. Throws an error if not certified.
    /// </summary>
    /// <param name="RoutingNo">The routing number to validate.</param>
    /// <param name="RoutingVersionCode">The version code to validate. If empty, the base routing header is validated.</param>
    internal procedure TestRoutingCertified(RoutingNo: Code[20]; RoutingVersionCode: Code[20])
    var
        RoutingHeader: Record "Routing Header";
        RoutingVersion: Record "Routing Version";
    begin
        if RoutingNo = '' then
            exit;

        if RoutingVersionCode <> '' then begin
            RoutingVersion.SetLoadFields(Status);
            RoutingVersion.Get(RoutingNo, RoutingVersionCode);
            RoutingVersion.TestField(Status, "Routing Status"::Certified);
            exit;
        end;

        RoutingHeader.SetLoadFields(Status);
        RoutingHeader.Get(RoutingNo);
        RoutingHeader.TestField(Status, "Routing Status"::Certified);
    end;

    /// <summary>
    /// Checks whether a production BOM (or a specific BOM version) exists in the database.
    /// </summary>
    /// <param name="ProductionBOMNo">The production BOM number to check.</param>
    /// <param name="BOMVersionCode">The version code to check. If empty, checks the base BOM header.</param>
    /// <returns>True if the BOM or BOM version record exists; otherwise false.</returns>
    internal procedure CheckBOMExists(ProductionBOMNo: Code[20]; BOMVersionCode: Code[20]): Boolean
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

    /// <summary>
    /// Validates that the specified production BOM (or BOM version) has Certified status. Throws an error if not certified.
    /// </summary>
    /// <param name="ProductionBOMNo">The production BOM number to validate.</param>
    /// <param name="BOMVersionCode">The version code to validate. If empty, the base BOM header is validated.</param>
    internal procedure TestBOMCertified(ProductionBOMNo: Code[20]; BOMVersionCode: Code[20])
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMVersion: Record "Production BOM Version";
    begin
        if ProductionBOMNo = '' then
            exit;

        if BOMVersionCode <> '' then begin
            ProductionBOMVersion.SetLoadFields(Status);
            ProductionBOMVersion.Get(ProductionBOMNo, BOMVersionCode);
            ProductionBOMVersion.TestField(Status, "BOM Status"::Certified);
            exit;
        end;

        ProductionBOMHeader.SetLoadFields(Status);
        ProductionBOMHeader.Get(ProductionBOMNo);
        ProductionBOMHeader.TestField(Status, "BOM Status"::Certified);
    end;

    /// <summary>
    /// Returns the number series code used for BOM versions of the specified production BOM.
    /// </summary>
    /// <param name="ProductionBOMNo">The production BOM number to retrieve the version number series for.</param>
    /// <returns>The version number series code from the production BOM header.</returns>
    internal procedure GetBOMVersionNoSeries(ProductionBOMNo: Code[20]): Code[20]
    var
        ProductionBOM: Record "Production BOM Header";
    begin
        ProductionBOM.SetLoadFields("Version Nos.");
        ProductionBOM.Get(ProductionBOMNo);
        ProductionBOM.TestField("Version Nos.");
        exit(ProductionBOM."Version Nos.");
    end;

    /// <summary>
    /// Returns the number series code used for routing versions of the specified routing.
    /// </summary>
    /// <param name="RoutingNo">The routing number to retrieve the version number series for.</param>
    /// <returns>The version number series code from the routing header.</returns>
    internal procedure GetRoutingVersionNoSeries(RoutingNo: Code[20]): Code[20]
    var
        Routing: Record "Routing Header";
    begin
        Routing.SetLoadFields("Version Nos.");
        Routing.Get(RoutingNo);
        Routing.TestField("Version Nos.");
        exit(Routing."Version Nos.");
    end;

    /// <summary>
    /// Validates that the production BOM has a version number series configured. Throws an error if not set.
    /// </summary>
    /// <param name="BOMNo">The production BOM number to validate the version number series for.</param>
    internal procedure ValidateBOMVersionNoSeries(BOMNo: Code[20])
    begin
        GetBOMVersionNoSeries(BOMNo);
    end;

    /// <summary>
    /// Validates that the routing has a version number series configured. Throws an error if not set.
    /// </summary>
    /// <param name="RoutingNo">The routing number to validate the version number series for.</param>
    internal procedure ValidateRoutingVersionNoSeries(RoutingNo: Code[20])
    begin
        GetRoutingVersionNoSeries(RoutingNo);
    end;
}