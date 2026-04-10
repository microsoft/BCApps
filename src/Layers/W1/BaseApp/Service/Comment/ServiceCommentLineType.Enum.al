// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Comment;

enum 5919 "Service Comment Line Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "General") { Caption = 'General'; }
    value(1; "Fault") { Caption = 'Fault'; }
    value(2; "Resolution") { Caption = 'Resolution'; }
    value(3; "Accessory") { Caption = 'Accessory'; }
    value(4; "Internal") { Caption = 'Internal'; }
    value(5; "Service Item Loaner") { Caption = 'Service Item Loaner'; }
}
