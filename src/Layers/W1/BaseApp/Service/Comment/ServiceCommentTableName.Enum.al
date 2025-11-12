// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Comment;

enum 5918 "Service Comment Table Name"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Service Contract") { Caption = 'Service Contract'; }
    value(1; "Service Header") { Caption = 'Service Header'; }
    value(2; "Service Item") { Caption = 'Service Item'; }
    value(3; "Loaner") { Caption = 'Loaner'; }
    value(4; "Service Shipment Header") { Caption = 'Service Shipment Header'; }
    value(5; "Service Invoice Header") { Caption = 'Service Invoice Header'; }
    value(6; "Service Cr.Memo Header") { Caption = 'Service Cr.Memo Header'; }
}
