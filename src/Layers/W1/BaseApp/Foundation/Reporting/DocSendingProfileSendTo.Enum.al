// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

enum 66 "Doc. Sending Profile Send To"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Disk") { Caption = 'Disk'; }
    value(1; "Email") { Caption = 'Email'; }
    value(2; "Print") { Caption = 'Print'; }
    value(3; "Electronic Document") { Caption = 'Electronic Document'; }
}
