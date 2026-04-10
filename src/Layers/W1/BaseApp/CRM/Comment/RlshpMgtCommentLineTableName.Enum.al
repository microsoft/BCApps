// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Comment;

#pragma warning disable AL0659
enum 5061 "Rlshp. Mgt. Comment Line Table Name"
#pragma warning restore AL0659
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Contact") { Caption = 'Contact'; }
    value(1; "Campaign") { Caption = 'Campaign'; }
    value(2; "To-do") { Caption = 'To-do'; }
    value(3; "Web Source") { Caption = 'Web Source'; }
    value(4; "Sales Cycle") { Caption = 'Sales Cycle'; }
    value(5; "Sales Cycle Stage") { Caption = 'Sales Cycle Stage'; }
    value(6; "Opportunity") { Caption = 'Opportunity'; }
}
