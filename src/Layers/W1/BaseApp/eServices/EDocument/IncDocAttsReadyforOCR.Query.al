// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

query 133 "Inc. Doc. Atts. Ready for OCR"
{
    Caption = 'Inc. Doc. Atts. Ready for OCR';

    elements
    {
        dataitem(Incoming_Document; "Incoming Document")
        {
            DataItemTableFilter = "OCR Status" = const(Ready);
            dataitem(Incoming_Document_Attachment; "Incoming Document Attachment")
            {
                DataItemLink = "Incoming Document Entry No." = Incoming_Document."Entry No.";
                SqlJoinType = InnerJoin;
                DataItemTableFilter = "Use for OCR" = const(true);
                column(Incoming_Document_Entry_No; "Incoming Document Entry No.")
                {
                }
                column(Line_No; "Line No.")
                {
                }
            }
        }
    }
}

