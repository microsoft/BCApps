// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

page 149041 "AIT Test Data"
{
    Caption = 'AI Test Data';
    PageType = CardPart;
    ApplicationArea = All;
    Editable = false;
    Extensible = false;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Data)
            {
                ShowCaption = false;

                field("Test Data"; TestDataText)
                {
                    ShowCaption = false;
                    Editable = false;
                    MultiLine = true;
                    ExtendedDatatype = RichContent;
                }
            }
        }
    }


    internal procedure SetTestData(Text: Text)
    begin
        TestDataText := Text;
        CurrPage.Update(false);
    end;

    var
        TestDataText: Text;
}