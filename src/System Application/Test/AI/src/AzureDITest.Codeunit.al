// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.AI;

using System.AI;
using System.TestLibraries.AI;
using System.TestLibraries.Environment;
using System.AI.DocumentIntelligence;
using System.TestLibraries.Utilities;

codeunit 132685 "Azure DI Test"
{
    Subtype = Test;

    var
        CopilotTestLibrary: Codeunit "Copilot Test Library";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        LibraryAssert: Codeunit "Library Assert";

    [Test]
    procedure TestSetCopilotCapabilityInactive()
    var
        AzureDI: Codeunit "Azure Document Intelligence";
    begin

        // [GIVEN] Capability is set
        RegisterCapability(Enum::"Copilot Capability"::"Text Capability");
        CopilotTestLibrary.SetCopilotStatus(Enum::"Copilot Capability"::"Text Capability", GetModuleAppId(), Enum::"Copilot Status"::Inactive);

        // [WHEN] SetCopilotCapability is called
        asserterror AzureDI.SetCopilotCapability(Enum::"Copilot Capability"::"Text Capability");

        // [THEN] SetCopilotCapability returns an error
        LibraryAssert.ExpectedError('Copilot capability ''Text Capability'' has not been enabled. Please contact your system administrator.');
    end;

    [Test]
    procedure AnalyzeInvoiceCopilotCapabilityNotSet()
    var
        AzureDI: Codeunit "Azure Document Intelligence";
    begin
        // [SCENARIO] AnalyzeInvoice returns an error when capability is not set

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);

        // [WHEN] AnalyzeInvoice is called
        asserterror AzureDI.AnalyzeInvoice('Text');

        // [THEN] AnalyzeInvoice returns an error
        LibraryAssert.ExpectedError('Copilot capability has not been set.');
    end;

    [Test]
    procedure AnalyzeInvoiceCapabilityInactive()
    var
        AzureDI: Codeunit "Azure Document Intelligence";
    begin
        // [SCENARIO]  AnalyzeInvoice returns an error when capability is not active

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);

        // [GIVEN] Capability is set
        RegisterCapability(Enum::"Copilot Capability"::"Text Capability");
        AzureDI.SetCopilotCapability(Enum::"Copilot Capability"::"Text Capability");
        CopilotTestLibrary.SetCopilotStatus(Enum::"Copilot Capability"::"Text Capability", GetModuleAppId(), Enum::"Copilot Status"::Inactive);

        // [WHEN] AnalyzeInvoice is called
        asserterror AzureDI.AnalyzeInvoice('Test');

        // [THEN] AnalyzeInvoice returns an error
        LibraryAssert.ExpectedError('Copilot capability ''Text Capability'' has not been enabled. Please contact your system administrator.');
    end;

    local procedure RegisterCapability(Capability: Enum "Copilot Capability")
    var
        AzureDI: Codeunit "Azure Document Intelligence";
        CopilotCapability: Codeunit "Copilot Capability";
    begin
        if CopilotCapability.IsCapabilityRegistered(Capability) then
            exit;

        AzureDI.RegisterCopilotCapability(Capability, Enum::"Copilot Availability"::Preview, '');
    end;

    local procedure GetModuleAppId(): Guid
    var
        CurrentModuleInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(CurrentModuleInfo);
        exit(CurrentModuleInfo.Id());
    end;
}