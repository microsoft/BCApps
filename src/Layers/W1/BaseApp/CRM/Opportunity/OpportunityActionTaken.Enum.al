// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Opportunity;

enum 5091 "Opportunity Action Taken"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Next") { Caption = 'Next'; }
    value(2; "Previous") { Caption = 'Previous'; }
    value(3; "Updated") { Caption = 'Updated'; }
    value(4; "Jumped") { Caption = 'Jumped'; }
    value(5; "Won") { Caption = 'Won'; }
    value(6; "Lost") { Caption = 'Lost'; }
}
