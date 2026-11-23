// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

enum 20580 "Subc. WIP Cohort"
{
    Extensible = false;
    value(0; Unassigned) { Caption = 'Unassigned'; }
    value(1; Legacy) { Caption = 'Legacy'; }
    value(2; StateV1) { Caption = 'State V1'; }
}
