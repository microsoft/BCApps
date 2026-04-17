// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

/// <summary>
/// How often the user observes the slow scenario.
/// </summary>
enum 5473 "Perf. Analysis Frequency"
{
    Access = Public;
    Extensible = false;

    value(0; Always) { Caption = 'Every time I do the action'; }
    value(1; Sometimes) { Caption = 'Sometimes and unpredictably'; }
    value(2; ComesAndGoes) { Caption = 'Comes and goes during the day'; }
    value(3; Unknown) { Caption = 'I am not sure'; }
}
