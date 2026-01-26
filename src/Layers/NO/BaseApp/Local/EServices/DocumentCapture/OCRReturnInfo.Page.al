// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Finance.GeneralLedger.Journal;

page 15000101 "OCR Return Info"
{
    // MBS Navision NO - OCR Payment

    Caption = 'OCR Return Info';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "Gen. Journal Line";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(Warning; Rec.Warning)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if a warning is sent from the recipient''s bank to the recipient.';
                }
                field("Warning text"; Rec."Warning text")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    MultiLine = true;
                    ToolTip = 'Specifies the warning text that is used if the Warning field is set to Other.';
                }
            }
        }
    }

    actions
    {
    }
}

