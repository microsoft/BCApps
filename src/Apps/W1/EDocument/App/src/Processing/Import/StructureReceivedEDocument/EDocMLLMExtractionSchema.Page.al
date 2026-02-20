// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

page 6142 "E-Doc. MLLM Extraction Schema"
{
    PageType = Card;
    SourceTable = "E-Doc. MLLM Extraction Schema";
    ApplicationArea = All;
    UsageCategory = None;
    Caption = 'E-Document MLLM Extraction Schema';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field("E-Document Service Code"; Rec."E-Document Service Code")
                {
                    ToolTip = 'Specifies the E-Document Service this schema is associated with.';
                    Editable = false;
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies a description for this extraction schema.';
                }
            }
            group(Schema)
            {
                Caption = 'JSON Schema';
                field(SchemaText; SchemaTextVar)
                {
                    Caption = 'JSON Schema';
                    ToolTip = 'Specifies the JSON schema that the MLLM will use to extract data from the document.';
                    MultiLine = true;

                    trigger OnValidate()
                    var
                        JsonObj: JsonObject;
                    begin
                        if SchemaTextVar <> '' then
                            JsonObj.ReadFrom(SchemaTextVar);
                        Rec.SetSchemaText(SchemaTextVar);
                    end;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(LoadDefaultSchema)
            {
                Caption = 'Load Default Schema';
                ToolTip = 'Loads the default UBL-inspired JSON schema for invoice extraction.';
                Image = Import;

                trigger OnAction()
                var
                    EDocMLLMSchemaHelper: Codeunit "E-Doc. MLLM Schema Helper";
                begin
                    SchemaTextVar := EDocMLLMSchemaHelper.GetDefaultSchema();
                    Rec.SetSchemaText(SchemaTextVar);
                end;
            }
        }
        area(Promoted)
        {
            actionref(LoadDefaultSchemaPromoted; LoadDefaultSchema) { }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        SchemaTextVar := Rec.GetSchemaText();
    end;

    var
        SchemaTextVar: Text;
}
