namespace System.Xml;

page 9600 "XML Schemas"
{
    ApplicationArea = Basic, Suite;
    Caption = 'XML Schemas';
    PageType = List;
    SourceTable = "XML Schema";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                IndentationColumn = Rec.Indentation;
                IndentationControls = "Code";
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code for the XML schema.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the XML schema file that has been loaded for the line.';
                }
                field("Target Namespace"; Rec."Target Namespace")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the namespace of the XML schema file that has been loaded for the line.';
                }
                field("XSD.HASVALUE"; Rec.XSD.HasValue)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Schema is Loaded';
                    ToolTip = 'Specifies that an XML schema file has been loaded for the line.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control7; Notes)
            {
                ApplicationArea = Notes;
            }
            systempart(Control8; Links)
            {
                ApplicationArea = RecordLinks;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Load Schema")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Load Schema';
                Image = Import;
                ToolTip = 'Load an XML schema into the database.';

                trigger OnAction()
                begin
                    Rec.LoadSchema();
                end;
            }
            action("Export Schema")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Export Schema';
                Image = Export;
                ToolTip = 'Export an XML schema to a file.';

                trigger OnAction()
                begin
                    Rec.ExportSchema(true);
                end;
            }
            action("Open Schema Viewer")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Open Schema Viewer';
                Image = ViewWorksheet;
                ToolTip = 'View the XML schema of a file for which you want to create an XMLport or a data exchange definition so that users can import/export data to or from the file in question.';

                trigger OnAction()
                var
                    XMLSchemaViewer: Page "XML Schema Viewer";
                begin
                    XMLSchemaViewer.SetXMLSchemaCode(Rec.Code);
                    XMLSchemaViewer.Run();
                end;
            }
            action("Expand All")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Expand All';
                Image = ExpandAll;
                ToolTip = 'Expand all elements.';

                trigger OnAction()
                begin
                    Rec.SetRange(Indentation);
                end;
            }
            action("Collapse All")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Collapse All';
                Image = CollapseAll;
                ToolTip = 'Collapse all elements.';

                trigger OnAction()
                begin
                    Rec.SetRange(Indentation, 0);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref("Load Schema_Promoted"; "Load Schema")
                {
                }
                actionref("Export Schema_Promoted"; "Export Schema")
                {
                }
                actionref("Open Schema Viewer_Promoted"; "Open Schema Viewer")
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'Show', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref("Expand All_Promoted"; "Expand All")
                {
                }
                actionref("Collapse All_Promoted"; "Collapse All")
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetRange(Indentation, 0);
    end;
}

