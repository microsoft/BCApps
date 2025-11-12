// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Insurance;

page 5650 "Total Value Insured Subform"
{
    Caption = 'Lines';
    DataCaptionFields = "FA No.";
    Editable = false;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Total Value Insured";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("FA No."; Rec."FA No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the number of the related fixed asset. ';
                    Visible = false;
                }
                field("Insurance No."; Rec."Insurance No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the number of the insurance policy that the entry is linked to.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the description of the insurance policy.';
                }
                field("Total Value Insured"; Rec."Total Value Insured")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the amounts you posted to each insurance policy for the fixed asset.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnFindRecord(Which: Text): Boolean
    begin
        exit(Rec.FindFirst(Which));
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    begin
        exit(Rec.FindNext(Steps));
    end;

    procedure CreateTotalValue(FANo: Code[20])
    begin
        Rec.CreateInsTotValueInsured(FANo);
        CurrPage.Update();
    end;
}

