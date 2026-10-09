// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
report 50152 "Filename Proof Report"
{
    // Exists for its caption. The [Report Caption] placeholder has to resolve in the document's
    // language rather than the session's, and that cannot be demonstrated with a Base
    // Application report in this container because none of their captions are translated here.
    // This report's caption is, so the two languages produce visibly different names.
    //
    // It is never rendered: the proofs call the manager with a record and a filter, which is
    // exactly the shape the platform hands over on the routes being proven.

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
