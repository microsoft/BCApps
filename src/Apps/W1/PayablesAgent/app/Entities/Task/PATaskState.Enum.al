// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

enum 3345 "PA Task State"
{
    Access = Internal;
    Extensible = false;

    value(0; "Pending Processing")
    {
        Caption = 'Pending processing';
    }
    value(1; "Needs Attention")
    {
        Caption = 'Needs attention';
    }
    value(2; "Ready For Review")
    {
        Caption = 'Ready for review';
    }
    value(3; Processed)
    {
        Caption = 'Processed';
    }
    value(4; Rejected)
    {
        Caption = 'Rejected';
    }
}
