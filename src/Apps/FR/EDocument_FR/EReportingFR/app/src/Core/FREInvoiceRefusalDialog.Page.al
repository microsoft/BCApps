// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

page 10972 "FR E-Invoice Refusal Dialog"
{
    Caption = 'Refuse E-Invoice';
    PageType = StandardDialog;

    layout
    {
        area(Content)
        {
            field(ReasonCode; ReasonCode)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Reason Code';
                NotBlank = true;
                ToolTip = 'Specifies the code that identifies why the invoice is refused.';
            }
            field(ReasonDescription; ReasonDescription)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Reason Description';
                MultiLine = true;
                NotBlank = true;
                ToolTip = 'Specifies why the invoice is refused.';
            }
        }
    }

    internal procedure GetReason(var NewReasonCode: Code[20]; var NewReasonDescription: Text[500])
    begin
        NewReasonCode := ReasonCode;
        NewReasonDescription := ReasonDescription;
    end;

    var
        ReasonCode: Code[20];
        ReasonDescription: Text[500];
}