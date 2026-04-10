// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Segment;

enum 5097 "Segment Criteria Line Action"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ")
    {
    }
    value(1; "Add Contacts")
    {
        Caption = 'Add Contacts';
    }
    value(2; "Remove Contacts (Reduce)")
    {
        Caption = 'Remove Contacts (Reduce)';
    }
    value(3; "Remove Contacts (Refine)")
    {
        Caption = 'Remove Contacts (Refine)';
    }
}
