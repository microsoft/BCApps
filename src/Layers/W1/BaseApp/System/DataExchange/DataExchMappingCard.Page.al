namespace System.IO;

page 1214 "Data Exch Mapping Card"
{
    Caption = 'Field Mapping';
    DelayedInsert = true;
    PageType = Document;
    SourceTable = "Data Exch. Mapping";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Table ID"; Rec."Table ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Table ID';
                    ToolTip = 'Specifies the table that holds the fields to or from which data is exchanged according to the mapping.';

                    trigger OnValidate()
                    begin
                        Rec.PositivePayUpdateCodeunits();
                        CurrPage.Update();
                    end;
                }
                field("Use as Intermediate Table"; Rec."Use as Intermediate Table")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the table that you select in the Table ID field is an intermediate table where the imported data is stored before it is mapped to the target table.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the data exchange mapping setup.';
                }
                field("Key Index"; Rec."Key Index")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the key index to sort the source records before exporting.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Key"; Rec."Key")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the key to sort the source records before exporting.';
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
                    ToolTip = 'Specifies the ID. This field is intended only for internal use.';
                    Visible = false;
                }
                field("Data Exch. Line Field ID"; Rec."Data Exch. Line Field ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID. This field is intended only for internal use.';
                    Visible = false;
                }
            }
            part("Field Mapping"; "Data Exch Field Mapping Part")
            {
                ApplicationArea = All;
                Caption = 'Field Mapping';
                SubPageLink = "Data Exch. Def Code" = field("Data Exch. Def Code"),
                              "Data Exch. Line Def Code" = field("Data Exch. Line Def Code"),
                              "Table ID" = field("Table ID");
                UpdatePropagation = Both;
                Visible = not Rec."Use as Intermediate Table";
            }
            part("Field Grouping"; "Data Exch Field Grouping Part")
            {
                ApplicationArea = All;
                Caption = 'Field Grouping';
                SubPageLink = "Data Exch. Def Code" = field("Data Exch. Def Code"),
                              "Data Exch. Line Def Code" = field("Data Exch. Line Def Code"),
                              "Table ID" = field("Table ID");
                Visible = not Rec."Use as Intermediate Table";
            }
            part(Control12; "Generic Data Exch Fld Mapping")
            {
                ApplicationArea = All;
                Caption = 'Field Mapping';
                SubPageLink = "Data Exch. Def Code" = field("Data Exch. Def Code"),
                              "Data Exch. Line Def Code" = field("Data Exch. Line Def Code"),
                              "Table ID" = field("Table ID");
                UpdatePropagation = Both;
                Visible = Rec."Use as Intermediate Table";
            }
        }
    }

    actions
    {
    }
}