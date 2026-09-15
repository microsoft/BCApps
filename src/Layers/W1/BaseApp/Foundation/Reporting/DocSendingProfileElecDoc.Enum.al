// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

enum 64 "Doc. Sending Profile Elec.Doc."
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "No") { Caption = 'No'; }
    value(1; "Through Document Exchange Service") { Caption = 'Through Document Exchange Service'; }
}
