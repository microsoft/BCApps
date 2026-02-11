// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

using System.Telemetry;

codeunit 7788 "AOAI Policy Params Impl"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        Telemetry: Codeunit "Telemetry";
        HarmsSeverity: Enum "AOAI Policy Harms Severity";
        IsXPIADetectionEnabled: Boolean;
        CustomAOAIPolicy: Text;
        Initialized: Boolean;
        IsDefault: Boolean;
        TelemetryCouldNotResolveAOAIPolicyParamsLbl: Label 'Unable to resolve the AOAI Policy params. Returned the default AOAI Policy instead.', Locked = true;

    procedure GetHarmsSeverity(): Enum "AOAI Policy Harms Severity"
    begin
        if not Initialized then
            InitializeDefaults();

        exit(HarmsSeverity);
    end;

    procedure GetXPIADetection(): Boolean
    begin
        if not Initialized then
            InitializeDefaults();

        exit(IsXPIADetectionEnabled);
    end;

    procedure SetHarmsSeverity(NewHarmsSeverity: Enum "AOAI Policy Harms Severity")
    begin
        if not Initialized then
            InitializeDefaults();

        IsDefault := false;

        HarmsSeverity := NewHarmsSeverity;
    end;

    procedure SetXPIADetection(IsEnabled: Boolean)
    begin
        if not Initialized then
            InitializeDefaults();

        IsDefault := false;

        IsXPIADetectionEnabled := IsEnabled;
    end;

    procedure GetCustomAOAIPolicy(): Text
    begin
        if not Initialized then
            InitializeDefaults();

        exit(CustomAOAIPolicy);
    end;

    procedure SetCustomAOAIPolicy(NewCustomAOAIPolicy: Text)
    begin
        if not Initialized then
            InitializeDefaults();

        IsDefault := false;

        CustomAOAIPolicy := NewCustomAOAIPolicy;
    end;

    internal procedure GetAOAIPolicy(): Text
    begin
        if GetCustomAOAIPolicy() <> '' then
            exit(GetCustomAOAIPolicy())
        else
            exit(Format(GetAOAIPolicyEnum()));
    end;

    local procedure GetAOAIPolicyEnum(): Enum "AOAI Policy"
    var
        AOAIPolicyHarmsSeverity: Enum "AOAI Policy Harms Severity";
        AOAIPolicyXPIADetection: Boolean;
        CombinationKey: Text;
    begin
        AOAIPolicyHarmsSeverity := GetHarmsSeverity();
        AOAIPolicyXPIADetection := GetXPIADetection();

        // Create readable combination key
        CombinationKey := 'Harms' + Format(AOAIPolicyHarmsSeverity) + '|XPIA' + (AOAIPolicyXPIADetection = true ? 'Enabled' : 'Disabled');

        case CombinationKey of
            'HarmsLow|XPIAEnabled':
                exit("AOAI Policy"::"ConservativeWithXPIA");
            'HarmsLow|XPIADisabled':
                exit("AOAI Policy"::"ConservativeWithoutXPIA");
            'HarmsMedium|XPIAEnabled':
                exit("AOAI Policy"::"MediumWithXPIA");
            'HarmsMedium|XPIADisabled':
                exit("AOAI Policy"::"MediumWithoutXPIA");
            else
                Telemetry.LogMessage('0000QRU', TelemetryCouldNotResolveAOAIPolicyParamsLbl, Verbosity::Normal, DataClassification::SystemMetadata);
                exit("AOAI Policy"::"ConservativeWithXPIA");
        end;
    end;

    procedure InitializeDefaults()
    begin
        IsDefault := true;
        Initialized := true;
        HarmsSeverity := "AOAI Policy Harms Severity"::Low;
        IsXPIADetectionEnabled := true;
        CustomAOAIPolicy := '';
    end;

    procedure IsDefaultPolicy(): Boolean
    begin
        if not Initialized then
            exit(true);

        exit(IsDefault);
    end;
}