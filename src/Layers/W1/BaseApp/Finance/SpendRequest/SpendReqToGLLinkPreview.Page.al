// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SpendRequest;

page 6844 "Spend Req. To G/L Link Preview"
{
    Caption = 'Posted to G/L Preview';
    PageType = List;
    ApplicationArea = Basic, Suite;
    SourceTableTemporary = true;
    SourceTable = "Spend Request To G/L Link";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field("Spend Request No."; Rec."Spend Request No.")
                {
                    Visible = ShowReqNo;
                    trigger OnDrillDown()
                    var
                        SpendRequest: Record "Spend Request";
                    begin
                        if SpendRequest.Get(Rec."Spend Request No.") then
                            page.Run(Page::"Spend Request Card", SpendRequest);
                    end;
                }
                field("Spend Request Detail No."; Rec."Spend Request Detail No.")
                {
                    Visible = false;
                }
                field("Detail Description"; Rec."Detail Description")
                {
                }
                field("G/L Entry No."; Rec."G/L Entry No.")
                {
                    Visible = false;
                }
                field("G/L Account No."; Rec."G/L Account No.")
                {
                }
                field("Posting Date"; Rec."Posting Date")
                {
                }
                field("Document No."; Rec."Document No.")
                {
                }
                field(Amount; Rec.Amount)
                {
                }
            }
        }
    }

    var
        SpendRequest: Record "Spend Request";
        ShowReqNo: Boolean;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        ShowReqNo := Rec.GetFilter("Spend Request No.") = '';
        exit(Rec.Find(Which));
    end;

    trigger OnAfterGetRecord()
    begin
        if Rec."Detail Description" <> '' then
            exit;
        SpendRequest.SetLoadFields(Purpose);
        if Rec."Spend Request No." <> SpendRequest."No." then
            SpendRequest.Get(Rec."Spend Request No.");
        Rec."Detail Description" := CopyStr(SpendRequest.Purpose, 1, MaxStrLen(Rec."Detail Description"));
    end;
}
