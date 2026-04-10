#pragma warning disable AA0247
report 17200 "Copy Tax Register Section"
{
    Caption = 'Copy Tax Register Section';
    ProcessingOnly = true;

    dataset
    {
        dataitem(ToTaxRegSection; "Tax Register Section")
        {
            DataItemTableView = sorting(Code);
            dataitem("Tax Register Section"; "Tax Register Section")
            {
                DataItemTableView = sorting(Code);
                dataitem("Tax Register"; "Tax Register")
                {
                    DataItemLink = "Section Code" = field(Code);
                    DataItemTableView = sorting("Section Code");

                    trigger OnAfterGetRecord()
                    begin
                        TaxReg.TransferFields("Tax Register", true);
                        TaxReg."Section Code" := ToTaxRegSection.Code;
                        TaxReg.Insert();
                    end;

                    trigger OnPreDataItem()
                    begin
                        TaxReg.SetFilter("Section Code", ToTaxRegSection.Code);
                        TaxReg.DeleteAll();
                    end;
                }
                dataitem("Tax Register Line Setup"; "Tax Register Line Setup")
                {
                    DataItemLink = "Section Code" = field(Code);
                    DataItemTableView = sorting("Section Code");

                    trigger OnAfterGetRecord()
                    begin
                        TaxRegLineSetup.TransferFields("Tax Register Line Setup", true);
                        TaxRegLineSetup."Section Code" := ToTaxRegSection.Code;
                        TaxRegLineSetup.Insert();
                    end;

                    trigger OnPreDataItem()
                    begin
                        TaxRegLineSetup.SetFilter("Section Code", ToTaxRegSection.Code);
                        TaxRegLineSetup.DeleteAll();
                    end;
                }
                dataitem("Tax Register Template"; "Tax Register Template")
                {
                    DataItemLink = "Section Code" = field(Code);
                    DataItemTableView = sorting("Section Code");

                    trigger OnAfterGetRecord()
                    begin
                        TaxRegTemplate.TransferFields("Tax Register Template", true);
                        TaxRegTemplate."Section Code" := ToTaxRegSection.Code;
                        TaxRegTemplate.Insert();
                    end;

                    trigger OnPreDataItem()
                    begin
                        TaxRegTemplate.SetFilter("Section Code", ToTaxRegSection.Code);
                        TaxRegTemplate.DeleteAll();
                    end;
                }
                dataitem("Tax Register Term"; "Tax Register Term")
                {
                    DataItemLink = "Section Code" = field(Code);
                    DataItemTableView = sorting("Section Code");

                    trigger OnAfterGetRecord()
                    begin
                        TaxRegTerm.TransferFields("Tax Register Term", true);
                        TaxRegTerm."Section Code" := ToTaxRegSection.Code;
                        TaxRegTerm.Insert();
                    end;

                    trigger OnPreDataItem()
                    begin
                        TaxRegTerm.SetFilter("Section Code", ToTaxRegSection.Code);
                        TaxRegTerm.DeleteAll();
                    end;
                }
                dataitem("Tax Register Term Formula"; "Tax Register Term Formula")
                {
                    DataItemLink = "Section Code" = field(Code);
                    DataItemTableView = sorting("Section Code");

                    trigger OnAfterGetRecord()
                    begin
                        TaxRegTermFormula.TransferFields("Tax Register Term Formula", true);
                        TaxRegTermFormula."Section Code" := ToTaxRegSection.Code;
                        TaxRegTermFormula.Insert();
                    end;

                    trigger OnPreDataItem()
                    begin
                        TaxRegTermFormula.SetFilter("Section Code", ToTaxRegSection.Code);
                        TaxRegTermFormula.DeleteAll();
                    end;
                }
                dataitem("Tax Register Dim. Filter"; "Tax Register Dim. Filter")
                {
                    DataItemLink = "Section Code" = field(Code);
                    DataItemTableView = sorting("Section Code");

                    trigger OnAfterGetRecord()
                    begin
                        TaxRegDimFilter.TransferFields("Tax Register Dim. Filter", true);
                        TaxRegDimFilter."Section Code" := ToTaxRegSection.Code;
                        TaxRegDimFilter.Insert();
                    end;

                    trigger OnPreDataItem()
                    begin
                        TaxRegDimFilter.SetFilter("Section Code", ToTaxRegSection.Code);
                        TaxRegDimFilter.DeleteAll();
                    end;
                }
                dataitem("Tax Register Dim. Comb."; "Tax Register Dim. Comb.")
                {
                    DataItemLink = "Section Code" = field(Code);
                    DataItemTableView = sorting("Section Code");

                    trigger OnAfterGetRecord()
                    begin
                        TaxRegDimComb.TransferFields("Tax Register Dim. Comb.", true);
                        TaxRegDimComb."Section Code" := ToTaxRegSection.Code;
                        TaxRegDimComb.Insert();
                    end;

                    trigger OnPreDataItem()
                    begin
                        TaxRegDimComb.SetFilter("Section Code", ToTaxRegSection.Code);
                        TaxRegDimComb.DeleteAll();
                    end;
                }
                dataitem("Tax Register Dim. Value Comb."; "Tax Register Dim. Value Comb.")
                {
                    DataItemLink = "Section Code" = field(Code);
                    DataItemTableView = sorting("Section Code");

                    trigger OnAfterGetRecord()
                    begin
                        TaxRegDimValueComb.TransferFields("Tax Register Dim. Value Comb.", true);
                        TaxRegDimValueComb."Section Code" := ToTaxRegSection.Code;
                        TaxRegDimValueComb.Insert();
                    end;

                    trigger OnPreDataItem()
                    begin
                        TaxRegDimValueComb.SetFilter("Section Code", ToTaxRegSection.Code);
                        TaxRegDimValueComb.DeleteAll();
                    end;
                }
                dataitem("Tax Register Dim. Def. Value"; "Tax Register Dim. Def. Value")
                {
                    DataItemLink = "Section Code" = field(Code);
                    DataItemTableView = sorting("Section Code");

                    trigger OnAfterGetRecord()
                    begin
                        TaxRegDimDefaultValue.TransferFields("Tax Register Dim. Def. Value", true);
                        TaxRegDimDefaultValue."Section Code" := ToTaxRegSection.Code;
                        TaxRegDimDefaultValue.Insert();
                    end;

                    trigger OnPreDataItem()
                    begin
                        TaxRegDimDefaultValue.SetFilter("Section Code", ToTaxRegSection.Code);
                        TaxRegDimDefaultValue.DeleteAll();
                    end;
                }
                dataitem("Tax Reg. G/L Corr. Dim. Filter"; "Tax Reg. G/L Corr. Dim. Filter")
                {
                    DataItemLink = "Section Code" = field(Code);
                    DataItemTableView = sorting("Section Code", "Tax Register No.", Define, "Line No.", "Filter Group", "Dimension Code");

                    trigger OnAfterGetRecord()
                    begin
                        TaxRegGLCorrDimFilter.TransferFields("Tax Reg. G/L Corr. Dim. Filter", true);
                        TaxRegGLCorrDimFilter."Section Code" := ToTaxRegSection.Code;
                        TaxRegGLCorrDimFilter.Insert();
                    end;

                    trigger OnPreDataItem()
                    begin
                        TaxRegGLCorrDimFilter.SetFilter("Section Code", ToTaxRegSection.Code);
                        TaxRegGLCorrDimFilter.DeleteAll();
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    ToTaxRegSection.TransferFields("Tax Register Section", false);
                    ToTaxRegSection."Starting Date" := 0D;
                    ToTaxRegSection."Ending Date" := 0D;
                    ToTaxRegSection."Last Date Updated" := 0D;
                    ToTaxRegSection."Absence GL Entries Date" := 0D;
                    ToTaxRegSection."Absence CV Entries Date" := 0D;
                    ToTaxRegSection."Absence Item Entries Date" := 0D;
                    ToTaxRegSection."Absence FA Entries Date" := 0D;
                    ToTaxRegSection."Absence FE Entries Date" := 0D;
                    ToTaxRegSection."Last GL Entries Date" := 0D;
                    ToTaxRegSection."Last CV Entries Date" := 0D;
                    ToTaxRegSection."Last Item Entries Date" := 0D;
                    ToTaxRegSection."Last FA Entries Date" := 0D;
                    ToTaxRegSection."Last FE Entries Date" := 0D;
                    ToTaxRegSection.Status := ToTaxRegSection.Status::Blocked;
                    ToTaxRegSection.Modify();
                end;

                trigger OnPreDataItem()
                begin
                    SetRange(Code, FromSectionCode);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                ValidateChangeDeclaration();
            end;

            trigger OnPreDataItem()
            begin
                if FromSectionCode = '' then
                    Error(Text1000);

                if FindFirst() then
                    if Next() <> 0 then
                        Error(Text1001);

                if FromSectionCode = Code then
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
                    field(FromSectionCode; FromSectionCode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Copy from';
                        TableRelation = "Tax Register Section";
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
        TaxReg: Record "Tax Register";
        TaxRegLineSetup: Record "Tax Register Line Setup";
        TaxRegTemplate: Record "Tax Register Template";
        TaxRegTerm: Record "Tax Register Term";
        TaxRegTermFormula: Record "Tax Register Term Formula";
        TaxRegDimComb: Record "Tax Register Dim. Comb.";
        TaxRegDimValueComb: Record "Tax Register Dim. Value Comb.";
        TaxRegDimDefaultValue: Record "Tax Register Dim. Def. Value";
        TaxRegDimFilter: Record "Tax Register Dim. Filter";
#pragma warning disable AA0074
        Text1000: Label 'Please select source section.';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text1001: Label 'You can copy only one section.';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text1002: Label 'You cannot copy section to itself.';
#pragma warning restore AA0074
        TaxRegGLCorrDimFilter: Record "Tax Reg. G/L Corr. Dim. Filter";
        FromSectionCode: Code[10];
}

