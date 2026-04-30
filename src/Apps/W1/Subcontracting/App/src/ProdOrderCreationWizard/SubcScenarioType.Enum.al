// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

enum 99001505 "Subc. Scenario Type"
{
    Extensible = true;

    value(0; BothAvailable)
    {
        Caption = 'Both Available';
    }
    value(1; PartiallyAvailable)
    {
        Caption = 'Partially Available';
    }
    value(2; NothingAvailable)
    {
        Caption = 'Nothing Available';
    }
}