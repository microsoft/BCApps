// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Setup;

enum 5417 "Flushing Method"
{
    Extensible = true;
    AssignmentCompatibility = true;

#if not CLEAN26
#pragma warning disable AS0072
    value(0; "Manual")
    {
        Caption = 'Manual';
        ObsoleteReason = 'The ''Pick + Manual'' option now works in the same way as the ''Manual'' option previously did. The ''Manual'' option will not be removed but it has been repurposed to no longer require picking. This functional change is controlled by the feature key ''Manual Flushing Method without requiring pick'', which will be enabled by default in version 29.0.';
        ObsoleteState = Pending;
        ObsoleteTag = '26.0';
    }
#pragma warning restore AS0072
#else
    value(0; "Manual") { Caption = 'Manual'; }
#endif
    value(1; "Forward") { Caption = 'Forward'; }
    value(2; "Backward") { Caption = 'Backward'; }
    value(3; "Pick + Forward") { Caption = 'Pick + Forward'; }
    value(4; "Pick + Backward") { Caption = 'Pick + Backward'; }
    value(6; "Pick + Manual") { Caption = 'Pick + Manual'; }
}
