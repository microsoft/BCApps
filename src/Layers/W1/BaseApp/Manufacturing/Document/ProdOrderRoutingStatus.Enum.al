// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

enum 99000765 "Prod. Order Routing Status"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Planned") { Caption = 'Planned'; }
    value(2; "In Progress") { Caption = 'In Progress'; }
    value(3; "Finished") { Caption = 'Finished'; }
}
