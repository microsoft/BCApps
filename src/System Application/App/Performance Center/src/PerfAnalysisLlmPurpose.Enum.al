// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

/// <summary>
/// Which Performance Center AI entry point produced a given LLM log entry.
/// </summary>
enum 8408 "Perf. Analysis LLM Purpose"
{
    Access = Public;
    Extensible = false;

    value(0; Filter) { Caption = 'Filter'; }
    value(1; Analyze) { Caption = 'Analyze'; }
    value(2; Chat) { Caption = 'Chat'; }
}
