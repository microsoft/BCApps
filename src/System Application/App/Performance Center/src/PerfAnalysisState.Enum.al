// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

/// <summary>
/// Lifecycle states of a Performance Analysis record.
/// </summary>
enum 5472 "Perf. Analysis State"
{
    Access = Public;
    Extensible = false;

    value(0; Requested) { Caption = 'Requested'; }
    value(1; Scheduled) { Caption = 'Scheduled'; }
    value(2; Capturing) { Caption = 'Capturing'; }
    value(3; CaptureEnded) { Caption = 'Capture ended'; }
    value(4; AiFiltering) { Caption = 'AI filtering'; }
    value(5; AiAnalyzing) { Caption = 'AI analyzing'; }
    value(6; Concluded) { Caption = 'Concluded'; }
    value(7; Cancelled) { Caption = 'Cancelled'; }
    value(8; Failed) { Caption = 'Failed'; }
}
