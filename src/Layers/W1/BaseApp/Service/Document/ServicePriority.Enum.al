// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

enum 5903 "Service Priority"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Low") { Caption = 'Low'; }
    value(1; "Medium") { Caption = 'Medium'; }
    value(2; "High") { Caption = 'High'; }
}
