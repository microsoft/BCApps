// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

page 10705 "Copy Data Transference Format"
{
    Caption = 'Copy Data Transference Format';
    PageType = List;
    SourceTable = "AEAT Transference Format";

    layout
    {
        area(content)
        {
            group("Fill in the following data:")
            {
                Caption = 'Fill in the following data:';
                repeater(Control1100001)
                {
                    ShowCaption = false;
                    field(Description; Rec.Description)
                    {
                        ApplicationArea = All;
                        Editable = false;
                        ToolTip = 'Specifies the description of the XML label that will be included in the VAT statement text file.';
                    }
                    field(Length; Rec.Length)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ToolTip = 'Specifies the field length of the XML label that will be included in the VAT statement text file.';
                    }
                    field(Value; Rec.Value)
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the field value of the XML label that will be included in the VAT statement text file.';
                    }
                }
            }
        }
    }

    actions
    {
    }

    trigger OnInit()
    begin
        CurrPage.LookupMode := true;
    end;
}

