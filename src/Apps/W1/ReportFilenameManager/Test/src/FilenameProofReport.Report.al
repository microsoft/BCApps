// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.Foundation.Reporting.FileNaming;

report 149502 "Filename Proof Report"
{
    // Metadata-only report for document-language selection and filename composition. Never rendered.

    Caption = 'Proof Document';

    dataset
    {
        dataitem(Document; "Filename Proof Document")
        {
            RequestFilterFields = "No.", "Customer Name";

            column(No_; "No.")
            {
            }
            column(CustomerName; "Customer Name")
            {
            }
        }
    }
}
