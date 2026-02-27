namespace Microsoft.EServices.EDocumentConnector.Avalara;

page 6374 "Avalara Input Fields"
{
    ApplicationArea = All;
    Caption = 'Avalara Input Fields';
    PageType = List;
    ShowFilter = true;
    SourceTable = "Avalara Input Field";
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(Mandate; Rec.Mandate)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Mandate field.';
                }
                field(FieldId; Rec.FieldId)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Field ID field.';
                }
                field(DocumentType; Rec.DocumentType)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Document Type field.';
                }
                field(DocumentVersion; Rec.DocumentVersion)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Document Version field.';
                }
                field(Path; Rec.Path)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Path field.';
                }
                field(PathType; Rec.PathType)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Path Type field.';
                }
                field(FieldName; Rec.FieldName)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Field Name field.';
                }
                field(NamespacePrefix; Rec.NamespacePrefix)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Namespace Prefix field.';
                }
                field(NamespaceValue; Rec.NamespaceValue)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Namespace Value field.';
                }
                field(AcceptedValues; Rec.AcceptedValues)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Accepted Values field.';
                }
                field(DocumentationLink; Rec.DocumentationLink)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Documentation Link field.';
                }
                field(DataType; Rec.DataType)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Data Type field.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Description field.';
                }
                field(Optionality; Rec.Optionality)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Optionality field.';
                }
                field(Cardinality; Rec.Cardinality)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Cardinality field.';
                }
                field(ExampleOrFixedValue; Rec.ExampleOrFixedValue)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Example Or Fixed Value field.';
                }
            }
        }
    }
    procedure SetFilterByMandate(MandateCode: Text; MandateDocumentType: Text)
    begin
        Rec.SetRange(Mandate, MandateCode);
        if MandateDocumentType <> '' then
            Rec.SetRange(DocumentType, MandateDocumentType);
        Rec.FindFirst();
        CurrPage.Update(false);
    end;
}