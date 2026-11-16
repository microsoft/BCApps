// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Wizard;

enum 99001028 "Prod. Definition Scenario"
{
    Extensible = true;
    value(0; NothingAvailable)
    {
        Caption = 'Nothing Available';
    }
    value(1; PartiallyAvailable)
    {
        Caption = 'Partially Available';
    }
    value(2; BothAvailable)
    {
        Caption = 'Both Available';
    }
}