// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

page 35562 "Modify Document Number Input"
{
    Caption = 'Modify Document Number Input';
    PageType = Card;

    layout
    {
        area(content)
        {
            group(Control1150008)
            {
                ShowCaption = false;
                label(Control1150000)
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = Text19001287;
                    ShowCaption = false;
                }
                field(NewDocumentNo; NewDocumentNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'New number';
                    ToolTip = 'Specifies the changed number.';
                }
            }
        }
    }

    actions
    {
    }

    var
        NewDocumentNo: Code[20];
        Text19001287: Label 'Modify document number';

    [Scope('OnPrem')]
    procedure SetNewDocumentNo(var DocNo: Code[20])
    begin
        NewDocumentNo := DocNo;
    end;

    [Scope('OnPrem')]
    procedure GetNewDocumentNo(var DocNo: Code[20])
    begin
        DocNo := NewDocumentNo;
    end;
}

