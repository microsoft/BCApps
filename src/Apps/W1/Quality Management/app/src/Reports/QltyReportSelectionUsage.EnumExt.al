// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Reports;

using Microsoft.Foundation.Reporting;

enumextension 20402 "Qlty. Report Selection Usage" extends "Report Selection Usage"
{
    value(20400; "Quality Management - Certificate of Analysis")
    {
        Caption = 'Quality Management - Certificate of Analysis';
    }
    value(20401; "Quality Management - Non-Conformance")
    {
        Caption = 'Quality Management - Non-Conformance';
    }
    value(20402; "Quality Management - General Purpose Inspection")
    {
        Caption = 'Quality Management - General Purpose Inspection';
    }
}
