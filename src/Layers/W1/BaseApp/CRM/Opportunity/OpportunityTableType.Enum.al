// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Opportunity;

enum 5094 "Opportunity Table Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(13; "Sales Person") { Caption = 'Sales Person'; }
    value(5050; "Contact") { Caption = 'Contact'; }
    value(5071; "Campaign") { Caption = 'Campaign'; }
}
