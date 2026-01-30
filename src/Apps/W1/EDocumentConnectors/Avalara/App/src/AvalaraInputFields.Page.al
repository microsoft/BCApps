page 6374 "Avalara Input Fields"
{
    ApplicationArea = All;
    Caption = 'Avalara Input Fields';
    PageType = List;
    ShowFilter = true;
    SourceTable = "AvalaraInput Field";
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
                field(fieldId; Rec.fieldId)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Field ID field.';
                }
                field(documentType; Rec.documentType)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Document Type field.';
                }
                field(documentVersion; Rec.documentVersion)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Document Version field.';
                }
                field(path; Rec.path)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Path field.';
                }
                field(pathType; Rec.pathType)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Path Type field.';
                }
                field(fieldName; Rec.fieldName)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Field Name field.';
                }
                field(namespace_prefix; Rec.namespace_prefix)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Namespace prefix field.';
                }
                field(namespace_value; Rec.namespace_value)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the name space Value field.';
                }
                field(acceptedValues; Rec.acceptedValues)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Accepted Values field.';
                }
                field(DocumentationLink; Rec.DocumentationLink)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Documentation Link field.';
                }
                field(dataType; Rec.dataType)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Data Type field.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Description field.';
                }
                field(optionality; Rec.optionality)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the optionality field.';
                }
                field(cardinality; Rec.cardinality)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the optionality field.';
                }
                field(exampleOrFixedValue; Rec.exampleOrFixedValue)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Example Or FixedValue field.';
                }
            }
        }
    }
    procedure SetFilterByMandate(MandateCode: Text; DocumentType: Text)
    begin
        Rec.SetFilter(Mandate, MandateCode);
        if DocumentType <> '' then
            Rec.SetFilter(documentType, DocumentType);
        Rec.FindFirst();
        CurrPage.Update(false);
    end;
}