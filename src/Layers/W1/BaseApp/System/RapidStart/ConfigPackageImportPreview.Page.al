namespace System.IO;

page 8617 "Config. Package Import Preview"
{
    Caption = 'Config. Package Import Preview';
    Editable = false;
    PageType = List;
    ShowFilter = false;
    SourceTable = "Config. Package Table";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group("Import Configuration Package Data from Excel")
            {
                Caption = 'Import Configuration Package Data from Excel';
                group(Control11)
                {
                    InstructionalText = 'Data in the Excel file will be imported for the following packages and tables:';
                    ShowCaption = false;
                    group(Control10)
                    {
                        InstructionalText = 'Review the package codes and tables in the list. If a configuration package with this code does not exist, it will be created. If it does exist, its data may be overwritten.';
                        ShowCaption = false;
                        group(Control9)
                        {
                            InstructionalText = 'Choose the Import action to proceed.';
                            ShowCaption = false;
                        }
                    }
                }
            }
            repeater(Group)
            {
                field("Package Code"; Rec."Package Code")
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = PackageStyleExpr;
                    ToolTip = 'Specifies the code for the package that data will be imported to.';
                }
                field("New Package"; Rec."Delayed Insert")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'New Package';
                    ToolTip = 'Specifies if a package with this code does not exist already.';
                }
                field("Table ID"; Rec."Table ID")
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = TableStyleExpr;
                    ToolTip = 'Specifies the table ID.';
                }
                field("Table Name"; Rec."Table Name")
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = TableStyleExpr;
                    ToolTip = 'Specifies the table name.';
                }
                field("New Table"; Rec.Validated)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the package does not include data for this table.';
                }
            }
        }
    }

    actions
    {
        area(creation)
        {
            action(Import)
            {
                ApplicationArea = Basic, Suite;
                Enabled = IsImportEnabled;
                Image = ImportExcel;
                ToolTip = 'Import the selected sheets with configuration package data from an Excel file.';

                trigger OnAction()
                begin
                    VerifyPackageCode();
                    ImportConfirmed := true;
                    CurrPage.Close();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Import_Promoted; Import)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        PackageStyleExpr := GetStyle(Rec."Delayed Insert");
        TableStyleExpr := GetStyle(Rec.Validated);
    end;

    trigger OnOpenPage()
    begin
        IsImportEnabled := not Rec.IsEmpty();
    end;

    var
        ImportConfirmed: Boolean;
        IsImportEnabled: Boolean;
        PackageStyleExpr: Text;
        SelectedPackageCode: Code[20];
        TableStyleExpr: Text;
        PackageCodeMustMatchErr: Label 'The package code in all sheets of the Excel file must match the selected package code, %1. Modify the package code in the Excel file or import this file from the Configuration Packages page to create a new package.', Comment = '%1 - package code';

    local procedure GetStyle(New: Boolean): Text
    begin
        if New then
            exit('Favorable');
        exit('Unfavorable');
    end;

    procedure SetData(NewSelectedPackageCode: Code[20]; var TempConfigPackageTable: Record "Config. Package Table" temporary)
    begin
        SelectedPackageCode := NewSelectedPackageCode;
        Rec.Copy(TempConfigPackageTable, true);
    end;

    procedure IsImportConfirmed(): Boolean
    begin
        exit(ImportConfirmed);
    end;

    local procedure VerifyPackageCode()
    var
        TempConfigPackageTable: Record "Config. Package Table" temporary;
    begin
        if SelectedPackageCode <> '' then begin
            TempConfigPackageTable.Copy(Rec, true);
            TempConfigPackageTable.SetFilter("Package Code", '<>%1', SelectedPackageCode);
            if not TempConfigPackageTable.IsEmpty() then
                Error(PackageCodeMustMatchErr, SelectedPackageCode);
        end;
    end;
}

