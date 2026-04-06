// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

page 690 "Payment Period Card"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Payment Period Card';
    PageType = ListPlus;
    SourceTable = "Payment Period Header";

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Rec.Code)
                {
                }
                field(Description; Rec.Description)
                {
                }
                field("Reporting Scheme"; Rec."Reporting Scheme")
                {
                    Editable = IsNewRecord;
                }
                field(Default; Rec.Default)
                {
                }
            }
            part(Lines; "Payment Period Subpage")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Lines';
                SubPageLink = "Period Header Code" = field(Code);
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        IsNewRecord := true;
    end;

    trigger OnAfterGetCurrRecord()
    begin
        IsNewRecord := Rec.Code = '';
    end;

    var
        IsNewRecord: Boolean;
}
