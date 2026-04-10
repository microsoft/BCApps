// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Profiling;

#pragma warning disable AL0659
enum 5084 "Profile Quest. Cont. Class. Field"
#pragma warning restore AL0659
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Interaction Quantity") { Caption = 'Interaction Quantity'; }
    value(2; "Interaction Frequency (No./Year)") { Caption = 'Interaction Frequency (No./Year)'; }
    value(3; "Avg. Interaction Cost (LCY)") { Caption = 'Avg. Interaction Cost (LCY)'; }
    value(4; "Avg. Interaction Duration (Min.)") { Caption = 'Avg. Interaction Duration (Min.)'; }
    value(5; "Opportunity Won (%)") { Caption = 'Opportunity Won (%)'; }
    value(6; "Rating") { Caption = 'Rating'; }
}
