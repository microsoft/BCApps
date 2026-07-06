namespace System.IO;

using System.Environment;

report 8616 "Get Package Tables"
{
    Caption = 'Get Package Tables';
    ProcessingOnly = true;

    dataset
    {
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
                    field(SelectTables; SelectedTables)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Select Tables';
                        Editable = false;
                        ToolTip = 'Specifies which tables to include. When you choose the field, the Config. Selection windows opens in which you can select tables.';

                        trigger OnAssistEdit()
                        var
                            ConfigSelection: Page "Config. Selection";
                        begin
                            ConfigSelection.Set(TempConfigSelection);
                            Commit();
                            if ConfigSelection.RunModal() = ACTION::OK then
                                SelectedTables := ConfigSelection.Get(TempConfigSelection);
                        end;
                    }
                    field(WithDataOnly; WithDataOnly)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'With Data Only';
                        ToolTip = 'Specifies if only data from the tables is included.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            InitSelection();
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    var
        ConfigLine: Record "Config. Line";
    begin
        if PackageCode = '' then
            Error(PackageNotSetErr);

        TempConfigSelection.Reset();
        TempConfigSelection.SetRange("Line Type", TempConfigSelection."Line Type"::Table);
        TempConfigSelection.SetRange(Selected, true);
        if TempConfigSelection.FindSet() then
            repeat
                if DataExists(TempConfigSelection."Table ID") and not ConfigPackageTable.Get(PackageCode, TempConfigSelection."Table ID") then begin
                    ConfigPackageTable.Init();
                    ConfigPackageTable.Validate("Package Code", PackageCode);
                    ConfigPackageTable.Validate("Table ID", TempConfigSelection."Table ID");
                    ConfigPackageTable.Insert(true);
                    ConfigLine.Get(TempConfigSelection."Line No.");
                    if ConfigLine."Package Code" = '' then begin
                        ConfigLine."Package Code" := PackageCode;
                        ConfigLine.Modify();
                    end;
                end;
            until TempConfigSelection.Next() = 0;

        CurrReport.Break();
    end;

    var
        ConfigPackageTable: Record "Config. Package Table";
        TempConfigSelection: Record "Config. Selection" temporary;
        TableInfo: Record "Table Information";
        SelectedTables: Integer;
        PackageCode: Code[20];
        WithDataOnly: Boolean;
        PackageNotSetErr: Label 'Package is not set.';

    procedure Set(NewPackageCode: Code[20])
    begin
        PackageCode := NewPackageCode;
    end;

    local procedure DataExists(TableID: Integer): Boolean
    begin
        if not WithDataOnly then
            exit(true);

        TableInfo.SetRange("Company Name", CompanyName);
        TableInfo.SetRange("Table No.", TableID);
        if TableInfo.FindFirst() then
            if TableInfo."No. of Records" > 0 then
                exit(true);

        exit(false);
    end;

    local procedure InitSelection()
    var
        ConfigLine: Record "Config. Line";
    begin
        TempConfigSelection.Reset();
        ConfigLine.SetFilter("Table ID", '<>0');
        if ConfigLine.FindSet() then
            repeat
                if (ConfigLine."Line Type" <> ConfigLine."Line Type"::Table) or
                   ((ConfigLine."Line Type" = ConfigLine."Line Type"::Table) and (ConfigLine."Package Code" = ''))
                then
                    if not TempConfigSelection.Get(ConfigLine."Line No.") then begin
                        TempConfigSelection.Init();
                        TempConfigSelection."Line No." := ConfigLine."Line No.";
                        TempConfigSelection."Table ID" := ConfigLine."Table ID";
                        TempConfigSelection.Name := ConfigLine.Name;
                        TempConfigSelection."Line Type" := ConfigLine."Line Type";
                        TempConfigSelection.Insert();
                    end;
            until ConfigLine.Next() = 0;
    end;
}

