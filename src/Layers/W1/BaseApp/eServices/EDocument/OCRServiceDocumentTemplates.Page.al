// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

page 1271 "OCR Service Document Templates"
{
    Caption = 'OCR Service Document Templates';
    PageType = List;
    SourceTable = "OCR Service Document Template";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the OCR document template.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the OCR document template.';
                }
            }
        }
    }

    actions
    {
        area(creation)
        {
            action(GetDefaults)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Update Document Template List';
                Image = Template;
                ToolTip = 'Check for new document templates that the OCR service supports, and add them to the list.';

                trigger OnAction()
                var
                    OCRServiceMgt: Codeunit "OCR Service Mgt.";
                begin
                    OCRServiceMgt.UpdateOcrDocumentTemplates();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(GetDefaults_Promoted; GetDefaults)
                {
                }
            }
        }
    }
}

