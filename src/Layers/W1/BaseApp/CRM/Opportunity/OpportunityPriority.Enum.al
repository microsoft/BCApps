// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Opportunity;

enum 5093 "Opportunity Priority"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Low") { Caption = 'Low'; }
    value(1; "Normal") { Caption = 'Normal'; }
    value(2; "High") { Caption = 'High'; }
}
