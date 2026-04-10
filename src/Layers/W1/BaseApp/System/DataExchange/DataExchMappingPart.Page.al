namespace System.IO;

page 1219 "Data Exch Mapping Part"
{
    Caption = 'Data Exchange Mapping';
    PageType = ListPart;
    SourceTable = "Data Exch. Mapping";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Table ID"; Rec."Table ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Table ID';
                    ToolTip = 'Specifies the table that holds the fields to or from which data is exchanged according to the mapping.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the data exchange mapping setup.';
                }
                field("Pre-Mapping Codeunit"; Rec."Pre-Mapping Codeunit")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the codeunit that prepares the mapping between fields in Dynamics 365 and external data.';
                }
                field("Mapping Codeunit"; Rec."Mapping Codeunit")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the codeunit that is used to map the specified columns or XML data elements to fields in Microsoft Dynamics 365.';
                }
                field("Post-Mapping Codeunit"; Rec."Post-Mapping Codeunit")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the codeunit that completes the mapping between fields in Dynamics 365 and the external data file or service.';
                }
                field("Data Exch. No. Field ID"; Rec."Data Exch. No. Field ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the No. field in the external file that is mapped to a field in Dynamics 365.';
                }
                field("Data Exch. Line Field ID"; Rec."Data Exch. Line Field ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the Line field in the external file that is mapped to a field in Dynamics 365.';
                }
            }
        }
    }

    actions
    {
    }
}

