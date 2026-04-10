namespace System.IO;

page 1211 "Data Exch Def List"
{
    AdditionalSearchTerms = 'file import,file export,data import,data export,data stream,transfer,ecommerce';
    ApplicationArea = Basic, Suite;
    Caption = 'Data Exchange Definitions';
    CardPageID = "Data Exch Def Card";
    PageType = List;
    SourceTable = "Data Exch. Def";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code that identifies the data exchange setup.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the data exchange definition.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies what type of exchange the data exchange definition is used for.';
                }
                field("Data Handling Codeunit"; Rec."Data Handling Codeunit")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the codeunit that transfers data in and out of tables in Microsoft Dynamics 365.';
                }
                field("Validation Codeunit"; Rec."Validation Codeunit")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the codeunit that is used to validate data against pre-defined business rules.';
                }
                field("Reading/Writing Codeunit"; Rec."Reading/Writing Codeunit")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the codeunit that processes imported data prior to mapping and exported data after mapping.';
                }
                field("Reading/Writing XMLport"; Rec."Reading/Writing XMLport")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the XMLport through which an imported data file or service enters prior to mapping and through which exported data exits when it is written to a data file or service after mapping.';
                }
                field("Ext. Data Handling Codeunit"; Rec."Ext. Data Handling Codeunit")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the codeunit that transfers external data in and out of the Data Exchange Framework.';
                }
                field("User Feedback Codeunit"; Rec."User Feedback Codeunit")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the codeunit that does various clean-up after mapping, such as marks the lines as exported and deletes temporary records.';
                }
                field("Header Lines"; Rec."Header Lines")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how many header lines exist in the file. This ensures that the header data is not imported. This field is only relevant for import.';
                }
                field("Header Tag"; Rec."Header Tag")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the text of the first column on the header line.';
                }
                field("Footer Tag"; Rec."Footer Tag")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the text of the first column on the footer line. If a footer line exists in several places in the file, enter the text of the first column on the footer line to ensure that the footer data is not imported. This field is only relevant for import.';
                }
                field("Column Separator"; Rec."Column Separator")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how columns in the file are separated if the file is of type Variable Text.';
                }
                field("Custom Column Separator"; Rec."Custom Column Separator")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how columns in the file are separated if the file is of a custom type.';
                }
                field("File Encoding"; Rec."File Encoding")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the encoding of the file to be imported. This field is only relevant for import.';
                }
                field("File Type"; Rec."File Type")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies what type of file the data exchange definition is used for. You can select between three file types.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Import Data Exchange Definition")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Import Data Exchange Definition';
                Image = Import;
                ToolTip = 'Import a data exchange definition from a bank file that is located on your computer or network. The file type must match the value of the File Type field.';

                trigger OnAction()
                begin
                    XMLPORT.Run(XMLPORT::"Imp / Exp Data Exch Def & Map", false, true);
                end;
            }
            action("Export Data Exchange Definition")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Export Data Exchange Definition';
                Image = Export;
                ToolTip = 'Export the data exchange definition to a file on your computer or network. You can then upload the file to your electronic bank to process the related transfers.';

                trigger OnAction()
                var
                    DataExchDef: Record "Data Exch. Def";
                begin
                    CurrPage.SetSelectionFilter(DataExchDef);
                    XMLPORT.Run(XMLPORT::"Imp / Exp Data Exch Def & Map", false, false, DataExchDef);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'Import/Export', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref("Import Data Exchange Definition_Promoted"; "Import Data Exchange Definition")
                {
                }
                actionref("Export Data Exchange Definition_Promoted"; "Export Data Exchange Definition")
                {
                }
            }
        }
    }
}

