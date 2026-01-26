// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

enum 10711 "SII Document Status"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Pending") { Caption = 'Pending'; }
    value(1; "Incorrect") { Caption = 'Incorrect'; }
    value(2; "Accepted") { Caption = 'Accepted'; }
    value(3; "Accepted With Errors") { Caption = 'Accepted With Errors'; }
    value(4; "Communication Error") { Caption = 'Communication Error'; }
    value(5; "Failed") { Caption = 'Failed'; }
    value(6; "Not Supported") { Caption = 'Not Supported'; }
}
