// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Routing;

enum 99000764 "Routing Status"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "New") { Caption = 'New'; }
    value(1; "Certified") { Caption = 'Certified'; }
    value(2; "Under Development") { Caption = 'Under Development'; }
    value(3; "Closed") { Caption = 'Closed'; }
}
