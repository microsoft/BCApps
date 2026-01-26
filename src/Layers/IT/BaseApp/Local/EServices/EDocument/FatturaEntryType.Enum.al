// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

enum 12200 "Fattura Entry Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Sales") { Caption = 'Sales'; }
    value(1; "Service") { Caption = 'Service'; }
}
