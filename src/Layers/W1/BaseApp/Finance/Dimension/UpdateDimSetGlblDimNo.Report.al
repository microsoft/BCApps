// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

report 482 "Update Dim. Set Glbl. Dim. No."
{
    Caption = 'Update Global Dimension No. for Dimension Set Entries';
    ApplicationArea = Dimensions;
    UsageCategory = Tasks;
    ProcessingOnly = true;

    requestpage
    {
        layout
        {
            area(Content)
            {
                label(NoteLabel)
                {
                    ApplicationArea = Dimensions;
                    MultiLine = true;
                    ShowCaption = false;
                    CaptionClass = NoteLbl;
                }
            }
        }
    }

    var
        CompletedTxt: Label 'The task was successfully completed.';
        NoteLbl: Label 'Fix inconsistent settings for global and shortcut dimensions. Depending on the number of records, this might take some time. Choose OK to fix the settings now, or Schedule to run the report later, for example, during non-working hours.';

    trigger OnPreReport()
    begin
        Codeunit.Run(Codeunit::"Update Dim. Set Glbl. Dim. No.");
        Message(CompletedTxt);
    end;
}
