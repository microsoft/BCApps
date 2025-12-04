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
        IsXPIADetectionEnabled: Boolean;
        CustomAOAIPolicy: Text;
        Initialized: Boolean;

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

        HarmsSeverity := NewHarmsSeverity;
    end;

    procedure SetXPIADetection(IsEnabled: Boolean)
    begin
        if not Initialized then
            InitializeDefaults();

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
                exit("AOAI Policy"::"ConservativeWithXPIA");
        end;
    end;

    procedure InitializeDefaults()
    begin
        Initialized := true;
        HarmsSeverity := "AOAI Policy Harms Severity"::Low;
        IsXPIADetectionEnabled := true;
        CustomAOAIPolicy := '';
    end;
}