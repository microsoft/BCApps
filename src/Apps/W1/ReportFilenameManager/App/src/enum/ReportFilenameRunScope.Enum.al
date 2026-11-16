// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting.FileNaming;

enum 8129 "Report Filename Run Scope"
{
    // How much of the table a Test Pattern run covers.

    Extensible = false;
    Caption = 'Report Filename Run Scope';
    Access = Internal;

    value(0; "One Record")
    {
        Caption = 'One Record';
    }
    value(1; "Some Records")
    {
        Caption = 'Some Records';
    }
    value(2; "Every Record")
    {
        Caption = 'Every Record';
    }
}
