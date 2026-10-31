// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reports;

#if not CLEAN30
using System.Environment.Configuration;
#endif

codeunit 10823 "Install Reports FR"
{
    Access = Internal;
    Subtype = Install;
    InherentEntitlements = X;
    InherentPermissions = X;
#if not CLEAN30
    Permissions = tabledata "Feature Key" = r;
#endif

    trigger OnInstallAppPerDatabase()
    begin
        RegisterFeature();
    end;

    trigger OnInstallAppPerCompany()
    var
        ReportLayoutsFR: Codeunit "Report Layouts FR";
    begin
        ReportLayoutsFR.InitializeCompany();
    end;

#if not CLEAN30
    var
        FeatureKeyTok: Label 'FRReports', Locked = true;
        MissingFeatureKeyErr: Label 'The FRReports feature key is unavailable. Install the platform update containing the Reports FR feature before installing this app.';
#endif

    procedure RegisterFeature()
#if not CLEAN30
    var
        FeatureKey: Record "Feature Key";
#endif
    begin
#if not CLEAN30
        if not FeatureKey.Get(FeatureKeyTok) then
            Error(MissingFeatureKeyErr);
#endif
    end;
}
