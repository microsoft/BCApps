// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
report 149502 "Filename Proof Report"
{
    // Exists for its translated caption, to prove [Report Name] resolves in the document's
    // language (the W1 Base Application carries no .xlf translations). Never rendered.

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
