// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Profiling;

enum 5089 "Profile Answer Priority"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Very Low (Hidden)") { Caption = 'Very Low (Hidden)'; }
    value(1; "Low") { Caption = 'Low'; }
    value(2; "Normal") { Caption = 'Normal'; }
    value(3; "High") { Caption = 'High'; }
    value(4; "Very High") { Caption = 'Very High'; }
}
