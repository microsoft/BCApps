// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

using Microsoft.Utilities;
using Microsoft.Foundation.BatchProcessing;

/// <summary>
/// Adds support for validating the selected no. series in a batch process
/// </summary>
pageextension 418 "No. Series Check" extends "No. Series"
{
    actions
    {
        modify(TestNoSeriesSingle)
        {
            visible = false;
        }
        addfirst(Processing)
        {
            action(TestNoSeries)
            {
                ApplicationArea = Basic, Suite;
                Image = TestFile;
                Caption = 'Test No. Series';
                ToolTip = 'Test whether the number series can generate new numbers.';

                trigger OnAction()
                var
                    NoSeries: Record "No. Series";
                    BatchProcessingMgt: Codeunit "Batch Processing Mgt.";
                begin
                    CurrPage.SetSelectionFilter(NoSeries);
                    BatchProcessingMgt.BatchProcess(NoSeries, Codeunit::"No. Series Check", Enum::"Error Handling Options"::"Show Error", 0, 0);
                end;
            }
        }
    }
}