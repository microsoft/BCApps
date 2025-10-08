// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

codeunit 7788 "AOAI Policy Params Impl"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        HarmsSeverity: Enum "AOAI Policy Harms Severity";
        XPIADetection: Enum "AOAI Policy XPIA Detection";
        Initialized: Boolean;

    procedure GetHarmsSeverity(): Enum "AOAI Policy Harms Severity"
    begin
        if not Initialized then
            InitializeDefaults();

        exit(HarmsSeverity);
    end;

    procedure GetXPIADetection(): Enum "AOAI Policy XPIA Detection"
    begin
        if not Initialized then
            InitializeDefaults();

        exit(XPIADetection);
    end;

    procedure SetHarmsSeverity(NewHarmsSeverity: Enum "AOAI Policy Harms Severity")
    begin
        if not Initialized then
            InitializeDefaults();

        HarmsSeverity := NewHarmsSeverity;
    end;

    procedure SetXPIADetection(NewXPIADetection: Enum "AOAI Policy XPIA Detection")
    begin
        if not Initialized then
            InitializeDefaults();

        XPIADetection := NewXPIADetection;
    end;

    local procedure InitializeDefaults()
    begin
        Initialized := true;
        HarmsSeverity := "AOAI Policy Harms Severity"::Low;
        XPIADetection := "AOAI Policy XPIA Detection"::Enabled;
    end;
}