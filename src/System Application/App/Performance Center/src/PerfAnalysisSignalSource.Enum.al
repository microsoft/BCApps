// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

/// <summary>
/// Where an individual signal finding came from.
/// </summary>
enum 5475 "Perf. Analysis Signal Source"
{
    Access = Public;
    Extensible = true;

    value(0; Profiler) { Caption = 'Profiler hotspot'; }
    value(1; MissingIndex) { Caption = 'Missing database index'; }
    value(2; Telemetry) { Caption = 'Telemetry'; }
    value(3; AiInsight) { Caption = 'AI insight'; }
    value(4; Custom) { Caption = 'Custom'; }
}
