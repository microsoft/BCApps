// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Outlook;

enum 5059 "Office Contact Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Company") { Caption = 'Company'; }
    value(1; "Contact Person") { Caption = 'Contact Person'; }
}
