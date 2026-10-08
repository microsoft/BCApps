// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Contact;

enum 5050 "Contact Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Company") { Caption = 'Company'; }
    value(1; "Person") { Caption = 'Person'; }
}
