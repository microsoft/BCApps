// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

page 5787 "Edit Financial Report Text"
{
    Caption = 'Edit Financial Report Introductory/Closing Paragraph';
    PageType = StandardDialog;
    Extensible = false;

    layout
    {
        area(content)
        {
            group(IntroductoryParagraphGroup)
            {
                Caption = 'Introductory paragraph';
                field(IntroductoryParagraph; IntroductoryParagraph)
                {
                    ApplicationArea = Basic, Suite;
                    ShowCaption = false;
                    ToolTip = 'Specifies the introductory paragraph displayed on the Financial Report.';
                    MultiLine = true;
                }
            }
            group(ClosingParagraphGroup)
            {
                Caption = 'Closing paragraph';
                field(ClosingParagraph; ClosingParagraph)
                {
                    ApplicationArea = Basic, Suite;
                    ShowCaption = false;
                    ToolTip = 'Specifies the closing paragraph displayed on the Financial Report, when it is printed to PDF or exported to Excel.';
                    MultiLine = true;
                }
            }
        }
    }

    var
        IntroductoryParagraph, ClosingParagraph : Text;

    internal procedure SetText(IntroductoryParagraph: Text; ClosingParagraph: Text)
    begin
        this.IntroductoryParagraph := IntroductoryParagraph;
        this.ClosingParagraph := ClosingParagraph;
    end;

    internal procedure GetText(var IntroductoryParagraph: Text; var ClosingParagraph: Text)
    begin
        IntroductoryParagraph := this.IntroductoryParagraph;
        ClosingParagraph := this.ClosingParagraph;
    end;
}
