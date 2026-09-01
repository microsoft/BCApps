#pragma warning disable AA0247
report 17310 "Copy Tax Calc. Section"
{
    Caption = 'Copy Tax Calc. Section';
    ProcessingOnly = true;

    dataset
    {
        dataitem(ToTaxCalcSection; "Tax Calc. Section")
        {
            DataItemTableView = sorting(Code);
            MaxIteration = 1;
            dataitem("Tax Calc. Section"; "Tax Calc. Section")
            {
                DataItemTableView = sorting(Code);
                dataitem("Tax Calc. Header"; "Tax Calc. Header")
                {
                    DataItemLink = "Section Code" = field(Code);
                    DataItemTableView = sorting("Section Code", "No.");

                    trigger OnAfterGetRecord()
                    begin
                        TaxCalcHeader.TransferFields("Tax Calc. Header", true);
                        TaxCalcHeader."Section Code" := ToTaxCalcSection.Code;
                        TaxCalcHeader.Insert();
                    end;

                    trigger OnPreDataItem()
                    begin
                        TaxCalcHeader.SetRange("Section Code", ToTaxCalcSection.Code);
                        TaxCalcHeader.DeleteAll();
                    end;
                }
                dataitem("Tax Calc. Selection Setup"; "Tax Calc. Selection Setup")
                {
                    DataItemLink = "Section Code" = field(Code);
                    DataItemTableView = sorting("Section Code", "Register No.", "Line No.");

                    trigger OnAfterGetRecord()
                    begin
                        TaxCalcSelectionSetup.TransferFields("Tax Calc. Selection Setup", true);
                        TaxCalcSelectionSetup."Section Code" := ToTaxCalcSection.Code;
                        TaxCalcSelectionSetup.Insert();
                    end;

                    trigger OnPreDataItem()
                    begin
                        TaxCalcSelectionSetup.SetRange("Section Code", ToTaxCalcSection.Code);
                        TaxCalcSelectionSetup.DeleteAll();
                    end;
                }
                dataitem("Tax Calc. Line"; "Tax Calc. Line")
                {
                    DataItemLink = "Section Code" = field(Code);
                    DataItemTableView = sorting("Section Code", Code, "Line No.");

                    trigger OnAfterGetRecord()
                    begin
                        TaxCalcLine.TransferFields("Tax Calc. Line", true);
                        TaxCalcLine."Section Code" := ToTaxCalcSection.Code;
                        TaxCalcLine.Insert();
                    end;

                    trigger OnPreDataItem()
                    begin
                        TaxCalcLine.SetRange("Section Code", ToTaxCalcSection.Code);
                        TaxCalcLine.DeleteAll();
                    end;
                }
                dataitem("Tax Calc. Term"; "Tax Calc. Term")
                {
                    DataItemLink = "Section Code" = field(Code);
                    DataItemTableView = sorting("Section Code", "Term Code");

                    trigger OnAfterGetRecord()
                    begin
                        TaxCalcTerm.TransferFields("Tax Calc. Term", true);
                        TaxCalcTerm."Section Code" := ToTaxCalcSection.Code;
                        TaxCalcTerm.Insert();
                    end;

                    trigger OnPreDataItem()
                    begin
                        TaxCalcTerm.SetRange("Section Code", ToTaxCalcSection.Code);
                        TaxCalcTerm.DeleteAll();
                    end;
                }
                dataitem("Tax Calc. Term Formula"; "Tax Calc. Term Formula")
                {
                    DataItemLink = "Section Code" = field(Code);
                    DataItemTableView = sorting("Section Code", "Term Code", "Line No.");

                    trigger OnAfterGetRecord()
                    begin
                        TaxCalcTermFormula.TransferFields("Tax Calc. Term Formula", true);
                        TaxCalcTermFormula."Section Code" := ToTaxCalcSection.Code;
                        TaxCalcTermFormula.Insert();
                    end;

                    trigger OnPreDataItem()
                    begin
                        TaxCalcTermFormula.SetRange("Section Code", ToTaxCalcSection.Code);
                        TaxCalcTermFormula.DeleteAll();
                    end;
                }
                dataitem("Tax Calc. Dim. Filter"; "Tax Calc. Dim. Filter")
                {
                    DataItemLink = "Section Code" = field(Code);
                    DataItemTableView = sorting("Section Code", "Register No.", Define, "Line No.", "Dimension Code");

                    trigger OnAfterGetRecord()
                    begin
                        TaxCalcDimFilter.TransferFields("Tax Calc. Dim. Filter", true);
                        TaxCalcDimFilter."Section Code" := ToTaxCalcSection.Code;
                        TaxCalcDimFilter.Insert();
                    end;

                    trigger OnPreDataItem()
                    begin
                        TaxCalcDimFilter.SetRange("Section Code", ToTaxCalcSection.Code);
                        TaxCalcDimFilter.DeleteAll();
                    end;
                }
                dataitem("Tax Calc. Dim. Corr. Filter"; "Tax Calc. Dim. Corr. Filter")
                {
                    DataItemLink = "Section Code" = field(Code);
                    DataItemTableView = sorting("Section Code", "Corresp. Entry No.", "Connection Entry No.");

                    trigger OnAfterGetRecord()
                    begin
                        TaxCalcDimCorFilter.TransferFields("Tax Calc. Dim. Corr. Filter", true);
                        TaxCalcDimCorFilter."Section Code" := ToTaxCalcSection.Code;
                        TaxCalcDimCorFilter.Insert();
                    end;

                    trigger OnPreDataItem()
                    begin
                        TaxCalcDimCorFilter.SetRange("Section Code", ToTaxCalcSection.Code);
                        TaxCalcDimCorFilter.DeleteAll();
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    ToTaxCalcSection.TransferFields("Tax Calc. Section", false);
                    ToTaxCalcSection."Starting Date" := 0D;
                    ToTaxCalcSection."Ending Date" := 0D;
                    ToTaxCalcSection."Last Date Updated" := 0D;
                    ToTaxCalcSection.Status := ToTaxCalcSection.Status::Blocked;
                    ToTaxCalcSection."No G/L Entries Date" := 0D;
                    ToTaxCalcSection."No Item Entries Date" := 0D;
                    ToTaxCalcSection."No FA Entries Date" := 0D;
                    ToTaxCalcSection."Last G/L Entries Date" := 0D;
                    ToTaxCalcSection."Last Item Entries Date" := 0D;
                    ToTaxCalcSection."Last FA Entries Date" := 0D;
                    ToTaxCalcSection.Modify();
                end;

                trigger OnPostDataItem()
                begin
                    Wnd.Close();
                end;

                trigger OnPreDataItem()
                begin
                    SetRange(Code, TaxCalcSectionCode);
                    Wnd.Open(Text1005);
                end;
            }

            trigger OnPreDataItem()
            begin
                if TaxCalcSectionCode = '' then
                    Error(Text1000);
                if FindFirst() then
                    if Next() <> 0 then
                        Error(Text1001);
                if TaxCalcSectionCode = Code then
                    Error(Text1002);
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(TaxCalcSectionCode; TaxCalcSectionCode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Copy from';
                        TableRelation = "Tax Calc. Section";
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        TaxCalcHeader: Record "Tax Calc. Header";
        TaxCalcSelectionSetup: Record "Tax Calc. Selection Setup";
        TaxCalcLine: Record "Tax Calc. Line";
        TaxCalcTerm: Record "Tax Calc. Term";
        TaxCalcTermFormula: Record "Tax Calc. Term Formula";
        TaxCalcDimFilter: Record "Tax Calc. Dim. Filter";
        TaxCalcDimCorFilter: Record "Tax Calc. Dim. Corr. Filter";
        TaxCalcSectionCode: Code[10];
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text1000: Label 'Unknown value %1 %2 of source copy.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text1001: Label 'Value %1 %2 of target copy set multiply.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text1002: Label 'Self-Copy not allowed.';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text1005: Label 'One moment, please . . ';
#pragma warning restore AA0074
        Wnd: Dialog;
}

