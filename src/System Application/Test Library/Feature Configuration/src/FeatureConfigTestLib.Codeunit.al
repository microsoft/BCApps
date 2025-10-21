// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.Config;

using System;

codeunit 132515 "Feature Config Test Lib."
{

    var
        ALCopilotFunctions: DotNet ALCopilotFunctions;

    /// <summary>
    /// Configures the system to use control allocation for A/B testing scenarios.
    /// </summary>
    /// <remarks>This has no effect in Saas.</remarks>
    procedure UseControlAllocation()
    begin
        ALCopilotFunctions.UseTreatmentAllocation(false);
    end;

    /// <summary>
    /// Configures the system to use treatment allocation for A/B testing scenarios.
    /// This has no effect in Saas.
    /// </summary>
    /// <remarks>This has no effect in Saas.</remarks>
    procedure UseTreatmentAllocation()
    begin
        ALCopilotFunctions.UseTreatmentAllocation(true);
    end;
}

