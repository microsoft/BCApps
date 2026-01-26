// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.GeneralLedger.Setup;

page 10738 "Rev. Chg. Post. Selection 340"
{
    Caption = 'Rev. Chg. Post. Selection 340';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Worksheet;
    SourceTable = "Gen. Prod. Post. Group Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1100000)
            {
                ShowCaption = false;
                field("Rev. Charge Prod. Post. Group"; Rec."Rev. Charge Prod. Post. Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if this is based on the posting group for reverse charges.';
                }
                field("Code"; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description.';
                }
            }
        }
    }

    actions
    {
    }

    [Scope('OnPrem')]
    procedure GetGPPGSelBuf(var TheGPPGSelectionBuf: Record "Gen. Prod. Post. Group Buffer")
    begin
        TheGPPGSelectionBuf.DeleteAll();
        if Rec.FindFirst() then
            repeat
                TheGPPGSelectionBuf := Rec;
                TheGPPGSelectionBuf.Insert();
            until Rec.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure InsertGPPGSelBuf(NewSelected: Boolean; NewCode: Code[10]; NewDescription: Text[100])
    var
        GenProdPostGroup: Record "Gen. Product Posting Group";
    begin
        if NewDescription = '' then
            if GenProdPostGroup.Get(NewCode) then
                NewDescription := GenProdPostGroup.Description;

        Rec.Init();
        Rec."Rev. Charge Prod. Post. Group" := NewSelected;
        Rec.Code := NewCode;
        Rec.Description := NewDescription;
        Rec.Insert();
    end;
}

